import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class UserService extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create or update user profile in Firestore
  Future<void> createUserProfile(User user) async {
    try {
      final userDoc = _firestore.collection('users').doc(user.uid);
      final snapshot = await userDoc.get();

      if (!snapshot.exists) {
        // Create new profile
        await userDoc.set({
          'uid': user.uid,
          'email': user.email,
          'provider': user.providerData.isNotEmpty
              ? user.providerData[0].providerId
              : 'unknown',
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
        });
      } else {
        // Update last login
        await userDoc.update({
          'lastLogin': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error creating user profile: $e');
      // Don't block app flow if firestore fails, just log it
    }
  }
}
