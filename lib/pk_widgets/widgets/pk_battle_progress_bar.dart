import 'dart:async';
import 'package:flutter/material.dart';
import 'package:finalchat/services/api_service.dart';

class PKBattleProgressBar extends StatefulWidget {
  final int pkBattleId;
  final String? leftHostName;
  final String? rightHostName;

  const PKBattleProgressBar({
    Key? key,
    required this.pkBattleId,
    this.leftHostName,
    this.rightHostName,
  }) : super(key: key);

  @override
  State<PKBattleProgressBar> createState() => _PKBattleProgressBarState();
}

class _PKBattleProgressBarState extends State<PKBattleProgressBar> {
  int leftScore = 0;
  int rightScore = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchScore();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _fetchScore());
  }

  Future<void> _fetchScore() async {
    final result = await ApiService.getPKBattleById(widget.pkBattleId);
    if (result != null && mounted) {
      setState(() {
        leftScore = result['left_score'] ?? 0;
        rightScore = result['right_score'] ?? 0;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = leftScore + rightScore;
    final leftPercent = total == 0 ? 0.5 : leftScore / total;
    final rightPercent = total == 0 ? 0.5 : rightScore / total;

    return Container(
      margin: const EdgeInsets.only(bottom: 0), // margin handled by Positioned
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.yellow, width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.leftHostName ?? 'Left',
                  textAlign: TextAlign.left,
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  widget.rightHostName ?? 'Right',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Stack(
            children: [
              Container(
                height: 18,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(9),
                  color: Colors.grey[800],
                ),
              ),
              Row(
                children: [
                  Expanded(
                    flex: (leftPercent * 1000).toInt(),
                    child: Container(
                      height: 18,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(9),
                          bottomLeft: Radius.circular(9),
                        ),
                        color: Colors.green,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: (rightPercent * 1000).toInt(),
                    child: Container(
                      height: 18,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(9),
                          bottomRight: Radius.circular(9),
                        ),
                        color: Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
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
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
} 