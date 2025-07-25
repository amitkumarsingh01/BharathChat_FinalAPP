import 'package:flutter/material.dart';
import 'dart:async';

class PKProgressBar extends StatefulWidget {
  final String? leftHostId;
  final String? rightHostId;
  final String? leftHostName;
  final String? rightHostName;
  final int leftDiamonds;
  final int rightDiamonds;
  final int totalDiamonds;
  final int timeLeft;

  const PKProgressBar({
    Key? key,
    this.leftHostId,
    this.rightHostId,
    this.leftHostName,
    this.rightHostName,
    required this.leftDiamonds,
    required this.rightDiamonds,
    required this.totalDiamonds,
    required this.timeLeft,
  }) : super(key: key);

  @override
  State<PKProgressBar> createState() => _PKProgressBarState();
}

class _PKProgressBarState extends State<PKProgressBar>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late Animation<double> _leftProgressAnimation;
  late Animation<double> _rightProgressAnimation;

  @override
  void initState() {
    super.initState();

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _leftProgressAnimation = Tween<double>(
      begin: 0.0,
      end:
          widget.totalDiamonds > 0
              ? widget.leftDiamonds / widget.totalDiamonds
              : 0.0,
    ).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeOutCubic),
    );

    _rightProgressAnimation = Tween<double>(
      begin: 0.0,
      end:
          widget.totalDiamonds > 0
              ? widget.rightDiamonds / widget.totalDiamonds
              : 0.0,
    ).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeOutCubic),
    );

    _progressController.forward();

    // Start continuous animation for the center diamond
    _startContinuousAnimation();
  }

  void _startContinuousAnimation() {
    _progressController.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(PKProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.leftDiamonds != widget.leftDiamonds ||
        oldWidget.rightDiamonds != widget.rightDiamonds ||
        oldWidget.totalDiamonds != widget.totalDiamonds) {
      _updateProgressAnimations();
    }
  }

  void _updateProgressAnimations() {
    _leftProgressAnimation = Tween<double>(
      begin: _leftProgressAnimation.value,
      end:
          widget.totalDiamonds > 0
              ? widget.leftDiamonds / widget.totalDiamonds
              : 0.0,
    ).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeOutCubic),
    );

    _rightProgressAnimation = Tween<double>(
      begin: _rightProgressAnimation.value,
      end:
          widget.totalDiamonds > 0
              ? widget.rightDiamonds / widget.totalDiamonds
              : 0.0,
    ).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeOutCubic),
    );

    _progressController.reset();
    _progressController.forward();
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final leftPercentage =
        widget.totalDiamonds > 0 ? widget.leftDiamonds / widget.totalDiamonds : 0.0;
    final rightPercentage =
        widget.totalDiamonds > 0 ? widget.rightDiamonds / widget.totalDiamonds : 0.0;
    final maxBarWidth = MediaQuery.of(context).size.width * 0.4;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // Timer
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.timer, color: Colors.orange, size: 18),
              const SizedBox(width: 4),
              Text(
                _formatTime(widget.timeLeft),
                style: const TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Progress Bar
          Container(
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.black.withOpacity(0.6),
              border: Border.all(
                color: Colors.purple.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Stack(
              children: [
                // Left Progress (Blue)
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: maxBarWidth * leftPercentage,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        bottomLeft: Radius.circular(20),
                      ),
                      gradient: LinearGradient(
                        colors: [
                          Colors.blue.withOpacity(0.8),
                          Colors.lightBlue.withOpacity(0.9),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                  ),
                ),
                // Right Progress (Red)
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: maxBarWidth * rightPercentage,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                      gradient: LinearGradient(
                        colors: [
                          Colors.red.withOpacity(0.8),
                          Colors.pink.withOpacity(0.9),
                        ],
                        begin: Alignment.centerRight,
                        end: Alignment.centerLeft,
                      ),
                    ),
                  ),
                ),
                // Center diamond and scores
                Align(
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Left host name and score
                      if (widget.leftHostName != null)
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.blue,
                              child: Text(
                                widget.leftHostName!.substring(0, 1),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${widget.leftDiamonds}',
                              style: const TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(width: 16),
                      // Diamond icon
                      Image.asset(
                        'assets/diamond.png',
                        width: 28,
                        height: 28,
                      ),
                      const SizedBox(width: 16),
                      // Right host name and score
                      if (widget.rightHostName != null)
                        Row(
                          children: [
                            Text(
                              '${widget.rightDiamonds}',
                              style: const TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(width: 4),
                            CircleAvatar(
                              backgroundColor: Colors.red,
                              child: Text(
                                widget.rightHostName!.substring(0, 1),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final min = seconds ~/ 60;
    final sec = seconds % 60;
    return '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}' ;
  }
}
