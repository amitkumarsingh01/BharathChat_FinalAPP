// import 'package:flutter/material.dart';
// import 'package:zego_uikit_prebuilt_live_streaming/zego_uikit_prebuilt_live_streaming.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:just_audio/just_audio.dart';
// import 'gift_panel.dart';
// import 'gift_animation.dart';
// import '../../services/api_service.dart';
// import '../../services/live_stream_service.dart';
// import 'package:finalchat/pk_widgets/config.dart';
// import 'package:finalchat/pk_widgets/events.dart';
// import 'package:finalchat/pk_widgets/surface.dart';
// import 'package:finalchat/pk_widgets/widgets/mute_button.dart';
// import 'package:finalchat/common.dart';
// import 'package:finalchat/constants.dart';
// import 'live_page.dart';
// import 'dart:async';
// import 'dart:convert';
// import 'dart:math';
// import 'package:finalchat/screens/main/store_screen.dart';
// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:zego_uikit/zego_uikit.dart';

// class LiveAudioScreen extends StatefulWidget {
//   final String liveID;
//   final String localUserID;
//   final bool isHost;
//   final int hostId;
//   final String? backgroundImage;
//   final String? backgroundMusic;
//   final String? profilePic;

//   const LiveAudioScreen({
//     Key? key,
//     required this.liveID,
//     required this.localUserID,
//     required this.hostId,
//     this.isHost = false,
//     this.backgroundImage,
//     this.backgroundMusic,
//     this.profilePic,
//   }) : super(key: key);

//   @override
//   State<LiveAudioScreen> createState() => _LiveAudioScreenState();
// }

// class _LiveAudioScreenState extends State<LiveAudioScreen>
//     with SingleTickerProviderStateMixin {
//   final _audioPlayer = AudioPlayer();
//   bool _isPlaying = false;
//   final int appID = 615877954; // Your ZEGOCLOUD AppID
//   final String appSign =
//       "12e07321bd8231dda371ea9235e274178403bd97a7ccabcb09e22474c42da3a4"; // Your ZEGOCLOUD AppSign

//   // Gift panel state
//   bool showGiftPanel = false;
//   List<Map<String, dynamic>> giftAnimations = [];

//   Map<String, dynamic>? currentUser;
//   Map<String, dynamic>? hostUser;
//   final LiveStreamService _liveStreamService = LiveStreamService();
//   List<dynamic> _zegoUsers = [];
//   Map<String, dynamic> _userProfiles = {};
//   StreamSubscription? _userListSub;
//   List<dynamic> _allUsers = [];

//   // Like animation state
//   late AnimationController _likeController;
//   late Animation<double> _likeScale;
//   bool _showLike = false;
//   List<Widget> _burstHearts = [];
//   int _burstKey = 0;

//   // Gift state
//   List<dynamic> _gifts = [];
//   bool _giftsLoading = true;
//   bool _sendingGift = false;
//   List<Widget> _activeGiftAnimations = [];
//   int _giftAnimKey = 0;

//   // Global deduplication for gift animations to prevent duplicates
//   final Set<String> _globalProcessedAnimations = {};
//   DateTime _lastAnimationCleanup = DateTime.now();

//   // Gift polling for synchronization
//   Timer? _giftPollingTimer;
//   DateTime _lastGiftCheck = DateTime.now();
//   final Set<String> _processedGifts = {};

//   // Host profile picture and username for top menu bar
//   String? _hostProfilePic;
//   String? _hostUsername;

//   @override
//   void initState() {
//     super.initState();
//     if (widget.backgroundMusic != null) {
//       _setupBackgroundMusic();
//     }
//     _loadCurrentUser();
//     _loadHostUser();
//     _fetchAllUsers();
//     _fetchHostProfilePicture();

//     _userListSub = ZegoUIKit().getUserListStream().listen((zegoUsers) {
//       setState(() {
//         _zegoUsers = zegoUsers;
//       });
//       _mapZegoUsersToProfiles(zegoUsers);
//     });

//     // Initialize like animation
//     _likeController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 400),
//     );
//     _likeScale = Tween<double>(
//       begin: 0.0,
//       end: 1.5,
//     ).chain(CurveTween(curve: Curves.elasticOut)).animate(_likeController);
//     _likeController.addStatusListener((status) {
//       if (status == AnimationStatus.completed) {
//         Future.delayed(const Duration(milliseconds: 300), () {
//           _likeController.reverse();
//         });
//       }
//     });

//     _fetchGiftsAndUser();
//     _startGiftPolling();

//     // Start block checking for audience members
//     _startBlockChecking();
//   }

//   // Gift panel functions
//   void _showGiftPanel() {
//     setState(() {
//       showGiftPanel = true;
//     });
//   }

//   void _hideGiftPanel() {
//     setState(() {
//       showGiftPanel = false;
//     });
//   }

//   void _showGiftAnimation(
//     String giftName,
//     String gifUrl,
//     String senderName, {
//     String? pkBattleSide,
//   }) {
//     setState(() {
//       giftAnimations.add({
//         'giftName': giftName,
//         'gifUrl': gifUrl,
//         'senderName': senderName,
//         'pkBattleSide': pkBattleSide,
//         'id': DateTime.now().millisecondsSinceEpoch,
//       });
//     });
//   }

//   void _removeGiftAnimation(int id) {
//     setState(() {
//       giftAnimations.removeWhere((animation) => animation['id'] == id);
//     });
//   }

//   // Gift polling methods for synchronization
//   void _startGiftPolling() {
//     _giftPollingTimer?.cancel();
//     _giftPollingTimer = Timer.periodic(const Duration(milliseconds: 500), (
//       timer,
//     ) {
//       // For audio screen (non-PK), use user gifts received endpoint
//       final int targetUserId =
//           widget.isHost
//               ? (currentUser?['id'] as int? ?? widget.hostId)
//               : widget.hostId;
//       _pollUserGiftsReceived(targetUserId);
//     });
//   }

//   void _stopGiftPolling() {
//     _giftPollingTimer?.cancel();
//     _giftPollingTimer = null;
//   }

//   // Poll gifts received by specific user and display
//   Future<void> _pollUserGiftsReceived(int targetUserId) async {
//     try {
//       final data = await ApiService.getUserGiftsReceived(
//         userIdentifier: targetUserId,
//       );
//       if (data == null) return;
//       final List<dynamic>? recentGifts = data['recent_gifts'] as List<dynamic>?;
//       if (recentGifts == null || recentGifts.isEmpty) return;

//       for (final dynamic g in recentGifts) {
//         final Map<String, dynamic> gift = g as Map<String, dynamic>;
//         // Time-based filtering to avoid replaying old gifts too frequently
//         final String? receivedAtStr = gift['received_at'] as String?;
//         if (receivedAtStr != null) {
//           try {
//             final receivedAt = DateTime.parse(receivedAtStr);
//             if (!receivedAt.isAfter(_lastGiftCheck)) {
//               continue;
//             }
//           } catch (_) {}
//         }

//         // Deduplication by transaction_id
//         final int? txnId =
//             (gift['transaction_id'] is int)
//                 ? gift['transaction_id'] as int
//                 : int.tryParse('${gift['transaction_id']}');
//         if (txnId == null) continue;
//         final giftKey = 'user_${targetUserId}_txn_$txnId';
//         if (_processedGifts.contains(giftKey)) continue;
//         _processedGifts.add(giftKey);

//         // Play audio (2s delay)
//         final dynamic audioFilenameRaw = gift['audio_filename'];
//         final String? audioFilename =
//             (audioFilenameRaw is String)
//                 ? audioFilenameRaw
//                 : (audioFilenameRaw?.toString());
//         if (audioFilename != null && audioFilename.isNotEmpty) {
//           try {
//             final audioUrl =
//                 'https://server.bharathchat.com/uploads/audio/$audioFilename';
//             debugPrint(
//               '🎁 (User $targetUserId) Playing received gift audio: $audioUrl',
//             );
//             await Future.delayed(const Duration(seconds: 2));
//             if (mounted) {
//               await _audioPlayer.setUrl(audioUrl);
//               await _audioPlayer.play();
//             }
//           } catch (e) {
//             debugPrint(
//               '🎁 (User $targetUserId) Error playing received gift audio: $e',
//             );
//           }
//         }

//         // Animation
//         String gifUrl;
//         final dynamic gifUrlRaw = gift['gif_url'];
//         if (gifUrlRaw is String && gifUrlRaw.isNotEmpty) {
//           gifUrl =
//               gifUrlRaw.startsWith('http')
//                   ? gifUrlRaw
//                   : 'https://server.bharathchat.com$gifUrlRaw';
//         } else {
//           final dynamic gifFilenameRaw = gift['gif_filename'];
//           final String gifFilename =
//               (gifFilenameRaw is String)
//                   ? gifFilenameRaw
//                   : (gifFilenameRaw?.toString() ?? '');
//           gifUrl = 'https://server.bharathchat.com/uploads/gifts/$gifFilename';
//         }
//         final Map<String, dynamic>? sender =
//             gift['sender'] as Map<String, dynamic>?;
//         final String senderName =
//             sender?['username'] as String? ??
//             sender?['first_name'] as String? ??
//             'User';
//         final String giftName = gift['gift_name'] as String? ?? 'Gift';
//         _createGiftAnimation(giftName, gifUrl, senderName);
//       }

//       _lastGiftCheck = DateTime.now();
//     } catch (e) {
//       debugPrint('❌ Error polling user gifts received: $e');
//     }
//   }

//   // Create gift animation (reusable method)
//   void _createGiftAnimation(String giftName, String gifUrl, String senderName) {
//     // Clean up old animation keys every 5 minutes to prevent memory leaks
//     final now = DateTime.now();
//     if (now.difference(_lastAnimationCleanup).inMinutes >= 5) {
//       _globalProcessedAnimations.clear();
//       _lastAnimationCleanup = now;
//       debugPrint('🎁 Cleaned up old animation deduplication keys');
//     }

//     // Create a unique key for this animation
//     final animationKey =
//         '${senderName}_${giftName}_${DateTime.now().millisecondsSinceEpoch}';

//     // Check if this animation was already processed
//     if (_globalProcessedAnimations.contains(animationKey)) {
//       debugPrint('🎁 Animation already processed, skipping: $animationKey');
//       return;
//     }

//     // Add to processed animations
//     _globalProcessedAnimations.add(animationKey);

//     debugPrint('🎁 Creating gift animation:');
//     debugPrint('🎁   - Gift Name: $giftName');
//     debugPrint('🎁   - GIF URL: $gifUrl');
//     debugPrint('🎁   - Sender: $senderName');
//     debugPrint('🎁   - Animation Key: $animationKey');

//     setState(() {
//       _activeGiftAnimations.add(
//         GiftAnimation(
//           key: ValueKey('gift_anim_${_giftAnimKey++}'),
//           giftName: giftName,
//           gifUrl: gifUrl,
//           senderName: senderName,
//           onAnimationComplete: () {
//             debugPrint('🎁 Gift animation completed, removing from list');
//             setState(() {
//               _activeGiftAnimations.removeWhere(
//                 (w) =>
//                     (w.key as ValueKey).value ==
//                     'gift_anim_${_giftAnimKey - 1}',
//               );
//             });
//           },
//         ),
//       );
//     });
//   }

//   Future<void> _fetchGiftsAndUser() async {
//     setState(() {
//       _giftsLoading = true;
//     });
//     try {
//       final gifts = await ApiService.getGifts();
//       final user = await ApiService.getCurrentUser();
//       setState(() {
//         _gifts = gifts;
//         currentUser = user;
//         _giftsLoading = false;
//       });
//     } catch (e) {
//       setState(() {
//         _giftsLoading = false;
//       });
//     }
//   }

//   Future<void> _loadCurrentUser() async {
//     try {
//       final userData = await ApiService.getCurrentUser();
//       setState(() {
//         currentUser = userData;
//       });
//     } catch (e) {
//       print('Error loading current user: $e');
//     }
//   }

//   Future<void> _loadHostUser() async {
//     try {
//       // For now, we'll assume the host is the current user
//       // In a real implementation, you'd get the host info from the live stream data
//       final userData = await ApiService.getCurrentUser();
//       setState(() {
//         hostUser = userData;
//       });
//     } catch (e) {
//       print('Error loading host user: $e');
//     }
//   }

//   // Fetch host profile picture and username for top menu bar
//   Future<void> _fetchHostProfilePicture() async {
//     try {
//       debugPrint('🔄 [HOST_PROFILE] Starting host profile fetch...');
//       debugPrint('🔄 [HOST_PROFILE] isHost: ${widget.isHost}');
//       debugPrint('🔄 [HOST_PROFILE] hostId: ${widget.hostId}');
//       debugPrint('🔄 [HOST_PROFILE] currentUser: ${currentUser != null}');

//       if (widget.isHost) {
//         // For host, use current user's profile picture and username
//         if (currentUser != null) {
//           setState(() {
//             _hostProfilePic = currentUser!['profile_pic'];
//             _hostUsername =
//                 currentUser!['username'] ??
//                 currentUser!['first_name'] ??
//                 'Host';
//           });
//           debugPrint(
//             '✅ [HOST_PROFILE] Fetched host profile picture: $_hostProfilePic',
//           );
//           debugPrint('✅ [HOST_PROFILE] Fetched host username: $_hostUsername');
//         }
//       } else {
//         // For audience, fetch host's profile picture and username
//         debugPrint(
//           '🔄 [HOST_PROFILE] Fetching host profile for audience view...',
//         );
//         final users = await ApiService.getAllUsers();
//         debugPrint('🔄 [HOST_PROFILE] Found ${users.length} total users');

//         final host = users.firstWhere(
//           (user) => user['id'] == widget.hostId,
//           orElse: () => null,
//         );

//         if (host != null) {
//           setState(() {
//             _hostProfilePic = host['profile_pic'];
//             _hostUsername = host['username'] ?? host['first_name'] ?? 'Host';
//           });
//           debugPrint(
//             '✅ [HOST_PROFILE] Fetched host profile picture: $_hostProfilePic',
//           );
//           debugPrint('✅ [HOST_PROFILE] Fetched host username: $_hostUsername');
//         } else {
//           debugPrint(
//             '⚠️ [HOST_PROFILE] Host profile picture not found for ID: ${widget.hostId}',
//           );
//           debugPrint(
//             '⚠️ [HOST_PROFILE] Available user IDs: ${users.map((u) => u['id']).toList()}',
//           );
//         }
//       }
//     } catch (e) {
//       debugPrint('❌ [HOST_PROFILE] Error fetching host profile picture: $e');
//     }
//   }

//   Future<void> _fetchAllUsers() async {
//     try {
//       final users = await ApiService.getUsers();
//       setState(() {
//         _allUsers = users;
//       });
//     } catch (e) {
//       print('Error fetching all users: $e');
//     }
//   }

//   void _mapZegoUsersToProfiles(List zegoUsers) {
//     debugPrint(
//       '🔄 [USER_MAPPING] Mapping ${zegoUsers.length} ZEGO users to profiles',
//     );
//     debugPrint(
//       '🔄 [USER_MAPPING] Available users in _allUsers: ${_allUsers.length}',
//     );
//     debugPrint(
//       '🔄 [USER_MAPPING] Current _userProfiles count: ${_userProfiles.length}',
//     );

//     for (var zUser in zegoUsers) {
//       final userId = zUser.id ?? zUser.userID ?? zUser['userID'] ?? zUser['id'];
//       debugPrint(
//         '🔄 [USER_MAPPING] Processing ZEGO user: $userId (${zUser.name})',
//       );

//       if (userId != null && !_userProfiles.containsKey(userId)) {
//         // Try multiple matching strategies
//         Map<String, dynamic>? match;

//         // Strategy 1: Match by exact username
//         try {
//           match = _allUsers.firstWhere(
//             (u) => u['username'] == userId,
//             orElse: () => null,
//           );
//           if (match != null) {
//             debugPrint(
//               '✅ [USER_MAPPING] Found user by username: $userId -> ${match['username']}',
//             );
//           }
//         } catch (e) {
//           debugPrint('❌ [USER_MAPPING] Error matching by username: $e');
//         }

//         // Strategy 2: Match by ID (handle both string and int formats)
//         if (match == null) {
//           try {
//             // Try exact string match first
//             match = _allUsers.firstWhere(
//               (u) => u['id'].toString() == userId.toString(),
//               orElse: () => null,
//             );
//             if (match != null) {
//               debugPrint(
//                 '✅ [USER_MAPPING] Found user by ID (string): $userId -> ${match['username']}',
//               );
//             }
//           } catch (e) {
//             debugPrint('❌ [USER_MAPPING] Error matching by ID: $e');
//           }
//         }

//         // Strategy 3: Match by first_name if username contains it
//         if (match == null) {
//           try {
//             match = _allUsers.firstWhere(
//               (u) =>
//                   u['first_name'] != null &&
//                   userId.toString().toLowerCase().contains(
//                     u['first_name'].toString().toLowerCase(),
//                   ),
//               orElse: () => null,
//             );
//             if (match != null) {
//               debugPrint(
//                 '✅ [USER_MAPPING] Found user by first_name: $userId -> ${match['username']}',
//               );
//             }
//           } catch (e) {
//             debugPrint('❌ [USER_MAPPING] Error matching by first_name: $e');
//           }
//         }

//         // Strategy 4: Try to parse userId as integer and match
//         if (match == null) {
//           try {
//             final userIdInt = int.tryParse(userId.toString());
//             if (userIdInt != null) {
//               match = _allUsers.firstWhere(
//                 (u) => u['id'] == userIdInt,
//                 orElse: () => null,
//               );
//               if (match != null) {
//                 debugPrint(
//                   '✅ [USER_MAPPING] Found user by parsed ID: $userId -> ${match['username']}',
//                 );
//               }
//             }
//           } catch (e) {
//             debugPrint('❌ [USER_MAPPING] Error matching by parsed ID: $e');
//           }
//         }

//         if (match != null) {
//           setState(() {
//             _userProfiles[userId] = match;
//           });
//           debugPrint(
//             '✅ [USER_MAPPING] Added user profile for $userId: ${match['profile_pic']}',
//           );
//         } else {
//           debugPrint('⚠️ [USER_MAPPING] No match found for ZEGO user: $userId');
//           // Try to fetch user directly from backend as last resort
//           _fetchUserFromBackend(userId);
//         }
//       }
//     }

//     debugPrint(
//       '🔄 [USER_MAPPING] Final _userProfiles count: ${_userProfiles.length}',
//     );
//   }

//   // Helper method to fetch user from backend as last resort
//   Future<void> _fetchUserFromBackend(String userId) async {
//     try {
//       debugPrint(
//         '🔄 [BACKEND_FETCH] Trying to fetch user $userId from backend...',
//       );

//       // Try to parse as integer first
//       final userIdInt = int.tryParse(userId.toString());
//       if (userIdInt != null) {
//         final userData = await ApiService.getUserById(userIdInt);
//         if (userData != null) {
//           setState(() {
//             _userProfiles[userId] = userData;
//           });
//           debugPrint(
//             '✅ [BACKEND_FETCH] Successfully fetched user $userId from backend',
//           );
//           return;
//         }
//       }

//       debugPrint(
//         '⚠️ [BACKEND_FETCH] Could not fetch user $userId from backend',
//       );
//     } catch (e) {
//       debugPrint(
//         '❌ [BACKEND_FETCH] Error fetching user $userId from backend: $e',
//       );
//     }
//   }

//   void _triggerLike() {
//     setState(() {
//       _burstKey++;
//       _burstHearts = List.generate(
//         5,
//         (i) => AnimatedHeart(
//           key: ValueKey('heart_$_burstKey$i'),
//           delay: Duration(milliseconds: i * 80),
//           random: Random(),
//         ),
//       );
//     });
//     // Remove hearts after animation
//     Future.delayed(const Duration(milliseconds: 1200), () {
//       if (mounted) setState(() => _burstHearts = []);
//     });
//   }

//   Future<void> _sendGiftFromList(dynamic gift) async {
//     try {
//       final requestId = DateTime.now().millisecondsSinceEpoch.toString();
//       debugPrint('🎁 [$requestId] Starting gift send from list...');

//       // Check if we have enough diamonds
//       final currentDiamonds = await ApiService.getCurrentUserDiamonds();
//       final giftCost = gift['diamond_amount'] as int? ?? 0;

//       if (currentDiamonds < giftCost) {
//         debugPrint(
//           '❌ [$requestId] Insufficient diamonds: $currentDiamonds < $giftCost',
//         );
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text('❌ Insufficient diamonds to send this gift'),
//               backgroundColor: Colors.red,
//               duration: const Duration(seconds: 3),
//             ),
//           );
//         }
//         return;
//       }

//       debugPrint(
//         '✅ [$requestId] Sufficient diamonds: $currentDiamonds >= $giftCost',
//       );

//       // Derive numeric live stream id from widget.liveID (e.g., "live_17775689" or just "17775689")
//       int liveStreamId = 0;
//       final liveIdStr = widget.liveID;
//       if (liveIdStr.startsWith('live_')) {
//         final parts = liveIdStr.split('_');
//         if (parts.length >= 2) {
//           liveStreamId = int.tryParse(parts[1]) ?? 0;
//         }
//       } else {
//         liveStreamId = int.tryParse(liveIdStr) ?? 0;
//       }

//       // Send gift via API
//       final success = await ApiService.sendGift(
//         receiverId: widget.hostId,
//         giftId: gift['id'],
//         liveStreamId: liveStreamId,
//         liveStreamType: 'audio',
//       );

//       if (success) {
//         debugPrint('✅ [$requestId] Gift sent successfully via API');

//         // Play gift audio if available (with 2-second delay)
//         final dynamic audioFilenameRaw = gift['audio_filename'];
//         final String? audioFilename =
//             (audioFilenameRaw is String)
//                 ? audioFilenameRaw
//                 : (audioFilenameRaw?.toString());
//         if (audioFilename != null && audioFilename.isNotEmpty) {
//           try {
//             final audioUrl =
//                 'https://server.bharathchat.com/uploads/audio/$audioFilename';
//             debugPrint('🎁 [$requestId] Playing gift audio: $audioUrl');
//             // Wait 200ms before playing audio (reduced from 500ms)
//             await Future.delayed(const Duration(milliseconds: 200));
//             if (mounted) {
//               await _audioPlayer.setUrl(audioUrl);
//               await _audioPlayer.play();
//             }
//           } catch (e) {
//             debugPrint('🎁 [$requestId] Error playing gift audio: $e');
//           }
//         }

//         // Immediately show animation for the sender
//         try {
//           String? gifUrl;
//           final dynamic gifUrlRaw = gift['gif_url'];
//           if (gifUrlRaw is String && gifUrlRaw.isNotEmpty) {
//             gifUrl =
//                 gifUrlRaw.startsWith('http')
//                     ? gifUrlRaw
//                     : 'https://server.bharathchat.com$gifUrlRaw';
//           } else {
//             final dynamic gifFilenameRaw = gift['gif_filename'];
//             final String gifFilename =
//                 (gifFilenameRaw is String)
//                     ? gifFilenameRaw
//                     : (gifFilenameRaw?.toString() ?? '');
//             gifUrl =
//                 'https://server.bharathchat.com/uploads/gifts/$gifFilename';
//           }
//           final String senderName =
//               currentUser?['username'] ?? currentUser?['first_name'] ?? 'You';
//           final String giftName = gift['name'] ?? gift['gift_name'] ?? 'Gift';
//           if (gifUrl != null) {
//             // REMOVED: _createGiftAnimation(giftName, gifUrl, senderName);
//             // Animation will be handled by polling system to prevent duplicates
//             debugPrint(
//               '🎁 [$requestId] Gift animation will be shown via polling system',
//             );
//           }
//         } catch (e) {
//           debugPrint(
//             '🎁 [$requestId] Error creating immediate gift animation: $e',
//           );
//         }

//         // Send ZEGOCLOUD in-room command for synchronization
//         final message = jsonEncode({
//           'type': 'gift',
//           'gift_id': gift['id'],
//           'gift_name': gift['name'],
//           'gif_filename': gift['gif_filename'],
//           'audio_filename': gift['audio_filename'],
//           'diamond_amount': giftCost,
//           'sender_id': currentUser?['id'],
//           'sender_name':
//               currentUser?['username'] ?? currentUser?['first_name'] ?? 'User',
//           'receiver_id': widget.hostId,
//           'timestamp': DateTime.now().toIso8601String(),
//         });

//         debugPrint('🎁 [$requestId] Sending in-room command: $message');
//         // Note: ZEGOCLOUD command sending is disabled due to API limitations
//         // Gift animations will be synchronized through server-side polling
//         debugPrint(
//           '🎁 [$requestId] ZEGOCLOUD command sending disabled - using server polling for sync',
//         );

//         // Success message removed - gift sent silently
//       } else {
//         debugPrint('❌ [$requestId] Failed to send gift via API');
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text('❌ Failed to send gift. Please try again.'),
//               backgroundColor: Colors.red,
//               duration: const Duration(seconds: 3),
//             ),
//           );
//         }
//       }
//     } catch (e) {
//       debugPrint('❌ Error sending gift: $e');
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('❌ Error sending gift: $e'),
//             backgroundColor: Colors.red,
//             duration: const Duration(seconds: 3),
//           ),
//         );
//       }
//     }
//   }

//   Future<void> _setupBackgroundMusic() async {
//     try {
//       await _audioPlayer.setUrl(
//         'https://server.bharathchat.com/uploads/music/${widget.backgroundMusic}',
//       );
//       await _audioPlayer.play();
//       setState(() => _isPlaying = true);
//     } catch (e) {
//       print('Error setting up background music: $e');
//     }
//   }

//   void _toggleBackgroundMusic() async {
//     try {
//       if (_isPlaying) {
//         await _audioPlayer.pause();
//       } else {
//         await _audioPlayer.play();
//       }
//       setState(() => _isPlaying = !_isPlaying);
//     } catch (e) {
//       print('Error toggling background music: $e');
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Failed to toggle background music')),
//         );
//       }
//     }
//   }

//   Future<void> _showGiftConfirmationDialog(
//     dynamic gift,
//     VoidCallback onConfirm,
//   ) async {
//     await showDialog(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           backgroundColor: Colors.black,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(16),
//           ),
//           title: Text(
//             'Send Gift',
//             style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
//           ),
//           content: Text(
//             'Do you want to send "${gift['name']}"?',
//             style: TextStyle(color: Colors.white),
//           ),
//           actions: [
//             TextButton(
//               style: TextButton.styleFrom(
//                 backgroundColor: Colors.black,
//                 foregroundColor: Colors.orange,
//                 side: BorderSide(color: Colors.orange),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//               ),
//               onPressed: () => Navigator.of(context).pop(),
//               child: const Text(
//                 'Cancel',
//                 style: TextStyle(color: Colors.orange),
//               ),
//             ),
//             ElevatedButton(
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.orange,
//                 foregroundColor: Colors.white,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//               ),
//               onPressed: () {
//                 Navigator.of(context).pop();
//                 onConfirm();
//               },
//               child: const Text('Send', style: TextStyle(color: Colors.white)),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   @override
//   void dispose() {
//     _audioPlayer.dispose();
//     _userListSub?.cancel();
//     _likeController.dispose();
//     _stopGiftPolling();
//     _stopBlockChecking();
//     if (widget.isHost) {
//       _liveStreamService.removeStream(widget.liveID);
//     }
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     // Audio-only configuration - no camera, no PK battles
//     final config =
//         widget.isHost
//             ? (ZegoUIKitPrebuiltLiveStreamingConfig.host()
//               ..turnOnCameraWhenJoining = false
//               ..turnOnMicrophoneWhenJoining = true
//               ..useSpeakerWhenJoining = true
//               // Configure host avatar in top menu bar
//               ..topMenuBar.hostAvatarBuilder = (ZegoUIKitUser host) {
//                 return Container(
//                   child: Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       // Host avatar
//                       customAvatarBuilder(context, const Size(40, 40), host, {
//                         'profile_pic_url': _hostProfilePic,
//                         'user_data': {
//                           'profile_pic': _hostProfilePic,
//                           'username': _hostUsername,
//                         },
//                       }),
//                       const SizedBox(width: 8),
//                       // Host username
//                       if (_hostUsername != null)
//                         Container(
//                           padding: const EdgeInsets.symmetric(
//                             horizontal: 8,
//                             vertical: 4,
//                           ),
//                           decoration: BoxDecoration(
//                             color: Colors.black.withOpacity(0.7),
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                           child: Text(
//                             _hostUsername!,
//                             style: const TextStyle(
//                               color: Colors.white,
//                               fontSize: 12,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                         ),
//                     ],
//                   ),
//                 );
//               }
//               // Top menu bar - minimal buttons for audio
//               ..topMenuBar.buttons = []
//               // Bottom menu bar - audio-specific buttons with extend buttons
//               ..bottomMenuBar.hostButtons = [
//                 ZegoLiveStreamingMenuBarButtonName.toggleMicrophoneButton,
//                 ZegoLiveStreamingMenuBarButtonName.leaveButton,
//                 ZegoLiveStreamingMenuBarButtonName.switchAudioOutputButton,
//                 ZegoLiveStreamingMenuBarButtonName.chatButton,
//               ]
//               // Audio video view config
//               ..audioVideoView.showUserNameOnView = false
//               ..avatarBuilder = (
//                 BuildContext context,
//                 Size size,
//                 ZegoUIKitUser? user,
//                 Map<String, dynamic> extraInfo,
//               ) {
//                 return user != null
//                     ? customAvatarBuilder(context, size, user, {
//                       ...extraInfo,
//                       // For host, use host profile picture
//                       'profile_pic_url':
//                           user.id == widget.localUserID
//                               ? _hostProfilePic
//                               : null,
//                       'user_data':
//                           user.id == widget.localUserID
//                               ? {
//                                 'profile_pic': _hostProfilePic,
//                                 'username': _hostUsername,
//                               }
//                               : _userProfiles[user.id],
//                     })
//                     : const SizedBox();
//               }
//               // Note: memberList.showAvatar and cohost.applyButtonStyle are not available in this version
//               // Custom start live button with app theme color
//               ..startLiveButtonBuilder = (
//                 BuildContext context,
//                 VoidCallback startLive,
//               ) {
//                 return Container(
//                   width: 70,
//                   height: 70,
//                   decoration: BoxDecoration(
//                     shape: BoxShape.circle,
//                     gradient: RadialGradient(
//                       colors: [
//                         Colors.orange.shade300,
//                         Colors.orange,
//                         Colors.orange.shade700,
//                       ],
//                       center: Alignment.center,
//                       radius: 0.8,
//                     ),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.orange.withOpacity(0.4),
//                         blurRadius: 15,
//                         spreadRadius: 2,
//                         offset: const Offset(0, 4),
//                       ),
//                       BoxShadow(
//                         color: Colors.orange.withOpacity(0.2),
//                         blurRadius: 25,
//                         spreadRadius: 5,
//                         offset: const Offset(0, 0),
//                       ),
//                     ],
//                   ),
//                   child: Material(
//                     color: Colors.transparent,
//                     child: InkWell(
//                       borderRadius: BorderRadius.circular(30),
//                       onTap: startLive,
//                       child: Center(
//                         child: Image.asset(
//                           'assets/start.png',
//                           // width: 32,
//                           // height: 32,
//                           width: 65,
//                           height: 65,
//                           fit: BoxFit.contain,
//                         ),
//                       ),
//                     ),
//                   ),
//                 );
//               }
//               // Customize text message UI with profile pictures for host
//               ..inRoomMessage.showAvatar = true
//               ..inRoomMessage.showName = true
//               ..inRoomMessage.backgroundColor = Colors.black.withOpacity(0.6)
//               ..inRoomMessage.opacity = 0.8
//               ..inRoomMessage.maxLines = 3
//               ..inRoomMessage.borderRadius = BorderRadius.circular(12)
//               ..inRoomMessage.paddings = const EdgeInsets.symmetric(
//                 horizontal: 8,
//                 vertical: 4,
//               )
//               ..inRoomMessage.nameTextStyle = const TextStyle(
//                 color: Colors.orange,
//                 fontSize: 12,
//                 fontWeight: FontWeight.bold,
//               )
//               ..inRoomMessage.messageTextStyle = const TextStyle(
//                 color: Colors.white,
//                 fontSize: 12,
//               )
//               // Add user ID and profile picture attributes
//               ..inRoomMessage.attributes = () {
//                 return {
//                   'user_id': currentUser?['id']?.toString() ?? '',
//                   'profile_pic': currentUser?['profile_pic'] ?? '',
//                 };
//               }
//               // Custom item builder for enhanced profile picture display
//               ..inRoomMessage.itemBuilder = (
//                 BuildContext context,
//                 ZegoInRoomMessage message,
//                 Map<String, dynamic> extraInfo,
//               ) {
//                 // Get user ID and profile picture from attributes
//                 final attributes = message.attributes;
//                 final userId = attributes['user_id'] ?? '';
//                 final profilePic = attributes['profile_pic'] ?? '';

//                 // Clean username by removing "user_" prefix and avatar info
//                 String cleanUsername = message.user.name;
//                 if (cleanUsername.startsWith('user_')) {
//                   cleanUsername = cleanUsername.substring(5);
//                 }
//                 if (cleanUsername.contains('|avatar:')) {
//                   cleanUsername = cleanUsername.split('|avatar:')[0];
//                 }

//                 return GestureDetector(
//                   onTap: () {
//                     // Only show block popup for hosts
//                     if (widget.isHost) {
//                       _showBlockUserPopup(
//                         context,
//                         cleanUsername,
//                         message.user.id,
//                       );
//                     }
//                   },
//                   child: Container(
//                     margin: const EdgeInsets.symmetric(vertical: 2),
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 8,
//                       vertical: 6,
//                     ),
//                     decoration: BoxDecoration(
//                       color: Colors.black.withOpacity(0.7),
//                       borderRadius: BorderRadius.circular(12),
//                       border: Border.all(
//                         color: Colors.orange.withOpacity(0.3),
//                         width: 1,
//                       ),
//                     ),
//                     child: Row(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         // Profile Picture
//                         Container(
//                           width: 24,
//                           height: 24,
//                           margin: const EdgeInsets.only(right: 8),
//                           child: ClipOval(
//                             child: customAvatarBuilder(
//                               context,
//                               const Size(24, 24),
//                               message.user,
//                               extraInfo,
//                             ),
//                           ),
//                         ),
//                         // Message Content
//                         Expanded(
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               // User Name
//                               Text(
//                                 cleanUsername,
//                                 style: const TextStyle(
//                                   color: Colors.orange,
//                                   fontSize: 11,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                               const SizedBox(height: 2),
//                               // Message Text
//                               Text(
//                                 message.message,
//                                 style: const TextStyle(
//                                   color: Colors.white,
//                                   fontSize: 12,
//                                 ),
//                                 maxLines: 3,
//                                 overflow: TextOverflow.ellipsis,
//                               ),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 );
//               }
//               // Custom button styles for enhanced UI
//               ..bottomMenuBar
//                   .buttonStyle = ZegoLiveStreamingBottomMenuBarButtonStyle(
//                 // Microphone button icons with enhanced colors
//                 toggleMicrophoneOnButtonIcon: Container(
//                   decoration: BoxDecoration(
//                     shape: BoxShape.circle,
//                     gradient: LinearGradient(
//                       // colors: [Color(0xFF2193b0), Color(0xFF6dd5ed)],
//                       colors: [Color(0xFFFF9A9E), Color(0xFFFECFEF)],
//                       begin: Alignment.topLeft,
//                       end: Alignment.bottomRight,
//                     ),
//                   ),
//                   child: const Icon(
//                     Icons.mic,
//                     color: Color(0xFF7A4E4E),
//                     size: 24,
//                   ),
//                 ),
//                 toggleMicrophoneOffButtonIcon: const Icon(
//                   Icons.mic_off,
//                   color: Colors.red,
//                   size: 24,
//                 ),

//                 // Chat button icons with enhanced colors
//                 chatEnabledButtonIcon: Container(
//                   width: 40,
//                   height: 40,
//                   decoration: BoxDecoration(
//                     shape: BoxShape.circle,
//                     // gradient: LinearGradient(
//                     //   colors: [Color(0xFFa18cd1), Color(0xFFfbc2eb)],
//                     //   begin: Alignment.topLeft,
//                     //   end: Alignment.bottomRight,
//                     // ),
//                   ),
//                   child: const Icon(
//                     Icons.chat_bubble_outline,
//                     color: Color(0xFF2193b0),
//                     size: 24,
//                   ),
//                 ),
//                 chatDisabledButtonIcon: const Icon(
//                   Icons.chat_bubble_outline,
//                   color: Colors.grey,
//                   size: 24,
//                 ),

//                 // Audio output button icons with enhanced colors
//                 switchAudioOutputToSpeakerButtonIcon: Container(
//                   width: 40,
//                   height: 40,
//                   decoration: BoxDecoration(
//                     shape: BoxShape.circle,
//                     // gradient: LinearGradient(
//                     //   colors: [Color(0xFF2193b0), Color(0xFF6dd5ed)],
//                     //   begin: Alignment.topLeft,
//                     //   end: Alignment.bottomRight,
//                     // ),
//                   ),
//                   child: const Icon(
//                     Icons.volume_up,
//                     color: Colors.white,
//                     size: 24,
//                   ),
//                 ),
//                 switchAudioOutputToHeadphoneButtonIcon: Container(
//                   width: 40,
//                   height: 40,
//                   decoration: BoxDecoration(
//                     shape: BoxShape.circle,
//                     // gradient: LinearGradient(
//                     //   colors: [Color(0xFF2193b0), Color(0xFF6dd5ed)],
//                     //   begin: Alignment.topLeft,
//                     //   end: Alignment.bottomRight,
//                     // ),
//                   ),
//                   child: const Icon(
//                     Icons.headphones,
//                     color: Colors.grey,
//                     size: 24,
//                   ),
//                 ),
//                 switchAudioOutputToBluetoothButtonIcon: Container(
//                   width: 40,
//                   height: 40,
//                   decoration: BoxDecoration(
//                     shape: BoxShape.circle,
//                     // gradient: LinearGradient(
//                     //   colors: [Color(0xFF2193b0), Color(0xFF6dd5ed)],
//                     //   begin: Alignment.topLeft,
//                     //   end: Alignment.bottomRight,
//                     // ),
//                   ),
//                   child: const Icon(
//                     Icons.bluetooth,
//                     color: Colors.grey,
//                     size: 24,
//                   ),
//                 ),

//                 // Leave button icon with enhanced color
//                 leaveButtonIcon: Container(
//                   width: 40,
//                   height: 40,
//                   decoration: BoxDecoration(
//                     shape: BoxShape.circle,
//                     // gradient: LinearGradient(
//                     //   colors: [Color(0xFFffa030), Color(0xFFfe9b00)],
//                     //   begin: Alignment.topLeft,
//                     //   end: Alignment.bottomRight,
//                     // ),
//                   ),
//                   child: const Icon(
//                     Icons.call_end,
//                     color: Colors.red,
//                     size: 24,
//                   ),
//                 ),

//                 // Beauty effect button icon
//                 beautyEffectButtonIcon: const Icon(
//                   Icons.face,
//                   color: Colors.white,
//                   size: 24,
//                 ),

//                 // Sound effect button icon
//                 soundEffectButtonIcon: const Icon(
//                   Icons.graphic_eq,
//                   color: Colors.white,
//                   size: 24,
//                 ),
//               ))
//             : (ZegoUIKitPrebuiltLiveStreamingConfig.audience()
//               ..turnOnCameraWhenJoining =
//                   false // No camera for audience
//               ..turnOnMicrophoneWhenJoining = false
//               ..useSpeakerWhenJoining = true
//               // Configure host avatar in top menu bar for audience view
//               ..topMenuBar.hostAvatarBuilder = (ZegoUIKitUser host) {
//                 return Container(
//                   child: Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       // Host avatar
//                       customAvatarBuilder(context, const Size(40, 40), host, {
//                         'profile_pic_url': _hostProfilePic,
//                         'user_data': {
//                           'profile_pic': _hostProfilePic,
//                           'username': _hostUsername,
//                         },
//                       }),
//                       const SizedBox(width: 8),
//                       // Host username
//                       if (_hostUsername != null)
//                         Container(
//                           padding: const EdgeInsets.symmetric(
//                             horizontal: 8,
//                             vertical: 4,
//                           ),
//                           decoration: BoxDecoration(
//                             color: Colors.black.withOpacity(0.7),
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                           child: Text(
//                             _hostUsername!,
//                             style: const TextStyle(
//                               color: Colors.white,
//                               fontSize: 12,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                         ),
//                     ],
//                   ),
//                 );
//               }
//               // Top menu bar - minimal buttons for audio
//               ..topMenuBar.buttons = [
//                 // ZegoLiveStreamingMenuBarButtonName.minimizingButton,
//               ]
//               // Bottom menu bar - audience buttons for audio with extend buttons
//               ..bottomMenuBar.audienceButtons = [
//                 ZegoLiveStreamingMenuBarButtonName.leaveButton,
//                 ZegoLiveStreamingMenuBarButtonName.switchAudioOutputButton,
//                 ZegoLiveStreamingMenuBarButtonName.chatButton,
//               ]
//               // Audio video view config
//               ..audioVideoView.showUserNameOnView = true
//               ..avatarBuilder = (
//                 BuildContext context,
//                 Size size,
//                 ZegoUIKitUser? user,
//                 Map<String, dynamic> extraInfo,
//               ) {
//                 if (user != null) {
//                   debugPrint(
//                     '🎭 [AUDIENCE] Processing user: ${user.id} (${user.name})',
//                   );
//                   debugPrint('🎭 [AUDIENCE] Host ID: ${widget.hostId}');
//                   debugPrint(
//                     '🎭 [AUDIENCE] Local User ID: ${widget.localUserID}',
//                   );
//                   debugPrint(
//                     '🎭 [AUDIENCE] Is host? ${user.id == widget.hostId.toString()}',
//                   );
//                   debugPrint(
//                     '🎭 [AUDIENCE] User profile in cache: ${_userProfiles[user.id]}',
//                   );
//                 }

//                 return user != null
//                     ? customAvatarBuilder(context, size, user, {
//                       ...extraInfo,
//                       // For host, use host profile picture (check by hostId in audience view)
//                       'profile_pic_url':
//                           user.id == widget.hostId.toString()
//                               ? _hostProfilePic
//                               : null,
//                       'user_data':
//                           user.id == widget.hostId.toString()
//                               ? {
//                                 'profile_pic': _hostProfilePic,
//                                 'username': _hostUsername,
//                               }
//                               : _userProfiles[user.id],
//                     })
//                     : const SizedBox();
//               }
//               // Customize text message UI with profile pictures for audience
//               ..inRoomMessage.showAvatar = true
//               ..inRoomMessage.showName = true
//               ..inRoomMessage.backgroundColor = Colors.black.withOpacity(0.6)
//               ..inRoomMessage.opacity = 0.8
//               ..inRoomMessage.maxLines = 3
//               ..inRoomMessage.borderRadius = BorderRadius.circular(12)
//               ..inRoomMessage.paddings = const EdgeInsets.symmetric(
//                 horizontal: 8,
//                 vertical: 4,
//               )
//               ..inRoomMessage.nameTextStyle = const TextStyle(
//                 color: Colors.orange,
//                 fontSize: 12,
//                 fontWeight: FontWeight.bold,
//               )
//               ..inRoomMessage.messageTextStyle = const TextStyle(
//                 color: Colors.white,
//                 fontSize: 12,
//               )
//               // Add user ID and profile picture attributes
//               ..inRoomMessage.attributes = () {
//                 return {
//                   'user_id': currentUser?['id']?.toString() ?? '',
//                   'profile_pic': currentUser?['profile_pic'] ?? '',
//                 };
//               }
//               // Custom item builder for enhanced profile picture display
//               ..inRoomMessage.itemBuilder = (
//                 BuildContext context,
//                 ZegoInRoomMessage message,
//                 Map<String, dynamic> extraInfo,
//               ) {
//                 // Get user ID and profile picture from attributes
//                 final attributes = message.attributes;
//                 final userId = attributes['user_id'] ?? '';
//                 final profilePic = attributes['profile_pic'] ?? '';

//                 // Clean username by removing "user_" prefix and avatar info
//                 String cleanUsername = message.user.name;
//                 if (cleanUsername.startsWith('user_')) {
//                   cleanUsername = cleanUsername.substring(5);
//                 }
//                 if (cleanUsername.contains('|avatar:')) {
//                   cleanUsername = cleanUsername.split('|avatar:')[0];
//                 }

//                 return GestureDetector(
//                   onTap: () {
//                     // Only show block popup for hosts
//                     if (widget.isHost) {
//                       _showBlockUserPopup(
//                         context,
//                         cleanUsername,
//                         message.user.id,
//                       );
//                     }
//                   },
//                   child: Container(
//                     margin: const EdgeInsets.symmetric(vertical: 2),
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 8,
//                       vertical: 6,
//                     ),
//                     decoration: BoxDecoration(
//                       color: Colors.black.withOpacity(0.7),
//                       borderRadius: BorderRadius.circular(12),
//                       border: Border.all(
//                         color: Colors.orange.withOpacity(0.3),
//                         width: 1,
//                       ),
//                     ),
//                     child: Row(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         // Profile Picture
//                         Container(
//                           width: 24,
//                           height: 24,
//                           margin: const EdgeInsets.only(right: 8),
//                           child: ClipOval(
//                             child: customAvatarBuilder(
//                               context,
//                               const Size(24, 24),
//                               message.user,
//                               extraInfo,
//                             ),
//                           ),
//                         ),
//                         // Message Content
//                         Expanded(
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               // User Name
//                               Text(
//                                 cleanUsername,
//                                 style: const TextStyle(
//                                   color: Colors.orange,
//                                   fontSize: 11,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                               const SizedBox(height: 2),
//                               // Message Text
//                               Text(
//                                 message.message,
//                                 style: const TextStyle(
//                                   color: Colors.white,
//                                   fontSize: 12,
//                                 ),
//                                 maxLines: 3,
//                                 overflow: TextOverflow.ellipsis,
//                               ),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 );
//               }
//               // Custom button styles for enhanced UI
//               ..bottomMenuBar
//                   .buttonStyle = ZegoLiveStreamingBottomMenuBarButtonStyle(
//                 // Chat button icons with enhanced colors
//                 chatEnabledButtonIcon: Container(
//                   width: 40,
//                   height: 40,
//                   decoration: BoxDecoration(
//                     shape: BoxShape.circle,
//                     gradient: LinearGradient(
//                       colors: [Color(0xFFa18cd1), Color(0xFFfbc2eb)],
//                       begin: Alignment.topLeft,
//                       end: Alignment.bottomRight,
//                     ),
//                   ),
//                   child: const Icon(
//                     Icons.chat_bubble,
//                     color: Colors.white,
//                     size: 24,
//                   ),
//                 ),
//                 chatDisabledButtonIcon: const Icon(
//                   Icons.chat_bubble_outline,
//                   color: Colors.grey,
//                   size: 24,
//                 ),

//                 // Audio output button icons with enhanced colors
//                 switchAudioOutputToSpeakerButtonIcon: Container(
//                   width: 40,
//                   height: 40,
//                   decoration: BoxDecoration(
//                     shape: BoxShape.circle,
//                     gradient: LinearGradient(
//                       colors: [Color(0xFF2193b0), Color(0xFF6dd5ed)],
//                       begin: Alignment.topLeft,
//                       end: Alignment.bottomRight,
//                     ),
//                   ),
//                   child: const Icon(
//                     Icons.volume_up,
//                     color: Colors.white,
//                     size: 24,
//                   ),
//                 ),
//                 switchAudioOutputToHeadphoneButtonIcon: Container(
//                   width: 40,
//                   height: 40,
//                   decoration: BoxDecoration(
//                     shape: BoxShape.circle,
//                     gradient: LinearGradient(
//                       colors: [Color(0xFF2193b0), Color(0xFF6dd5ed)],
//                       begin: Alignment.topLeft,
//                       end: Alignment.bottomRight,
//                     ),
//                   ),
//                   child: const Icon(
//                     Icons.headphones,
//                     color: Colors.white,
//                     size: 24,
//                   ),
//                 ),
//                 switchAudioOutputToBluetoothButtonIcon: Container(
//                   width: 40,
//                   height: 40,
//                   decoration: BoxDecoration(
//                     shape: BoxShape.circle,
//                     gradient: LinearGradient(
//                       colors: [Color(0xFF2193b0), Color(0xFF6dd5ed)],
//                       begin: Alignment.topLeft,
//                       end: Alignment.bottomRight,
//                     ),
//                   ),
//                   child: const Icon(
//                     Icons.bluetooth,
//                     color: Colors.white,
//                     size: 24,
//                   ),
//                 ),

//                 // Leave button icon with enhanced color
//                 leaveButtonIcon: const Icon(
//                   Icons.call_end,
//                   color: Colors.red,
//                   size: 24,
//                 ),

//                 // Beauty effect button icon
//                 beautyEffectButtonIcon: const Icon(
//                   Icons.face,
//                   color: Colors.white,
//                   size: 24,
//                 ),

//                 // Sound effect button icon
//                 soundEffectButtonIcon: const Icon(
//                   Icons.graphic_eq,
//                   color: Colors.white,
//                   size: 24,
//                 ),
//               ));

//     // Add virtual gift, like, and diamond buttons for both host and audience
//     final double buttonSize = 38;
//     final Gradient buttonGradient = const SweepGradient(
//       colors: [
//         Color(0xFFffa030),
//         Color(0xFFfe9b00),
//         Color(0xFFf67d00),
//         Color(0xFFffa030),
//       ],
//       startAngle: 0.0,
//       endAngle: 3.14 * 2,
//       center: Alignment.center,
//     );

//     final giftButton = ZegoMenuBarExtendButton(
//       index: 0,
//       child: Padding(
//         padding: const EdgeInsets.all(8.0),
//         child: Container(
//           width: buttonSize,
//           height: buttonSize,
//           decoration: BoxDecoration(
//             shape: BoxShape.circle,
//             gradient: buttonGradient,
//           ),
//           child: ElevatedButton(
//             style: ElevatedButton.styleFrom(
//               shape: const CircleBorder(),
//               backgroundColor: Colors.transparent,
//               shadowColor: Colors.transparent,
//               padding: EdgeInsets.zero,
//               minimumSize: Size(buttonSize, buttonSize),
//               maximumSize: Size(buttonSize, buttonSize),
//               elevation: 0,
//             ),
//             onPressed: () {
//               _showGiftPanel();
//             },
//             child: const Icon(
//               Icons.card_giftcard,
//               color: Colors.white,
//               size: 22,
//             ),
//           ),
//         ),
//       ),
//     );

//     final likeButton = ZegoMenuBarExtendButton(
//       index: 1,
//       child: Padding(
//         padding: const EdgeInsets.all(8.0),
//         child: GestureDetector(
//           onTap: _triggerLike,
//           child: Container(
//             decoration: const BoxDecoration(
//               shape: BoxShape.circle,
//               color: Colors.white,
//             ),
//             width: buttonSize,
//             height: buttonSize,
//             alignment: Alignment.center,
//             child: const Icon(Icons.favorite, color: Colors.pink, size: 22),
//           ),
//         ),
//       ),
//     );

//     final diamondButton = ZegoMenuBarExtendButton(
//       index: 2,
//       child: Padding(
//         padding: const EdgeInsets.all(8.0),
//         child: GestureDetector(
//           onTap: () {
//             Navigator.of(context).push(
//               MaterialPageRoute(builder: (context) => const StoreScreen()),
//             );
//           },
//           child: Container(
//             width: buttonSize,
//             height: buttonSize,
//             decoration: BoxDecoration(
//               shape: BoxShape.circle,
//               gradient: buttonGradient,
//             ),
//             alignment: Alignment.center,
//             child: Image.asset(
//               'assets/diamond.png',
//               width: 22,
//               height: 22,
//               fit: BoxFit.contain,
//             ),
//           ),
//         ),
//       ),
//     );

//     // Add extend buttons to config
//     if (widget.isHost) {
//       config.bottomMenuBar.hostExtendButtons = [
//         giftButton,
//         likeButton,
//         diamondButton,
//       ];
//     } else {
//       config.bottomMenuBar.audienceExtendButtons = [
//         giftButton,
//         likeButton,
//         diamondButton,
//       ];
//     }

//     return Scaffold(
//       body: Stack(
//         children: [
//           // Background image if provided
//           if (widget.backgroundImage != null)
//             Image.network(
//               'https://server.bharathchat.com/uploads/backgrounds/${widget.backgroundImage}',
//               fit: BoxFit.cover,
//               width: double.infinity,
//               height: double.infinity,
//             ),

//           // Zego UI Kit for audio streaming
//           ZegoUIKitPrebuiltLiveStreaming(
//             appID: appID,
//             appSign: appSign,
//             userID: widget.localUserID,
//             userName:
//                 currentUser != null
//                     ? (currentUser!['first_name'] ??
//                         currentUser!['username'] ??
//                         widget.localUserID)
//                     : widget.localUserID,
//             liveID: widget.liveID,
//             config: config,
//             events: ZegoUIKitPrebuiltLiveStreamingEvents(
//               onError: (ZegoUIKitError error) {
//                 debugPrint('onError: [33m$error [0m');
//               },
//               onStateUpdated: (state) {
//                 debugPrint('onStateUpdated: [33m$state [0m');
//               },
//               onLeaveConfirmation: (
//                 ZegoLiveStreamingLeaveConfirmationEvent event,
//                 Future<bool> Function() defaultAction,
//               ) async {
//                 return await showDialog<bool>(
//                       context: context,
//                       barrierDismissible: false,
//                       builder: (BuildContext context) {
//                         return AlertDialog(
//                           backgroundColor: Colors.black,
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(16),
//                           ),
//                           title: const Text(
//                             "Leave the room",
//                             style: TextStyle(
//                               color: Colors.orange,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                           content: const Text(
//                             "Are you sure you want to leave the live audio room?",
//                             style: TextStyle(color: Colors.white),
//                           ),
//                           actions: [
//                             TextButton(
//                               style: TextButton.styleFrom(
//                                 backgroundColor: Colors.black,
//                                 foregroundColor: Colors.orange,
//                                 side: const BorderSide(color: Colors.orange),
//                                 shape: RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(8),
//                                 ),
//                               ),
//                               onPressed: () => Navigator.of(context).pop(false),
//                               child: const Text(
//                                 'Cancel',
//                                 style: TextStyle(color: Colors.orange),
//                               ),
//                             ),
//                             ElevatedButton(
//                               style: ElevatedButton.styleFrom(
//                                 backgroundColor: Colors.orange,
//                                 foregroundColor: Colors.white,
//                                 shape: RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(8),
//                                 ),
//                               ),
//                               onPressed: () => Navigator.of(context).pop(true),
//                               child: const Text(
//                                 'Leave',
//                                 style: TextStyle(color: Colors.white),
//                               ),
//                             ),
//                           ],
//                         );
//                       },
//                     ) ??
//                     false;
//               },
//             ),
//           ),

//           // Background music control (only for host)
//           if (widget.isHost && widget.backgroundMusic != null)
//             Positioned(
//               top: 100,
//               right: 16,
//               child: GestureDetector(
//                 onTap: _toggleBackgroundMusic,
//                 child: Container(
//                   padding: const EdgeInsets.all(12),
//                   decoration: BoxDecoration(
//                     color: Colors.black54,
//                     borderRadius: BorderRadius.circular(25),
//                   ),
//                   child: Icon(
//                     _isPlaying ? Icons.pause : Icons.play_arrow,
//                     color: Colors.white,
//                     size: 24,
//                   ),
//                 ),
//               ),
//             ),

//           // User avatars - Horizontal layout on left side
//           // if (_zegoUsers.isNotEmpty)
//           //   Positioned(
//           //     top: 100,
//           //     left: 20,
//           //     child: Row(
//           //       mainAxisSize: MainAxisSize.min,
//           //       children:
//           //           _zegoUsers.map<Widget>((zUser) {
//           //             final userId =
//           //                 zUser.id ??
//           //                 zUser.userID ??
//           //                 zUser['userID'] ??
//           //                 zUser['id'];
//           //             final user = _userProfiles[userId];
//           //             final profilePic =
//           //                 user != null ? user['profile_pic'] : null;
//           //             return Padding(
//           //               padding: const EdgeInsets.symmetric(horizontal: 8.0),
//           //               child: CircleAvatar(
//           //                 radius: 35,
//           //                 child:
//           //                     profilePic != null && profilePic.isNotEmpty
//           //                         ? ClipOval(
//           //                           child: CachedNetworkImage(
//           //                             imageUrl:
//           //                                 profilePic.startsWith('http')
//           //                                     ? profilePic
//           //                                     : 'https://server.bharathchat.com/$profilePic',
//           //                             width: 70,
//           //                             height: 70,
//           //                             fit: BoxFit.cover,
//           //                             placeholder:
//           //                                 (context, url) => Container(
//           //                                   width: 70,
//           //                                   height: 70,
//           //                                   decoration: BoxDecoration(
//           //                                     shape: BoxShape.circle,
//           //                                     color: Colors.grey[300],
//           //                                   ),
//           //                                   child: Icon(
//           //                                     Icons.person,
//           //                                     size: 35,
//           //                                     color: Colors.grey[600],
//           //                                   ),
//           //                                 ),
//           //                             errorWidget:
//           //                                 (context, url, error) => Container(
//           //                                   width: 70,
//           //                                   height: 70,
//           //                                   decoration: BoxDecoration(
//           //                                     shape: BoxShape.circle,
//           //                                     color: Colors.grey[300],
//           //                                   ),
//           //                                   child: Icon(
//           //                                     Icons.person,
//           //                                     size: 35,
//           //                                     color: Colors.grey[600],
//           //                                   ),
//           //                                 ),
//           //                           ),
//           //                         )
//           //                         : Icon(Icons.person, size: 35),
//           //               ),
//           //             );
//           //           }).toList(),
//           //     ),
//           //   ),

//           // OPTION 2: Vertical stack on right side (uncomment to use)
//           /*
//             Positioned(
//               top: 100,
//               right: 20,
//               child: Column(
//                 children: _zegoUsers.map<Widget>((zUser) {
//                   final userId = zUser.id ?? zUser.userID ?? zUser['userID'] ?? zUser['id'];
//                   final user = _userProfiles[userId];
//                   final profilePic = user != null ? user['profile_pic'] : null;
//                   return Padding(
//                     padding: const EdgeInsets.symmetric(vertical: 8.0),
//                     child: CircleAvatar(
//                       radius: 35,
//                       child: profilePic != null && profilePic.isNotEmpty
//                           ? ClipOval(
//                               child: CachedNetworkImage(
//                                 imageUrl: profilePic.startsWith('http')
//                                     ? profilePic
//                                     : 'https://server.bharathchat.com/$profilePic',
//                                 width: 70,
//                                 height: 70,
//                                 fit: BoxFit.cover,
//                                 placeholder: (context, url) => Container(
//                                   width: 70,
//                                   height: 70,
//                                   decoration: BoxDecoration(
//                                     shape: BoxShape.circle,
//                                     color: Colors.grey[300],
//                                   ),
//                                   child: Icon(Icons.person, size: 35, color: Colors.grey[600]),
//                                 ),
//                                 errorWidget: (context, url, error) => Container(
//                                   width: 70,
//                                   height: 70,
//                                   decoration: BoxDecoration(
//                                     shape: BoxShape.circle,
//                                     color: Colors.grey[300],
//                                   ),
//                                   child: Icon(Icons.person, size: 35, color: Colors.grey[600]),
//                                 ),
//                               ),
//                             )
//                           : Icon(Icons.person, size: 35),
//                     ),
//                   );
//                 }).toList(),
//               ),
//             ),
//             */

//           // OPTION 3: Grid layout (uncomment to use)
//           Positioned(
//             top: 100,
//             left: 20,
//             right: 20,
//             child: Wrap(
//               spacing: 12,
//               runSpacing: 12,
//               alignment: WrapAlignment.center,
//               children:
//                   _zegoUsers.map<Widget>((zUser) {
//                     final userId =
//                         zUser.id ??
//                         zUser.userID ??
//                         zUser['userID'] ??
//                         zUser['id'];
//                     final user = _userProfiles[userId];
//                     final profilePic =
//                         user != null ? user['profile_pic'] : null;
//                     return CircleAvatar(
//                       radius: 30,
//                       child:
//                           profilePic != null && profilePic.isNotEmpty
//                               ? ClipOval(
//                                 child: CachedNetworkImage(
//                                   imageUrl:
//                                       profilePic.startsWith('http')
//                                           ? profilePic
//                                           : 'https://server.bharathchat.com/$profilePic',
//                                   width: 60,
//                                   height: 60,
//                                   fit: BoxFit.cover,
//                                   placeholder:
//                                       (context, url) => Container(
//                                         width: 60,
//                                         height: 60,
//                                         decoration: BoxDecoration(
//                                           shape: BoxShape.circle,
//                                           color: Colors.grey[300],
//                                         ),
//                                         child: Icon(
//                                           Icons.person,
//                                           size: 30,
//                                           color: Colors.grey[600],
//                                         ),
//                                       ),
//                                   errorWidget:
//                                       (context, url, error) => Container(
//                                         width: 60,
//                                         height: 60,
//                                         decoration: BoxDecoration(
//                                           shape: BoxShape.circle,
//                                           color: Colors.grey[300],
//                                         ),
//                                         child: Icon(
//                                           Icons.person,
//                                           size: 30,
//                                           color: Colors.grey[600],
//                                         ),
//                                       ),
//                                 ),
//                               )
//                               : Icon(Icons.person, size: 30),
//                     );
//                   }).toList(),
//             ),
//           ),

//           // OPTION 4: Bottom horizontal bar (uncomment to use)
//           /*
//             Positioned(
//               bottom: 120,
//               left: 0,
//               right: 0,
//               child: Container(
//                 height: 80,
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: _zegoUsers.map<Widget>((zUser) {
//                     final userId = zUser.id ?? zUser.userID ?? zUser['userID'] ?? zUser['id'];
//                     final user = _userProfiles[userId];
//                     final profilePic = user != null ? user['profile_pic'] : null;
//                     return Padding(
//                       padding: const EdgeInsets.symmetric(horizontal: 6.0),
//                       child: CircleAvatar(
//                         radius: 35,
//                         child: profilePic != null && profilePic.isNotEmpty
//                             ? ClipOval(
//                                 child: CachedNetworkImage(
//                                   imageUrl: profilePic.startsWith('http')
//                                       ? profilePic
//                                       : 'https://server.bharathchat.com/$profilePic',
//                                   width: 70,
//                                   height: 70,
//                                   fit: BoxFit.cover,
//                                   placeholder: (context, url) => Container(
//                                     width: 70,
//                                     height: 70,
//                                     decoration: BoxDecoration(
//                                       shape: BoxShape.circle,
//                                       color: Colors.grey[300],
//                                     ),
//                                     child: Icon(Icons.person, size: 35, color: Colors.grey[600]),
//                                   ),
//                                   errorWidget: (context, url, error) => Container(
//                                     width: 70,
//                                     height: 70,
//                                     decoration: BoxDecoration(
//                                       shape: BoxShape.circle,
//                                       color: Colors.grey[300],
//                                     ),
//                                     child: Icon(Icons.person, size: 35, color: Colors.grey[600]),
//                                   ),
//                                 ),
//                               )
//                             : Icon(Icons.person, size: 35),
//                       ),
//                     );
//                   }).toList(),
//                 ),
//               ),
//             ),
//             */

//           // OPTION 5: Corner positioning (uncomment to use)
//           /*
//             Positioned(
//               top: 80,
//               left: 20,
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     'Participants (${_zegoUsers.length})',
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontSize: 14,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   SizedBox(height: 8),
//                   ..._zegoUsers.map<Widget>((zUser) {
//                     final userId = zUser.id ?? zUser.userID ?? zUser['userID'] ?? zUser['id'];
//                     final user = _userProfiles[userId];
//                     final profilePic = user != null ? user['profile_pic'] : null;
//                     return Padding(
//                       padding: const EdgeInsets.symmetric(vertical: 4.0),
//                       child: Row(
//                         children: [
//                           CircleAvatar(
//                             radius: 20,
//                             child: profilePic != null && profilePic.isNotEmpty
//                                 ? ClipOval(
//                                     child: CachedNetworkImage(
//                                       imageUrl: profilePic.startsWith('http')
//                                           ? profilePic
//                                           : 'https://server.bharathchat.com/$profilePic',
//                                       width: 40,
//                                       height: 40,
//                                       fit: BoxFit.cover,
//                                       placeholder: (context, url) => Container(
//                                         width: 40,
//                                         height: 40,
//                                         decoration: BoxDecoration(
//                                           shape: BoxShape.circle,
//                                           color: Colors.grey[300],
//                                         ),
//                                         child: Icon(Icons.person, size: 20, color: Colors.grey[600]),
//                                       ),
//                                       errorWidget: (context, url, error) => Container(
//                                         width: 40,
//                                         height: 40,
//                                         decoration: BoxDecoration(
//                                           shape: BoxShape.circle,
//                                           color: Colors.grey[300],
//                                         ),
//                                         child: Icon(Icons.person, size: 20, color: Colors.grey[600]),
//                                       ),
//                                     ),
//                                   )
//                                 : Icon(Icons.person, size: 20),
//                           ),
//                           SizedBox(width: 8),
//                           Text(
//                             user?['username'] ?? user?['first_name'] ?? 'User',
//                             style: TextStyle(
//                               color: Colors.white,
//                               fontSize: 12,
//                             ),
//                           ),
//                         ],
//                       ),
//                     );
//                   }).toList(),
//                 ],
//               ),
//             ),
//             */

//           // Burst hearts overlay
//           ..._burstHearts.map(
//             (w) => Positioned(
//               bottom: 80,
//               left:
//                   MediaQuery.of(context).size.width / 2 -
//                   20 +
//                   (Random().nextDouble() * 40 - 20),
//               child: w,
//             ),
//           ),

//           // Overlay active gift animations
//           ..._activeGiftAnimations,

//           // Gift Animations
//           ...giftAnimations.map(
//             (anim) => GiftAnimation(
//               giftName: anim['giftName'],
//               gifUrl: anim['gifUrl'],
//               senderName: anim['senderName'],
//               pkBattleSide: anim['pkBattleSide'],
//               onAnimationComplete: () => _removeGiftAnimation(anim['id']),
//             ),
//           ),

//           // Gift Panel
//           if (showGiftPanel)
//             Positioned.fill(
//               child: GestureDetector(
//                 onTap: _hideGiftPanel,
//                 child: Container(
//                   color: Colors.black54,
//                   child: Center(
//                     child: FractionallySizedBox(
//                       heightFactor: 0.5,
//                       child: GiftPanel(
//                         receiverId: widget.hostId,
//                         roomId: widget.liveID,
//                         onGiftSent: _hideGiftPanel,
//                         // REMOVED: onGiftAnimation: _showGiftAnimation,
//                         // Animations are now handled by polling system to prevent duplicates
//                         onClose: _hideGiftPanel,
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ),

//           // Watermark logo in top left
//           Positioned(
//             top: 100,
//             left: 12,
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Opacity(
//                   opacity: 0.5,
//                   child: Container(
//                     margin: const EdgeInsets.only(left: 28),
//                     child: Image.asset(
//                       'assets/logo.png',
//                       width: 36,
//                       height: 36,
//                       fit: BoxFit.contain,
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 4),
//                 Opacity(
//                   opacity: 0.5,
//                   child: ShaderMask(
//                     shaderCallback: (Rect bounds) {
//                       return const LinearGradient(
//                         colors: [
//                           Color(0xFFffa030),
//                           Color(0xFFfe9b00),
//                           Color(0xFFf67d00),
//                         ],
//                         begin: Alignment.topLeft,
//                         end: Alignment.bottomRight,
//                       ).createShader(bounds);
//                     },
//                     child: const Text(
//                       'Bharath Chat',
//                       style: TextStyle(
//                         fontSize: 14,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.white,
//                         letterSpacing: 1.1,
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // Show block user popup
//   void _showBlockUserPopup(
//     BuildContext context,
//     String userName,
//     String userId,
//   ) {
//     showDialog(
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
//           content: Text(
//             'Are you sure you want to block $userName?',
//             style: const TextStyle(color: Colors.white70, fontSize: 16),
//           ),
//           actions: [
//             TextButton(
//               style: TextButton.styleFrom(
//                 backgroundColor: Colors.transparent,
//                 foregroundColor: Colors.grey,
//                 side: const BorderSide(color: Colors.grey),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//               ),
//               onPressed: () => Navigator.of(context).pop(),
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
//               onPressed: () async {
//                 Navigator.of(context).pop();
//                 await _blockUser(userId);
//               },
//               child: const Text('Block', style: TextStyle(color: Colors.white)),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   // Check if current user is blocked by the host
//   Future<bool> _checkIfUserIsBlocked() async {
//     try {
//       if (widget.isHost)
//         return false; // Hosts can't be blocked in their own stream

//       final currentUser = await ApiService.getCurrentUser();
//       if (currentUser == null) return false;

//       // Get the host's blocked users list using the correct API
//       final relations = await ApiService.getUserSimpleRelations(widget.hostId);
//       final blockedIds = List<int>.from(relations['blocked'] ?? []);

//       // Check if current user is in the blocked list
//       return blockedIds.contains(currentUser['id']);
//     } catch (e) {
//       debugPrint('Error checking if user is blocked: $e');
//       return false;
//     }
//   }

//   // Block checking timer
//   Timer? _blockCheckTimer;
//   bool _isUserBlocked = false;

//   void _startBlockChecking() {
//     if (widget.isHost) return; // Only check for audience members

//     _blockCheckTimer?.cancel();
//     _blockCheckTimer = Timer.periodic(const Duration(seconds: 5), (
//       timer,
//     ) async {
//       final isBlocked = await _checkIfUserIsBlocked();
//       if (isBlocked && !_isUserBlocked) {
//         setState(() {
//           _isUserBlocked = true;
//         });
//         if (mounted) {
//           // Show blocking message and navigate back
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(
//               content: Text(
//                 'You have been blocked by the host and cannot view this live stream',
//               ),
//               backgroundColor: Colors.red,
//               duration: Duration(seconds: 3),
//             ),
//           );
//           // Navigate back to previous screen after a short delay
//           Future.delayed(const Duration(seconds: 3), () {
//             if (mounted) {
//               Navigator.of(context).pop();
//             }
//           });
//         }
//       } else if (!isBlocked && _isUserBlocked) {
//         setState(() {
//           _isUserBlocked = false;
//         });
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(
//               content: Text('You have been unblocked by the host'),
//               backgroundColor: Colors.green,
//               duration: Duration(seconds: 3),
//             ),
//           );
//         }
//       }
//     });
//   }

//   void _stopBlockChecking() {
//     _blockCheckTimer?.cancel();
//     _blockCheckTimer = null;
//   }

//   // Block user method
//   Future<void> _blockUser(String userId) async {
//     try {
//       // Handle different user ID formats from live streaming
//       int userIdInt;

//       // First, try to get the user ID from the app's user list by username
//       // This is the most reliable way since we need the actual database user ID
//       final allUsers = await ApiService.getAllUsers();

//       // Clean the username by removing any prefixes
//       String cleanUsername = userId;
//       if (userId.startsWith('user_')) {
//         cleanUsername = userId.substring(5);
//       }

//       // Try to find the user by username first
//       final user = allUsers.firstWhere(
//         (u) =>
//             u['username'] == cleanUsername ||
//             u['id'].toString() == cleanUsername,
//         orElse: () => null,
//       );

//       if (user != null) {
//         userIdInt = user['id'] as int;
//       } else {
//         // Fallback: try to parse as integer
//         try {
//           userIdInt = int.parse(cleanUsername);
//         } catch (e) {
//           throw Exception('User not found in the system');
//         }
//       }

//       await ApiService.blockUser(userIdInt);
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('User blocked successfully'),
//           backgroundColor: Colors.green,
//         ),
//       );
//     } catch (e) {
//       String errorMsg = 'Failed to block user';
//       if (e is Exception && e.toString().contains('Exception:')) {
//         errorMsg = e.toString().replaceFirst('Exception: ', '');
//       }
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
//       );
//     }
//   }
// }

// // AnimatedHeart widget for burst effect
// class AnimatedHeart extends StatefulWidget {
//   final Duration delay;
//   final Random random;
//   const AnimatedHeart({Key? key, required this.delay, required this.random})
//     : super(key: key);

//   @override
//   State<AnimatedHeart> createState() => _AnimatedHeartState();
// }

// class _AnimatedHeartState extends State<AnimatedHeart>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _controller;
//   late Animation<double> _moveUp;
//   late Animation<double> _fade;
//   late double _xOffset;

//   @override
//   void initState() {
//     super.initState();
//     _xOffset = widget.random.nextDouble() * 60 - 30;
//     _controller = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 900),
//     );
//     _moveUp = Tween<double>(
//       begin: 0,
//       end: -80,
//     ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
//     _fade = Tween<double>(
//       begin: 1,
//       end: 0,
//     ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
//     Future.delayed(widget.delay, () {
//       if (mounted) _controller.forward();
//     });
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return AnimatedBuilder(
//       animation: _controller,
//       builder: (context, child) {
//         return Opacity(
//           opacity: _fade.value,
//           child: Transform.translate(
//             offset: Offset(_xOffset, _moveUp.value),
//             child: Icon(Icons.favorite, color: Colors.pink, size: 28),
//           ),
//         );
//       },
//     );
//   }
// }
