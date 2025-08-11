import 'package:flutter/material.dart';
import 'package:zego_uikit_prebuilt_live_streaming/zego_uikit_prebuilt_live_streaming.dart';
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

class LiveAudioScreen extends StatefulWidget {
  final String liveID;
  final String localUserID;
  final bool isHost;
  final int hostId;
  final String? backgroundImage;
  final String? backgroundMusic;

  const LiveAudioScreen({
    Key? key,
    required this.liveID,
    required this.localUserID,
    required this.hostId,
    this.isHost = false,
    this.backgroundImage,
    this.backgroundMusic,
  }) : super(key: key);

  @override
  State<LiveAudioScreen> createState() => _LiveAudioScreenState();
}

class _LiveAudioScreenState extends State<LiveAudioScreen>
    with SingleTickerProviderStateMixin {
  final _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  final int appID = 615877954; // Your ZEGOCLOUD AppID
  final String appSign =
      "12e07321bd8231dda371ea9235e274178403bd97a7ccabcb09e22474c42da3a4"; // Your ZEGOCLOUD AppSign

  List<Map<String, dynamic>> giftAnimations = [];
  Map<String, dynamic>? currentUser;
  Map<String, dynamic>? hostUser;
  final LiveStreamService _liveStreamService = LiveStreamService();
  List<dynamic> _zegoUsers = [];
  Map<String, dynamic> _userProfiles = {};
  StreamSubscription? _userListSub;
  List<dynamic> _allUsers = [];

  // Like animation state
  late AnimationController _likeController;
  late Animation<double> _likeScale;
  bool _showLike = false;
  List<Widget> _burstHearts = [];
  int _burstKey = 0;

  // Gift state
  List<dynamic> _gifts = [];
  bool _giftsLoading = true;
  bool _sendingGift = false;
  List<Widget> _activeGiftAnimations = [];
  int _giftAnimKey = 0;
  
  // Gift polling for synchronization
  Timer? _giftPollingTimer;
  DateTime _lastGiftCheck = DateTime.now();
  final Set<String> _processedGifts = {};

  @override
  void initState() {
    super.initState();
    if (widget.backgroundMusic != null) {
      _setupBackgroundMusic();
    }
    _loadCurrentUser();
    _loadHostUser();
    _fetchAllUsers();
    _userListSub = ZegoUIKit().getUserListStream().listen((zegoUsers) {
      setState(() {
        _zegoUsers = zegoUsers;
      });
      _mapZegoUsersToProfiles(zegoUsers);
    });

    // Initialize like animation
    _likeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _likeScale = Tween<double>(
      begin: 0.0,
      end: 1.5,
    ).chain(CurveTween(curve: Curves.elasticOut)).animate(_likeController);
    _likeController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Future.delayed(const Duration(milliseconds: 300), () {
          _likeController.reverse();
        });
      }
    });

    _fetchGiftsAndUser();
    
    // Start gift polling for synchronization across devices
    _startGiftPolling();
  }
  
  // Gift polling methods for synchronization
  void _startGiftPolling() {
    _giftPollingTimer?.cancel();
    _giftPollingTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      // For audio screen (non-PK), use user gifts received endpoint
      final int targetUserId = widget.isHost
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
      final data = await ApiService.getUserGiftsReceived(userIdentifier: targetUserId);
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
        final int? txnId = (gift['transaction_id'] is int)
            ? gift['transaction_id'] as int
            : int.tryParse('${gift['transaction_id']}');
        if (txnId == null) continue;
        final giftKey = 'user_${targetUserId}_txn_$txnId';
        if (_processedGifts.contains(giftKey)) continue;
        _processedGifts.add(giftKey);

        // Play audio (2s delay)
        final dynamic audioFilenameRaw = gift['audio_filename'];
        final String? audioFilename = (audioFilenameRaw is String) ? audioFilenameRaw : (audioFilenameRaw?.toString());
        if (audioFilename != null && audioFilename.isNotEmpty) {
          try {
            final audioUrl = 'https://server.bharathchat.com/uploads/audio/$audioFilename';
            debugPrint('🎁 (User $targetUserId) Playing received gift audio: $audioUrl');
            await Future.delayed(const Duration(seconds: 2));
            if (mounted) {
              await _audioPlayer.setUrl(audioUrl);
              await _audioPlayer.play();
            }
          } catch (e) {
            debugPrint('🎁 (User $targetUserId) Error playing received gift audio: $e');
          }
        }

        // Animation
        String gifUrl;
        final dynamic gifUrlRaw = gift['gif_url'];
        if (gifUrlRaw is String && gifUrlRaw.isNotEmpty) {
          gifUrl = gifUrlRaw.startsWith('http')
              ? gifUrlRaw
              : 'https://server.bharathchat.com$gifUrlRaw';
        } else {
          final dynamic gifFilenameRaw = gift['gif_filename'];
          final String gifFilename = (gifFilenameRaw is String) ? gifFilenameRaw : (gifFilenameRaw?.toString() ?? '');
          gifUrl = 'https://server.bharathchat.com/uploads/gifts/$gifFilename';
        }
        final Map<String, dynamic>? sender = gift['sender'] as Map<String, dynamic>?;
        final String senderName = sender?['username'] as String? ?? sender?['first_name'] as String? ?? 'User';
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
    debugPrint('🎁 Creating gift animation:');
    debugPrint('🎁   - Gift Name: $giftName');
    debugPrint('🎁   - GIF URL: $gifUrl');
    debugPrint('🎁   - Sender: $senderName');
    
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
                (w) => (w.key as ValueKey).value == 'gift_anim_${_giftAnimKey - 1}',
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
      final userData = await ApiService.getCurrentUser();
      setState(() {
        currentUser = userData;
      });
    } catch (e) {
      print('Error loading current user: $e');
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

  Future<void> _fetchAllUsers() async {
    try {
      final users = await ApiService.getUsers();
      setState(() {
        _allUsers = users;
      });
    } catch (e) {
      print('Error fetching all users: $e');
    }
  }

  void _mapZegoUsersToProfiles(List zegoUsers) {
    for (var zUser in zegoUsers) {
      final userId = zUser.id ?? zUser.userID ?? zUser['userID'] ?? zUser['id'];
      if (userId != null && !_userProfiles.containsKey(userId)) {
        // Try to find user in _allUsers by username or id
        final match = _allUsers.firstWhere(
          (u) =>
              u['username'] == userId ||
              u['id'].toString() == userId.toString(),
          orElse: () => null,
        );
        if (match != null) {
          setState(() {
            _userProfiles[userId] = match;
          });
        }
      }
    }
  }

  void _showGiftAnimation(String giftName, String gifUrl, String senderName, {String? pkBattleSide}) {
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

  void _triggerLike() {
    setState(() {
      _burstKey++;
      _burstHearts = List.generate(
        5,
        (i) => AnimatedHeart(
          key: ValueKey('heart_$_burstKey$i'),
          delay: Duration(milliseconds: i * 80),
          random: Random(),
        ),
      );
    });
    // Remove hearts after animation
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _burstHearts = []);
    });
  }

  Future<void> _sendGiftFromList(dynamic gift) async {
    try {
      final requestId = DateTime.now().millisecondsSinceEpoch.toString();
      debugPrint('🎁 [$requestId] Starting gift send from list...');
      
      // Check if we have enough diamonds
      final currentDiamonds = await ApiService.getCurrentUserDiamonds();
      final giftCost = gift['diamond_amount'] as int? ?? 0;
      
      if (currentDiamonds < giftCost) {
        debugPrint('❌ [$requestId] Insufficient diamonds: $currentDiamonds < $giftCost');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Insufficient diamonds to send this gift'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
        return;
      }
      
      debugPrint('✅ [$requestId] Sufficient diamonds: $currentDiamonds >= $giftCost');
      
      // Derive numeric live stream id from widget.liveID (e.g., "live_17775689" or just "17775689")
      int liveStreamId = 0;
      final liveIdStr = widget.liveID;
      if (liveIdStr.startsWith('live_')) {
        final parts = liveIdStr.split('_');
        if (parts.length >= 2) {
          liveStreamId = int.tryParse(parts[1]) ?? 0;
        }
      } else {
        liveStreamId = int.tryParse(liveIdStr) ?? 0;
      }

      // Send gift via API
      final success = await ApiService.sendGift(
        receiverId: widget.hostId,
        giftId: gift['id'],
        liveStreamId: liveStreamId,
        liveStreamType: 'audio',
      );
      
      if (success) {
        debugPrint('✅ [$requestId] Gift sent successfully via API');
        
        // Play gift audio if available (with 2-second delay)
        final dynamic audioFilenameRaw = gift['audio_filename'];
        final String? audioFilename = (audioFilenameRaw is String) ? audioFilenameRaw : (audioFilenameRaw?.toString());
        if (audioFilename != null && audioFilename.isNotEmpty) {
          try {
            final audioUrl = 'https://server.bharathchat.com/uploads/audio/$audioFilename';
            debugPrint('🎁 [$requestId] Playing gift audio: $audioUrl');
            // Wait 2 seconds before playing audio
            await Future.delayed(const Duration(seconds: 2));
            if (mounted) {
              await _audioPlayer.setUrl(audioUrl);
              await _audioPlayer.play();
            }
          } catch (e) {
            debugPrint('🎁 [$requestId] Error playing gift audio: $e');
          }
        }
        
        // Immediately show animation for the sender
        try {
          String? gifUrl;
          final dynamic gifUrlRaw = gift['gif_url'];
          if (gifUrlRaw is String && gifUrlRaw.isNotEmpty) {
            gifUrl = gifUrlRaw.startsWith('http')
                ? gifUrlRaw
                : 'https://server.bharathchat.com$gifUrlRaw';
          } else {
            final dynamic gifFilenameRaw = gift['gif_filename'];
            final String gifFilename = (gifFilenameRaw is String)
                ? gifFilenameRaw
                : (gifFilenameRaw?.toString() ?? '');
            gifUrl = 'https://server.bharathchat.com/uploads/gifts/$gifFilename';
          }
          final String senderName = currentUser?['username'] ?? currentUser?['first_name'] ?? 'You';
          final String giftName = gift['name'] ?? gift['gift_name'] ?? 'Gift';
          if (gifUrl != null) {
            _createGiftAnimation(giftName, gifUrl, senderName);
          }
        } catch (e) {
          debugPrint('🎁 [$requestId] Error creating immediate gift animation: $e');
        }

        // Send ZEGOCLOUD in-room command for synchronization
        final message = jsonEncode({
          'type': 'gift',
          'gift_id': gift['id'],
          'gift_name': gift['name'],
          'gif_filename': gift['gif_filename'],
          'audio_filename': gift['audio_filename'],
          'diamond_amount': giftCost,
          'sender_id': currentUser?['id'],
          'sender_name': currentUser?['username'] ?? currentUser?['first_name'] ?? 'User',
          'receiver_id': widget.hostId,
          'timestamp': DateTime.now().toIso8601String(),
        });
        
        debugPrint('🎁 [$requestId] Sending in-room command: $message');
        // Note: ZEGOCLOUD command sending is disabled due to API limitations
        // Gift animations will be synchronized through server-side polling
        debugPrint('🎁 [$requestId] ZEGOCLOUD command sending disabled - using server polling for sync');
        
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🎁 Gift sent successfully!'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        debugPrint('❌ [$requestId] Failed to send gift via API');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Failed to send gift. Please try again.'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error sending gift: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error sending gift: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _setupBackgroundMusic() async {
    try {
      await _audioPlayer.setUrl(
        'https://server.bharathchat.com/uploads/music/${widget.backgroundMusic}',
      );
      await _audioPlayer.play();
      setState(() => _isPlaying = true);
    } catch (e) {
      print('Error setting up background music: $e');
    }
  }

  void _toggleBackgroundMusic() async {
    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.play();
      }
      setState(() => _isPlaying = !_isPlaying);
    } catch (e) {
      print('Error toggling background music: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to toggle background music')),
        );
      }
    }
  }

  Future<void> _showGiftConfirmationDialog(
    dynamic gift,
    VoidCallback onConfirm,
  ) async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Send Gift',
            style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Do you want to send "${gift['name']}"?',
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.orange,
                side: BorderSide(color: Colors.orange),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
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
              onPressed: () {
                Navigator.of(context).pop();
                onConfirm();
              },
              child: const Text('Send', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _userListSub?.cancel();
    _likeController.dispose();
    _stopGiftPolling();
    if (widget.isHost) {
      _liveStreamService.removeStream(widget.liveID);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Audio-only configuration - no camera, no PK battles
    final config =
        widget.isHost
            ? (ZegoUIKitPrebuiltLiveStreamingConfig.host()
              ..turnOnCameraWhenJoining = false
              ..turnOnMicrophoneWhenJoining = true
              ..useSpeakerWhenJoining = true
              // Top menu bar - minimal buttons for audio
              ..topMenuBar.buttons = [
                // ZegoLiveStreamingMenuBarButtonName.minimizingButton,
              ]
              // Bottom menu bar - audio-specific buttons with extend buttons
              ..bottomMenuBar.hostButtons = [
                ZegoLiveStreamingMenuBarButtonName.toggleMicrophoneButton,
                ZegoLiveStreamingMenuBarButtonName.leaveButton,
                ZegoLiveStreamingMenuBarButtonName.switchAudioOutputButton,
                ZegoLiveStreamingMenuBarButtonName.chatButton,
              ])
            : (ZegoUIKitPrebuiltLiveStreamingConfig.audience()
              ..turnOnCameraWhenJoining =
                  false // No camera for audience
              ..turnOnMicrophoneWhenJoining = false
              ..useSpeakerWhenJoining = true
              // Top menu bar - minimal buttons for audio
              ..topMenuBar.buttons = [
                // ZegoLiveStreamingMenuBarButtonName.minimizingButton,
              ]
              // Bottom menu bar - audience buttons for audio with extend buttons
              ..bottomMenuBar.audienceButtons = [
                ZegoLiveStreamingMenuBarButtonName.leaveButton,
                ZegoLiveStreamingMenuBarButtonName.switchAudioOutputButton,
                ZegoLiveStreamingMenuBarButtonName.chatButton,
              ]);

    // Add virtual gift, like, and diamond buttons for both host and audience
    final double buttonSize = 38;
    final Gradient buttonGradient = const SweepGradient(
      colors: [
        Color(0xFFffa030),
        Color(0xFFfe9b00),
        Color(0xFFf67d00),
        Color(0xFFffa030),
      ],
      startAngle: 0.0,
      endAngle: 3.14 * 2,
      center: Alignment.center,
    );

    final giftButton = ZegoMenuBarExtendButton(
      index: 0,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          width: buttonSize,
          height: buttonSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: buttonGradient,
          ),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              shape: const CircleBorder(),
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              padding: EdgeInsets.zero,
              minimumSize: Size(buttonSize, buttonSize),
              maximumSize: Size(buttonSize, buttonSize),
              elevation: 0,
            ),
            onPressed: () {
              // Removed _showGiftPanel()
            },
            child: const Icon(
              Icons.card_giftcard,
              color: Colors.white,
              size: 22,
            ),
          ),
        ),
      ),
    );

    final likeButton = ZegoMenuBarExtendButton(
      index: 1,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: GestureDetector(
          onTap: _triggerLike,
          child: Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            width: buttonSize,
            height: buttonSize,
            alignment: Alignment.center,
            child: const Icon(Icons.favorite, color: Colors.pink, size: 22),
          ),
        ),
      ),
    );

    final diamondButton = ZegoMenuBarExtendButton(
      index: 2,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const StoreScreen()),
            );
          },
          child: Container(
            width: buttonSize,
            height: buttonSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: buttonGradient,
            ),
            alignment: Alignment.center,
            child: Image.asset(
              'assets/diamond.png',
              width: 22,
              height: 22,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );

    // Add extend buttons to config
    if (widget.isHost) {
      config.bottomMenuBar.hostExtendButtons = [
        giftButton,
        likeButton,
        diamondButton,
      ];
    } else {
      config.bottomMenuBar.audienceExtendButtons = [
        giftButton,
        likeButton,
        diamondButton,
      ];
    }

    return Scaffold(
      body: Stack(
        children: [
          // Background image if provided
          if (widget.backgroundImage != null)
            Image.network(
              'https://server.bharathchat.com/uploads/backgrounds/${widget.backgroundImage}',
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),

          // Zego UI Kit for audio streaming
          ZegoUIKitPrebuiltLiveStreaming(
            appID: appID,
            appSign: appSign,
            userID: widget.localUserID,
            userName:
                currentUser != null
                    ? (currentUser!['username'] ??
                        currentUser!['first_name'] ??
                        'User_${widget.localUserID}')
                    : 'User_${widget.localUserID}',
            liveID: widget.liveID,
            config: config,
            events: ZegoUIKitPrebuiltLiveStreamingEvents(
              onError: (ZegoUIKitError error) {
                debugPrint('onError: [33m$error [0m');
              },
              onStateUpdated: (state) {
                debugPrint('onStateUpdated: [33m$state [0m');
              },
              onLeaveConfirmation: (
                ZegoLiveStreamingLeaveConfirmationEvent event,
                Future<bool> Function() defaultAction,
              ) async {
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
                            "Are you sure you want to leave the live audio room?",
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

          // Background music control (only for host)
          if (widget.isHost && widget.backgroundMusic != null)
            Positioned(
              top: 100,
              right: 16,
              child: GestureDetector(
                onTap: _toggleBackgroundMusic,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Icon(
                    _isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),

          // User avatars
          if (_zegoUsers.isNotEmpty)
            Positioned(
              top: 40,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children:
                    _zegoUsers.map<Widget>((zUser) {
                      final userId =
                          zUser.id ??
                          zUser.userID ??
                          zUser['userID'] ??
                          zUser['id'];
                      final user = _userProfiles[userId];
                      final profilePic =
                          user != null ? user['profile_pic'] : null;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: CircleAvatar(
                          radius: 40,
                          backgroundImage:
                              profilePic != null && profilePic.isNotEmpty
                                  ? MemoryImage(
                                    base64Decode(
                                      profilePic.contains(',')
                                          ? profilePic.split(',').last
                                          : profilePic,
                                    ),
                                  )
                                  : null,
                          child:
                              (profilePic == null || profilePic.isEmpty)
                                  ? Icon(Icons.person, size: 40)
                                  : null,
                        ),
                      );
                    }).toList(),
              ),
            ),

          // Burst hearts overlay
          ..._burstHearts.map(
            (w) => Positioned(
              bottom: 80,
              left:
                  MediaQuery.of(context).size.width / 2 -
                  20 +
                  (Random().nextDouble() * 40 - 20),
              child: w,
            ),
          ),

          // Overlay active gift animations
          ..._activeGiftAnimations,

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

          // Watermark logo in top left
          Positioned(
            top: 100,
            left: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Opacity(
                  opacity: 0.5,
                  child: Container(
                    margin: const EdgeInsets.only(left: 28),
                    child: Image.asset(
                      'assets/logo.png',
                      width: 36,
                      height: 36,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Opacity(
                  opacity: 0.5,
                  child: ShaderMask(
                    shaderCallback: (Rect bounds) {
                      return const LinearGradient(
                        colors: [
                          Color(0xFFffa030),
                          Color(0xFFfe9b00),
                          Color(0xFFf67d00),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(bounds);
                    },
                    child: const Text(
                      'Bharath Chat',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// AnimatedHeart widget for burst effect
class AnimatedHeart extends StatefulWidget {
  final Duration delay;
  final Random random;
  const AnimatedHeart({Key? key, required this.delay, required this.random})
    : super(key: key);

  @override
  State<AnimatedHeart> createState() => _AnimatedHeartState();
}

class _AnimatedHeartState extends State<AnimatedHeart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _moveUp;
  late Animation<double> _fade;
  late double _xOffset;

  @override
  void initState() {
    super.initState();
    _xOffset = widget.random.nextDouble() * 60 - 30;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _moveUp = Tween<double>(
      begin: 0,
      end: -80,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _fade = Tween<double>(
      begin: 1,
      end: 0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _fade.value,
          child: Transform.translate(
            offset: Offset(_xOffset, _moveUp.value),
            child: Icon(Icons.favorite, color: Colors.pink, size: 28),
          ),
        );
      },
    );
  }
}
