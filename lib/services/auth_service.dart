import '../services/notification_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:math';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<User?> register(String email, String password, String name, String surname) async {
    try {
      final res = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      final user = res.user;

      if (user != null) {
        final pairCode = _generatePairCode();
        String? photoUrl;

        // Generate and upload default profile image
        try {
          photoUrl = await _generateDefaultProfileImage(name, surname, user.uid);
        } catch (e) {
          print("Error generating profile image: $e");
        }
        
        // 1. Create User Document
        await _db.collection('users').doc(user.uid).set({
          'name': name,
          'surname': surname,
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
          'onboardingCompleted': false,
          'myPairCode': pairCode,
          'coupleId': user.uid, // Initially, coupleId is their own UID
          'partnerId': null,
          'photoUrl': photoUrl,
        });

        // 2. Create Couple Document
        await _db.collection('couples').doc(user.uid).set({
          'users': [user.uid],
          'partnerCode': pairCode,
          'createdAt': FieldValue.serverTimestamp(),
          'relationshipStartDate': null, // For duration calculation
          'events': {}, 
        });

        // Save FCM Token
        await NotificationService().saveTokenToFirestore();
      }
      return user;
    } catch (e) {
      rethrow;
    }
  }

  Future<String?> _generateDefaultProfileImage(String name, String surname, String uid) async {
    try {
      // Use a solid color background (e.g., Primary Color hex) and white text
      // 6750A4 is a common M3 purple. 
      final url = Uri.parse('https://ui-avatars.com/api/?name=$name+$surname&background=6750A4&color=fff&size=512&length=2&font-size=0.5');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final ref = FirebaseStorage.instance.ref().child('profile_images').child('$uid.jpg');
        await ref.putData(response.bodyBytes);
        return await ref.getDownloadURL();
      }
    } catch (e) {
      print("Error uploading default image: $e");
    }
    return null;
  }

  Future<User?> login(String email, String password) async {
    final res = await _auth.signInWithEmailAndPassword(email: email, password: password);
    if (res.user != null) {
      await NotificationService().saveTokenToFirestore();
    }
    return res.user;
  }

  Future<void> logout() async {
    await NotificationService().deleteToken();
    await _auth.signOut();
  }

  // Link partner using their pair code
  Future<void> linkPartner(String partnerCode) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('User not logged in');

    try {
      // 1. Find partner by code
      final querySnapshot = await _db
          .collection('users')
          .where('myPairCode', isEqualTo: partnerCode)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        throw Exception('Invalid partner code');
      }

      final partnerDoc = querySnapshot.docs.first;
      final partnerId = partnerDoc.id;
      final partnerData = partnerDoc.data();
      
      if (partnerId == currentUser.uid) {
        throw Exception('You cannot link with yourself');
      }

      // Check if partner is already linked
      if (partnerData['partnerId'] != null) {
         // Optional: Allow re-linking? For now, throw.
         // throw Exception('Partner is already linked');
      }

      final targetCoupleId = partnerData['coupleId'];

      // 2. Update Current User
      // Switch to partner's coupleId
      await _db.collection('users').doc(currentUser.uid).update({
        'coupleId': targetCoupleId,
        'partnerId': partnerId,
      });

      // 3. Update Partner User
      await _db.collection('users').doc(partnerId).update({
        'partnerId': currentUser.uid,
      });

      // 4. Update Couple Document (Target)
      await _db.collection('couples').doc(targetCoupleId).update({
        'users': FieldValue.arrayUnion([currentUser.uid]),
      });
      
      // 5. Cleanup: Delete current user's old orphan couple doc (which was their UID)
      // Only do this if their coupleId was their UID (which it should be if they were single)
      await _db.collection('couples').doc(currentUser.uid).delete().catchError((e) {
        // Ignore if it doesn't exist or sets error
        print("Error deleting orphan couple: $e");
      });

    } catch (e) {
      rethrow;
    }
  }
  
  // Update password
  Future<void> updatePassword(String newPassword) async {
    await _auth.currentUser?.updatePassword(newPassword);
  }

  // Update email
  Future<void> updateEmail(String newEmail) async {
    await _auth.currentUser?.verifyBeforeUpdateEmail(newEmail);
  }

  // Delete account
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user != null) {
      // Delete user data from Firestore
      await _db.collection('users').doc(user.uid).delete();
      // Remove from couple? Logic gets complex here. 
      // For now, just delete the user doc and auth.
      await user.delete();
    }
  }
  // Disconnect partner
  Future<void> disconnectPartner({required bool keepData}) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('User not logged in');

    try {
      final userDoc = await _db.collection('users').doc(currentUser.uid).get();
      final userData = userDoc.data();
      final partnerId = userData?['partnerId'];
      final oldCoupleId = userData?['coupleId'];

      if (partnerId == null || oldCoupleId == null) {
        throw Exception('No partner to disconnect');
      }

      // 1. Create new couple doc for current user (they become single)
      final newCoupleId = currentUser.uid; // Use their UID as new couple ID
      
      // 2. Prepare new couple data
      Map<String, dynamic> newCoupleData = {
        'users': [currentUser.uid],
        'partnerCode': userData?['myPairCode'] ?? _generatePairCode(),
        'createdAt': FieldValue.serverTimestamp(),
        'events': {},
      };

      if (keepData) {
         // Copy events from old couple
         final oldCoupleDoc = await _db.collection('couples').doc(oldCoupleId).get();
         if (oldCoupleDoc.exists) {
           final oldData = oldCoupleDoc.data();
           if (oldData != null && oldData['events'] != null) {
             newCoupleData['events'] = oldData['events'];
           }
         }
      }

      await _db.collection('couples').doc(newCoupleId).set(newCoupleData);

      // 3. Update User Docs & Old Couple Doc
      await _db.runTransaction((transaction) async {
        // Update my user doc
        transaction.update(_db.collection('users').doc(currentUser.uid), {
          'partnerId': null,
          'coupleId': newCoupleId,
        });

        // Update partner user doc
        transaction.update(_db.collection('users').doc(partnerId), {
          'partnerId': null,
        });

        // Remove me from old couple doc
        transaction.update(_db.collection('couples').doc(oldCoupleId), {
          'users': FieldValue.arrayRemove([currentUser.uid]),
        });
      });

    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateOnboardingStatus(bool completed) async {
    final user = _auth.currentUser;
    if (user != null) {
      await _db.collection('users').doc(user.uid).update({
        'onboardingCompleted': completed,
      });
    }
  }

  String _generatePairCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rnd = Random();
    return String.fromCharCodes(Iterable.generate(
      6,
      (_) => chars.codeUnitAt(rnd.nextInt(chars.length)),
    ));
  }
}