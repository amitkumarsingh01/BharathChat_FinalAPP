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
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _fetchScore();
    // Update more frequently during PK battles to show gift scores immediately
    _timer = Timer.periodic(const Duration(milliseconds: 500), (_) => _fetchScore());
    
    // Setup pulse animation for the central gem
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.repeat(reverse: true);
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = leftScore + rightScore;
    final leftPercent = total == 0 ? 0.5 : leftScore / total;
    final rightPercent = total == 0 ? 0.5 : rightScore / total;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a2e).withOpacity(0.95),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: const Color(0xFFffa030).withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Host names row
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.leftHostName ?? 'Left',
                  textAlign: TextAlign.left,
                  style: const TextStyle(
                    color: Colors.cyan,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    shadows: [
                      Shadow(
                        color: Colors.cyan,
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  widget.rightHostName ?? 'Right',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: Colors.pink,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    shadows: [
                      Shadow(
                        color: Colors.pink,
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Main progress bar
          SizedBox(
            height: 40,
            child: Stack(
              children: [
                // Background bar
                Container(
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: const Color(0xFF2a2a3e),
                  ),
                ),
                // Progress bars
                Row(
                  children: [
                    // Left side (Blue/Cyan)
                    Expanded(
                      flex: (leftPercent * 1000).toInt(),
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            bottomLeft: Radius.circular(20),
                          ),
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF00b4d8),
                              Color(0xFF0096c7),
                              Color(0xFF0077b6),
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(20),
                              bottomLeft: Radius.circular(20),
                            ),
                            gradient: LinearGradient(
                              colors: [
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
                    // Right side (Pink/Magenta)
                    Expanded(
                      flex: (rightPercent * 1000).toInt(),
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(20),
                            bottomRight: Radius.circular(20),
                          ),
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFff69b4),
                              Color(0xFFff1493),
                              Color(0xFFc71585),
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(20),
                              bottomRight: Radius.circular(20),
                            ),
                            gradient: LinearGradient(
                              colors: [
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
                // Central gem
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
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF9d4edd),
                                  Color(0xFF7b2cbf),
                                  Color(0xFF5a189a),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF9d4edd).withOpacity(0.6),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.diamond,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                // Sword icons
                Positioned(
                  left: 8,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF00b4d8),
                            Color(0xFF0096c7),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00b4d8).withOpacity(0.5),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.pentagon_sharp,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 8,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFff69b4),
                            Color(0xFFff1493),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFff69b4).withOpacity(0.5),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.pentagon_sharp,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
                // Score text overlay
                Positioned.fill(
                  child: Row(
                    children: [
                      Expanded(
                        child: Center(
                          child: Text(
                            leftScore.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              shadows: [
                                Shadow(
                                  color: Colors.black,
                                  blurRadius: 2,
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
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              shadows: [
                                Shadow(
                                  color: Colors.black,
                                  blurRadius: 2,
                                ),
                              ],
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
          const SizedBox(height: 4),
          // Total score
          Text(
            'Total: ${leftScore + rightScore}',
            style: const TextStyle(
              color: Color(0xFFffa030),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
} 