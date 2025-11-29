import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';

class AuthRepository {
  final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  bool _isGoogleSignInInitialized = false;

  // Get current user stream
  Stream<auth.User?> get authStateChanges => _auth.authStateChanges();

  // Get current user
  auth.User? get currentUser => _auth.currentUser;

  // Sign in with email and password
  Future<UserModel> signInWithEmail(String email, String password) async {
    try {
      final auth.UserCredential userCredential = await _auth
          .signInWithEmailAndPassword(email: email, password: password);

      // Check if user document exists, if not create it
      final userDoc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (!userDoc.exists) {
        // Create new user document
        final newUser = UserModel(
          uid: userCredential.user!.uid,
          email: email,
          name: userCredential.user!.displayName ?? email.split('@')[0],
          phone: userCredential.user!.phoneNumber,
          role: UserRole.user,
          photoURL: userCredential.user!.photoURL,
          provider: AuthProvider.email,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .set(newUser.toFirestore());

        return newUser;
      }

      // Update last login time
      await _firestore.collection('users').doc(userCredential.user!.uid).update(
        {'updatedAt': FieldValue.serverTimestamp()},
      );

      // Return existing user
      return UserModel.fromFirestore(userDoc);
    } on auth.FirebaseAuthException catch (e) {
      throw Exception(e.code);
    } catch (e) {
      throw Exception('Sign in failed: $e');
    }
  }

  Future<void> _ensureGoogleSignInInitialized() async {
    if (_isGoogleSignInInitialized) return;
    await _googleSignIn.initialize();
    _isGoogleSignInInitialized = true;
  }

  // Sign in with Google
  Future<UserModel> signInWithGoogle() async {
    try {
      await _ensureGoogleSignInInitialized();

      // Trigger the authentication flow (v7 API)
      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      // Create a new credential (access tokens are no longer provided in v7+)
      final credential = auth.GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final auth.UserCredential userCredential = await _auth
          .signInWithCredential(credential);

      // Check if user document exists
      final userDoc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (!userDoc.exists) {
        // Create new user document
        final newUser = UserModel(
          uid: userCredential.user!.uid,
          email: userCredential.user!.email!,
          name: userCredential.user!.displayName ?? 'User',
          phone: userCredential.user!.phoneNumber,
          role: UserRole.user,
          photoURL: userCredential.user!.photoURL,
          provider: AuthProvider.google,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .set(newUser.toFirestore());

        return newUser;
      }

      // Update last login time
      await _firestore.collection('users').doc(userCredential.user!.uid).update(
        {'updatedAt': FieldValue.serverTimestamp()},
      );

      return UserModel.fromFirestore(userDoc);
    } on auth.FirebaseAuthException catch (e) {
      throw Exception(e.code);
    } catch (e) {
      throw Exception('Google sign in failed: $e');
    }
  }

  // Register with email and password
  Future<UserModel> registerWithEmail({
    required String email,
    required String password,
    required String name,
    String? phone,
  }) async {
    try {
      final auth.UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      // Update display name
      await userCredential.user!.updateDisplayName(name);

      // Create user document in Firestore
      final newUser = UserModel(
        uid: userCredential.user!.uid,
        email: email,
        name: name,
        phone: phone,
        role: UserRole.user,
        photoURL: null,
        provider: AuthProvider.email,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .set(newUser.toFirestore());

      return newUser;
    } on auth.FirebaseAuthException catch (e) {
      throw Exception(e.code);
    } catch (e) {
      throw Exception('Registration failed: $e');
    }
  }

  // Get user data from Firestore
  Future<UserModel?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user data: $e');
    }
  }

  // Stream user data
  Stream<UserModel?> streamUserData(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? UserModel.fromFirestore(doc) : null);
  }

  // Update user profile
  Future<void> updateUserProfile({
    required String uid,
    String? name,
    String? phone,
    String? photoURL,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (name != null) updateData['name'] = name;
      if (phone != null) updateData['phone'] = phone;
      if (photoURL != null) updateData['photoURL'] = photoURL;

      await _firestore.collection('users').doc(uid).update(updateData);
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await Future.wait([_auth.signOut(), _googleSignIn.signOut()]);
    } catch (e) {
      throw Exception('Sign out failed: $e');
    }
  }

  // Delete account
  Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Delete user document from Firestore
        await _firestore.collection('users').doc(user.uid).delete();

        // Delete auth account
        await user.delete();
      }
    } catch (e) {
      throw Exception('Failed to delete account: $e');
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on auth.FirebaseAuthException catch (e) {
      throw Exception(e.code);
    } catch (e) {
      throw Exception('Failed to send reset email: $e');
    }
  }
}
