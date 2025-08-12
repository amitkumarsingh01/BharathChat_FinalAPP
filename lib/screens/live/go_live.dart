import 'package:flutter/material.dart';
import 'package:zego_uikit_prebuilt_live_streaming/zego_uikit_prebuilt_live_streaming.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../services/api_service.dart';
import 'package:camera/camera.dart'
    show
        CameraController,
        CameraDescription,
        CameraPreview,
        ResolutionPreset,
        availableCameras;
import 'package:just_audio/just_audio.dart';
import '../live/live_video_screen.dart';
import '../live/live_audio_screen.dart';
import '../../services/live_stream_service.dart';
import '../../common.dart';
import 'pk_battle_debug_screen.dart';

// Removed main() and MyApp. Only HomePage is exported for navigation.

class HomePage extends StatefulWidget {
  final int appID;
  final String appSign;

  const HomePage({super.key, required this.appID, required this.appSign});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController userIdController = TextEditingController();
  final TextEditingController roomIdController = TextEditingController();

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

  void joinLiveStream() async {
    final userID = userIdController.text.trim();
    final liveID = roomIdController.text.trim();

    if (userID.isEmpty || liveID.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter both User ID and Live Stream ID'),
        ),
      );
      return;
    }

    // Request permissions first
    bool permissionsGranted = await requestPermissions();
    if (!permissionsGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Camera and microphone permissions are required'),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => ZegoUIKitPrebuiltLiveStreaming(
              appID: widget.appID,
              appSign: widget.appSign,
              userID: userID,
              userName: userID,
              liveID: liveID,
              config:
                  ZegoUIKitPrebuiltLiveStreamingConfig.host()
                    // Basic settings
                    ..turnOnCameraWhenJoining = true
                    ..turnOnMicrophoneWhenJoining = true
                    ..useSpeakerWhenJoining = true
                    // Top menu bar settings
                    ..topMenuBar.buttons = [
                      // ZegoLiveStreamingMenuBarButtonName.minimizingButton,
                    ]
                    // Bottom menu bar settings
                    ..bottomMenuBar.hostButtons = [
                      ZegoLiveStreamingMenuBarButtonName.toggleCameraButton,
                      ZegoLiveStreamingMenuBarButtonName.toggleMicrophoneButton,
                      ZegoLiveStreamingMenuBarButtonName.leaveButton,
                      ZegoLiveStreamingMenuBarButtonName
                          .switchAudioOutputButton,
                      ZegoLiveStreamingMenuBarButtonName.chatButton,
                      ZegoLiveStreamingMenuBarButtonName.switchCameraButton,

                      // ZegoLiveStreamingMenuBarButtonName.beautyEffectButton,
                      // ZegoLiveStreamingMenuBarButtonName.soundEffectButton,
                    ]
                    // Audio video view config
                    ..audioVideoView.showAvatarInAudioMode = true
                    ..audioVideoView.showSoundWavesInAudioMode = true
                    ..audioVideoView.showMicrophoneStateOnView = true
                    ..audioVideoView.showUserNameOnView = false
                    ..avatarBuilder = (
                      BuildContext context,
                      Size size,
                      ZegoUIKitUser? user,
                      Map<String, dynamic> extraInfo,
                    ) {
                      return customAvatarBuilder(
                        context,
                        size,
                        user,
                        extraInfo,
                        profilePic:
                            null, // For this simple test, we don't have user data
                      );
                    }
                    // Custom button styles for enhanced UI
                    ..bottomMenuBar.buttonStyle =
                        ZegoLiveStreamingBottomMenuBarButtonStyle(
                          // Camera button icons with enhanced colors
                          toggleCameraOnButtonIcon: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 24,
                          ),
                          toggleCameraOffButtonIcon: const Icon(
                            Icons.camera_alt_outlined,
                            color: Colors.red,
                            size: 24,
                          ),

                          // Microphone button icons with enhanced colors
                          toggleMicrophoneOnButtonIcon: const Icon(
                            Icons.mic,
                            color: Colors.white,
                            size: 24,
                          ),
                          toggleMicrophoneOffButtonIcon: const Icon(
                            Icons.mic_off,
                            color: Colors.red,
                            size: 24,
                          ),

                          // Chat button icons with enhanced colors
                          chatEnabledButtonIcon: const Icon(
                            Icons.chat_bubble,
                            color: Colors.white,
                            size: 24,
                          ),
                          chatDisabledButtonIcon: const Icon(
                            Icons.chat_bubble_outline,
                            color: Colors.grey,
                            size: 24,
                          ),

                          // Audio output button icons with enhanced colors
                          switchAudioOutputToSpeakerButtonIcon: const Icon(
                            Icons.volume_up,
                            color: Colors.white,
                            size: 24,
                          ),
                          switchAudioOutputToHeadphoneButtonIcon: const Icon(
                            Icons.headphones,
                            color: Colors.white,
                            size: 24,
                          ),
                          switchAudioOutputToBluetoothButtonIcon: const Icon(
                            Icons.bluetooth,
                            color: Colors.white,
                            size: 24,
                          ),

                          // Leave button icon with enhanced color
                          leaveButtonIcon: const Icon(
                            Icons.call_end,
                            color: Colors.red,
                            size: 24,
                          ),

                          // Beauty effect button icon
                          beautyEffectButtonIcon: const Icon(
                            Icons.face,
                            color: Colors.white,
                            size: 24,
                          ),

                          // Sound effect button icon
                          soundEffectButtonIcon: const Icon(
                            Icons.graphic_eq,
                            color: Colors.white,
                            size: 24,
                          ),

                          // Switch camera button icon with enhanced colors
                          switchCameraButtonIcon: Container(
                            decoration: BoxDecoration(color: Colors.orange),
                            child: const Icon(
                              Icons.flip_camera_ios,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),

                          // Background button icon
                        ),
            ),
      ),
    );
  }

  @override
  void dispose() {
    userIdController.dispose();
    roomIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Streaming'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Enter your details to start live streaming',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            TextField(
              controller: userIdController,
              decoration: const InputDecoration(
                labelText: "Enter your User ID",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: roomIdController,
              decoration: const InputDecoration(
                labelText: "Enter Live Stream ID",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.live_tv),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: joinLiveStream,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  "Start Live Stream",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Make sure to allow camera and microphone permissions',
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class Category {
  final String name;
  final String icon;
  final String type;

  Category({required this.name, required this.icon, required this.type});
}

class GoLiveScreen extends StatefulWidget {
  const GoLiveScreen({Key? key}) : super(key: key);

  @override
  State<GoLiveScreen> createState() => _GoLiveScreenState();
}

class _GoLiveScreenState extends State<GoLiveScreen> {
  bool isVideoMode = true;
  bool videoOn = true;
  bool autoCall = true;
  String selectedCategory = 'Live Show';
  String selectedHashtag = 'कुछ नहीं';
  final TextEditingController nameController = TextEditingController();
  final TextEditingController chatroomController = TextEditingController();

  CameraController? _cameraController;
  List<dynamic> backgroundImages = [];
  List<dynamic> musicList = [];
  List<dynamic> gifts = [];
  String? selectedBackgroundImage;
  String? selectedMusic;
  final _audioPlayer = AudioPlayer();
  bool isPlaying = false;

  Language selectedLanguage = languages[0];

  // PK Battle Transactions
  Map<String, dynamic>? pkBattleTransactions;
  bool isLoadingPKBattleData = false;
  int? currentPKBattleId = 150; // For testing, you can make this dynamic

  // Request permissions before joining live stream
  Future<bool> requestPermissions() async {
    final List<Permission> permissions =
        isVideoMode
            ? [Permission.camera, Permission.microphone]
            : [Permission.microphone];

    Map<Permission, PermissionStatus> statuses = await permissions.request();

    return statuses.values.every(
      (status) => status == PermissionStatus.granted,
    );
  }

  final List<Category> categories = [
    Category(name: 'Live Show', icon: '🎥', type: 'live'),
    Category(name: 'Party Room', icon: '🎉', type: 'party'),
    Category(name: 'Singing', icon: '🎤', type: 'singing'),
    Category(name: 'Dance', icon: '💃', type: 'dance'),
    Category(name: 'Comedy', icon: '😄', type: 'comedy'),
  ];

  final List<String> hashtags = [
    'कुछ नहीं',
    'Sitaarein Eloelo Par⭐',
    'खबाबों का सफर😎',
    'दिल के टुट',
    'गपशप💭',
  ];

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _loadBackgroundData();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isNotEmpty) {
      _cameraController = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: true,
      );
      await _cameraController!.initialize();
      if (mounted) setState(() {});
    }
  }

  Future<void> _loadBackgroundData() async {
    final images = await ApiService.getBackgroundImages();
    final music = await ApiService.getMusic();
    final giftsData = await ApiService.getGifts();
    setState(() {
      backgroundImages = images;
      musicList = music;
      gifts = giftsData;
    });
  }

  Future<void> _loadPKBattleTransactions() async {
    if (currentPKBattleId == null) return;

    setState(() {
      isLoadingPKBattleData = true;
    });

    try {
      final data = await ApiService.getPKBattleTransactions(currentPKBattleId!);
      setState(() {
        pkBattleTransactions = data;
        isLoadingPKBattleData = false;
      });
    } catch (e) {
      print('Error loading PK battle transactions: $e');
      setState(() {
        isLoadingPKBattleData = false;
      });
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      // Move the bottom navigation and Go Live button to bottomNavigationBar
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() => isVideoMode = false);
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        !isVideoMode
                            ? ShaderMask(
                              shaderCallback: (Rect bounds) {
                                return LinearGradient(
                                  colors: [
                                    Color(0xFFffa030),
                                    Color(0xFFfe9b00),
                                    Color(0xFFf67d00),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ).createShader(bounds);
                              },
                              child: Icon(
                                Icons.mic,
                                color: Colors.white,
                                size: 28,
                              ),
                            )
                            : Icon(Icons.mic, color: Colors.grey, size: 28),
                        const SizedBox(height: 4),
                        Text(
                          'Audio',
                          style: TextStyle(
                            color:
                                !isVideoMode ? Color(0xFFffa030) : Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          height: 2,
                          color:
                              !isVideoMode
                                  ? Color(0xFFffa030)
                                  : Colors.transparent,
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() => isVideoMode = true);
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        isVideoMode
                            ? ShaderMask(
                              shaderCallback: (Rect bounds) {
                                return LinearGradient(
                                  colors: [
                                    Color(0xFFffa030),
                                    Color(0xFFfe9b00),
                                    Color(0xFFf67d00),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ).createShader(bounds);
                              },
                              child: Icon(
                                Icons.videocam,
                                color: Colors.white,
                                size: 28,
                              ),
                            )
                            : Icon(
                              Icons.videocam,
                              color: Colors.grey,
                              size: 28,
                            ),
                        const SizedBox(height: 4),
                        Text(
                          'Video',
                          style: TextStyle(
                            color:
                                isVideoMode ? Color(0xFFffa030) : Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          height: 2,
                          color:
                              isVideoMode
                                  ? Color(0xFFffa030)
                                  : Colors.transparent,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 60),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFffa030),
                    Color(0xFFfe9b00),
                    Color(0xFFf67d00),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(25),
              ),
              child: ElevatedButton(
                onPressed: () => _goLive(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Text(
                  'Go Live',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with back button and language selector
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.arrow_back_ios,
                              color: Colors.white,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const Text(
                            'Host Live Show',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                if (!isVideoMode) ...[
                  // Background Image Selection
                  // Padding(
                  //   padding: const EdgeInsets.symmetric(horizontal: 16),
                  //   child: Column(
                  //     crossAxisAlignment: CrossAxisAlignment.start,
                  //     children: [
                  //       const Text(
                  //         'Select Background',
                  //         style: TextStyle(
                  //           color: Colors.white,
                  //           fontSize: 18,
                  //           fontWeight: FontWeight.w600,
                  //         ),
                  //       ),
                  //       const SizedBox(height: 16),
                  //       SizedBox(
                  //         height: 100,
                  //         child: ListView.builder(
                  //           scrollDirection: Axis.horizontal,
                  //           itemCount: backgroundImages.length,
                  //           itemBuilder: (context, index) {
                  //             final image = backgroundImages[index];
                  //             return GestureDetector(
                  //               onTap: () {
                  //                 setState(() {
                  //                   selectedBackgroundImage = image['filename'];
                  //                 });
                  //               },
                  //               child: Container(
                  //                 width: 100,
                  //                 margin: const EdgeInsets.only(right: 8),
                  //                 decoration:
                  //                     selectedBackgroundImage ==
                  //                             image['filename']
                  //                         ? BoxDecoration(
                  //                           gradient: LinearGradient(
                  //                             colors: [
                  //                               Color(0xFFffa030),
                  //                               Color(0xFFfe9b00),
                  //                               Color(0xFFf67d00),
                  //                             ],
                  //                             begin: Alignment.topLeft,
                  //                             end: Alignment.bottomRight,
                  //                           ),
                  //                           borderRadius: BorderRadius.circular(
                  //                             10,
                  //                           ),
                  //                         )
                  //                         : BoxDecoration(
                  //                           color: Colors.transparent,
                  //                           borderRadius: BorderRadius.circular(
                  //                             10,
                  //                           ),
                  //                         ),
                  //                 padding:
                  //                     selectedBackgroundImage ==
                  //                             image['filename']
                  //                         ? const EdgeInsets.all(2)
                  //                         : EdgeInsets.zero,
                  //                 child: ClipRRect(
                  //                   borderRadius: BorderRadius.circular(8),
                  //                   child: Image.network(
                  //                     'https://server.bharathchat.com/uploads/backgrounds/${image['filename']}',
                  //                     fit: BoxFit.cover,
                  //                   ),
                  //                 ),
                  //               ),
                  //             );
                  //           },
                  //         ),
                  //       ),
                  //     ],
                  //   ),
                  // ),

                  // const SizedBox(height: 20),

                  // Music Selection
                  // Padding(
                  //   padding: const EdgeInsets.symmetric(horizontal: 16),
                  //   child: Column(
                  //     crossAxisAlignment: CrossAxisAlignment.start,
                  //     children: [
                  //       const Text(
                  //         'Select Music',
                  //         style: TextStyle(
                  //           color: Colors.white,
                  //           fontSize: 18,
                  //           fontWeight: FontWeight.w600,
                  //         ),
                  //       ),
                  //       const SizedBox(height: 16),
                  //       SizedBox(
                  //         height: 100,
                  //         child: ListView.builder(
                  //           scrollDirection: Axis.horizontal,
                  //           itemCount: musicList.length,
                  //           itemBuilder: (context, index) {
                  //             final music = musicList[index];
                  //             final isSelected =
                  //                 selectedMusic == music['filename'];
                  //             return GestureDetector(
                  //               onTap: () async {
                  //                 if (isSelected) {
                  //                   await _audioPlayer.stop();
                  //                   setState(() {
                  //                     selectedMusic = null;
                  //                     isPlaying = false;
                  //                   });
                  //                 } else {
                  //                   setState(
                  //                     () => selectedMusic = music['filename'],
                  //                   );
                  //                   await _audioPlayer.setUrl(
                  //                     'https://server.bharathchat.com/uploads/music/${music['filename']}',
                  //                   );
                  //                   _audioPlayer.play();
                  //                   setState(() => isPlaying = true);
                  //                 }
                  //               },
                  //               child: Container(
                  //                 width: 100,
                  //                 margin: const EdgeInsets.only(right: 8),
                  //                 decoration:
                  //                     isSelected
                  //                         ? BoxDecoration(
                  //                           gradient: LinearGradient(
                  //                             colors: [
                  //                               Color(0xFFffa030),
                  //                               Color(0xFFfe9b00),
                  //                               Color(0xFFf67d00),
                  //                             ],
                  //                             begin: Alignment.topLeft,
                  //                             end: Alignment.bottomRight,
                  //                           ),
                  //                           borderRadius: BorderRadius.circular(
                  //                             10,
                  //                           ),
                  //                         )
                  //                         : BoxDecoration(
                  //                           color: Colors.transparent,
                  //                           borderRadius: BorderRadius.circular(
                  //                             10,
                  //                           ),
                  //                         ),
                  //                 padding:
                  //                     isSelected
                  //                         ? const EdgeInsets.all(2)
                  //                         : EdgeInsets.zero,
                  //                 child: Container(
                  //                   decoration: BoxDecoration(
                  //                     color: Colors.grey[900],
                  //                     borderRadius: BorderRadius.circular(8),
                  //                   ),
                  //                   child: Column(
                  //                     mainAxisAlignment:
                  //                         MainAxisAlignment.center,
                  //                     children: [
                  //                       Icon(
                  //                         isSelected && isPlaying
                  //                             ? Icons.pause
                  //                             : Icons.play_arrow,
                  //                         color: Colors.white,
                  //                         size: 32,
                  //                       ),
                  //                       const SizedBox(height: 4),
                  //                       Text(
                  //                         'Music ${index + 1}',
                  //                         style: const TextStyle(
                  //                           color: Colors.white,
                  //                           fontSize: 12,
                  //                         ),
                  //                       ),
                  //                     ],
                  //                   ),
                  //                 ),
                  //               ),
                  //             );
                  //           },
                  //         ),
                  //       ),
                  //     ],
                  //   ),
                  // ),
                ],

                const SizedBox(height: 20),

                // Language Selection
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select Language',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children:
                              languages.map((lang) {
                                final isSelected =
                                    selectedLanguage.code == lang.code;
                                return GestureDetector(
                                  onTap: () {
                                    setState(() => selectedLanguage = lang);
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.only(right: 12),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          isSelected
                                              ? lang.backgroundColor
                                              : Colors.grey[900],
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color:
                                            isSelected
                                                ? Colors.white
                                                : Colors.grey,
                                        width: isSelected ? 2 : 1,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          lang.nativeName,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        Text(
                                          lang.name,
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 12,
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

                const SizedBox(height: 20),

                // Categories
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Choose Category',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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
                                      () => selectedCategory = category.name,
                                    );
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.only(right: 12),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      gradient:
                                          isSelected
                                              ? LinearGradient(
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
                                          isSelected ? null : Colors.grey[900],
                                      borderRadius: BorderRadius.circular(12),
                                      border:
                                          isSelected
                                              ? Border.all(
                                                color: Color(0xFFffa030),
                                                width: 2,
                                              )
                                              : null,
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          category.icon,
                                          style: const TextStyle(fontSize: 24),
                                        ),
                                        const SizedBox(height: 4),
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

                const SizedBox(height: 20),

                // Hidden hashtag with default value "iamlive"
                Container(
                  width: 0,
                  height: 0,
                  child: const Text(
                    'iamlive',
                    style: TextStyle(fontSize: 0, color: Colors.transparent),
                  ),
                ),

                const SizedBox(height: 20),

                // Gifts Section
                //     Padding(
                //       padding: const EdgeInsets.symmetric(horizontal: 16),
                //       child: Column(
                //         crossAxisAlignment: CrossAxisAlignment.start,
                //         children: [
                //           const Text(
                //             'Available Gifts',
                //             style: TextStyle(
                //               color: Colors.white,
                //               fontSize: 18,
                //               fontWeight: FontWeight.w600,
                //             ),
                //           ),
                //           const SizedBox(height: 16),
                //           SizedBox(
                //             height: 120,
                //             child: ListView.builder(
                //               scrollDirection: Axis.horizontal,
                //               itemCount: gifts.length,
                //               itemBuilder: (context, index) {
                //                 final gift = gifts[index];
                //                 return Container(
                //                   width: 100,
                //                   margin: const EdgeInsets.only(right: 12),
                //                   decoration: BoxDecoration(
                //                     color: Colors.grey[900],
                //                     borderRadius: BorderRadius.circular(12),
                //                     border: Border.all(
                //                       color: Colors.grey[700]!,
                //                       width: 1,
                //                     ),
                //                   ),
                //                   child: Column(
                //                     mainAxisAlignment: MainAxisAlignment.center,
                //                     children: [
                //                       // Gift Image
                //                       Container(
                //                         width: 60,
                //                         height: 60,
                //                         decoration: BoxDecoration(
                //                           borderRadius: BorderRadius.circular(8),
                //                           color: Colors.grey[800],
                //                         ),
                //                         child: ClipRRect(
                //                           borderRadius: BorderRadius.circular(8),
                //                           child: Image.network(
                //                             'https://server.bharathchat.com/uploads/gifts/${gift['gif_filename']}',
                //                             fit: BoxFit.cover,
                //                             errorBuilder: (
                //                               context,
                //                               error,
                //                               stackTrace,
                //                             ) {
                //                               return Container(
                //                                 decoration: BoxDecoration(
                //                                   color: Colors.grey[800],
                //                                   borderRadius:
                //                                       BorderRadius.circular(8),
                //                                 ),
                //                                 child: const Icon(
                //                                   Icons.card_giftcard,
                //                                   color: Colors.white,
                //                                   size: 30,
                //                                 ),
                //                               );
                //                             },
                //                           ),
                //                         ),
                //                       ),
                //                       const SizedBox(height: 8),
                //                       // Gift Name
                //                       Text(
                //                         gift['name'] ?? 'Gift',
                //                         style: const TextStyle(
                //                           color: Colors.white,
                //                           fontSize: 12,
                //                           fontWeight: FontWeight.w500,
                //                         ),
                //                         textAlign: TextAlign.center,
                //                         maxLines: 1,
                //                         overflow: TextOverflow.ellipsis,
                //                       ),
                //                       const SizedBox(height: 4),
                //                       // Diamond Amount
                //                       Container(
                //                         padding: const EdgeInsets.symmetric(
                //                           horizontal: 6,
                //                           vertical: 2,
                //                         ),
                //                         decoration: BoxDecoration(
                //                           color: Colors.orange,
                //                           borderRadius: BorderRadius.circular(8),
                //                         ),
                //                         child: Text(
                //                           '${gift['diamond_amount']} 💎',
                //                           style: const TextStyle(
                //                             color: Colors.white,
                //                             fontSize: 10,
                //                             fontWeight: FontWeight.bold,
                //                           ),
                //                         ),
                //                       ),
                //                     ],
                //                   ),
                //                 );
                //               },
                //             ),
                //           ),
                //         ],
                //       ),
                //     ),

                //     const SizedBox(height: 20),

                //     // PK Battle Transactions Section
                //     Padding(
                //       padding: const EdgeInsets.symmetric(horizontal: 16),
                //       child: Column(
                //         crossAxisAlignment: CrossAxisAlignment.start,
                //         children: [
                //           Column(
                //             crossAxisAlignment: CrossAxisAlignment.start,
                //             children: [
                //               const Text(
                //                 'PK Battle Transactions',
                //                 style: TextStyle(
                //                   color: Colors.white,
                //                   fontSize: 18,
                //                   fontWeight: FontWeight.w600,
                //                 ),
                //               ),
                //               const SizedBox(height: 8),
                //               Row(
                //                 children: [
                //                   if (currentPKBattleId != null)
                //                     Container(
                //                       padding: const EdgeInsets.symmetric(
                //                         horizontal: 8,
                //                         vertical: 4,
                //                       ),
                //                       decoration: BoxDecoration(
                //                         color: Colors.orange,
                //                         borderRadius: BorderRadius.circular(8),
                //                       ),
                //                       child: Text(
                //                         'ID: $currentPKBattleId',
                //                         style: const TextStyle(
                //                           color: Colors.white,
                //                           fontSize: 12,
                //                           fontWeight: FontWeight.bold,
                //                         ),
                //                       ),
                //                     ),
                //                   const SizedBox(width: 8),
                //                   Flexible(
                //                     child: ElevatedButton.icon(
                //                       onPressed: _loadPKBattleTransactions,
                //                       style: ElevatedButton.styleFrom(
                //                         backgroundColor: Colors.blue,
                //                         padding: const EdgeInsets.symmetric(
                //                           horizontal: 8,
                //                           vertical: 8,
                //                         ),
                //                         shape: RoundedRectangleBorder(
                //                           borderRadius: BorderRadius.circular(8),
                //                         ),
                //                       ),
                //                       icon:
                //                           isLoadingPKBattleData
                //                               ? const SizedBox(
                //                                 width: 16,
                //                                 height: 16,
                //                                 child: CircularProgressIndicator(
                //                                   strokeWidth: 2,
                //                                   valueColor:
                //                                       AlwaysStoppedAnimation<Color>(
                //                                         Colors.white,
                //                                       ),
                //                                 ),
                //                               )
                //                               : const Icon(
                //                                 Icons.refresh,
                //                                 color: Colors.white,
                //                                 size: 16,
                //                               ),
                //                       label: Text(
                //                         isLoadingPKBattleData ? 'Loading...' : 'R',
                //                         style: const TextStyle(
                //                           color: Colors.white,
                //                           fontSize: 12,
                //                           fontWeight: FontWeight.w600,
                //                         ),
                //                       ),
                //                     ),
                //                   ),
                //                 ],
                //               ),
                //             ],
                //           ),
                //           const SizedBox(height: 16),

                //           if (pkBattleTransactions != null) ...[
                //             // PK Battle Info
                //             Container(
                //               width: double.infinity,
                //               padding: const EdgeInsets.all(16),
                //               decoration: BoxDecoration(
                //                 color: Colors.grey[900],
                //                 borderRadius: BorderRadius.circular(12),
                //                 border: Border.all(color: Colors.grey[700]!),
                //               ),
                //               child: Column(
                //                 crossAxisAlignment: CrossAxisAlignment.start,
                //                 children: [
                //                   const Text(
                //                     'Battle Info',
                //                     style: TextStyle(
                //                       color: Colors.white,
                //                       fontSize: 16,
                //                       fontWeight: FontWeight.bold,
                //                     ),
                //                   ),
                //                   const SizedBox(height: 8),
                //                   _buildPKBattleInfo(
                //                     pkBattleTransactions!['pk_battle_info'],
                //                   ),
                //                 ],
                //               ),
                //             ),

                //             const SizedBox(height: 16),

                //             // Transactions List
                //             Container(
                //               width: double.infinity,
                //               padding: const EdgeInsets.all(16),
                //               decoration: BoxDecoration(
                //                 color: Colors.grey[900],
                //                 borderRadius: BorderRadius.circular(12),
                //                 border: Border.all(color: Colors.grey[700]!),
                //               ),
                //               child: Column(
                //                 crossAxisAlignment: CrossAxisAlignment.start,
                //                 children: [
                //                   Row(
                //                     mainAxisAlignment:
                //                         MainAxisAlignment.spaceBetween,
                //                     children: [
                //                       const Text(
                //                         'Gift Transactions',
                //                         style: TextStyle(
                //                           color: Colors.white,
                //                           fontSize: 16,
                //                           fontWeight: FontWeight.bold,
                //                         ),
                //                       ),
                //                       Container(
                //                         padding: const EdgeInsets.symmetric(
                //                           horizontal: 8,
                //                           vertical: 4,
                //                         ),
                //                         decoration: BoxDecoration(
                //                           color: Colors.green,
                //                           borderRadius: BorderRadius.circular(8),
                //                         ),
                //                         child: Text(
                //                           '${pkBattleTransactions!['transactions'].length} gifts',
                //                           style: const TextStyle(
                //                             color: Colors.white,
                //                             fontSize: 12,
                //                             fontWeight: FontWeight.bold,
                //                           ),
                //                         ),
                //                       ),
                //                     ],
                //                   ),
                //                   const SizedBox(height: 12),
                //                   SizedBox(
                //                     height: 300,
                //                     child: ListView.builder(
                //                       itemCount:
                //                           pkBattleTransactions!['transactions']
                //                               .length,
                //                       itemBuilder: (context, index) {
                //                         final transaction =
                //                             pkBattleTransactions!['transactions'][index];
                //                         return _buildTransactionCard(
                //                           transaction,
                //                           index,
                //                         );
                //                       },
                //                     ),
                //                   ),
                //                 ],
                //               ),
                //             ),

                //             const SizedBox(height: 16),

                //             // Summary
                //             Container(
                //               width: double.infinity,
                //               padding: const EdgeInsets.all(16),
                //               decoration: BoxDecoration(
                //                 color: Colors.grey[900],
                //                 borderRadius: BorderRadius.circular(12),
                //                 border: Border.all(color: Colors.grey[700]!),
                //               ),
                //               child: Column(
                //                 crossAxisAlignment: CrossAxisAlignment.start,
                //                 children: [
                //                   const Text(
                //                     'Summary',
                //                     style: TextStyle(
                //                       color: Colors.white,
                //                       fontSize: 16,
                //                       fontWeight: FontWeight.bold,
                //                     ),
                //                   ),
                //                   const SizedBox(height: 8),
                //                   _buildSummaryInfo(
                //                     pkBattleTransactions!['summary'],
                //                   ),
                //                 ],
                //               ),
                //             ),
                //           ] else ...[
                //             Container(
                //               width: double.infinity,
                //               padding: const EdgeInsets.all(32),
                //               decoration: BoxDecoration(
                //                 color: Colors.grey[900],
                //                 borderRadius: BorderRadius.circular(12),
                //                 border: Border.all(color: Colors.grey[700]!),
                //               ),
                //               child: Column(
                //                 children: [
                //                   Icon(
                //                     Icons.sports_esports,
                //                     color: Colors.grey[600],
                //                     size: 48,
                //                   ),
                //                   const SizedBox(height: 16),
                //                   Text(
                //                     'No PK Battle Data',
                //                     style: TextStyle(
                //                       color: Colors.grey[400],
                //                       fontSize: 16,
                //                       fontWeight: FontWeight.w500,
                //                     ),
                //                   ),
                //                   const SizedBox(height: 8),
                //                   Text(
                //                     'Tap Refresh to load PK battle transactions',
                //                     style: TextStyle(
                //                       color: Colors.grey[600],
                //                       fontSize: 12,
                //                     ),
                //                   ),
                //                 ],
                //               ),
                //             ),
                //           ],
                //         ],
                //       ),
                //     ),

                //     const SizedBox(height: 20),

                //     // Debug PK Battle Gift API Button
                //     Padding(
                //       padding: const EdgeInsets.symmetric(horizontal: 16),
                //       child: Column(
                //         crossAxisAlignment: CrossAxisAlignment.start,
                //         children: [
                //           const Text(
                //             'Debug Tools',
                //             style: TextStyle(
                //               color: Colors.white,
                //               fontSize: 18,
                //               fontWeight: FontWeight.w600,
                //             ),
                //           ),
                //           const SizedBox(height: 16),
                //           Container(
                //             width: double.infinity,
                //             decoration: BoxDecoration(
                //               color: Colors.grey[900],
                //               borderRadius: BorderRadius.circular(12),
                //               border: Border.all(
                //                 color: Colors.grey[700]!,
                //                 width: 1,
                //               ),
                //             ),
                //             child: Column(
                //               children: [
                //                 Padding(
                //                   padding: const EdgeInsets.all(16),
                //                   child: Column(
                //                     crossAxisAlignment: CrossAxisAlignment.start,
                //                     children: [
                //                       const Text(
                //                         'Test PK Battle Gift API',
                //                         style: TextStyle(
                //                           color: Colors.white,
                //                           fontSize: 16,
                //                           fontWeight: FontWeight.w600,
                //                         ),
                //                       ),
                //                       const SizedBox(height: 8),
                //                       const Text(
                //                         'This will test the /pk-battle/gift API call with sample data',
                //                         style: TextStyle(
                //                           color: Colors.grey,
                //                           fontSize: 12,
                //                         ),
                //                       ),
                //                       const SizedBox(height: 16),
                //                       SizedBox(
                //                         width: double.infinity,
                //                         child: ElevatedButton.icon(
                //                           onPressed: _testPKBattleGiftAPI,
                //                           style: ElevatedButton.styleFrom(
                //                             backgroundColor: Colors.orange,
                //                             padding: const EdgeInsets.symmetric(
                //                               vertical: 12,
                //                             ),
                //                             shape: RoundedRectangleBorder(
                //                               borderRadius: BorderRadius.circular(
                //                                 8,
                //                               ),
                //                             ),
                //                           ),
                //                           icon: const Icon(
                //                             Icons.bug_report,
                //                             color: Colors.white,
                //                             size: 20,
                //                           ),
                //                           label: const Text(
                //                             'Test PK Battle Gift API',
                //                             style: TextStyle(
                //                               color: Colors.white,
                //                               fontSize: 14,
                //                               fontWeight: FontWeight.w600,
                //                             ),
                //                           ),
                //                         ),
                //                       ),
                //                     ],
                //                   ),
                //                 ),
                //               ],
                //             ),
                //           ),
                //         ],
                //       ),
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToggleRow(String title, bool value, Function(bool) onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        GestureDetector(
          onTap: () => onChanged(!value),
          child: AnimatedContainer(
            duration: Duration(milliseconds: 200),
            width: 50,
            height: 28,
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient:
                  value
                      ? LinearGradient(
                        colors: [
                          Color(0xFFffa030),
                          Color(0xFFfe9b00),
                          Color(0xFFf67d00),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                      : null,
              color: value ? null : Colors.grey[800],
              // color: value ? null : Colors.transparent,
            ),
            child: Align(
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: AnimatedContainer(
                duration: Duration(milliseconds: 200),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Debug method to test PK Battle Gift API
  void _testPKBattleGiftAPI() async {
    try {
      print('🔧 [DEBUG] Testing PK Battle Gift API...');

      // Sample data for testing (using the exact values from your curl example)
      const int pkBattleId = 150;
      const int senderId = 5;
      const int receiverId = 5;
      const int giftId = 2;
      const int amount = 1;

      print(
        '🔧 [DEBUG] This will call the EXACT same API as your curl command:',
      );
      print(
        '🔧 [DEBUG] curl -X POST https://server.bharathchat.com/pk-battle/gift',
      );
      print('🔧 [DEBUG] with body: {');
      print('🔧 [DEBUG]   "pk_battle_id": $pkBattleId,');
      print('🔧 [DEBUG]   "sender_id": $senderId,');
      print('🔧 [DEBUG]   "receiver_id": $receiverId,');
      print('🔧 [DEBUG]   "gift_id": $giftId,');
      print('🔧 [DEBUG]   "amount": $amount');
      print('🔧 [DEBUG] }');

      print('🔧 [DEBUG] PK Battle Gift API Parameters:');
      print('🔧 [DEBUG]   - PK Battle ID: $pkBattleId');
      print('🔧 [DEBUG]   - Sender ID: $senderId');
      print('🔧 [DEBUG]   - Receiver ID: $receiverId');
      print('🔧 [DEBUG]   - Gift ID: $giftId');
      print('🔧 [DEBUG]   - Amount: $amount');

      print('🔧 [DEBUG] Calling ApiService.sendPKBattleGift...');
      final success = await ApiService.sendPKBattleGift(
        pkBattleId: pkBattleId,
        senderId: senderId,
        receiverId: receiverId,
        giftId: giftId,
        amount: amount,
      );

      print('🔧 [DEBUG] PK Battle Gift API Result: $success');

      if (success) {
        print('✅ [DEBUG] PK Battle Gift API test SUCCESS!');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ PK Battle Gift API test successful!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        print('❌ [DEBUG] PK Battle Gift API test FAILED!');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ PK Battle Gift API test failed!'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      print('❌ [DEBUG] PK Battle Gift API test ERROR: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ PK Battle Gift API test error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _goLive(BuildContext context) async {
    try {
      // Generate a unique live URL using timestamp and random string
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final liveUrl =
          'live_${timestamp}_${nameController.text.isNotEmpty ? nameController.text.toLowerCase().replaceAll(' ', '_') : 'host'}';

      // Prepare the base data
      Map<String, dynamic> data;

      if (isVideoMode) {
        data = {
          'category': selectedCategory,
          'hashtag': [selectedHashtag],
          'live_url': liveUrl,
          'language': selectedLanguage.code,
        };
      } else {
        // Get music ID if music is selected
        int? musicId;
        if (selectedMusic != null) {
          musicId = await ApiService.getMusicIdByFilename(selectedMusic);
        }

        data = {
          'title':
              chatroomController.text.isNotEmpty
                  ? chatroomController.text
                  : 'Chatroom',
          'chat_room':
              nameController.text.isNotEmpty ? nameController.text : 'Host',
          'hashtag': [selectedHashtag],
          'music_id': musicId,
          'background_img': selectedBackgroundImage,
          'live_url': liveUrl,
          'language': selectedLanguage.code,
        };
      }

      // Call the appropriate API
      final response =
          isVideoMode
              ? await ApiService.createVideoLive(data)
              : await ApiService.createAudioLive(data);

      // Debug logging
      print(
        'API Response for ${isVideoMode ? 'video' : 'audio'} live: $response',
      );

      // Check if live_id exists and is not null
      if (response['live_id'] == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error: Could not create live session'),
            ),
          );
        }
        return;
      }

      // Add the stream to LiveStreamService so it appears in the live streams list
      final liveStreamService = LiveStreamService();
      final streamType =
          isVideoMode ? LiveStreamType.video : LiveStreamType.audio;
      final userData = ApiService.currentUserData;
      final streamTitle =
          isVideoMode
              ? selectedCategory
              : (chatroomController.text.isNotEmpty
                  ? chatroomController.text
                  : 'Chatroom');

      liveStreamService.addStream(
        LiveStream(
          channelName: liveUrl,
          type: streamType,
          viewers: 0,
          host:
              userData != null
                  ? (userData['first_name'] ?? 'Host')
                  : (nameController.text.isNotEmpty
                      ? nameController.text
                      : 'Host'),
          liveId: response['live_id'] as int,
          userId: userData != null ? userData['id'] ?? 0 : 0,
        ),
      );

      // Navigate to the appropriate live screen
      if (context.mounted) {
        // Request permissions first
        bool permissionsGranted = await requestPermissions();
        if (!permissionsGranted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Camera and microphone permissions are required'),
            ),
          );
          return;
        }

        // Use real user info
        final userID =
            userData != null
                ? (userData['username'] ?? userData['id'].toString())
                : DateTime.now().millisecondsSinceEpoch.toString();
        final userName =
            userData != null
                ? (userData['first_name'] ?? 'Host')
                : (nameController.text.isNotEmpty
                    ? nameController.text
                    : 'Host');

        // Get user profile picture
        String? userAvatarUrl;
        if (userData != null && userData['profile_pic'] != null) {
          final profilePic = userData['profile_pic'].toString();
          if (profilePic.isNotEmpty) {
            userAvatarUrl =
                profilePic.startsWith('http')
                    ? profilePic
                    : 'https://server.bharathchat.com/$profilePic';
          }
        }

        // Create userName with avatar info for Zego
        final userNameWithAvatar =
            userAvatarUrl != null
                ? '${userName}|avatar:$userAvatarUrl'
                : userName;

        // Create the appropriate configuration
        late final ZegoUIKitPrebuiltLiveStreamingConfig config;

        if (isVideoMode) {
          config =
              ZegoUIKitPrebuiltLiveStreamingConfig.host()
                ..turnOnCameraWhenJoining = videoOn
                ..turnOnMicrophoneWhenJoining = true
                ..useSpeakerWhenJoining = true
                ..topMenuBar.buttons = [
                  // ZegoLiveStreamingMenuBarButtonName.minimizingButton,
                ]
                ..bottomMenuBar.hostButtons = [
                  ZegoLiveStreamingMenuBarButtonName.toggleCameraButton,
                  ZegoLiveStreamingMenuBarButtonName.toggleMicrophoneButton,
                  ZegoLiveStreamingMenuBarButtonName.leaveButton,
                  ZegoLiveStreamingMenuBarButtonName.switchAudioOutputButton,
                  ZegoLiveStreamingMenuBarButtonName.chatButton,
                  ZegoLiveStreamingMenuBarButtonName.switchCameraButton,
                ]
                ..audioVideoView.showAvatarInAudioMode = true
                ..audioVideoView.showSoundWavesInAudioMode = true
                ..audioVideoView.showMicrophoneStateOnView = true
                ..audioVideoView.showUserNameOnView = false
                ..avatarBuilder = (
                  BuildContext context,
                  Size size,
                  ZegoUIKitUser? user,
                  Map<String, dynamic> extraInfo,
                ) {
                  return customAvatarBuilder(
                    context,
                    size,
                    user,
                    extraInfo,
                    profilePic:
                        userData != null ? userData['profile_pic'] : null,
                  );
                }
                // Custom button styles for enhanced UI
                ..bottomMenuBar
                    .buttonStyle = ZegoLiveStreamingBottomMenuBarButtonStyle(
                  // Camera button icons with enhanced colors
                  toggleCameraOnButtonIcon: const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 24,
                  ),
                  toggleCameraOffButtonIcon: const Icon(
                    Icons.camera_alt_outlined,
                    color: Colors.red,
                    size: 24,
                  ),

                  // Microphone button icons with enhanced colors
                  toggleMicrophoneOnButtonIcon: const Icon(
                    Icons.mic,
                    color: Colors.white,
                    size: 24,
                  ),
                  toggleMicrophoneOffButtonIcon: const Icon(
                    Icons.mic_off,
                    color: Colors.red,
                    size: 24,
                  ),

                  // Chat button icons with enhanced colors
                  chatEnabledButtonIcon: const Icon(
                    Icons.chat_bubble,
                    color: Colors.white,
                    size: 24,
                  ),
                  chatDisabledButtonIcon: const Icon(
                    Icons.chat_bubble_outline,
                    color: Colors.grey,
                    size: 24,
                  ),

                  // Audio output button icons with enhanced colors
                  switchAudioOutputToSpeakerButtonIcon: const Icon(
                    Icons.volume_up,
                    color: Colors.white,
                    size: 24,
                  ),
                  switchAudioOutputToHeadphoneButtonIcon: const Icon(
                    Icons.headphones,
                    color: Colors.white,
                    size: 24,
                  ),
                  switchAudioOutputToBluetoothButtonIcon: const Icon(
                    Icons.bluetooth,
                    color: Colors.white,
                    size: 24,
                  ),

                  // Leave button icon with enhanced color
                  leaveButtonIcon: const Icon(
                    Icons.call_end,
                    color: Colors.red,
                    size: 24,
                  ),

                  // Beauty effect button icon
                  beautyEffectButtonIcon: const Icon(
                    Icons.face,
                    color: Colors.white,
                    size: 24,
                  ),

                  // Sound effect button icon
                  soundEffectButtonIcon: const Icon(
                    Icons.graphic_eq,
                    color: Colors.white,
                    size: 24,
                  ),

                  // Switch camera button icon with enhanced colors
                  switchCameraButtonIcon: const Icon(
                    Icons.flip_camera_ios,
                    color: Colors.white,
                    size: 24,
                  ),
                );
        } else {
          config =
              ZegoUIKitPrebuiltLiveStreamingConfig.host()
                ..turnOnCameraWhenJoining = false
                ..turnOnMicrophoneWhenJoining = true
                ..useSpeakerWhenJoining = true
                ..topMenuBar.buttons = [
                  // ZegoLiveStreamingMenuBarButtonName.minimizingButton,
                ]
                ..bottomMenuBar.hostButtons = [
                  ZegoLiveStreamingMenuBarButtonName.toggleMicrophoneButton,
                  ZegoLiveStreamingMenuBarButtonName.leaveButton,
                  ZegoLiveStreamingMenuBarButtonName.switchAudioOutputButton,
                  ZegoLiveStreamingMenuBarButtonName.chatButton,
                ]
                ..audioVideoView.showAvatarInAudioMode = true
                ..audioVideoView.showSoundWavesInAudioMode = true
                ..audioVideoView.showMicrophoneStateOnView = true
                ..audioVideoView.showUserNameOnView = false
                ..avatarBuilder = (
                  BuildContext context,
                  Size size,
                  ZegoUIKitUser? user,
                  Map<String, dynamic> extraInfo,
                ) {
                  return customAvatarBuilder(
                    context,
                    size,
                    user,
                    extraInfo,
                    profilePic:
                        userData != null ? userData['profile_pic'] : null,
                  );
                }
                // Custom button styles for enhanced UI
                ..bottomMenuBar
                    .buttonStyle = ZegoLiveStreamingBottomMenuBarButtonStyle(
                  // Microphone button icons with enhanced colors
                  toggleMicrophoneOnButtonIcon: const Icon(
                    Icons.mic,
                    color: Colors.white,
                    size: 24,
                  ),
                  toggleMicrophoneOffButtonIcon: const Icon(
                    Icons.mic_off,
                    color: Colors.red,
                    size: 24,
                  ),

                  // Chat button icons with enhanced colors
                  chatEnabledButtonIcon: const Icon(
                    Icons.chat_bubble,
                    color: Colors.white,
                    size: 24,
                  ),
                  chatDisabledButtonIcon: const Icon(
                    Icons.chat_bubble_outline,
                    color: Colors.grey,
                    size: 24,
                  ),

                  // Audio output button icons with enhanced colors
                  switchAudioOutputToSpeakerButtonIcon: const Icon(
                    Icons.volume_up,
                    color: Colors.white,
                    size: 24,
                  ),
                  switchAudioOutputToHeadphoneButtonIcon: const Icon(
                    Icons.headphones,
                    color: Colors.white,
                    size: 24,
                  ),
                  switchAudioOutputToBluetoothButtonIcon: const Icon(
                    Icons.bluetooth,
                    color: Colors.white,
                    size: 24,
                  ),

                  // Leave button icon with enhanced color
                  leaveButtonIcon: const Icon(
                    Icons.call_end,
                    color: Colors.red,
                    size: 24,
                  ),

                  // Beauty effect button icon
                  beautyEffectButtonIcon: const Icon(
                    Icons.face,
                    color: Colors.white,
                    size: 24,
                  ),

                  // Sound effect button icon
                  soundEffectButtonIcon: const Icon(
                    Icons.graphic_eq,
                    color: Colors.white,
                    size: 24,
                  ),

                  // Switch camera button icon with enhanced colors
                  switchCameraButtonIcon: const Icon(
                    Icons.flip_camera_ios,
                    color: Colors.white,
                    size: 24,
                  ),
                );
        }

        // Navigate to the appropriate screen based on mode
        if (isVideoMode) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => LiveVideoScreen(
                    liveID: liveUrl,
                    localUserID: userID,
                    isHost: true,
                    hostId: userData != null ? userData['id'] ?? 0 : 0,
                  ),
            ),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => LiveAudioScreen(
                    liveID: liveUrl,
                    localUserID: userID,
                    isHost: true,
                    hostId: userData != null ? userData['id'] ?? 0 : 0,
                    backgroundImage: selectedBackgroundImage,
                    backgroundMusic: selectedMusic,
                    profilePic:
                        userData != null ? userData['profile_pic'] : null,
                  ),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error starting live: $e')));
      }
    }
  }

  // Helper method to build PK Battle Info
  Widget _buildPKBattleInfo(Map<String, dynamic> battleInfo) {
    final leftScore = battleInfo['left_score'] ?? 0;
    final rightScore = battleInfo['right_score'] ?? 0;
    final status = battleInfo['status'] ?? 'unknown';
    final winnerId = battleInfo['winner_id'];

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Left Team',
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '$leftScore',
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
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.pink.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.pink),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Right Team',
                      style: TextStyle(
                        color: Colors.pink,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '$rightScore',
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
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Status: ${status.toUpperCase()}',
              style: TextStyle(
                color: status == 'ended' ? Colors.red : Colors.green,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (winnerId != null)
              Text(
                'Winner: ID $winnerId',
                style: const TextStyle(
                  color: Colors.orange,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ],
    );
  }

  // Helper method to build Transaction Card
  Widget _buildTransactionCard(Map<String, dynamic> transaction, int index) {
    final giftDetails = transaction['gift_details'] ?? {};
    final senderDetails = transaction['sender_details'] ?? {};
    final receiverDetails = transaction['receiver_details'] ?? {};
    final amount = transaction['amount'] ?? 0;
    final createdAt = DateTime.tryParse(transaction['created_at'] ?? '');

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[700]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Gift Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.card_giftcard,
                  color: Colors.orange,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              // Gift Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      giftDetails['name'] ?? 'Unknown Gift',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${giftDetails['diamond_amount'] ?? 0} 💎 x $amount',
                      style: const TextStyle(
                        color: Colors.orange,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              // Amount Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${(giftDetails['diamond_amount'] ?? 0) * amount}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'From:',
                      style: TextStyle(color: Colors.grey, fontSize: 10),
                    ),
                    Text(
                      senderDetails['first_name'] ?? 'Unknown',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward, color: Colors.grey, size: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'To:',
                      style: TextStyle(color: Colors.grey, fontSize: 10),
                    ),
                    Text(
                      receiverDetails['first_name'] ?? 'Unknown',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (createdAt != null) ...[
            const SizedBox(height: 4),
            Text(
              '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}',
              style: TextStyle(color: Colors.grey[600], fontSize: 10),
            ),
          ],
        ],
      ),
    );
  }

  // Helper method to build Summary Info
  Widget _buildSummaryInfo(Map<String, dynamic> summary) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSummaryItem(
                'Total Gifts',
                '${summary['total_transactions'] ?? 0}',
                Icons.card_giftcard,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildSummaryItem(
                'Total Diamonds',
                '${summary['total_diamonds_spent'] ?? 0}',
                Icons.diamond,
                Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildSummaryItem(
                'Left Team',
                '${summary['left_team_total'] ?? 0}',
                Icons.arrow_back,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildSummaryItem(
                'Right Team',
                '${summary['right_team_total'] ?? 0}',
                Icons.arrow_forward,
                Colors.pink,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildSummaryItem(
                'Senders',
                '${summary['unique_senders'] ?? 0}',
                Icons.person,
                Colors.green,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildSummaryItem(
                'Receivers',
                '${summary['unique_receivers'] ?? 0}',
                Icons.people,
                Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Helper method to build Summary Item
  Widget _buildSummaryItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 10)),
        ],
      ),
    );
  }
}
