// import 'package:flutter/material.dart';
// import 'dart:convert';
// import 'dart:async';
// import 'package:http/http.dart' as http;
// import '../../../services/api_service.dart';
// import 'package:zego_uikit_prebuilt_live_streaming/zego_uikit_prebuilt_live_streaming.dart';
// import 'package:flutter/cupertino.dart';

// class PKBattleButton extends StatelessWidget {
//   final VoidCallback? onPressed;
//   final ValueNotifier<String>? requestIDNotifier;
//   final ValueNotifier<Map<String, List<String>>>? requestingHostsMapRequestIDNotifier;

//   const PKBattleButton({
//     Key? key,
//     this.onPressed,
//     this.requestIDNotifier,
//     this.requestingHostsMapRequestIDNotifier,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           colors: [Color(0xFFffa030), Color(0xFFfe9b00), Color(0xFFf67d00)],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//         borderRadius: BorderRadius.circular(24),
//       ),
//       child: ElevatedButton(
//         onPressed: () {
//           showModalBottomSheet(
//             context: context,
//             isScrollControlled: true,
//             backgroundColor: Colors.transparent,
//             builder: (context) => PKBattleModal(
//               requestIDNotifier: requestIDNotifier,
//               requestingHostsMapRequestIDNotifier: requestingHostsMapRequestIDNotifier,
//             ),
//           );
//           if (onPressed != null) onPressed!();
//         },
//         style: ElevatedButton.styleFrom(
//           backgroundColor: Colors.transparent,
//           shadowColor: Colors.transparent,
//           padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(24),
//           ),
//         ),
//         child: const Text(
//           'PK Battle',
//           style: TextStyle(
//             color: Colors.white,
//             fontWeight: FontWeight.bold,
//             fontSize: 15,
//             letterSpacing: 1.1,
//           ),
//         ),
//       ),
//     );
//   }
// }

// class PKBattleModal extends StatefulWidget {
//   final ValueNotifier<String>? requestIDNotifier;
//   final ValueNotifier<Map<String, List<String>>>? requestingHostsMapRequestIDNotifier;

//   const PKBattleModal({
//     Key? key,
//     this.requestIDNotifier,
//     this.requestingHostsMapRequestIDNotifier,
//   }) : super(key: key);

//   @override
//   State<PKBattleModal> createState() => _PKBattleModalState();
// }

// class _PKBattleModalState extends State<PKBattleModal>
//     with SingleTickerProviderStateMixin {
//   late TabController _tabController;
//   final TextEditingController _searchController = TextEditingController();
//   List<Map<String, dynamic>> _users = [];
//   List<Map<String, dynamic>> _pkRequests = [];
//   List<Map<String, dynamic>> _liveStreams = [];
//   bool _loadingUsers = true;
//   bool _loadingRequests = true;
//   String? _userError;
//   String? _requestError;
//   String _searchQuery = '';
//   Set<int> _following = {};
//   Set<int> _blocked = {};
//   Map<int, int> _followersCounts = {};
//   Map<int, int> _followingCounts = {};
//   bool _isSendingRequest = false;
//   Timer? _countRefreshTimer;
//   Map<String, dynamic>? _currentUserData;

//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: 2, vsync: this);
//     _searchController.addListener(() {
//       setState(() {
//         _searchQuery = _searchController.text.trim().toLowerCase();
//       });
//     });
//     _fetchUsers();
//     _fetchLiveStreams();
//     _loadUserRelations();
//     _loadPkRequests();
//     _startCountRefreshTimer();
//     _loadCurrentUserData();
//   }

//   Future<void> _fetchLiveStreams() async {
//     try {
//       final streams = await ApiService.getLiveVideoStreams();
//       final now = DateTime.now();

//       // Filter for streams that are live within 3 minutes of created_at
//       final liveStreams = streams.where((stream) {
//         final createdAt = DateTime.parse(stream['created_at']);
//         final timeDifference = now.difference(createdAt).inMinutes;
//         return timeDifference <= 3; // Show streams created within last 3 minutes
//       }).toList();

//       // Reverse order so latest appears first
//       final reversedStreams = liveStreams.reversed.toList();

//       setState(() {
//         _liveStreams = reversedStreams;
//       });
//     } catch (e) {
//       print('Error fetching live streams: $e');
//     }
//   }

//   Future<void> _fetchUsers() async {
//     setState(() {
//       _loadingUsers = true;
//       _userError = null;
//     });
//     try {
//       final users = await ApiService.getAllUsers();
//       final currentUserId = ApiService.currentUserId;
//       setState(() {
//         _users = users.where((u) => u['id'] != currentUserId).map((u) => u as Map<String, dynamic>).toList();
//         _loadingUsers = false;
//       });
//     } catch (e) {
//       setState(() {
//         _userError = 'Error: $e';
//         _loadingUsers = false;
//       });
//     }
//   }

//   void _startCountRefreshTimer() {
//     _countRefreshTimer?.cancel();
//     _countRefreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
//       if (mounted) {
//         _refreshCountsOnly();
//         _fetchLiveStreams(); // Also refresh live streams every 5 seconds
//       }
//     });
//   }

//   Future<void> _loadCurrentUserData() async {
//     try {
//       final userData = await ApiService.getCurrentUser();
//       setState(() {
//         _currentUserData = userData;
//       });
//     } catch (e) {
//       print('Error loading current user data: $e');
//     }
//   }

//   Future<void> _loadPkRequests() async {
//     setState(() {
//       _loadingRequests = true;
//       _requestError = null;
//     });
//     try {
//       // For now, we'll use a placeholder. You can implement actual PK request loading here
//       setState(() {
//         _pkRequests = [];
//         _loadingRequests = false;
//       });
//     } catch (e) {
//       setState(() {
//         _requestError = 'Error: $e';
//         _loadingRequests = false;
//       });
//     }
//   }

//   Widget _buildProfileInitial() {
//     final displayName = _currentUserData != null
//         ? ((_currentUserData!['first_name'] ?? '') + ' ' + (_currentUserData!['last_name'] ?? '')).trim()
//         : 'U';
//     final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';

//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.grey[800],
//         shape: BoxShape.circle,
//       ),
//       child: Center(
//         child: Text(
//           initial,
//           style: const TextStyle(
//             color: Colors.white,
//             fontWeight: FontWeight.bold,
//             fontSize: 16,
//           ),
//         ),
//       ),
//     );
//   }

//   void _stopCountRefreshTimer() {
//     _countRefreshTimer?.cancel();
//     _countRefreshTimer = null;
//   }

//   Future<void> _refreshCountsOnly() async {
//     try {
//       final currentUserId = ApiService.currentUserId;

//       // Load followers and following counts for each user
//       Map<int, int> followersCounts = {};
//       Map<int, int> followingCounts = {};

//       for (var user in _users) {
//         if (user['id'] != currentUserId) {
//           try {
//             final followers = await ApiService.getUserFollowers(user['id']);
//             final following = await ApiService.getUserFollowing(user['id']);
//             followersCounts[user['id']] = followers.length;
//             followingCounts[user['id']] = following.length;
//           } catch (e) {
//             // If there's an error fetching counts, keep existing values
//             followersCounts[user['id']] = _followersCounts[user['id']] ?? 0;
//             followingCounts[user['id']] = _followingCounts[user['id']] ?? 0;
//           }
//         }
//       }

//       if (mounted) {
//         setState(() {
//           _followersCounts = followersCounts;
//           _followingCounts = followingCounts;
//         });
//       }
//     } catch (e) {
//       print('Error refreshing counts: $e');
//     }
//   }

//   Future<void> _loadUserRelations() async {
//     try {
//       final currentUserId = ApiService.currentUserId;
//       final relations = await ApiService.getUserSimpleRelations(currentUserId);

//       // Load followers and following counts for each user
//       Map<int, int> followersCounts = {};
//       Map<int, int> followingCounts = {};

//       for (var user in _users) {
//         if (user['id'] != currentUserId) {
//           try {
//             final followers = await ApiService.getUserFollowers(user['id']);
//             final following = await ApiService.getUserFollowing(user['id']);
//             followersCounts[user['id']] = followers.length;
//             followingCounts[user['id']] = following.length;
//           } catch (e) {
//             // If there's an error fetching counts, set to 0
//             followersCounts[user['id']] = 0;
//             followingCounts[user['id']] = 0;
//           }
//         }
//       }

//       setState(() {
//         _following = Set<int>.from(relations['following'] ?? []);
//         _blocked = Set<int>.from(relations['blocked'] ?? []);
//         _followersCounts = followersCounts;
//         _followingCounts = followingCounts;
//       });
//     } catch (e) {
//       print('Error loading user relations: $e');
//     }
//   }

//   void _followUser(int userId) async {
//     try {
//       if (_following.contains(userId)) {
//         await ApiService.unfollowUser(userId);
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('User unfollowed successfully'),
//             backgroundColor: Colors.green,
//           ),
//         );
//       } else {
//         await ApiService.followUser(userId);
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('User followed successfully'),
//             backgroundColor: Colors.green,
//           ),
//         );
//       }
//       await _loadUserRelations();
//     } catch (e) {
//       String errorMsg = 'Failed to follow/unfollow user';
//       if (e is Exception && e.toString().contains('Exception:')) {
//         errorMsg = e.toString().replaceFirst('Exception: ', '');
//       }
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
//       );
//       await _loadUserRelations();
//     }
//   }

//   Future<void> _sendPKBattleRequest(String userID, String username) async {
//     if (_isSendingRequest) return;

//     setState(() {
//       _isSendingRequest = true;
//     });

//     try {
//       await ZegoUIKitPrebuiltLiveStreamingController().pk
//           .sendRequest(
//             targetHostIDs: [userID],
//             isAutoAccept: false,
//           )
//           .then((ret) async {
//         if (ret.error != null) {
//           showDialog(
//             context: context,
//             builder: (context) {
//               return CupertinoAlertDialog(
//                 title: const Text('PK Battle Request Failed'),
//                 content: Text('Error: ${ret.error}'),
//                 actions: [
//                   CupertinoDialogAction(
//                     onPressed: Navigator.of(context).pop,
//                     child: const Text('OK'),
//                   ),
//                 ],
//               );
//             },
//           );
//         } else {
//           // Update notifiers if provided
//           if (widget.requestIDNotifier != null) {
//             widget.requestIDNotifier!.value = ret.requestID;
//           }

//           if (widget.requestingHostsMapRequestIDNotifier != null) {
//             if (widget.requestingHostsMapRequestIDNotifier!.value.containsKey(ret.requestID)) {
//               widget.requestingHostsMapRequestIDNotifier!.value[ret.requestID]!.add(userID);
//             } else {
//               widget.requestingHostsMapRequestIDNotifier!.value[ret.requestID] = [userID];
//             }
//             widget.requestingHostsMapRequestIDNotifier!.notifyListeners();
//           }

//           // Show success message
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text('PK Battle request sent to @$username'),
//               backgroundColor: Colors.green,
//             ),
//           );

//           // Close modal
//           Navigator.of(context).pop();
//         }
//       });
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Failed to send PK Battle request: $e'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     } finally {
//       setState(() {
//         _isSendingRequest = false;
//       });
//     }
//   }

//   void _blockUser(int userId) async {
//     // If user is already blocked, unblock directly
//     if (_blocked.contains(userId)) {
//       try {
//         await ApiService.unblockUser(userId);
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('User unblocked successfully'),
//             backgroundColor: Colors.green,
//           ),
//         );
//         // Only update blocked status, don't reload all counts
//         setState(() {
//           _blocked.remove(userId);
//         });
//       } catch (e) {
//         String errorMsg = 'Failed to unblock user';
//         if (e is Exception && e.toString().contains('Exception:')) {
//           errorMsg = e.toString().replaceFirst('Exception: ', '');
//         }
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
//         );
//       }
//       return;
//     }

//     // Show confirmation dialog for blocking
//     final shouldBlock = await showDialog<bool>(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           backgroundColor: const Color(0xFF23272F),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(16),
//           ),
//           title: const Text(
//             'Block User',
//             style: TextStyle(
//               color: Colors.white,
//               fontWeight: FontWeight.bold,
//               fontSize: 18,
//             ),
//           ),
//           content: const Text(
//             'Are you sure you want to block this user?',
//             style: TextStyle(color: Colors.white70, fontSize: 16),
//           ),
//           actions: [
//             TextButton(
//               style: TextButton.styleFrom(
//                 backgroundColor: Colors.transparent,
//                 foregroundColor: Colors.grey,
//                 side: BorderSide(color: Colors.grey),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//               ),
//               onPressed: () => Navigator.of(context).pop(false),
//               child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
//             ),
//             ElevatedButton(
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.red,
//                 foregroundColor: Colors.white,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//               ),
//               onPressed: () => Navigator.of(context).pop(true),
//               child: const Text(
//                 'Yes, Block',
//                 style: TextStyle(color: Colors.white),
//               ),
//             ),
//           ],
//         );
//       },
//     );

//     // If user confirmed blocking
//     if (shouldBlock == true) {
//       try {
//         await ApiService.blockUser(userId);

//         // Immediately update the blocked set and trigger UI refresh
//         setState(() {
//           _blocked.add(userId);
//         });

//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('User blocked successfully'),
//             backgroundColor: Colors.green,
//           ),
//         );

//         // Don't reload all relations - just keep the current counts
//       } catch (e) {
//         String errorMsg = 'Failed to block user';
//         if (e is Exception && e.toString().contains('Exception:')) {
//           errorMsg = e.toString().replaceFirst('Exception: ', '');
//         }
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
//         );
//       }
//     }
//   }

//   @override
//   void dispose() {
//     _stopCountRefreshTimer();
//     _tabController.dispose();
//     _searchController.dispose();
//     super.dispose();
//   }

//   List<Map<String, dynamic>> get _filteredUsers {
//     // Get user IDs of currently live users
//     final liveUserIds = _liveStreams.map((stream) => stream['user_id'] as int).toSet();

//     // First filter for only live users, then filter out blocked users
//     final liveUsers = _users.where((user) => liveUserIds.contains(user['id'])).toList();
//     final nonBlockedLiveUsers = liveUsers.where((user) => !_blocked.contains(user['id'])).toList();

//     // Then apply search filter
//     if (_searchQuery.isEmpty) return nonBlockedLiveUsers;
//     return nonBlockedLiveUsers.where((user) {
//       final name =
//           ((user['first_name'] ?? '') +
//                   ' ' +
//                   (user['last_name'] ?? '') +
//                   ' ' +
//                   (user['username'] ?? ''))
//               .toLowerCase();
//       return name.contains(_searchQuery);
//     }).toList();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       decoration: const BoxDecoration(
//         color: Color(0xFF232323),
//         borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
//       ),
//       padding: const EdgeInsets.only(top: 16, left: 0, right: 0, bottom: 0),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Container(
//             width: 40,
//             height: 4,
//             margin: const EdgeInsets.only(bottom: 12),
//             decoration: BoxDecoration(
//               color: Colors.grey[700],
//               borderRadius: BorderRadius.circular(2),
//             ),
//           ),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               // Profile Picture
//               Container(
//                 width: 32,
//                 height: 32,
//                 margin: const EdgeInsets.only(right: 12),
//                 decoration: BoxDecoration(
//                   shape: BoxShape.circle,
//                   border: Border.all(
//                     color: Color(0xFFffa030),
//                     width: 2,
//                   ),
//                 ),
//                 child: ClipOval(
//                   child: _currentUserData != null && _currentUserData!['profile_pic'] != null && _currentUserData!['profile_pic'].isNotEmpty
//                       ? (_currentUserData!['profile_pic'].startsWith('http')
//                           ? Image.network(
//                               _currentUserData!['profile_pic'],
//                               fit: BoxFit.cover,
//                               errorBuilder: (context, error, stackTrace) => _buildProfileInitial(),
//                             )
//                           : Image.network(
//                               'https://server.bharathchat.com/${_currentUserData!['profile_pic']}',
//                               fit: BoxFit.cover,
//                               errorBuilder: (context, error, stackTrace) => _buildProfileInitial(),
//                             ))
//                       : _buildProfileInitial(),
//                 ),
//               ),
//               // Title
//               const Text(
//                 'PK Battle',
//                 style: TextStyle(
//                   fontWeight: FontWeight.bold,
//                   fontSize: 20,
//                   color: Colors.white,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 8),
//           TabBar(
//             controller: _tabController,
//             indicatorColor: Color(0xFFffa030),
//             labelColor: Colors.white,
//             unselectedLabelColor: Colors.white70,
//             labelStyle: const TextStyle(
//               fontWeight: FontWeight.bold,
//               fontSize: 16,
//             ),
//             tabs: [
//               Tab(text: 'Invite'),
//               Tab(text: 'Requests'),
//             ],
//           ),
//           const SizedBox(height: 8),
//           Container(height: 2, color: Colors.grey[800]),
//           SizedBox(
//             height: 420,
//             child: TabBarView(
//               controller: _tabController,
//               children: [
//                 // Invite Tab
//                 Column(
//                   children: [
//                     Padding(
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 16,
//                         vertical: 12,
//                       ),
//                       child: TextField(
//                         controller: _searchController,
//                         style: const TextStyle(color: Colors.white),
//                         decoration: InputDecoration(
//                           hintText: 'Search live hosts...',
//                           hintStyle: const TextStyle(color: Colors.white54),
//                           prefixIcon: const Icon(
//                             Icons.search,
//                             color: Colors.white54,
//                           ),
//                           filled: true,
//                           fillColor: Colors.grey[900],
//                           contentPadding: const EdgeInsets.symmetric(
//                             vertical: 0,
//                             horizontal: 12,
//                           ),
//                           border: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(12),
//                             borderSide: BorderSide.none,
//                           ),
//                         ),
//                       ),
//                     ),
//                     Expanded(
//                       child:
//                           _loadingUsers
//                               ? const Center(child: CircularProgressIndicator())
//                               : _userError != null
//                               ? Center(
//                                 child: Text(
//                                   _userError!,
//                                   style: const TextStyle(color: Colors.red),
//                                 ),
//                               )
//                               : _filteredUsers.isEmpty
//                               ? Column(
//                                 mainAxisAlignment: MainAxisAlignment.center,
//                                 children: const [
//                                   Icon(
//                                     Icons.live_tv,
//                                     color: Colors.white38,
//                                     size: 64,
//                                   ),
//                                   SizedBox(height: 12),
//                                   Text(
//                                     'No live hosts found',
//                                     style: TextStyle(color: Colors.white70),
//                                   ),
//                                   SizedBox(height: 8),
//                                   Text(
//                                     'Only users who are currently live\nwill appear here',
//                                     style: TextStyle(color: Colors.white54, fontSize: 12),
//                                     textAlign: TextAlign.center,r
//                                   ),
//                                 ],
//                               )
//                               : ListView.separated(
//                                 padding: const EdgeInsets.symmetric(
//                                   horizontal: 16,
//                                 ),
//                                 itemCount: _filteredUsers.length,
//                                 separatorBuilder:
//                                     (_, __) => const SizedBox(height: 10),
//                                 itemBuilder: (context, index) {
//                                   final user = _filteredUsers[index];
//                                   final isFollowing = _following.contains(user['id']);
//                                   final isBlocked = _blocked.contains(user['id']);
//                                   final displayName =
//                                       ((user['first_name'] ?? '') +
//                                               ' ' +
//                                               (user['last_name'] ?? ''))
//                                           .trim()
//                                           .isNotEmpty
//                                       ? ((user['first_name'] ?? '') +
//                                               ' ' +
//                                               (user['last_name'] ?? ''))
//                                           .trim()
//                                       : (user['username'] ?? 'User');
//                                   return Container(
//                                     padding: const EdgeInsets.symmetric(
//                                       vertical: 10,
//                                       horizontal: 12,
//                                     ),
//                                     decoration: BoxDecoration(
//                                       color: Colors.grey[850],
//                                       borderRadius: BorderRadius.circular(12),
//                                     ),
//                                     child: Row(
//                                       children: [
//                                         Stack(
//                                           alignment: Alignment.center,
//                                           children: [
//                                             CircleAvatar(
//                                               radius: 24,
//                                               backgroundColor: Colors.grey[800],
//                                               backgroundImage:
//                                                   (user['profile_pic'] != null &&
//                                                           user['profile_pic']
//                                                               .isNotEmpty)
//                                                       ? (user['profile_pic'].startsWith(
//                                                             'http',
//                                                           )
//                                                           ? NetworkImage(
//                                                             user['profile_pic'],
//                                                           )
//                                                           : NetworkImage(
//                                                             'https://server.bharathchat.com/${user['profile_pic']}',
//                                                           ))
//                                                       : null,
//                                               child:
//                                                   (user['profile_pic'] == null ||
//                                                           user['profile_pic'].isEmpty)
//                                                       ? Text(
//                                                         displayName[0]
//                                                             .toUpperCase(),
//                                                         style: const TextStyle(
//                                                           color: Colors.white,
//                                                           fontWeight: FontWeight.bold,
//                                                           fontSize: 18,
//                                                         ),
//                                                       )
//                                                       : null,
//                                             ),
//                                             if (user['is_online'] == true)
//                                               Positioned(
//                                                 right: 0,
//                                                 bottom: 0,
//                                                 child: Container(
//                                                   width: 12,
//                                                   height: 12,
//                                                   decoration: BoxDecoration(
//                                                     color: Colors.green,
//                                                     shape: BoxShape.circle,
//                                                     border: Border.all(
//                                                       color: Colors.white,
//                                                       width: 2,
//                                                     ),
//                                                   ),
//                                                 ),
//                                               ),
//                                           ],
//                                         ),
//                                         const SizedBox(width: 12),
//                                         Expanded(
//                                           child: Column(
//                                             crossAxisAlignment:
//                                                 CrossAxisAlignment.start,
//                                             children: [
//                                               Row(
//                                                 children: [
//                                                   Text(
//                                                     displayName,
//                                                     style: const TextStyle(
//                                                       color: Colors.white,
//                                                       fontWeight: FontWeight.bold,
//                                                     ),
//                                                   ),
//                                                   if (user['verified'] == true)
//                                                     const Padding(
//                                                       padding: EdgeInsets.only(left: 4.0),
//                                                       child: Icon(
//                                                         Icons.verified,
//                                                         color: Colors.blue,
//                                                         size: 16,
//                                                       ),
//                                                     ),
//                                                   if (isBlocked)
//                                                     const Padding(
//                                                       padding: EdgeInsets.only(left: 4.0),
//                                                       child: Icon(
//                                                         Icons.block,
//                                                         color: Colors.red,
//                                                         size: 16,
//                                                       ),
//                                                     ),
//                                                 ],
//                                               ),
//                                               if (user['username'] != null)
//                                                 Text(
//                                                   '@${user['username']}',
//                                                   style: const TextStyle(
//                                                     color: Colors.white54,
//                                                     fontSize: 12,
//                                                   ),
//                                                 ),
//                                               Row(
//                                                 children: [
//                                                   Text(
//                                                     '${_followersCounts[user['id']] ?? 0}',
//                                                     style: const TextStyle(
//                                                       color: Colors.orange,
//                                                       fontSize: 10,
//                                                       fontWeight: FontWeight.bold,
//                                                     ),
//                                                   ),
//                                                   const Text(
//                                                     ' followers • ',
//                                                     style: TextStyle(
//                                                       color: Colors.white54,
//                                                       fontSize: 9,
//                                                     ),
//                                                   ),
//                                                   Text(
//                                                     '${_followingCounts[user['id']] ?? 0}',
//                                                     style: const TextStyle(
//                                                       color: Colors.orange,
//                                                       fontSize: 10,
//                                                       fontWeight: FontWeight.bold,
//                                                     ),
//                                                   ),
//                                                   const Text(
//                                                     ' following',
//                                                     style: TextStyle(
//                                                       color: Colors.white54,
//                                                       fontSize: 9,
//                                                     ),
//                                                   ),
//                                                 ],
//                                               ),
//                                             ],
//                                           ),
//                                         ),
//                                         Row(
//                                           mainAxisSize: MainAxisSize.min,
//                                           children: [
//                                             // Follow Button - Commented out
//                                             // Container(
//                                             //   width: 90,
//                                             //   height: 26,
//                                             //   decoration: BoxDecoration(
//                                             //     gradient:
//                                             //         isFollowing
//                                             //             ? null
//                                             //             : const LinearGradient(
//                                             //               colors: [
//                                             //                 Color(0xFFFF6B35),
//                                             //                 Color(0xFFFF8E53),
//                                             //                 Color(0xFFFFA726),
//                                             //               ],
//                                             //               begin: Alignment.centerLeft,
//                                             //               end: Alignment.centerRight,
//                                             //             ),
//                                             //     color:
//                                             //         isFollowing
//                                             //             ? Colors.transparent
//                                             //             : null,
//                                             //     borderRadius: BorderRadius.circular(13),
//                                             //   ),
//                                             //   child: ElevatedButton(
//                                             //     onPressed: () => _followUser(user['id']),
//                                             //     style: ElevatedButton.styleFrom(
//                                             //       backgroundColor: Colors.transparent,
//                                             //       foregroundColor: Colors.white,
//                                             //       shadowColor: Colors.transparent,
//                                             //       shape: RoundedRectangleBorder(
//                                             //         borderRadius: BorderRadius.circular(13),
//                                             //       ),
//                                             //       padding: const EdgeInsets.symmetric(
//                                             //         horizontal: 6,
//                                             //         vertical: 2,
//                                             //       ),
//                                             //       elevation: 0,
//                                             //       minimumSize: const Size(60, 22),
//                                             //     ),
//                                             //     child: Row(
//                                             //       mainAxisSize: MainAxisSize.min,
//                                             //       children: [
//                                             //         if (!isFollowing) ...[
//                                             //           const Icon(
//                                             //             Icons.add,
//                                             //             size: 9,
//                                             //             color: Colors.white,
//                                             //           ),
//                                             //           const SizedBox(width: 1),
//                                             //         ],
//                                             //         if (isFollowing) ...[
//                                             //           const Icon(
//                                             //             Icons.check,
//                                             //             size: 9,
//                                             //             color: Colors.white,
//                                             //           ),
//                                             //           const SizedBox(width: 1),
//                                             //         ],
//                                             //         Text(
//                                             //           isFollowing ? 'Following' : 'Follow',
//                                             //           style: TextStyle(
//                                             //             fontWeight: FontWeight.bold,
//                                             //             fontSize: 9,
//                                             //             color: Colors.white,
//                                             //           ),
//                                             //         ),
//                                             //       ],
//                                             //     ),
//                                             //   ),
//                                             // ),
//                                             // const SizedBox(height: 4),
//                                             // PK Battle Button - Increased width
//                                             Container(
//                                               width: 100, // Reduced width to fit in row
//                                               decoration: BoxDecoration(
//                                                 gradient: LinearGradient(
//                                                   colors: [Color(0xFFffa030), Color(0xFFfe9b00), Color(0xFFf67d00)],
//                                                   begin: Alignment.centerLeft,
//                                                   end: Alignment.centerRight,
//                                                 ),
//                                                 borderRadius: BorderRadius.circular(6),
//                                               ),
//                                               child: TextButton(
//                                                 onPressed: _isSendingRequest
//                                                     ? null
//                                                     : () => _sendPKBattleRequest('user_${user['id']}', user['username'] ?? 'User'),
//                                                 style: TextButton.styleFrom(
//                                                   padding: const EdgeInsets.symmetric(
//                                                     horizontal: 8, // Reduced horizontal padding
//                                                     vertical: 6,
//                                                   ),
//                                                 ),
//                                                 child: _isSendingRequest
//                                                     ? const SizedBox(
//                                                         width: 12,
//                                                         height: 12,
//                                                         child: CircularProgressIndicator(
//                                                           strokeWidth: 2,
//                                                           valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//                                                         ),
//                                                       )
//                                                     : const Text(
//                                                         'Battle',
//                                                         style: TextStyle(
//                                                           color: Colors.white,
//                                                           fontSize: 11, // Slightly reduced font size
//                                                           fontWeight: FontWeight.bold,
//                                                         ),
//                                                       ),
//                                               ),
//                                             ),
//                                             const SizedBox(width: 8), // Horizontal spacing between buttons
//                                             // Block Button
//                                             Container(
//                                               width: 60, // Reduced width for icon button
//                                               decoration: BoxDecoration(
//                                                 color: Colors.red[600],
//                                                 borderRadius: BorderRadius.circular(6),
//                                                 border: Border.all(
//                                                   color: Colors.red[700]!,
//                                                 ),
//                                               ),
//                                               child: TextButton(
//                                                 onPressed: () => _blockUser(user['id']),
//                                                 style: TextButton.styleFrom(
//                                                   padding: const EdgeInsets.symmetric(
//                                                     horizontal: 4,
//                                                     vertical: 6,
//                                                   ),
//                                                 ),
//                                                 child: const Icon(
//                                                   Icons.block,
//                                                   color: Colors.white,
//                                                   size: 16,
//                                                 ),
//                                               ),
//                                             ),
//                                           ],
//                                         ),
//                                       ],
//                                     ),
//                                   );
//                                 },
//                               ),
//                     ),
//                     const SizedBox(height: 8),
//                     const Padding(
//                       padding: EdgeInsets.symmetric(vertical: 8),
//                       child: Text(
//                         'Select a live host to start PK battle',
//                         style: TextStyle(color: Colors.white54, fontSize: 13),
//                       ),
//                     ),
//                   ],
//                 ),
//                 // Requests Tab
//                 Column(
//                   children: [
//                     _loadingRequests
//                         ? const Center(child: CircularProgressIndicator())
//                         : _requestError != null
//                         ? Center(
//                             child: Text(
//                               _requestError!,
//                               style: const TextStyle(color: Colors.red),
//                             ),
//                           )
//                         : _pkRequests.isEmpty
//                         ? const Center(
//                             child: Column(
//                               mainAxisAlignment: MainAxisAlignment.center,
//                               children: [
//                                 Icon(
//                                   Icons.inbox,
//                                   size: 64,
//                                   color: Colors.white54,
//                                 ),
//                                 SizedBox(height: 16),
//                                 Text(
//                                   'No Requests received',
//                                   style: TextStyle(
//                                     color: Colors.white54,
//                                     fontSize: 16,
//                                     fontWeight: FontWeight.w500,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           )
//                         : Expanded(
//                             child: ListView.builder(
//                               itemCount: _pkRequests.length,
//                               itemBuilder: (context, index) {
//                                 final request = _pkRequests[index];
//                                 return ListTile(
//                                   title: Text(
//                                     request['username'] ?? 'Unknown User',
//                                     style: const TextStyle(color: Colors.white),
//                                   ),
//                                   subtitle: Text(
//                                     'Request received',
//                                     style: const TextStyle(color: Colors.white54),
//                                   ),
//                                 );
//                               },
//                             ),
//                           ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../services/api_service.dart';

class PKBattleButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final void Function(String)? onInvite;
  const PKBattleButton({Key? key, this.onPressed, this.onInvite})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFffa030), Color(0xFFfe9b00), Color(0xFFf67d00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: ElevatedButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => PKBattleModal(onInvite: onInvite),
          );
          if (onPressed != null) onPressed!();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        child: const Text(
          'PK Battle',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 15,
            letterSpacing: 1.1,
          ),
        ),
      ),
    );
  }
}

class PKBattleModal extends StatefulWidget {
  final void Function(String)? onInvite;
  const PKBattleModal({Key? key, this.onInvite}) : super(key: key);

  @override
  State<PKBattleModal> createState() => _PKBattleModalState();
}

class _PKBattleModalState extends State<PKBattleModal>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _liveStreams = [];
  bool _loadingUsers = true;
  String? _userError;
  final List<Map<String, String>> _pkRequests = [
    {'name': 'Amit', 'followers': '2.1K'},
    {'name': 'Priya', 'followers': '1.2K'},
  ];
  String _searchQuery = '';
  Set<int> _following = {};
  Set<int> _blocked = {};
  Map<int, int> _followersCounts = {};
  Map<int, int> _followingCounts = {};
  Map<String, dynamic>? _currentUserData;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
    _loadUsersAndRelations();
    _fetchLiveStreams();
    _loadCurrentUserData();
  }

  Future<void> _loadUsersAndRelations() async {
    setState(() {
      _loadingUsers = true;
    });
    try {
      final users = await ApiService.getAllUsers();
      final currentUserId = ApiService.currentUserId;
      final relations = await ApiService.getUserSimpleRelations(currentUserId);

      // Load followers and following counts for each user
      Map<int, int> followersCounts = {};
      Map<int, int> followingCounts = {};

      for (var user in users) {
        if (user['id'] != currentUserId) {
          try {
            final followers = await ApiService.getUserFollowers(user['id']);
            final following = await ApiService.getUserFollowing(user['id']);
            followersCounts[user['id']] = followers.length;
            followingCounts[user['id']] = following.length;
          } catch (e) {
            // If there's an error fetching counts, set to 0
            followersCounts[user['id']] = 0;
            followingCounts[user['id']] = 0;
          }
        }
      }

      setState(() {
        _users =
            users
                .where((u) => u['id'] != currentUserId)
                .map((u) => u as Map<String, dynamic>)
                .toList();
        _following = Set<int>.from(relations['following'] ?? []);
        _blocked = Set<int>.from(relations['blocked'] ?? []);
        _followersCounts = followersCounts;
        _followingCounts = followingCounts;
        _loadingUsers = false;
      });
    } catch (e) {
      setState(() {
        _loadingUsers = false;
      });
    }
  }

  Future<void> _fetchLiveStreams() async {
    try {
      final response = await http.get(
        Uri.parse('https://server.bharathchat.com/go-live-video/'),
        headers: {'accept': 'application/json'},
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final now = DateTime.now();

        // Filter for streams that are live within 3 minutes of created_at
        final liveStreams =
            data.where((stream) {
              final createdAt = DateTime.parse(stream['created_at']);
              final timeDifference = now.difference(createdAt).inMinutes;
              return timeDifference <=
                  3; // Show streams created within last 3 minutes
            }).toList();

        // Reverse order so latest appears first
        final reversedStreams = liveStreams.reversed.toList();

        setState(() {
          _liveStreams =
              reversedStreams
                  .map((stream) => stream as Map<String, dynamic>)
                  .toList();
        });
      }
    } catch (e) {
      print('Error fetching live streams: $e');
    }
  }

  Future<void> _loadCurrentUserData() async {
    try {
      final userData = await ApiService.getCurrentUser();
      setState(() {
        _currentUserData = userData;
      });
    } catch (e) {
      print('Error loading current user data: $e');
    }
  }

  Widget _buildProfileInitial() {
    final displayName =
        _currentUserData != null
            ? ((_currentUserData!['first_name'] ?? '') +
                    ' ' +
                    (_currentUserData!['last_name'] ?? ''))
                .trim()
            : 'U';
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[800],
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
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
        // Only update blocked status, don't reload all counts
        setState(() {
          _blocked.remove(userId);
        });
      } catch (e) {
        String errorMsg = 'Failed to unblock user';
        if (e is Exception && e.toString().contains('Exception:')) {
          errorMsg = e.toString().replaceFirst('Exception: ', '');
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
        );
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

        // Immediately update the blocked set and trigger UI refresh
        setState(() {
          _blocked.add(userId);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User blocked successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        String errorMsg = 'Failed to block user';
        if (e is Exception && e.toString().contains('Exception:')) {
          errorMsg = e.toString().replaceFirst('Exception: ', '');
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredUsers {
    // Get user IDs of currently live users
    final liveUserIds =
        _liveStreams.map((stream) => stream['user_id'] as int).toSet();

    // First filter for only live users, then filter out blocked users
    final liveUsers =
        _users.where((user) => liveUserIds.contains(user['id'])).toList();
    final nonBlockedLiveUsers =
        liveUsers.where((user) => !_blocked.contains(user['id'])).toList();

    // Then apply search filter
    if (_searchQuery.isEmpty) return nonBlockedLiveUsers;
    return nonBlockedLiveUsers.where((user) {
      final name =
          (user['username'] ?? user['username'] ?? '').toString().toLowerCase();
      return name.contains(_searchQuery);
    }).toList();
  }

  List<Map<String, String>> get _filteredPKRequests {
    if (_searchQuery.isEmpty) return _pkRequests;
    return _pkRequests
        .where((req) => req['name']!.toLowerCase().contains(_searchQuery))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF232323),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.only(top: 16, left: 0, right: 0, bottom: 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.grey[700],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Profile Picture
              Container(
                width: 32,
                height: 32,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Color(0xFFffa030), width: 2),
                ),
                child: ClipOval(
                  child:
                      _currentUserData != null &&
                              _currentUserData!['profile_pic'] != null &&
                              _currentUserData!['profile_pic'].isNotEmpty
                          ? (_currentUserData!['profile_pic'].startsWith('http')
                              ? Image.network(
                                _currentUserData!['profile_pic'],
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (context, error, stackTrace) =>
                                        _buildProfileInitial(),
                              )
                              : Image.network(
                                'https://server.bharathchat.com/${_currentUserData!['profile_pic']}',
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (context, error, stackTrace) =>
                                        _buildProfileInitial(),
                              ))
                          : _buildProfileInitial(),
                ),
              ),
              // Title
              const Text(
                'PK Battle',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TabBar(
            controller: _tabController,
            indicatorColor: Color(0xFFffa030),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            tabs: [Tab(text: 'Invite')],
          ),
          const SizedBox(height: 8),
          Container(height: 2, color: Colors.grey[800]),
          SizedBox(
            height: 420,
            child: TabBarView(
              controller: _tabController,
              children: [
                // Invite Tab
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Search live hosts...',
                          hintStyle: const TextStyle(color: Colors.white54),
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Colors.white54,
                          ),
                          filled: true,
                          fillColor: Colors.grey[900],
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 0,
                            horizontal: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child:
                          _loadingUsers
                              ? const Center(child: CircularProgressIndicator())
                              : _userError != null
                              ? Center(
                                child: Text(
                                  _userError!,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              )
                              : _filteredUsers.isEmpty
                              ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(
                                    Icons.live_tv,
                                    color: Colors.white38,
                                    size: 64,
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    'No live hosts found',
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                ],
                              )
                              : ListView.separated(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                itemCount: _filteredUsers.length,
                                separatorBuilder:
                                    (_, __) => const SizedBox(height: 10),
                                itemBuilder: (context, index) {
                                  final user = _filteredUsers[index];
                                  final isBlocked = _blocked.contains(
                                    user['id'],
                                  );
                                  final displayName =
                                      ((user['first_name'] ?? '') +
                                                  ' ' +
                                                  (user['last_name'] ?? ''))
                                              .trim()
                                              .isNotEmpty
                                          ? ((user['first_name'] ?? '') +
                                                  ' ' +
                                                  (user['last_name'] ?? ''))
                                              .trim()
                                          : (user['username'] ?? 'User');
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                      horizontal: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[850],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            CircleAvatar(
                                              radius: 24,
                                              backgroundColor: Colors.grey[800],
                                              backgroundImage:
                                                  (user['profile_pic'] !=
                                                              null &&
                                                          user['profile_pic']
                                                              .isNotEmpty)
                                                      ? (user['profile_pic']
                                                              .startsWith(
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
                                                  (user['profile_pic'] ==
                                                              null ||
                                                          user['profile_pic']
                                                              .isEmpty)
                                                      ? Text(
                                                        displayName[0]
                                                            .toUpperCase(),
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 18,
                                                        ),
                                                      )
                                                      : null,
                                            ),
                                            if (user['is_online'] == true)
                                              Positioned(
                                                right: 0,
                                                bottom: 0,
                                                child: Container(
                                                  width: 12,
                                                  height: 12,
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
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Text(
                                                    displayName,
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  if (user['verified'] == true)
                                                    const Padding(
                                                      padding: EdgeInsets.only(
                                                        left: 4.0,
                                                      ),
                                                      child: Icon(
                                                        Icons.verified,
                                                        color: Colors.blue,
                                                        size: 16,
                                                      ),
                                                    ),
                                                  if (isBlocked)
                                                    const Padding(
                                                      padding: EdgeInsets.only(
                                                        left: 4.0,
                                                      ),
                                                      child: Icon(
                                                        Icons.block,
                                                        color: Colors.red,
                                                        size: 16,
                                                      ),
                                                    ),
                                                ],
                                              ),
                                              if (user['username'] != null)
                                                Text(
                                                  '@${user['username']}',
                                                  style: const TextStyle(
                                                    color: Colors.white54,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              Row(
                                                children: [
                                                  Text(
                                                    '${_followersCounts[user['id']] ?? 0}',
                                                    style: const TextStyle(
                                                      color: Colors.orange,
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  const Text(
                                                    ' followers • ',
                                                    style: TextStyle(
                                                      color: Colors.white54,
                                                      fontSize: 9,
                                                    ),
                                                  ),
                                                  Text(
                                                    '${_followingCounts[user['id']] ?? 0}',
                                                    style: const TextStyle(
                                                      color: Colors.orange,
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  const Text(
                                                    ' following',
                                                    style: TextStyle(
                                                      color: Colors.white54,
                                                      fontSize: 9,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            // Invite Button
                                            Container(
                                              width: 65,
                                              height: 33,
                                              decoration: BoxDecoration(
                                                color: Colors.grey[900],
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                border: Border.all(
                                                  color: Colors.grey[700]!,
                                                ),
                                              ),
                                              child: TextButton(
                                                onPressed: () {
                                                  if (widget.onInvite != null) {
                                                    // Pass username instead of displayName
                                                    final username =
                                                        user['username']
                                                            ?.toString() ??
                                                        '';
                                                    widget.onInvite!(username);
                                                    Navigator.of(context).pop();
                                                  }
                                                },
                                                child: const Text(
                                                  'Invite',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(
                                              width: 4,
                                            ), // Horizontal spacing between buttons
                                            // Block Button
                                            Container(
                                              width: 65,
                                              height: 33,
                                              // Reduced width for icon button
                                              decoration: BoxDecoration(
                                                color: Colors.red[600],
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                border: Border.all(
                                                  color: Colors.red[700]!,
                                                ),
                                              ),
                                              child: TextButton(
                                                onPressed:
                                                    () =>
                                                        _blockUser(user['id']),
                                                style: TextButton.styleFrom(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 4,
                                                        vertical: 6,
                                                      ),
                                                ),
                                                child: const Icon(
                                                  Icons.block,
                                                  color: Colors.white,
                                                  size: 16,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                    ),
                    const SizedBox(height: 8),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Select a live host to start PK battle',
                        style: TextStyle(color: Colors.white54, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
