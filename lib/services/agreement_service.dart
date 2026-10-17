import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/agreement_model.dart';

class AgreementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Create new agreement
  Future<String?> createAgreement(String testerId) async {
    try {
      final String ownerId = _auth.currentUser!.uid;

      final agreement = AgreementModel(
        agreementId: '',
        ownerId: ownerId,
        testerId: testerId,
        status: 'pending',
      );

      final doc = await _firestore
          .collection('agreements')
          .add(agreement.toMap());

      print('✅ Agreement created: ${doc.id}');
      return doc.id;
    } catch (e) {
      print('❌ Create agreement error: $e');
      return null;
    }
  }

  // Sign agreement
  Future<bool> signAgreement({
    required String agreementId,
    required String signature,
    required String ipAddress,
  }) async {
    try {
      await _firestore
          .collection('agreements')
          .doc(agreementId)
          .update({
        'status': 'active',
        'signedAt': DateTime.now().toIso8601String(),
        'digitalSignature': signature,
        'ipAddress': ipAddress,
      });

      // Update user agreementSigned status
      final doc = await _firestore
          .collection('agreements')
          .doc(agreementId)
          .get();

      final data = doc.data() as Map<String, dynamic>;
      final testerId = data['testerId'];

      await _firestore
          .collection('users')
          .doc(testerId)
          .update({
        'agreementSigned': true,
        'agreementId': agreementId,
      });

      print('✅ Agreement signed: $agreementId');
      return true;
    } catch (e) {
      print('❌ Sign agreement error: $e');
      return false;
    }
  }

  // Withdraw agreement
  Future<bool> withdrawAgreement(String agreementId) async {
    try {
      await _firestore
          .collection('agreements')
          .doc(agreementId)
          .update({
        'status': 'withdrawn',
        'withdrawnAt': DateTime.now().toIso8601String(),
      });

      final doc = await _firestore
          .collection('agreements')
          .doc(agreementId)
          .get();

      final data = doc.data() as Map<String, dynamic>;
      final testerId = data['testerId'];

      await _firestore
          .collection('users')
          .doc(testerId)
          .update({
        'agreementSigned': false,
        'agreementId': null,
        'status': 'revoked',
      });

      print('✅ Agreement withdrawn: $agreementId');
      return true;
    } catch (e) {
      print('❌ Withdraw agreement error: $e');
      return false;
    }
  }

  // Get agreements for tester
  Stream<List<AgreementModel>> getTesterAgreements(String testerId) {
    return _firestore
        .collection('agreements')
        .where('testerId', isEqualTo: testerId)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => AgreementModel.fromMap(doc.data(), doc.id))
        .toList());
  }

  // Get all agreements (for owner)
  Stream<List<AgreementModel>> getAllAgreements() {
    return _firestore
        .collection('agreements')
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => AgreementModel.fromMap(doc.data(), doc.id))
        .toList());
  }
}