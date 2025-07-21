import 'package:flutter/material.dart';
import 'package:zego_uikit_prebuilt_live_streaming/zego_uikit_prebuilt_live_streaming.dart';
import 'dart:ui';

class PKMuteButton extends StatefulWidget {
  final String userID;

  const PKMuteButton({Key? key, required this.userID}) : super(key: key);

  @override
  State<PKMuteButton> createState() => _PKMuteButtonState();
}

class _PKMuteButtonState extends State<PKMuteButton> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<String>>(
      valueListenable:
          ZegoUIKitPrebuiltLiveStreamingController().pk.mutedUsersNotifier,
      builder: (context, muteUsers, _) {
        return GestureDetector(
          onTap: () {
            ZegoUIKitPrebuiltLiveStreamingController().pk.muteAudios(
              targetHostIDs: [widget.userID],
              isMute: !muteUsers.contains(widget.userID),
            );
          },
          child: Container(
            margin: EdgeInsets.all(6),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.transparent,
              border: Border.all(color: Color(0xFFffa030), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFFffa030).withOpacity(0.10),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Container(
              padding: EdgeInsets.all(8),
              child: Icon(
                muteUsers.contains(widget.userID)
                    ? Icons.volume_off
                    : Icons.volume_up,
                color: Color(0xFFffa030),
                size: 20,
              ),
            ),
          ),
        );
      },
    );
  }
}
