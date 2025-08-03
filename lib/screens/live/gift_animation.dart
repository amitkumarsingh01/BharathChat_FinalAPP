import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:audioplayers/audioplayers.dart';

class GiftAnimation extends StatefulWidget {
  final String giftName;
  final String gifUrl;
  final String senderName;
  final VoidCallback? onAnimationComplete;
  final bool isPKBattleGift;
  final String? pkBattleSide; // 'left' or 'right' for PK battle positioning

  const GiftAnimation({
    Key? key,
    required this.giftName,
    required this.gifUrl,
    required this.senderName,
    this.onAnimationComplete,
    this.isPKBattleGift = false,
    this.pkBattleSide, // New parameter for PK battle side
  }) : super(key: key);

  @override
  State<GiftAnimation> createState() => _GiftAnimationState();
}

class _GiftAnimationState extends State<GiftAnimation>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;
  late AudioPlayer _audioPlayer;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.3, curve: Curves.elasticOut),
      ),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    // Initialize audio player and play gift sound
    _audioPlayer = AudioPlayer();
    _playGiftSound();

    _controller.forward().then((_) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          _controller.reverse().then((_) {
            widget.onAnimationComplete?.call();
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playGiftSound() async {
    try {
      await _audioPlayer.play(AssetSource('gift_sound.mp3'));
    } catch (e) {
      print('Error playing gift sound: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned.fill(
          child: Container(
            color: Colors.transparent,
            child: Center(
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.transparent, width: 3),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Gift GIF
                        Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: CachedNetworkImage(
                              imageUrl: widget.gifUrl,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: Colors.grey[800],
                                child: const Icon(
                                  Icons.card_giftcard,
                                  color: Colors.white,
                                  size: 60,
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: Colors.grey[800],
                                child: const Icon(
                                  Icons.card_giftcard,
                                  color: Colors.white,
                                  size: 60,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Gift name
                        Text(
                          widget.giftName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 8),

                        // Sender name
                        Text(
                          'Sent by ${widget.senderName}',
                          style: TextStyle(
                            color: Colors.orange,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        // PK Battle indicator
                        if (widget.isPKBattleGift && widget.pkBattleSide != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: widget.pkBattleSide == 'left' 
                                  ? [Colors.green, Colors.lightGreen]
                                  : [Colors.orange, Colors.deepOrange],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              widget.pkBattleSide == 'left' 
                                ? '🟢 LEFT SIDE 🟢'
                                : '🟠 RIGHT SIDE 🟠',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],

                        // PK Battle indicator (general)
                        if (widget.isPKBattleGift && widget.pkBattleSide == null) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Colors.yellow, Colors.orange],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              '🎮 PK BATTLE GIFT 🎮',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],

                        // const SizedBox(height: 16),

                        // Celebration emoji
                        // const Text('🎉', style: TextStyle(fontSize: 40)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
