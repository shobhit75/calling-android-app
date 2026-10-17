import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/team_service.dart';
import 'call_screen.dart';

class UsersScreen extends StatelessWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final TeamService teamService = TeamService();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Team Members',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue[800],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<List<UserModel>>(
        stream: teamService.getAllUsers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data ?? [];
          final activeUsers = users
              .where((u) => u.status == 'active')
              .toList();

          if (activeUsers.isEmpty) {
            return const Center(
              child: Text(
                'No active users yet.',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: activeUsers.length,
            itemBuilder: (context, index) {
              final user = activeUsers[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.shade100,
                    child: Text(
                      user.email[0].toUpperCase(),
                      style: TextStyle(
                        color: Colors.blue.shade800,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    user.email.split('@')[0],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    user.email,
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          user.role,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.blue.shade800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => CallScreen(
                                remoteUser: user,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.call,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}