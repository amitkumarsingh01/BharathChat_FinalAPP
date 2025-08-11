import 'dart:async';
import 'package:flutter/material.dart';
import 'package:finalchat/services/api_service.dart';

class PKBattleProgressBar extends StatefulWidget {
  final int pkBattleId;
  final String? leftHostName;
  final String? rightHostName;
  final VoidCallback? onScoreUpdate;

  const PKBattleProgressBar({
    Key? key,
    required this.pkBattleId,
    this.leftHostName,
    this.rightHostName,
    this.onScoreUpdate,
  }) : super(key: key);

  @override
  State<PKBattleProgressBar> createState() => _PKBattleProgressBarState();
}

class _PKBattleProgressBarState extends State<PKBattleProgressBar>
    with TickerProviderStateMixin {
  int leftScore = 0;
  int rightScore = 0;
  Timer? _timer;
  late AnimationController _animationController;
  late AnimationController _scoreAnimationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scoreAnimation;
  Animation<double>? _glowAnimation;

  @override
  void initState() {
    super.initState();
    _fetchScore();
    // Update more frequently during PK battles to show gift scores immediately
    _timer = Timer.periodic(const Duration(milliseconds: 500), (_) => _fetchScore());
    
    // Setup pulse animation for the central gem
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.repeat(reverse: true);

    // Setup score animation
    _scoreAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scoreAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scoreAnimationController, curve: Curves.elasticOut),
    );

    // Setup glow animation - must be after _animationController is initialized
    _glowAnimation = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  Future<void> _fetchScore() async {
    final result = await ApiService.getPKBattleById(widget.pkBattleId);
    if (result != null && mounted) {
      final newLeftScore = result['left_score'] ?? 0;
      final newRightScore = result['right_score'] ?? 0;
      
      // Check if scores changed
      if (newLeftScore != leftScore || newRightScore != rightScore) {
        debugPrint('🎯 === PK BATTLE SCORE UPDATE ===');
        debugPrint('🎯 PK Battle ID: ${widget.pkBattleId}');
        debugPrint('🎯 Left Host: ${widget.leftHostName} - Score: $leftScore → $newLeftScore');
        debugPrint('🎯 Right Host: ${widget.rightHostName} - Score: $rightScore → $newRightScore');
        debugPrint('🎯 Total Score: ${leftScore + rightScore} → ${newLeftScore + newRightScore}');
        
        setState(() {
          leftScore = newLeftScore;
          rightScore = newRightScore;
        });
        
        // Trigger score animation
        _scoreAnimationController.forward(from: 0.0);
        
        // Notify parent about score update
        if (widget.onScoreUpdate != null) {
          widget.onScoreUpdate!();
        }
        
        debugPrint('🎯 PK Battle Scores Updated - Left: $leftScore, Right: $rightScore');
      }
    } else {
      debugPrint('❌ Failed to fetch PK battle scores for ID: ${widget.pkBattleId}');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    _scoreAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = leftScore + rightScore;
    final leftPercent = total == 0 ? 0.5 : leftScore / total;
    final rightPercent = total == 0 ? 0.5 : rightScore / total;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0),
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 16),
                    decoration: BoxDecoration(
         color: Colors.transparent,
         borderRadius: BorderRadius.circular(0),
       ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Main progress bar
          SizedBox(
            height: 48,
            child: Stack(
              children: [
                                 // Background bar with enhanced styling
                 Container(
                   height: 48,
                   decoration: BoxDecoration(
                     borderRadius: BorderRadius.circular(0),
                     color: Colors.transparent,
                   ),
                 ),
                // Progress bars with enhanced gradients
                Row(
                  children: [
                    // Left side (Enhanced Blue/Cyan)
                    Expanded(
                      flex: (leftPercent * 1000).toInt(),
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(0),
                            bottomLeft: Radius.circular(0),
                          ),
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF00d4ff),
                              const Color(0xFF00b4d8),
                              const Color(0xFF0096c7),
                              const Color(0xFF0077b6),
                              const Color(0xFF005f8a),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                                                     boxShadow: [
                             BoxShadow(
                               color: const Color(0xFF00b4d8).withOpacity(0.2),
                               blurRadius: 4,
                               spreadRadius: 1,
                             ),
                           ],
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(0),
                              bottomLeft: Radius.circular(0),
                            ),
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withOpacity(0.2),
                                Colors.white.withOpacity(0.1),
                                Colors.transparent,
                                Colors.white.withOpacity(0.05),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Right side (Enhanced Pink/Magenta)
                    Expanded(
                      flex: (rightPercent * 1000).toInt(),
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(0),
                            bottomRight: Radius.circular(0),
                          ),
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFFff8fab),
                              const Color(0xFFff69b4),
                              const Color(0xFFff1493),
                              const Color(0xFFc71585),
                              const Color(0xFFa01585),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                                                     boxShadow: [
                             BoxShadow(
                               color: const Color(0xFFff69b4).withOpacity(0.2),
                               blurRadius: 4,
                               spreadRadius: 1,
                             ),
                           ],
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(0),
                              bottomRight: Radius.circular(0),
                            ),
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withOpacity(0.2),
                                Colors.white.withOpacity(0.1),
                                Colors.transparent,
                                Colors.white.withOpacity(0.05),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                // Central gem with enhanced effects
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _pulseAnimation.value,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                                                           boxShadow: [
                               BoxShadow(
                                 color: const Color(0xFF9d4edd).withOpacity(0.3),
                                 blurRadius: 8,
                                 spreadRadius: 1,
                               ),
                             ],
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/diamond.png',
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        colors: [
                                          const Color(0xFFffd700),
                                          const Color(0xFF9d4edd),
                                          const Color(0xFF7b2cbf),
                                          const Color(0xFF5a189a),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.diamond,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                // Enhanced sword icons
                Positioned(
                  left: 10,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: _glowAnimation != null
                        ? AnimatedBuilder(
                            animation: _glowAnimation!,
                            builder: (context, child) {
                              return Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(0xFF00d4ff),
                                      const Color(0xFF00b4d8),
                                      const Color(0xFF0096c7),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                                                     boxShadow: [
                                     BoxShadow(
                                       color: const Color(0xFF00b4d8).withOpacity(_glowAnimation!.value * 0.3),
                                       blurRadius: 6,
                                       spreadRadius: 1,
                                     ),
                                   ],
                                ),
                                child: const Icon(
                                  Icons.pentagon_sharp,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              );
                            },
                          )
                        : Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF00d4ff),
                                  const Color(0xFF00b4d8),
                                  const Color(0xFF0096c7),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                                                               boxShadow: [
                                   BoxShadow(
                                     color: const Color(0xFF00b4d8).withOpacity(0.2),
                                     blurRadius: 6,
                                     spreadRadius: 1,
                                   ),
                                 ],
                            ),
                            child: const Icon(
                              Icons.pentagon_sharp,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                  ),
                ),
                Positioned(
                  right: 10,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: _glowAnimation != null
                        ? AnimatedBuilder(
                            animation: _glowAnimation!,
                            builder: (context, child) {
                              return Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(0xFFff8fab),
                                      const Color(0xFFff69b4),
                                      const Color(0xFFff1493),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                                                     boxShadow: [
                                     BoxShadow(
                                       color: const Color(0xFFff69b4).withOpacity(_glowAnimation!.value * 0.3),
                                       blurRadius: 6,
                                       spreadRadius: 1,
                                     ),
                                   ],
                                ),
                                child: const Icon(
                                  Icons.pentagon_sharp,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              );
                            },
                          )
                        : Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFFff8fab),
                                  const Color(0xFFff69b4),
                                  const Color(0xFFff1493),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                                                               boxShadow: [
                                   BoxShadow(
                                     color: const Color(0xFFff69b4).withOpacity(0.2),
                                     blurRadius: 6,
                                     spreadRadius: 1,
                                   ),
                                 ],
                            ),
                            child: const Icon(
                              Icons.pentagon_sharp,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                  ),
                ),
                // Enhanced score text overlay with animation
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _scoreAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: 0.8 + (_scoreAnimation.value * 0.2),
                        child: Row(
                          children: [
                            Expanded(
                              child: Center(
                                child: Text(
                                  leftScore.toString(),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 18,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withOpacity(0.8),
                                        blurRadius: 4,
                                        offset: const Offset(1, 1),
                                      ),
                                      Shadow(
                                        color: const Color(0xFF00b4d8).withOpacity(0.6),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Center(
                                child: Text(
                                  rightScore.toString(),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 18,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withOpacity(0.8),
                                        blurRadius: 4,
                                        offset: const Offset(1, 1),
                                      ),
                                      Shadow(
                                        color: const Color(0xFFff69b4).withOpacity(0.6),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
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