import 'package:flutter/material.dart';
import 'widgets/pk_battle_ended_popup.dart';

class PKBattleEndedService {
  static final PKBattleEndedService _instance = PKBattleEndedService._internal();
  factory PKBattleEndedService() => _instance;
  PKBattleEndedService._internal();

  static PKBattleEndedService get instance => _instance;

  void showPKBattleEndedPopup({
    required BuildContext context,
    required int winnerId,
    required int leftScore,
    required int rightScore,
    String? leftHostName,
    String? rightHostName,
    String? leftHostId,
    String? rightHostId,
  }) {
    // Show the popup as an overlay that covers the entire screen
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      builder: (context) => PKBattleEndedPopup(
        winnerId: winnerId,
        leftScore: leftScore,
        rightScore: rightScore,
        leftHostName: leftHostName,
        rightHostName: rightHostName,
        leftHostId: leftHostId,
        rightHostId: rightHostId,
        onDismiss: () {
          Navigator.of(context).pop();
        },
      ),
    );
  }
}
