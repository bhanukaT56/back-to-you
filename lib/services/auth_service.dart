import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'dart:convert';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // get current logged in user
  User? get currentUser => _auth.currentUser;

  // listen to auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // REGISTER
  Future<String?> register({
    required String name,
    required String email,
    required String password,
    required String studentId,
    required File studentIdImage,
  }) async {
    try {
      // step 1 — create account in Firebase Auth
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      String uid = userCredential.user!.uid;

      // step 2 — convert image to base64 string
      List<int> imageBytes = await studentIdImage.readAsBytes();
      String base64Image = base64Encode(imageBytes);

      // step 3 — save user data to Firestore
      await _firestore.collection('users').doc(uid).set({
        'name': name,
        'email': email,
        'studentId': studentId,
        'idPhotoBase64': base64Image,
        'isVerified': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return null; // null means success!

    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'weak-password':
          return 'password is too weak';
        case 'email-already-in-use':
          return 'an account already exists with this email';
        case 'invalid-email':
          return 'please enter a valid email address';
        default:
          return 'registration failed. please try again';
      }
    } catch (e) {
      return 'something went wrong. please try again';
    }
  }

  // LOGIN
 Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return null;

    } on FirebaseAuthException catch (e) {
      print('🔴 Firebase error code: ${e.code}');
      print('🔴 Firebase error message: ${e.message}');
      
      switch (e.code) {
        case 'user-not-found':
          return 'no account found with this email';
        case 'wrong-password':
          return 'incorrect email or password';
        case 'invalid-credential':
          return 'incorrect email or password';
        case 'invalid-email':
          return 'please enter a valid email';
        case 'user-disabled':
          return 'this account has been disabled';
        default:
          return 'error: ${e.code}';
      }
    } catch (e) {
      print('🔴 General error: $e');
      return e.toString();
    }
  }
  // LOGOUT
  Future<void> logout() async {
    await _auth.signOut();
  }

  // CHECK IF USER IS VERIFIED
  Future<bool> isUserVerified() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) return false;

      DocumentSnapshot doc =
          await _firestore.collection('users').doc(user.uid).get();

      if (doc.exists) {
        return doc['isVerified'] ?? false;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // GET USER DATA
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) return null;

      DocumentSnapshot doc =
          await _firestore.collection('users').doc(user.uid).get();

      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}