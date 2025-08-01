import 'package:flutter/material.dart';
import 'package:finalchat/pk_widgets/config.dart';
import 'package:zego_uikit_prebuilt_live_streaming/zego_uikit_prebuilt_live_streaming.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';
import 'package:finalchat/common.dart';
import 'package:finalchat/constants.dart';
import 'package:finalchat/pk_widgets/events.dart';
import 'package:finalchat/pk_widgets/widgets/mute_button.dart';
import 'package:finalchat/pk_widgets/surface.dart';
import 'dart:math';
import 'dart:async';
import 'package:finalchat/screens/main/store_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:zego_uikit/zego_uikit.dart';
import 'dart:convert';
import 'package:finalchat/services/api_service.dart';
import 'package:finalchat/screens/live/gift_animation.dart';
import 'package:finalchat/pk_widgets/widgets/pk_battle_notification.dart';
import 'package:finalchat/pk_widgets/widgets/pk_battle_timer.dart';
import 'package:finalchat/pk_widgets/widgets/pk_battle_progress_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pk_battle_debug_screen.dart';

class LivePage extends StatefulWidget {
  final String liveID;
  final String localUserID;
  final bool isHost;
  final String? profilePic;
  final int receiverId; // <-- add this
  final VoidCallback? onGiftButtonPressed;
  final Map<String, dynamic>? activePKBattle; // Add this parameter

  const LivePage({
    Key? key,
    required this.liveID,
    required this.localUserID,
    required this.receiverId, // <-- add this
    this.isHost = false,
    this.profilePic,
    this.onGiftButtonPressed,
    this.activePKBattle, // Add this parameter
  }) : super(key: key);

  @override
  State<LivePage> createState() => _LivePageState();
}

class _LivePageState extends State<LivePage>
    with SingleTickerProviderStateMixin {
  final liveStateNotifier = ValueNotifier<ZegoLiveStreamingState>(
    ZegoLiveStreamingState.idle,
  );

  final requestingHostsMapRequestIDNotifier =
      ValueNotifier<Map<String, List<String>>>({});
  final requestIDNotifier = ValueNotifier<String>('');
  PKEvents? pkEvents;

  // Like animation state
  late AnimationController _likeController;
  late Animation<double> _likeScale;
  bool _showLike = false;
  List<Widget> _burstHearts = [];
  int _burstKey = 0;

  List<dynamic> _gifts = [];
  bool _giftsLoading = true;
  Map<String, dynamic>? _currentUser;
  bool _sendingGift = false;
  List<Widget> _activeGiftAnimations = [];
  int _giftAnimKey = 0;
  
  // PK Battle notification state
  bool _showPKBattleNotification = false;
  String _pkBattleMessage = '';
  String? _leftHostId;
  String? _rightHostId;
  String? _leftHostName;
  String? _rightHostName;
  String? _liveId;
  String? _pkBattleId;
  
  // PK Battle timer state
  bool _showPKBattleTimer = false;
  
  // Debug/Info display state
  bool _showDebugInfo = false;
  Map<String, dynamic> _debugInfo = {};
  List<String> _apiLogs = [];
  
  // Custom logger for capturing API logs
  static List<String> _globalApiLogs = [];
  static Function(String)? _onLogAdded;

  @override
  void initState() {
    super.initState();

    // Set up log callback to capture API logs
    _setLogCallback();

    // Initialize debug info
    _updateDebugInfo('is_host', widget.isHost);
    _updateDebugInfo('live_id', widget.liveID);
    _updateDebugInfo('local_user_id', widget.localUserID);
    _updateDebugInfo('receiver_id', widget.receiverId);
    _updateDebugInfo('has_active_pk_battle', widget.activePKBattle != null);

    // Extract stream ID from liveID for audience
    // Extract stream ID for both hosts and audience
    if (widget.liveID.startsWith('live_')) {
      final parts = widget.liveID.split('_');
      if (parts.length >= 2) {
        final streamId = int.tryParse(parts[1]);
        if (streamId != null) {
          _updateDebugInfo('stream_id', streamId);
          _logApiCall('Stream ID Extraction', 'Extracted stream ID: $streamId from liveID: ${widget.liveID}');
          debugPrint('🎯 STREAM ID EXTRACTED: $streamId for ${widget.isHost ? "HOST" : "AUDIENCE"}');
        } else {
          _logApiCall('Stream ID Extraction', 'Failed to parse stream ID from: ${parts[1]}');
          debugPrint('❌ Failed to parse stream ID from: ${parts[1]}');
        }
      } else {
        _logApiCall('Stream ID Extraction', 'Invalid liveID format: ${widget.liveID}');
        debugPrint('❌ Invalid liveID format: ${widget.liveID}');
      }
    } else {
      debugPrint('❌ LiveID does not start with "live_": ${widget.liveID}');
    }

    pkEvents = PKEvents(
      context: context,
      requestIDNotifier: requestIDNotifier,
      requestingHostsMapRequestIDNotifier: requestingHostsMapRequestIDNotifier,
      onPKBattleNotification: _handlePKBattleNotification,
      onPKBattleAccepted: _handlePKBattleAccepted,
      onPKBattleAutoEnded: _handlePKBattleAutoEnded,
    );

    // Initialize PK battle state if audience joins with active PK battle
    if (widget.activePKBattle != null && !widget.isHost) {
      debugPrint('🎮 Audience joining with active PK battle: ${widget.activePKBattle!['id']}');
      _logApiCall('Active PK Battle', 'Found active PK battle: ${widget.activePKBattle!['id']}');
      _updateDebugInfo('active_pk_battle_data', widget.activePKBattle);
      
      PKEvents.setCurrentPKBattleId(widget.activePKBattle!['id']);
      _pkBattleId = widget.activePKBattle!['id']?.toString();
      if (widget.activePKBattle!['start_time'] != null) {
        final serverStartTime = DateTime.parse(widget.activePKBattle!['start_time']);
        PKEvents.setCurrentPKBattleStartTime(serverStartTime);
        debugPrint('⏰ PK battle start time: $serverStartTime');
        _updateDebugInfo('pk_battle_start_time', serverStartTime.toString());
      }
      
      // Set host information for audience
      setState(() {
        _leftHostId = widget.activePKBattle!['left_host_id']?.toString();
        _rightHostId = widget.activePKBattle!['right_host_id']?.toString();
        _showPKBattleTimer = true;
      });
      
      _updateDebugInfo('left_host_id', widget.activePKBattle!['left_host_id']);
      _updateDebugInfo('right_host_id', widget.activePKBattle!['right_host_id']);
    } else {
      // For both hosts and audience without pre-loaded PK battle, fetch it immediately
      debugPrint('🎮 ${widget.isHost ? "Host" : "Audience"} joining - fetching PK battle data...');
      _logApiCall('${widget.isHost ? "Host" : "Audience"} Join', 'Fetching PK battle data');
      
      // Fetch PK battle data with delay to allow backend to create PK battle
      Future.delayed(Duration(seconds: 2), () {
        _fetchPKBattleDataFromServer();
      });
    }

    // Check if there's an active PK battle when joining
    _checkActivePKBattle();
    
    // Start a timer to periodically check for PK battle ID if not available (using stream ID only)
    Timer.periodic(Duration(seconds: 2), (timer) {
      if (_pkBattleId == null && PKEvents.currentPKBattleId == null && _showPKBattleTimer) {
        debugPrint('🔄 Periodic check: PK battle ID still not available, fetching by stream ID...');
        _fetchPKBattleIdByStreamId();
      } else if (_pkBattleId != null || PKEvents.currentPKBattleId != null) {
        if (widget.isHost) {
          // For hosts, stop timer once PK battle ID is found
          debugPrint('✅ Periodic check: PK battle ID found, stopping timer for host');
          timer.cancel();
        } else {
          // For audience, keep timer running to maintain PK battle data
          debugPrint('🔄 Periodic check: PK battle ID found, keeping timer running for audience');
        }
      }
    });

    // Listen to live state changes to show/hide timer
    liveStateNotifier.addListener(_onLiveStateChanged);

    _likeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _likeScale = Tween<double>(
      begin: 0.0,
      end: 1.5,
    ).chain(CurveTween(curve: Curves.elasticOut)).animate(_likeController);
    _likeController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Future.delayed(const Duration(milliseconds: 300), () {
          _likeController.reverse();
        });
      }
    });
    _fetchGiftsAndUser();
  }

  Future<void> _fetchGiftsAndUser() async {
    setState(() {
      _giftsLoading = true;
    });
    try {
      _logApiCall('getGifts', 'Fetching gifts...');
      final gifts = await ApiService.getGifts();
      _logApiCall('getGifts', 'Success: ${gifts.length} gifts fetched');
      _updateDebugInfo('gifts_count', gifts.length);
      
      _logApiCall('getCurrentUser', 'Fetching current user...');
      final user = await ApiService.getCurrentUser();
      _logApiCall('getCurrentUser', 'Success: User ${user['username']} fetched');
      _updateDebugInfo('current_user', {
        'id': user['id'],
        'username': user['username'],
        'diamonds': user['diamonds'],
        'first_name': user['first_name'],
        'last_name': user['last_name'],
      });
      
      setState(() {
        _gifts = gifts;
        _currentUser = user;
        _giftsLoading = false;
      });
    } catch (e) {
      _logApiCall('Error', 'Failed to fetch data: $e');
      setState(() {
        _giftsLoading = false;
      });
    }
  }

  Future<void> _sendGiftFromList(dynamic gift) async {
    if (_sendingGift) return;
    if (_currentUser == null) return;
    if (_currentUser!['diamonds'] < gift['diamond_amount']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Not enough diamonds!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check if we're in PK battle mode
    final isPKBattle =
        liveStateNotifier.value == ZegoLiveStreamingState.inPKBattle;

    if (isPKBattle && !widget.isHost) {
      // Show host selection dialog for PK battle
      final selectedHost = await _showHostSelectionDialog();
      if (selectedHost == null) return; // User cancelled

      await _sendGiftToHost(gift, selectedHost);

      // Update PK progress bar diamond count
      _updatePKDiamondCount(selectedHost, gift['diamond_amount']);
    } else {
      // Normal gift sending (not in PK battle or host sending)
      await _sendGiftToHost(gift, widget.receiverId);
    }
  }

  Future<void> _sendGiftToHost(dynamic gift, int receiverId) async {
    setState(() {
      _sendingGift = true;
      _currentUser!['diamonds'] -= gift['diamond_amount'];
    });
    try {
      bool success = false;
      
      // Check if we're in PK battle mode
      final isPKBattle = liveStateNotifier.value == ZegoLiveStreamingState.inPKBattle;
      
      if (isPKBattle && PKEvents.currentPKBattleId != null) {
        // Send gift for PK battle
        final senderId = _currentUser?['id'];
        if (senderId != null) {
          success = await ApiService.sendPKBattleGift(
            pkBattleId: PKEvents.currentPKBattleId!,
            senderId: senderId,
            receiverId: receiverId,
            giftId: gift['id'],
            amount: gift['diamond_amount'],
          );
        }
      } else {
        // Normal gift sending
        success = await ApiService.sendGift(
          receiverId: receiverId,
          giftId: gift['id'],
          liveStreamId: int.tryParse(widget.liveID) ?? 0,
          liveStreamType: widget.isHost ? 'host' : 'audience',
        );
      }
      
      if (success) {
        // Send ZEGOCLOUD in-room command for gift notification
        final message = jsonEncode({
          "type": "gift",
          "sender_id": _currentUser?['id'],
          "sender_name": _currentUser?['first_name'] ?? 'User',
          "gift_id": gift['id'],
          "gift_name": gift['name'],
          "gift_amount": gift['diamond_amount'],
          "gif_filename": gift['gif_filename'],
          "timestamp": DateTime.now().millisecondsSinceEpoch,
        });
        await ZegoUIKit().sendInRoomCommand(widget.liveID, [message]);

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${gift['name']} sent successfully!'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
        // Trigger gift animation (same as gift panel)
        final gifUrl =
            'https://server.bharathchat.com/uploads/gifts/' +
            gift['gif_filename'];
        final senderName = _currentUser?['first_name'] ?? 'User';
        setState(() {
          _activeGiftAnimations.add(
            GiftAnimation(
              key: ValueKey('gift_anim_${_giftAnimKey++}'),
              giftName: gift['name'],
              gifUrl: gifUrl,
              senderName: senderName,
              onAnimationComplete: () {
                setState(() {
                  _activeGiftAnimations.removeWhere(
                    (w) =>
                        (w.key as ValueKey).value ==
                        'gift_anim_${_giftAnimKey - 1}',
                  );
                });
              },
            ),
          );
        });
        // Optionally: refresh user data
        setState(() {});
      } else {
        throw Exception('Gift send failed');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending gift: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      setState(() {
        _sendingGift = false;
      });
    }
  }

  Future<int?> _showHostSelectionDialog() async {
    return await showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Choose Host',
            style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Which host would you like to send the gift to?',
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Colors.blue.withOpacity(0.2),
                foregroundColor: Colors.blue,
                side: BorderSide(color: Colors.blue),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => Navigator.of(context).pop(1), // Host 1
              child: const Text(
                'Host 1',
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Colors.pink.withOpacity(0.2),
                foregroundColor: Colors.pink,
                side: BorderSide(color: Colors.pink),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => Navigator.of(context).pop(2), // Host 2
              child: const Text(
                'Host 2',
                style: TextStyle(
                  color: Colors.pink,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.grey,
                side: BorderSide(color: Colors.grey),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => Navigator.of(context).pop(null), // Cancel
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showGiftConfirmationDialog(
    dynamic gift,
    VoidCallback onConfirm,
  ) async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Send Gift',
            style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Do you want to send "${gift['name']}"?',
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.orange,
                side: BorderSide(color: Colors.orange),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.orange),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                onConfirm();
              },
              child: const Text('Send', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    liveStateNotifier.removeListener(_onLiveStateChanged);
    _likeController.dispose();
    super.dispose();
  }

  void _updatePKDiamondCount(int hostNumber, int diamonds) {
    // This method will be called when gifts are sent during PK battles
    // The surface widget will handle the actual diamond count updates
    // For now, we'll just log the update
    print('PK Battle: Host $hostNumber received $diamonds diamonds');
  }

  void _logApiCall(String apiName, String details) {
    final timestamp = DateTime.now().toString().substring(11, 19);
    final logEntry = '[$timestamp] $apiName: $details';
    setState(() {
      _apiLogs.add(logEntry);
      if (_apiLogs.length > 50) {
        _apiLogs.removeAt(0); // Keep only last 50 logs
      }
    });
    debugPrint(logEntry);
  }
  
  // Static method to capture API logs from anywhere
  static void captureApiLog(String logMessage) {
    final timestamp = DateTime.now().toString().substring(11, 19);
    final logEntry = '[$timestamp] $logMessage';
    _globalApiLogs.add(logEntry);
    
    // Keep only last 100 logs to prevent memory issues
    if (_globalApiLogs.length > 100) {
      _globalApiLogs.removeAt(0);
    }
    
    // Notify listeners if callback is set
    if (_onLogAdded != null) {
      _onLogAdded!(logEntry);
    }
    
    // Also print to console
    debugPrint(logEntry);
  }
  
  // Set callback for when new logs are added
  void _setLogCallback() {
    _LivePageState._onLogAdded = (String logEntry) {
      if (mounted) {
        setState(() {
          _apiLogs.add(logEntry);
          if (_apiLogs.length > 100) {
            _apiLogs.removeAt(0);
          }
        });
      }
    };
    
    // Set up the API logger callback
    try {
      LivePageLogger.captureLog = (String message) {
        if (mounted) {
          setState(() {
            _apiLogs.add(message);
            if (_apiLogs.length > 100) {
              _apiLogs.removeAt(0);
            }
          });
        }
      };
    } catch (e) {
      debugPrint('Failed to set up API logger: $e');
    }
  }
  
  // Get all captured logs
  List<String> get _allApiLogs {
    final allLogs = <String>[];
    allLogs.addAll(_apiLogs);
    allLogs.addAll(_LivePageState._globalApiLogs);
    return allLogs;
  }

  void _updateDebugInfo(String key, dynamic value) {
    setState(() {
      _debugInfo[key] = value;
    });
  }

  Widget _buildInfoSection(String title, Map<String, String> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.orange,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: data.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Row(
                  children: [
                    SizedBox(
                      width: 80,
                      child: Text(
                        '${entry.key}:',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        entry.value,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  void _handlePKBattleNotification(String message, {
    String? leftHostId,
    String? rightHostId,
    String? leftHostName,
    String? rightHostName,
    String? liveId,
    String? pkBattleId,
  }) {
    debugPrint('🎯 Received PK battle notification: $message');
    debugPrint('🎯 PK Battle ID from notification: $pkBattleId');
    debugPrint('🎯 Current PKEvents PK Battle ID: ${PKEvents.currentPKBattleId}');
    
    setState(() {
      _showPKBattleNotification = true;
      _pkBattleMessage = message;
      _leftHostId = leftHostId;
      _rightHostId = rightHostId;
      _leftHostName = leftHostName;
      _rightHostName = rightHostName;
      _liveId = liveId;
      
      // Update PK battle ID - prioritize the one from notification, then from PKEvents
      _pkBattleId = pkBattleId ?? PKEvents.currentPKBattleId?.toString();
      debugPrint('🎯 Final PK Battle ID set to: $_pkBattleId');
      
      // Show timer when PK battle starts
      if (message.contains('Started')) {
        _showPKBattleTimer = true;
      } else if (message.contains('Ended')) {
        _showPKBattleTimer = false;
      }
    });
  }

  void _handlePKBattleAccepted(String leftHostId, String rightHostId, String leftHostName, String rightHostName, String liveId) async {
    debugPrint('=== PK BATTLE ACCEPTED ===');
    debugPrint('LeftHostId: $leftHostId, RightHostId: $rightHostId');
    debugPrint('LeftHostName: $leftHostName, RightHostName: $rightHostName');
    debugPrint('LiveId: $liveId');
    debugPrint('Current user ID: ${ZegoUIKit().getLocalUser().id}');
    
    // Store the host information
    setState(() {
      _leftHostId = leftHostId;
      _rightHostId = rightHostId;
      _leftHostName = leftHostName;
      _rightHostName = rightHostName;
      _liveId = liveId;
    });
    
    debugPrint('Stored names - Left: $_leftHostName, Right: $_rightHostName');
    
    // PK battle ID will be fetched by stream ID in the periodic timer
    debugPrint('🎯 PK battle ID will be fetched by stream ID in periodic timer');
  }

  void _handlePKBattleAutoEnded(int winnerId, String reason) {
    debugPrint('🚨 PK BATTLE AUTO-ENDED ===');
    debugPrint('Winner ID: $winnerId');
    debugPrint('Reason: $reason');
    
    // Clear PK battle data and hide timer
    setState(() {
      _showPKBattleTimer = false;
      _pkBattleId = null;
    });
    
    // Clear PKEvents data
    PKEvents.setCurrentPKBattleId(null);
    PKEvents.setCurrentPKBattleStartTime(null);
    
    debugPrint('🎯 PK battle data cleared due to auto-end');
  }

  void _hidePKBattleNotification() {
    setState(() {
      _showPKBattleNotification = false;
      _pkBattleMessage = '';
      _leftHostId = null;
      _rightHostId = null;
      _leftHostName = null;
      _rightHostName = null;
      _liveId = null;
      _pkBattleId = null;
    });
  }

  void _fetchPKBattleIdByStreamId() async {
    debugPrint('🔄 Fetching PK battle ID by stream ID...');
    try {
      // Get stream ID from debug info
      final streamId = _debugInfo['stream_id'];
      if (streamId != null) {
        debugPrint('🎯 Using stream ID: $streamId');
        
        // Add 2-second delay as requested
        await Future.delayed(Duration(seconds: 2));
        
        final pkBattle = await ApiService.getActivePKBattleByStreamId(streamId);
        if (pkBattle != null) {
          debugPrint('✅ Stream ID fetch found PK battle: ${pkBattle['pk_battle_id']}');
          PKEvents.setCurrentPKBattleId(pkBattle['pk_battle_id']);
          setState(() {
            _pkBattleId = pkBattle['pk_battle_id']?.toString();
            // For audience, also update host information and show timer
            if (!widget.isHost) {
              _leftHostId = pkBattle['left_host_id']?.toString();
              _rightHostId = pkBattle['right_host_id']?.toString();
              _showPKBattleTimer = true;
            }
          });
          debugPrint('🎯 Updated PK battle ID to: $_pkBattleId');
          
          // Update start time if available
          if (pkBattle['start_time'] != null) {
            final serverStartTime = DateTime.parse(pkBattle['start_time']);
            PKEvents.setCurrentPKBattleStartTime(serverStartTime);
            debugPrint('⏰ Updated PK battle start time: $serverStartTime');
          }
        } else {
          debugPrint('❌ No PK battle found for stream ID: $streamId');
        }
      } else {
        debugPrint('❌ Stream ID not available in debug info');
      }
    } catch (e) {
      debugPrint('❌ Error in stream ID PK battle fetch: $e');
    }
  }

  void _checkActivePKBattle() {
    // Check if there's an active PK battle when user joins
    if (PKEvents.currentPKBattleStartTime != null) {
      final now = DateTime.now();
      final battleEndTime = PKEvents.currentPKBattleStartTime!.add(const Duration(minutes: 3));
      
      if (now.isBefore(battleEndTime)) {
        setState(() {
          _showPKBattleTimer = true;
        });
      }
    }
  }

  void _onLiveStateChanged() {
    final liveState = liveStateNotifier.value;
    debugPrint('🎬 Live state changed to: $liveState');
    
    if (liveState == ZegoLiveStreamingState.inPKBattle) {
      debugPrint('🎮 Entering PK battle state...');
      setState(() {
        _showPKBattleTimer = true;
      });
      
      // Set start time if not already set
      if (PKEvents.currentPKBattleStartTime == null) {
        PKEvents.setCurrentPKBattleStartTime(DateTime.now());
        debugPrint('⏰ Set local start time: ${PKEvents.currentPKBattleStartTime}');
      }
      
      // Fetch PK battle ID if not available (with 2-second delay for backend timing)
      if (PKEvents.currentPKBattleId == null) {
        Future.delayed(Duration(seconds: 2), () {
          _fetchPKBattleDataFromServer();
        });
      }
    } else {
      debugPrint('🏁 Exiting PK battle state...');
      // Don't hide timer or clear PK battle data - keep them persistent for audience
      if (widget.isHost) {
        // Only clear for hosts, not for audience
        setState(() {
          _showPKBattleTimer = false;
        });
        
        // Clear PK battle data when exiting (only for hosts)
        PKEvents.setCurrentPKBattleId(null);
        setState(() {
          _pkBattleId = null;
        });
        PKEvents.setCurrentPKBattleStartTime(null);
      } else {
        // For audience, keep the timer and PK battle data persistent
        debugPrint('🎯 Keeping PK battle timer and data persistent for audience');
      }
    }
  }
  
  void _fetchPKBattleDataFromServer() async {
    debugPrint('🔍 Fetching PK battle data from server...');
    _logApiCall('PK Battle', 'Fetching PK battle data...');
    
    try {
      // Use stream ID for both hosts and audience
      final streamId = _debugInfo['stream_id'];
      
      if (streamId != null) {
        _logApiCall('getActivePKBattleByStreamId', 'Calling API with stream ID: $streamId');
        
        debugPrint('🔍 Fetching PK battle for stream: $streamId');
        final pkBattle = await ApiService.getActivePKBattleByStreamId(streamId);
          
        if (pkBattle != null) {
          _logApiCall('getActivePKBattleByStreamId', 'Success: PK Battle ${pkBattle['pk_battle_id']} found');
          _updateDebugInfo('pk_battle', pkBattle);
          
          // Set PK battle ID and start time
          debugPrint('🔧 Setting PK Battle ID: ${pkBattle['pk_battle_id']}');
          PKEvents.setCurrentPKBattleId(pkBattle['pk_battle_id']);
          debugPrint('🔧 PK Battle ID set to: ${PKEvents.currentPKBattleId}');
          
          // Update local state for UI reactivity
          setState(() {
            _pkBattleId = pkBattle['pk_battle_id']?.toString();
          });
          
          if (pkBattle['start_time'] != null) {
            final serverStartTime = DateTime.parse(pkBattle['start_time']);
            PKEvents.setCurrentPKBattleStartTime(serverStartTime);
            debugPrint('⏰ Server start time: $serverStartTime');
            debugPrint('⏰ End time will be: ${serverStartTime.add(Duration(minutes: 3))}');
            _updateDebugInfo('pk_battle_start_time', serverStartTime.toString());
          }
          
          // Set host information for both hosts and audience
          setState(() {
            _leftHostId = pkBattle['left_host_id']?.toString();
            _rightHostId = pkBattle['right_host_id']?.toString();
            _showPKBattleTimer = true;
          });
          
          // Update debug info with both hosts
          _updateDebugInfo('left_host_id', pkBattle['left_host_id']);
          _updateDebugInfo('right_host_id', pkBattle['right_host_id']);
          _updateDebugInfo('left_score', pkBattle['left_score']);
          _updateDebugInfo('right_score', pkBattle['right_score']);
          _updateDebugInfo('left_stream_id', pkBattle['left_stream_id']);
          _updateDebugInfo('right_stream_id', pkBattle['right_stream_id']);
          _updateDebugInfo('pk_battle_status', pkBattle['status']);
          
          debugPrint('✅ Got PK battle data from server: ${pkBattle['pk_battle_id']}');
          debugPrint('✅ Left Host ID: ${pkBattle['left_host_id']}, Right Host ID: ${pkBattle['right_host_id']}');
          debugPrint('✅ Left Score: ${pkBattle['left_score']}, Right Score: ${pkBattle['right_score']}');
          
          setState(() {}); // Refresh UI to show progress bar and timer
        } else {
          _logApiCall('getActivePKBattleByStreamId', 'No active PK battle found for stream: $streamId');
          debugPrint('❌ No active PK battle found for stream: $streamId');
        }
      } else {
        _logApiCall('Error', 'Stream ID not available');
        debugPrint('❌ Stream ID not available');
      }
    } catch (e) {
      _logApiCall('Error', 'Failed to fetch PK battle data: $e');
      debugPrint('❌ Error fetching PK battle data: $e');
    }
  }

  void _triggerLike() {
    setState(() {
      _burstKey++;
      _burstHearts = List.generate(
        5,
        (i) => AnimatedHeart(
          key: ValueKey('heart_$_burstKey$i'),
          delay: Duration(milliseconds: i * 80),
          random: Random(),
        ),
      );
    });
    // Remove hearts after animation
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _burstHearts = []);
    });
  }

  Future<void> _onPKBattleTimerEnd() async {
    if (PKEvents.currentPKBattleId == null) return;
    final pkBattleId = PKEvents.currentPKBattleId!;
    final result = await ApiService.getPKBattleById(pkBattleId);
    if (result == null) return;

    final leftScore = result['left_score'] ?? 0;
    final rightScore = result['right_score'] ?? 0;
    int winnerId;
    if (leftScore > rightScore) {
      winnerId = result['left_host_id'];
    } else if (rightScore > leftScore) {
      winnerId = result['right_host_id'];
    } else {
      winnerId = 0; // Draw
    }

    final endResult = await ApiService.endPKBattle(
      pkBattleId: pkBattleId,
      leftScore: leftScore,
      rightScore: rightScore,
      winnerId: winnerId,
    );

    // Show popup
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('PK Battle Ended'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Winner: '
                + (winnerId == 0
                  ? 'Draw'
                  : (winnerId == (result['left_host_id'])
                      ? (_leftHostName ?? _leftHostId ?? 'Left')
                      : (_rightHostName ?? _rightHostId ?? 'Right')))),
              const SizedBox(height: 12),
              Text('Final Scores:\n'
                '${_leftHostName ?? _leftHostId ?? 'Left'}: $leftScore\n'
                '${_rightHostName ?? _rightHostId ?? 'Right'}: $rightScore'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final config =
        (widget.isHost
            ? (ZegoUIKitPrebuiltLiveStreamingConfig.host(
                plugins: [ZegoUIKitSignalingPlugin()],
              )
              ..foreground = PKV2Surface(
                requestIDNotifier: requestIDNotifier,
                liveStateNotifier: liveStateNotifier,
                requestingHostsMapRequestIDNotifier:
                    requestingHostsMapRequestIDNotifier,
              ))
            : ZegoUIKitPrebuiltLiveStreamingConfig.audience(
              plugins: [ZegoUIKitSignalingPlugin()],
            ));

    config.avatarBuilder =
        (context, size, user, extraInfo) => customAvatarBuilder(
          context,
          size,
          user,
          extraInfo,
          profilePic: widget.profilePic,
        );
    config.audioVideoView.foregroundBuilder = foregroundBuilder;
    // If pkBattle is not a valid property, comment or remove the next line
    // config.pkBattle = pkConfig();
    config.topMenuBar.buttons = [
      ZegoLiveStreamingMenuBarButtonName.minimizingButton,
    ];

    // Add virtual gift, like, and diamond buttons for both host and audience
    final double buttonSize = 38; // Reduced size for all three
    // Gradient for circular buttons
    final Gradient buttonGradient = const SweepGradient(
      colors: [
        Color(0xFFffa030),
        Color(0xFFfe9b00),
        Color(0xFFf67d00),
        Color(0xFFffa030), // To complete the sweep
      ],
      startAngle: 0.0,
      endAngle: 3.14 * 2,
      center: Alignment.center,
    );
    final giftButton = ZegoMenuBarExtendButton(
      index: 0,
      child: Container(
        width: buttonSize,
        height: buttonSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: buttonGradient,
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            shape: const CircleBorder(),
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            padding: EdgeInsets.zero,
            minimumSize: Size(buttonSize, buttonSize),
            maximumSize: Size(buttonSize, buttonSize),
            elevation: 0,
          ),
          onPressed: () {
            if (widget.onGiftButtonPressed != null) {
              widget.onGiftButtonPressed!();
            } else {
              print('Gift button pressed');
            }
          },
          child: const Icon(Icons.card_giftcard, color: Colors.white, size: 22),
        ),
      ),
    );

    final likeButton = ZegoMenuBarExtendButton(
      index: 1,
      child: GestureDetector(
        onTap: _triggerLike,
        child: Container(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
          width: buttonSize,
          height: buttonSize,
          alignment: Alignment.center,
          child: const Icon(Icons.favorite, color: Colors.pink, size: 22),
        ),
      ),
    );

    final diamondButton = ZegoMenuBarExtendButton(
      index: 2,
      child: GestureDetector(
        onTap: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (context) => const StoreScreen()));
        },
        child: Container(
          width: buttonSize,
          height: buttonSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: buttonGradient,
          ),
          alignment: Alignment.center,
          child: Image.asset(
            'assets/diamond.png',
            width: 22,
            height: 22,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );

    if (widget.isHost) {
      config.bottomMenuBar.hostExtendButtons = [
        // No gift, like, or diamond buttons for host
      ];
    } else {
      config.bottomMenuBar.audienceExtendButtons = [
        giftButton,
        likeButton,
        diamondButton,
      ];
    }

    return SafeArea(
      child: Scaffold(
        body: Stack(
          children: [
            ZegoUIKitPrebuiltLiveStreaming(
              appID: 615877954, // input your AppID
              appSign:
                  '12e07321bd8231dda371ea9235e274178403bd97a7ccabcb09e22474c42da3a4',
              userID: widget.localUserID,
              userName: 'user_${widget.localUserID}',
              liveID: widget.liveID,
              config: config,
              events: ZegoUIKitPrebuiltLiveStreamingEvents(
                pk: pkEvents?.event,
                onStateUpdated: (state) {
                  liveStateNotifier.value = state;
                },
                onLeaveConfirmation: (
                  ZegoLiveStreamingLeaveConfirmationEvent event,
                  Future<bool> Function() defaultAction,
                ) async {
                  return await showDialog<bool>(
                        context: context,
                        barrierDismissible: false,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            backgroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            title: const Text(
                              "Leave the room",
                              style: TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            content: const Text(
                              "Are you sure you want to leave the live room?",
                              style: TextStyle(color: Colors.white),
                            ),
                            actions: [
                              TextButton(
                                style: TextButton.styleFrom(
                                  backgroundColor: Colors.black,
                                  foregroundColor: Colors.orange,
                                  side: const BorderSide(color: Colors.orange),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onPressed:
                                    () => Navigator.of(context).pop(false),
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(color: Colors.orange),
                                ),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onPressed:
                                    () => Navigator.of(context).pop(true),
                                child: const Text(
                                  'Leave',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          );
                        },
                      ) ??
                      false;
                },
              ),
            ),
            // PK Battle notification overlay
            if (_showPKBattleNotification)
              Positioned(
                top: 50,
                left: 0,
                right: 0,
                child: PKBattleNotification(
                  message: _pkBattleMessage,
                  onDismiss: _hidePKBattleNotification,
                  leftHostId: _leftHostId,
                  rightHostId: _rightHostId,
                  leftHostName: _leftHostName,
                  rightHostName: _rightHostName,
                  liveId: _liveId,
                  pkBattleId: _pkBattleId,
                ),
              ),
            // PK Battle timer overlay
            if (_showPKBattleTimer)
              Positioned(
                bottom: 120,
                left: 0,
                right: 0,
                child: Center(
                  child: PKEvents.currentPKBattleStartTime != null
                    ? PKBattleTimer(
                        battleStartTime: PKEvents.currentPKBattleStartTime!,
                        onTimerEnd: _onPKBattleTimerEnd,
                      )
                    : Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF4CAF50), Color(0xFFFFEB3B), Color(0xFF4CAF50)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Loading Timer...',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                ),
              ),
            // PK Battle progress bar overlay
            if (_showPKBattleTimer)
              Positioned(
                bottom: 200,
                left: 0,
                right: 0,
                child: Center(
                  child: Builder(
                    builder: (context) {
                      debugPrint('Progress Bar - LeftName: $_leftHostName, RightName: $_rightHostName, PKID: ${PKEvents.currentPKBattleId}');
                      return PKEvents.currentPKBattleId != null
                        ? PKBattleProgressBar(
                            pkBattleId: PKEvents.currentPKBattleId!,
                            leftHostName: _leftHostName,
                            rightHostName: _rightHostName,
                          )
                        : Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: Colors.yellow, width: 2),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _leftHostName ?? 'Left',
                                        textAlign: TextAlign.left,
                                        style: const TextStyle(
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Center(
                                        child: Text(
                                          'PK: ${PKEvents.currentPKBattleId ?? "..."}',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            color: Colors.yellow,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        _rightHostName ?? 'Right',
                                        textAlign: TextAlign.right,
                                        style: const TextStyle(
                                          color: Colors.orange,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  height: 18,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(9),
                                    color: Colors.grey[800],
                                  ),
                                  child: const Row(
                                    children: [
                                      Expanded(
                                        child: Center(
                                          child: Text(
                                            '0',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Center(
                                          child: Text(
                                            '0',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                    },
                  ),
                ),
              ),
            // PK Battle ID display (separate, big, at 300px)
            if (_showPKBattleTimer)
              Positioned(
                bottom: 300,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4CAF50), Color(0xFFFFEB3B), Color(0xFF4CAF50)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      'PK Battle ID: ${_pkBattleId ?? PKEvents.currentPKBattleId ?? "Loading..."}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
              ),
            // Burst hearts overlay (audience only)
            if (!widget.isHost)
              ..._burstHearts.map(
                (w) => Positioned(
                  bottom: 80,
                  left:
                      MediaQuery.of(context).size.width / 2 -
                      20 +
                      (Random().nextDouble() * 40 - 20),
                  child: w,
                ),
              ),
            // Horizontal gift list above the bottom buttons (audience only)
            if (!widget.isHost && !_giftsLoading && _gifts.isNotEmpty)
              Positioned(
                left: 0,
                right: 0,
                bottom: 100, // Moved higher above the bottom bar
                child: SizedBox(
                  height: 56, // keep height
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _gifts.length,
                    separatorBuilder:
                        (context, idx) => const SizedBox(width: 12),
                    itemBuilder: (context, idx) {
                      final gift = _gifts[idx];
                      final canAfford =
                          _currentUser != null &&
                          _currentUser!['diamonds'] >= gift['diamond_amount'];
                      return GestureDetector(
                        onTap:
                            canAfford && !_sendingGift
                                ? () => _showGiftConfirmationDialog(
                                  gift,
                                  () => _sendGiftFromList(gift),
                                )
                                : null,
                        child: Opacity(
                          opacity: canAfford ? 1.0 : 0.5,
                          child: Container(
                            width: 48,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(12),
                              // No border
                            ),
                            padding: const EdgeInsets.all(4),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: CachedNetworkImage(
                                    imageUrl:
                                        'https://server.bharathchat.com/uploads/gifts/' +
                                        gift['gif_filename'],
                                    width: 28,
                                    height: 28,
                                    fit: BoxFit.cover,
                                    placeholder:
                                        (context, url) => Container(
                                          color: Colors.grey[700],
                                          child: const Icon(
                                            Icons.card_giftcard,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                        ),
                                    errorWidget:
                                        (context, url, error) => Container(
                                          color: Colors.grey[700],
                                          child: const Icon(
                                            Icons.card_giftcard,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                        ),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Image.asset(
                                      'assets/diamond.png',
                                      width: 12,
                                      height: 12,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      '${gift['diamond_amount']}',
                                      style: TextStyle(
                                        color:
                                            canAfford
                                                ? Colors.orange
                                                : Colors.grey[500],
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

            // Overlay active gift animations (host and audience)
            ..._activeGiftAnimations,
            // Watermark logo in top left, even further below, with transparent gradient text
            Positioned(
              top: 100,
              left: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Opacity(
                    opacity: 0.5,
                    child: Container(
                      margin: const EdgeInsets.only(
                        left: 28,
                      ), // move logo further right
                      child: Image.asset(
                        'assets/logo.png',
                        width: 36,
                        height: 36,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Opacity(
                    opacity: 0.5,
                    child: ShaderMask(
                      shaderCallback: (Rect bounds) {
                        return const LinearGradient(
                          colors: [
                            Color(0xFFffa030),
                            Color(0xFFfe9b00),
                            Color(0xFFf67d00),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(bounds);
                      },
                      child: const Text(
                        'Bharath Chat',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color:
                              Colors.white,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Audience Debug Info Panel (audience only)
            if (!widget.isHost)
              Positioned(
                top: 50,
                right: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Toggle button
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _showDebugInfo = !_showDebugInfo;
                        });
                      },
                      // child: Container(
                      //   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      //   decoration: BoxDecoration(
                      //     color: _showDebugInfo ? Colors.orange : Colors.black.withOpacity(0.7),
                      //     borderRadius: BorderRadius.circular(20),
                      //     border: Border.all(color: Colors.orange, width: 1),
                      //   ),
                      //   child: Text(
                      //     _showDebugInfo ? 'Hide Info' : 'Show Info',
                      //     style: TextStyle(
                      //       color: _showDebugInfo ? Colors.black : Colors.orange,
                      //       fontSize: 12,
                      //       fontWeight: FontWeight.bold,
                      //     ),
                      //   ),
                      // ),
                    ),
                    const SizedBox(height: 8),
                    // Debug Info button
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PKBattleDebugScreen(
                              streamId: _debugInfo['stream_id'],
                            ),
                          ),
                        );
                      },
                      // child: Container(
                      //   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      //   decoration: BoxDecoration(
                      //     color: Colors.purple.withOpacity(0.8),
                      //     borderRadius: BorderRadius.circular(20),
                      //     border: Border.all(color: Colors.purple, width: 1),
                      //   ),
                      //   child: const Text(
                      //     'Debug Info',
                      //     style: TextStyle(
                      //       color: Colors.white,
                      //       fontSize: 12,
                      //       fontWeight: FontWeight.bold,
                      //     ),
                      //   ),
                      // ),
                    ),
                    // Debug Info Panel
                    if (_showDebugInfo)
                      Container(
                        width: 300,
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange, width: 1),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Header
                            Row(
                              children: [
                                const Icon(Icons.info_outline, color: Colors.orange, size: 16),
                                const SizedBox(width: 8),
                                const Text(
                                  'Audience Info Panel',
                                  style: TextStyle(
                                    color: Colors.orange,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const Spacer(),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _apiLogs.clear();
                                      _debugInfo.clear();
                                      _LivePageState._globalApiLogs.clear();
                                    });
                                  },
                                  child: const Icon(Icons.clear, color: Colors.grey, size: 16),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            
                            // Basic Info
                            _buildInfoSection('Basic Info', {
                              'Is Host': widget.isHost.toString(),
                              'Live ID': widget.liveID,
                              'Local User ID': widget.localUserID,
                              'Receiver ID': widget.receiverId.toString(),
                              'Has Active PK Battle': (widget.activePKBattle != null).toString(),
                            }),
                            
                            const SizedBox(height: 8),
                            
                            // PK Battle Info
                            if (PKEvents.currentPKBattleId != null)
                              _buildInfoSection('PK Battle Info', {
                                'PK Battle ID': PKEvents.currentPKBattleId.toString(),
                                'Left Host ID': _debugInfo['left_host_id']?.toString() ?? 'N/A',
                                'Right Host ID': _debugInfo['right_host_id']?.toString() ?? 'N/A',
                                'Left Score': _debugInfo['left_score']?.toString() ?? '0',
                                'Right Score': _debugInfo['right_score']?.toString() ?? '0',
                                'Left Stream ID': _debugInfo['left_stream_id']?.toString() ?? 'N/A',
                                'Right Stream ID': _debugInfo['right_stream_id']?.toString() ?? 'N/A',
                                'Status': _debugInfo['pk_battle_status']?.toString() ?? 'N/A',
                                'Start Time': _debugInfo['pk_battle_start_time']?.toString() ?? 'N/A',
                              }),
                            
                            const SizedBox(height: 8),
                            
                            // User Info
                            if (_debugInfo['current_user'] != null)
                              _buildInfoSection('User Info', {
                                'User ID': _debugInfo['current_user']['id']?.toString() ?? 'N/A',
                                'Username': _debugInfo['current_user']['username']?.toString() ?? 'N/A',
                                'Diamonds': _debugInfo['current_user']['diamonds']?.toString() ?? '0',
                                'Name': '${_debugInfo['current_user']['first_name'] ?? ''} ${_debugInfo['current_user']['last_name'] ?? ''}'.trim(),
                              }),
                            
                            const SizedBox(height: 8),
                            
                            // Stream Info
                            _buildInfoSection('Stream Info', {
                              'Stream ID': _debugInfo['stream_id']?.toString() ?? 'N/A',
                              'Gifts Count': _debugInfo['gifts_count']?.toString() ?? '0',
                              'Show PK Timer': _showPKBattleTimer.toString(),
                              'Show PK Notification': _showPKBattleNotification.toString(),
                            }),
                            
                            const SizedBox(height: 8),
                            
                            // API Logs
                            Row(
                              children: [
                                const Text(
                                  'API Logs (All Captured):',
                                  style: TextStyle(
                                    color: Colors.orange,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${_allApiLogs.length}',
                                    style: const TextStyle(
                                      color: Colors.orange,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Container(
                              height: 200,
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.grey[900],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ListView.builder(
                                itemCount: _allApiLogs.length,
                                itemBuilder: (context, index) {
                                  final log = _allApiLogs[index];
                                  Color logColor = Colors.white;
                                  
                                  // Color code different types of logs
                                  if (log.contains('🚀')) {
                                    logColor = Colors.blue;
                                  } else if (log.contains('🔍')) {
                                    logColor = Colors.cyan;
                                  } else if (log.contains('📡')) {
                                    logColor = Colors.yellow;
                                  } else if (log.contains('✅')) {
                                    logColor = Colors.green;
                                  } else if (log.contains('❌')) {
                                    logColor = Colors.red;
                                  } else if (log.contains('⚠️')) {
                                    logColor = Colors.orange;
                                  } else if (log.contains('💥')) {
                                    logColor = Colors.purple;
                                  } else if (log.contains('⏳')) {
                                    logColor = Colors.grey;
                                  }
                                  
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 2),
                                    child: Text(
                                      log,
                                      style: TextStyle(
                                        color: logColor,
                                        fontSize: 9,
                                        fontFamily: 'monospace',
                                        fontWeight: FontWeight.w500,
                                      ),
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
              ),
          ],
        ),
      ),
    );
  }

  Widget foregroundBuilder(context, size, ZegoUIKitUser? user, _) {
    if (user == null) {
      return Container();
    }

    final hostWidgets = [
      Positioned(
        top: 5,
        left: 5,
        child: SizedBox(
          width: 40,
          height: 40,
          child: PKMuteButton(userID: user.id),
        ),
      ),
    ];

    return Stack(
      children: [
        ...((widget.isHost && user.id != widget.localUserID)
            ? hostWidgets
            : []),
        Positioned(
          top: 5,
          right: 35,
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircleAvatar(
              backgroundColor: Colors.purple.withOpacity(0.6),
              child: Icon(
                user.camera.value ? Icons.videocam : Icons.videocam_off,
                color: Colors.white,
                size: 15,
              ),
            ),
          ),
        ),
        Positioned(
          top: 5,
          right: 5,
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircleAvatar(
              backgroundColor: Colors.purple.withOpacity(0.6),
              child: Icon(
                user.microphone.value ? Icons.mic : Icons.mic_off,
                color: Colors.white,
                size: 15,
              ),
            ),
          ),
        ),
        Positioned(
          top: 25,
          right: 5,
          child: Container(
            height: 18,
            color: Colors.purple,
            child: Text(user.name),
          ),
        ),
      ],
    );
  }
}

// AnimatedHeart widget for burst effect
class AnimatedHeart extends StatefulWidget {
  final Duration delay;
  final Random random;
  const AnimatedHeart({Key? key, required this.delay, required this.random})
    : super(key: key);

  @override
  State<AnimatedHeart> createState() => _AnimatedHeartState();
}

class _AnimatedHeartState extends State<AnimatedHeart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _moveUp;
  late Animation<double> _fade;
  late double _xOffset;

  @override
  void initState() {
    super.initState();
    _xOffset = widget.random.nextDouble() * 60 - 30;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _moveUp = Tween<double>(
      begin: 0,
      end: -80,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _fade = Tween<double>(
      begin: 1,
      end: 0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _fade.value,
          child: Transform.translate(
            offset: Offset(_xOffset, _moveUp.value),
            child: Icon(Icons.favorite, color: Colors.pink, size: 28),
          ),
        );
      },
    );
  }
}
