import 'package:flutter/material.dart';
import 'dart:convert';
import '../../services/api_service.dart';

class UserProfileScreen extends StatefulWidget {
  final int userId;
  final String userName;

  const UserProfileScreen({
    Key? key,
    required this.userId,
    required this.userName,
  }) : super(key: key);

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final users = await ApiService.getAllUsers();
      final user = users.firstWhere((u) => u['id'] == widget.userId);
      setState(() {
        _userData = user;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  ImageProvider? _getProfileImage() {
    if (_userData?['profile_pic'] != null && _userData!['profile_pic'].toString().isNotEmpty) {
      try {
        return MemoryImage(base64Decode(_userData!['profile_pic']));
      } catch (e) {
        print('Error decoding profile image: $e');
        return null;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _userData?['username'] ?? widget.userName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _userData?['is_following'] == true ? Icons.person_remove : Icons.person_add,
              color: _userData?['is_following'] == true ? Colors.red : Colors.orange,
            ),
            onPressed: () async {
              try {
                await ApiService.followUser(widget.userId);
                _loadUserData(); // Reload data to update UI
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Failed to follow/unfollow user'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.block, color: Colors.red),
            onPressed: () async {
              try {
                await ApiService.blockUser(widget.userId);
                Navigator.pop(context); // Go back to previous screen
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('User blocked successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Failed to block user'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Profile Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.grey[800],
                          backgroundImage: _getProfileImage(),
                          child: _getProfileImage() == null
                              ? Text(
                                  (widget.userName).substring(0, 1).toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 40,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '${_userData?['first_name'] ?? ''} ${_userData?['last_name'] ?? ''}'.trim(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '@${_userData?['username'] ?? ''}',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Followers and Following Count
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildCountColumn(
                              'Followers',
                              _userData?['followers_count'] ?? 0,
                            ),
                            const SizedBox(width: 32),
                            _buildCountColumn(
                              'Following',
                              _userData?['following_count'] ?? 0,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Bio
                        if (_userData?['bio'] != null && _userData!['bio'].toString().isNotEmpty)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[900],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _userData!['bio'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),
                        // Stats
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildStatColumn(
                              'Diamonds',
                              _userData?['diamonds'] ?? 0,
                              Icons.diamond,
                            ),
                            _buildStatColumn(
                              'Balance',
                              _userData?['balance'] ?? 0,
                              Icons.account_balance_wallet,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildCountColumn(String label, int count) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildStatColumn(String label, dynamic value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.orange, size: 24),
        const SizedBox(height: 8),
        Text(
          value.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 12,
          ),
        ),
      ],
    );
  }
} 