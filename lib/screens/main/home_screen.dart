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

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class Language {
  final String name;
  final String nativeName;
  final String code;
  final Color backgroundColor;

  Language({
    required this.name,
    required this.nativeName,
    required this.code,
    required this.backgroundColor,
  });
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

  Future<Map<String, dynamic>> _userProfileFuture = Future.value({});

  // Store users by id for quick lookup
  Map<int, dynamic> _usersById = {};

  // Category selector support
  final List<Category> categories = [
    Category(name: 'Live Show', icon: '🎥', type: 'live'),
    Category(name: 'Party Room', icon: '🎉', type: 'party'),
    Category(name: 'Singing', icon: '🎤', type: 'singing'),
    Category(name: 'Dance', icon: '💃', type: 'dance'),
    Category(name: 'Comedy', icon: '😄', type: 'comedy'),
  ];
  String selectedCategory = 'Live Show';

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

  static final List<Language> languages = [
    Language(
      name: 'Hindi',
      nativeName: 'हिंदी',
      code: 'hi',
      backgroundColor: const Color(0xFF8B4513), // Brown
    ),
    Language(
      name: 'Telugu',
      nativeName: 'తెలుగు',
      code: 'te',
      backgroundColor: const Color(0xFF008080), // Teal
    ),
    Language(
      name: 'Tamil',
      nativeName: 'தமிழ்',
      code: 'ta',
      backgroundColor: const Color(0xFF556B2F), // Olive
    ),
    Language(
      name: 'Bengali',
      nativeName: 'বাংলা',
      code: 'bn',
      backgroundColor: const Color(0xFF800000), // Maroon
    ),
    Language(
      name: 'Marathi',
      nativeName: 'मराठी',
      code: 'mr',
      backgroundColor: const Color(0xFF8B4513), // Brown
    ),
    Language(
      name: 'Punjabi',
      nativeName: 'ਪੰਜਾਬੀ',
      code: 'pa',
      backgroundColor: const Color(0xFF000080), // Navy
    ),
    Language(
      name: 'Kannada',
      nativeName: 'ಕನ್ನಡ',
      code: 'kn',
      backgroundColor: const Color(0xFF4B0082), // Purple
    ),
    Language(
      name: 'Malayalam',
      nativeName: 'മലയാളം',
      code: 'ml',
      backgroundColor: const Color(0xFF006400), // Dark Green
    ),
  ];

  @override
  void initState() {
    super.initState();
    _checkUserActive();
    _loadData();
    _userProfileFuture = ApiService.getCurrentUser();
    // Start periodic refresh of live streams
    _startLiveStreamRefresh();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF181A20),
      appBar: AppBar(
        backgroundColor: const Color(0xFF23272F),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            // Language Selector
            GestureDetector(
              onTap: _showLanguageSelector,
              child: Container(
                height: 35,
                width: 40,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
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
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Diamond Store Icon
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const StoreScreen()),
                );
              },
              child: Image.asset('assets/diamond.png', width: 28, height: 28),
            ),
            const SizedBox(width: 10),
            // Trophy/Leaderboard Icon
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LeaderboardScreen(),
                  ),
                );
              },
              child: const Icon(
                Icons.emoji_events,
                color: Colors.orange,
                size: 28,
              ),
            ),
          ],
        ),
        actions: [
          // Search Icon
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white, size: 28),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SearchScreen()),
              );
            },
          ),
          // Go Live Button
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const GoLiveScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                child: const Text(
                  'Go Live',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          // Profile Photo
          Padding(
            padding: const EdgeInsets.only(right: 16),
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
                  if (snapshot.hasData &&
                      snapshot.data?['profile_pic'] != null) {
                    try {
                      final base64Str = snapshot.data!['profile_pic'];
                      print('HomeScreen profile_pic: ' + base64Str.toString());
                      // Handle both data URI and pure base64
                      final pureBase64 =
                          base64Str.contains(',')
                              ? base64Str.split(',').last
                              : base64Str;
                      return CircleAvatar(
                        radius: 16,
                        backgroundImage: MemoryImage(base64Decode(pureBase64)),
                      );
                    } catch (e) {
                      // If decoding fails, show an error icon
                      return CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.grey[800],
                        child: const Icon(
                          Icons.error,
                          color: Colors.red,
                          size: 20,
                        ),
                      );
                    }
                  }
                  return CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.grey[800],
                    child: const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 20,
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

                    const SizedBox(height: 30),

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
                          const SizedBox(height: 16),
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
                                        margin: const EdgeInsets.only(
                                          right: 12,
                                        ),
                                        padding: const EdgeInsets.all(12),
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
                                            12,
                                          ),
                                          border:
                                              isSelected
                                                  ? Border.all(
                                                    color: Colors.transparent,
                                                    width: 2,
                                                  )
                                                  : null,
                                        ),
                                        child: Column(
                                          children: [
                                            // Text(
                                            //   category.icon,
                                            //   style: const TextStyle(fontSize: 24),
                                            // ),
                                            // const SizedBox(height: 4),
                                            Text(
                                              category.name,
                                              style: TextStyle(
                                                color:
                                                    isSelected
                                                        ? Colors.black
                                                        : Colors.white,
                                                fontWeight: FontWeight.bold,
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

                        if (videoStreams.isEmpty) {
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
                          itemCount: videoStreams.length,
                          itemBuilder: (context, index) {
                            final stream = videoStreams[index];
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
                                                    ? Image.memory(
                                                      base64Decode(
                                                        profilePic.contains(',')
                                                            ? profilePic
                                                                .split(',')
                                                                .last
                                                            : profilePic,
                                                      ),
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
