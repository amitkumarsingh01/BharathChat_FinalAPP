import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'dart:convert';

class FollowedUser extends StatefulWidget {
  const FollowedUser({Key? key}) : super(key: key);

  @override
  State<FollowedUser> createState() => _FollowedUserState();
}

class _FollowedUserState extends State<FollowedUser>
    with SingleTickerProviderStateMixin {
  List<dynamic> _followers = [];
  List<dynamic> _following = [];
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadRelationsUsers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRelationsUsers() async {
    setState(() {
      _isLoading = true;
    });
    try {
      int? currentUserId = ApiService.currentUserId;
      if (currentUserId == null) {
        final user = await ApiService.getCurrentUser();
        currentUserId = user['id'] ?? user['user_id'];
      }
      final relations = await ApiService.getUserRelations(currentUserId);
      final followingIds = List<int>.from(relations['following_ids'] ?? []);
      final followersIds = List<int>.from(relations['followers_ids'] ?? []);
      final allUsers = await ApiService.getAllUsers();
      final followingUsers =
          allUsers.where((u) => followingIds.contains(u['id'])).toList();
      final followersUsers =
          allUsers.where((u) => followersIds.contains(u['id'])).toList();
      setState(() {
        _following = followingUsers;
        _followers = followersUsers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _unfollowUser(int userId) async {
    try {
      await ApiService.unfollowUser(userId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User unfollowed successfully'),
          backgroundColor: Colors.green,
        ),
      );
      await _loadRelationsUsers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to unfollow user'),
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
          'Followers & Following',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
            letterSpacing: 1.1,
          ),
        ),
        centerTitle: false,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.orange,
          labelColor: Colors.orange,
          unselectedLabelColor: Colors.white54,
          tabs: const [Tab(text: 'Following'), Tab(text: 'Followers')],
        ),
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Colors.amber),
              )
              : TabBarView(
                controller: _tabController,
                children: [
                  _buildUserList(
                    _following,
                    isFollowing: true,
                    emptyText: 'No following users',
                  ),
                  _buildUserList(
                    _followers,
                    isFollowing: false,
                    emptyText: 'No followers',
                  ),
                ],
              ),
    );
  }

  Widget _buildUserList(
    List<dynamic> users, {
    required bool isFollowing,
    required String emptyText,
  }) {
    if (users.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            emptyText,
            style: const TextStyle(color: Colors.white54, fontSize: 16),
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.only(top: 16),
      itemCount: users.length,
      separatorBuilder:
          (_, __) => const Divider(color: Colors.white12, height: 1),
      itemBuilder: (context, index) {
        final user = users[index];
        return _userTile(user, isFollowing: isFollowing);
      },
    );
  }

  Widget _userTile(dynamic user, {required bool isFollowing}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color.fromARGB(255, 41, 41, 41),
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
                              'https://server.bharathchat.com/${user['profile_pic']}',
                            ))
                        : null,
                child:
                    (user['profile_pic'] == null || user['profile_pic'].isEmpty)
                        ? Text(
                          ((user['first_name'] ?? user['username'] ?? 'U')
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
                  if (user['bio'] != null && (user['bio'] as String).isNotEmpty)
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
            if (isFollowing)
              Container(
                width: 90,
                height: 28,
                decoration: BoxDecoration(
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
                  onPressed: () => _unfollowUser(user['id']),
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
                    'Unfollow',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
