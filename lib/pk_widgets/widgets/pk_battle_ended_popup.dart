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
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _pulseAnimation;

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

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _animationController.forward();
    _confettiController.repeat();
    _pulseController.repeat(reverse: true);

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
    _pulseController.dispose();
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
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: _getWinnerColor().withOpacity(0.4),
                        width: 2.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _getWinnerColor().withOpacity(0.3),
                          blurRadius: 25,
                          spreadRadius: 8,
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.6),
                          blurRadius: 40,
                          spreadRadius: 15,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Enhanced Header with confetti effect
                        Container(
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _getWinnerColor().withOpacity(0.25),
                                _getWinnerColor().withOpacity(0.1),
                                Colors.transparent,
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(28),
                              topRight: Radius.circular(28),
                            ),
                          ),
                          child: Column(
                            children: [
                              // Enhanced Trophy icon with pulse animation
                              AnimatedBuilder(
                                animation: Listenable.merge([
                                  _confettiController,
                                  _pulseController,
                                ]),
                                builder: (context, child) {
                                  return Transform.rotate(
                                    angle: _confettiController.value * 0.1,
                                    child: Transform.scale(
                                      scale: _pulseAnimation.value,
                                      child: Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: RadialGradient(
                                            colors: [
                                              _getWinnerColor().withOpacity(
                                                0.3,
                                              ),
                                              _getWinnerColor().withOpacity(
                                                0.1,
                                              ),
                                              Colors.transparent,
                                            ],
                                          ),
                                        ),
                                        child: Icon(
                                          widget.winnerId == 0
                                              ? Icons.emoji_events
                                              : Icons.emoji_events,
                                          size: 52,
                                          color: _getWinnerColor(),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'PK Battle Ended!',
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 1.2,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Enhanced Content
                        Padding(
                          padding: const EdgeInsets.all(28),
                          child: Column(
                            children: [
                              // Enhanced Winner announcement
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 16,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      _getWinnerColor().withOpacity(0.4),
                                      _getWinnerColor().withOpacity(0.15),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: _getWinnerColor().withOpacity(
                                            0.2,
                                          ),
                                        ),
                                        child: Icon(
                                          widget.winnerId == 0
                                              ? Icons.handshake
                                              : Icons.star,
                                          color: _getWinnerColor(),
                                          size: 26,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Winner: ${_getWinnerName()}',
                                        style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          letterSpacing: 0.5,
                                          decoration: TextDecoration.none,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 28),

                              // Enhanced Final scores
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.4),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      'Final Scores',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white70,
                                        letterSpacing: 0.5,
                                        decoration: TextDecoration.none,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        // Enhanced Left host score
                                        Column(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                gradient: RadialGradient(
                                                  colors: [
                                                    const Color(
                                                      0xFF00d4ff,
                                                    ).withOpacity(0.3),
                                                    const Color(
                                                      0xFF00d4ff,
                                                    ).withOpacity(0.1),
                                                  ],
                                                ),
                                              ),
                                              child: CircleAvatar(
                                                radius: 32,
                                                backgroundColor: const Color(
                                                  0xFF00d4ff,
                                                ).withOpacity(0.2),
                                                child: Text(
                                                  '${widget.leftScore}',
                                                  style: const TextStyle(
                                                    fontSize: 22,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF00d4ff),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 10),
                                            Text(
                                              widget.leftHostName ??
                                                  widget.leftHostId ??
                                                  'Left',
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: Colors.white70,
                                                fontWeight: FontWeight.w500,
                                                decoration: TextDecoration.none,
                                              ),
                                            ),
                                          ],
                                        ),

                                        // Enhanced VS indicator
                                        Column(
                                          children: [
                                            Container(
                                              width: 44,
                                              height: 44,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                gradient: LinearGradient(
                                                  colors: [
                                                    _getWinnerColor()
                                                        .withOpacity(0.8),
                                                    _getWinnerColor()
                                                        .withOpacity(0.4),
                                                  ],
                                                ),
                                              ),
                                              child: Icon(
                                                Icons.sports_martial_arts,
                                                color: Colors.white,
                                                size: 22,
                                              ),
                                            ),
                                            const SizedBox(height: 10),
                                            Text(
                                              'VS',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.white60,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 1,
                                                decoration: TextDecoration.none,
                                              ),
                                            ),
                                          ],
                                        ),

                                        // Enhanced Right host score
                                        Column(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                gradient: RadialGradient(
                                                  colors: [
                                                    const Color(
                                                      0xFFff69b4,
                                                    ).withOpacity(0.3),
                                                    const Color(
                                                      0xFFff69b4,
                                                    ).withOpacity(0.1),
                                                  ],
                                                ),
                                              ),
                                              child: CircleAvatar(
                                                radius: 32,
                                                backgroundColor: const Color(
                                                  0xFFff69b4,
                                                ).withOpacity(0.2),
                                                child: Text(
                                                  '${widget.rightScore}',
                                                  style: const TextStyle(
                                                    fontSize: 22,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFFff69b4),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 10),
                                            Text(
                                              widget.rightHostName ??
                                                  widget.rightHostId ??
                                                  'Right',
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: Colors.white70,
                                                fontWeight: FontWeight.w500,
                                                decoration: TextDecoration.none,
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

                        // Enhanced Action buttons
                        Container(
                          padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
                          child: Row(
                            children: [
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    gradient: LinearGradient(
                                      colors: [
                                        _getWinnerColor(),
                                        _getWinnerColor().withOpacity(0.8),
                                      ],
                                    ),
                                  ),
                                  child: ElevatedButton(
                                    onPressed: _dismiss,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 18,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      elevation: 0,
                                      shadowColor: Colors.transparent,
                                    ),
                                    child: const Text(
                                      'Continue',
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                        decoration: TextDecoration.none,
                                      ),
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
