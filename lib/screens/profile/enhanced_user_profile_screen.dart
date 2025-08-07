import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../chat/message_screen.dart';
import 'followers_screen.dart';
import 'following_screen.dart';
import 'dart:convert';

class EnhancedUserProfileScreen extends StatefulWidget {
  final int userId;
  final String userName;

  const EnhancedUserProfileScreen({
    Key? key,
    required this.userId,
    required this.userName,
  }) : super(key: key);

  @override
  State<EnhancedUserProfileScreen> createState() =>
      _EnhancedUserProfileScreenState();
}

class _EnhancedUserProfileScreenState extends State<EnhancedUserProfileScreen> {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  Set<int> _following = {};
  Set<int> _blocked = {};
  bool _isSendingHi = false;
  int _followersCount = 0;
  int _followingCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUserDataAndRelations();
  }

  Future<void> _loadUserDataAndRelations() async {
    setState(() {
      _isLoading = true;
    });
    try {
      // Load user data
      final users = await ApiService.getAllUsers();
      final user = users.firstWhere((u) => u['id'] == widget.userId);

      // Load current user's relations
      final currentUserId = ApiService.currentUserId;
      final relations = await ApiService.getUserSimpleRelations(currentUserId);

      // Load followers and following counts
      final followers = await ApiService.getUserFollowers(widget.userId);
      final following = await ApiService.getUserFollowing(widget.userId);

      setState(() {
        _userData = user;
        _following = Set<int>.from(relations['following'] ?? []);
        _blocked = Set<int>.from(relations['blocked'] ?? []);
        _followersCount = followers.length;
        _followingCount = following.length;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  ImageProvider? _getProfileImage() {
    if (_userData?['profile_pic'] != null &&
        _userData!['profile_pic'].toString().isNotEmpty) {
      final profilePic = _userData!['profile_pic'].toString();
      if (profilePic.startsWith('http')) {
        return NetworkImage(profilePic);
      } else {
        return NetworkImage('https://server.bharathchat.com/${profilePic}');
      }
    }
    return null;
  }

  String? _getProfilePicUrl() {
    if (_userData?['profile_pic'] != null &&
        _userData!['profile_pic'].toString().isNotEmpty) {
      final profilePic = _userData!['profile_pic'].toString();
      if (profilePic.startsWith('http')) {
        return profilePic;
      } else {
        return 'https://server.bharathchat.com/${profilePic}';
      }
    }
    return null;
  }

  String _getUserInitial() {
    if (_userData?['first_name'] != null &&
        _userData!['first_name'].toString().isNotEmpty) {
      return _userData!['first_name'].toString().substring(0, 1).toUpperCase();
    }
    return 'U';
  }

  String _getFullName() {
    final firstName = _userData?['first_name'] ?? '';
    final lastName = _userData?['last_name'] ?? '';
    final username = _userData?['username'] ?? '';

    // If both first and last name exist, combine them
    if (firstName.toString().isNotEmpty && lastName.toString().isNotEmpty) {
      return '${firstName.toString().trim()} ${lastName.toString().trim()}';
    }
    // If only first name exists
    else if (firstName.toString().isNotEmpty) {
      return firstName.toString().trim();
    }
    // If only username exists
    else if (username.toString().isNotEmpty) {
      return username.toString().trim();
    }
    // Fallback to widget userName
    return widget.userName;
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
      await _loadUserDataAndRelations();
    } catch (e) {
      String errorMsg = 'Failed to follow/unfollow user';
      if (e is Exception && e.toString().contains('Exception:')) {
        errorMsg = e.toString().replaceFirst('Exception: ', '');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
      );
      await _loadUserDataAndRelations();
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
        await _loadUserDataAndRelations();
      } catch (e) {
        String errorMsg = 'Failed to unblock user';
        if (e is Exception && e.toString().contains('Exception:')) {
          errorMsg = e.toString().replaceFirst('Exception: ', '');
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
        );
        await _loadUserDataAndRelations();
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
        await _loadUserDataAndRelations();
      } catch (e) {
        String errorMsg = 'Failed to block user';
        if (e is Exception && e.toString().contains('Exception:')) {
          errorMsg = e.toString().replaceFirst('Exception: ', '');
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
        );
        await _loadUserDataAndRelations();
      }
    }
  }

  void _sendHiMessage() async {
    setState(() {
      _isSendingHi = true;
    });
    try {
      await ApiService.sendMessage(widget.userId, 'Say Hii!');
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => MessageScreen(
                userId: widget.userId,
                userName: _getFullName(),
                profilePic: _getProfilePicUrl(),
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
    } finally {
      setState(() {
        _isSendingHi = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF181A20),
        body: const Center(
          child: CircularProgressIndicator(color: Colors.amber),
        ),
      );
    }

    final isFollowing = _following.contains(widget.userId);
    final isBlocked = _blocked.contains(widget.userId);

    return Scaffold(
      backgroundColor: const Color(0xFF181A20),
      body: CustomScrollView(
        slivers: [
          // App Bar with background image
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: const Color(0xFF181A20),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              // IconButton(
              //   icon: const Icon(Icons.share, color: Colors.white),
              //   onPressed: () {
              //     // Share functionality
              //   },
              // ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                color: Colors.white,
                itemBuilder:
                    (context) => [
                      // PopupMenuItem(
                      //   value: 'report',
                      //   child: const Text(
                      //     'Report',
                      //     style: TextStyle(color: Colors.black),
                      //   ),
                      // ),
                      PopupMenuItem(
                        value: 'block',
                        child: Text(
                          isBlocked ? 'Unblock' : 'Block',
                          style: TextStyle(
                            color: isBlocked ? Colors.red : Colors.black,
                          ),
                        ),
                      ),
                    ],
                onSelected: (value) {
                  if (value == 'report') {
                    // Report functionality
                  } else if (value == 'block') {
                    _blockUser(widget.userId);
                  }
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Background image (using profile pic as background)
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.blue.withOpacity(0.8),
                          Colors.purple.withOpacity(0.6),
                        ],
                      ),
                    ),
                    child:
                        _getProfileImage() != null
                            ? Image(
                              image: _getProfileImage()!,
                              fit: BoxFit.cover,
                            )
                            : Container(color: Colors.grey[800]),
                  ),
                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Profile content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),

                  // Blocked user indicator
                  if (isBlocked)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red, width: 1),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.block, color: Colors.red, size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'This user is blocked',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (isBlocked) const SizedBox(height: 16),

                  // User name with star icon
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        _getFullName(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Live time
                  // if (_userData?['live_time'] != null)
                  //   Text(
                  //     'Live time :- ${_userData?['live_time']}',
                  //     style: const TextStyle(
                  //       color: Colors.white70,
                  //       fontSize: 14,
                  //     ),
                  //   ),
                  // const SizedBox(height: 8),

                  // Instagram link
                  // if (_userData?['instagram'] != null)
                  // Row(
                  //   children: [
                  //     const Icon(
                  //       Icons.camera_alt,
                  //       color: Colors.white,
                  //       size: 16,
                  //     ),
                  //     const SizedBox(width: 4),
                  //     Text(
                  //       _userData?['instagram'] ?? 'no',
                  //       style: const TextStyle(
                  //         color: Colors.white70,
                  //         fontSize: 14,
                  //       ),
                  //     ),
                  //   ],
                  // ),
                  const SizedBox(height: 16),
                  const SizedBox(height: 16),

                  // Followers and Following stats
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => FollowersScreen(
                                      userId: widget.userId,
                                      userName: _getFullName(),
                                    ),
                              ),
                            ).then((_) {
                              // Refresh the profile when returning from followers screen
                              _loadUserDataAndRelations();
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[800],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  '$_followersCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Text(
                                  'Followers',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => FollowingScreen(
                                      userId: widget.userId,
                                      userName: _getFullName(),
                                    ),
                              ),
                            ).then((_) {
                              // Refresh the profile when returning from following screen
                              _loadUserDataAndRelations();
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[800],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  '$_followingCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Text(
                                  'Following',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Action buttons
                  Row(
                    children: [
                      // Message button
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                isBlocked ? Colors.grey : Colors.white,
                            foregroundColor:
                                isBlocked ? Colors.grey[600] : Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: isBlocked ? null : _sendHiMessage,
                          child:
                              _isSendingHi
                                  ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.black,
                                      ),
                                    ),
                                  )
                                  : const Text(
                                    'Message',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Follow button
                      Expanded(
                        child: Container(
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
                            border:
                                isFollowing
                                    ? Border.all(color: Colors.grey, width: 1.0)
                                    : null,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor:
                                  isBlocked ? Colors.grey[600] : Colors.white,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed:
                                isBlocked
                                    ? null
                                    : () => _followUser(widget.userId),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (!isFollowing) ...[
                                  const Icon(Icons.add, size: 16),
                                  const SizedBox(width: 4),
                                ],
                                if (isFollowing) ...[
                                  const Icon(Icons.check, size: 16),
                                  const SizedBox(width: 4),
                                ],
                                Text(
                                  isFollowing ? 'Following' : 'Follow',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
