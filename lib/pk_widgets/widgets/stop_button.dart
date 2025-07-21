import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:zego_uikit_prebuilt_live_streaming/zego_uikit_prebuilt_live_streaming.dart';

class PKStopButton extends StatefulWidget {
  final ValueNotifier<Map<String, List<String>>>
  requestingHostsMapRequestIDNotifier;
  final ValueNotifier<ZegoLiveStreamingState> liveStateNotifier;

  const PKStopButton({
    Key? key,
    required this.liveStateNotifier,
    required this.requestingHostsMapRequestIDNotifier,
  }) : super(key: key);

  @override
  State<PKStopButton> createState() => _PKStopButtonState();
}

class _PKStopButtonState extends State<PKStopButton> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: widget.liveStateNotifier,
      builder: (context, state, _) {
        return Container(
          margin: EdgeInsets.only(bottom: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.transparent,
            border: Border.all(color: Color(0xFFf67d00), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Color(0xFFf67d00).withOpacity(0.10),
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
              icon: Icon(Icons.stop_circle, color: Color(0xFFf67d00), size: 20),
              label: const Text(
                'Stop',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFf67d00),
                  fontSize: 16,
                  letterSpacing: 0.5,
                ),
              ),
              onPressed:
                  ZegoLiveStreamingState.inPKBattle == state
                      ? () => stopPKBattle(context)
                      : null,
            ),
          ),
        );
      },
    );
  }

  void stopPKBattle(context) {
    if (!ZegoUIKitPrebuiltLiveStreamingController().pk.isInPK) {
      return;
    }

    ZegoUIKitPrebuiltLiveStreamingController().pk.stop().then((ret) {
      if (ret.error != null) {
        showDialog(
          context: context,
          builder: (context) {
            return CupertinoAlertDialog(
              title: const Text('stopPKBattle failed'),
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
