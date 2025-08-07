import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../../services/api_service.dart';
import '../profile/profile_screen.dart';
import '../live/live_video_screen.dart';
import '../live/live_audio_screen.dart';
import '../live/go_live.dart';
import '../../services/live_stream_service.dart';
import 'dart:convert';
import 'leaderboard_screen.dart';
import 'store_screen.dart';
import 'package:zego_uikit_prebuilt_live_streaming/zego_uikit_prebuilt_live_streaming.dart';
import 'package:permission_handler/permission_handler.dart';
import 'search_screen.dart';
import '../auth/pending.dart';
import '../live/creator_invitation_screen.dart';
import '../../common.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class Category {
  final String name;
  final String icon;
  final String type;

  Category({required this.name, required this.icon, required this.type});
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> _sliders = [];
  List<dynamic> _videoLives = [];
  List<dynamic> _audioLives = [];
  bool _isLoading = true;
  final LiveStreamService _liveStreamService = LiveStreamService();
  Language selectedLanguage = languages[0]; // Default to Hindi
  String goLiveButtonText = 'No Live'; // Default
  bool goLiveButtonLoading = false;

  Future<Map<String, dynamic>> _userProfileFuture = Future.value({});

  // Store users by id for quick lookup
  Map<int, dynamic> _usersById = {};

  // Category selector support
  final List<Category> categories = [
    Category(name: 'All', icon: '🌐', type: 'all'),
    Category(name: 'Live Show', icon: '🎥', type: 'live'),
    Category(name: 'Party Room', icon: '🎉', type: 'party'),
    Category(name: 'Singing', icon: '🎤', type: 'singing'),
    Category(name: 'Dance', icon: '💃', type: 'dance'),
    Category(name: 'Comedy', icon: '😄', type: 'comedy'),
  ];
  String selectedCategory = 'All';

  // Zego App credentials - replace with your actual values
  static const int appID = 615877954; // Replace with your App ID
  static const String appSign =
      "12e07321bd8231dda371ea9235e274178403bd97a7ccabcb09e22474c42da3a4"; // Replace with your App Sign

  // Request permissions before joining live stream
  Future<bool> requestPermissions() async {
    final List<Permission> permissions = [
      Permission.camera,
      Permission.microphone,
    ];

    Map<Permission, PermissionStatus> statuses = await permissions.request();

    return statuses.values.every(
      (status) => status == PermissionStatus.granted,
    );
  }

  void joinLiveStream(String liveID, int hostId, bool isHost) async {
    // Request permissions first
    bool permissionsGranted = await requestPermissions();
    if (!permissionsGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Camera and microphone permissions are required'),
          ),
        );
      }
      return;
    }

    // Use real user info
    final userData = ApiService.currentUserData;
    final userID =
        userData != null
            ? (userData['username'] ?? userData['id'].toString())
            : DateTime.now().millisecondsSinceEpoch.toString();

    // Check for active PK battle if audience is joining
    Map<String, dynamic>? activePKBattle;
    if (!isHost) {
      try {
        // Extract stream ID from live_url (e.g., "live_1753954952241_host" -> 1753954952241)
        if (liveID.startsWith('live_')) {
          final parts = liveID.split('_');
          if (parts.length >= 2) {
            final streamId = int.tryParse(parts[1]);
            if (streamId != null) {
              debugPrint(
                '🔍 Checking for active PK battle for stream: $streamId',
              );
              activePKBattle = await ApiService.getActivePKBattleByStreamId(
                streamId,
              );
              if (activePKBattle != null) {
                debugPrint(
                  '🎮 Found active PK battle: ${activePKBattle['id']}',
                );
              } else {
                debugPrint('❌ No active PK battle found for stream: $streamId');
              }
            }
          }
        }
      } catch (e) {
        debugPrint('❌ Error checking for PK battle: $e');
      }
    }

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => LiveVideoScreen(
                liveID: liveID,
                localUserID: userID,
                isHost: isHost,
                hostId: hostId,
                activePKBattle:
                    activePKBattle, // Pass PK battle info to live screen
              ),
        ),
      );
    }
  }

  void createTestLiveStream() async {
    try {
      // Create a test live stream on the server
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final liveUrl = 'test_live_stream_123';

      final data = {
        'category': 'Test Live',
        'hashtag': ['test'],
        'live_url': liveUrl,
      };

      final response = await ApiService.createVideoLive(data);
      print('Created test live stream: $response');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Test live stream created! You can now join from another device.',
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Refresh the live streams list
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating test live stream: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _checkUserActive();
    _loadData();
    _userProfileFuture = ApiService.getCurrentUser();
    _startLiveStreamRefresh();
    updateGoLiveButtonText(); // Add this
  }

  void _checkUserActive() async {
    final isActive = await ApiService.isCurrentUserActive();
    if (!isActive && mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const PendingScreen()),
        (route) => false,
      );
    }
  }

  void _startLiveStreamRefresh() {
    // Refresh live streams every 10 seconds
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) {
        _loadData();
        _startLiveStreamRefresh(); // Schedule next refresh
      }
    });
  }

  void _loadData() async {
    try {
      final sliders = await ApiService.getSliders();
      final videoLives = await ApiService.getVideoLives();
      final audioLives = await ApiService.getAudioLives();
      final users = await ApiService.getUsers(); // Fetch all users

      // Build user map for quick lookup
      _usersById = {for (var user in users) user['id']: user};

      // Update LiveStreamService with server data
      _liveStreamService.clear(); // Clear existing streams

      // Add video lives from server
      for (var live in videoLives) {
        _liveStreamService.addStream(
          LiveStream(
            channelName: live['live_url'] ?? 'video_${live['id']}',
            type: LiveStreamType.video,
            viewers: live['viewers'] ?? 0,
            host: live['host_name'] ?? 'Host',
            liveId: live['id'] ?? 0,
            userId: live['user_id'] ?? 0, // Pass userId
          ),
        );
      }

      // Add audio lives from server
      for (var live in audioLives) {
        _liveStreamService.addStream(
          LiveStream(
            channelName: live['live_url'] ?? 'audio_${live['id']}',
            type: LiveStreamType.audio,
            viewers: live['viewers'] ?? 0,
            host: live['host_name'] ?? live['chat_room'] ?? 'Host',
            liveId: live['id'] ?? 0,
            userId: live['user_id'] ?? 0, // Pass userId
          ),
        );
      }

      setState(() {
        _sliders = sliders;
        _videoLives = videoLives;
        _audioLives = audioLives;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showLanguageSelector() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1a1a1a),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with back button and title
                Row(
                  children: [
                    // Back arrow button
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Title
                    const Expanded(
                      child: Text(
                        'See live rooms in this language',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Choose language you can speak and watch content in',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                // Make the language list scrollable
                Expanded(
                  child: ListView(
                    shrinkWrap: true,
                    children:
                        languages.map((language) {
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedLanguage = language;
                              });
                              Navigator.pop(context);
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 16,
                              ),
                              decoration: BoxDecoration(
                                color: language.backgroundColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    language.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    language.nativeName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> updateGoLiveButtonText() async {
    final userId = ApiService.currentUserId;
    if (userId == null) {
      setState(() {
        goLiveButtonText = 'No Live';
      });
      return;
    }
    final userTypes = await ApiService.getUserTypes();
    final userTypeEntry = userTypes.firstWhere(
      (e) => e['user_id'] == userId,
      orElse: () => null,
    );
    final type = userTypeEntry != null ? userTypeEntry['type'] : null;
    if (type == 'no') {
      setState(() {
        goLiveButtonText = 'No Live';
      });
    } else if (type == 'premium') {
      setState(() {
        goLiveButtonText = 'Go Live';
      });
    } else {
      final approvalList = await ApiService.getLiveApproval();
      final approved = approvalList.any((e) => e['user_id'] == userId);
      setState(() {
        goLiveButtonText = approved ? 'No Live' : 'Request Live';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF181A20),
      appBar: AppBar(
        backgroundColor: const Color(0xFF23272F),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = MediaQuery.of(context).size.width;
            final isSmallScreen = screenWidth < 400;

            return Row(
              children: [
                // Language Selector
                GestureDetector(
                  onTap: _showLanguageSelector,
                  child: Container(
                    height: 35,
                    width: isSmallScreen ? 36 : 42,
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 3 : 4,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: selectedLanguage.backgroundColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          selectedLanguage.nativeName.isNotEmpty
                              ? selectedLanguage.nativeName[0]
                              : selectedLanguage.name[0],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isSmallScreen ? 16 : 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: isSmallScreen ? 6 : 10),
                // Diamond Store Icon
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const StoreScreen(),
                      ),
                    );
                  },
                  child: Image.asset(
                    'assets/diamond.png',
                    width: isSmallScreen ? 26 : 30,
                    height: isSmallScreen ? 26 : 30,
                  ),
                ),
                SizedBox(width: isSmallScreen ? 6 : 10),

                // Trophy/Leaderboard Icon
                // GestureDetector(
                //   onTap: () {
                //     Navigator.push(
                //       context,
                //       MaterialPageRoute(
                //         builder: (context) => const LeaderboardScreen(),
                //       ),
                //     );
                //   },
                //   child: Icon(
                //     Icons.emoji_events,
                //     color: Colors.orange,
                //     size: isSmallScreen ? 26 : 30,
                //   ),
                // ),
              ],
            );
          },
        ),
        actions: [
          // Search Icon
          IconButton(
            icon: Icon(
              Icons.search,
              color: Colors.white,
              size: MediaQuery.of(context).size.width < 400 ? 26 : 30,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SearchScreen()),
              );
            },
          ),
          // Go Live Button - Responsive
          LayoutBuilder(
            builder: (context, constraints) {
              final screenWidth = MediaQuery.of(context).size.width;
              final isSmallScreen = screenWidth < 400;

              return Container(
                margin: EdgeInsets.symmetric(vertical: 8),
                child: ElevatedButton(
                  onPressed:
                      (goLiveButtonText == 'No Live' || goLiveButtonLoading)
                          ? null
                          : () async {
                            setState(() {
                              goLiveButtonLoading = true;
                            });
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder:
                                  (context) => const Center(
                                    child: CircularProgressIndicator(
                                      color: Colors.orange,
                                    ),
                                  ),
                            );
                            try {
                              final userId = ApiService.currentUserId;
                              if (userId == null) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('User not logged in!'),
                                  ),
                                );
                                setState(() {
                                  goLiveButtonLoading = false;
                                });
                                return;
                              }
                              final userTypes = await ApiService.getUserTypes();
                              final userTypeEntry = userTypes.firstWhere(
                                (e) => e['user_id'] == userId,
                                orElse: () => null,
                              );
                              final type =
                                  userTypeEntry != null
                                      ? userTypeEntry['type']
                                      : null;
                              if (type == 'no') {
                                Navigator.pop(context);
                                showDialog(
                                  context: context,
                                  builder:
                                      (context) => AlertDialog(
                                        title: const Text('No Live'),
                                        content: const Text(
                                          'You are not allowed to go live.',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed:
                                                () => Navigator.pop(context),
                                            child: const Text('OK'),
                                          ),
                                        ],
                                      ),
                                );
                                setState(() {
                                  goLiveButtonLoading = false;
                                });
                                await updateGoLiveButtonText();
                                return;
                              } else if (type == 'premium') {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const GoLiveScreen(),
                                  ),
                                );
                                setState(() {
                                  goLiveButtonLoading = false;
                                });
                                await updateGoLiveButtonText();
                                return;
                              } else {
                                // type is normal or not present
                                final approvalList =
                                    await ApiService.getLiveApproval();
                                final approved = approvalList.any(
                                  (e) => e['user_id'] == userId,
                                );
                                Navigator.pop(context);
                                if (approved) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => const GoLiveScreen(),
                                    ),
                                  );
                                } else {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) =>
                                              const CreatorInvitationScreen(),
                                    ),
                                  );
                                }
                                setState(() {
                                  goLiveButtonLoading = false;
                                });
                                await updateGoLiveButtonText();
                              }
                            } catch (e) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
                              setState(() {
                                goLiveButtonLoading = false;
                              });
                              await updateGoLiveButtonText();
                            }
                          },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 6 : 8,
                      vertical: 0,
                    ),
                    elevation: 0,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFffa030),
                          Color(0xFFfe9b00),
                          Color(0xFFf67d00),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 12 : 16,
                      vertical: 6,
                    ),
                    child: Text(
                      goLiveButtonText,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: isSmallScreen ? 11 : 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          SizedBox(width: MediaQuery.of(context).size.width < 400 ? 2 : 4),
          // Profile Photo
          Padding(
            padding: EdgeInsets.only(
              right: MediaQuery.of(context).size.width < 400 ? 8 : 16,
            ),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
                );
              },
              child: FutureBuilder<Map<String, dynamic>>(
                future: _userProfileFuture,
                builder: (context, snapshot) {
                  final avatarRadius =
                      MediaQuery.of(context).size.width < 400 ? 16.0 : 18.0;

                  if (snapshot.hasData &&
                      snapshot.data?['profile_pic'] != null) {
                    try {
                      final profilePic = snapshot.data!['profile_pic'];
                      final isFullUrl =
                          profilePic.startsWith('http://') ||
                          profilePic.startsWith('https://');
                      final url =
                          isFullUrl
                              ? profilePic
                              : 'https://server.bharathchat.com/' + profilePic;
                      return CircleAvatar(
                        radius: avatarRadius,
                        backgroundImage: NetworkImage(url),
                      );
                    } catch (e) {
                      // If decoding fails, show an error icon
                      return CircleAvatar(
                        radius: avatarRadius,
                        backgroundColor: Colors.grey[800],
                        child: Icon(
                          Icons.error,
                          color: Colors.red,
                          size: avatarRadius * 1.25,
                        ),
                      );
                    }
                  }
                  return CircleAvatar(
                    radius: avatarRadius,
                    backgroundColor: Colors.grey[800],
                    child: Icon(
                      Icons.person,
                      color: Colors.white,
                      size: avatarRadius * 1.25,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Colors.orange),
              )
              : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Slider Section
                    if (_sliders.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      CarouselSlider(
                        options: CarouselOptions(
                          height: MediaQuery.of(context).size.width * 6 / 16,
                          autoPlay: true,
                          enlargeCenterPage: true,
                          viewportFraction: 0.9,
                        ),
                        items:
                            _sliders.map((slider) {
                              return Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: Colors.grey[900],
                                  border: Border.all(color: Colors.transparent),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child:
                                      slider['img'].startsWith('data:image')
                                          ? Image.memory(
                                            base64Decode(
                                              slider['img'].split(',')[1],
                                            ),
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                            height: double.infinity,
                                            errorBuilder: (
                                              context,
                                              error,
                                              stackTrace,
                                            ) {
                                              return Container(
                                                color: Colors.grey[800],
                                                child: const Center(
                                                  child: Icon(
                                                    Icons.error_outline,
                                                    color: Colors.white,
                                                    size: 40,
                                                  ),
                                                ),
                                              );
                                            },
                                          )
                                          : Image.network(
                                            slider['img'] ?? '',
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                            height: double.infinity,
                                            errorBuilder: (
                                              context,
                                              error,
                                              stackTrace,
                                            ) {
                                              return Container(
                                                color: Colors.grey[800],
                                                child: const Center(
                                                  child: Icon(
                                                    Icons.error_outline,
                                                    color: Colors.white,
                                                    size: 40,
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                ),
                              );
                            }).toList(),
                      ),
                    ],

                    const SizedBox(height: 10),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: const [
                          Icon(Icons.star, color: Colors.orange, size: 24),
                          SizedBox(width: 8),
                          Text(
                            'Popular Hosts',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    AnimatedBuilder(
                      animation: _liveStreamService,
                      builder: (context, _) {
                        final videoStreams =
                            _liveStreamService.streams
                                .where(
                                  (stream) =>
                                      stream.type == LiveStreamType.video,
                                )
                                .toList()
                                .reversed
                                .toList();
                        // Only unique hosts by userId
                        final Set<int> seenUserIds = {};
                        final uniqueHostStreams = <dynamic>[];
                        for (final stream in videoStreams) {
                          if (stream.userId != null &&
                              !seenUserIds.contains(stream.userId)) {
                            seenUserIds.add(stream.userId);
                            uniqueHostStreams.add(stream);
                          }
                        }
                        if (uniqueHostStreams.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'No popular hosts live right now!',
                              style: TextStyle(color: Colors.white70),
                            ),
                          );
                        }
                        return SizedBox(
                          height: 120,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: uniqueHostStreams.length,
                            separatorBuilder:
                                (_, __) => const SizedBox(width: 16),
                            itemBuilder: (context, index) {
                              final stream = uniqueHostStreams[index];
                              final user = _usersById[stream.userId];
                              final userName =
                                  user != null
                                      ? ((user['first_name'] ?? '') +
                                              ' ' +
                                              (user['last_name'] ?? ''))
                                          .trim()
                                      : 'Host';
                              final profilePic =
                                  user != null ? user['profile_pic'] : null;
                              final backgroundImg =
                                  user != null ? user['background_img'] : null;
                              return GestureDetector(
                                onTap: () {
                                  joinLiveStream(
                                    stream.channelName,
                                    stream.userId,
                                    false,
                                  );
                                },
                                child: Column(
                                  children: [
                                    Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Container(
                                          width: 70,
                                          height: 70,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.red,
                                              width: 3,
                                            ),
                                            image:
                                                backgroundImg != null &&
                                                        backgroundImg.isNotEmpty
                                                    ? DecorationImage(
                                                      image: MemoryImage(
                                                        base64Decode(
                                                          backgroundImg
                                                                  .contains(',')
                                                              ? backgroundImg
                                                                  .split(',')
                                                                  .last
                                                              : backgroundImg,
                                                        ),
                                                      ),
                                                      fit: BoxFit.cover,
                                                    )
                                                    : null,
                                            color: Colors.grey[900],
                                          ),
                                          child: ClipOval(
                                            child:
                                                profilePic != null &&
                                                        profilePic.isNotEmpty
                                                    ? Image.network(
                                                      profilePic.startsWith(
                                                            'http',
                                                          )
                                                          ? profilePic
                                                          : 'https://server.bharathchat.com/' +
                                                              profilePic,
                                                      fit: BoxFit.cover,
                                                      width: 70,
                                                      height: 70,
                                                    )
                                                    : Container(
                                                      color: Colors.black,
                                                      child: const Center(
                                                        child: Icon(
                                                          Icons.person,
                                                          color: Colors.white,
                                                          size: 40,
                                                        ),
                                                      ),
                                                    ),
                                          ),
                                        ),
                                        Positioned(
                                          bottom: 0,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.red,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: const Text(
                                              'LIVE',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    SizedBox(
                                      width: 80,
                                      child: Text(
                                        userName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                    // const SizedBox(height: 8),

                    // Live Stream List (Discord-style)
                    // Padding(
                    //   padding: const EdgeInsets.symmetric(horizontal: 16),
                    //   child: Row(
                    //     children: [
                    //       const Icon(Icons.live_tv, color: Colors.orange),
                    //       const SizedBox(width: 8),
                    //       const Text(
                    //         'Live Streams',
                    //         style: TextStyle(
                    //           color: Colors.white,
                    //           fontSize: 20,
                    //           fontWeight: FontWeight.bold,
                    //         ),
                    //       ),
                    //       const SizedBox(width: 8),
                    //       AnimatedBuilder(
                    //         animation: _liveStreamService,
                    //         builder: (context, _) {
                    //           return Container(
                    //             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    //             decoration: BoxDecoration(
                    //               color: Colors.orange,
                    //               borderRadius: BorderRadius.circular(12),
                    //             ),
                    //             child: Text(
                    //               '${_liveStreamService.streams.length}',
                    //               style: const TextStyle(
                    //                 color: Colors.white,
                    //                 fontSize: 12,
                    //                 fontWeight: FontWeight.bold,
                    //               ),
                    //             ),
                    //           );
                    //         },
                    //       ),
                    //     ],
                    //   ),
                    // ),
                    // const SizedBox(height: 12),
                    // AnimatedBuilder(
                    //   animation: _liveStreamService,
                    //   builder: (context, _) {
                    //     final streams = _liveStreamService.streams;
                    //     if (streams.isEmpty) {
                    //       return const Padding(
                    //         padding: EdgeInsets.symmetric(horizontal: 16),
                    //         child: Text(
                    //           'No live streams. Start one or check back later!',
                    //           style: TextStyle(color: Colors.white70),
                    //         ),
                    //       );
                    //     }
                    //     return ListView.builder(
                    //       shrinkWrap: true,
                    //       physics: const NeverScrollableScrollPhysics(),
                    //       padding: const EdgeInsets.symmetric(horizontal: 16),
                    //       itemCount: streams.length,
                    //       itemBuilder: (context, index) {
                    //         final stream = streams[index];
                    //         return Card(
                    //           color: const Color(0xFF23272F),
                    //           shape: RoundedRectangleBorder(
                    //             borderRadius: BorderRadius.circular(12),
                    //           ),
                    //           child: ListTile(
                    //             leading: Icon(
                    //               stream.type == LiveStreamType.video ? Icons.videocam : Icons.mic,
                    //               color: Colors.orange,
                    //             ),
                    //             title: Text(
                    //               stream.channelName,
                    //               style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    //             ),
                    //             subtitle: Text(
                    //               'Host: ${stream.host}  |  Viewers: ${stream.viewers}',
                    //               style: const TextStyle(color: Colors.white70),
                    //             ),
                    //             trailing: ElevatedButton(
                    //               style: ElevatedButton.styleFrom(
                    //                 backgroundColor: Colors.orange,
                    //                 foregroundColor: Colors.white,
                    //               ),
                    //               onPressed: () {
                    //                 joinLiveStream(stream.channelName, stream.userId, false);
                    //               },
                    //               child: const Text('Join'),
                    //             ),
                    //           ),
                    //         );
                    //       },
                    //     );
                    //   },
                    // ),

                    // const SizedBox(height: 30),

                    // Live Video Streams (from LiveStreamService)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Live ChatRooms',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    // const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // const Text(
                          //   'Choose Category',
                          //   style: TextStyle(
                          //     color: Colors.white,
                          //     fontSize: 18,
                          //     fontWeight: FontWeight.w600,
                          //   ),
                          // ),
                          const SizedBox(height: 8),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children:
                                  categories.map((category) {
                                    bool isSelected =
                                        selectedCategory == category.name;
                                    return GestureDetector(
                                      onTap: () {
                                        setState(
                                          () =>
                                              selectedCategory = category.name,
                                        );
                                      },
                                      child: Container(
                                        width: 120,
                                        height: 35,
                                        margin: const EdgeInsets.only(
                                          right: 12,
                                        ),
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          gradient:
                                              isSelected
                                                  ? const LinearGradient(
                                                    colors: [
                                                      Color(0xFFffa030),
                                                      Color(0xFFfe9b00),
                                                      Color(0xFFf67d00),
                                                    ],
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                  )
                                                  : null,
                                          color:
                                              isSelected
                                                  ? null
                                                  : Colors.grey[900],
                                          borderRadius: BorderRadius.circular(
                                            25,
                                          ),
                                          border:
                                              isSelected
                                                  ? Border.all(
                                                    color: Colors.transparent,
                                                    width: 2,
                                                  )
                                                  : null,
                                        ),
                                        child: Text(
                                          category.name,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 15,
                                            color:
                                                isSelected
                                                    ? Colors.black
                                                    : Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    AnimatedBuilder(
                      animation: _liveStreamService,
                      builder: (context, _) {
                        final videoStreams =
                            _liveStreamService.streams
                                .where(
                                  (stream) =>
                                      stream.type == LiveStreamType.video,
                                )
                                .toList()
                                .reversed
                                .toList();

                        // Filter by selected language and category
                        final filteredVideoStreams =
                            videoStreams.where((stream) {
                              final user = _usersById[stream.userId];
                              // Find the matching live data from _videoLives by live_url or id
                              final live = _videoLives.firstWhere(
                                (l) =>
                                    (l['live_url'] == stream.channelName) ||
                                    (l['id'] == stream.liveId),
                                orElse: () => null,
                              );
                              final languageCode =
                                  live != null ? live['language'] : null;
                              final category =
                                  live != null ? live['category'] : null;
                              final matchesLanguage =
                                  languageCode == selectedLanguage.code;
                              final matchesCategory =
                                  selectedCategory == 'All' ||
                                  category == selectedCategory;
                              return matchesLanguage && matchesCategory;
                            }).toList();

                        if (filteredVideoStreams.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'No live video streams. Start one or check back later!',
                              style: TextStyle(color: Colors.white70),
                            ),
                          );
                        }

                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.8,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                              ),
                          itemCount: filteredVideoStreams.length,
                          itemBuilder: (context, index) {
                            final stream = filteredVideoStreams[index];
                            final user = _usersById[stream.userId];
                            final userName =
                                user != null
                                    ? ((user['first_name'] ?? '') +
                                            ' ' +
                                            (user['last_name'] ?? ''))
                                        .trim()
                                    : 'Host';
                            final profilePic =
                                user != null ? user['profile_pic'] : null;
                            return GestureDetector(
                              onTap: () {
                                joinLiveStream(
                                  stream.channelName,
                                  stream.userId,
                                  false,
                                );
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey[900],
                                  borderRadius: BorderRadius.circular(12),
                                  // No border
                                ),
                                child: Column(
                                  children: [
                                    Expanded(
                                      child: Stack(
                                        children: [
                                          ClipRRect(
                                            borderRadius:
                                                const BorderRadius.vertical(
                                                  top: Radius.circular(12),
                                                ),
                                            child:
                                                profilePic != null &&
                                                        profilePic.isNotEmpty
                                                    ? Image.network(
                                                      profilePic.startsWith(
                                                            'http',
                                                          )
                                                          ? profilePic
                                                          : 'https://server.bharathchat.com/' +
                                                              profilePic,
                                                      fit: BoxFit.cover,
                                                      width: double.infinity,
                                                      height: double.infinity,
                                                    )
                                                    : Container(
                                                      color: Colors.black,
                                                      child: const Center(
                                                        child: Icon(
                                                          Icons.person,
                                                          color: Colors.white,
                                                          size: 60,
                                                        ),
                                                      ),
                                                    ),
                                          ),
                                          // LIVE badge (top-left)
                                          Positioned(
                                            top: 8,
                                            left: 8,
                                            child: Container(
                                              padding: const EdgeInsets.all(0),
                                              decoration: BoxDecoration(
                                                color: Colors.transparent,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),

                                              // child: Image.asset('assets/live.jpg', width: 22, height: 22),
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Colors.red,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        4,
                                                      ), // optional rounded corners
                                                ),
                                                child: const Text(
                                                  'LIVE',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 10,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          // Watching count (top-right)
                                          Positioned(
                                            top: 8,
                                            right: 8,
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.black87,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                '${stream.viewers} Watching',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                          // User name (bottom-left, above Chit Chat bar)
                                          Positioned(
                                            left: 8,
                                            bottom:
                                                48, // adjust as needed for your bar height
                                            child: Text(
                                              userName.isNotEmpty
                                                  ? userName
                                                  : 'Host',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                                shadows: [
                                                  Shadow(
                                                    blurRadius: 4,
                                                    color: Colors.black,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          // Play icon (bottom-right, above Chit Chat bar)
                                          Positioned(
                                            right: 8,
                                            bottom: 48, // same as above
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: Colors.black54,
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.play_circle_fill,
                                                color: Colors.white,
                                                size: 28,
                                              ),
                                            ),
                                          ),
                                          // Chit Chat + PK row (bottom, over image)
                                          Positioned(
                                            left: 0,
                                            right: 0,
                                            bottom: 0,
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                // color: Colors.black54,
                                                borderRadius:
                                                    const BorderRadius.vertical(
                                                      bottom: Radius.circular(
                                                        12,
                                                      ),
                                                    ),
                                              ),
                                              child: Row(
                                                children: [
                                                  const Icon(
                                                    Icons.chat_bubble,
                                                    color: Colors.blue,
                                                    size: 18,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  const Text(
                                                    'Chit Chat',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                  const Spacer(),
                                                  Image.asset(
                                                    'assets/pk.png',
                                                    width: 40,
                                                    height: 40,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
    );
  }

  Widget _buildLiveOptionCard(String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.orange),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper for Live Ended dialog
  void showLiveEndedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Live Ended'),
            content: const Text('This live stream has ended.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }
}
