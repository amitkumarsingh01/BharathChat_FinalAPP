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
    this.onPKBattleAccepted,
  });

  final BuildContext context;

  final ValueNotifier<String> requestIDNotifier;
  final ValueNotifier<Map<String, List<String>>>
      requestingHostsMapRequestIDNotifier;
  final void Function(Map<String, dynamic> pkBattleInfo)? onPKBattleStarted;
  final void Function(String message, {String? leftHostId, String? rightHostId, String? leftHostName, String? rightHostName, String? liveId, String? pkBattleId})? onPKBattleNotification;
  final void Function(String leftHostId, String rightHostId, String leftHostName, String rightHostName, String liveId)? onPKBattleAccepted;
  
  // Store the current PK battle ID and start time
  static int? _currentPKBattleId;
  static DateTime? _currentPKBattleStartTime;
  static int? get currentPKBattleId => _currentPKBattleId;
  static DateTime? get currentPKBattleStartTime => _currentPKBattleStartTime;

  static void setCurrentPKBattleStartTime(DateTime? time) {
    _currentPKBattleStartTime = time;
  }

  static void setCurrentPKBattleId(int? id) {
    _currentPKBattleId = id;
  }

  ZegoLiveStreamingPKEvents get event => ZegoLiveStreamingPKEvents(
        onIncomingRequestReceived: (event, defaultAction) async {
          debugPrint(
              'custom event, onIncomingPKBattleRequestReceived, event: 24event');
          
          // Extract usernames from Zego user IDs (remove 'user_' prefix)
          final leftZegoId = event.fromHost.id; // sender
          final rightZegoId = ZegoUIKit().getLocalUser().id; // receiver
          
          String leftUsername = leftZegoId;
          String rightUsername = rightZegoId;
          
          // Remove 'user_' prefix if present
          if (leftZegoId.startsWith('user_')) {
            leftUsername = leftZegoId.substring(5);
          }
          if (rightZegoId.startsWith('user_')) {
            rightUsername = rightZegoId.substring(5);
          }
          
          try {
            // Fetch actual user details from API
            final leftUserDetails = await ApiService.getUserDetailsByUsername(leftUsername);
            final rightUserDetails = await ApiService.getUserDetailsByUsername(rightUsername);
            
            final leftHostId = leftUserDetails?['id']?.toString() ?? leftZegoId;
            final rightHostId = rightUserDetails?['id']?.toString() ?? rightZegoId;
            final leftHostName = leftUserDetails?['username'] ?? leftUsername;
            final rightHostName = rightUserDetails?['username'] ?? rightUsername;
            final liveId = rightZegoId; // current live stream ID
            
            // Show PK battle request received notification with user details
            if (onPKBattleNotification != null) {
              onPKBattleNotification!(
                '🎮 PK Battle Request Received! 🎮',
                leftHostId: leftHostId,
                rightHostId: rightHostId,
                leftHostName: leftHostName,
                rightHostName: rightHostName,
                liveId: liveId,
                pkBattleId: null,
              );
            }
          } catch (e) {
            debugPrint('Failed to fetch user details: $e');
            // Fallback to Zego IDs if API fails
            if (onPKBattleNotification != null) {
              onPKBattleNotification!(
                '🎮 PK Battle Request Received! 🎮',
                leftHostId: leftZegoId,
                rightHostId: rightZegoId,
                leftHostName: leftUsername,
                rightHostName: rightUsername,
                liveId: rightZegoId,
                pkBattleId: null,
              );
            }
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
        onOutgoingRequestAccepted: (event, defaultAction) async {
          debugPrint(
              'custom event, onOutgoingPKBattleRequestAccepted, event: 24event');
          
          // Extract usernames from Zego user IDs (remove 'user_' prefix)
          final leftZegoId = event.fromHost.id; // sender
          final rightZegoId = ZegoUIKit().getLocalUser().id; // acceptor
          
          String leftUsername = leftZegoId;
          String rightUsername = rightZegoId;
          
          // Remove 'user_' prefix if present
          if (leftZegoId.startsWith('user_')) {
            leftUsername = leftZegoId.substring(5);
          }
          if (rightZegoId.startsWith('user_')) {
            rightUsername = rightZegoId.substring(5);
          }
          
          try {
            // Fetch actual user details from API
            final leftUserDetails = await ApiService.getUserDetailsByUsername(leftUsername);
            final rightUserDetails = await ApiService.getUserDetailsByUsername(rightUsername);
            
            final leftHostId = leftUserDetails?['id']?.toString() ?? leftZegoId;
            final rightHostId = rightUserDetails?['id']?.toString() ?? rightZegoId;
            final leftHostName = leftUserDetails?['username'] ?? leftUsername;
            final rightHostName = rightUserDetails?['username'] ?? rightUsername;
            final liveId = rightZegoId; // current live stream ID
            
            // Call the onPKBattleAccepted callback for both hosts
            if (onPKBattleAccepted != null) {
              debugPrint('🎯 Calling onPKBattleAccepted for device: ${ZegoUIKit().getLocalUser().id}');
              debugPrint('🎯 LeftHostId: $leftHostId, RightHostId: $rightHostId');
              debugPrint('🎯 LeftHostName: $leftHostName, RightHostName: $rightHostName');
              onPKBattleAccepted!(leftHostId, rightHostId, leftHostName, rightHostName, liveId);
            } else {
              debugPrint('❌ onPKBattleAccepted callback is null!');
            }
            
            // Call the API to start PK battle when request is accepted
            if (leftUserDetails != null && rightUserDetails != null) {
              try {
                debugPrint('🎯 Calling startPKBattle API for hosts: ${leftUserDetails['id']} vs ${rightUserDetails['id']}');
                final pkBattleResponse = await ApiService.startPKBattle(
                  leftHostId: leftUserDetails['id'],
                  rightHostId: rightUserDetails['id'],
                  leftStreamId: 0,
                  rightStreamId: 0,
                );
                
                // Store the PK battle ID and start time
                _currentPKBattleId = pkBattleResponse?['pk_battle_id'];
                _currentPKBattleStartTime = DateTime.now();
                debugPrint('✅ PK Battle started with ID: $_currentPKBattleId');
                
                // Call the onPKBattleStarted callback if available
                if (onPKBattleStarted != null && pkBattleResponse != null) {
                  onPKBattleStarted!(pkBattleResponse);
                }
              } catch (e) {
                debugPrint('❌ Failed to start PK battle via API: $e');
              }
            } else {
              // Set the start time immediately if user details couldn't be fetched
              if (_currentPKBattleStartTime == null) {
                _currentPKBattleStartTime = DateTime.now();
                debugPrint('⏰ Set PK battle start time: $_currentPKBattleStartTime');
              }
            }
            
            // Show PK battle started notification with user details
            if (onPKBattleNotification != null) {
              onPKBattleNotification!(
                '🎮 PK Battle Started! 🎮',
                leftHostId: leftHostId,
                rightHostId: rightHostId,
                leftHostName: leftHostName,
                rightHostName: rightHostName,
                liveId: liveId,
                pkBattleId: _currentPKBattleId?.toString(),
              );
            }
          } catch (e) {
            debugPrint('Failed to fetch user details: $e');
            // Fallback to Zego IDs if API fails
            if (onPKBattleNotification != null) {
              onPKBattleNotification!(
                '🎮 PK Battle Started! 🎮',
                leftHostId: leftZegoId,
                rightHostId: rightZegoId,
                leftHostName: leftUsername,
                rightHostName: rightUsername,
                liveId: rightZegoId,
                pkBattleId: null,
              );
            }
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
        onEnded: (event, defaultAction) async {
          debugPrint('custom event, onPKBattleEnded, event: 24event');
          
          // Extract usernames from Zego user IDs (remove 'user_' prefix)
          final leftZegoId = event.fromHost.id; // one of the hosts
          final rightZegoId = ZegoUIKit().getLocalUser().id; // current user
          
          String leftUsername = leftZegoId;
          String rightUsername = rightZegoId;
          
          // Remove 'user_' prefix if present
          if (leftZegoId.startsWith('user_')) {
            leftUsername = leftZegoId.substring(5);
          }
          if (rightZegoId.startsWith('user_')) {
            rightUsername = rightZegoId.substring(5);
          }
          
          try {
            // Fetch actual user details from API
            final leftUserDetails = await ApiService.getUserDetailsByUsername(leftUsername);
            final rightUserDetails = await ApiService.getUserDetailsByUsername(rightUsername);
            
            final leftHostId = leftUserDetails?['id']?.toString() ?? leftZegoId;
            final rightHostId = rightUserDetails?['id']?.toString() ?? rightZegoId;
            final leftHostName = leftUserDetails?['username'] ?? leftUsername;
            final rightHostName = rightUserDetails?['username'] ?? rightUsername;
            final liveId = rightZegoId; // current live stream ID
            
            // Show PK battle ended notification with user details
            if (onPKBattleNotification != null) {
              onPKBattleNotification!(
                '🏁 PK Battle Ended! 🏁',
                leftHostId: leftHostId,
                rightHostId: rightHostId,
                leftHostName: leftHostName,
                rightHostName: rightHostName,
                liveId: liveId,
                pkBattleId: _currentPKBattleId?.toString(),
              );
            }
          } catch (e) {
            debugPrint('Failed to fetch user details: $e');
            // Fallback to Zego IDs if API fails
            if (onPKBattleNotification != null) {
              onPKBattleNotification!(
                '🏁 PK Battle Ended! 🏁',
                leftHostId: leftZegoId,
                rightHostId: rightZegoId,
                leftHostName: leftUsername,
                rightHostName: rightUsername,
                liveId: rightZegoId,
                pkBattleId: _currentPKBattleId?.toString(),
              );
            }
          }
          
          defaultAction.call();

          requestIDNotifier.value = '';
          
          // Clear the PK battle ID and start time when battle ends
          _currentPKBattleId = null;
          _currentPKBattleStartTime = null;

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