import 'package:flutter/material.dart';
import 'dart:async';

class PKBattleTimer extends StatefulWidget {
  final DateTime battleStartTime;
  final Duration totalDuration;
  final VoidCallback? onTimerEnd;

  const PKBattleTimer({
    Key? key,
    required this.battleStartTime,
    this.totalDuration = const Duration(minutes: 3),
    this.onTimerEnd,
  }) : super(key: key);

  @override
  State<PKBattleTimer> createState() => _PKBattleTimerState();
}

class _PKBattleTimerState extends State<PKBattleTimer> {
  late Timer _timer;
  // late DateTime _userJoinTime;
  late DateTime _userJoinTime;
  Duration _remainingTime = const Duration(minutes: 3);
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _userJoinTime = DateTime.now();

    _calculateRemainingTime();
    _startTimer();
  }

  void _calculateRemainingTime() {
    final now = DateTime.now();
    final battleEndTime = widget.battleStartTime.add(widget.totalDuration);

    if (now.isAfter(battleEndTime)) {
      _remainingTime = Duration.zero;
      _isActive = false;
    } else {
      _remainingTime = battleEndTime.difference(now);
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _calculateRemainingTime();
      });

      if (_remainingTime.inSeconds <= 0) {
        _isActive = false;
        timer.cancel();
        widget.onTimerEnd?.call();
      }
    });
  }

  String _formatTime(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isActive) {
      return const SizedBox.shrink();
    }
    return Container(
      height: 30,
      width: 100,
      // padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      padding: EdgeInsets.all(3),
      decoration: BoxDecoration(
        // gradient: const LinearGradient(
        //   colors: [
        //     Color(0xFFE0C3FC), // pastel lavender
        //     Color(0xFF8EC5FC), // pastel sky blue
        //   ],
        //   begin: Alignment.topLeft,
        //   end: Alignment.bottomRight,
        // ),
        // color: Colors.transparent,
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1), // softer shadow
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.timer,
            // color: Color(0xFF5B5B8F),
            // // soft muted indigo
            color: Colors.white,
            size: 20,
          ),
          // Container(
          //   padding: const EdgeInsets.all(6),
          //   decoration: BoxDecoration(
          //     color: Colors.white.withOpacity(0.25),
          //     borderRadius: BorderRadius.circular(15),
          //   ),
          //   child: const Icon(
          //     Icons.timer,
          //     // color: Color(0xFF5B5B8F),
          //     // // soft muted indigo
          //     color: Colors.white,
          //     size: 20,
          //   ),
          // ),
          const SizedBox(width: 12),
          Text(
            _formatTime(_remainingTime),
            style: const TextStyle(
              // color: Color(0xFF425C78), // soft navy for text
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
              shadows: [
                Shadow(
                  offset: Offset(0.5, 0.5),
                  blurRadius: 1,
                  color: Colors.black26,
                ),
              ],
            ),
          ),
        ],
      ),
    );

    // return Container(
    //   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    //   decoration: BoxDecoration(
    //     gradient: const LinearGradient(
    //       colors: [
    //         // Color(0xFF4CAF50), // Green
    //         // Color(0xFFFFEB3B), // Yellow
    //         // Color(0xFF4CAF50), // Green
    //         Color(0xFFE0C3FC), // pastel lavender
    //         Color(0xFF8EC5FC), // pastel sky blue
    //       ],
    //       begin: Alignment.topLeft,
    //       end: Alignment.bottomRight,
    //     ),
    //     borderRadius: BorderRadius.circular(20),
    //     boxShadow: [
    //       BoxShadow(
    //         color: Colors.black.withOpacity(0.3),
    //         blurRadius: 8,
    //         offset: const Offset(0, 4),
    //       ),
    //     ],
    //   ),
    //   child: Row(
    //     mainAxisSize: MainAxisSize.min,
    //     children: [
    //       Container(
    //         padding: const EdgeInsets.all(6),
    //         decoration: BoxDecoration(
    //           color: Colors.white.withOpacity(0.2),
    //           borderRadius: BorderRadius.circular(15),
    //         ),
    //         child: const Icon(
    //           Icons.timer,
    //           // color: Colors.white,
    //           color: Color(0xFF5B5B8F), // soft muted indigo
    //           size: 20,
    //         ),
    //       ),
    //       const SizedBox(width: 12),
    //       Text(
    //         _formatTime(_remainingTime),
    //         style: const TextStyle(
    //           color: Colors.white,
    //           fontSize: 18,
    //           fontWeight: FontWeight.bold,
    //           fontFamily: 'monospace',
    //           shadows: [
    //             Shadow(
    //               offset: Offset(1, 1),
    //               blurRadius: 3,
    //               color: Colors.black54,
    //             ),
    //           ],
    //         ),
    //       ),
    //     ],
    //   ),
    // );
  }
}
