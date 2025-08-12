import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'dart:convert';

class BlockedUser extends StatefulWidget {
  const BlockedUser({Key? key}) : super(key: key);

  @override
  State<BlockedUser> createState() => _BlockedUserState();
}

class _BlockedUserState extends State<BlockedUser> {
  List<dynamic> _blockedUsers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBlockedUsers();
  }

  Future<void> _loadBlockedUsers() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final currentUserId = ApiService.currentUserId;
      final relations = await ApiService.getUserSimpleRelations(currentUserId);
      final blockedIds = List<int>.from(relations['blocked'] ?? []);
      final allUsers = await ApiService.getAllUsers();
      final blockedUsers =
          allUsers.where((u) => blockedIds.contains(u['id'])).toList();
      setState(() {
        _blockedUsers = blockedUsers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _unblockUser(int userId) async {
    try {
      await ApiService.unblockUser(userId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User unblocked successfully'),
          backgroundColor: Colors.green,
        ),
      );
      await _loadBlockedUsers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to unblock user'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
          'Blocked Users',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
            letterSpacing: 1.1,
          ),
        ),
        centerTitle: false,
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Colors.amber),
              )
              : _blockedUsers.isEmpty
              ? const Center(
                child: Text(
                  'No blocked users',
                  style: TextStyle(color: Colors.white54, fontSize: 16),
                ),
              )
              : ListView.separated(
                itemCount: _blockedUsers.length,
                separatorBuilder:
                    (_, __) => const Divider(color: Colors.white12, height: 1),
                itemBuilder: (context, index) {
                  final user = _blockedUsers[index];
                  return Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(width: 2, color: Colors.transparent),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,

                              color: const Color.fromARGB(255, 41, 41, 41),
                              // gradient: const LinearGradient(
                              //   colors: [
                              //     Color(0xFFffa030),
                              //     Color(0xFFfe9b00),
                              //     Color(0xFFf67d00),
                              //   ],
                              //   begin: Alignment.topLeft,
                              //   end: Alignment.bottomRight,
                              // ),
                            ),
                            padding: const EdgeInsets.all(2),
                            child: CircleAvatar(
                              radius: 28,
                              backgroundColor: Colors.grey[900],
                              backgroundImage:
                                  user['profile_pic'] != null &&
                                          user['profile_pic'].isNotEmpty
                                      ? (user['profile_pic'].startsWith('http')
                                          ? NetworkImage(user['profile_pic'])
                                          : NetworkImage(
                                            'https://server.bharathchat.com${user['profile_pic']}',
                                          ))
                                      : null,
                              child:
                                  (user['profile_pic'] == null ||
                                          user['profile_pic'].isEmpty)
                                      ? Text(
                                        ((user['first_name'] ??
                                                    user['username'] ??
                                                    'U')
                                                as String)[0]
                                            .toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 22,
                                        ),
                                      )
                                      : null,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ShaderMask(
                                  shaderCallback:
                                      (bounds) => const LinearGradient(
                                        colors: [
                                          Color(0xFFffa030),
                                          Color(0xFFfe9b00),
                                          Color(0xFFf67d00),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ).createShader(bounds),
                                  child: Text(
                                    ((user['first_name'] ?? '') +
                                                ' ' +
                                                (user['last_name'] ?? ''))
                                            .trim()
                                            .isNotEmpty
                                        ? ((user['first_name'] ?? '') +
                                                ' ' +
                                                (user['last_name'] ?? ''))
                                            .trim()
                                        : (user['username'] ?? 'User'),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 17,
                                    ),
                                  ),
                                ),
                                if (user['bio'] != null &&
                                    (user['bio'] as String).isNotEmpty)
                                  Text(
                                    user['bio'],
                                    style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 13,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            width: 80,
                            height: 30,
                            decoration: BoxDecoration(
                              // color: Colors.red,
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFFffa030),
                                  Color(0xFFfe9b00),
                                  Color(0xFFf67d00),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: ElevatedButton(
                              onPressed: () => _unblockUser(user['id']),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(22),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 0,
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                'Unblock',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
