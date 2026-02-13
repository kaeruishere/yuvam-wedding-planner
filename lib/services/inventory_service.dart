import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class InventoryService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Kullanıcının güncel coupleId bilgisini getirir
  Future<String> _getCoupleId() async {
    final userDoc = await _db.collection('users').doc(_auth.currentUser?.uid).get();
    return userDoc.data()?['coupleId'] ?? _auth.currentUser!.uid;
  }

  // Yeni kategori ekleme (couples/{coupleId}/inventory)
  Future<void> addCategory(String sectionId, String name, String emoji) async {
    final coupleId = await _getCoupleId();
    await _db.collection('couples').doc(coupleId).collection('inventory').add({
      'sectionId': sectionId,
      'name': name.trim().toUpperCase(),
      'emoji': emoji.isEmpty ? "📦" : emoji.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Kategori içine eşya ekleme (couples/{coupleId}/inventory/{catId}/items)
  Future<void> addItem(String coupleId, String categoryDocId, String itemName) async {
    await _db
        .collection('couples')
        .doc(coupleId)
        .collection('inventory')
        .doc(categoryDocId)
        .collection('items')
        .add({
      'name': itemName.trim(),
      'isBought': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}