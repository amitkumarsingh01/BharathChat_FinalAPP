import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class GiftAnimation extends StatefulWidget {
  final String giftName;
  final String gifUrl;
  final String senderName;
  final VoidCallback? onAnimationComplete;

  const GiftAnimation({
    Key? key,
    required this.giftName,
    required this.gifUrl,
    required this.senderName,
    this.onAnimationComplete,
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned.fill(
          child: Container(
            color: Colors.black.withOpacity(0.3 * _opacityAnimation.value),
            child: Center(
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.8),
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
                              placeholder:
                                  (context, url) => Container(
                                    color: Colors.grey[800],
                                    child: const Icon(
                                      Icons.card_giftcard,
                                      color: Colors.white,
                                      size: 60,
                                    ),
                                  ),
                              errorWidget:
                                  (context, url, error) => Container(
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

                        const SizedBox(height: 16),

                        // Celebration emoji
                        const Text('🎉', style: TextStyle(fontSize: 40)),
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
