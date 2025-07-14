import 'package:flutter/material.dart';

class BlockedUsersScreen extends StatelessWidget {
  const BlockedUsersScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Placeholder blocked users
    final blockedUsers = [
      {'name': 'Blocked User 1', 'avatar': null},
      {'name': 'Blocked User 2', 'avatar': null},
      {'name': 'Blocked User 3', 'avatar': null},
    ];
    return Scaffold(
      backgroundColor: const Color(0xFF181A20),
      appBar: AppBar(
        backgroundColor: const Color(0xFF181A20),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Blocked Chats',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: false,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        itemCount: blockedUsers.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final user = blockedUsers[index];
          return Container(
            decoration: BoxDecoration(
              color: const Color(0xFF23272F),
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.grey[800],
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    user['name']!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                // Optionally add an unblock button or icon here
              ],
            ),
          );
        },
      ),
    );
  }
}
