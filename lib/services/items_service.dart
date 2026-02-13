import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/item_model.dart';
import 'notification_trigger_service.dart';

class ItemsService {
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

  /// Stream of all items for the couple
  Stream<List<Item>> getItemsStream() async* {
    final coupleId = await _getCoupleId();
    if (coupleId == null) {
      yield [];
      return;
    }

    yield* _db
        .collection('couples')
        .doc(coupleId)
        .collection('items')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Item.fromFirestore(doc))
            .toList());
  }

  /// Stream of items by category
  Stream<List<Item>> getItemsByCategory(String category) async* {
    final coupleId = await _getCoupleId();
    if (coupleId == null) {
      yield [];
      return;
    }

    yield* _db
        .collection('couples')
        .doc(coupleId)
        .collection('items')
        .where('category', isEqualTo: category)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Item.fromFirestore(doc))
            .toList());
  }

  /// Stream of items by status
  Stream<List<Item>> getItemsByStatus(String status) async* {
    final coupleId = await _getCoupleId();
    if (coupleId == null) {
      yield [];
      return;
    }

    yield* _db
        .collection('couples')
        .doc(coupleId)
        .collection('items')
        .where('status', isEqualTo: status)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Item.fromFirestore(doc))
            .toList());
  }

  /// Add a new item
  Future<String?> addItem(Item item) async {
    try {
      final coupleId = await _getCoupleId();
      if (coupleId == null) return 'User not authenticated';

      // Use the model's toMap but exclude 'createdAt' as it's handled by server timestamp in toMap logic (or here)
      // Actually, my model toMap handles serverTimestamp for null createdAt.
      // But creating a new document we might want to let Firestore handle ID generation if empty, 
      // but Item model requires ID. Usually we add then update ID or ignore ID in add.
      // Better approach: use .add() and let Firestore generate ID.
      
      final docRef = await _db
          .collection('couples')
          .doc(coupleId)
          .collection('items')
          .add(item.toMap());

      // Trigger Notification
      await NotificationTriggerService.triggerNotification(
        coupleId: coupleId,
        title: 'Yeni Ürün Eklendi',
        body: '${item.name} alışveriş listesine eklendi.',
        data: {'type': 'item', 'id': docRef.id},
      );

      return null; // Success
    } catch (e) {
      return 'Failed to add item: $e';
    }
  }

  /// Update item status
  Future<String?> updateItemStatus({
    required String itemId,
    required String status,
  }) async {
    try {
      final coupleId = await _getCoupleId();
      if (coupleId == null) return 'User not authenticated';

      await _db
          .collection('couples')
          .doc(coupleId)
          .collection('items')
          .doc(itemId)
          .update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Trigger Notification
      await NotificationTriggerService.triggerNotification(
        coupleId: coupleId,
        title: 'Ürün Durumu Güncellendi',
        body: 'Alışveriş listesindeki bir ürünün durumu değişti.',
        data: {'type': 'item', 'id': itemId, 'status': status},
      );

      return null; // Success
    } catch (e) {
      return 'Failed to update status: $e';
    }
  }

  /// Update item details
  Future<String?> updateItem(Item item) async {
    try {
      final coupleId = await _getCoupleId();
      if (coupleId == null) return 'User not authenticated';

      await _db
          .collection('couples')
          .doc(coupleId)
          .collection('items')
          .doc(item.id)
          .update(item.toMap());

      // Trigger Notification
      await NotificationTriggerService.triggerNotification(
        coupleId: coupleId,
        title: 'Ürün Güncellendi',
        body: '${item.name} bilgileri güncellendi.',
        data: {'type': 'item', 'id': item.id},
      );

      return null; // Success
    } catch (e) {
      return 'Failed to update item: $e';
    }
  }

  /// Delete an item
  Future<String?> deleteItem(String itemId) async {
    try {
      final coupleId = await _getCoupleId();
      if (coupleId == null) return 'User not authenticated';

      await _db
          .collection('couples')
          .doc(coupleId)
          .collection('items')
          .doc(itemId)
          .delete();

      // Trigger Notification
      await NotificationTriggerService.triggerNotification(
        coupleId: coupleId,
        title: 'Ürün Silindi',
        body: 'Alışveriş listesinden bir ürün silindi.',
      );

      return null; // Success
    } catch (e) {
      return 'Failed to delete item: $e';
    }
  }

  /// Get item statistics
  Future<Map<String, int>> getItemStats() async {
    try {
      final coupleId = await _getCoupleId();
      if (coupleId == null) return {};

      final itemsSnapshot = await _db
          .collection('couples')
          .doc(coupleId)
          .collection('items')
          .get();

      int totalItems = 0;
      int toBuyItems = 0;
      int boughtItems = 0;

      for (var doc in itemsSnapshot.docs) {
        // Use Model parsing for consistency
        final item = Item.fromFirestore(doc);
        totalItems++;
        
        if (item.status == 'bought' || item.status == 'received') {
          boughtItems++;
        } else {
          toBuyItems++;
        }
      }

      return {
        'total': totalItems,
        'to_buy': toBuyItems,
        'bought': boughtItems,
      };
    } catch (e) {
      return {};
    }
  }

  /// Get total cost of all items
  Future<double> getTotalCost() async {
    try {
      final coupleId = await _getCoupleId();
      if (coupleId == null) return 0.0;

      final itemsSnapshot = await _db
          .collection('couples')
          .doc(coupleId)
          .collection('items')
          .get();

      double totalCost = 0.0;

      for (var doc in itemsSnapshot.docs) {
        final item = Item.fromFirestore(doc);
        totalCost += (item.cost * item.quantity);
      }

      return totalCost;
    } catch (e) {
      return 0.0;
    }
  }

  // --- Documents ---

  Future<String?> addDocument({
    required String itemId,
    required String name,
    required String link,
    String type = 'link',
  }) async {
    try {
      final coupleId = await getCoupleIdPublic();
      if (coupleId == null) return "User not linked";

      final docData = DocumentAttachment(
        id: DateTime.now().millisecondsSinceEpoch.toString(), 
        name: name, 
        link: link,
        type: type,
        createdAt: DateTime.now(),
      ).toMap(); // We need a toMap for DocumentAttachment as well, or manual map

      await _db
          .collection('couples')
          .doc(coupleId)
          .collection('items')
          .doc(itemId)
          .update({
        'documents.list': FieldValue.arrayUnion([docData]),
      });
      return null;
    } catch (e) {
      return "Error adding document: $e";
    }
  }

  Future<String?> deleteDocument({
    required String itemId,
    required DocumentAttachment doc,
  }) async {
    try {
      final coupleId = await getCoupleIdPublic();
      if (coupleId == null) return "User not linked";

      // IMPORTANT: removing objects from array in firestore requires EXACT match.
      // This is risky if dates/timestamps slightly differ.
      // Better to read, filter, write back.
      
      final itemRef = _db.collection('couples').doc(coupleId).collection('items').doc(itemId);
      
      await _db.runTransaction((transaction) async {
        final snapshot = await transaction.get(itemRef);
        if (!snapshot.exists) return; // Item deleted?
        
        final item = Item.fromFirestore(snapshot);
        final updatedDocs = item.documents.where((d) => d.id != doc.id).map((d) => d.toMap()).toList();
        
        transaction.update(itemRef, {'documents.list': updatedDocs});
      });

      return null;
    } catch (e) {
      return "Error deleting document: $e";
    }
  }
}

// Extension to help with DocumentAttachment -> Map if not in model
extension DocumentAttachmentMap on DocumentAttachment {
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'link': link,
      'type': type,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}
