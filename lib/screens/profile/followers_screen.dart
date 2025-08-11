import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../chat/message_screen.dart';
import 'enhanced_user_profile_screen.dart';

class FollowersScreen extends StatefulWidget {
  final int userId;
  final String userName;

  const FollowersScreen({
    Key? key,
    required this.userId,
    required this.userName,
  }) : super(key: key);

  @override
  State<FollowersScreen> createState() => _FollowersScreenState();
}

class _FollowersScreenState extends State<FollowersScreen> {
  List<Map<String, dynamic>> _followers = [];
  bool _isLoading = true;
  Set<int> _following = {};
  Set<int> _blocked = {};

  @override
  void initState() {
    super.initState();
    _loadFollowersAndRelations();
  }

  Future<void> _loadFollowersAndRelations() async {
    setState(() {
      _isLoading = true;
    });
    try {
      // Load followers
      final followers = await ApiService.getUserFollowers(widget.userId);

      // Load current user's relations
      final currentUserId = ApiService.currentUserId;
      final relations = await ApiService.getUserSimpleRelations(currentUserId);

      setState(() {
        _followers = followers;
        _following = Set<int>.from(relations['following'] ?? []);
        _blocked = Set<int>.from(relations['blocked'] ?? []);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load followers: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  ImageProvider? _getProfileImage(String? profilePic) {
    if (profilePic != null && profilePic.isNotEmpty) {
      if (profilePic.startsWith('http')) {
        return NetworkImage(profilePic);
      } else {
        return NetworkImage('https://server.bharathchat.com/${profilePic}');
      }
    }
    return null;
  }

  String _getUserInitial(Map<String, dynamic> user) {
    if (user['first_name'] != null &&
        user['first_name'].toString().isNotEmpty) {
      return user['first_name'].toString().substring(0, 1).toUpperCase();
    } else if (user['username'] != null &&
        user['username'].toString().isNotEmpty) {
      return user['username'].toString().substring(0, 1).toUpperCase();
    }
    return 'U';
  }

  String _getFullName(Map<String, dynamic> user) {
    final firstName = user['first_name'] ?? '';
    final lastName = user['last_name'] ?? '';
    final username = user['username'] ?? '';

    if (firstName.toString().isNotEmpty && lastName.toString().isNotEmpty) {
      return '${firstName.toString().trim()} ${lastName.toString().trim()}';
    } else if (firstName.toString().isNotEmpty) {
      return firstName.toString().trim();
    } else if (username.toString().isNotEmpty) {
      return username.toString().trim();
    }
    return 'User';
  }

  void _followUser(int userId) async {
    try {
      if (_following.contains(userId)) {
        await ApiService.unfollowUser(userId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User unfollowed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        await ApiService.followUser(userId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User followed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
      await _loadFollowersAndRelations();
    } catch (e) {
      String errorMsg = 'Failed to follow/unfollow user';
      if (e is Exception && e.toString().contains('Exception:')) {
        errorMsg = e.toString().replaceFirst('Exception: ', '');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
      );
      await _loadFollowersAndRelations();
    }
  }

  void _blockUser(int userId) async {
    // If user is already blocked, unblock directly
    if (_blocked.contains(userId)) {
      try {
        await ApiService.unblockUser(userId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User unblocked successfully'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadFollowersAndRelations();
      } catch (e) {
        String errorMsg = 'Failed to unblock user';
        if (e is Exception && e.toString().contains('Exception:')) {
          errorMsg = e.toString().replaceFirst('Exception: ', '');
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
        );
        await _loadFollowersAndRelations();
      }
      return;
    }

    // Show confirmation dialog for blocking
    final shouldBlock = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF23272F),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Block User',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          content: const Text(
            'Are you sure you want to block this user?',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.grey,
                side: BorderSide(color: Colors.grey),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'Yes, Block',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );

    // If user confirmed blocking
    if (shouldBlock == true) {
      try {
        await ApiService.blockUser(userId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User blocked successfully'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadFollowersAndRelations();
      } catch (e) {
        String errorMsg = 'Failed to block user';
        if (e is Exception && e.toString().contains('Exception:')) {
          errorMsg = e.toString().replaceFirst('Exception: ', '');
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
        );
        await _loadFollowersAndRelations();
      }
    }
  }

  void _sendMessage(int userId, String userName, String? profilePic) async {
    try {
      await ApiService.sendMessage(userId, 'Say Hii!');
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => MessageScreen(
                userId: userId,
                userName: userName,
                profilePic: profilePic,
              ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to send "Say Hii!" message.'),
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
          'Followers',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Colors.amber),
              )
              : ListView.separated(
                itemCount: _followers.length,
                separatorBuilder:
                    (_, __) => const Divider(color: Colors.white12, height: 1),
                itemBuilder: (context, index) {
                  final user = _followers[index];
                  final isFollowing = _following.contains(user['id']);
                  final isBlocked = _blocked.contains(user['id']);
                  final fullName = _getFullName(user);

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        // Profile Picture
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => EnhancedUserProfileScreen(
                                      userId: user['id'],
                                      userName: fullName,
                                    ),
                              ),
                            ).then((_) {
                              // Refresh the list when returning from profile
                              _loadFollowersAndRelations();
                            });
                          },
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CircleAvatar(
                                radius: 28,
                                backgroundColor: Colors.grey[800],
                                backgroundImage: _getProfileImage(
                                  user['profile_pic'],
                                ),
                                child:
                                    _getProfileImage(user['profile_pic']) ==
                                            null
                                        ? Text(
                                          _getUserInitial(user),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 22,
                                          ),
                                        )
                                        : null,
                              ),
                              if (user['is_online'] == true)
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    width: 14,
                                    height: 14,
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),

                        // User Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                fullName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                ),
                              ),
                              if (user['bio'] != null &&
                                  user['bio'].toString().isNotEmpty)
                                Text(
                                  user['bio'],
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 13,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),

                        // Action Buttons
                        Row(
                          children: [
                            // Follow Button
                            Container(
                              width: 90,
                              height: 28,
                              decoration: BoxDecoration(
                                gradient:
                                    isFollowing
                                        ? null
                                        : const LinearGradient(
                                          colors: [
                                            Color(0xFFFF6B35),
                                            Color(0xFFFF8E53),
                                            Color(0xFFFFA726),
                                          ],
                                          begin: Alignment.centerLeft,
                                          end: Alignment.centerRight,
                                        ),
                                color: isFollowing ? Colors.transparent : null,
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: ElevatedButton(
                                onPressed: () => _followUser(user['id']),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  foregroundColor: Colors.white,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  elevation: 0,
                                  minimumSize: const Size(70, 24),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (!isFollowing) ...[
                                      const Icon(
                                        Icons.add,
                                        size: 12,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 3),
                                    ],
                                    if (isFollowing) ...[
                                      const Icon(
                                        Icons.check,
                                        size: 12,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 3),
                                    ],
                                    Text(
                                      isFollowing ? 'Following' : 'Follow',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(width: 8),

                            // More Options Menu
                            PopupMenuButton<String>(
                              icon: const Icon(
                                Icons.more_vert,
                                color: Colors.white,
                                size: 20,
                              ),
                              color: Colors.grey[800],
                              itemBuilder:
                                  (context) => [
                                    PopupMenuItem(
                                      value: 'view_profile',
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.person,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 8),
                                          const Text(
                                            'View Profile',
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'message',
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.message,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 8),
                                          const Text(
                                            'Message',
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'block',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.block,
                                            color:
                                                isBlocked
                                                    ? Colors.red
                                                    : Colors.white,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            isBlocked ? 'Unblock' : 'Block',
                                            style: TextStyle(
                                              color:
                                                  isBlocked
                                                      ? Colors.red
                                                      : Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                              onSelected: (value) {
                                switch (value) {
                                  case 'view_profile':
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) =>
                                                EnhancedUserProfileScreen(
                                                  userId: user['id'],
                                                  userName: fullName,
                                                ),
                                      ),
                                    ).then((_) {
                                      _loadFollowersAndRelations();
                                    });
                                    break;
                                  case 'message':
                                    _sendMessage(
                                      user['id'],
                                      fullName,
                                      user['profile_pic'],
                                    );
                                    break;
                                  case 'block':
                                    _blockUser(user['id']);
                                    break;
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
    );
  }
}
