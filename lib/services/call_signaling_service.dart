import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CallSignalingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Generate consistent channel ID for two users
  String getChannelId(String otherUserId) {
    final myId = _auth.currentUser!.uid;
    // Sort IDs so both users get same channel
    final ids = [myId, otherUserId]..sort();
    return 'call_${ids[0]}_${ids[1]}';
  }

  // Save call invitation to Firestore
  Future<void> initiateCall({
    required String receiverId,
    required String channelId,
  }) async {
    final callerId = _auth.currentUser!.uid;
    await _firestore.collection('activeCalls').doc(channelId).set({
      'callerId': callerId,
      'receiverId': receiverId,
      'channelId': channelId,
      'status': 'calling',
      'startedAt': DateTime.now().toIso8601String(),
    });
  }

  // End call
  Future<void> endCall(String channelId) async {
    await _firestore
        .collection('activeCalls')
        .doc(channelId)
        .update({
      'status': 'ended',
      'endedAt': DateTime.now().toIso8601String(),
    });
  }

  // Listen for incoming calls
  Stream<Map<String, dynamic>?> listenForIncomingCalls() {
    final myId = _auth.currentUser?.uid;
    if (myId == null) return const Stream.empty();

    return _firestore
        .collection('activeCalls')
        .where('receiverId', isEqualTo: myId)
        .where('status', isEqualTo: 'calling')
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      final doc = snapshot.docs.first;
      return {...doc.data(), 'channelId': doc.id};
    });
  }

  // Accept call
  Future<void> acceptCall(String channelId) async {
    await _firestore
        .collection('activeCalls')
        .doc(channelId)
        .update({'status': 'active'});
  }

  // Decline call
  Future<void> declineCall(String channelId) async {
    await _firestore
        .collection('activeCalls')
        .doc(channelId)
        .update({'status': 'declined'});
  }
}