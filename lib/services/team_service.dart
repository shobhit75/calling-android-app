import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class TeamService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get all testers
  Stream<List<UserModel>> getTesters() {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'tester')
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => UserModel.fromMap(doc.data(), doc.id))
        .toList());
  }

  // Get all users
  Stream<List<UserModel>> getAllUsers() {
    return _firestore
        .collection('users')
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => UserModel.fromMap(doc.data(), doc.id))
        .toList());
  }

  // Grant tester access
  Future<bool> grantTesterAccess({
    required String email,
    required String password,
  }) async {
    try {
      // Get current owner ID
      final String ownerId = _auth.currentUser!.uid;

      // Create tester account in Firebase Auth
      final UserCredential result = await _auth
          .createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final User? tester = result.user;
      if (tester == null) return false;

      // Save tester in Firestore
      final UserModel newTester = UserModel(
        userId: tester.uid,
        email: email.trim(),
        role: 'tester',
        status: 'active',
        createdBy: ownerId,
        createdAt: DateTime.now(),
        agreementSigned: false,
      );

      await _firestore
          .collection('users')
          .doc(tester.uid)
          .set(newTester.toMap());

      // Log the action
      await _logAction(
        userId: tester.uid,
        action: 'granted',
        performedBy: ownerId,
      );

      // Sign back in as owner
      print('✅ Tester created: ${tester.uid}');
      return true;

    } catch (e) {
      print('❌ Grant access error: $e');
      return false;
    }
  }

  // Revoke tester access
  Future<bool> revokeAccess(String testerId) async {
    try {
      final String ownerId = _auth.currentUser!.uid;

      // Update status to revoked
      await _firestore
          .collection('users')
          .doc(testerId)
          .update({'status': 'revoked'});

      // Log the action
      await _logAction(
        userId: testerId,
        action: 'revoked',
        performedBy: ownerId,
      );

      print('✅ Access revoked for: $testerId');
      return true;

    } catch (e) {
      print('❌ Revoke access error: $e');
      return false;
    }
  }

  // Restore tester access
  Future<bool> restoreAccess(String testerId) async {
    try {
      final String ownerId = _auth.currentUser!.uid;

      await _firestore
          .collection('users')
          .doc(testerId)
          .update({'status': 'active'});

      await _logAction(
        userId: testerId,
        action: 'restored',
        performedBy: ownerId,
      );

      print('✅ Access restored for: $testerId');
      return true;

    } catch (e) {
      print('❌ Restore access error: $e');
      return false;
    }
  }

  // Log actions
  Future<void> _logAction({
    required String userId,
    required String action,
    required String performedBy,
  }) async {
    await _firestore.collection('accessLogs').add({
      'userId': userId,
      'action': action,
      'performedBy': performedBy,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  // Check if current user is owner
  Future<bool> isOwner() async {
    try {
      final String uid = _auth.currentUser!.uid;
      final DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(uid)
          .get();
      if (!doc.exists) return false;
      final data = doc.data() as Map<String, dynamic>;
      return data['role'] == 'owner';
    } catch (e) {
      return false;
    }
  }

  // Make user an owner
  Future<void> makeOwner(String userId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .update({'role': 'owner'});
  }
}