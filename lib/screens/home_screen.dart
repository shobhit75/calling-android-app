import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/call_signaling_service.dart';
import '../models/user_model.dart';
import 'login_screen.dart';
import 'admin_dashboard.dart';
import 'call_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  final CallSignalingService _signalingService = CallSignalingService();
  UserModel? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = _authService.currentUser;
    if (user != null) {
      final userData = await _authService.getUserData(user.uid);
      setState(() {
        _currentUser = userData;
        _isLoading = false;
      });

      // If owner, go to admin dashboard
      if (userData?.role == 'owner') {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const AdminDashboard(),
            ),
          );
        }
      } else {
        // If tester, listen for incoming calls
        _listenForIncomingCalls();
      }
    }
  }

  void _listenForIncomingCalls() {
    _signalingService.listenForIncomingCalls().listen((callData) {
      if (callData != null && mounted) {
        _showIncomingCallDialog(callData);
      }
    });
  }

  void _showIncomingCallDialog(Map<String, dynamic> callData) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.call, color: Colors.green, size: 60),
            const SizedBox(height: 16),
            const Text(
              'Incoming Call',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'From: ${callData['callerId'].toString().substring(0, 8)}...',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          // Decline
          ElevatedButton.icon(
            onPressed: () async {
              await _signalingService
                  .declineCall(callData['channelId']);
              if (context.mounted) Navigator.pop(context);
            },
            icon: const Icon(Icons.call_end, color: Colors.white),
            label: const Text(
              'Decline',
              style: TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
          ),
          // Accept
          ElevatedButton.icon(
            onPressed: () async {
              await _signalingService
                  .acceptCall(callData['channelId']);
              if (context.mounted) {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => CallScreen(
                      remoteUser: UserModel(
                        userId: callData['callerId'],
                        email: 'Caller',
                        role: 'owner',
                        status: 'active',
                        createdAt: DateTime.now(),
                      ),
                      isIncoming: true,
                      channelId: callData['channelId'],
                    ),
                  ),
                );
              }
            },
            icon: const Icon(Icons.call, color: Colors.white),
            label: const Text(
              'Accept',
              style: TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Call App'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _authService.signOut();
              if (context.mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const LoginScreen(),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle,
              size: 100,
              color: Colors.green,
            ),
            const SizedBox(height: 20),
            const Text(
              'Welcome!',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _currentUser?.email ?? '',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Role: ${_currentUser?.role ?? 'user'}',
                style: TextStyle(
                  color: Colors.blue.shade800,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '📞 Waiting for incoming calls...',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}