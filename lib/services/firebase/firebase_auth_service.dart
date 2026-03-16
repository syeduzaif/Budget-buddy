 import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get/get.dart';
import 'firestore_service.dart';
import 'google_auth_service.dart';

class FirebaseAuthService extends GetxService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;
  String? get currentUserId => _auth.currentUser?.uid;
  String? get currentUserEmail => _auth.currentUser?.email;
  String? get currentUserName => _auth.currentUser?.displayName;
  bool get isLoggedIn => _auth.currentUser != null;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> signUpWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleException(e);
    } catch (_) {
      throw 'An unexpected error occurred. Please try again.';
    }
  }

  Future<UserCredential> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleException(e);
    } catch (_) {
      throw 'An unexpected error occurred. Please try again.';
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (_) {
      throw 'Failed to sign out. Please try again.';
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _handleException(e);
    } catch (_) {
      throw 'Failed to send password reset email.';
    }
  }

  Future<void> updateDisplayName(String name) async {
    await _auth.currentUser?.updateDisplayName(name);
  }

  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final uid = user.uid;

    try {
      // 1. Delete Firestore Data
      await Get.find<FirestoreService>().deleteUserData(uid);

      // 2. Delete Storage Data
      await _deleteStorageData(uid);

      // 3. Delete Auth Account
      await user.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw 'reauthentication-required';
      }
      throw _handleException(e);
    } catch (e) {
      throw 'Failed to delete account. Please try again.';
    }
  }

  Future<void> _deleteStorageData(String uid) async {
    try {
      final storageRef = FirebaseStorage.instance.ref().child('users').child(uid);
      final listResult = await storageRef.listAll();
      
      // Delete all files in the user folder
      for (final item in listResult.items) {
        await item.delete();
      }
      
      // Delete all subfolders (recursively if needed, but usually we just have files)
      for (final prefix in listResult.prefixes) {
        await _deleteFolder(prefix);
      }
    } catch (e) {
      // If storage is not initialized or folder doesn't exist, ignore
      print('Storage deletion error (probably normal if no files): $e');
    }
  }

  Future<void> _deleteFolder(Reference ref) async {
    final list = await ref.listAll();
    for (final item in list.items) {
      await item.delete();
    }
    for (final prefix in list.prefixes) {
      await _deleteFolder(prefix);
    }
  }

  Future<void> reauthenticate(String password) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) return;

    AuthCredential? credential;
    
    // Check if user is google signed in or email signed in
    final isGoogle = user.providerData.any((p) => p.providerId == 'google.com');
    
    if (isGoogle) {
      final googleAuth = Get.find<GoogleAuthService>();
      // This will trigger the Google sign-in flow again
      await googleAuth.signInWithGoogle();
      return;
    } else {
      credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);
    }
  }

  String _handleException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'Password is too weak.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      case 'invalid-credential':
        return 'Invalid credentials. Please check your email and password.';
      default:
        return e.message ?? 'Authentication failed. Please try again.';
    }
  }
}
