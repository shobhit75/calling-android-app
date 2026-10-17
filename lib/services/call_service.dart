import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../config/app_config.dart';

class CallService {
  RtcEngine? _engine;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isInCall = false;
  bool _isMuted = false;
  bool _isSpeakerOn = true; // Default speaker ON for calls

  bool get isInCall => _isInCall;
  bool get isMuted => _isMuted;
  bool get isSpeakerOn => _isSpeakerOn;

  // Initialize Agora
  Future<bool> initAgora() async {
    try {
      // Request microphone permission
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        print('❌ Microphone permission denied');
        return false;
      }

      // Release any existing engine
      if (_engine != null) {
        await _engine!.leaveChannel();
        await _engine!.release();
        _engine = null;
      }

      // Create engine
      _engine = createAgoraRtcEngine();
      
      _isSpeakerOn = true;

print('✅ Agora audio enabled');
      // Enable audio
      await _engine!.enableAudio();
      
      // Set audio profile for voice call
      await _engine!.setAudioProfile(
        profile: AudioProfileType.audioProfileDefault,
        scenario: AudioScenarioType.audioScenarioChatroom,
      );

      // Enable speaker by default
      await _engine!.setEnableSpeakerphone(true);
      _isSpeakerOn = true;

      print('✅ Agora audio enabled');
      return true;

    } catch (e) {
      print('❌ Agora init error: $e');
      return false;
    }
  }

  // Join a call channel
  Future<void> joinCall({
    required String channelId,
    required Function(int uid) onUserJoined,
    required Function(int uid) onUserLeft,
    required Function() onJoinSuccess,
    required Function(String error) onError,
  }) async {
    try {
      print('🔄 Joining call: $channelId');

      // Initialize if not already done
      final initialized = await initAgora();
      if (!initialized) {
        onError('Failed to initialize audio. Please check microphone permission.');
        return;
      }

      // Register event handlers
      _engine!.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (connection, elapsed) async {
  print('✅ Joined channel: ${connection.channelId}');
  _isInCall = true;
  
  // Enable speaker after joining
  try {
    await _engine?.setEnableSpeakerphone(true);
    _isSpeakerOn = true;
    print('✅ Speaker enabled');
  } catch (e) {
    print('⚠️ Speaker error: $e');
  }
  
  onJoinSuccess();
},
          onUserJoined: (connection, remoteUid, elapsed) {
            print('✅ User joined: $remoteUid');
            onUserJoined(remoteUid);
          },
          onUserOffline: (connection, remoteUid, reason) {
            print('✅ User left: $remoteUid (reason: $reason)');
            onUserLeft(remoteUid);
          },
          onError: (err, msg) {
            print('❌ Agora error: $err - $msg');
            onError('Connection error: $err');
          },
          onConnectionStateChanged: (connection, state, reason) {
            print('🔄 Connection state: $state (reason: $reason)');
          },
        ),
      );

      // Join channel
      await _engine!.joinChannel(
        token: '', // No token needed in test mode
        channelId: channelId,
        uid: 0, // Auto-assign UID
        options: const ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          channelProfile: ChannelProfileType.channelProfileCommunication,
          autoSubscribeAudio: true,
          publishMicrophoneTrack: true,
        ),
      );

      print('✅ Join channel command sent');

    } catch (e) {
      print('❌ Join call error: $e');
      onError('Failed to join call: $e');
    }
  }

  // Leave call
  Future<void> leaveCall() async {
    try {
      await _engine?.leaveChannel();
      _isInCall = false;
      _isMuted = false;
      print('✅ Left call');
    } catch (e) {
      print('❌ Leave call error: $e');
    }
  }

  // Toggle mute
  Future<void> toggleMute() async {
    try {
      _isMuted = !_isMuted;
      await _engine?.muteLocalAudioStream(_isMuted);
      print('🎤 Muted: $_isMuted');
    } catch (e) {
      print('❌ Toggle mute error: $e');
    }
  }

  // Toggle speaker
  Future<void> toggleSpeaker() async {
    try {
      _isSpeakerOn = !_isSpeakerOn;
      await _engine?.setEnableSpeakerphone(_isSpeakerOn);
      print('🔊 Speaker: $_isSpeakerOn');
    } catch (e) {
      print('❌ Toggle speaker error: $e');
    }
  }

  // Save call log to Firestore
  Future<void> saveCallLog({
    required String receiverId,
    required DateTime startTime,
    required DateTime endTime,
    required String status,
  }) async {
    try {
      final callerId = _auth.currentUser!.uid;
      final duration = endTime.difference(startTime).inSeconds;

      await _firestore.collection('calls').add({
        'callerId': callerId,
        'receiverId': receiverId,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        'duration': duration,
        'status': status,
        'callType': 'voice',
      });

      print('✅ Call log saved');
    } catch (e) {
      print('❌ Save call log error: $e');
    }
  }

  // Dispose engine
  Future<void> dispose() async {
    try {
      await _engine?.leaveChannel();
      await _engine?.release();
      _engine = null;
      print('✅ Agora engine disposed');
    } catch (e) {
      print('❌ Dispose error: $e');
    }
  }
}