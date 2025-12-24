import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Add user details to Firestore
  Future<void> addUserDetails({
    required String uid,
    required String name,
    required String email,
  }) async {
    await _firestore.collection('users').doc(uid).set({
      'name': name,
      'email': email,
      'bio': '',
      'followers': [],
      'following': [],
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Register with email and password
  Future<String?> register({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      print('Starting registration for email: $email');
      
      // Create user in Firebase Auth
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;
      print('User created in Auth: ${user?.uid}');

      if (user != null) {
        print('Creating Firestore document...');
        
        // Add user details to Firestore using separate function
        await addUserDetails(
          uid: user.uid,
          name: name,
          email: email,
        );

        print('Firestore document created successfully!');
        return null; // Success
      }
      return 'Registration failed';
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException: ${e.code} - ${e.message}');
      switch (e.code) {
        case 'weak-password':
          return 'Password is too weak';
        case 'email-already-in-use':
          return 'Email already exists';
        case 'invalid-email':
          return 'Invalid email address';
        default:
          return e.message ?? 'Registration failed';
      }
    } catch (e) {
      print('General error during registration: $e');
      return 'Error: ${e.toString()}';
    }
  }

  // Login with email and password
  Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return null; // Success
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          return 'No user found with this email';
        case 'wrong-password':
          return 'Wrong password';
        case 'invalid-email':
          return 'Invalid email address';
        case 'user-disabled':
          return 'This account has been disabled';
        default:
          return e.message ?? 'Login failed';
      }
    } catch (e) {
      return 'Error: ${e.toString()}';
    }
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
  }

  // Get user data from Firestore
  Future<DocumentSnapshot> getUserData(String uid) async {
    return await _firestore.collection('users').doc(uid).get();
  }
}