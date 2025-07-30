import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:zego_uikit_prebuilt_live_streaming/zego_uikit_prebuilt_live_streaming.dart';
import 'package:finalchat/services/api_service.dart';

class PKEvents {
  const PKEvents({
    required this.context,
    required this.requestIDNotifier,
    required this.requestingHostsMapRequestIDNotifier,
    this.onPKBattleStarted,
    this.onPKBattleNotification,
  });

  final BuildContext context;

  final ValueNotifier<String> requestIDNotifier;
  final ValueNotifier<Map<String, List<String>>>
      requestingHostsMapRequestIDNotifier;
  final void Function(Map<String, dynamic> pkBattleInfo)? onPKBattleStarted;
  final void Function(String message)? onPKBattleNotification;

  ZegoLiveStreamingPKEvents get event => ZegoLiveStreamingPKEvents(
        onIncomingRequestReceived: (event, defaultAction) {
          debugPrint(
              'custom event, onIncomingPKBattleRequestReceived, event: 24event');
          
          // Show PK battle request received notification
          if (onPKBattleNotification != null) {
            onPKBattleNotification!('🎮 PK Battle Request Received! 🎮');
          }
          
          defaultAction.call();
        },
        onIncomingRequestCancelled: (event, defaultAction) {
          debugPrint(
              'custom event, onIncomingPKBattleRequestCancelled, event: 24event');
          defaultAction.call();

          requestIDNotifier.value = '';

          removeRequestingHostsMap(event.requestID);
        },
        onIncomingRequestTimeout: (event, defaultAction) {
          debugPrint(
              'custom event, onIncomingPKBattleRequestTimeout, event: 24event');
          defaultAction.call();

          requestIDNotifier.value = '';

          removeRequestingHostsMap(event.requestID);
        },
        // onOutgoingRequestAccepted: (event, defaultAction) async {
        //   debugPrint(
        //       'custom event, onOutgoingPKBattleRequestAccepted, event: 24event');

        //   // Use sender and acceptor ZEGOCLOUD IDs for mapping
        //   final leftHostZegoId = event.fromHost.id; // sender
        //   final rightHostZegoId = ZegoUIKit().getLocalUser().id; // acceptor

        //   try {
        //     // Fetch all live streams and build the mapping
        //     final allStreams = await ApiService.getAllLiveStreams();
        //     // Map: zegoId (username or 'user_<id>') -> {userId, liveId}
        //     final Map<String, Map<String, dynamic>> zegoToBackend = {};
        //     for (final stream in allStreams) {
        //       final zegoId = stream['host_id']?.toString() ?? stream['username']?.toString();
        //       if (zegoId != null) {
        //         zegoToBackend[zegoId] = {
        //           'userId': stream['host_id'],
        //           'liveId': stream['id'],
        //         };
        //       }
        //       // Also map by username if available
        //       if (stream['username'] != null) {
        //         zegoToBackend[stream['username'].toString()] = {
        //           'userId': stream['host_id'],
        //           'liveId': stream['id'],
        //         };
        //       }
        //     }
        //     debugPrint('PKEvents: leftHostZegoId: ' + leftHostZegoId);
        //     debugPrint('PKEvents: rightHostZegoId: ' + rightHostZegoId);
        //     debugPrint('PKEvents: zegoToBackend mapping: ' + zegoToBackend.toString());
        //     final leftBackend = zegoToBackend[leftHostZegoId];
        //     final rightBackend = zegoToBackend[rightHostZegoId];
        //     debugPrint('PKEvents: leftBackend: ' + leftBackend.toString());
        //     debugPrint('PKEvents: rightBackend: ' + rightBackend.toString());
        //     if (leftBackend != null && rightBackend != null) {
        //       debugPrint('PKEvents: Calling startPKBattle with leftHostId: ' + leftBackend['userId'].toString() + ', rightHostId: ' + rightBackend['userId'].toString() + ', leftStreamId: ' + leftBackend['liveId'].toString() + ', rightStreamId: ' + rightBackend['liveId'].toString());
        //       final pkBattleInfo = await ApiService.startPKBattle(
        //         leftHostId: leftBackend['userId'],
        //         rightHostId: rightBackend['userId'],
        //         leftStreamId: leftBackend['liveId'],
        //         rightStreamId: rightBackend['liveId'],
        //       );
        //       debugPrint('PKEvents: startPKBattle response: ' + pkBattleInfo.toString());
        //       if (onPKBattleStarted != null) {
        //         onPKBattleStarted!(pkBattleInfo);
        //       }
        //     } else {
        //       debugPrint('Could not find both hosts in live stream mapping.');
        //     }
        //   } catch (e, stackTrace) {
        //     debugPrint('Failed to start PK battle: $e');
        //     debugPrint('Failed to start PK battle: $stackTrace');
        //   }

        //   defaultAction.call();

        //   removeRequestingHostsMapWhenRemoteHostDone(
        //     event.requestID,
        //     event.fromHost.id,
        //   );
        // },
        onOutgoingRequestAccepted: (event, defaultAction) {
          debugPrint(
              'custom event, onOutgoingPKBattleRequestAccepted, event: 24event');
          
          // Show PK battle started notification
          if (onPKBattleNotification != null) {
            onPKBattleNotification!('🎮 PK Battle Started! 🎮');
          }
          
          defaultAction.call();
        },
        onOutgoingRequestRejected: (event, defaultAction) {
          debugPrint(
              'custom event, onOutgoingPKBattleRequestRejected, event: 24event');
          defaultAction.call();

          removeRequestingHostsMapWhenRemoteHostDone(
            event.requestID,
            event.fromHost.id,
          );
        },
        onOutgoingRequestTimeout: (event, defaultAction) {
          debugPrint(
              'custom event, onOutgoingPKBattleRequestTimeout, event: 24event');

          removeRequestingHostsMapWhenRemoteHostDone(
            event.requestID,
            event.fromHost.id,
          );

          defaultAction.call();
        },
        onEnded: (event, defaultAction) {
          debugPrint('custom event, onPKBattleEnded, event: 24event');
          
          // Show PK battle ended notification
          if (onPKBattleNotification != null) {
            onPKBattleNotification!('🏁 PK Battle Ended! 🏁');
          }
          
          defaultAction.call();

          requestIDNotifier.value = '';

          removeRequestingHostsMapWhenRemoteHostDone(
            event.requestID,
            event.fromHost.id,
          );
        },
        onUserOffline: (event, defaultAction) {
          debugPrint('custom event, onUserOffline, event: 24event');
          defaultAction.call();

          removeRequestingHostsMapWhenRemoteHostDone(
            event.requestID,
            event.fromHost.id,
          );
        },
        onUserQuited: (event, defaultAction) {
          debugPrint('custom event, onUserQuited, event: 24event');
          defaultAction.call();

          if (event.fromHost.id == ZegoUIKit().getLocalUser().id) {
            requestIDNotifier.value = '';
          }

          removeRequestingHostsMapWhenRemoteHostDone(
            event.requestID,
            event.fromHost.id,
          );
        },
        onUserJoined: (ZegoUIKitUser user) {
          debugPrint('custom event, onUserJoined: 24user');
        },
        onUserDisconnected: (ZegoUIKitUser user) {
          debugPrint('custom event, onUserDisconnected: 24user');
        },
        onUserReconnecting: (ZegoUIKitUser user) {
          debugPrint('custom event, onUserReconnecting: 24user');
        },
        onUserReconnected: (ZegoUIKitUser user) {
          debugPrint('custom event, onUserReconnected: 24user');
        },
      );

  void removeRequestingHostsMap(String requestID) {
    requestingHostsMapRequestIDNotifier.value.remove(requestID);

    requestingHostsMapRequestIDNotifier.notifyListeners();
  }

  void removeRequestingHostsMapWhenRemoteHostDone(
    String requestID,
    String fromHostID,
  ) {
    requestingHostsMapRequestIDNotifier.value[requestID]
        ?.removeWhere((requestHostID) => fromHostID == requestHostID);
    if (requestingHostsMapRequestIDNotifier.value[requestID]?.isEmpty ??
        false) {
      removeRequestingHostsMap(requestID);
    }

    requestingHostsMapRequestIDNotifier.notifyListeners();
  }
} 