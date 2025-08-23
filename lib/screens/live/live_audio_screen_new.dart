import 'package:flutter/material.dart';
import 'package:zego_uikit_prebuilt_live_audio_room/zego_uikit_prebuilt_live_audio_room.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:just_audio/just_audio.dart';
import 'gift_panel.dart';
import 'gift_animation.dart';
import '../../services/api_service.dart';
import '../../services/live_stream_service.dart';
import 'package:finalchat/pk_widgets/config.dart';
import 'package:finalchat/pk_widgets/events.dart';
import 'package:finalchat/pk_widgets/surface.dart';
import 'package:finalchat/pk_widgets/widgets/mute_button.dart';
import 'package:finalchat/common.dart';
import 'package:finalchat/constants.dart';
import 'live_page.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:finalchat/screens/main/store_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:zego_uikit/zego_uikit.dart';

/// Live Audio Screen with ZEGOCLOUD Seat Customization Features
///
/// This screen implements advanced seat customization features from ZEGOCLOUD Live Audio Room Kit:
///
/// 1. **Custom Seat Layout**:
///    - Host seat (index 0) in center of first row
///    - 4 seats in second row with spaceAround alignment
///    - 4 seats in third row with spaceAround alignment
///
/// 2. **Custom Seat UI**:
///    - Host seat has orange gradient background with glow effect
///    - Speaker seats have blue gradient background
///    - Username labels with different styling for host vs speakers
///    - Host star icon and speaker mic icons
///    - Seat number indicators
///
/// 3. **Visual Enhancements**:
///    - Custom avatar builder with profile pictures
///    - Sound wave animations
///    - Gradient backgrounds and shadows
///
/// 4. **Interactive Features**:
///    - Custom seat click dialogs (take seat, user options)
///    - Host controls (remove user, mute, block)
///    - Audience actions (send gift, view profile)
///
/// Based on ZEGOCLOUD documentation: https://www.zegocloud.com/docs/uikit/live-audio-room-kit-flutter/custom-prebuilt-features/customize-the-seats

class LiveAudioScreenNew extends StatefulWidget {
  final String liveID;
  final String localUserID;
  final bool isHost;
  final int hostId;
  final String? backgroundImage;
  final String? backgroundMusic;
  final String? profilePic;

  const LiveAudioScreenNew({
    Key? key,
    required this.liveID,
    required this.localUserID,
    required this.hostId,
    this.isHost = false,
    this.backgroundImage,
    this.backgroundMusic,
    this.profilePic,
  }) : super(key: key);

  @override
  State<LiveAudioScreenNew> createState() => _LiveAudioScreenNewState();
}

class _LiveAudioScreenNewState extends State<LiveAudioScreenNew>
    with SingleTickerProviderStateMixin {
  final _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  final int appID = 615877954; // Your ZEGOCLOUD AppID
  final String appSign =
      "12e07321bd8231dda371ea9235e274178403bd97a7ccabcb09e22474c42da3a4"; // Your ZEGOCLOUD AppSign

  // Background selection state
  String _selectedBackground = 'assets/background.jpg';
  final List<Map<String, String>> _availableBackgrounds = [
    {'name': 'Template 1', 'path': 'assets/2.png'},
    {'name': 'Template 2', 'path': 'assets/template1.png'},
    {'name': 'Template 3', 'path': 'assets/background.jpg'},
    {'name': 'Template 4', 'path': 'assets/3.png'},
    {'name': 'Template 5', 'path': 'assets/4.png'},
    {'name': 'Template 6', 'path': 'assets/5.png'},

    // {'name': 'Template 6', 'path': 'assets/template6.png'},
    // {'name': 'Template 7', 'path': 'assets/template7.png'},
    // {'name': 'Template 8', 'path': 'assets/template8.png'},
  ];

  // Gift panel state
  bool showGiftPanel = false;
  List<Map<String, dynamic>> giftAnimations = [];

  Map<String, dynamic>? currentUser;
  Map<String, dynamic>? hostUser;
  final LiveStreamService _liveStreamService = LiveStreamService();
  List<dynamic> _zegoUsers = [];
  Map<String, dynamic> _userProfiles = {};
  StreamSubscription? _userListSub;
  List<dynamic> _allUsers = [];

  // Gift state
  List<dynamic> _gifts = [];
  bool _giftsLoading = true;
  bool _sendingGift = false;
  List<Widget> _activeGiftAnimations = [];
  int _giftAnimKey = 0;

  // Global deduplication for gift animations to prevent duplicates
  final Set<String> _globalProcessedAnimations = {};
  DateTime _lastAnimationCleanup = DateTime.now();

  // Gift polling for synchronization
  Timer? _giftPollingTimer;
  DateTime _lastGiftCheck = DateTime.now();
  final Set<String> _processedGifts = {};

  // Host profile picture and username for top menu bar
  String? _hostProfilePic;
  String? _hostUsername;

  @override
  void initState() {
    super.initState();
    if (widget.backgroundMusic != null) {
      _setupBackgroundMusic();
    }
    _loadCurrentUser();
    _loadHostUser();
    _fetchAllUsers();
    _fetchHostProfilePicture();

    _userListSub = ZegoUIKit().getUserListStream().listen((zegoUsers) {
      setState(() {
        _zegoUsers = zegoUsers;
      });
      _mapZegoUsersToProfiles(zegoUsers);
    });

    _fetchGiftsAndUser();
    _startGiftPolling();

    // Start block checking for audience members
    _startBlockChecking();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _userListSub?.cancel();
    _stopGiftPolling();
    _stopBlockChecking();
    super.dispose();
  }

  // Background music setup
  void _setupBackgroundMusic() async {
    try {
      await _audioPlayer.setUrl(widget.backgroundMusic!);
      await _audioPlayer.setLoopMode(LoopMode.one);
      await _audioPlayer.play();
      setState(() {
        _isPlaying = true;
      });
    } catch (e) {
      print('Error setting up background music: $e');
    }
  }

  // Gift panel functions
  void _showGiftPanel() {
    setState(() {
      showGiftPanel = true;
    });
  }

  void _hideGiftPanel() {
    setState(() {
      showGiftPanel = false;
    });
  }

  void _showGiftAnimation(
    String giftName,
    String gifUrl,
    String senderName, {
    String? pkBattleSide,
  }) {
    setState(() {
      giftAnimations.add({
        'giftName': giftName,
        'gifUrl': gifUrl,
        'senderName': senderName,
        'pkBattleSide': pkBattleSide,
        'id': DateTime.now().millisecondsSinceEpoch,
      });
    });
  }

  void _removeGiftAnimation(int id) {
    setState(() {
      giftAnimations.removeWhere((animation) => animation['id'] == id);
    });
  }

  // Gift polling methods for synchronization
  void _startGiftPolling() {
    _giftPollingTimer?.cancel();
    _giftPollingTimer = Timer.periodic(const Duration(milliseconds: 500), (
      timer,
    ) {
      // For audio screen (non-PK), use user gifts received endpoint
      final int targetUserId =
          widget.isHost
              ? (currentUser?['id'] as int? ?? widget.hostId)
              : widget.hostId;
      _pollUserGiftsReceived(targetUserId);
    });
  }

  void _stopGiftPolling() {
    _giftPollingTimer?.cancel();
    _giftPollingTimer = null;
  }

  // Poll gifts received by specific user and display
  Future<void> _pollUserGiftsReceived(int targetUserId) async {
    try {
      final data = await ApiService.getUserGiftsReceived(
        userIdentifier: targetUserId,
      );
      if (data == null) return;
      final List<dynamic>? recentGifts = data['recent_gifts'] as List<dynamic>?;
      if (recentGifts == null || recentGifts.isEmpty) return;

      for (final dynamic g in recentGifts) {
        final Map<String, dynamic> gift = g as Map<String, dynamic>;
        // Time-based filtering to avoid replaying old gifts too frequently
        final String? receivedAtStr = gift['received_at'] as String?;
        if (receivedAtStr != null) {
          try {
            final receivedAt = DateTime.parse(receivedAtStr);
            if (!receivedAt.isAfter(_lastGiftCheck)) {
              continue;
            }
          } catch (_) {}
        }

        // Deduplication by transaction_id
        final int? txnId =
            (gift['transaction_id'] is int)
                ? gift['transaction_id'] as int
                : int.tryParse('${gift['transaction_id']}');
        if (txnId == null) continue;
        final giftKey = 'user_${targetUserId}_txn_$txnId';
        if (_processedGifts.contains(giftKey)) continue;
        _processedGifts.add(giftKey);

        // Play audio (2s delay)
        final dynamic audioFilenameRaw = gift['audio_filename'];
        final String? audioFilename =
            (audioFilenameRaw is String)
                ? audioFilenameRaw
                : (audioFilenameRaw?.toString());
        if (audioFilename != null && audioFilename.isNotEmpty) {
          try {
            final audioUrl =
                'https://server.bharathchat.com/uploads/audio/$audioFilename';
            debugPrint(
              '🎁 (User $targetUserId) Playing received gift audio: $audioUrl',
            );
            await Future.delayed(const Duration(milliseconds: 200));
            if (mounted) {
              await _audioPlayer.setUrl(audioUrl);
              await _audioPlayer.play();
            }
          } catch (e) {
            debugPrint(
              '🎁 (User $targetUserId) Error playing received gift audio: $e',
            );
          }
        }

        // Animation
        String gifUrl;
        final dynamic gifUrlRaw = gift['gif_url'];
        if (gifUrlRaw is String && gifUrlRaw.isNotEmpty) {
          gifUrl =
              gifUrlRaw.startsWith('http')
                  ? gifUrlRaw
                  : 'https://server.bharathchat.com$gifUrlRaw';
        } else {
          final dynamic gifFilenameRaw = gift['gif_filename'];
          final String gifFilename =
              (gifFilenameRaw is String)
                  ? gifFilenameRaw
                  : (gifFilenameRaw?.toString() ?? '');
          gifUrl = 'https://server.bharathchat.com/uploads/gifts/$gifFilename';
        }
        final Map<String, dynamic>? sender =
            gift['sender'] as Map<String, dynamic>?;
        final String senderName =
            sender?['username'] as String? ??
            sender?['first_name'] as String? ??
            'User';
        final String giftName = gift['gift_name'] as String? ?? 'Gift';
        _createGiftAnimation(giftName, gifUrl, senderName);
      }

      _lastGiftCheck = DateTime.now();
    } catch (e) {
      debugPrint('❌ Error polling user gifts received: $e');
    }
  }

  // Create gift animation (reusable method)
  void _createGiftAnimation(String giftName, String gifUrl, String senderName) {
    // Clean up old animation keys every 5 minutes to prevent memory leaks
    final now = DateTime.now();
    if (now.difference(_lastAnimationCleanup).inMinutes >= 5) {
      _globalProcessedAnimations.clear();
      _lastAnimationCleanup = now;
      debugPrint('🎁 Cleaned up old animation deduplication keys');
    }

    // Create a unique key for this animation
    final animationKey =
        '${senderName}_${giftName}_${DateTime.now().millisecondsSinceEpoch}';

    // Check if this animation was already processed
    if (_globalProcessedAnimations.contains(animationKey)) {
      debugPrint('🎁 Animation already processed, skipping: $animationKey');
      return;
    }

    // Add to processed animations
    _globalProcessedAnimations.add(animationKey);

    debugPrint('🎁 Creating gift animation:');
    debugPrint('🎁   - Gift Name: $giftName');
    debugPrint('🎁   - GIF URL: $gifUrl');
    debugPrint('🎁   - Sender: $senderName');
    debugPrint('🎁   - Animation Key: $animationKey');

    setState(() {
      _activeGiftAnimations.add(
        GiftAnimation(
          key: ValueKey('gift_anim_${_giftAnimKey++}'),
          giftName: giftName,
          gifUrl: gifUrl,
          senderName: senderName,
          onAnimationComplete: () {
            debugPrint('🎁 Gift animation completed, removing from list');
            setState(() {
              _activeGiftAnimations.removeWhere(
                (w) =>
                    (w.key as ValueKey).value ==
                    'gift_anim_${_giftAnimKey - 1}',
              );
            });
          },
        ),
      );
    });
  }

  Future<void> _fetchGiftsAndUser() async {
    setState(() {
      _giftsLoading = true;
    });
    try {
      final gifts = await ApiService.getGifts();
      final user = await ApiService.getCurrentUser();
      setState(() {
        _gifts = gifts;
        currentUser = user;
        _giftsLoading = false;
      });
    } catch (e) {
      setState(() {
        _giftsLoading = false;
      });
    }
  }

  Future<void> _loadCurrentUser() async {
    try {
      debugPrint('🔄 [AVATAR] Loading current user...');
      final userData = await ApiService.getCurrentUser();
      debugPrint('🔄 [AVATAR] Current user data: $userData');
      debugPrint(
        '🔄 [AVATAR] Current user profile pic: ${userData['profile_pic']}',
      );

      setState(() {
        currentUser = userData;
      });

      // Also add current user to user profiles for avatar builder
      if (userData != null && userData['profile_pic'] != null) {
        String profilePic = userData['profile_pic'] as String;
        if (profilePic.isNotEmpty) {
          String profilePicUrl =
              profilePic.startsWith('http')
                  ? profilePic
                  : 'https://server.bharathchat.com/$profilePic';

          _userProfiles[widget.localUserID] = {
            'profile_pic': userData['profile_pic'],
            'profile_pic_url': profilePicUrl,
            'username': userData['username'] ?? userData['first_name'],
            'user_id': userData['id'],
          };
          debugPrint(
            '✅ [AVATAR] Added current user to profiles: ${widget.localUserID}',
          );
        }
      }
    } catch (e) {
      debugPrint('❌ [AVATAR] Error loading current user: $e');
    }
  }

  Future<void> _loadHostUser() async {
    try {
      // For now, we'll assume the host is the current user
      // In a real implementation, you'd get the host info from the live stream data
      final userData = await ApiService.getCurrentUser();
      setState(() {
        hostUser = userData;
      });
    } catch (e) {
      print('Error loading host user: $e');
    }
  }

  // Fetch host profile picture and username for top menu bar
  Future<void> _fetchHostProfilePicture() async {
    try {
      debugPrint('🔄 [HOST_PROFILE] Starting host profile fetch...');
      debugPrint('🔄 [HOST_PROFILE] isHost: ${widget.isHost}');
      debugPrint('🔄 [HOST_PROFILE] hostId: ${widget.hostId}');
      debugPrint('🔄 [HOST_PROFILE] currentUser: ${currentUser != null}');

      if (widget.isHost) {
        // For host, use current user's profile picture and username
        if (currentUser != null) {
          setState(() {
            _hostProfilePic = currentUser!['profile_pic'];
            _hostUsername =
                currentUser!['username'] ??
                currentUser!['first_name'] ??
                'Host';
          });
          debugPrint(
            '✅ [HOST_PROFILE] Fetched host profile picture: $_hostProfilePic',
          );
          debugPrint('✅ [HOST_PROFILE] Fetched host username: $_hostUsername');
        }
      } else {
        // For audience, fetch host's profile picture and username
        try {
          final hostData = await ApiService.getUserById(widget.hostId);
          if (hostData != null) {
            setState(() {
              _hostProfilePic = hostData['profile_pic'];
              _hostUsername =
                  hostData['username'] ?? hostData['first_name'] ?? 'Host';
            });
            debugPrint(
              '✅ [HOST_PROFILE] Fetched host profile picture: $_hostProfilePic',
            );
            debugPrint(
              '✅ [HOST_PROFILE] Fetched host username: $_hostUsername',
            );
          }
        } catch (e) {
          debugPrint('❌ [HOST_PROFILE] Error fetching host data: $e');
        }
      }
    } catch (e) {
      debugPrint('❌ [HOST_PROFILE] Error in _fetchHostProfilePicture: $e');
    }
  }

  Future<void> _fetchAllUsers() async {
    try {
      debugPrint('🔄 [AVATAR] Fetching all users...');
      final users = await ApiService.getAllUsers();
      debugPrint('🔄 [AVATAR] Fetched ${users.length} users');

      // Log a few sample users to see their structure
      if (users.isNotEmpty) {
        debugPrint('🔄 [AVATAR] Sample user 1: ${users.first}');
        if (users.length > 1) {
          debugPrint('🔄 [AVATAR] Sample user 2: ${users[1]}');
        }
      }

      setState(() {
        _allUsers = users;
      });
    } catch (e) {
      debugPrint('❌ [AVATAR] Error fetching all users: $e');
    }
  }

  void _mapZegoUsersToProfiles(List<dynamic> zegoUsers) {
    debugPrint(
      '🔄 [AVATAR] Mapping ${zegoUsers.length} Zego users to profiles',
    );
    debugPrint('🔄 [AVATAR] All users count: ${_allUsers.length}');

    for (final zegoUser in zegoUsers) {
      final String zegoUserId = zegoUser.id;
      debugPrint('🔄 [AVATAR] Processing Zego user: $zegoUserId');

      // Try to extract user ID from Zego user ID
      int? userId;

      // Check if it's a numeric ID
      if (int.tryParse(zegoUserId) != null) {
        userId = int.parse(zegoUserId);
        debugPrint('🔄 [AVATAR] Extracted numeric user ID: $userId');
      } else if (zegoUserId.startsWith('user_')) {
        // Extract ID from "user_123" format
        final idPart = zegoUserId.substring(5);
        userId = int.tryParse(idPart);
        debugPrint(
          '🔄 [AVATAR] Extracted user ID from "user_" prefix: $userId',
        );
      } else {
        debugPrint('🔄 [AVATAR] Could not extract user ID from: $zegoUserId');
      }

      if (userId != null) {
        // Try to find in all users list first (faster)
        final appUser = _allUsers.firstWhere(
          (u) => u['id'] == userId,
          orElse: () => null,
        );
        if (appUser != null) {
          debugPrint('🔄 [AVATAR] Found user $userId in all users list');
          String? profilePicUrl = appUser['profile_pic'];
          if (profilePicUrl != null && profilePicUrl.isNotEmpty) {
            // Format the URL like the rest of the app
            if (!profilePicUrl.startsWith('http')) {
              profilePicUrl = 'https://server.bharathchat.com/$profilePicUrl';
            }
            debugPrint('🔄 [AVATAR] Profile pic URL: $profilePicUrl');
          } else {
            debugPrint('🔄 [AVATAR] No profile pic found for user $userId');
          }

          _userProfiles[zegoUserId] = {
            'profile_pic': appUser['profile_pic'],
            'profile_pic_url': profilePicUrl, // Add formatted URL
            'username': appUser['username'] ?? appUser['first_name'],
            'user_id': userId,
          };
          debugPrint(
            '✅ [AVATAR] Mapped user $zegoUserId (ID: $userId) to profile from all users list',
          );
        } else {
          debugPrint(
            '🔄 [AVATAR] User $userId not found in all users list, fetching from API',
          );
          // If not found in all users list, fetch from API asynchronously
          _fetchUserAvatarAsync(userId, zegoUserId);
        }
      } else {
        debugPrint(
          '🔄 [AVATAR] Trying fallback username matching for: $zegoUserId',
        );
        // Fallback: try to find by username in all users list
        final appUser = _allUsers.firstWhere(
          (user) =>
              user['username'] == zegoUserId ||
              user['id'].toString() == zegoUserId,
          orElse: () => null,
        );
        if (appUser != null) {
          debugPrint('🔄 [AVATAR] Found user by username fallback');
          String? profilePicUrl = appUser['profile_pic'];
          if (profilePicUrl != null && profilePicUrl.isNotEmpty) {
            // Format the URL like the rest of the app
            if (!profilePicUrl.startsWith('http')) {
              profilePicUrl = 'https://server.bharathchat.com/$profilePicUrl';
            }
          }

          _userProfiles[zegoUserId] = {
            'profile_pic': appUser['profile_pic'],
            'profile_pic_url': profilePicUrl, // Add formatted URL
            'username': appUser['username'] ?? appUser['first_name'],
            'user_id': appUser['id'],
          };
          debugPrint(
            '✅ [AVATAR] Fallback mapped user $zegoUserId to profile by username',
          );
        } else {
          debugPrint('❌ [AVATAR] Could not find user $zegoUserId in any way');
        }
      }
    }
    debugPrint(
      '🔄 [AVATAR] Final user profiles count: ${_userProfiles.length}',
    );
  }

  // Block checking methods
  Future<bool> _checkIfUserIsBlocked() async {
    try {
      if (currentUser == null) return false;

      // Get the host's blocked users list using the correct API
      final relations = await ApiService.getUserSimpleRelations(widget.hostId);
      final blockedIds = List<int>.from(relations['blocked'] ?? []);

      // Check if current user is in the blocked list
      return blockedIds.contains(currentUser!['id']);
    } catch (e) {
      debugPrint('Error checking if user is blocked: $e');
      return false;
    }
  }

  // Block checking timer
  Timer? _blockCheckTimer;
  bool _isUserBlocked = false;

  void _startBlockChecking() {
    if (widget.isHost) return; // Only check for audience members

    _blockCheckTimer?.cancel();
    _blockCheckTimer = Timer.periodic(const Duration(seconds: 5), (
      timer,
    ) async {
      final isBlocked = await _checkIfUserIsBlocked();
      if (isBlocked && !_isUserBlocked) {
        setState(() {
          _isUserBlocked = true;
        });
        if (mounted) {
          // Show blocking message and navigate back
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'You have been blocked by the host and cannot view this live stream',
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
          // Navigate back to previous screen after a short delay
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) {
              Navigator.of(context).pop();
            }
          });
        }
      } else if (!isBlocked && _isUserBlocked) {
        setState(() {
          _isUserBlocked = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You have been unblocked by the host'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    });
  }

  void _stopBlockChecking() {
    _blockCheckTimer?.cancel();
    _blockCheckTimer = null;
  }

  // Avatar methods
  String _getCurrentUserAvatarUrl() {
    debugPrint('🔄 [AVATAR] Getting current user avatar URL');
    debugPrint('🔄 [AVATAR] Current user: ${currentUser != null}');

    if (currentUser != null && currentUser!['profile_pic'] != null) {
      String profilePic = currentUser!['profile_pic'] as String;
      debugPrint('🔄 [AVATAR] Current user profile pic: $profilePic');

      // Ensure the URL is complete
      if (profilePic.isNotEmpty) {
        String finalUrl;
        if (profilePic.startsWith('http')) {
          finalUrl = profilePic;
        } else {
          finalUrl = 'https://server.bharathchat.com/$profilePic';
        }
        debugPrint('🔄 [AVATAR] Final current user avatar URL: $finalUrl');
        return finalUrl;
      }
    }
    debugPrint(
      '🔄 [AVATAR] No current user avatar found, returning empty string',
    );
    // Return default avatar or empty string
    return '';
  }

  // Custom avatar builder that can access our user profiles
  Widget _customAvatarBuilder(
    BuildContext context,
    Size size,
    ZegoUIKitUser? user,
    Map<String, dynamic> extraInfo,
  ) {
    if (user == null) {
      return CircleAvatar(
        radius: size.width,
        backgroundColor: Colors.grey[300],
        child: Icon(Icons.person, size: size.width, color: Colors.grey[600]),
      );
    }

    // Try to get avatar from our user profiles first
    if (_userProfiles.containsKey(user.id)) {
      String? profilePicUrl = _userProfiles[user.id]['profile_pic_url'];

      if (profilePicUrl != null && profilePicUrl.isNotEmpty) {
        return ClipOval(
          child: CachedNetworkImage(
            imageUrl: profilePicUrl,
            width: size.width * 2,
            height: size.height * 2,
            fit: BoxFit.cover,
            placeholder: (context, url) => _buildPlaceholder(size),
            errorWidget: (context, url, error) => _buildPlaceholder(size),
          ),
        );
      }
    }

    // If not found in user profiles, try to get from current user
    if (user.id == widget.localUserID) {
      String? currentUserAvatarUrl = _getCurrentUserAvatarUrl();
      if (currentUserAvatarUrl.isNotEmpty) {
        return ClipOval(
          child: CachedNetworkImage(
            imageUrl: currentUserAvatarUrl,
            width: size.width * 2,
            height: size.height * 2,
            fit: BoxFit.cover,
            placeholder: (context, url) => _buildPlaceholder(size),
            errorWidget: (context, url, error) => _buildPlaceholder(size),
          ),
        );
      }
    }

    // Try to find user in all users list (fast lookup)
    int? userId;
    if (int.tryParse(user.id) != null) {
      userId = int.parse(user.id);
    } else if (user.id.startsWith('user_')) {
      final idPart = user.id.substring(5);
      userId = int.tryParse(idPart);
    }

    if (userId != null && _allUsers.isNotEmpty) {
      final appUser = _allUsers.firstWhere(
        (u) => u['id'] == userId,
        orElse: () => null,
      );

      if (appUser != null && appUser['profile_pic'] != null) {
        String profilePic = appUser['profile_pic'] as String;
        if (profilePic.isNotEmpty) {
          String profilePicUrl =
              profilePic.startsWith('http')
                  ? profilePic
                  : 'https://server.bharathchat.com/$profilePic';

          // Cache this user for future use
          if (!_userProfiles.containsKey(user.id)) {
            _userProfiles[user.id] = {
              'profile_pic': appUser['profile_pic'],
              'profile_pic_url': profilePicUrl,
              'username': appUser['username'] ?? appUser['first_name'],
              'user_id': userId,
            };
          }

          return ClipOval(
            child: CachedNetworkImage(
              imageUrl: profilePicUrl,
              width: size.width * 2,
              height: size.height * 2,
              fit: BoxFit.cover,
              placeholder: (context, url) => _buildPlaceholder(size),
              errorWidget: (context, url, error) => _buildPlaceholder(size),
            ),
          );
        }
      } else {
        // Only fetch from API if not already cached and not already fetching
        if (!_userProfiles.containsKey(user.id) && userId != null) {
          // Use Future.microtask to avoid blocking the UI
          Future.microtask(() => _fetchUserAvatarAsync(userId!, user.id));
        }
      }
    }

    // Default fallback - always return the same widget to prevent blinking
    return _buildPlaceholder(size);
  }

  // Helper method to build consistent placeholder
  Widget _buildPlaceholder(Size size) {
    return Container(
      width: size.width * 2,
      height: size.height * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey[300],
      ),
      child: Icon(Icons.person, size: size.width, color: Colors.grey[600]),
    );
  }

  // Async method to fetch user avatar and update the UI
  Future<void> _fetchUserAvatarAsync(int userId, String zegoUserId) async {
    try {
      // Check if already cached to avoid duplicate fetches
      if (_userProfiles.containsKey(zegoUserId)) {
        return;
      }

      final userData = await ApiService.getUserById(userId);
      if (userData != null && userData['profile_pic'] != null) {
        String profilePic = userData['profile_pic'] as String;
        if (profilePic.isNotEmpty) {
          String? profilePicUrl = profilePic;
          // Format the URL like the rest of the app
          if (!profilePic.startsWith('http')) {
            profilePicUrl = 'https://server.bharathchat.com/$profilePic';
          }

          // Only update if not already cached and widget is still mounted
          if (!_userProfiles.containsKey(zegoUserId) && mounted) {
            _userProfiles[zegoUserId] = {
              'profile_pic': userData['profile_pic'],
              'profile_pic_url': profilePicUrl, // Add formatted URL
              'username': userData['username'] ?? userData['first_name'],
              'user_id': userId,
            };
            // Don't call setState to avoid blinking
          }
        }
      }
    } catch (e) {
      // Silently handle errors to avoid excessive logging
    }
  }

  // Block user method
  Future<void> _blockUser(String userId) async {
    try {
      // Handle different user ID formats from live streaming
      int userIdInt;

      // First, try to get the user ID from the app's user list by username
      // This is the most reliable way since we need the actual database user ID
      final allUsers = await ApiService.getAllUsers();

      // Clean the username by removing any prefixes
      String cleanUsername = userId;
      if (userId.startsWith('user_')) {
        cleanUsername = userId.substring(5);
      }

      // Try to find the user by username first
      final user = allUsers.firstWhere(
        (u) =>
            u['username'] == cleanUsername ||
            u['id'].toString() == cleanUsername,
        orElse: () => null,
      );

      if (user != null) {
        userIdInt = user['id'] as int;
      } else {
        // Fallback: try to parse as integer
        try {
          userIdInt = int.parse(cleanUsername);
        } catch (e) {
          throw Exception('User not found in the system');
        }
      }

      await ApiService.blockUser(userIdInt);
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

  // Show block user popup
  void _showBlockUserPopup(
    BuildContext context,
    String userName,
    String userId,
  ) {
    showDialog(
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
          content: Text(
            'Are you sure you want to block $userName?',
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.grey,
                side: const BorderSide(color: Colors.grey),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
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
              onPressed: () async {
                Navigator.of(context).pop();
                await _blockUser(userId);
              },
              child: const Text('Block', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  // Custom seat background builder
  Widget _customSeatBackgroundBuilder(
    BuildContext context,
    Size size,
    ZegoUIKitUser? user,
    Map<String, dynamic> extraInfo,
  ) {
    // Check if this is the host seat (index 0)
    final int seatIndex = extraInfo['index'] as int? ?? 0;
    final bool isHostSeat = seatIndex == 0;

    if (isHostSeat && user != null) {
      // Add special background for host seat with animated gradient
      return Positioned(
        top: -8,
        left: 0,
        child: Container(
          width: size.width,
          height: size.height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.orange.withOpacity(0.4),
                Colors.orange.withOpacity(0.2),
                Colors.orange.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(size.width / 2),
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withOpacity(0.3),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
      );
    }

    // No background for speaker seats (removed blue gradient)
    // if (user != null && !isHostSeat) {
    //   return Positioned(...);
    // }

    return Container(); // No special background for empty seats
  }

  // Custom seat foreground builder
  Widget _customSeatForegroundBuilder(
    BuildContext context,
    Size size,
    ZegoUIKitUser? user,
    Map<String, dynamic> extraInfo,
  ) {
    final int seatIndex = extraInfo['index'] as int? ?? 0;
    final bool isHostSeat = seatIndex == 0;

    List<Widget> widgets = [];

    // Add username label for all seats
    if (user != null && user.name.isNotEmpty) {
      widgets.add(
        Positioned(
          bottom: -5,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color:
                  isHostSeat
                      ? Colors.orange.withOpacity(0.8)
                      : Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(10),
              border:
                  isHostSeat
                      ? Border.all(color: Colors.orange, width: 1)
                      : null,
            ),
            child: Text(
              user.name,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: isHostSeat ? 11 : 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      );
    }

    // Add host star icon for host seat
    if (isHostSeat && user != null) {
      widgets.add(
        Positioned(
          top: -8,
          right: -8,
          child: Container(
            width: size.width * 0.5,
            height: size.height * 0.5,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.orange, Colors.deepOrange],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withOpacity(0.5),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: const Icon(Icons.star, color: Colors.white, size: 18),
          ),
        ),
      );
    }

    // Speaker mic icons removed for cleaner look
    // if (!isHostSeat && user != null) {
    //   widgets.add(
    //     Positioned(
    //       top: -5,
    //       left: -5,
    //       child: Container(
    //         width: size.width * 0.3,
    //         height: size.height * 0.3,
    //         decoration: BoxDecoration(
    //           color: Colors.blue.withOpacity(0.8),
    //           shape: BoxShape.circle,
    //         ),
    //         child: const Icon(Icons.mic, color: Colors.white, size: 12),
    //       ),
    //     ),
    //   );
    // }

    // Add seat number indicator
    widgets.add(
      Positioned(
        top: -3,
        left: -3,
        child: Container(
          width: size.width * 0.25,
          height: size.height * 0.25,
          decoration: BoxDecoration(
            color:
                seatIndex == 0
                    ? Colors.grey.withOpacity(0.7) // Host seat (seat 1) - grey
                    : Colors.orange.withOpacity(0.8), // Seats 2-9 - orange
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '${seatIndex + 1}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 8,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );

    return Stack(children: widgets);
  }

  // Custom seat click handler
  void _onSeatClicked(int index, ZegoUIKitUser? user) {
    if (user == null) {
      // Empty seat clicked - show take seat option for audience
      if (!widget.isHost) {
        _showTakeSeatDialog(index);
      }
    } else {
      // Occupied seat clicked - show user options
      _showUserOptionsDialog(index, user);
    }
  }

  // Show take seat dialog for audience
  void _showTakeSeatDialog(int seatIndex) {
    showModalBottomSheet(
      backgroundColor: const Color(0xff111014),
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32.0),
          topRight: Radius.circular(32.0),
        ),
      ),
      isDismissible: true,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Take Seat',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    // The ZEGOCLOUD SDK will handle taking the seat automatically
                    // when the user clicks on an empty seat
                  },
                  child: const Text(
                    'Take This Seat',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Show user options dialog
  void _showUserOptionsDialog(int seatIndex, ZegoUIKitUser user) {
    showModalBottomSheet(
      backgroundColor: const Color(0xff111014),
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32.0),
          topRight: Radius.circular(32.0),
        ),
      ),
      isDismissible: true,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                user.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              if (widget.isHost) ...[
                // Host options
                _buildMenuOption(
                  'Change Background',
                  Icons.wallpaper,
                  Colors.purple,
                  () {
                    Navigator.of(context).pop();
                    _showBackgroundSelectionDialog();
                  },
                ),
                _buildMenuOption(
                  'Remove from Seat',
                  Icons.remove_circle_outline,
                  Colors.red,
                  () {
                    Navigator.of(context).pop();
                    // Handle remove user from seat logic
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Removed ${user.name} from seat')),
                    );
                  },
                ),
                _buildMenuOption('Mute User', Icons.mic_off, Colors.orange, () {
                  Navigator.of(context).pop();
                  // Handle mute logic
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Muted ${user.name}')));
                }),
                _buildMenuOption('Block User', Icons.block, Colors.red, () {
                  Navigator.of(context).pop();
                  _blockUser(user.id);
                }),
              ] else ...[
                // Audience options
                _buildMenuOption(
                  'Send Gift',
                  Icons.card_giftcard,
                  Colors.pink,
                  () {
                    Navigator.of(context).pop();
                    _showGiftPanel();
                  },
                ),
                _buildMenuOption('View Profile', Icons.person, Colors.blue, () {
                  Navigator.of(context).pop();
                  // Handle view profile logic
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Viewing ${user.name}\'s profile')),
                  );
                }),
              ],
              const SizedBox(height: 12),
              _buildMenuOption(
                'Cancel',
                Icons.close,
                Colors.grey,
                () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      },
    );
  }

  // Helper method to build menu options
  Widget _buildMenuOption(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title, style: TextStyle(color: color)),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  // Show background selection dialog for hosts
  void _showBackgroundSelectionDialog() {
    showModalBottomSheet(
      backgroundColor: const Color(0xff111014),
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32.0),
          topRight: Radius.circular(32.0),
        ),
      ),
      isDismissible: true,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Select Background',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 300,
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.2,
                  ),
                  itemCount: _availableBackgrounds.length,
                  itemBuilder: (context, index) {
                    final background = _availableBackgrounds[index];
                    final isSelected =
                        _selectedBackground == background['path'];

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedBackground = background['path']!;
                        });
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Background changed to ${background['name']}',
                            ),
                            backgroundColor: Colors.green,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                isSelected
                                    ? Colors.orange
                                    : Colors.grey.withOpacity(0.3),
                            width: isSelected ? 3 : 1,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(11),
                          child: Stack(
                            children: [
                              // Background image
                              Positioned.fill(
                                child: Image.asset(
                                  background['path']!,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              // Overlay for better text visibility
                              Positioned.fill(
                                child: Container(
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
                              ),
                              // Background name
                              Positioned(
                                bottom: 8,
                                left: 8,
                                right: 8,
                                child: Text(
                                  background['name']!,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              // Selected indicator
                              if (isSelected)
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.orange,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main Zego UIKit Audio Room
        ZegoUIKitPrebuiltLiveAudioRoom(
          appID: appID,
          appSign: appSign,
          userID: widget.localUserID,
          userName: widget.localUserID,
          roomID: widget.liveID,
          config:
              (widget.isHost
                    ? ZegoUIKitPrebuiltLiveAudioRoomConfig.host()
                    : ZegoUIKitPrebuiltLiveAudioRoomConfig.audience())
                ..userAvatarUrl = _getCurrentUserAvatarUrl()
                ..seat.avatarBuilder = _customAvatarBuilder
                // Add background image to the audio room
                ..background = Container(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage(_selectedBackground),
                      fit: BoxFit.cover,
                    ),
                  ),
                )
                // Custom seat layout configuration
                ..seat.hostIndexes = [0] // Host sits in seat 0
                ..seat.takeIndexWhenJoining =
                    widget.isHost
                        ? 0
                        : -1 // Host auto-sits in seat 0
                ..seat.layout.rowConfigs = [
                  // First row: 1 seat for host (center)
                  ZegoLiveAudioRoomLayoutRowConfig(
                    count: 1,
                    alignment: ZegoLiveAudioRoomLayoutAlignment.center,
                  ),
                  // Second row: 4 seats (spaceAround)
                  ZegoLiveAudioRoomLayoutRowConfig(
                    count: 4,
                    alignment: ZegoLiveAudioRoomLayoutAlignment.spaceAround,
                  ),
                  // Third row: 4 seats (spaceAround)
                  ZegoLiveAudioRoomLayoutRowConfig(
                    count: 4,
                    alignment: ZegoLiveAudioRoomLayoutAlignment.spaceAround,
                  ),
                ]
                ..seat.layout.rowSpacing = 20
                // Custom seat UI configuration
                ..seat.showSoundWaveInAudioMode = true
                ..seat.backgroundBuilder = _customSeatBackgroundBuilder
                ..seat.foregroundBuilder = _customSeatForegroundBuilder
                // Custom message configuration for enhanced UI
                ..inRoomMessage = ZegoLiveAudioRoomInRoomMessageConfig(
                  itemBuilder: (
                    BuildContext context,
                    ZegoInRoomMessage message,
                    Map<String, dynamic> extraInfo,
                  ) {
                    // Clean username by removing "user_" prefix
                    final cleanUsername =
                        message.user.name.startsWith('user_')
                            ? message.user.name.substring(5)
                            : message.user.name;

                    return GestureDetector(
                      onTap: () {
                        // Only show block popup for hosts
                        if (widget.isHost) {
                          _showBlockUserPopup(
                            context,
                            cleanUsername,
                            message.user.id,
                          );
                        }
                      },
                      child: Container(
                        width: 160,
                        margin: const EdgeInsets.symmetric(vertical: 2),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.orange.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Profile Picture
                            Container(
                              width: 20,
                              height: 20,
                              margin: const EdgeInsets.only(right: 6),
                              child: ClipOval(
                                child: _customAvatarBuilder(
                                  context,
                                  const Size(20, 20),
                                  message.user,
                                  extraInfo,
                                ),
                              ),
                            ),
                            // Message Content
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // User Name
                                  Text(
                                    cleanUsername,
                                    style: const TextStyle(
                                      color: Colors.orange,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 1),
                                  // Message Text
                                  Text(
                                    message.message,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                )
                // Custom bottom menu bar configuration - add background selection for host, gift button for audience
                ..bottomMenuBar =
                    widget.isHost
                        ? ZegoLiveAudioRoomBottomMenuBarConfig(
                          maxCount: 5,
                          showInRoomMessageButton: true,
                          hostExtendButtons: [
                            // Custom background selection button for host
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.purple.shade300,
                                    Colors.purple.shade500,
                                    Colors.purple.shade700,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.purple.withOpacity(0.3),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(20),
                                  onTap: _showBackgroundSelectionDialog,
                                  child: const Icon(
                                    Icons.wallpaper,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                        : ZegoLiveAudioRoomBottomMenuBarConfig(
                          maxCount: 5,
                          showInRoomMessageButton: true,
                          audienceExtendButtons: [
                            // Custom gift button with gradient background
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.pink.shade300,
                                    Colors.pink.shade500,
                                    Colors.pink.shade700,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.pink.withOpacity(0.3),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(20),
                                  onTap: _showGiftPanel,
                                  child: const Icon(
                                    Icons.card_giftcard,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
          events: ZegoUIKitPrebuiltLiveAudioRoomEvents(
            onLeaveConfirmation: (event, defaultAction) async {
              return await showDialog<bool>(
                    context: context,
                    barrierDismissible: false,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        title: const Text(
                          "Leave the room",
                          style: TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        content: const Text(
                          "Are you sure you want to leave the live room?",
                          style: TextStyle(color: Colors.white),
                        ),
                        actions: [
                          TextButton(
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.orange,
                              side: const BorderSide(color: Colors.orange),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(color: Colors.orange),
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text(
                              'Leave',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      );
                    },
                  ) ??
                  false;
            },
          ),
        ),

        // Gift Panel
        if (showGiftPanel)
          Positioned.fill(
            child: GestureDetector(
              onTap: _hideGiftPanel,
              child: Container(
                color: Colors.black54,
                child: Center(
                  child: FractionallySizedBox(
                    heightFactor: 0.5,
                    child: GiftPanel(
                      receiverId: widget.hostId,
                      roomId: widget.liveID,
                      onGiftSent: _hideGiftPanel,
                      onGiftAnimation: _showGiftAnimation,
                      onClose: _hideGiftPanel,
                    ),
                  ),
                ),
              ),
            ),
          ),

        // Gift Animations
        ...giftAnimations.map(
          (anim) => GiftAnimation(
            giftName: anim['giftName'],
            gifUrl: anim['gifUrl'],
            senderName: anim['senderName'],
            pkBattleSide: anim['pkBattleSide'],
            onAnimationComplete: () => _removeGiftAnimation(anim['id']),
          ),
        ),

        // Active Gift Animations
        ..._activeGiftAnimations,
      ],
    );
  }
}
