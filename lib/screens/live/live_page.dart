import 'package:flutter/material.dart';
import 'package:finalchat/pk_widgets/config.dart';
import 'package:zego_uikit_prebuilt_live_streaming/zego_uikit_prebuilt_live_streaming.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';
import 'package:finalchat/common.dart';
import 'package:finalchat/constants.dart';
import 'package:finalchat/pk_widgets/events.dart';
import 'package:finalchat/pk_widgets/widgets/mute_button.dart';
import 'package:finalchat/pk_widgets/surface.dart';
import 'dart:math';
import 'package:finalchat/screens/main/store_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:zego_uikit/zego_uikit.dart';
import 'dart:convert';
import 'package:finalchat/services/api_service.dart';
import 'package:finalchat/screens/live/gift_animation.dart';
import 'dart:async';

class LivePage extends StatefulWidget {
  final String liveID;
  final String localUserID;
  final bool isHost;
  final String? profilePic;
  final int receiverId; // <-- add this
  final VoidCallback? onGiftButtonPressed;

  const LivePage({
    Key? key,
    required this.liveID,
    required this.localUserID,
    required this.receiverId, // <-- add this
    this.isHost = false,
    this.profilePic,
    this.onGiftButtonPressed,
  }) : super(key: key);

  @override
  State<LivePage> createState() => _LivePageState();
}

// class AutoProgressBar extends StatefulWidget {
//   final Duration duration;
//   final VoidCallback? onCompleted; // optional callback when done

//   const AutoProgressBar({
//     Key? key,
//     this.duration = const Duration(seconds: 5),
//     this.onCompleted,
//   }) : super(key: key);

//   @override
//   State<AutoProgressBar> createState() => _AutoProgressBarState();
// }

// class _AutoProgressBarState extends State<AutoProgressBar>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _controller;

//   @override
//   void initState() {
//     super.initState();
//     _controller = AnimationController(
//       vsync: this,
//       duration: widget.duration,
//     )..forward(); // Start animation automatically

//     _controller.addStatusListener((status) {
//       if (status == AnimationStatus.completed) {
//         widget.onCompleted?.call(); // Call when done
//       }
//     });
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return SizedBox(
//       height: 8,
//       child: AnimatedBuilder(
//         animation: _controller,
//         builder: (context, child) {
//           return LinearProgressIndicator(
//             value: _controller.value,
//             backgroundColor: Colors.grey.shade300,
//             valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
//           );
//         },
//       ),
//     );
//   }
// }


class _LivePageState extends State<LivePage>
    with SingleTickerProviderStateMixin {
  final liveStateNotifier = ValueNotifier<ZegoLiveStreamingState>(
    ZegoLiveStreamingState.idle,
  );

  final requestingHostsMapRequestIDNotifier =
      ValueNotifier<Map<String, List<String>>>({});
  final requestIDNotifier = ValueNotifier<String>('');
  PKEvents? pkEvents;

  // PK battle state
  int? pkBattleId; // Set this when PK battle starts or is joined
  int leftScore = 0;
  int rightScore = 0;
  bool isLoadingPK = false;

  // Like animation state
  late AnimationController _likeController;
  late Animation<double> _likeScale;
  bool _showLike = false;
  List<Widget> _burstHearts = [];
  int _burstKey = 0;

  List<dynamic> _gifts = [];
  bool _giftsLoading = true;
  Map<String, dynamic>? _currentUser;
  bool _sendingGift = false;
  List<Widget> _activeGiftAnimations = [];
  int _giftAnimKey = 0;
  bool isLiveStarted = false; // <-- Add this state variable
  Timer? _pkBattleTimer;
  final TextEditingController _pkBattleIdController = TextEditingController();

  @override
  void initState() {
    super.initState();

    pkEvents = PKEvents(
      requestIDNotifier: requestIDNotifier,
      requestingHostsMapRequestIDNotifier: requestingHostsMapRequestIDNotifier,
    );

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
    if (pkBattleId != null) {
      fetchPKBattleState();
      _pkBattleTimer = Timer.periodic(Duration(seconds: 1), (timer) {
        print('Timer tick: fetching PK battle state');
        fetchPKBattleState();
      });
    }
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
        _currentUser = user;
        _giftsLoading = false;
      });
    } catch (e) {
      setState(() {
        _giftsLoading = false;
      });
    }
  }

  Future<void> _sendGiftFromList(dynamic gift) async {
    if (_sendingGift) return;
    if (_currentUser == null) return;
    if (_currentUser!['diamonds'] < gift['diamond_amount']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Not enough diamonds!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() {
      _sendingGift = true;
      _currentUser!['diamonds'] -= gift['diamond_amount'];
    });
    try {
      bool pkGiftSent = false;
      // If PK battle is active, send PK battle gift
      if (pkBattleId != null) {
        final result = await ApiService.sendPKBattleGift(
          pkBattleId: pkBattleId!,
          senderId: _currentUser!['id'],
          receiverId: widget.receiverId,
          giftId: gift['id'],
          amount: gift['diamond_amount'],
        );
        if (result.containsKey('left_score') && result.containsKey('right_score')) {
          setState(() {
            leftScore = result['left_score'] ?? 0;
            rightScore = result['right_score'] ?? 0;
          });
        }
        pkGiftSent = true;
      }
      if (!pkGiftSent) {
        final success = await ApiService.sendGift(
          receiverId: widget.receiverId, // <-- use this!
          giftId: gift['id'],
          liveStreamId: int.tryParse(widget.liveID) ?? 0,
          liveStreamType: widget.isHost ? 'host' : 'audience',
        );
        if (!success) throw Exception('Gift send failed');
      }
      // Send ZEGOCLOUD in-room command for gift notification
      final message = jsonEncode({
        "type": "gift",
        "sender_id": _currentUser?['id'],
        "sender_name": _currentUser?['first_name'] ?? 'User',
        "gift_id": gift['id'],
        "gift_name": gift['name'],
        "gift_amount": gift['diamond_amount'],
        "gif_filename": gift['gif_filename'],
        "timestamp": DateTime.now().millisecondsSinceEpoch,
      });
      await ZegoUIKit().sendInRoomCommand(widget.liveID, [message]);
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${gift['name']} sent successfully!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      // Trigger gift animation (same as gift panel)
      final gifUrl =
          'https://server.bharathchat.com/uploads/gifts/' +
          gift['gif_filename'];
      final senderName = _currentUser?['first_name'] ?? 'User';
      setState(() {
        _activeGiftAnimations.add(
          GiftAnimation(
            key: ValueKey('gift_anim_${_giftAnimKey++}'),
            giftName: gift['name'],
            gifUrl: gifUrl,
            senderName: senderName,
            onAnimationComplete: () {
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
      // Optionally: refresh user data
      setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending gift: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      setState(() {
        _sendingGift = false;
      });
    }
  }

  // Call this method from parent when live is started
  void startLive() {
    setState(() {
      isLiveStarted = true;
    });
  }

  Future<void> fetchPKBattleState() async {
    if (pkBattleId == null) {
      print('PK Battle ID is null, not fetching state');
      return;
    }
    print('Fetching PK battle state for id: $pkBattleId');
    setState(() { isLoadingPK = true; });
    final data = await ApiService.getPKBattleById(pkBattleId!);
    print('API response: $data');
    if (data != null) {
      setState(() {
        leftScore = data['left_score'] ?? 0;
        rightScore = data['right_score'] ?? 0;
        isLoadingPK = false;
      });
      print('Scores updated: leftScore=$leftScore, rightScore=$rightScore');
    } else {
      setState(() { isLoadingPK = false; });
      print('Failed to fetch PK battle state for id: $pkBattleId');
    }
  }

  @override
  void dispose() {
    _pkBattleTimer?.cancel();
    _likeController.dispose();
    _pkBattleIdController.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    final config =
        (widget.isHost
            ? (ZegoUIKitPrebuiltLiveStreamingConfig.host(
                plugins: [ZegoUIKitSignalingPlugin()],
              )
              ..foreground = PKV2Surface(
                requestIDNotifier: requestIDNotifier,
                liveStateNotifier: liveStateNotifier,
                requestingHostsMapRequestIDNotifier:
                    requestingHostsMapRequestIDNotifier,
              ))
            : ZegoUIKitPrebuiltLiveStreamingConfig.audience(
              plugins: [ZegoUIKitSignalingPlugin()],
            ));

    config.avatarBuilder =
        (context, size, user, extraInfo) => customAvatarBuilder(
          context,
          size,
          user,
          extraInfo,
          profilePic: widget.profilePic,
        );
    config.audioVideoView.foregroundBuilder = foregroundBuilder;
    // If pkBattle is not a valid property, comment or remove the next line
    // config.pkBattle = pkConfig();
    config.topMenuBar.buttons = [
      ZegoLiveStreamingMenuBarButtonName.minimizingButton,
    ];

    // Add virtual gift, like, and diamond buttons for both host and audience
    final double buttonSize = 38; // Reduced size for all three
    // Gradient for circular buttons
    final Gradient buttonGradient = const SweepGradient(
      colors: [
        Color(0xFFffa030),
        Color(0xFFfe9b00),
        Color(0xFFf67d00),
        Color(0xFFffa030), // To complete the sweep
      ],
      startAngle: 0.0,
      endAngle: 3.14 * 2,
      center: Alignment.center,
    );
    final giftButton = ZegoMenuBarExtendButton(
      index: 0,
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
            if (widget.onGiftButtonPressed != null) {
              widget.onGiftButtonPressed!();
            } else {
              print('Gift button pressed');
            }
          },
          child: const Icon(Icons.card_giftcard, color: Colors.white, size: 22),
        ),
      ),
    );

    final likeButton = ZegoMenuBarExtendButton(
      index: 1,
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
    );

    final diamondButton = ZegoMenuBarExtendButton(
      index: 2,
      child: GestureDetector(
        onTap: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (context) => const StoreScreen()));
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
    );

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

    return SafeArea(
      child: Scaffold(
        body: Stack(
          children: [
            ZegoUIKitPrebuiltLiveStreaming(
              appID: 615877954, // input your AppID
              appSign:
                  '12e07321bd8231dda371ea9235e274178403bd97a7ccabcb09e22474c42da3a4',
              userID: widget.localUserID,
              userName: 'user_${widget.localUserID}',
              liveID: widget.liveID,
              config: config,
              events: ZegoUIKitPrebuiltLiveStreamingEvents(
                pk: pkEvents?.event,
                onStateUpdated: (state) {
                  liveStateNotifier.value = state;
                },
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
            // Add this new widget to display the PK battle status
            Positioned(
              left: 0,
              right: 0,
              bottom: 260,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Left: '
                            ' $leftScore',
                            style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                        Text('Right: '
                            ' $rightScore',
                            style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: Icon(Icons.refresh),
                          onPressed: fetchPKBattleState,
                          tooltip: 'Refresh PK Battle',
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: (leftScore + rightScore) > 0
                          ? leftScore / (leftScore + rightScore)
                          : 0.5,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                      minHeight: 10,
                    ),
                  ],
                ),
              ),
            ),
            // in all case display with 1 second update here 

            // Horizontal gift list above the bottom buttons
            if (!_giftsLoading && _gifts.isNotEmpty && isLiveStarted)
              Positioned(
                left: 0,
                right: 0,
                bottom: 60,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (pkBattleId != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Left: $leftScore', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                                Text('Right: $rightScore', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            SizedBox(height: 4),
                            LinearProgressIndicator(
                              value: (leftScore + rightScore) > 0
                                  ? leftScore / (leftScore + rightScore)
                                  : 0.5,
                              backgroundColor: Colors.grey[300],
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                              minHeight: 10,
                            ),
                          ],
                        ),
                      ),
                    SizedBox(
                      height: 56, // keep height
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: _gifts.length,
                        separatorBuilder:
                            (context, idx) => const SizedBox(width: 12),
                        itemBuilder: (context, idx) {
                          final gift = _gifts[idx];
                          final canAfford =
                              _currentUser != null &&
                              _currentUser!['diamonds'] >= gift['diamond_amount'];
                          return GestureDetector(
                            onTap:
                                canAfford && !_sendingGift
                                    ? () => _sendGiftFromList(gift)
                                    : null,
                            child: Opacity(
                              opacity: canAfford ? 1.0 : 0.5,
                              child: Container(
                                width: 48,
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.all(4),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: CachedNetworkImage(
                                        imageUrl: 'https://server.bharathchat.com/uploads/gifts/' +
                                            gift['gif_filename'],
                                        width: 28,
                                        height: 28,
                                        fit: BoxFit.cover,
                                        placeholder:
                                            (context, url) => Container(
                                              color: Colors.grey[700],
                                              child: const Icon(
                                                Icons.card_giftcard,
                                                color: Colors.white,
                                                size: 16,
                                              ),
                                            ),
                                        errorWidget:
                                            (context, url, error) => Container(
                                              color: Colors.grey[700],
                                              child: const Icon(
                                                Icons.card_giftcard,
                                                color: Colors.white,
                                                size: 16,
                                              ),
                                            ),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Image.asset(
                                          'assets/diamond.png',
                                          width: 12,
                                          height: 12,
                                        ),
                                        const SizedBox(width: 2),
                                        Text(
                                          '${gift['diamond_amount']}',
                                          style: TextStyle(
                                            color: canAfford ? Colors.orange : Colors.grey[500],
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            // Overlay active gift animations
            ..._activeGiftAnimations,
            // Watermark logo in top left, even further below, with transparent gradient text
            Positioned(
              top: 100,
              left: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Opacity(
                    opacity: 0.5,
                    child: Container(
                      margin: const EdgeInsets.only(
                        left: 28,
                      ), // move logo further right
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
                          color:
                              Colors.white, // This will be replaced by gradient
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Manual test UI for pkBattleId
            Positioned(
              top: 100,
              right: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _pkBattleIdController,
                          decoration: InputDecoration(
                            labelText: 'PK Battle ID',
                            hintText: 'Enter PK Battle ID',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          final id = int.tryParse(_pkBattleIdController.text);
                          if (id != null) {
                            setState(() {
                              pkBattleId = id;
                              leftScore = 0;
                              rightScore = 0;
                            });
                            fetchPKBattleState();
                            _pkBattleTimer?.cancel();
                            _pkBattleTimer = Timer.periodic(Duration(seconds: 1), (timer) {
                              print('Timer tick: fetching PK battle state');
                              fetchPKBattleState();
                            });
                          }
                        },
                        child: Text('Set PK Battle ID'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget foregroundBuilder(context, size, ZegoUIKitUser? user, _) {
    if (user == null) {
      return Container();
    }

    final hostWidgets = [
      Positioned(
        top: 5,
        left: 5,
        child: SizedBox(
          width: 40,
          height: 40,
          child: PKMuteButton(userID: user.id),
        ),
      ),
    ];

    return Stack(
      children: [
        ...((widget.isHost && user.id != widget.localUserID)
            ? hostWidgets
            : []),
        Positioned(
          top: 5,
          right: 35,
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircleAvatar(
              backgroundColor: Colors.purple.withOpacity(0.6),
              child: Icon(
                user.camera.value ? Icons.videocam : Icons.videocam_off,
                color: Colors.white,
                size: 15,
              ),
            ),
          ),
        ),
        Positioned(
          top: 5,
          right: 5,
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircleAvatar(
              backgroundColor: Colors.purple.withOpacity(0.6),
              child: Icon(
                user.microphone.value ? Icons.mic : Icons.mic_off,
                color: Colors.white,
                size: 15,
              ),
            ),
          ),
        ),
        Positioned(
          top: 25,
          right: 5,
          child: Container(
            height: 18,
            color: Colors.purple,
            child: Text(user.name),
          ),
        ),
      ],
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