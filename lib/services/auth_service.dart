import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign up with email and password
  Future<UserModel?> signUp({
    required String email,
    required String password,
    String role = 'user',
  }) async {
    try {
      // Create user in Firebase Auth
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;
      if (user == null) return null;

      // Create user document in Firestore
      UserModel newUser = UserModel(
        userId: user.uid,
        email: email,
        role: role,
        status: 'active',
        createdAt: DateTime.now(),
        agreementSigned: false,
      );

      await _firestore.collection('users').doc(user.uid).set(newUser.toMap());

      return newUser;
    } catch (e) {
      print('Sign up error: $e');
      return null;
    }
  }

  // Sign in with email and password
  Future<UserModel?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;
      if (user == null) return null;

      // Get user data from Firestore
      DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();

      if (!doc.exists) return null;

      return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    } catch (e) {
      print('Sign in error: $e');
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Get user data from Firestore
  Future<UserModel?> getUserData(String userId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(userId).get();

      if (!doc.exists) return null;

      return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    } catch (e) {
      print('Get user data error: $e');
      return null;
    }
  }
}