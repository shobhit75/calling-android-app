import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/team_service.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'users_screen.dart';
import 'agreement_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final TeamService _teamService = TeamService();
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.blue[800],
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
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
      body: StreamBuilder<List<UserModel>>(
        stream: _teamService.getAllUsers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final users = snapshot.data ?? [];
          final testers = users.where((u) => u.role == 'tester').toList();
          final activeTesters =
          testers.where((u) => u.status == 'active').toList();
          final revokedTesters =
          testers.where((u) => u.status == 'revoked').toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stats Cards
                Row(
                  children: [
                    _StatCard(
                      title: 'Total Users',
                      count: users.length,
                      color: Colors.blue,
                      icon: Icons.people,
                    ),
                    const SizedBox(width: 12),
                    _StatCard(
                      title: 'Active Testers',
                      count: activeTesters.length,
                      color: Colors.green,
                      icon: Icons.check_circle,
                    ),
                    const SizedBox(width: 12),
                    _StatCard(
                      title: 'Revoked',
                      count: revokedTesters.length,
                      color: Colors.red,
                      icon: Icons.block,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Grant Tester Access Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showGrantAccessDialog(context),
                    icon: const Icon(Icons.person_add, color: Colors.white),
                    label: const Text(
                      'Grant Tester Access',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Voice Call Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const UsersScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.call, color: Colors.white),
                    label: const Text(
                      'Voice Call Team Members',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Active Testers
                const Text(
                  'Active Testers',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                if (activeTesters.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(
                        child: Text(
                          'No active testers yet.\nClick "Grant Tester Access" to add one.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                  )
                else
                  ...activeTesters.map((tester) => _TesterCard(
                    tester: tester,
                    onRevoke: () => _revokeAccess(tester),
                    isActive: true,
                  )),

                const SizedBox(height: 24),

                // Revoked Testers
                if (revokedTesters.isNotEmpty) ...[
                  const Text(
                    'Revoked Testers',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...revokedTesters.map((tester) => _TesterCard(
                    tester: tester,
                    onRevoke: () => _restoreAccess(tester),
                    isActive: false,
                  )),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  void _showGrantAccessDialog(BuildContext context) {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text(
            'Grant Tester Access',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter credentials for the new tester:',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Tester Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Temporary Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                if (emailController.text.isEmpty ||
                    passwordController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill all fields'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                setDialogState(() => isLoading = true);
                final success = await _teamService.grantTesterAccess(
                  email: emailController.text,
                  password: passwordController.text,
                );
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? '✅ Tester access granted!'
                            : '❌ Failed to grant access',
                      ),
                      backgroundColor:
                      success ? Colors.green : Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              child: isLoading
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
                  : const Text(
                'Grant Access',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _revokeAccess(UserModel tester) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revoke Access'),
        content: Text(
            'Are you sure you want to revoke access for ${tester.email}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Revoke',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await _teamService.revokeAccess(tester.userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                success ? '✅ Access revoked!' : '❌ Failed to revoke'),
            backgroundColor: success ? Colors.orange : Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _restoreAccess(UserModel tester) async {
    final success = await _teamService.restoreAccess(tester.userId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              success ? '✅ Access restored!' : '❌ Failed to restore'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }
}

// Stat Card Widget
class _StatCard extends StatelessWidget {
  final String title;
  final int count;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                title,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Tester Card Widget
class _TesterCard extends StatelessWidget {
  final UserModel tester;
  final VoidCallback onRevoke;
  final bool isActive;

  const _TesterCard({
    required this.tester,
    required this.onRevoke,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isActive ? Colors.green.shade200 : Colors.red.shade200,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: isActive
                      ? Colors.green.shade100
                      : Colors.red.shade100,
                  child: Icon(
                    isActive ? Icons.person : Icons.person_off,
                    color: isActive ? Colors.green : Colors.red,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tester.email,
                        style:
                        const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        'Created: ${tester.createdAt.toString().substring(0, 10)}',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: tester.agreementSigned
                        ? Colors.green.shade100
                        : Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    tester.agreementSigned ? '✅ Signed' : '⏳ Pending',
                    style: TextStyle(
                      fontSize: 11,
                      color: tester.agreementSigned
                          ? Colors.green.shade800
                          : Colors.orange.shade800,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                // Agreement Button
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => AgreementScreen(
                            tester: tester,
                            agreementId: tester.agreementId,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.description, size: 16),
                    label: Text(
                      tester.agreementSigned
                          ? 'View Agreement'
                          : 'Send Agreement',
                      style: const TextStyle(fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue[800],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Revoke/Restore Button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onRevoke,
                    icon: Icon(
                      isActive ? Icons.block : Icons.restore,
                      size: 16,
                    ),
                    label: Text(
                      isActive ? 'Revoke' : 'Restore',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 12),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                      isActive ? Colors.red : Colors.green,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}