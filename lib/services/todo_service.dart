import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/task_model.dart';
import '../services/notification_service.dart';
import 'notification_trigger_service.dart';

class TodoService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get current user's coupleId
  Future<String?> _getCoupleId() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;

    final userDoc = await _db.collection('users').doc(uid).get();
    return userDoc.data()?['coupleId'] ?? uid;
  }

  /// Public method to get couple ID
  Future<String?> getCoupleIdPublic() => _getCoupleId();

  /// Stream of all tasks for the couple
  Stream<List<Task>> getTasksStream() async* {
    final coupleId = await _getCoupleId();
    if (coupleId == null) {
      yield [];
      return;
    }

    yield* _db
        .collection('couples')
        .doc(coupleId)
        .collection('todos')
        .orderBy('dueDate', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Task.fromFirestore(doc))
            .toList());
  }

  /// Stream of tasks by status
  Stream<List<Task>> getTasksByStatus(bool completed) async* {
    final coupleId = await _getCoupleId();
    if (coupleId == null) {
      yield [];
      return;
    }

    yield* _db
        .collection('couples')
        .doc(coupleId)
        .collection('todos')
        .where('completed', isEqualTo: completed)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Task.fromFirestore(doc))
            .toList());
  }
  
  /// Get pending tasks (for dashboard)
  Stream<List<Task>> getPendingTasks({int limit = 5}) async* {
    final coupleId = await _getCoupleId();
    if (coupleId == null) {
      yield [];
      return;
    }

    yield* _db
        .collection('couples')
        .doc(coupleId)
        .collection('todos')
        .where('completed', isEqualTo: false)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Task.fromFirestore(doc))
            .toList());
  }

  // ... (imports)

  /// Add a new task
  Future<String?> addTask(Task task) async {
    try {
      final coupleId = await _getCoupleId();
      if (coupleId == null) return 'User not authenticated';

      // Add to Firestore
      final docRef = await _db
          .collection('couples')
          .doc(coupleId)
          .collection('todos')
          .add(task.toMap());

      // Schedule Reminder if dueDate exists
      if (task.dueDate != null) {
        // Schedule for 1 day before due date, or same day if close
        // Let's say 24 hours before
        final scheduledDate = task.dueDate!.subtract(const Duration(days: 1));
        
        // Only schedule if future
        if (scheduledDate.isAfter(DateTime.now())) {
             // Create unique int ID from hash of doc ID or random? 
             // Doc ID is string. hashcode collisions possible but rare enough for this scale.
             // Better: use millisecond timestamp part of task creation? No.
             // We can use docRef.id.hashCode
             
             await NotificationService().scheduleNotification(
               id: docRef.id.hashCode,
               title: "Görev Hatırlatıcı",
               body: "${task.title} için son gün yarın!",
               scheduledDate: scheduledDate,
             );
        }
      }

      // Trigger Notification
      await NotificationTriggerService.triggerNotification(
        coupleId: coupleId,
        title: 'Yeni Görev',
        body: '${task.title} görevi eklendi.',
        data: {'type': 'todo', 'id': docRef.id},
      );

      return null; // Success
    } catch (e) {
      return 'Failed to add task: $e';
    }
  }

  /// Toggle task completion
  Future<String?> toggleTaskCompletion({
    required String taskId,
    required bool completed,
  }) async {
    try {
      final coupleId = await _getCoupleId();
      if (coupleId == null) return 'User not authenticated';

      await _db
          .collection('couples')
          .doc(coupleId)
          .collection('todos')
          .doc(taskId)
          .update({
        'completed': completed,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Trigger Notification
      await NotificationTriggerService.triggerNotification(
        coupleId: coupleId,
        title: completed ? 'Görev Tamamlandı' : 'Görev Geri Alındı',
        body: 'Bir görev ${completed ? 'tamamlandı' : 'güncellendi'}.',
        data: {'type': 'todo', 'id': taskId, 'completed': completed},
      );

      return null; // Success
    } catch (e) {
      return 'Failed to update task: $e';
    }
  }

  /// Update task details
  Future<String?> updateTask(Task task) async {
    try {
      final coupleId = await _getCoupleId();
      if (coupleId == null) return 'User not authenticated';

      await _db
          .collection('couples')
          .doc(coupleId)
          .collection('todos')
          .doc(task.id)
          .update(task.toMap()..['updatedAt'] = FieldValue.serverTimestamp());

      // Trigger Notification
      await NotificationTriggerService.triggerNotification(
        coupleId: coupleId,
        title: 'Görev Güncellendi',
        body: '${task.title} görevi güncellendi.',
        data: {'type': 'todo', 'id': task.id},
      );

      return null; // Success
    } catch (e) {
      return 'Failed to update task: $e';
    }
  }

  /// Delete a task
  Future<String?> deleteTask(String taskId) async {
    try {
      final coupleId = await _getCoupleId();
      if (coupleId == null) return 'User not authenticated';

      await _db
          .collection('couples')
          .doc(coupleId)
          .collection('todos')
          .doc(taskId)
          .delete();
          
      // Cancel reminder
      await NotificationService().cancelNotification(taskId.hashCode);

      // Trigger Notification
      await NotificationTriggerService.triggerNotification(
        coupleId: coupleId,
        title: 'Görev Silindi',
        body: 'Bir görev silindi.',
      );

      return null; // Success
    } catch (e) {
      return 'Failed to delete task: $e';
    }
  }

  /// Get task statistics
  Future<Map<String, int>> getTaskStats() async {
    try {
      final coupleId = await _getCoupleId();
      if (coupleId == null) return {};

      final tasksSnapshot = await _db
          .collection('couples')
          .doc(coupleId)
          .collection('todos')
          .get();

      int totalTasks = 0;
      int completedTasks = 0;
      int pendingTasks = 0;
      int overdueTasks = 0;

      final now = DateTime.now();

      for (var doc in tasksSnapshot.docs) {
        final task = Task.fromFirestore(doc);
        totalTasks++;

        if (task.completed) {
          completedTasks++;
        } else {
          pendingTasks++;

          if (task.dueDate != null && task.dueDate!.isBefore(now)) {
            overdueTasks++;
          }
        }
      }

      return {
        'total': totalTasks,
        'completed': completedTasks,
        'pending': pendingTasks,
        'overdue': overdueTasks,
      };
    } catch (e) {
      return {};
    }
  }
}
