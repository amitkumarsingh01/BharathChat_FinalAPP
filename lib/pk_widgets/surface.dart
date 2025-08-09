// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';

// import 'package:zego_uikit_prebuilt_live_streaming/zego_uikit_prebuilt_live_streaming.dart';

// import 'widgets/quit_button.dart';
// import 'widgets/requesting_id.dart';
// import 'widgets/requesting_list.dart';
// import 'widgets/stop_button.dart';
// import 'widgets/pk_battle_button.dart';
// import 'widgets/pk_progress_bar.dart';

// class PKV2Surface extends StatefulWidget {
//   final ValueNotifier<Map<String, List<String>>>
//   requestingHostsMapRequestIDNotifier;
//   final ValueNotifier<String> requestIDNotifier;
//   final ValueNotifier<ZegoLiveStreamingState> liveStateNotifier;

//   const PKV2Surface({
//     Key? key,
//     required this.requestIDNotifier,
//     required this.liveStateNotifier,
//     required this.requestingHostsMapRequestIDNotifier,
//   }) : super(key: key);

//   @override
//   State<PKV2Surface> createState() => _PKV2SurfaceState();
// }

// class _PKV2SurfaceState extends State<PKV2Surface> {
//   bool _showPKRequestList = false;

//   // PK Progress Bar State
//   bool _isPKBattleActive = false;
//   int _leftHostDiamonds = 0;
//   int _rightHostDiamonds = 0;
//   String? _leftHostId;
//   String? _rightHostId;
//   String? _leftHostName;
//   String? _rightHostName;

//   @override
//   void initState() {
//     super.initState();
//     _setupPKBattleListener();
//   }

//   void _setupPKBattleListener() {
//     // Listen to live streaming state changes for PK battle
//     widget.liveStateNotifier.addListener(() {
//       final state = widget.liveStateNotifier.value;
//       setState(() {
//         _isPKBattleActive = state == ZegoLiveStreamingState.inPKBattle;
//         if (_isPKBattleActive) {
//           _startPKBattle();
//         } else {
//           _stopPKBattle();
//         }
//       });
//     });
//   }

//   void _startPKBattle() {
//     // Reset diamond counts
//     _leftHostDiamonds = 0;
//     _rightHostDiamonds = 0;

//     // Set default host information
//     _leftHostId = 'host_1';
//     _rightHostId = 'host_2';
//     _leftHostName = 'Host 1';
//     _rightHostName = 'Host 2';
//   }

//   void _stopPKBattle() {
//     setState(() {
//       _isPKBattleActive = false;
//     });
//   }

//   void _updateDiamondCount(String hostId, int diamonds) {
//     if (hostId == _leftHostId) {
//       setState(() {
//         _leftHostDiamonds += diamonds;
//       });
//     } else if (hostId == _rightHostId) {
//       setState(() {
//         _rightHostDiamonds += diamonds;
//       });
//     }
//   }

//   // Method to update diamond count by host number (1 or 2)
//   void updateDiamondCountByHostNumber(int hostNumber, int diamonds) {
//     if (hostNumber == 1) {
//       setState(() {
//         _leftHostDiamonds += diamonds;
//       });
//     } else if (hostNumber == 2) {
//       setState(() {
//         _rightHostDiamonds += diamonds;
//       });
//     }
//   }

//   @override
//   void dispose() {
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return ValueListenableBuilder<ZegoLiveStreamingState>(
//       valueListenable: widget.liveStateNotifier,
//       builder: (context, state, _) {
//         const baseYPos = 50;

//         final canPK = state != ZegoLiveStreamingState.idle;
//         return canPK
//             ? Stack(
//               children: [
//                 // PK Progress Bar (only visible during PK battle)
//                 if (_isPKBattleActive)
//                   // Positioned(
//                   //   bottom:
//                   //       baseYPos +
//                   //       3.5 * 30 +
//                   //       3.5 * 5, // Position above PK buttons
//                   //   left: 0,
//                   //   right: 0,
//                   //   child: PKProgressBar(
//                   //     leftHostId: _leftHostId,
//                   //     rightHostId: _rightHostId,
//                   //     leftHostName: _leftHostName,
//                   //     rightHostName: _rightHostName,
//                   //     leftDiamonds: _leftHostDiamonds,
//                   //     rightDiamonds: _rightHostDiamonds,
//                   //     totalDiamonds: _leftHostDiamonds + _rightHostDiamonds,
//                   //   ),
//                   // ),
//                   Positioned(
//                     left: 1,
//                     // bottom: baseYPos + 150 + 60,
//                     // bottom: baseYPos + 3.5 * 30 + 3.5 * 5,
//                     bottom: baseYPos + 2.3 * 30 + 2 * 5,
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         GestureDetector(
//                           onTap: () {
//                             setState(() {
//                               _showPKRequestList = !_showPKRequestList;
//                             });
//                           },
//                           child: Container(
//                             padding: const EdgeInsets.symmetric(
//                               horizontal: 20,
//                               vertical: 12,
//                             ),
//                             decoration: BoxDecoration(
//                               gradient: LinearGradient(
//                                 colors: [
//                                   Color(0xFFffa030),
//                                   Color(0xFFfe9b00),
//                                   Color(0xFFf67d00),
//                                 ],
//                                 begin: Alignment.topLeft,
//                                 end: Alignment.bottomRight,
//                               ),
//                               borderRadius: BorderRadius.circular(20),
//                             ),
//                             child: const Text(
//                               'PK Request',
//                               style: TextStyle(
//                                 color: Colors.white,
//                                 fontWeight: FontWeight.bold,
//                                 fontSize: 15,
//                                 letterSpacing: 1.1,
//                               ),
//                             ),
//                           ),
//                         ),
//                         const SizedBox(height: 8),
//                         if (_showPKRequestList)
//                           PKRequestingList(
//                             requestingHostsMapRequestIDNotifier:
//                                 widget.requestingHostsMapRequestIDNotifier,
//                           ),
//                       ],
//                     ),
//                   ),
//                 // Positioned(
//                 //   bottom: baseYPos + 3.5 * 30 + 3.5 * 5,
//                 //   right: 1,
//                 //   child: PKRequestingList(
//                 //     requestingHostsMapRequestIDNotifier:
//                 //         widget.requestingHostsMapRequestIDNotifier,
//                 //   ),
//                 // ),
//                 // child: PKQuitButton(
//                 //   liveStateNotifier: widget.liveStateNotifier,
//                 //   requestingHostsMapRequestIDNotifier:
//                 //       widget.requestingHostsMapRequestIDNotifier,
//                 // ),
//                 // ),
//                 // Positioned(
//                 //   bottom: baseYPos + 2 * 30 + 2 * 5,
//                 //   right: 1,
//                 //   child: PKStopButton(
//                 //     liveStateNotifier: widget.liveStateNotifier,
//                 //     requestingHostsMapRequestIDNotifier:
//                 //         widget.requestingHostsMapRequestIDNotifier,
//                 //   ),
//                 // ),
//                 Positioned(
//                   bottom: baseYPos + 2.5 * 10 + 2.5 * 5,
//                   left: 1,
//                   child: PKBattleButton(
//                     onPressed: () {
//                     },
//                     requestIDNotifier: widget.requestIDNotifier,
//                     requestingHostsMapRequestIDNotifier:
//                         widget.requestingHostsMapRequestIDNotifier,
//                   ),
//                 ),
//                 // Positioned(
//                 //   bottom: baseYPos + 1,
//                 //   left: 40,
//                 //   child: PKBattleButton(
//                 //     onPressed: () {
//                 //     },
//                 //     requestIDNotifier: widget.requestIDNotifier,
//                 //     requestingHostsMapRequestIDNotifier:
//                 //         widget.requestingHostsMapRequestIDNotifier,
//                 //   ),
//                 // ),
//                 // Positioned(
//                 //   bottom: baseYPos,
//                 //   right: 1,
//                 //   child: PKJoinWidget(
//                 //     liveController: widget.liveController,
//                 //     requestingHostsMapRequestIDNotifier:
//                 //         widget.requestingHostsMapRequestIDNotifier,
//                 //   ),
//                 // ),
//                 // Positioned(
//                 //   left: 1,
//                 //   bottom: baseYPos + 150 + 60,
//                 //   child: Column(
//                 //     crossAxisAlignment: CrossAxisAlignment.start,
//                 //     children: [
//                 //       GestureDetector(
//                 //         onTap: () {
//                 //           setState(() {
//                 //             _showPKRequestList = !_showPKRequestList;
//                 //           });
//                 //         },
//                 //         child: Container(
//                 //           padding: const EdgeInsets.symmetric(
//                 //             horizontal: 18,
//                 //             vertical: 10,
//                 //           ),
//                 //           decoration: BoxDecoration(
//                 //             gradient: LinearGradient(
//                 //               colors: [
//                 //                 Color(0xFFffa030),
//                 //                 Color(0xFFfe9b00),
//                 //                 Color(0xFFf67d00),
//                 //               ],
//                 //               begin: Alignment.topLeft,
//                 //               end: Alignment.bottomRight,
//                 //             ),
//                 //             borderRadius: BorderRadius.circular(18),
//                 //           ),
//                 //           child: const Text(
//                 //             'PK Request',
//                 //             style: TextStyle(
//                 //               color: Colors.white,
//                 //               fontWeight: FontWeight.bold,
//                 //               fontSize: 15,
//                 //               letterSpacing: 1.1,
//                 //             ),
//                 //           ),
//                 //         ),
//                 //       ),
//                 //       const SizedBox(height: 8),
//                 //       if (_showPKRequestList)
//                 //         PKRequestingList(
//                 //           requestingHostsMapRequestIDNotifier:
//                 //               widget.requestingHostsMapRequestIDNotifier,
//                 //         ),
//                 //     ],
//                 //   ),
//                 // ),
//                 // Positioned(
//                 //   left: 1,
//                 //   bottom: baseYPos + 60,
//                 //   child: PKRequestingList(
//                 //     requestingHostsMapRequestIDNotifier:
//                 //         widget.requestingHostsMapRequestIDNotifier,
//                 //   ),
//                 // ),
//               ],
//             )
//             : Container();
//       },
//     );
//   }
// }

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:zego_uikit_prebuilt_live_streaming/zego_uikit_prebuilt_live_streaming.dart';

import 'widgets/quit_button.dart';
import 'widgets/request_widget.dart';
import 'widgets/requesting_id.dart';
import 'widgets/requesting_list.dart';
import 'widgets/stop_button.dart';
import 'widgets/pk_battle_button.dart';
import 'widgets/pk_progress_bar.dart';

class PKV2Surface extends StatefulWidget {
  final ValueNotifier<Map<String, List<String>>>
  requestingHostsMapRequestIDNotifier;
  final ValueNotifier<String> requestIDNotifier;
  final ValueNotifier<ZegoLiveStreamingState> liveStateNotifier;

  const PKV2Surface({
    Key? key,
    required this.requestIDNotifier,
    required this.liveStateNotifier,
    required this.requestingHostsMapRequestIDNotifier,
  }) : super(key: key);

  @override
  State<PKV2Surface> createState() => _PKV2SurfaceState();
}

class _PKV2SurfaceState extends State<PKV2Surface> {
  bool _showPKRequestList = false;
  final TextEditingController _hostIDController = TextEditingController();

  // PK Progress Bar State
  bool _isPKBattleActive = false;
  int _leftHostDiamonds = 0;
  int _rightHostDiamonds = 0;
  String? _leftHostId;
  String? _rightHostId;
  String? _leftHostName;
  String? _rightHostName;

  @override
  void initState() {
    super.initState();
    _setupPKBattleListener();
  }

  void _setupPKBattleListener() {
    // Listen to live streaming state changes for PK battle
    widget.liveStateNotifier.addListener(() {
      final state = widget.liveStateNotifier.value;
      setState(() {
        _isPKBattleActive = state == ZegoLiveStreamingState.inPKBattle;
        if (_isPKBattleActive) {
          _startPKBattle();
        } else {
          _stopPKBattle();
        }
      });
    });
  }

  void _startPKBattle() {
    // Reset diamond counts
    _leftHostDiamonds = 0;
    _rightHostDiamonds = 0;

    // Set default host information
    _leftHostId = 'host_1';
    _rightHostId = 'host_2';
    _leftHostName = 'Host 1';
    _rightHostName = 'Host 2';
  }

  void _stopPKBattle() {
    setState(() {
      _isPKBattleActive = false;
    });
  }

  void _updateDiamondCount(String hostId, int diamonds) {
    if (hostId == _leftHostId) {
      setState(() {
        _leftHostDiamonds += diamonds;
      });
    } else if (hostId == _rightHostId) {
      setState(() {
        _rightHostDiamonds += diamonds;
      });
    }
  }

  // Method to update diamond count by host number (1 or 2)
  void updateDiamondCountByHostNumber(int hostNumber, int diamonds) {
    if (hostNumber == 1) {
      setState(() {
        _leftHostDiamonds += diamonds;
      });
    } else if (hostNumber == 2) {
      setState(() {
        _rightHostDiamonds += diamonds;
      });
    }
  }

  @override
  void dispose() {
    _hostIDController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ZegoLiveStreamingState>(
      valueListenable: widget.liveStateNotifier,
      builder: (context, state, _) {
        const baseYPos = 50;

        final canPK = state != ZegoLiveStreamingState.idle;
        return canPK
            ? Stack(
              children: [
                // PK Progress Bar (only visible during PK battle)
                if (_isPKBattleActive)
                  // Positioned(
                  //   bottom:
                  //       baseYPos +
                  //       3.5 * 30 +
                  //       3.5 * 5, // Position above PK buttons
                  //   left: 0,
                  //   right: 0,
                  //   child: PKProgressBar(
                  //     leftHostId: _leftHostId,
                  //     rightHostId: _rightHostId,
                  //     leftHostName: _leftHostName,
                  //     rightHostName: _rightHostName,
                  //     leftDiamonds: _leftHostDiamonds,
                  //     rightDiamonds: _rightHostDiamonds,
                  //     totalDiamonds: _leftHostDiamonds + _rightHostDiamonds,
                  //   ),
                  // ),
                  // Positioned(
                  //   left: 1,
                  //   // bottom: baseYPos + 150 + 60,
                  //   // bottom: baseYPos + 3.5 * 30 + 3.5 * 5,
                  //   bottom: baseYPos + 2.3 * 30 + 2 * 5,
                  //   child: Column(
                  //     crossAxisAlignment: CrossAxisAlignment.start,
                  //     children: [
                  //       GestureDetector(
                  //         onTap: () {
                  //           setState(() {
                  //             _showPKRequestList = !_showPKRequestList;
                  //           });
                  //         },
                  //         child: Container(
                  //           padding: const EdgeInsets.symmetric(
                  //             horizontal: 20,
                  //             vertical: 12,
                  //           ),
                  //           decoration: BoxDecoration(
                  //             gradient: LinearGradient(
                  //               colors: [
                  //                 Color(0xFFffa030),
                  //                 Color(0xFFfe9b00),
                  //                 Color(0xFFf67d00),
                  //               ],
                  //               begin: Alignment.topLeft,
                  //               end: Alignment.bottomRight,
                  //             ),
                  //             borderRadius: BorderRadius.circular(20),
                  //           ),
                  //           child: const Text(
                  //             'PK Request',
                  //             style: TextStyle(
                  //               color: Colors.white,
                  //               fontWeight: FontWeight.bold,
                  //               fontSize: 15,
                  //               letterSpacing: 1.1,
                  //             ),
                  //           ),
                  //         ),
                  //       ),
                  //       const SizedBox(height: 8),
                  //       if (_showPKRequestList)
                  //         PKRequestingList(
                  //           requestingHostsMapRequestIDNotifier:
                  //               widget.requestingHostsMapRequestIDNotifier,
                  //         ),
                  //     ],
                  //   ),
                  // ),
                // Positioned(
                //   bottom: baseYPos + 3.5 * 30 + 3.5 * 5,
                //   right: 1,
                //   child: PKRequestingList(
                //     requestingHostsMapRequestIDNotifier:
                //         widget.requestingHostsMapRequestIDNotifier,
                //   ),
                // ),
                // child: PKQuitButton(
                //   liveStateNotifier: widget.liveStateNotifier,
                //   requestingHostsMapRequestIDNotifier:
                //       widget.requestingHostsMapRequestIDNotifier,
                // ),
                // ),
                // Positioned(
                //   bottom: baseYPos + 2 * 30 + 2 * 5,
                //   right: 1,
                //   child: PKStopButton(
                //     liveStateNotifier: widget.liveStateNotifier,
                //     requestingHostsMapRequestIDNotifier:
                //         widget.requestingHostsMapRequestIDNotifier,
                //   ),
                // ),
                if (!_isPKBattleActive)
                  Positioned(
                    // bottom: baseYPos + 60 + 5,
                    bottom: baseYPos + 30 + 5,
                    left: 1,
                    child: PKBattleButton(
                      onPressed: () {
                        // TODO: Implement PK battle logic
                      },
                      onInvite: (String username) {
                        _hostIDController.text = username;
                      },
                    ),
                  ),
                if (!_isPKBattleActive)
                  Positioned(
                    bottom: baseYPos + 30 + 5,
                    right: 1,
                    child: PKRequestWidget(
                      requestIDNotifier: widget.requestIDNotifier,
                      requestingHostsMapRequestIDNotifier:
                          widget.requestingHostsMapRequestIDNotifier,
                      hostIDTextController: _hostIDController,
                    ),
                  ),
                // Positioned(
                //   bottom: baseYPos,
                //   right: 1,
                //   child: PKJoinWidget(
                //     liveController: widget.liveController,
                //     requestingHostsMapRequestIDNotifier:
                //         widget.requestingHostsMapRequestIDNotifier,
                //   ),
                // ),
                // Positioned(
                //   left: 1,
                //   bottom: baseYPos + 150 + 60,
                //   child: Column(
                //     crossAxisAlignment: CrossAxisAlignment.start,
                //     children: [
                //       GestureDetector(
                //         onTap: () {
                //           setState(() {
                //             _showPKRequestList = !_showPKRequestList;
                //           });
                //         },
                //         child: Container(
                //           padding: const EdgeInsets.symmetric(
                //             horizontal: 18,
                //             vertical: 10,
                //           ),
                //           decoration: BoxDecoration(
                //             gradient: LinearGradient(
                //               colors: [
                //                 Color(0xFFffa030),
                //                 Color(0xFFfe9b00),
                //                 Color(0xFFf67d00),
                //               ],
                //               begin: Alignment.topLeft,
                //               end: Alignment.bottomRight,
                //             ),
                //             borderRadius: BorderRadius.circular(18),
                //           ),
                //           child: const Text(
                //             'PK Request',
                //             style: TextStyle(
                //               color: Colors.white,
                //               fontWeight: FontWeight.bold,
                //               fontSize: 15,
                //               letterSpacing: 1.1,
                //             ),
                //           ),
                //         ),
                //       ),
                //       const SizedBox(height: 8),
                //       if (_showPKRequestList)
                //         PKRequestingList(
                //           requestingHostsMapRequestIDNotifier:
                //               widget.requestingHostsMapRequestIDNotifier,
                //         ),
                //     ],
                //   ),
                // ),
                // Positioned(
                //   left: 1,
                //   bottom: baseYPos + 60,
                //   child: PKRequestingList(
                //     requestingHostsMapRequestIDNotifier:
                //         widget.requestingHostsMapRequestIDNotifier,
                //   ),
                // ),
              ],
            )
            : Container();
      },
    );
  }
}