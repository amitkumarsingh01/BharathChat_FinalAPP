import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:zego_uikit_prebuilt_live_streaming/zego_uikit_prebuilt_live_streaming.dart';
import 'package:finalchat/services/api_service.dart';
import 'package:finalchat/screens/live/pk_battle_debug_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class PKEvents {
  const PKEvents({
    required this.requestIDNotifier,
    required this.requestingHostsMapRequestIDNotifier,
    this.onRemoteUserInfoReceived,
    this.context,
  });

  final ValueNotifier<String> requestIDNotifier;
  final ValueNotifier<Map<String, List<String>>>
      requestingHostsMapRequestIDNotifier;
  final Function(String)? onRemoteUserInfoReceived;
  final BuildContext? context;

  ZegoLiveStreamingPKEvents get event => ZegoLiveStreamingPKEvents(
        onIncomingRequestReceived: (event, defaultAction) {
          print('printfromzego: ==========================================');
          print('printfromzego: INCOMING PK REQUEST RECEIVED');
          print('printfromzego: Request ID: ${event.requestID}');
          print('printfromzego: From Host: ${event.fromHost.name} (ID: ${event.fromHost.id})');
          print('printfromzego: From Live ID: ${event.fromLiveID}');
          print('printfromzego: Event data: $event');
          print('printfromzego: Current PK State: ${ZegoUIKitPrebuiltLiveStreamingController().pk.stateNotifier.value}');
          print('printfromzego: Is PK Battle Active: ${ZegoUIKitPrebuiltLiveStreamingController().pk.isInPK}');
          
          // Store the incoming request info for when user accepts
          requestIDNotifier.value = event.requestID;
          
          // Store the remote user info for API call
          if (onRemoteUserInfoReceived != null) {
            onRemoteUserInfoReceived!(event.fromHost.name);
            print('printfromzego: Remote user info stored: ${event.fromHost.name}');
          }
          
          // Let the user manually accept or reject the PK request
          // The default action will show the accept/reject UI
          defaultAction.call();
          
          // Add a listener to detect when PK battle starts (user accepts)
          _addPKBattleStartListener(event);
          
          print('printfromzego: ==========================================');
        },
        onIncomingRequestCancelled: (event, defaultAction) {
          debugPrint('responsefromzego: onIncomingPKBattleRequestCancelled');
          debugPrint('responsefromzego: Request ID: ${event.requestID}');
          debugPrint('responsefromzego: Event data: $event');
          defaultAction.call();

          requestIDNotifier.value = '';
          removeRequestingHostsMap(event.requestID);
        },
        onIncomingRequestTimeout: (event, defaultAction) {
          debugPrint('responsefromzego: onIncomingPKBattleRequestTimeout');
          debugPrint('responsefromzego: Request ID: ${event.requestID}');
          debugPrint('responsefromzego: Event data: $event');
          defaultAction.call();

          requestIDNotifier.value = '';
          removeRequestingHostsMap(event.requestID);
        },

        // This is called when the PK request you sent is accepted by the other user
        onOutgoingRequestAccepted: (event, defaultAction) async {
          print('printfromzego: ==========================================');
          print('printfromzego: OUTGOING PK REQUEST ACCEPTED');
          print('printfromzego: Request ID: ${event.requestID}');
          print('printfromzego: From Host: ${event.fromHost.name} (ID: ${event.fromHost.id})');
          print('printfromzego: From Live ID: ${event.fromLiveID}');
          print('printfromzego: Event data: $event');
          print('printfromzego: Current PK State: ${ZegoUIKitPrebuiltLiveStreamingController().pk.stateNotifier.value}');
          print('printfromzego: Is PK Battle Active: ${ZegoUIKitPrebuiltLiveStreamingController().pk.isInPK}');
          defaultAction.call();

          removeRequestingHostsMapWhenRemoteHostDone(
            event.requestID,
            event.fromHost.id,
          );
          
          print('printfromzego: PK request accepted - CALLING API NOW');
          
          // CALL THE API TO CREATE PK BATTLE
          await _startPKBattleAPI(event);
          
          print('printfromzego: ==========================================');
        },
        onOutgoingRequestRejected: (event, defaultAction) {
          debugPrint('responsefromzego: onOutgoingPKBattleRequestRejected');
          debugPrint('responsefromzego: Request ID: ${event.requestID}');
          debugPrint('responsefromzego: From Host: ${event.fromHost.name} (ID: ${event.fromHost.id})');
          debugPrint('responsefromzego: Event data: $event');
          defaultAction.call();

          removeRequestingHostsMapWhenRemoteHostDone(
            event.requestID,
            event.fromHost.id,
          );
        },
        onOutgoingRequestTimeout: (event, defaultAction) {
          debugPrint('responsefromzego: onOutgoingPKBattleRequestTimeout');
          debugPrint('responsefromzego: Request ID: ${event.requestID}');
          debugPrint('responsefromzego: From Host: ${event.fromHost.name} (ID: ${event.fromHost.id})');
          debugPrint('responsefromzego: Event data: $event');

          removeRequestingHostsMapWhenRemoteHostDone(
            event.requestID,
            event.fromHost.id,
          );

          defaultAction.call();
        },
        onEnded: (event, defaultAction) async {
          debugPrint('responsefromzego: onPKBattleEnded');
          debugPrint('responsefromzego: Request ID: ${event.requestID}');
          debugPrint('responsefromzego: From Host: ${event.fromHost.name} (ID: ${event.fromHost.id})');
          debugPrint('responsefromzego: Event data: $event');
          defaultAction.call();

          // Clear PK battle ID from storage when battle ends
          await ApiService.clearPKBattleId();
          print('printfromzego: PK Battle ID cleared from storage');
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
    requestingHostsMapRequestIDNotifier.value[requestID]?.removeWhere((requestHostID) => fromHostID == requestHostID);
    if (requestingHostsMapRequestIDNotifier.value[requestID]?.isEmpty ?? false) {
      removeRequestingHostsMap(requestID);
    }
    requestingHostsMapRequestIDNotifier.notifyListeners();
  }

  // Method to handle PK battle API call
  Future<void> _startPKBattleAPI(dynamic event) async {
    print('printfromzego: ==========================================');
    print('printfromzego: STARTING PK BATTLE API CALL');
    print('printfromzego: Context available: ${context != null}');
    
    // Store API call details for display
    Map<String, dynamic> apiCallDetails = {
      'timestamp': DateTime.now().toIso8601String(),
      'api_calls': [],
      'final_response': null,
      'error': null,
    };
    
    try {
      // Get local user info
      final localUser = ZegoUIKit().getLocalUser();
      final localUserName = localUser.name;
      
      // Get remote user info from the event
      final remoteUserName = event.fromHost?.name ?? '';

      print('printfromzego: Local user: $localUserName (ID: ${localUser.id})');
      print('printfromzego: Remote user: $remoteUserName');
      print('printfromzego: Remote user Zego ID: ${event.fromHost?.id}');

      if (localUserName.isEmpty || remoteUserName.isEmpty) {
        print('printfromzego: ERROR - Host usernames not available for PK battle API');
        apiCallDetails['error'] = 'Host usernames not available for PK battle API';
        _showApiResponseDialog(apiCallDetails);
        return;
      }

      // Get local user ID - this is the current user (sender or receiver)
      int? localUserId = ApiService.currentUserId;
      if (localUserId == null) {
        print('printfromzego: Local user ID not available from API service, will fetch from username');
      } else {
        print('printfromzego: Local user ID available from API service: $localUserId');
      }

      // Clean usernames by removing 'user_' prefix if present
      final cleanLocalUserName = localUserName.startsWith('user_') 
          ? localUserName.substring(5) 
          : localUserName;
      final cleanRemoteUserName = remoteUserName.startsWith('user_') 
          ? remoteUserName.substring(5) 
          : remoteUserName;

      print('printfromzego: Cleaned usernames - Local: $cleanLocalUserName, Remote: $cleanRemoteUserName');
      
      // Validate usernames are not empty after cleaning
      if (cleanLocalUserName.isEmpty || cleanRemoteUserName.isEmpty) {
        print('printfromzego: ERROR - Usernames are empty after cleaning');
        apiCallDetails['error'] = 'Usernames are empty after cleaning';
        _showApiResponseDialog(apiCallDetails);
        return;
      }

      // Get user IDs from usernames
      print('printfromzego: Fetching user IDs from usernames...');
      
      // API Call 1: Get Local User ID (only if not available from service)
      if (localUserId == null) {
        final localUserIdUrl = '${ApiService.baseUrl}/user-id-by-username?username=$cleanLocalUserName';
        final localUserIdHeaders = 'Content-Type: application/json, accept: application/json';
        
        apiCallDetails['api_calls'].add({
          'api_name': 'Get User ID by Username (Local)',
          'url': localUserIdUrl,
          'method': 'GET',
          'request_headers': localUserIdHeaders,
          'request_body': null,
          'response_status': null,
          'response_body': null,
          'result': null,
          'error': null,
        });
        
        try {
          print('printfromzego: Starting API call for local user: $cleanLocalUserName');
          localUserId = await ApiService.getUserIdByUsername(cleanLocalUserName);
          print('printfromzego: API call completed successfully: $localUserId');
          
          // Update the API call with success response
          apiCallDetails['api_calls'][0]['response_status'] = 200;
          apiCallDetails['api_calls'][0]['response_body'] = json.encode({'id': localUserId});
          apiCallDetails['api_calls'][0]['result'] = localUserId;
          print('printfromzego: Local user ID API call successful: $localUserId');
        } catch (e) {
          print('printfromzego: EXCEPTION in local user API call: $e');
          print('printfromzego: Exception type: ${e.runtimeType}');
          print('printfromzego: Exception stack trace: ${e.toString()}');
          
          // Update the API call with error response
          apiCallDetails['api_calls'][0]['response_status'] = 400;
          apiCallDetails['api_calls'][0]['response_body'] = json.encode({'error': e.toString()});
          apiCallDetails['api_calls'][0]['error'] = e.toString();
          print('printfromzego: Local user ID API call failed: $e');
        }
      } else {
        // Add entry for local user ID from service
        apiCallDetails['api_calls'].add({
          'api_name': 'Get User ID from Service (Local)',
          'url': 'N/A - From API Service',
          'method': 'N/A',
          'request_headers': 'N/A',
          'request_body': null,
          'response_status': 200,
          'response_body': json.encode({'id': localUserId}),
          'result': localUserId,
          'error': null,
        });
        print('printfromzego: Using local user ID from service: $localUserId');
      }

      // API Call 2: Get Remote User ID
      final remoteUserIdUrl = '${ApiService.baseUrl}/user-id-by-username?username=$cleanRemoteUserName';
      final remoteUserIdHeaders = 'Content-Type: application/json, accept: application/json';
      
      apiCallDetails['api_calls'].add({
        'api_name': 'Get User ID by Username (Remote)',
        'url': remoteUserIdUrl,
        'method': 'GET',
        'request_headers': remoteUserIdHeaders,
        'request_body': null,
        'response_status': null,
        'response_body': null,
        'result': null,
        'error': null,
      });
      
      int? remoteUserId;
      try {
        remoteUserId = await ApiService.getUserIdByUsername(cleanRemoteUserName);
        // Update the API call with success response
        apiCallDetails['api_calls'][1]['response_status'] = 200;
        apiCallDetails['api_calls'][1]['response_body'] = json.encode({'id': remoteUserId});
        apiCallDetails['api_calls'][1]['result'] = remoteUserId;
        print('printfromzego: Remote user ID API call successful: $remoteUserId');
      } catch (e) {
        print('printfromzego: EXCEPTION in remote user API call: $e');
        print('printfromzego: Exception type: ${e.runtimeType}');
        print('printfromzego: Exception stack trace: ${e.toString()}');
        
        // Update the API call with error response
        apiCallDetails['api_calls'][1]['response_status'] = 400;
        apiCallDetails['api_calls'][1]['response_body'] = json.encode({'error': e.toString()});
        apiCallDetails['api_calls'][1]['error'] = e.toString();
        print('printfromzego: Remote user ID API call failed: $e');
      }

      print('printfromzego: Local user ID: $localUserId');
      print('printfromzego: Remote user ID: $remoteUserId');

      if (localUserId == null || remoteUserId == null) {
        print('printfromzego: ERROR - Could not fetch host user IDs for PK battle API');
        print('printfromzego: Local user ID is null: ${localUserId == null}');
        print('printfromzego: Remote user ID is null: ${remoteUserId == null}');
        apiCallDetails['error'] = 'Could not fetch host user IDs for PK battle API. Local: $localUserId, Remote: $remoteUserId';
        _showApiResponseDialog(apiCallDetails);
        return;
      }

      // Determine who is left host and who is right host
      // The user who sent the request is typically the left host
      int leftHostId;
      int rightHostId;
      
      // Check if current user is the one who sent the request
      // We can determine this by checking if the requestID matches our outgoing request
      final isLocalUserSender = requestIDNotifier.value.isNotEmpty && 
                               requestIDNotifier.value == event.requestID;
      
      if (isLocalUserSender) {
        // Local user sent the request, so they are the left host (sender)
        leftHostId = localUserId;
        rightHostId = remoteUserId;
        print('printfromzego: Local user is SENDER - Left Host: $leftHostId, Right Host: $rightHostId');
        print('printfromzego: Sender ID: $leftHostId, Receiver ID: $rightHostId');
      } else {
        // Remote user sent the request, so they are the left host (sender)
        leftHostId = remoteUserId;
        rightHostId = localUserId;
        print('printfromzego: Remote user is SENDER - Left Host: $leftHostId, Right Host: $rightHostId');
        print('printfromzego: Sender ID: $leftHostId, Receiver ID: $rightHostId');
      }

      // Try to get stream IDs if available from the event
      int leftStreamId = 0;
      int rightStreamId = 0;
      
      // Check if stream IDs are available in the event
      if (event.fromLiveID != null && event.fromLiveID.isNotEmpty) {
        try {
          rightStreamId = int.parse(event.fromLiveID);
          print('printfromzego: Found remote stream ID: $rightStreamId');
        } catch (e) {
          print('printfromzego: Could not parse remote stream ID: ${event.fromLiveID}');
        }
      }
      
      // For local stream ID, we might need to get it from the current live stream
      // This would depend on how you're tracking the current live stream ID
      
      print('printfromzego: Calling API with parameters:');
      print('printfromzego: - leftHostId: $leftHostId');
      print('printfromzego: - rightHostId: $rightHostId');
      print('printfromzego: - leftStreamId: $leftStreamId');
      print('printfromzego: - rightStreamId: $rightStreamId');

      // Prepare request body for final API call
      final requestBody = {
        'left_host_id': leftHostId,
        'right_host_id': rightHostId,
        'left_stream_id': leftStreamId,
        'right_stream_id': rightStreamId,
      };

      // API Call 3: Start PK Battle
      final pkBattleUrl = '${ApiService.baseUrl}/pk-battle/start';
      final pkBattleHeaders = 'Authorization: Bearer ${ApiService.token}, Content-Type: application/json';
      
      apiCallDetails['api_calls'].add({
        'api_name': 'Start PK Battle',
        'url': pkBattleUrl,
        'method': 'POST',
        'request_headers': pkBattleHeaders,
        'request_body': json.encode(requestBody),
        'response_status': null,
        'response_body': null,
        'result': null,
        'error': null,
      });
      
      int? pkBattleId;
      try {
        // Use the existing ApiService.startPKBattle method
        pkBattleId = await ApiService.startPKBattle(
          leftHostId: leftHostId,
          rightHostId: rightHostId,
          leftStreamId: leftStreamId,
          rightStreamId: rightStreamId,
        );
        
        // Update the API call with success response
        apiCallDetails['api_calls'][2]['response_status'] = 200;
        apiCallDetails['api_calls'][2]['response_body'] = json.encode({
          'pk_battle_id': pkBattleId,
          'status': 'started'
        });
        apiCallDetails['api_calls'][2]['result'] = pkBattleId;
        print('printfromzego: PK Battle API call successful: $pkBattleId');
      } catch (e) {
        print('printfromzego: EXCEPTION in PK Battle API call: $e');
        print('printfromzego: Exception type: ${e.runtimeType}');
        print('printfromzego: Exception stack trace: ${e.toString()}');
        
        // Update the API call with error response
        apiCallDetails['api_calls'][2]['response_status'] = 400;
        apiCallDetails['api_calls'][2]['response_body'] = json.encode({'error': e.toString()});
        apiCallDetails['api_calls'][2]['error'] = e.toString();
        print('printfromzego: PK Battle API call failed: $e');
      }

      print('printfromserver: PK Battle API response received');
      print('printfromserver: pk_battle_id: $pkBattleId');

      if (pkBattleId != null) {
        await ApiService.savePKBattleId(pkBattleId);
        print('printfromserver: PK Battle started successfully with ID: $pkBattleId');
        print('printfromserver: PK Battle ID saved to local storage');
        
        // Store final response
        apiCallDetails['final_response'] = {
          'pk_battle_id': pkBattleId,
          'status': 'started',
          'message': 'PK Battle started successfully',
        };
      } else {
        print('printfromserver: No pk_battle_id returned from server');
        apiCallDetails['error'] = 'No pk_battle_id returned from server';
      }
      
    } catch (e) {
      print('printfromzego: ERROR in PK battle API call: $e');
      apiCallDetails['error'] = 'Error in PK battle API call: $e';
    }
    
    // ALWAYS show the dialog at the end, regardless of success or failure
    print('printfromzego: ALWAYS SHOWING DIALOG - API call completed');
    print('printfromzego: API Call Details: $apiCallDetails');
    _showApiResponseDialog(apiCallDetails);
    
    print('printfromzego: ==========================================');
  }

  // Method to add listener for PK battle start
  void _addPKBattleStartListener(dynamic event) {
    print('printfromzego: Adding PK battle start listener');
    
    // Check current PK state immediately
    final currentPkState = ZegoUIKitPrebuiltLiveStreamingController().pk.stateNotifier.value;
    print('printfromzego: Current PK State: $currentPkState');
    print('printfromzego: Is PK Battle Active: ${ZegoUIKitPrebuiltLiveStreamingController().pk.isInPK}');
    
    // If PK battle is already active, trigger API call immediately
    if (currentPkState == ZegoLiveStreamingPKBattleState.inPK || ZegoUIKitPrebuiltLiveStreamingController().pk.isInPK) {
      print('printfromzego: PK BATTLE ALREADY ACTIVE - Triggering API call immediately!');
      _startPKBattleAPI(event);
      return;
    }
    
    // Listen to PK state changes
    ZegoUIKitPrebuiltLiveStreamingController().pk.stateNotifier.addListener(() {
      final pkState = ZegoUIKitPrebuiltLiveStreamingController().pk.stateNotifier.value;
      print('printfromzego: PK State changed to: $pkState');
      print('printfromzego: Is PK Battle Active: ${ZegoUIKitPrebuiltLiveStreamingController().pk.isInPK}');
      
      // If PK battle started (user accepted the request)
      if (pkState == ZegoLiveStreamingPKBattleState.inPK || ZegoUIKitPrebuiltLiveStreamingController().pk.isInPK) {
        print('printfromzego: PK BATTLE STARTED - User accepted the request!');
        print('printfromzego: Calling API for accepted incoming request');
        
        // Call the API to create PK battle
        _startPKBattleAPI(event);
        
        // Remove the listener to avoid multiple calls
        ZegoUIKitPrebuiltLiveStreamingController().pk.stateNotifier.removeListener(() {});
      }
    });
  }

  // Method to show API response debug screen
  void _showApiResponseDialog(Map<String, dynamic> apiCallDetails) {
    print('printfromzego: ==========================================');
    print('printfromzego: SHOWING PK BATTLE DEBUG SCREEN');
    print('printfromzego: Context available: ${context != null}');
    print('printfromzego: API Call Details: $apiCallDetails');
    
    // Check if context is available
    if (context == null) {
      print('printfromzego: ERROR - Context not available for debug screen');
      print('printfromzego: FALLBACK - Printing API details to console:');
      print('printfromzego: Timestamp: ${apiCallDetails['timestamp']}');
      print('printfromzego: API Calls: ${apiCallDetails['api_calls']}');
      print('printfromzego: Final Response: ${apiCallDetails['final_response']}');
      print('printfromzego: Error: ${apiCallDetails['error']}');
      return;
    }

    // Navigate to the dedicated debug screen
    Navigator.of(context!).push(
      MaterialPageRoute(
        builder: (context) => PKBattleDebugScreen(
          apiCallDetails: apiCallDetails,
        ),
      ),
    );
    
    print('printfromzego: Debug screen navigation initiated');
    print('printfromzego: ==========================================');
  }

  // Public method to manually trigger debug screen (for testing)
  void showDebugScreenManually() {
    print('printfromzego: MANUALLY TRIGGERING DEBUG SCREEN');
    
    // Check if PK battle is currently active
    final currentPkState = ZegoUIKitPrebuiltLiveStreamingController().pk.stateNotifier.value;
    print('printfromzego: Current PK State: $currentPkState');
    print('printfromzego: Is PK Battle Active: ${ZegoUIKitPrebuiltLiveStreamingController().pk.isInPK}');
    
    if (currentPkState == ZegoLiveStreamingPKBattleState.inPK || ZegoUIKitPrebuiltLiveStreamingController().pk.isInPK) {
      print('printfromzego: PK BATTLE IS ACTIVE - Triggering API call now!');
      
      // Create a mock event with current user info
      final localUser = ZegoUIKit().getLocalUser();
      final mockEvent = MockPKBattleEvent(
        fromHost: MockHost(name: localUser.name, id: localUser.id),
        requestID: 'manual_trigger_${DateTime.now().millisecondsSinceEpoch}',
      );
      
      // Trigger the API call
      _startPKBattleAPI(mockEvent);
    } else {
      print('printfromzego: No PK battle active - testing direct API call');
      
      // Test direct API call
      _testDirectApiCall();
    }
  }

  // Public method to force PK battle API call (for testing)
  void forcePKBattleApiCall() {
    print('printfromzego: FORCING PK BATTLE API CALL');
    
    // Create a mock event with current user info
    final localUser = ZegoUIKit().getLocalUser();
    final mockEvent = MockPKBattleEvent(
      fromHost: MockHost(name: localUser.name, id: localUser.id),
      requestID: 'force_trigger_${DateTime.now().millisecondsSinceEpoch}',
    );
    
    // Force the API call
    _startPKBattleAPI(mockEvent);
  }

  // Public method to manually trigger PK battle API call with current PK state
  void triggerPKBattleApiCall() {
    print('printfromzego: MANUALLY TRIGGERING PK BATTLE API CALL');
    
    // Check if PK battle is currently active
    final currentPkState = ZegoUIKitPrebuiltLiveStreamingController().pk.stateNotifier.value;
    final isInPK = ZegoUIKitPrebuiltLiveStreamingController().pk.isInPK;
    
    print('printfromzego: Current PK State: $currentPkState');
    print('printfromzego: Is PK Battle Active: $isInPK');
    
    if (isInPK || currentPkState == ZegoLiveStreamingPKBattleState.inPK) {
      print('printfromzego: PK BATTLE IS ACTIVE - Creating mock event and calling API');
      
      // Create a mock event with current user info
      final localUser = ZegoUIKit().getLocalUser();
      final mockEvent = MockPKBattleEvent(
        fromHost: MockHost(name: localUser.name, id: localUser.id),
        requestID: 'manual_trigger_${DateTime.now().millisecondsSinceEpoch}',
      );
      
      // Call the API
      _startPKBattleAPI(mockEvent);
    } else {
      print('printfromzego: No PK battle active - cannot trigger API call');
      
      if (context != null) {
        showDialog(
          context: context!,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('No PK Battle Active'),
              content: const Text('Please start a PK battle first before triggering the API call.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      }
    }
  }

  // Test method to directly call the API
  Future<void> _testDirectApiCall() async {
    print('printfromzego: TESTING DIRECT API CALL');
    
    try {
      // Get current user's username
      final currentUser = await ApiService.getCurrentUser();
      final username = currentUser['username'] ?? 'unknown';
      
      final result = await ApiService.getUserIdByUsername(username);
      print('printfromzego: Direct API call result for username $username: $result');
      
      if (context != null) {
        showDialog(
          context: context!,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('API Test Result'),
              content: Text('API call successful!\nUsername: $username\nUser ID: $result'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      print('printfromzego: Direct API call failed: $e');
      
      if (context != null) {
        showDialog(
          context: context!,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('API Test Failed'),
              content: Text('Error: $e'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      }
    }
  }

  // Test method to call PK Battle API using two different user IDs
  Future<void> testPKBattleApiWithCurlParams() async {
    print('printfromzego: TESTING PK BATTLE API WITH TWO USER IDs');
    
    try {
      // Get current user info (sender)
      final localUser = ZegoUIKit().getLocalUser();
      final localUserName = localUser.name;
      
      // Clean username
      final cleanLocalUserName = localUserName.startsWith('user_') 
          ? localUserName.substring(5) 
          : localUserName;
      
      // Get current user ID (sender)
      int? senderUserId = ApiService.currentUserId;
      if (senderUserId == null) {
        senderUserId = await ApiService.getUserIdByUsername(cleanLocalUserName);
      }
      
      if (senderUserId == null) {
        throw Exception('Could not get current user ID');
      }
      
      // For testing, get a different user ID as receiver
      // In real scenario, this would be the actual receiver's user ID from the Zego event
      final testReceiverUsername = 'testuser123'; // This would come from Zego event
      final receiverUserId = await ApiService.getUserIdByUsername(testReceiverUsername);
      
      if (receiverUserId == null) {
        throw Exception('Could not get receiver user ID');
      }
      
      print('printfromzego: Sender User ID: $senderUserId');
      print('printfromzego: Receiver User ID: $receiverUserId');
      print('printfromzego: Sender Username: $cleanLocalUserName');
      print('printfromzego: Receiver Username: $testReceiverUsername');
      
      final pkBattleId = await ApiService.startPKBattle(
        leftHostId: senderUserId,
        rightHostId: receiverUserId,
        leftStreamId: 0,
        rightStreamId: 0,
      );

      print('printfromzego: Test API Response - PK Battle ID: $pkBattleId');
      print('printfromzego: Test Parameters - Sender: $senderUserId, Receiver: $receiverUserId');

      if (context != null) {
        showDialog(
          context: context!,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('PK Battle API Test Result'),
              content: Text('PK Battle ID: $pkBattleId\nStatus: started\nSender ID: $senderUserId\nReceiver ID: $receiverUserId\nSender Username: $cleanLocalUserName\nReceiver Username: $testReceiverUsername'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      print('printfromzego: Test PK Battle API call failed: $e');
      
      if (context != null) {
        showDialog(
          context: context!,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('PK Battle API Test Failed'),
              content: Text('Error: $e'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      }
    }
  }

  // Helper method to get current live stream ID (if available)
  int? getCurrentLiveStreamId() {
    // This method should be implemented based on how you track the current live stream
    // You might need to store the live stream ID when starting a live stream
    // For now, return null to use default value
    return null;
  }

  // Helper method to validate PK battle parameters
  bool validatePKBattleParameters(int leftHostId, int rightHostId) {
    if (leftHostId <= 0 || rightHostId <= 0) {
      print('printfromzego: ERROR - Invalid host IDs: left=$leftHostId, right=$rightHostId');
      return false;
    }
    
    if (leftHostId == rightHostId) {
      print('printfromzego: ERROR - Left and right host IDs are the same: $leftHostId');
      return false;
    }
    
    return true;
  }

  // Helper method to create a simplified PK battle API call (for testing)
  Future<int?> createSimplePKBattle({
    required int leftHostId,
    required int rightHostId,
    int leftStreamId = 0,
    int rightStreamId = 0,
  }) async {
    try {
      if (!validatePKBattleParameters(leftHostId, rightHostId)) {
        return null;
      }
      
      final pkBattleId = await ApiService.startPKBattle(
        leftHostId: leftHostId,
        rightHostId: rightHostId,
        leftStreamId: leftStreamId,
        rightStreamId: rightStreamId,
      );
      
      if (pkBattleId != null) {
        await ApiService.savePKBattleId(pkBattleId);
        print('printfromzego: Simple PK Battle created successfully: $pkBattleId');
      }
      
      return pkBattleId;
    } catch (e) {
      print('printfromzego: Error creating simple PK battle: $e');
      return null;
    }
  }
}

// Mock classes for manual testing
class MockHost {
  final String name;
  final String id;
  
  MockHost({required this.name, required this.id});
}

class MockPKBattleEvent {
  final MockHost fromHost;
  final String requestID;
  
  MockPKBattleEvent({required this.fromHost, required this.requestID});
}