import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:zego_uikit_prebuilt_live_streaming/zego_uikit_prebuilt_live_streaming.dart';

class PKQuitButton extends StatefulWidget {
  final ValueNotifier<Map<String, List<String>>>
  requestingHostsMapRequestIDNotifier;
  final ValueNotifier<ZegoLiveStreamingState> liveStateNotifier;

  const PKQuitButton({
    Key? key,
    required this.liveStateNotifier,
    required this.requestingHostsMapRequestIDNotifier,
  }) : super(key: key);

  @override
  State<PKQuitButton> createState() => _PKQuitButtonState();
}

class _PKQuitButtonState extends State<PKQuitButton> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: widget.liveStateNotifier,
      builder: (context, state, _) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Container(
            margin: EdgeInsets.only(bottom: 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.transparent,
              border: Border.all(color: Color(0xFFffa030), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFFffa030).withOpacity(0.10),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: SizedBox(
              height: 40,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: Colors.transparent),
                  ),
                  elevation: 0,
                ),
                icon: Icon(Icons.logout, color: Color(0xFFffa030), size: 20),
                label: const Text(
                  'Quit',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFffa030),
                    fontSize: 16,
                    letterSpacing: 0.5,
                  ),
                ),
                onPressed:
                    ZegoLiveStreamingState.inPKBattle == state
                        ? () => quitPKBattle(context)
                        : null,
              ),
            ),
          ),
        );
      },
    );
  }

  void quitPKBattle(context) {
    if (!ZegoUIKitPrebuiltLiveStreamingController().pk.isInPK) {
      return;
    }

    ZegoUIKitPrebuiltLiveStreamingController().pk.quit().then((ret) {
      if (ret.error != null) {
        showDialog(
          context: context,
          builder: (context) {
            return CupertinoAlertDialog(
              title: const Text('quitPKBattle failed'),
              content: Text('Error: ${ret.error}'),
              actions: [
                CupertinoDialogAction(
                  onPressed: Navigator.of(context).pop,
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      } else {
        widget.requestingHostsMapRequestIDNotifier.value = {};
      }
    });
  }
}
