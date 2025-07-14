import 'package:flutter/material.dart';
import 'dart:convert';
import '../../services/api_service.dart';
import '../chat/message_screen.dart';
import '../profile/user_profile_screen.dart';
import 'invite_screen.dart';
import 'blocked_users_screen.dart';
import 'main_screen.dart';
import 'search_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with SingleTickerProviderStateMixin {
  List<dynamic> _conversations = [];
  List<dynamic> _allUsers = [];
  bool _isLoading = true;
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  List<dynamic> get _filteredUsers {
    if (_searchQuery.isEmpty) return _allUsers;
    return _allUsers.where((user) {
      final name = (user['first_name'] ?? '').toLowerCase();
      return name.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  List<dynamic> get _filteredConversations {
    if (_searchQuery.isEmpty) return _conversations;
    return _conversations.where((conv) {
      final name = (conv['user']['first_name'] ?? '').toLowerCase();
      return name.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  void _loadData() async {
    try {
      final conversations = await ApiService.getConversations();
      final allUsers = await ApiService.getAllUsers();
      setState(() {
        _conversations = conversations;
        _allUsers = allUsers;
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
      final user = _allUsers.firstWhere((u) => u['id'] == userId);
      final isFollowing = user['is_following'] == true;

      if (isFollowing) {
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
      _loadData(); // Reload data to update UI
    } catch (e) {
      final user = _allUsers.firstWhere(
        (u) => u['id'] == userId,
        orElse: () => {'is_following': false},
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to ${user['is_following'] == true ? 'unfollow' : 'follow'} user',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _blockUser(int userId) async {
    final user = _allUsers.firstWhere((u) => u['id'] == userId);
    final userName = user['first_name'] ?? 'User ${user['id']}';

    // Show confirmation dialog
    final shouldBlock = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Block User'),
            content: Text('Are you sure you want to block $userName?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Block'),
              ),
            ],
          ),
    );

    if (shouldBlock == true) {
      try {
        await ApiService.blockUser(userId);
        _loadData(); // Reload data to update UI
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
    }
  }

  ImageProvider? _getProfileImage(String? profilePic) {
    if (profilePic != null && profilePic.isNotEmpty) {
      try {
        return MemoryImage(base64Decode(profilePic));
      } catch (e) {
        print('Error decoding profile image: $e');
        return null;
      }
    }
    return null;
  }

  Widget _buildUserTile(dynamic user) {
    // For conversations tab
    if (user['last_message'] != null) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange),
        ),
        child: ListTile(
          leading: CircleAvatar(
            radius: 25,
            backgroundColor: Colors.grey[800],
            backgroundImage: _getProfileImage(user['user']['profile_pic']),
            child:
                _getProfileImage(user['user']['profile_pic']) == null
                    ? Text(
                      (user['user']['first_name'] ?? 'U')
                          .substring(0, 1)
                          .toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                    : null,
          ),
          title: Text(
            user['user']['first_name'] ?? 'User ${user['user']['id']}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color:
                          user['user']['is_online'] == true
                              ? Colors.green
                              : Colors.grey,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    user['user']['is_online'] == true ? 'Online' : 'Offline',
                    style: TextStyle(
                      color:
                          user['user']['is_online'] == true
                              ? Colors.green
                              : Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                user['last_message']['message'],
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color:
                      user['last_message']['is_read']
                          ? Colors.grey
                          : Colors.white,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatTimestamp(user['last_message']['timestamp']),
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              if (!user['last_message']['is_read'] &&
                  !user['last_message']['is_sender'])
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.orange,
                    // gradient: LinearGradient(
                    //   colors: [
                    //     Color(0xFFffa030),
                    //     Color(0xFFfe9b00),
                    //     Color(0xFFf67d00),
                    //   ],
                    //   begin: Alignment.centerLeft,
                    //   end: Alignment.centerRight,
                    // ),
                    shape: BoxShape.circle,
                  ),
                  child: const Text(
                    '1',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => MessageScreen(
                      userId: user['user']['id'],
                      userName:
                          user['user']['first_name'] ??
                          'User ${user['user']['id']}',
                      profilePic: user['user']['profile_pic'],
                    ),
              ),
            ).then(
              (_) => _loadData(),
            ); // Reload data when returning from message screen
          },
        ),
      );
    }

    // For all users tab
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange),
      ),
      child: ListTile(
        leading: CircleAvatar(
          radius: 25,
          backgroundColor: Colors.grey[800],
          backgroundImage: _getProfileImage(user['profile_pic']),
          child:
              _getProfileImage(user['profile_pic']) == null
                  ? Text(
                    (user['first_name'] ?? 'U').substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                  : null,
        ),
        title: Text(
          user['first_name'] ?? 'User ${user['id']}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: user['is_online'] == true ? Colors.green : Colors.grey,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              user['is_online'] == true ? 'Online' : 'Offline',
              style: TextStyle(
                color: user['is_online'] == true ? Colors.green : Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                user['is_following'] == true
                    ? Icons.person_remove
                    : Icons.person_add,
                color:
                    user['is_following'] == true ? Colors.red : Colors.orange,
              ),
              onPressed: () => _followUser(user['id']),
            ),
            IconButton(
              icon: const Icon(Icons.block, color: Colors.red),
              onPressed: () => _blockUser(user['id']),
            ),
            IconButton(
              icon: const Icon(Icons.message, color: Colors.orange),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => MessageScreen(
                          userId: user['id'],
                          userName: user['first_name'] ?? 'User ${user['id']}',
                          profilePic: user['profile_pic'],
                        ),
                  ),
                ).then(
                  (_) => _loadData(),
                ); // Reload data when returning from message screen
              },
            ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => UserProfileScreen(
                    userId: user['id'],
                    userName: user['first_name'] ?? 'User ${user['id']}',
                  ),
            ),
          );
        },
      ),
    );
  }

  String _formatTimestamp(String timestamp) {
    try {
      final date = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 0) {
        return '${difference.inDays}d';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m';
      } else {
        return 'now';
      }
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF181C23),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MainScreen(),
                        ),
                      );
                    },
                  ),
                  const Text(
                    'Chat',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                  const Spacer(),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 0,
                      ),
                    ),
                    icon: const Icon(
                      Icons.person_add_alt,
                      color: Colors.white,
                      size: 18,
                    ),
                    label: const Text(
                      'Invite',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const InviteScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.more_vert, color: Colors.white),
                    onPressed: () async {
                      final result = await showMenu(
                        context: context,
                        position: const RelativeRect.fromLTRB(1000, 80, 16, 0),
                        items: [
                          PopupMenuItem(
                            value: 'blocked',
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF23272F),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.block,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Blocked Chats',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                        elevation: 8,
                        color: Colors.transparent,
                      );
                      if (result == 'blocked') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const BlockedUsersScreen(),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SearchScreen(),
                    ),
                  );
                },
                child: AbsorbPointer(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF23272F),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white),
                      readOnly: true,
                      decoration: const InputDecoration(
                        hintText: 'Search',
                        hintStyle: TextStyle(color: Colors.white54),
                        border: InputBorder.none,
                        prefixIcon: Icon(Icons.search, color: Colors.white54),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Start a conversation (Horizontal Scroll)
            Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 8),
              child: const Text(
                'Start a conversation',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
            ),
            SizedBox(
              height: 200,
              child:
                  _isLoading
                      ? const Center(
                        child: CircularProgressIndicator(color: Colors.orange),
                      )
                      : ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount:
                            _filteredUsers.length > 10
                                ? 10
                                : _filteredUsers.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final user = _filteredUsers[index];
                          return Container(
                            width: 120,
                            decoration: BoxDecoration(
                              color: const Color(0xFF23272F),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Stack(
                                  children: [
                                    CircleAvatar(
                                      radius: 50,
                                      backgroundColor: Colors.grey[800],
                                      backgroundImage: _getProfileImage(
                                        user['profile_pic'],
                                      ),
                                      child:
                                          _getProfileImage(
                                                    user['profile_pic'],
                                                  ) ==
                                                  null
                                              ? Text(
                                                (user['first_name'] ?? 'U')
                                                    .substring(0, 1)
                                                    .toUpperCase(),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
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
                                const SizedBox(height: 8),
                                Text(
                                  user['first_name'] ?? 'User',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    textStyle: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  onPressed: () {
                                    // Say Hi action
                                  },
                                  child: const Text('Say Hi!'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
            ),
            const SizedBox(height: 12),
            // Tabs (Message & Friend Requests)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        _tabController.index = 0;
                        setState(() {});
                      },
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Message',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  // color: Colors.purple,
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0xFFffa030),
                                      Color(0xFFfe9b00),
                                      Color(0xFFf67d00),
                                    ],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _filteredConversations.length.toString(),
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Container(
                            height: 3,
                            margin: const EdgeInsets.only(top: 6),
                            decoration:
                                _tabController.index == 0
                                    ? BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Color(0xFFffa030),
                                          Color(0xFFfe9b00),
                                          Color(0xFFf67d00),
                                        ],
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    )
                                    : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Expanded(
                  //   child: GestureDetector(
                  //     onTap: () {
                  //       _tabController.index = 1;
                  //       setState(() {});
                  //     },
                  //     child: Column(
                  //       children: [
                  //         Row(
                  //           mainAxisAlignment: MainAxisAlignment.center,
                  //           children: [
                  //             const Text('Friend Requests', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                  //             const SizedBox(width: 6),
                  //             Container(
                  //               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  //               decoration: BoxDecoration(
                  //                 color: Colors.amber,
                  //                 borderRadius: BorderRadius.circular(12),
                  //               ),
                  //               child: const Text(
                  //                 '61', // Replace with actual friend request count
                  //                 style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14),
                  //               ),
                  //             ),
                  //           ],
                  //         ),
                  //         Container(
                  //           height: 3,
                  //           margin: const EdgeInsets.only(top: 6),
                  //           color: _tabController.index == 1 ? Colors.amber : Colors.transparent,
                  //         ),
                  //       ],
                  //     ),
                  //   ),
                  // ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Message List or Friend Requests
            Expanded(
              child:
                  _isLoading
                      ? const Center(
                        child: CircularProgressIndicator(color: Colors.orange),
                      )
                      : _tabController.index == 0
                      ? ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 0),
                        itemCount: _filteredConversations.length,
                        itemBuilder: (context, index) {
                          final user = _filteredConversations[index];
                          final u = user['user'];
                          return Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF23272F),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                radius: 26,
                                backgroundColor: Colors.grey[800],
                                backgroundImage: _getProfileImage(
                                  u['profile_pic'],
                                ),
                                child:
                                    _getProfileImage(u['profile_pic']) == null
                                        ? Text(
                                          (u['first_name'] ?? 'U')
                                              .substring(0, 1)
                                              .toUpperCase(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                        : null,
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      u['first_name'] ?? 'User',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  // Container(
                                  //   padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  //   decoration: BoxDecoration(
                                  //     color: const Color(0xFF23272F),
                                  //     borderRadius: BorderRadius.circular(8),
                                  //     border: Border.all(color: Colors.white24),
                                  //   ),
                                  //   child: Row(
                                  //     children: [
                                  //       const Icon(Icons.shield, color: Colors.blueAccent, size: 16),
                                  //       const SizedBox(width: 2),
                                  //       Text(
                                  //         'Lv.${u['level'] ?? 1}',
                                  //         style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                  //       ),
                                  //     ],
                                  //   ),
                                  // ),
                                ],
                              ),
                              subtitle: Text(
                                user['last_message']['message'],
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 15,
                                ),
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    _formatTimestamp(
                                      user['last_message']['timestamp'],
                                    ),
                                    style: const TextStyle(
                                      color: Colors.white38,
                                      fontSize: 13,
                                    ),
                                  ),
                                  // Add unread indicator if needed
                                ],
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => MessageScreen(
                                          userId: u['id'],
                                          userName: u['first_name'] ?? 'User',
                                          profilePic: u['profile_pic'],
                                        ),
                                  ),
                                ).then((_) => _loadData());
                              },
                            ),
                          );
                        },
                      )
                      : Center(
                        child: Text(
                          'No friend requests',
                          style: TextStyle(color: Colors.white54, fontSize: 16),
                        ),
                      ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}

class UserSearchDelegate extends SearchDelegate {
  final List<dynamic> users;

  UserSearchDelegate(this.users);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    final filteredUsers =
        users.where((user) {
          final name = (user['first_name'] ?? '').toLowerCase();
          return name.contains(query.toLowerCase());
        }).toList();

    return ListView.builder(
      itemCount: filteredUsers.length,
      itemBuilder: (context, index) {
        final user = filteredUsers[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.orange,
            child: Text(
              (user['first_name'] ?? 'U').substring(0, 1).toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text(
            user['first_name'] ?? 'User ${user['id']}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => UserProfileScreen(
                      userId: user['id'],
                      userName: user['first_name'] ?? 'User ${user['id']}',
                    ),
              ),
            );
          },
        );
      },
    );
  }
}
