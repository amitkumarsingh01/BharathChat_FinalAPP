import 'dart:ffi';
import 'package:finalchat/services/api_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:zego_uikit_prebuilt_live_streaming/zego_uikit_prebuilt_live_streaming.dart';

class PKRequestWidget extends StatefulWidget {
  final ValueNotifier<Map<String, List<String>>>
  requestingHostsMapRequestIDNotifier;
  final ValueNotifier<String> requestIDNotifier;
  final TextEditingController? hostIDTextController;

  const PKRequestWidget({
    Key? key,
    required this.requestIDNotifier,
    required this.requestingHostsMapRequestIDNotifier,
    this.hostIDTextController,
  }) : super(key: key);

  @override
  State<PKRequestWidget> createState() => _PKRequestWidgetState();
}

class _PKRequestWidgetState extends State<PKRequestWidget> {
  final isAutoAcceptedNotifier = ValueNotifier<bool>(false);
  TextEditingController? _internalHostIDController;

  TextEditingController get _hostIDController =>
      widget.hostIDTextController ?? _internalHostIDController!;

  @override
  void initState() {
    super.initState();
    if (widget.hostIDTextController == null) {
      _internalHostIDController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _internalHostIDController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 32), // Increased space above the request row
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Container(
          //   padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          //   decoration: BoxDecoration(
          //     gradient: SweepGradient(
          //       colors: [
          //         Color(0xFFffa030),
          //         Color(0xFFfe9b00),
          //         Color(0xFFf67d00),
          //         Color(0xFFffa030),
          //       ],
          //       startAngle: 0.0,
          //       endAngle: 3.14 * 2,
          //       center: Alignment.center,
          //     ),
          //     borderRadius: BorderRadius.circular(8),
          //   ),
          //   child: const Text(
          //     'Auto Accept:',
          //     style: TextStyle(
          //       fontSize: 15,
          //       color: Colors.white,
          //       fontWeight: FontWeight.bold,
          //     ),
          //   ),
          // ),
          // SizedBox(
          //   width: 30,
          //   height: 30,
          //   child: ValueListenableBuilder<bool>(
          //     valueListenable: isAutoAcceptedNotifier,
          //     builder: (context, isAutoAccepted, _) {
          //       return Checkbox(
          //         value: isAutoAccepted,
          //         onChanged: (value) {
          //           isAutoAcceptedNotifier.value = value ?? false;
          //         },
          //         activeColor: Color(0xFFffa030),
          //         checkColor: Colors.white,
          //       );
          //
          //   ),
          // ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFffa030),
                  Color(0xFFfe9b00),
                  Color(0xFFf67d00),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFFffa030).withOpacity(0.3),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 100,
                  height: 30,
                  child: TextFormField(
                    controller: _hostIDController,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Host ID',
                      hintStyle: TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: Colors.black26,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 0,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.white70, width: 1.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                SizedBox(
                  height: 30,
                  child: ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _hostIDController,
                    builder: (context, value, _) {
                      return SizedBox(
                        width: 110,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 2,
                            backgroundColor: Colors.white,
                            shadowColor: Colors.black26,
                          ),
                          icon: Icon(Icons.send, color: Color(0xFFffa030), size: 16),
                          label: Text(
                            'Request',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFffa030),
                              fontSize: 15,
                            ),
                          ),
                          onPressed: value.text.isEmpty
                              ? null
                              : () async {
                                  FocusScope.of(context).unfocus();
                                  await sendPKBattleRequest(
                                    context,
                                    _hostIDController.text.trim(),
                                  );
                                },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> sendPKBattleRequest(
    BuildContext context,
    String anotherHostUserID,
  ) async {
    await ZegoUIKitPrebuiltLiveStreamingController().pk
        .sendRequest(
          targetHostIDs: [anotherHostUserID],
          isAutoAccept: isAutoAcceptedNotifier.value,
        )
        .then((ret) async {
          if (ret.error != null) {
            showDialog(
              context: context,
              builder: (context) {
                return CupertinoAlertDialog(
                  title: const Text('sendPKBattleRequest failed'),
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
            widget.requestIDNotifier.value = ret.requestID;

            if (widget.requestingHostsMapRequestIDNotifier.value.containsKey(
              ret.requestID,
            )) {
              widget.requestingHostsMapRequestIDNotifier.value[ret.requestID]!
                  .add(anotherHostUserID);
            } else {
              widget.requestingHostsMapRequestIDNotifier.value[ret
                  .requestID] = [anotherHostUserID];
            }
            widget.requestingHostsMapRequestIDNotifier.notifyListeners();
          }
        });
  }
}