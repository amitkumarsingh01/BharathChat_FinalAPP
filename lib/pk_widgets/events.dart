import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:zego_uikit_prebuilt_live_streaming/zego_uikit_prebuilt_live_streaming.dart';
import 'package:finalchat/services/api_service.dart';
import 'pk_battle_ended_service.dart';

class PKEvents {
  const PKEvents({
    required this.context,
    required this.requestIDNotifier,
    required this.requestingHostsMapRequestIDNotifier,
    this.onPKBattleStarted,
    this.onPKBattleNotification,
    this.onPKBattleAccepted,
    this.onPKBattleAutoEnded,
  });

  final BuildContext context;

  final ValueNotifier<String> requestIDNotifier;
  final ValueNotifier<Map<String, List<String>>>
      requestingHostsMapRequestIDNotifier;
  final void Function(Map<String, dynamic> pkBattleInfo)? onPKBattleStarted;
  final void Function(String message, {String? leftHostId, String? rightHostId, String? leftHostName, String? rightHostName, String? liveId, String? pkBattleId})? onPKBattleNotification;
  final void Function(String leftHostId, String rightHostId, String leftHostName, String rightHostName, String liveId)? onPKBattleAccepted;
  final void Function(int winnerId, String reason)? onPKBattleAutoEnded;
  
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
            
            // PK battle request received - no notification needed
          } catch (e) {
            debugPrint('Failed to fetch user details: $e');
            // Fallback to Zego IDs if API fails - no notification needed
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
                
                // Get all video lives to find the stream IDs for both hosts
                final videoLives = await ApiService.getVideoLives();
                int leftStreamId = 0;
                int rightStreamId = 0;
                
                // Find stream IDs for both hosts
                for (final live in videoLives) {
                  if (live['user_id'] == leftUserDetails['id']) {
                    final liveUrl = live['live_url'] ?? '';
                    if (liveUrl.startsWith('live_')) {
                      final parts = liveUrl.split('_');
                      if (parts.length >= 2) {
                        leftStreamId = int.tryParse(parts[1]) ?? 0;
                        debugPrint('🎯 Found left stream ID: $leftStreamId from live_url: $liveUrl for host: ${leftUserDetails['id']}');
                      }
                    }
                  }
                  if (live['user_id'] == rightUserDetails['id']) {
                    final liveUrl = live['live_url'] ?? '';
                    if (liveUrl.startsWith('live_')) {
                      final parts = liveUrl.split('_');
                      if (parts.length >= 2) {
                        rightStreamId = int.tryParse(parts[1]) ?? 0;
                        debugPrint('🎯 Found right stream ID: $rightStreamId from live_url: $liveUrl for host: ${rightUserDetails['id']}');
                      }
                    }
                  }
                }
                
                final pkBattleResponse = await ApiService.startPKBattle(
                  leftHostId: leftUserDetails['id'],
                  rightHostId: rightUserDetails['id'],
                  leftStreamId: leftStreamId,
                  rightStreamId: rightStreamId,
                );
                
                debugPrint('🎯 Full PK battle response: $pkBattleResponse');
                debugPrint('🎯 PK battle response keys: ${pkBattleResponse?.keys.toList()}');
                debugPrint('🎯 PK battle ID from response: ${pkBattleResponse?['pk_battle_id']}');
                debugPrint('🎯 PK battle ID type: ${pkBattleResponse?['pk_battle_id']?.runtimeType}');
                
                // Store the PK battle ID and start time
                _currentPKBattleId = pkBattleResponse?['pk_battle_id'];
                _currentPKBattleStartTime = DateTime.now();
                debugPrint('✅ PK Battle started with ID: $_currentPKBattleId');
                debugPrint('✅ PK Battle ID type: ${_currentPKBattleId?.runtimeType}');
                
                // Call the onPKBattleStarted callback if available
                if (onPKBattleStarted != null && pkBattleResponse != null) {
                  onPKBattleStarted!(pkBattleResponse);
                }
                
                // Update the local pkBattleId variable for immediate UI update
                final pkBattleIdString = _currentPKBattleId?.toString();
                debugPrint('🎯 PK Battle ID for notification: $pkBattleIdString');
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
            
            // PK battle started - no notification needed
          } catch (e) {
            debugPrint('Failed to fetch user details: $e');
            // Fallback to Zego IDs if API fails - no notification needed
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
            
            // Show PK battle ended popup for all users
            if (context.mounted) {
              // Try to get PK battle details to show scores
              try {
                final pkBattleDetails = await ApiService.getActivePKBattleByStreamId(int.parse(liveId));
                if (pkBattleDetails != null) {
                  // Determine winner based on scores
                  final leftScore = int.tryParse(pkBattleDetails['left_score']?.toString() ?? '0') ?? 0;
                  final rightScore = int.tryParse(pkBattleDetails['right_score']?.toString() ?? '0') ?? 0;
                  int winnerId = 0;
                  if (leftScore > rightScore) {
                    winnerId = int.tryParse(leftHostId) ?? 0;
                  } else if (rightScore > leftScore) {
                    winnerId = int.tryParse(rightHostId) ?? 0;
                  }
                  
                  PKBattleEndedService.instance.showPKBattleEndedPopup(
                    context: context,
                    winnerId: winnerId,
                    leftScore: leftScore,
                    rightScore: rightScore,
                    leftHostName: leftHostName,
                    rightHostName: rightHostName,
                    leftHostId: leftHostId,
                    rightHostId: rightHostId,
                  );
                }
              } catch (e) {
                debugPrint('Failed to fetch PK battle details: $e');
              }
            }
          } catch (e) {
            debugPrint('Failed to fetch user details: $e');
            // Fallback to Zego IDs if API fails - no notification needed
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
        onUserOffline: (event, defaultAction) async {
          debugPrint('custom event, onUserOffline, event: 24event');
          debugPrint('🚨 User went offline: ${event.fromHost.id}');
          
          // Auto-end PK battle if user goes offline
          await _autoEndPKBattleOnUserLeave(event.fromHost.id, 'offline');
          
          defaultAction.call();

          removeRequestingHostsMapWhenRemoteHostDone(
            event.requestID,
            event.fromHost.id,
          );
        },
        onUserQuited: (event, defaultAction) async {
          debugPrint('custom event, onUserQuited, event: 24event');
          debugPrint('🚨 User quit: ${event.fromHost.id}');
          
          // Auto-end PK battle if user quits
          await _autoEndPKBattleOnUserLeave(event.fromHost.id, 'quit');
          
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
        onUserDisconnected: (ZegoUIKitUser user) async {
          debugPrint('custom event, onUserDisconnected: 24user');
          debugPrint('🚨 User disconnected: ${user.id}');
          
          // Auto-end PK battle if user disconnects
          await _autoEndPKBattleOnUserLeave(user.id, 'disconnected');
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

  Future<void> _autoEndPKBattleOnUserLeave(String userId, String reason) async {
    try {
      debugPrint('🚨 Auto-ending PK battle due to user leave: $userId ($reason)');
      
      // Check if there's an active PK battle
      if (_currentPKBattleId != null) {
        debugPrint('🎮 Found active PK battle: $_currentPKBattleId');
        
        // Extract usernames from Zego user IDs (remove 'user_' prefix)
        String username = userId;
        if (userId.startsWith('user_')) {
          username = userId.substring(5);
        }
        
        try {
          // Get user details to determine if this user is one of the PK battle hosts
          final userDetails = await ApiService.getUserDetailsByUsername(username);
          if (userDetails != null) {
            final userHostId = userDetails['id']?.toString();
            debugPrint('🎯 User host ID: $userHostId');
            
            // Get current PK battle details to check if this user is a participant
            final pkBattleDetails = await ApiService.getPKBattleById(_currentPKBattleId!);
            if (pkBattleDetails != null) {
              final leftHostId = pkBattleDetails['left_host_id']?.toString();
              final rightHostId = pkBattleDetails['right_host_id']?.toString();
              
              debugPrint('🎯 PK Battle hosts - Left: $leftHostId, Right: $rightHostId');
              
              // Check if the leaving user is one of the PK battle hosts
              if (userHostId == leftHostId || userHostId == rightHostId) {
                debugPrint('🚨 PK Battle host left! Auto-ending PK battle...');
                
                // Determine winner (the other host)
                int winnerId = 0;
                if (userHostId == leftHostId) {
                  winnerId = int.tryParse(rightHostId ?? '0') ?? 0;
                  debugPrint('🏆 Right host wins (left host left)');
                } else {
                  winnerId = int.tryParse(leftHostId ?? '0') ?? 0;
                  debugPrint('🏆 Left host wins (right host left)');
                }
                
                // End the PK battle via API
                final endResult = await ApiService.endPKBattle(
                  pkBattleId: _currentPKBattleId!,
                  leftScore: pkBattleDetails['left_score'] ?? 0,
                  rightScore: pkBattleDetails['right_score'] ?? 0,
                  winnerId: winnerId,
                );
                
                if (endResult != null) {
                  debugPrint('✅ PK battle auto-ended successfully');
                  debugPrint('🏆 Winner ID: $winnerId');
                  
                  // Show PK battle ended popup for all users
                  if (context.mounted) {
                    // Convert scores to integers
                    final leftScore = int.tryParse(pkBattleDetails['left_score']?.toString() ?? '0') ?? 0;
                    final rightScore = int.tryParse(pkBattleDetails['right_score']?.toString() ?? '0') ?? 0;
                    
                    // Use left/right instead of Unknown for usernames
                    final leftHostName = leftHostId != null ? 'Left Host' : 'Left Host';
                    final rightHostName = rightHostId != null ? 'Right Host' : 'Right Host';
                    
                    PKBattleEndedService.instance.showPKBattleEndedPopup(
                      context: context,
                      winnerId: winnerId,
                      leftScore: leftScore,
                      rightScore: rightScore,
                      leftHostName: leftHostName,
                      rightHostName: rightHostName,
                      leftHostId: leftHostId,
                      rightHostId: rightHostId,
                    );
                  }
                  
                  // Call auto-ended callback
                  if (onPKBattleAutoEnded != null) {
                    onPKBattleAutoEnded!(winnerId, reason);
                  }
                } else {
                  debugPrint('❌ Failed to auto-end PK battle via API');
                }
                
                // Clear the PK battle data
                _currentPKBattleId = null;
                _currentPKBattleStartTime = null;
                
              } else {
                debugPrint('ℹ️ Leaving user is not a PK battle host, no action needed');
              }
            } else {
              debugPrint('❌ Could not fetch PK battle details');
            }
          } else {
            debugPrint('❌ Could not fetch user details for: $username');
          }
        } catch (e) {
          debugPrint('❌ Error in auto-end PK battle: $e');
        }
      } else {
        debugPrint('ℹ️ No active PK battle to end');
      }
    } catch (e) {
      debugPrint('❌ Error in _autoEndPKBattleOnUserLeave: $e');
    }
  }
} 