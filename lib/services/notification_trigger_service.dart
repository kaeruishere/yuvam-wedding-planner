import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationTriggerService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Future<void> triggerNotification({
    required String coupleId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    await _db
        .collection('couples')
        .doc(coupleId)
        .collection('notifications')
        .add({
      'title': title,
      'body': body,
      'senderId': currentUser.uid,
      'senderName': currentUser.displayName ?? 'Partnerin',
      'createdAt': FieldValue.serverTimestamp(),
      'data': data ?? {},
      'isRead': false,
    });
  }
}
