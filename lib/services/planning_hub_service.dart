import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PlanningHubService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String> _getCoupleId() async {
    final userDoc = await _db.collection('users').doc(_auth.currentUser?.uid).get();
    return userDoc.data()?['coupleId'] ?? _auth.currentUser!.uid;
  }

  CollectionReference<Map<String, dynamic>> _planningCollection(String coupleId) {
    return _db.collection('couples').doc(coupleId).collection('planning_hub');
  }

  CollectionReference<Map<String, dynamic>> _transactionsCollection(String coupleId) {
    return _db.collection('couples').doc(coupleId).collection('transactions');
  }

  Future<void> addTask(String title) async {
    final coupleId = await _getCoupleId();
    await _planningCollection(coupleId).add({
      'type': 'task',
      'title': title.trim(),
      'isDone': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> addItem({
    required String title,
    double? price,
    String? category,
  }) async {
    final coupleId = await _getCoupleId();

    final data = <String, dynamic>{
      'type': 'item',
      'title': title.trim(),
      'isBought': false,
      'createdAt': FieldValue.serverTimestamp(),
    };

    if (price != null && price > 0) {
      data['price'] = price;
      data['hasExpenseEntry'] = true;
    }
    if (category != null && category.trim().isNotEmpty) {
      data['category'] = category.trim();
    }

    final docRef = await _planningCollection(coupleId).add(data);

    if (price != null && price > 0) {
      await _transactionsCollection(coupleId).add({
        'type': 'expense',
        'amount': price,
        'title': title.trim(),
        'planningItemId': docRef.id,
        'category': category?.trim() ?? 'item',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> addService({
    required String title,
    double? totalPrice,
    double? depositPaid,
  }) async {
    final coupleId = await _getCoupleId();

    double? remainingDebt;
    if (totalPrice != null) {
      final deposit = depositPaid ?? 0;
      remainingDebt = (totalPrice - deposit).clamp(0, double.infinity);
    }

    final data = <String, dynamic>{
      'type': 'service',
      'title': title.trim(),
      'totalPrice': totalPrice,
      'depositPaid': depositPaid ?? 0,
      'remainingDebt': remainingDebt,
      'createdAt': FieldValue.serverTimestamp(),
    };

    final docRef = await _planningCollection(coupleId).add(data);

    if (depositPaid != null && depositPaid > 0) {
      await _transactionsCollection(coupleId).add({
        'type': 'expense',
        'amount': depositPaid,
        'title': title.trim(),
        'planningItemId': docRef.id,
        'category': 'service',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> toggleTaskDone({
    required String planningItemId,
    required bool isDone,
  }) async {
    final coupleId = await _getCoupleId();
    await _planningCollection(coupleId).doc(planningItemId).update({
      'isDone': isDone,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> toggleItemBought({
    required String planningItemId,
    required bool isBought,
    double? price,
    bool hasExpenseEntry = false,
    String? title,
    String? category,
  }) async {
    final coupleId = await _getCoupleId();
    final itemRef = _planningCollection(coupleId).doc(planningItemId);

    if (isBought && (price ?? 0) > 0 && !hasExpenseEntry) {
      final batch = _db.batch();
      batch.update(itemRef, {
        'isBought': true,
        'hasExpenseEntry': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      final txRef = _transactionsCollection(coupleId).doc();
      batch.set(txRef, {
        'type': 'expense',
        'amount': price,
        'title': title?.trim(),
        'planningItemId': planningItemId,
        'category': category?.trim() ?? 'item',
        'createdAt': FieldValue.serverTimestamp(),
      });
      await batch.commit();
    } else {
      await itemRef.update({
        'isBought': isBought,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> addServicePayment({
    required String planningItemId,
    required double amount,
  }) async {
    if (amount <= 0) return;

    final coupleId = await _getCoupleId();
    final serviceRef = _planningCollection(coupleId).doc(planningItemId);

    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(serviceRef);
      final data = snapshot.data() ?? {};

      final currentDeposit = (data['depositPaid'] as num?)?.toDouble() ?? 0;
      final totalPrice = (data['totalPrice'] as num?)?.toDouble() ?? 0;
      final currentRemaining = (data['remainingDebt'] as num?)?.toDouble() ?? (totalPrice - currentDeposit);

      final newDeposit = currentDeposit + amount;
      final newRemaining = (currentRemaining - amount).clamp(0, double.infinity);

      transaction.update(serviceRef, {
        'depositPaid': newDeposit,
        'remainingDebt': newRemaining,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final txRef = _transactionsCollection(coupleId).doc();
      transaction.set(txRef, {
        'type': 'expense',
        'amount': amount,
        'title': data['title'] ?? '',
        'planningItemId': planningItemId,
        'category': data['category'] ?? 'service',
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }
}

