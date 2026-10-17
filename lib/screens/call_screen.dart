import 'package:flutter/material.dart';
import 'dart:async';
import '../services/call_service.dart';
import '../services/call_signaling_service.dart';
import '../models/user_model.dart';

class CallScreen extends StatefulWidget {
  final UserModel remoteUser;
  final bool isIncoming;
  final String? channelId;

  const CallScreen({
    super.key,
    required this.remoteUser,
    this.isIncoming = false,
    this.channelId,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  final CallService _callService = CallService();
  late final CallSignalingService _signalingService;

  bool _isCallConnected = false;
  bool _isMuted = false;
  bool _isSpeakerOn = false;
  bool _isLoading = true;
  int _callDuration = 0;
  Timer? _timer;
  DateTime? _callStartTime;
  String _statusText = 'Connecting...';
  late String _channelId;

  @override
  void initState() {
    super.initState();
    _signalingService = CallSignalingService();
    // Use provided channelId or generate a FIXED one based on both users
    _channelId = widget.channelId ?? _signalingService.getChannelId(
      widget.remoteUser.userId,
    );
    _startCall();
  }

  Future<void> _startCall() async {
    // Save call invitation to Firestore so other user can join
    await _signalingService.initiateCall(
      receiverId: widget.remoteUser.userId,
      channelId: _channelId,
    );

    await _callService.joinCall(
      channelId: _channelId,
      onUserJoined: (uid) {
        setState(() {
          _isCallConnected = true;
          _isLoading = false;
          _statusText = 'Connected';
          _callStartTime = DateTime.now();
        });
        _startTimer();
      },
      onUserLeft: (uid) {
        _endCall();
      },
      onJoinSuccess: () {
        setState(() {
          _isLoading = false;
          _statusText = widget.isIncoming ? 'Connected' : 'Ringing...';
        });
      },
      onError: (error) {
        setState(() {
          _isLoading = false;
          _statusText = 'Connection failed';
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Call error: $error'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
    );
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() => _callDuration++);
    });
  }

  String _formatDuration(int seconds) {
    final mins = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  Future<void> _endCall() async {
    _timer?.cancel();
    final endTime = DateTime.now();

    await _signalingService.endCall(_channelId);

    if (_callStartTime != null) {
      await _callService.saveCallLog(
        receiverId: widget.remoteUser.userId,
        startTime: _callStartTime!,
        endTime: endTime,
        status: 'completed',
      );
    }

    await _callService.leaveCall();
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _toggleMute() async {
    await _callService.toggleMute();
    setState(() => _isMuted = _callService.isMuted);
  }

  Future<void> _toggleSpeaker() async {
    await _callService.toggleSpeaker();
    setState(() => _isSpeakerOn = _callService.isSpeakerOn);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _callService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue[900]!,
              Colors.blue[700]!,
              Colors.blue[500]!,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 60),

              // Status
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _statusText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // Avatar
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.2),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.5),
                    width: 3,
                  ),
                ),
                child: Center(
                  child: Text(
                    widget.remoteUser.email[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 50,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Name
              Text(
                widget.remoteUser.email.split('@')[0],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // Email
              Text(
                widget.remoteUser.email,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 20),

              // Timer or Loading
              if (_isCallConnected)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _formatDuration(_callDuration),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3,
                    ),
                  ),
                )
              else if (_isLoading)
                const CircularProgressIndicator(color: Colors.white),

              const Spacer(),

              // Channel ID (small, for debugging)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Channel: ${_channelId.substring(0, 12)}...',
                  style: const TextStyle(
                    color: Colors.white30,
                    fontSize: 10,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Controls
              Padding(
                padding: const EdgeInsets.only(bottom: 60),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _CallControlButton(
                          icon: _isMuted ? Icons.mic_off : Icons.mic,
                          label: _isMuted ? 'Unmute' : 'Mute',
                          onPressed: _toggleMute,
                          backgroundColor: _isMuted
                              ? Colors.red.withOpacity(0.8)
                              : Colors.white.withOpacity(0.2),
                        ),
                        const SizedBox(width: 40),
                        _CallControlButton(
                          icon: _isSpeakerOn
                              ? Icons.volume_up
                              : Icons.volume_down,
                          label: _isSpeakerOn ? 'Speaker' : 'Earpiece',
                          onPressed: _toggleSpeaker,
                          backgroundColor: _isSpeakerOn
                              ? Colors.blue.withOpacity(0.8)
                              : Colors.white.withOpacity(0.2),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),

                    // End Call
                    GestureDetector(
                      onTap: _endCall,
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black38,
                              blurRadius: 12,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.call_end,
                          color: Colors.white,
                          size: 34,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'End Call',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CallControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color backgroundColor;

  const _CallControlButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onPressed,
          child: Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: backgroundColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
      ],
    );
  }
}