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
              userName: "User_$userID",
              liveID: liveID,
              config:
                  ZegoUIKitPrebuiltLiveStreamingConfig.host()
                    // Basic settings
                    ..turnOnCameraWhenJoining = true
                    ..turnOnMicrophoneWhenJoining = true
                    ..useSpeakerWhenJoining = true
                    // Top menu bar settings
                    ..topMenuBar.buttons = [
                      ZegoLiveStreamingMenuBarButtonName.minimizingButton,
                      ZegoLiveStreamingMenuBarButtonName.switchCameraButton,
                    ]
                    // Bottom menu bar settings
                    ..bottomMenuBar.hostButtons = [
                      ZegoLiveStreamingMenuBarButtonName.toggleCameraButton,
                      ZegoLiveStreamingMenuBarButtonName.toggleMicrophoneButton,
                      ZegoLiveStreamingMenuBarButtonName.leaveButton,
                      ZegoLiveStreamingMenuBarButtonName
                          .switchAudioOutputButton,
                      ZegoLiveStreamingMenuBarButtonName.chatButton,
                    ]
                    // Audio video view config
                    ..audioVideoView.showAvatarInAudioMode = true
                    ..audioVideoView.showSoundWavesInAudioMode = true
                    ..audioVideoView.showMicrophoneStateOnView = true,
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
  String? selectedBackgroundImage;
  String? selectedMusic;
  final _audioPlayer = AudioPlayer();
  bool isPlaying = false;

  Language selectedLanguage = languages[0];

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
    setState(() {
      backgroundImages = images;
      musicList = music;
    });
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
                          children: languages.map((lang) {
                            final isSelected = selectedLanguage.code == lang.code;
                            return GestureDetector(
                              onTap: () {
                                setState(() => selectedLanguage = lang);
                              },
                              child: Container(
                                margin: const EdgeInsets.only(right: 12),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected ? lang.backgroundColor : Colors.grey[900],
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected ? Colors.white : Colors.grey,
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

                // Hashtags
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select Hashtag',
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
                              hashtags.map((tag) {
                                bool isSelected = selectedHashtag == tag;
                                return GestureDetector(
                                  onTap: () {
                                    setState(() => selectedHashtag = tag);
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.only(right: 12),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
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
                                          isSelected
                                              ? null
                                              : Colors.transparent,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color:
                                            isSelected
                                                ? Color(0xFFffa030)
                                                : Colors.grey,
                                      ),
                                    ),
                                    child: Text(
                                      tag,
                                      style: TextStyle(
                                        color:
                                            isSelected
                                                ? Colors.black
                                                : Colors.white,
                                        fontWeight: FontWeight.w500,
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

  void _goLive(BuildContext context) async {
    try {
      // Generate a unique live URL using timestamp and random string
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final liveUrl =
          'live_${timestamp}_${nameController.text.isNotEmpty ? nameController.text.toLowerCase().replaceAll(' ', '_') : 'host'}';

      // Fetch user type
      String liveType = categories.firstWhere((cat) => cat.name == selectedCategory, orElse: () => categories[0]).type;
      final userId = ApiService.currentUserId;
      if (userId != null) {
        final userTypes = await ApiService.getUserTypes();
        final userTypeEntry = userTypes.firstWhere(
          (e) => e['user_id'] == userId,
          orElse: () => null,
        );
        final userType = userTypeEntry != null ? userTypeEntry['type'] : null;
        if (userType == 'premium' || userType == 'super') {
          liveType = userType;
        }
      }

      // Prepare the base data
      Map<String, dynamic> data;

      if (isVideoMode) {
        data = {
          'category': selectedCategory,
          'hashtag': [selectedHashtag],
          'live_url': liveUrl,
          'language': selectedLanguage.code,
          'types': liveType,
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
          'types': liveType,
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

        // Create the appropriate configuration
        late final ZegoUIKitPrebuiltLiveStreamingConfig config;

        if (isVideoMode) {
          config =
              ZegoUIKitPrebuiltLiveStreamingConfig.host()
                ..turnOnCameraWhenJoining = videoOn
                ..turnOnMicrophoneWhenJoining = true
                ..useSpeakerWhenJoining = true
                ..topMenuBar.buttons = [
                  ZegoLiveStreamingMenuBarButtonName.minimizingButton,
                  ZegoLiveStreamingMenuBarButtonName.switchCameraButton,
                ]
                ..bottomMenuBar.hostButtons = [
                  ZegoLiveStreamingMenuBarButtonName.toggleCameraButton,
                  ZegoLiveStreamingMenuBarButtonName.toggleMicrophoneButton,
                  ZegoLiveStreamingMenuBarButtonName.leaveButton,
                  ZegoLiveStreamingMenuBarButtonName.switchAudioOutputButton,
                  ZegoLiveStreamingMenuBarButtonName.chatButton,
                ]
                ..audioVideoView.showAvatarInAudioMode = true
                ..audioVideoView.showSoundWavesInAudioMode = true
                ..audioVideoView.showMicrophoneStateOnView = true;
        } else {
          config =
              ZegoUIKitPrebuiltLiveStreamingConfig.host()
                ..turnOnCameraWhenJoining = false
                ..turnOnMicrophoneWhenJoining = true
                ..useSpeakerWhenJoining = true
                ..topMenuBar.buttons = [
                  ZegoLiveStreamingMenuBarButtonName.minimizingButton,
                ]
                ..bottomMenuBar.hostButtons = [
                  ZegoLiveStreamingMenuBarButtonName.toggleMicrophoneButton,
                  ZegoLiveStreamingMenuBarButtonName.leaveButton,
                  ZegoLiveStreamingMenuBarButtonName.switchAudioOutputButton,
                  ZegoLiveStreamingMenuBarButtonName.chatButton,
                ]
                ..audioVideoView.showAvatarInAudioMode = true
                ..audioVideoView.showSoundWavesInAudioMode = true
                ..audioVideoView.showMicrophoneStateOnView = true;
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
}