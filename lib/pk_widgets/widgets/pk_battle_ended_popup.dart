import 'package:flutter/material.dart';
import 'dart:ui';

class PKBattleEndedPopup extends StatefulWidget {
  final int winnerId;
  final int leftScore;
  final int rightScore;
  final String? leftHostName;
  final String? rightHostName;
  final String? leftHostId;
  final String? rightHostId;
  final VoidCallback? onDismiss;

  const PKBattleEndedPopup({
    Key? key,
    required this.winnerId,
    required this.leftScore,
    required this.rightScore,
    this.leftHostName,
    this.rightHostName,
    this.leftHostId,
    this.rightHostId,
    this.onDismiss,
  }) : super(key: key);

  @override
  State<PKBattleEndedPopup> createState() => _PKBattleEndedPopupState();
}

class _PKBattleEndedPopupState extends State<PKBattleEndedPopup>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _confettiController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _confettiController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<double>(
      begin: 50.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    _animationController.forward();
    _confettiController.repeat();

    // Auto dismiss after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  void _dismiss() {
    _animationController.reverse().then((_) {
      if (widget.onDismiss != null) {
        widget.onDismiss!();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  String _getWinnerName() {
    if (widget.winnerId == 0) return 'Draw';
    
    final isLeftWinner = widget.winnerId.toString() == widget.leftHostId;
    return isLeftWinner 
        ? (widget.leftHostName ?? widget.leftHostId ?? 'Left Host')
        : (widget.rightHostName ?? widget.rightHostId ?? 'Right Host');
  }

  Color _getWinnerColor() {
    if (widget.winnerId == 0) return Colors.grey;
    
    final isLeftWinner = widget.winnerId.toString() == widget.leftHostId;
    return isLeftWinner ? const Color(0xFF00d4ff) : const Color(0xFFff69b4);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 8 * _fadeAnimation.value,
            sigmaY: 8 * _fadeAnimation.value,
          ),
          child: Container(
            color: Colors.black.withOpacity(0.6 * _fadeAnimation.value),
            child: Center(
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Transform.translate(
                  offset: Offset(0, _slideAnimation.value),
                  child: Container(
                    margin: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF1a1a2e),
                          const Color(0xFF16213e),
                          const Color(0xFF0f3460),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: _getWinnerColor().withOpacity(0.3),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _getWinnerColor().withOpacity(0.2),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 30,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header with confetti effect
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _getWinnerColor().withOpacity(0.2),
                                _getWinnerColor().withOpacity(0.1),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(24),
                              topRight: Radius.circular(24),
                            ),
                          ),
                          child: Column(
                            children: [
                              // Trophy icon
                              AnimatedBuilder(
                                animation: _confettiController,
                                builder: (context, child) {
                                  return Transform.rotate(
                                    angle: _confettiController.value * 0.1,
                                    child: Icon(
                                      widget.winnerId == 0 
                                          ? Icons.emoji_events 
                                          : Icons.emoji_events,
                                      size: 48,
                                      color: _getWinnerColor(),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'PK Battle Ended!',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      color: _getWinnerColor().withOpacity(0.5),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Content
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              // Winner announcement
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      _getWinnerColor().withOpacity(0.3),
                                      _getWinnerColor().withOpacity(0.1),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: _getWinnerColor().withOpacity(0.5),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      widget.winnerId == 0 
                                          ? Icons.handshake 
                                          : Icons.star,
                                      color: _getWinnerColor(),
                                      size: 24,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Winner: ${_getWinnerName()}',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              const SizedBox(height: 24),
                              
                              // Final scores
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.1),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      'Final Scores',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white70,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      children: [
                                        // Left host score
                                        Column(
                                          children: [
                                            CircleAvatar(
                                              radius: 30,
                                              backgroundColor: const Color(0xFF00d4ff).withOpacity(0.2),
                                              child: Text(
                                                '${widget.leftScore}',
                                                style: const TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF00d4ff),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              widget.leftHostName ?? widget.leftHostId ?? 'Left',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.white70,
                                              ),
                                            ),
                                          ],
                                        ),
                                        
                                        // VS indicator
                                        Column(
                                          children: [
                                            Container(
                                              width: 40,
                                              height: 40,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                gradient: LinearGradient(
                                                  colors: [
                                                    const Color(0xFFffd700),
                                                    const Color(0xFF9d4edd),
                                                  ],
                                                ),
                                              ),
                                                                                             child: const Icon(
                                                 Icons.sports_martial_arts,
                                                 color: Colors.white,
                                                 size: 20,
                                               ),
                                            ),
                                            const SizedBox(height: 8),
                                            const Text(
                                              'VS',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.white54,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                        
                                        // Right host score
                                        Column(
                                          children: [
                                            CircleAvatar(
                                              radius: 30,
                                              backgroundColor: const Color(0xFFff69b4).withOpacity(0.2),
                                              child: Text(
                                                '${widget.rightScore}',
                                                style: const TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFFff69b4),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              widget.rightHostName ?? widget.rightHostId ?? 'Right',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.white70,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Action buttons
                        Container(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                          child: Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _dismiss,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _getWinnerColor(),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 8,
                                    shadowColor: _getWinnerColor().withOpacity(0.3),
                                  ),
                                  child: const Text(
                                    'Continue',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
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
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
