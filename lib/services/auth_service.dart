import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  User? get currentUser => _auth.currentUser;
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
      // step 1 — create account
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      String uid = userCredential.user!.uid;

      // step 2 — upload student ID to Firebase Storage
      String fileName = 'student_ids/$uid/student_id.jpg';
      Reference storageRef = _storage.ref().child(fileName);
      await storageRef.putFile(studentIdImage);
      String idPhotoUrl = await storageRef.getDownloadURL();

      // step 3 — save user data to Firestore
      await _firestore.collection('users').doc(uid).set({
        'name': name,
        'email': email,
        'studentId': studentId,
        'idPhotoUrl': idPhotoUrl,
        'isVerified': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return null;

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
      print('🔴 register error: $e');
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
      switch (e.code) {
        case 'user-not-found':
          return 'no account found with this email';
        case 'wrong-password':
          return 'incorrect email or password';
        case 'invalid-credential':
          return 'incorrect email or password';
        case 'user-disabled':
          return 'this account has been disabled';
        default:
          return 'login failed. please try again';
      }
    } catch (e) {
      return 'something went wrong. please try again';
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

  // UPDATE PROFILE PHOTO
  Future<String?> updateProfilePhoto(File photo) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) return 'not logged in';

      // upload to Storage
      String fileName = 'profile_photos/${user.uid}/profile.jpg';
      Reference storageRef = _storage.ref().child(fileName);
      await storageRef.putFile(photo);
      String photoUrl = await storageRef.getDownloadURL();

      // save url to Firestore
      await _firestore.collection('users').doc(user.uid).update({
        'profilePhotoUrl': photoUrl,
      });

      return null;
    } catch (e) {
      print('🔴 profile photo error: $e');
      return 'could not update photo';
    }
  }
}