import 'dart:ui';
import 'package:flutter/material.dart';

import 'package:zego_uikit_prebuilt_live_streaming/zego_uikit_prebuilt_live_streaming.dart';

class PKRequestingList extends StatefulWidget {
  final ValueNotifier<Map<String, List<String>>>
  requestingHostsMapRequestIDNotifier;

  const PKRequestingList({
    Key? key,
    required this.requestingHostsMapRequestIDNotifier,
  }) : super(key: key);

  @override
  State<PKRequestingList> createState() => _PKRequestingListState();
}

class _PKRequestingListState extends State<PKRequestingList> {
  final requestTextController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 18),
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const Text(
            'Requesting Host,\nClick to Cancel',
            style: TextStyle(
              color: Color(0xFFffa030),
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 120,
            height: 90,
            child: ValueListenableBuilder<Map<String, List<String>>>(
              valueListenable: widget.requestingHostsMapRequestIDNotifier,
              builder: (context, requestingHostsMapRequestID, _) {
                final uniqueItems = <String>{};
                requestingHostsMapRequestID.values.forEach((list) {
                  uniqueItems.addAll(list);
                });
                final invitingHostIDs = uniqueItems.toList();

                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: invitingHostIDs.length,
                  itemBuilder: (context, index) {
                    final hostID = invitingHostIDs.elementAt(index);

                    return ValueListenableBuilder<
                      ZegoLiveStreamingPKBattleState
                    >(
                      valueListenable:
                          ZegoUIKitPrebuiltLiveStreamingController()
                              .pk
                              .stateNotifier,
                      builder: (context, pkState, _) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 0,
                              ),
                              shape: StadiumBorder(),
                              elevation: 0,
                              backgroundColor: Colors.white,
                              shadowColor: Colors.transparent,
                              side: BorderSide(
                                color: Color(0xFFffa030),
                                width: 1.2,
                              ),
                            ),
                            icon: Icon(
                              Icons.person,
                              color: Color(0xFFffa030),
                              size: 16,
                            ),
                            label: Text(
                              hostID,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Color(0xFFffa030),
                              ),
                            ),
                            onPressed:
                                pkState == ZegoLiveStreamingPKBattleState.inPK
                                    ? null
                                    : () {
                                      ZegoUIKitPrebuiltLiveStreamingController()
                                          .pk
                                          .cancelRequest(
                                            targetHostIDs: [hostID],
                                          )
                                          .then((ret) {
                                            if (ret.error == null) {
                                              requestingHostsMapRequestID.forEach((
                                                requestID,
                                                hostIDs,
                                              ) {
                                                if (hostIDs.contains(hostID)) {
                                                  removeRequestingHostsMapWhenRemoteHostDone(
                                                    requestID,
                                                    hostID,
                                                  );

                                                  return;
                                                }
                                              });
                                            }
                                          });
                                    },
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void removeRequestingHostsMapWhenRemoteHostDone(
    String requestID,
    String fromHostID,
  ) {
    widget.requestingHostsMapRequestIDNotifier.value[requestID]?.removeWhere(
      (requestHostID) => fromHostID == requestHostID,
    );
    if (widget.requestingHostsMapRequestIDNotifier.value[requestID]?.isEmpty ??
        false) {
      widget.requestingHostsMapRequestIDNotifier.value.remove(requestID);
    }
    widget.requestingHostsMapRequestIDNotifier.notifyListeners();
  }
}
