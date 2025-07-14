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

class _LiveAudioScreenState extends State<LiveAudioScreen> {
  final _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  final int appID = 615877954; // Your ZEGOCLOUD AppID
  final String appSign =
      "12e07321bd8231dda371ea9235e274178403bd97a7ccabcb09e22474c42da3a4"; // Your ZEGOCLOUD AppSign

  bool showGiftPanel = false;
  List<Map<String, dynamic>> giftAnimations = [];
  Map<String, dynamic>? currentUser;
  Map<String, dynamic>? hostUser;
  final LiveStreamService _liveStreamService = LiveStreamService();
  List<dynamic> _zegoUsers = [];
  Map<String, dynamic> _userProfiles = {};
  StreamSubscription? _userListSub;
  List<dynamic> _allUsers = [];

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

  void _onGiftSent() {
    _hideGiftPanel();
    // You can add additional logic here, like showing a notification
  }

  void _showGiftAnimation(String giftName, String gifUrl, String senderName) {
    setState(() {
      giftAnimations.add({
        'giftName': giftName,
        'gifUrl': gifUrl,
        'senderName': senderName,
        'id': DateTime.now().millisecondsSinceEpoch,
      });
    });
  }

  void _removeGiftAnimation(int id) {
    setState(() {
      giftAnimations.removeWhere((animation) => animation['id'] == id);
    });
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

  @override
  void dispose() {
    _audioPlayer.dispose();
    _userListSub?.cancel();
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
              ..turnOnCameraWhenJoining =
                  false // No camera for audio
              ..turnOnMicrophoneWhenJoining = true
              ..useSpeakerWhenJoining = true
              // Top menu bar - minimal buttons for audio
              ..topMenuBar.buttons = [
                ZegoLiveStreamingMenuBarButtonName.minimizingButton,
              ]
              // Bottom menu bar - audio-specific buttons
              ..bottomMenuBar.hostButtons = [
                ZegoLiveStreamingMenuBarButtonName.toggleMicrophoneButton,
                ZegoLiveStreamingMenuBarButtonName.leaveButton,
                ZegoLiveStreamingMenuBarButtonName.switchAudioOutputButton,
                ZegoLiveStreamingMenuBarButtonName.chatButton,
              ]
              // Audio video view config - optimized for audio
              ..audioVideoView.showAvatarInAudioMode = true
              ..audioVideoView.showSoundWavesInAudioMode = true
              ..audioVideoView.showMicrophoneStateOnView = true)
            : (ZegoUIKitPrebuiltLiveStreamingConfig.audience()
              ..turnOnCameraWhenJoining =
                  false // No camera for audience
              ..turnOnMicrophoneWhenJoining = false
              ..useSpeakerWhenJoining = true
              // Top menu bar - minimal buttons for audio
              ..topMenuBar.buttons = [
                ZegoLiveStreamingMenuBarButtonName.minimizingButton,
              ]
              // Bottom menu bar - audience buttons for audio
              ..bottomMenuBar.audienceButtons = [
                ZegoLiveStreamingMenuBarButtonName.leaveButton,
                ZegoLiveStreamingMenuBarButtonName.switchAudioOutputButton,
                ZegoLiveStreamingMenuBarButtonName.chatButton,
              ]
              // Audio video view config - optimized for audio
              ..audioVideoView.showAvatarInAudioMode = true
              ..audioVideoView.showSoundWavesInAudioMode = true
              ..audioVideoView.showMicrophoneStateOnView = true);

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
                debugPrint('onError:$error');
              },
              onStateUpdated: (state) {
                debugPrint('onStateUpdated:$state');
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
        ],
      ),
    );
  }
}
