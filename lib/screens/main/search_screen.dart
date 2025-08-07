import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../profile/enhanced_user_profile_screen.dart';
import 'dart:convert';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  List<dynamic> _users = [];
  bool _isLoading = true;
  String _searchQuery = '';
  Set<int> _following = {};
  Set<int> _blocked = {};

  @override
  void initState() {
    super.initState();
    _loadUsersAndRelations();
  }

  Future<void> _loadUsersAndRelations() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final users = await ApiService.getAllUsers();
      final currentUserId = ApiService.currentUserId;
      // Use the new /users/{user_id}/relations API
      final relations = await ApiService.getUserSimpleRelations(currentUserId);
      // relations['following'] and relations['blocked'] are lists of user IDs
      setState(() {
        _users = users.where((u) => u['id'] != currentUserId).toList();
        _following = Set<int>.from(relations['following'] ?? []);
        _blocked = Set<int>.from(relations['blocked'] ?? []);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
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
      await _loadUsersAndRelations();
    } catch (e) {
      String errorMsg = 'Failed to follow/unfollow user';
      if (e is Exception && e.toString().contains('Exception:')) {
        errorMsg = e.toString().replaceFirst('Exception: ', '');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
      );
      await _loadUsersAndRelations();
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
        await _loadUsersAndRelations();
      } catch (e) {
        String errorMsg = 'Failed to unblock user';
        if (e is Exception && e.toString().contains('Exception:')) {
          errorMsg = e.toString().replaceFirst('Exception: ', '');
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
        );
        await _loadUsersAndRelations();
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
        await _loadUsersAndRelations();
      } catch (e) {
        String errorMsg = 'Failed to block user';
        if (e is Exception && e.toString().contains('Exception:')) {
          errorMsg = e.toString().replaceFirst('Exception: ', '');
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
        );
        await _loadUsersAndRelations();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredUsers =
        _searchQuery.isEmpty
            ? _users
            : _users.where((user) {
              final name =
                  ((user['first_name'] ?? '') +
                          ' ' +
                          (user['last_name'] ?? '') +
                          ' ' +
                          (user['username'] ?? ''))
                      .toLowerCase();
              return name.contains(_searchQuery.toLowerCase());
            }).toList();
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
          'Search',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF23272F),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Search "Name"',
                  hintStyle: TextStyle(color: Colors.white54),
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.search, color: Colors.white54),
                ),
                onChanged: (val) => setState(() => _searchQuery = val),
              ),
            ),
          ),
          Expanded(
            child:
                _isLoading
                    ? const Center(
                      child: CircularProgressIndicator(color: Colors.amber),
                    )
                    : ListView.separated(
                      itemCount: filteredUsers.length,
                      separatorBuilder:
                          (_, __) =>
                              const Divider(color: Colors.white12, height: 1),
                      itemBuilder: (context, index) {
                        final user = filteredUsers[index];
                        final isFollowing = _following.contains(user['id']);
                        final isBlocked = _blocked.contains(user['id']);
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) =>
                                              EnhancedUserProfileScreen(
                                                userId: user['id'],
                                                userName:
                                                    user['first_name'] ??
                                                    user['username'] ??
                                                    'User',
                                              ),
                                    ),
                                  ).then((_) {
                                    // Refresh the search screen when returning from profile
                                    _loadUsersAndRelations();
                                  });
                                },
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    CircleAvatar(
                                      radius: 28,
                                      backgroundColor: Colors.grey[800],
                                      backgroundImage:
                                          (user['profile_pic'] != null &&
                                                  user['profile_pic']
                                                      .isNotEmpty)
                                              ? (user['profile_pic'].startsWith(
                                                    'http',
                                                  )
                                                  ? NetworkImage(
                                                    user['profile_pic'],
                                                  )
                                                  : NetworkImage(
                                                    'https://server.bharathchat.com/${user['profile_pic']}',
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
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
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
                                        if (user['verified'] == true)
                                          const Padding(
                                            padding: EdgeInsets.only(left: 4.0),
                                            child: Icon(
                                              Icons.verified,
                                              color: Colors.blue,
                                              size: 18,
                                            ),
                                          ),
                                        if (isBlocked)
                                          const Padding(
                                            padding: EdgeInsets.only(left: 4.0),
                                            child: Icon(
                                              Icons.block,
                                              color: Colors.red,
                                              size: 18,
                                            ),
                                          ),
                                      ],
                                    ),
                                    Text(
                                      'Diamonds: ${user['diamonds'] ?? 0}',
                                      style: const TextStyle(
                                        color: Colors.orange,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
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
                                    // if (user['phone_number'] != null)
                                    //   Text(
                                    //     'Phone: ${user['phone_number']}',
                                    //     style: const TextStyle(color: Colors.white54, fontSize: 13),
                                    //   ),
                                    // if (user['email'] != null)
                                    //   Text(
                                    //     'Email: ${user['email']}',
                                    //     style: const TextStyle(color: Colors.white54, fontSize: 13),
                                    //   ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(2.0),
                                    child: Container(
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
                                        color:
                                            isFollowing
                                                ? Colors.transparent
                                                : null,
                                        // border:
                                        //     isFollowing
                                        //         ? Border.all(
                                        //           color: Colors.grey,
                                        //           width: 1.0,
                                        //         )
                                        //         : null,
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      child: ElevatedButton(
                                        onPressed:
                                            () => _followUser(user['id']),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          foregroundColor:
                                              isFollowing
                                                  ? Colors.white
                                                  : Colors.white,
                                          shadowColor: Colors.transparent,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              15,
                                            ),
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
                                              isFollowing
                                                  ? 'Following'
                                                  : 'Follow',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 11,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  // const SizedBox(height: 6),
                                  // ElevatedButton(
                                  //   onPressed: () => _blockUser(user['id']),
                                  //   style: ElevatedButton.styleFrom(
                                  //     backgroundColor:
                                  //         isBlocked
                                  //             ? Colors.red
                                  //             : Colors.grey[700],
                                  //     foregroundColor: Colors.white,
                                  //     shape: RoundedRectangleBorder(
                                  //       borderRadius: BorderRadius.circular(22),
                                  //     ),
                                  //     padding: const EdgeInsets.symmetric(
                                  //       horizontal: 18,
                                  //       vertical: 0,
                                  //     ),
                                  //     elevation: 0,
                                  //     minimumSize: const Size(
                                  //       110,
                                  //       40,
                                  //     ), // Set same size
                                  //   ),
                                  //   child: Text(
                                  //     isBlocked ? 'Unblock' : 'Block',
                                  //     style: const TextStyle(
                                  //       fontWeight: FontWeight.bold,
                                  //       fontSize: 15,
                                  //     ),
                                  //   ),
                                  // ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
