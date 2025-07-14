import 'package:flutter/material.dart';
import 'package:avatar_glow/avatar_glow.dart';
import '../../services/api_service.dart';
import 'dart:convert';
import 'package:carousel_slider/carousel_slider.dart';
import '../live/live_audio_screen.dart';
import '../auth/pending.dart';

class AudioChatScreen extends StatefulWidget {
  const AudioChatScreen({Key? key}) : super(key: key);

  @override
  State<AudioChatScreen> createState() => _AudioChatScreenState();
}

class _AudioChatScreenState extends State<AudioChatScreen> {
  List<dynamic> _audioRooms = [];
  bool _isLoading = true;
  bool _isMuted = false;
  Map<int, dynamic> _usersById = {};
  List<dynamic> _sliders = [];

  @override
  void initState() {
    super.initState();
    _checkUserActive();
    _loadAudioRooms();
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

  void _loadAudioRooms() async {
    try {
      final rooms = await ApiService.getAudioLives();
      final users = await ApiService.getUsers();
      final sliders = await ApiService.getSliders();
      setState(() {
        _audioRooms = rooms;
        _usersById = {for (var user in users) user['id']: user};
        _sliders = sliders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _createAudioRoom() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final titleController = TextEditingController();
        final roomController = TextEditingController();

        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text(
            'Create Audio Room',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Room Title',
                  hintStyle: const TextStyle(color: Colors.white54),
                  border: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.orange),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.orange),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: roomController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Room Name',
                  hintStyle: const TextStyle(color: Colors.white54),
                  border: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.orange),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.orange),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white54),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isNotEmpty &&
                    roomController.text.isNotEmpty) {
                  try {
                    await ApiService.createAudioLive({
                      'title': titleController.text,
                      'chat_room': roomController.text,
                      'live_url': 'demo-url',
                    });
                    Navigator.pop(context);
                    _loadAudioRooms();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Audio room created successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Failed to create room'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text(
                'Create',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF23272F),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Audio Chat',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Colors.orange),
              )
              : SingleChildScrollView(
                child: Column(
                  children: [
                    // Audio Controls
                    // Container(
                    //   padding: const EdgeInsets.all(16),
                    //   child: Row(
                    //     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    //     children: [
                    //       GestureDetector(
                    //         onTap: () {
                    //           setState(() {
                    //             _isMuted = !_isMuted;
                    //           });
                    //         },
                    //         child: CircleAvatar(
                    //           radius: 30,
                    //           backgroundColor: _isMuted ? Colors.red : Colors.orange,
                    //           child: Icon(
                    //             _isMuted ? Icons.mic_off : Icons.mic,
                    //             color: Colors.white,
                    //             size: 30,
                    //           ),
                    //         ),
                    //       ),
                    //       CircleAvatar(
                    //         radius: 30,
                    //         backgroundColor: Colors.grey[700],
                    //         child: const Icon(
                    //           Icons.headphones,
                    //           color: Colors.white,
                    //           size: 30,
                    //         ),
                    //       ),
                    //       CircleAvatar(
                    //         radius: 30,
                    //         backgroundColor: Colors.red,
                    //         child: const Icon(
                    //           Icons.call_end,
                    //           color: Colors.white,
                    //           size: 30,
                    //         ),
                    //       ),
                    //     ],
                    //   ),
                    // ),
                    const Divider(color: Colors.transparent),

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

                    // Audio Rooms List
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      itemCount: _audioRooms.length,
                      itemBuilder: (context, index) {
                        final room = _audioRooms.reversed.toList()[index];
                        final user = _usersById[room['user_id']];
                        final userName =
                            user != null
                                ? ((user['first_name'] ?? '') +
                                        ' ' +
                                        (user['last_name'] ?? ''))
                                    .trim()
                                : 'Host';
                        final profilePic =
                            user != null ? user['profile_pic'] : null;
                        final seats =
                            room['seats'] ?? 7; // fallback if not present
                        final listeners = room['viewers'] ?? 0;
                        return GestureDetector(
                          onTap: () async {
                            // Join audio room logic
                            final userData = await ApiService.getCurrentUser();
                            final userID =
                                userData != null
                                    ? (userData['username'] ??
                                        userData['id'].toString())
                                    : DateTime.now().millisecondsSinceEpoch
                                        .toString();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => LiveAudioScreen(
                                      liveID: room['live_url'] ?? '',
                                      localUserID: userID,
                                      isHost: false,
                                      hostId: room['user_id'] ?? 0,
                                      backgroundImage: room['background_img'],
                                      backgroundMusic: room['music'],
                                    ),
                              ),
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.grey[900],
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Profile image with LIVE badge
                                Stack(
                                  children: [
                                    Container(
                                      margin: const EdgeInsets.all(12),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(16),
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
                                                  width: 90,
                                                  height: 90,
                                                  fit: BoxFit.cover,
                                                )
                                                : Container(
                                                  width: 90,
                                                  height: 90,
                                                  color: Colors.black,
                                                  child: const Icon(
                                                    Icons.person,
                                                    color: Colors.white,
                                                    size: 50,
                                                  ),
                                                ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 20,
                                      left: 20,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.red,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
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
                                // Main info
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                      horizontal: 0,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          room['title'] ?? userName,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          room['chat_room'] ?? '',
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 14,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.graphic_eq,
                                              color: Colors.green,
                                              size: 18,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              listeners.toString(),
                                              style: const TextStyle(
                                                color: Colors.green,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                // Seats and Join button
                                Padding(
                                  padding: const EdgeInsets.only(right: 16),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.event_seat,
                                            color: Colors.white54,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '$seats Seats',
                                            style: const TextStyle(
                                              color: Colors.white54,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
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
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: ElevatedButton.icon(
                                          onPressed: () async {
                                            // Join audio room logic
                                            final userData =
                                                await ApiService.getCurrentUser();
                                            final userID =
                                                userData != null
                                                    ? (userData['username'] ??
                                                        userData['id']
                                                            .toString())
                                                    : DateTime.now()
                                                        .millisecondsSinceEpoch
                                                        .toString();
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder:
                                                    (
                                                      context,
                                                    ) => LiveAudioScreen(
                                                      liveID:
                                                          room['live_url'] ??
                                                          '',
                                                      localUserID: userID,
                                                      isHost: false,
                                                      hostId:
                                                          room['user_id'] ?? 0,
                                                      backgroundImage:
                                                          room['background_img'],
                                                      backgroundMusic:
                                                          room['music'],
                                                    ),
                                              ),
                                            );
                                          },
                                          icon: const Icon(
                                            Icons.headset_mic,
                                            color: Colors.black,
                                            size: 20,
                                          ),
                                          label: const Text(
                                            'Join',
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.transparent,
                                            shadowColor: Colors.transparent,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 18,
                                              vertical: 10,
                                            ),
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
                    ),
                  ],
                ),
              ),
    );
  }
}
