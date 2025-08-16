import 'package:flutter/material.dart';
import 'package:zego_uikit_prebuilt_live_streaming/zego_uikit_prebuilt_live_streaming.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:camera/camera.dart'
    show
        CameraController,
        CameraDescription,
        CameraPreview,
        ResolutionPreset,
        availableCameras;
import 'package:just_audio/just_audio.dart';
import 'package:finalchat/pk_widgets/config.dart';
import 'package:finalchat/pk_widgets/events.dart';
import 'package:finalchat/pk_widgets/surface.dart';
import 'package:finalchat/pk_widgets/widgets/join_widget.dart';
import 'package:finalchat/pk_widgets/widgets/request_widget.dart';
import 'package:finalchat/pk_widgets/widgets/requesting_list.dart';
import 'package:finalchat/pk_widgets/widgets/requesting_id.dart';
import 'package:finalchat/pk_widgets/widgets/pk_battle_button.dart';
import 'package:finalchat/pk_widgets/widgets/pk_battle_timer.dart';
import 'package:finalchat/pk_widgets/widgets/pk_battle_progress_bar.dart';
import 'package:finalchat/pk_widgets/widgets/pk_progress_bar.dart';
import 'package:finalchat/pk_widgets/widgets/quit_button.dart';
import 'package:finalchat/pk_widgets/widgets/stop_button.dart';
import 'package:finalchat/pk_widgets/widgets/mute_button.dart';
import 'package:finalchat/pk_widgets/widgets/pk_battle_ended_popup.dart';
import 'package:finalchat/pk_widgets/widgets/pk_battle_notification.dart';
import 'package:finalchat/pk_widgets/pk_battle_ended_service.dart';
import 'package:finalchat/services/api_service.dart';
import 'package:finalchat/services/live_stream_service.dart';
import 'package:finalchat/common.dart';
import 'package:finalchat/constants.dart';
import 'gift_panel.dart';
import 'gift_animation.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:zego_uikit/zego_uikit.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:finalchat/screens/main/store_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pk_battle_debug_screen.dart';
import 'package:http/http.dart' as http;

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
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final liveStateNotifier = ValueNotifier<ZegoLiveStreamingState>(
    ZegoLiveStreamingState.idle,
  );

  final requestingHostsMapRequestIDNotifier =
      ValueNotifier<Map<String, List<String>>>({});
  final requestIDNotifier = ValueNotifier<String>('');
  PKEvents? pkEvents;

  // Host profile picture and username for top menu bar
  String? _hostProfilePic;
  String? _hostUsername;

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

  // Audio player for gift sounds
  final AudioPlayer _giftAudioPlayer = AudioPlayer();

  // User profiles for member list
  Map<String, dynamic> _userProfiles = {};
  List<dynamic> _allUsers = [];
  List<dynamic> _zegoUsers = [];

  // Stream subscription for user list
  StreamSubscription? _userListSub;

  @override
  void initState() {
    super.initState();

    // Set up log callback to capture API logs
    _setLogCallback();

    // Listen for in-room commands (gift animations from other users)
    // Note: We'll handle this through the ZegoUIKitPrebuiltLiveStreaming events
    // The gift animations will be broadcasted via sendInRoomCommand

    // Initialize debug info
    _updateDebugInfo('is_host', widget.isHost);
    _updateDebugInfo('live_id', widget.liveID);
    _updateDebugInfo('local_user_id', widget.localUserID);
    _updateDebugInfo('receiver_id', widget.receiverId);
    _updateDebugInfo('has_active_pk_battle', widget.activePKBattle != null);

    // Fetch host profile picture for top menu bar
    _fetchHostProfilePicture();

    // Load all users for member list
    _fetchAllUsers();

    // Listen for Zego user list changes
    _userListSub = ZegoUIKit().getUserListStream().listen((zegoUsers) {
      setState(() {
        _zegoUsers = zegoUsers;
      });
      _mapZegoUsersToProfiles(zegoUsers);
    });

    // Extract stream ID from liveID for audience
    // Extract stream ID for both hosts and audience
    if (widget.liveID.startsWith('live_')) {
      final parts = widget.liveID.split('_');
      if (parts.length >= 2) {
        final streamId = int.tryParse(parts[1]);
        if (streamId != null) {
          _updateDebugInfo('stream_id', streamId);
          _logApiCall(
            'Stream ID Extraction',
            'Extracted stream ID: $streamId from liveID: ${widget.liveID}',
          );
          debugPrint(
            '🎯 STREAM ID EXTRACTED: $streamId for ${widget.isHost ? "HOST" : "AUDIENCE"}',
          );
        } else {
          _logApiCall(
            'Stream ID Extraction',
            'Failed to parse stream ID from: ${parts[1]}',
          );
          debugPrint('❌ Failed to parse stream ID from: ${parts[1]}');
        }
      } else {
        _logApiCall(
          'Stream ID Extraction',
          'Invalid liveID format: ${widget.liveID}',
        );
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
      debugPrint(
        '🎮 Audience joining with active PK battle: ${widget.activePKBattle!['id']}',
      );
      _logApiCall(
        'Active PK Battle',
        'Found active PK battle: ${widget.activePKBattle!['id']}',
      );
      _updateDebugInfo('active_pk_battle_data', widget.activePKBattle);

      PKEvents.setCurrentPKBattleId(widget.activePKBattle!['id']);
      _pkBattleId = widget.activePKBattle!['id']?.toString();

      // Start polling for transactions when audience joins with active PK battle
      _startPKBattleTransactionsPolling();

      if (widget.activePKBattle!['start_time'] != null) {
        final serverStartTime = DateTime.parse(
          widget.activePKBattle!['start_time'],
        );
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
      _updateDebugInfo(
        'right_host_id',
        widget.activePKBattle!['right_host_id'],
      );
    } else {
      // For both hosts and audience without pre-loaded PK battle, fetch it immediately

      // Start block checking for audience members
      _startBlockChecking();
      debugPrint(
        '🎮 ${widget.isHost ? "Host" : "Audience"} joining - fetching PK battle data...',
      );
      _logApiCall(
        '${widget.isHost ? "Host" : "Audience"} Join',
        'Fetching PK battle data',
      );

      // Fetch PK battle data with delay to allow backend to create PK battle
      Future.delayed(Duration(seconds: 2), () {
        _fetchPKBattleDataFromServer();
      });
    }

    // Check if there's an active PK battle when joining
    _checkActivePKBattle();

    // Start a timer to periodically check for PK battle ID if not available (using stream ID only)
    Timer.periodic(Duration(seconds: 2), (timer) {
      if (_pkBattleId == null &&
          PKEvents.currentPKBattleId == null &&
          _showPKBattleTimer) {
        debugPrint(
          '🔄 Periodic check: PK battle ID still not available, fetching by stream ID...',
        );
        _fetchPKBattleIdByStreamId();
      } else if (_pkBattleId != null || PKEvents.currentPKBattleId != null) {
        if (widget.isHost) {
          // For hosts, stop timer once PK battle ID is found
          debugPrint(
            '✅ Periodic check: PK battle ID found, stopping timer for host',
          );
          timer.cancel();
        } else {
          // For audience, keep timer running to maintain PK battle data
          debugPrint(
            '🔄 Periodic check: PK battle ID found, keeping timer running for audience',
          );
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

    // Start periodic fetching of PK battle transactions for gift animations
    _startPKBattleTransactionsPolling();

    // Start gift polling for synchronization across devices
    _startGiftPolling();
    // Start host-side user gifts polling for normal (non-PK) lives
    _startUserGiftsPolling();

    // Start periodic check for PK battle active status
    _startPKBattleActiveCheck();
  }

  // Variables for PK battle transactions polling
  Timer? _pkBattleTransactionsTimer;
  Set<String> _processedTransactionIds = {};
  int _lastTransactionPollTime = 0;

  // Timer to check if stored PK battle ID is still active
  Timer? _pkBattleActiveCheckTimer;

  void _startPKBattleTransactionsPolling() {
    debugPrint('🔄 Starting PK battle transactions polling...');
    _pkBattleTransactionsTimer = Timer.periodic(Duration(seconds: 3), (timer) {
      _fetchAndDisplayPKBattleTransactions();
    });
  }

  void _stopPKBattleTransactionsPolling() {
    debugPrint('🛑 Stopping PK battle transactions polling...');
    _pkBattleTransactionsTimer?.cancel();
    _pkBattleTransactionsTimer = null;
  }

  // Start periodic check for PK battle active status
  void _startPKBattleActiveCheck() {
    _pkBattleActiveCheckTimer?.cancel();
    _pkBattleActiveCheckTimer = Timer.periodic(Duration(seconds: 10), (timer) {
      _checkPKBattleActiveStatus();
    });
    debugPrint('🔄 Starting PK battle active status check every 10 seconds');
  }

  void _stopPKBattleActiveCheck() {
    debugPrint('🛑 Stopping PK battle active status check');
    _pkBattleActiveCheckTimer?.cancel();
    _pkBattleActiveCheckTimer = null;
  }

  // Check if stored PK battle ID is still active
  Future<void> _checkPKBattleActiveStatus() async {
    try {
      if (PKEvents.currentPKBattleId == null) return;

      final storedPKBattleId = PKEvents.currentPKBattleId!;
      debugPrint(
        '🔍 Checking if PK battle $storedPKBattleId is still active...',
      );

      final response = await http.get(
        Uri.parse('https://server.bharathchat.com/api/pk-battle/active'),
        headers: {'accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> activeBattles = json.decode(response.body);
        debugPrint('📡 Found ${activeBattles.length} active PK battles');

        // Check if our stored PK battle ID is in the active list
        final isStillActive = activeBattles.any(
          (battle) => battle['battle_id'] == storedPKBattleId,
        );

        if (!isStillActive) {
          debugPrint(
            '❌ PK battle $storedPKBattleId is no longer active, clearing...',
          );

          // Clear PK battle data and return to normal mode
          PKEvents.setCurrentPKBattleId(null);
          setState(() {
            _pkBattleId = null;
            _showPKBattleTimer = false;
            _leftHostId = null;
            _rightHostId = null;
            _leftHostName = null;
            _rightHostName = null;
          });
          PKEvents.setCurrentPKBattleStartTime(null);

          // Stop PK battle specific polling
          _stopPKBattleTransactionsPolling();

          debugPrint(
            '🎯 PK battle data cleared, returned to normal single host mode',
          );
        } else {
          debugPrint('✅ PK battle $storedPKBattleId is still active');
        }
      } else {
        debugPrint(
          '❌ Failed to check PK battle active status: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('❌ Error checking PK battle active status: $e');
    }
  }

  Future<void> _fetchAndDisplayPKBattleTransactions() async {
    if (PKEvents.currentPKBattleId == null) {
      return; // No active PK battle
    }

    try {
      final transactions = await ApiService.getPKBattleTransactions(
        PKEvents.currentPKBattleId!,
      );

      if (transactions['transactions'] != null) {
        final List<dynamic> transactionList = transactions['transactions'];

        for (final transaction in transactionList) {
          final transactionId = transaction['id'].toString();

          // Skip if we've already processed this transaction
          if (_processedTransactionIds.contains(transactionId)) {
            continue;
          }

          // Skip if transaction is too old (older than 10 seconds)
          final createdAt = DateTime.parse(transaction['created_at']);
          final now = DateTime.now();
          if (now.difference(createdAt).inSeconds > 10) {
            continue;
          }

          // Process the transaction and create gift animation
          _processPKBattleTransaction(transaction);
          _processedTransactionIds.add(transactionId);
        }
      }
    } catch (e) {
      debugPrint('❌ Error fetching PK battle transactions: $e');
    }
  }

  void _processPKBattleTransaction(Map<String, dynamic> transaction) {
    try {
      final giftDetails = transaction['gift_details'];
      final senderDetails = transaction['sender_details'];
      final receiverDetails = transaction['receiver_details'];

      if (giftDetails == null || senderDetails == null) {
        return;
      }

      final giftName = giftDetails['name'];
      final gifFilename = giftDetails['gif_filename'];
      final senderName =
          senderDetails['username'] ??
          '${senderDetails['first_name']} ${senderDetails['last_name']}';

      // Determine PK battle side based on receiver
      String? pkBattleSide;
      if (transaction['receiver_id'] == transaction['left_host_id']) {
        pkBattleSide = 'left';
      } else if (transaction['receiver_id'] == transaction['right_host_id']) {
        pkBattleSide = 'right';
      }

      // Create GIF URL
      final gifUrl =
          'https://server.bharathchat.com/uploads/gifts/$gifFilename';

      debugPrint('🎁 Processing PK battle transaction:');
      debugPrint('🎁   - Transaction ID: ${transaction['id']}');
      debugPrint('🎁   - Gift: $giftName');
      debugPrint('🎁   - Sender: $senderName');
      debugPrint('🎁   - Receiver: ${receiverDetails['username']}');
      debugPrint('🎁   - PK Battle Side: $pkBattleSide');
      debugPrint('🎁   - GIF URL: $gifUrl');

      // Create gift animation
      _createGiftAnimation(giftName, gifUrl, senderName, pkBattleSide);
    } catch (e) {
      debugPrint('❌ Error processing PK battle transaction: $e');
    }
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
      _logApiCall(
        'getCurrentUser',
        'Success: User ${user['username']} fetched',
      );
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

      debugPrint('🎁 === GIFT LOADING COMPLETED ===');
      debugPrint('🎁 Total gifts loaded: ${gifts.length}');
      debugPrint('🎁 Current user diamonds: ${user['diamonds']}');
      debugPrint(
        '🎁 First gift: ${gifts.isNotEmpty ? gifts.first['name'] : 'No gifts'}',
      );
    } catch (e) {
      _logApiCall('Error', 'Failed to fetch data: $e');
      setState(() {
        _giftsLoading = false;
      });
    }
  }

  Future<void> _sendGiftFromList(dynamic gift) async {
    final requestId = DateTime.now().millisecondsSinceEpoch.toString();
    debugPrint('🎁 === GIFT SENDING STARTED [${requestId}] ===');
    debugPrint('🎁 [${requestId}] Gift Details:');
    debugPrint('🎁 [${requestId}] - Name: ${gift['name']}');
    debugPrint('🎁 [${requestId}] - ID: ${gift['id']}');
    debugPrint('🎁 [${requestId}] - Diamond Amount: ${gift['diamond_amount']}');
    debugPrint('🎁 [${requestId}] - GIF Filename: ${gift['gif_filename']}');
    debugPrint('🎁 [${requestId}] Current User State:');
    debugPrint('🎁 [${requestId}] - User ID: ${_currentUser?['id']}');
    debugPrint('🎁 [${requestId}] - Username: ${_currentUser?['username']}');
    debugPrint(
      '🎁 [${requestId}] - First Name: ${_currentUser?['first_name']}',
    );
    debugPrint(
      '🎁 [${requestId}] - Current Diamonds: ${_currentUser?['diamonds']}',
    );
    debugPrint(
      '🎁 [${requestId}] - Can Afford: ${(_currentUser?['diamonds'] ?? 0) >= (gift['diamond_amount'] ?? 0)}',
    );
    debugPrint('🎁 [${requestId}] App State:');
    debugPrint('🎁 [${requestId}] - Already Sending: $_sendingGift');
    debugPrint('🎁 [${requestId}] - Live State: ${liveStateNotifier.value}');
    debugPrint('🎁 [${requestId}] - Is Host: ${widget.isHost}');
    debugPrint(
      '🎁 [${requestId}] - PK Battle ID: ${PKEvents.currentPKBattleId}',
    );
    debugPrint('🎁 [${requestId}] - Live ID: ${widget.liveID}');
    debugPrint('🎁 [${requestId}] - Local User ID: ${widget.localUserID}');
    debugPrint('🎁 [${requestId}] - Receiver ID: ${widget.receiverId}');

    if (_sendingGift) {
      debugPrint('❌ [${requestId}] Already sending gift, skipping...');
      return;
    }
    if (_currentUser == null) {
      debugPrint('❌ [${requestId}] Current user is null, skipping...');
      return;
    }
    if (_currentUser!['diamonds'] < gift['diamond_amount']) {
      debugPrint(
        '❌ [${requestId}] Not enough diamonds! User has: ${_currentUser!['diamonds']}, Gift costs: ${gift['diamond_amount']}',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Not enough diamonds!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Set sending flag early to prevent multiple sends
    setState(() {
      _sendingGift = true;
    });

    try {
      // Check if we're in PK battle mode
      final isPKBattle =
          liveStateNotifier.value == ZegoLiveStreamingState.inPKBattle;
      debugPrint('🎁 [${requestId}] Is PK Battle: $isPKBattle');
      debugPrint(
        '🎁 [${requestId}] Live State Value: ${liveStateNotifier.value}',
      );
      debugPrint(
        '🎁 [${requestId}] Expected PK Battle State: ${ZegoLiveStreamingState.inPKBattle}',
      );

      if (isPKBattle && !widget.isHost) {
        debugPrint(
          '🎁 [${requestId}] PK Battle mode - showing host selection dialog',
        );
        debugPrint(
          '🎁 [${requestId}] Left Host: ${_leftHostName} (${_leftHostId})',
        );
        debugPrint(
          '🎁 [${requestId}] Right Host: ${_rightHostName} (${_rightHostId})',
        );

        // Show host selection dialog for PK battle
        final selectedHost = await _showHostSelectionDialog();
        debugPrint(
          '🎁 [${requestId}] Host selection dialog result: $selectedHost',
        );

        if (selectedHost == null) {
          debugPrint('🎁 [${requestId}] User cancelled host selection');
          return; // User cancelled
        }

        debugPrint('🎁 [${requestId}] Selected host ID: $selectedHost');
        debugPrint(
          '🎁 [${requestId}] Calling _sendGiftToHost with selected host...',
        );
        await _sendGiftToHost(gift, selectedHost);

        // Update PK progress bar diamond count
        debugPrint('🎁 [${requestId}] Updating PK diamond count...');
        _updatePKDiamondCount(selectedHost, gift['diamond_amount']);
      } else {
        debugPrint('🎁 [${requestId}] Normal gift sending mode');
        debugPrint('🎁 [${requestId}] Is Host: ${widget.isHost}');
        debugPrint('🎁 [${requestId}] Receiver ID: ${widget.receiverId}');
        debugPrint(
          '🎁 [${requestId}] Calling _sendGiftToHost with receiver ID...',
        );
        // Normal gift sending (not in PK battle or host sending)
        await _sendGiftToHost(gift, widget.receiverId);
      }
    } finally {
      // Always reset the sending flag
      setState(() {
        _sendingGift = false;
      });
      debugPrint(
        '🎁 [${requestId}] Gift sending process finished, resetting sending state',
      );
    }
  }

  Future<void> _sendGiftToHost(dynamic gift, int receiverId) async {
    try {
      final requestId = DateTime.now().millisecondsSinceEpoch.toString();
      debugPrint('🎁 [$requestId] Starting gift send to host $receiverId');

      // Check if we have enough diamonds
      final currentDiamonds = await ApiService.getCurrentUserDiamonds();
      final giftCost = gift['diamond_amount'] as int? ?? 0;

      if (currentDiamonds < giftCost) {
        debugPrint(
          '❌ [$requestId] Insufficient diamonds: $currentDiamonds < $giftCost',
        );
        _showInsufficientDiamondsDialog();
        return;
      }

      debugPrint(
        '✅ [$requestId] Sufficient diamonds: $currentDiamonds >= $giftCost',
      );

      // Show confirmation dialog
      await _showGiftConfirmationDialog(gift, giftCost, requestId, () async {
        try {
          debugPrint('🎁 [$requestId] User confirmed, sending gift...');

          bool success = false;

          // Check if PK battle is active
          if (PKEvents.currentPKBattleId != null) {
            debugPrint(
              '🎁 [$requestId] PK Battle active, using PK battle gift API',
            );

            // Use PK battle gift API
            success = await ApiService.sendPKBattleGift(
              pkBattleId: PKEvents.currentPKBattleId!,
              senderId: _currentUser?['id'] as int? ?? 0,
              receiverId: receiverId,
              giftId: gift['id'],
              amount: giftCost,
            );
          } else {
            debugPrint('🎁 [$requestId] No PK battle, using regular gift API');

            // Send gift via regular API (ensure numeric stream id)
            int liveStreamId = 0;
            final dynamic streamIdRaw = _debugInfo['stream_id'];
            if (streamIdRaw is int) {
              liveStreamId = streamIdRaw;
            } else if (streamIdRaw is String) {
              liveStreamId = int.tryParse(streamIdRaw) ?? 0;
            }

            success = await ApiService.sendGift(
              receiverId: receiverId,
              giftId: gift['id'],
              liveStreamId: liveStreamId,
              liveStreamType: 'video',
            );
          }

          if (success) {
            debugPrint('✅ [$requestId] Gift sent successfully via API');

            // Play gift audio if available (with 2-second delay)
            final dynamic audioFilenameRaw = gift['audio_filename'];
            final String? audioFilename =
                (audioFilenameRaw is String)
                    ? audioFilenameRaw
                    : (audioFilenameRaw?.toString());
            if (audioFilename != null && audioFilename.isNotEmpty) {
              try {
                final audioUrl =
                    'https://server.bharathchat.com/uploads/audio/$audioFilename';
                debugPrint('🎁 [$requestId] Playing gift audio: $audioUrl');
                // Use the new 2-second delay method
                _playGiftAudioWithDelay(audioUrl);
              } catch (e) {
                debugPrint('🎁 [$requestId] Error playing gift audio: $e');
              }
            }

            // Immediately show animation for the sender
            try {
              String? gifUrl;
              final dynamic gifUrlRaw = gift['gif_url'];
              if (gifUrlRaw is String && gifUrlRaw.isNotEmpty) {
                gifUrl =
                    gifUrlRaw.startsWith('http')
                        ? gifUrlRaw
                        : 'https://server.bharathchat.com$gifUrlRaw';
              } else {
                final dynamic gifFilenameRaw = gift['gif_filename'];
                final String gifFilename =
                    (gifFilenameRaw is String)
                        ? gifFilenameRaw
                        : (gifFilenameRaw?.toString() ?? '');
                gifUrl =
                    'https://server.bharathchat.com/uploads/gifts/$gifFilename';
              }
              final String senderName =
                  _currentUser?['username'] ??
                  _currentUser?['first_name'] ??
                  'You';
              final String giftName =
                  gift['name'] ?? gift['gift_name'] ?? 'Gift';
              String? pkBattleSide;
              if (PKEvents.currentPKBattleId != null) {
                if (receiverId == int.tryParse(_leftHostId ?? '0')) {
                  pkBattleSide = 'left';
                } else if (receiverId == int.tryParse(_rightHostId ?? '0')) {
                  pkBattleSide = 'right';
                }
              }
              if (gifUrl != null) {
                _createGiftAnimation(
                  giftName,
                  gifUrl,
                  senderName,
                  pkBattleSide,
                );
              }
            } catch (e) {
              debugPrint(
                '🎁 [$requestId] Error creating immediate gift animation: $e',
              );
            }

            // Send in-room command for synchronization
            final message = jsonEncode({
              'type': 'gift',
              'gift_id': gift['id'],
              'gift_name': gift['name'],
              'gif_filename': gift['gif_filename'],
              'audio_filename': gift['audio_filename'],
              'diamond_amount': giftCost,
              'sender_id': _currentUser?['id'],
              'sender_name':
                  _currentUser?['username'] ??
                  _currentUser?['first_name'] ??
                  'User',
              'receiver_id': receiverId,
              'timestamp': DateTime.now().toIso8601String(),
            });

            debugPrint('🎁 [$requestId] In-room command prepared: $message');
            // Note: ZEGOCLOUD command sending is disabled due to API limitations
            // Gift animations will be synchronized through server-side polling
            debugPrint(
              '🎁 [$requestId] ZEGOCLOUD command sending disabled - using server polling for sync',
            );

            // Show success message
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('🎁 Gift sent successfully!'),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          } else {
            debugPrint('❌ [$requestId] Failed to send gift via API');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('❌ Failed to send gift. Please try again.'),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          }
        } catch (e) {
          debugPrint('❌ [$requestId] Error sending gift: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('❌ Error sending gift: $e'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      });

      debugPrint('✅ [$requestId] Gift confirmation dialog completed');
    } catch (e) {
      debugPrint('❌ Error in _sendGiftToHost: $e');
    }
  }

  Future<int?> _showHostSelectionDialog() async {
    debugPrint('🎁 === HOST SELECTION DIALOG ===');
    debugPrint('🎁 Left Host Name: $_leftHostName, ID: $_leftHostId');
    debugPrint('🎁 Right Host Name: $_rightHostName, ID: $_rightHostId');
    debugPrint('🎁 PK Battle ID: ${PKEvents.currentPKBattleId}');
    debugPrint(
      '🎁 Current User: ${_currentUser?['id']} - ${_currentUser?['first_name']}',
    );

    return await showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            '🎁 Choose Gift Recipient',
            style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Which host would you like to send the gift to?',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 16),
              // Left Host Info
              // Container(
              //   padding: const EdgeInsets.all(12),
              //   decoration: BoxDecoration(
              //     color: Colors.green.withOpacity(0.1),
              //     borderRadius: BorderRadius.circular(8),
              //     border: Border.all(color: Colors.green),
              //   ),
              //   child: Column(
              //     crossAxisAlignment: CrossAxisAlignment.start,
              //     children: [
              //       Text(
              //         '🟢 Left Host: ${_leftHostName ?? 'Unknown'}',
              //         style: const TextStyle(
              //           color: Colors.green,
              //           fontWeight: FontWeight.bold,
              //           fontSize: 14,
              //         ),
              //       ),
              //       Text(
              //         'ID: ${_leftHostId ?? 'N/A'}',
              //         style: const TextStyle(
              //           color: Colors.green,
              //           fontSize: 12,
              //         ),
              //       ),
              //     ],
              //   ),
              // ),
              // const SizedBox(height: 8),
              // // Right Host Info
              // Container(
              //   padding: const EdgeInsets.all(12),
              //   decoration: BoxDecoration(
              //     color: Colors.orange.withOpacity(0.1),
              //     borderRadius: BorderRadius.circular(8),
              //     border: Border.all(color: Colors.orange),
              //   ),
              //   child: Column(
              //     crossAxisAlignment: CrossAxisAlignment.start,
              //     children: [
              //       Text(
              //         '🟠 Right Host: ${_rightHostName ?? 'Unknown'}',
              //         style: const TextStyle(
              //           color: Colors.orange,
              //           fontWeight: FontWeight.bold,
              //           fontSize: 14,
              //         ),
              //       ),
              //       Text(
              //         'ID: ${_rightHostId ?? 'N/A'}',
              //         style: const TextStyle(
              //           color: Colors.orange,
              //           fontSize: 12,
              //         ),
              //       ),
              //     ],
              //   ),
              // ),
            ],
          ),
          actions: [
            // Left Host Button
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Colors.green.withOpacity(0.2),
                foregroundColor: Colors.green,
                side: BorderSide(color: Colors.green),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                debugPrint(
                  '🎁 User selected LEFT HOST: ${_leftHostId} - ${_leftHostName}',
                );
                Navigator.of(
                  context,
                ).pop(int.tryParse(_leftHostId ?? '0') ?? 0);
              },
              child: Text(
                '🟢 ${_leftHostName ?? 'Left Host'}',
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // Right Host Button
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Colors.orange.withOpacity(0.2),
                foregroundColor: Colors.orange,
                side: BorderSide(color: Colors.orange),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                debugPrint(
                  '🎁 User selected RIGHT HOST: ${_rightHostId} - ${_rightHostName}',
                );
                Navigator.of(
                  context,
                ).pop(int.tryParse(_rightHostId ?? '0') ?? 0);
              },
              child: Text(
                '🟠 ${_rightHostName ?? 'Right Host'}',
                style: const TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // Cancel Button
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.grey,
                side: BorderSide(color: Colors.grey),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                debugPrint('🎁 User cancelled host selection');
                Navigator.of(context).pop(null);
              },
              child: const Text(
                '❌ Cancel',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showGiftConfirmationDialog(
    dynamic gift,
    int giftCost,
    String requestId,
    VoidCallback onConfirm,
  ) async {
    debugPrint('🎁 [${requestId}] === GIFT CONFIRMATION DIALOG ===');
    debugPrint('🎁 [${requestId}] Gift: ${gift['name']} (${gift['id']})');
    debugPrint('🎁 [${requestId}] Diamond Amount: $giftCost');
    debugPrint(
      '🎁 [${requestId}] Current User: ${_currentUser?['id']} - ${_currentUser?['first_name']}',
    );
    debugPrint('🎁 [${requestId}] User Diamonds: ${_currentUser?['diamonds']}');
    debugPrint(
      '🎁 [${requestId}] Can Afford: ${(_currentUser?['diamonds'] ?? 0) >= giftCost}',
    );

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
              onPressed: () {
                debugPrint(
                  '🎁 [${requestId}] User cancelled gift confirmation',
                );
                Navigator.of(context).pop();
              },
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
                debugPrint('🎁 [${requestId}] User confirmed gift sending');
                debugPrint('🎁 [${requestId}] Calling onConfirm callback...');
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
    _stopPKBattleTransactionsPolling();
    _stopGiftPolling();
    _stopUserGiftsPolling();
    _stopPKBattleActiveCheck();
    _stopBlockChecking();
    _giftAudioPlayer.dispose();
    _userListSub?.cancel();
    super.dispose();
  }

  void _updatePKDiamondCount(int hostId, int diamondAmount) {
    debugPrint('🎁 === UPDATING PK DIAMOND COUNT ===');
    debugPrint('🎁 Host ID: $hostId');
    debugPrint('🎁 Diamond Amount: $diamondAmount');
    debugPrint('🎁 Left Host ID: $_leftHostId');
    debugPrint('🎁 Right Host ID: $_rightHostId');

    if (hostId.toString() == _leftHostId) {
      debugPrint(
        '🎁 Adding $diamondAmount diamonds to LEFT host (${_leftHostName})',
      );
    } else if (hostId.toString() == _rightHostId) {
      debugPrint(
        '🎁 Adding $diamondAmount diamonds to RIGHT host (${_rightHostName})',
      );
    } else {
      debugPrint('❌ Host ID $hostId not found in PK battle hosts');
      debugPrint('❌ Available hosts: Left=$_leftHostId, Right=$_rightHostId');
    }

    // The actual score update is handled by the progress bar's periodic fetch
    debugPrint('🎁 Progress bar will automatically update scores from server');
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

  // Fetch host profile picture and username for top menu bar
  Future<void> _fetchHostProfilePicture() async {
    try {
      // Get all users to find the host's profile picture and username
      final users = await ApiService.getAllUsers();
      final hostUser = users.firstWhere(
        (user) => user['id'] == widget.receiverId,
        orElse: () => null,
      );

      if (hostUser != null) {
        setState(() {
          _hostProfilePic = hostUser['profile_pic'];
          _hostUsername =
              hostUser['username'] ?? hostUser['first_name'] ?? 'Host';
        });
        debugPrint('✅ Fetched host profile picture: $_hostProfilePic');
        debugPrint('✅ Fetched host username: $_hostUsername');
      } else {
        debugPrint(
          '⚠️ Host profile picture not found for ID: ${widget.receiverId}',
        );
      }
    } catch (e) {
      debugPrint('❌ Error fetching host profile picture: $e');
    }
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
            children:
                data.entries.map((entry) {
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

  Widget _buildDebugSection(String title, Map<String, String> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.orange,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        if (data.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[700]!),
            ),
            child: Column(
              children:
                  data.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Text(
                            '${entry.key}: ',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              entry.value,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
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

  void _handlePKBattleNotification(
    String message, {
    String? leftHostId,
    String? rightHostId,
    String? leftHostName,
    String? rightHostName,
    String? liveId,
    String? pkBattleId,
  }) {
    // PK battle notification handling disabled - no notifications shown
    debugPrint('🎯 PK battle notification received but disabled: $message');

    // Still update PK battle ID for internal tracking
    _pkBattleId = pkBattleId ?? PKEvents.currentPKBattleId?.toString();

    // Show timer when PK battle starts (without notification)
    if (message.contains('Started')) {
      setState(() {
        _showPKBattleTimer = true;
      });
    } else if (message.contains('Ended')) {
      setState(() {
        _showPKBattleTimer = false;
      });
    }
  }

  void _handlePKBattleAccepted(
    String leftHostId,
    String rightHostId,
    String leftHostName,
    String rightHostName,
    String liveId,
  ) async {
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
    debugPrint(
      '🎯 PK battle ID will be fetched by stream ID in periodic timer',
    );
  }

  void _handlePKBattleAutoEnded(int winnerId, String reason) {
    debugPrint('🚨 PK BATTLE AUTO-ENDED ===');
    debugPrint('🚨 Winner ID: $winnerId');
    debugPrint('🚨 Reason: $reason');
    debugPrint('🚨 PK Battle ID: ${PKEvents.currentPKBattleId}');
    debugPrint('🚨 Left Host: $_leftHostName (ID: $_leftHostId)');
    debugPrint('🚨 Right Host: $_rightHostName (ID: $_rightHostId)');

    // Call PK battle end API on all devices (both host and audience)
    if (PKEvents.currentPKBattleId != null) {
      try {
        // Get current scores from the progress bar or use default values
        final leftScore = 0; // Will be updated by the API call
        final rightScore = 0; // Will be updated by the API call

        ApiService.endPKBattle(
              pkBattleId: PKEvents.currentPKBattleId!,
              leftScore: leftScore,
              rightScore: rightScore,
              winnerId: winnerId,
            )
            .then((result) {
              debugPrint('✅ PK battle auto-ended via API: $result');
            })
            .catchError((e) {
              debugPrint('❌ Error auto-ending PK battle via API: $e');
            });
      } catch (e) {
        debugPrint('❌ Error in auto-end PK battle API call: $e');
      }
    }

    // Clear PK battle ID and return to normal mode
    PKEvents.setCurrentPKBattleId(null);
    setState(() {
      _pkBattleId = null;
      _showPKBattleTimer = false;
      _leftHostId = null;
      _rightHostId = null;
      _leftHostName = null;
      _rightHostName = null;
    });
    debugPrint(
      '🎯 PK battle ID cleared after auto-end, returning to normal single host mode',
    );

    // Show PK battle ended popup for all users
    if (mounted) {
      // Use left/right instead of Unknown for usernames
      final leftHostName = _leftHostName ?? 'Left Host';
      final rightHostName = _rightHostName ?? 'Right Host';

      PKBattleEndedService.instance.showPKBattleEndedPopup(
        context: context,
        winnerId: winnerId,
        leftScore: 0, // Will be updated by the API
        rightScore: 0, // Will be updated by the API
        leftHostName: leftHostName,
        rightHostName: rightHostName,
        leftHostId: _leftHostId,
        rightHostId: _rightHostId,
      );
    }
  }

  void _triggerPKBattleScoreUpdate() {
    debugPrint('🎯 Manually triggering PK battle score update');
    setState(() {}); // Force rebuild to refresh progress bar
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
          debugPrint(
            '✅ Stream ID fetch found PK battle: ${pkBattle['pk_battle_id']}',
          );
          PKEvents.setCurrentPKBattleId(pkBattle['pk_battle_id']);

          // Restart polling for transactions when new PK battle starts
          _stopPKBattleTransactionsPolling();
          _startPKBattleTransactionsPolling();

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
      final battleEndTime = PKEvents.currentPKBattleStartTime!.add(
        const Duration(minutes: 3),
      );

      if (now.isBefore(battleEndTime)) {
        setState(() {
          _showPKBattleTimer = true;
        });
      }
    }
  }

  // Poll for recent gifts to synchronize animations across devices
  Timer? _giftPollingTimer;
  DateTime _lastGiftCheck = DateTime.now();

  // Host-side polling for user-received gifts (non-PK normal live)
  Timer? _userGiftsPollingTimer;
  final Set<String> _processedUserGiftTxnIds = {};
  DateTime _lastUserGiftsCheck = DateTime.now();

  void _startGiftPolling() {
    _giftPollingTimer?.cancel();
    _giftPollingTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      // Check if PK battle is active
      if (PKEvents.currentPKBattleId != null) {
        // PK battle active - poll for PK battle gifts
        debugPrint('🎁 PK Battle active, polling for PK battle gifts');
        _pollForPKBattleGifts();
      } else {
        // Single host normal live - use the original working logic
        debugPrint('🎁 Single host normal live, using original gift polling');
        _pollForRecentGifts();
      }
    });
  }

  void _stopGiftPolling() {
    _giftPollingTimer?.cancel();
    _giftPollingTimer = null;
  }

  // Start polling user gifts for host in normal (single host) live
  void _startUserGiftsPolling() {
    _userGiftsPollingTimer?.cancel();
    _lastUserGiftsCheck = DateTime.now();
    _userGiftsPollingTimer = Timer.periodic(const Duration(seconds: 2), (
      timer,
    ) {
      // Only for single host normal live (no PK battle)
      if (PKEvents.currentPKBattleId == null) {
        final int targetUserId =
            widget.isHost
                ? ((_currentUser?['id'] as int?) ?? widget.receiverId)
                : widget.receiverId;
        _pollUserGiftsReceived(targetUserId);
      }
    });
  }

  void _stopUserGiftsPolling() {
    _userGiftsPollingTimer?.cancel();
    _userGiftsPollingTimer = null;
  }

  Future<void> _pollForRecentGifts() async {
    try {
      final streamId = _debugInfo['stream_id'];
      if (streamId == null) return;
      int liveStreamId;
      if (streamId is int) {
        liveStreamId = streamId;
      } else if (streamId is String) {
        liveStreamId = int.tryParse(streamId) ?? 0;
      } else {
        return;
      }

      // Get recent gifts from the last 5 seconds
      final recentGifts = await ApiService.getRecentGifts(
        liveStreamId: liveStreamId,
        since: _lastGiftCheck,
      );

      if (recentGifts.isNotEmpty) {
        debugPrint('🎁 Found ${recentGifts.length} recent gifts to sync');

        for (final gift in recentGifts) {
          // Check if we already processed this gift
          final giftKey =
              '${gift['sender_id']}_${gift['gift_id']}_${gift['timestamp']}';
          if (!_processedGifts.contains(giftKey)) {
            _processedGifts.add(giftKey);

            // Play gift audio if available (with 2-second delay)
            final dynamic audioFilenameRaw = gift['audio_filename'];
            final String? audioFilename =
                (audioFilenameRaw is String)
                    ? audioFilenameRaw
                    : (audioFilenameRaw?.toString());
            if (audioFilename != null && audioFilename.isNotEmpty) {
              try {
                final audioUrl =
                    'https://server.bharathchat.com/uploads/audio/$audioFilename';
                debugPrint('🎁 Playing received gift audio: $audioUrl');
                // Use the new 2-second delay method
                _playGiftAudioWithDelay(audioUrl);
              } catch (e) {
                debugPrint('🎁 Error playing received gift audio: $e');
              }
            }

            final dynamic gifFilenameRaw = gift['gif_filename'];
            final String gifFilename =
                (gifFilenameRaw is String)
                    ? gifFilenameRaw
                    : (gifFilenameRaw?.toString() ?? '');
            final gifUrl =
                'https://server.bharathchat.com/uploads/gifts/$gifFilename';
            final senderName = gift['sender_name'] ?? 'User';
            final giftName = gift['gift_name'] ?? 'Gift';

            // Determine PK battle side if applicable
            String? pkBattleSide;
            final isPKBattle = PKEvents.currentPKBattleId != null;
            if (isPKBattle && gift['receiver_id'] != null) {
              final receiverId = gift['receiver_id'];
              if (receiverId == int.tryParse(_leftHostId ?? '0')) {
                pkBattleSide = 'left';
              } else if (receiverId == int.tryParse(_rightHostId ?? '0')) {
                pkBattleSide = 'right';
              }
            }

            // Create gift animation
            _createGiftAnimation(giftName, gifUrl, senderName, pkBattleSide);
          }
        }
      }

      _lastGiftCheck = DateTime.now();
    } catch (e) {
      debugPrint('❌ Error polling for recent gifts: $e');
    }
  }

  // Poll for PK battle gifts and display
  Future<void> _pollForPKBattleGifts() async {
    try {
      if (PKEvents.currentPKBattleId == null) return;

      final pkBattleId = PKEvents.currentPKBattleId!;
      debugPrint('🎁 Polling for PK battle gifts, battle ID: $pkBattleId');

      // For PK battles, we need to poll both hosts' gifts received
      final leftHostId =
          _leftHostId != null ? int.tryParse(_leftHostId!) : null;
      final rightHostId =
          _rightHostId != null ? int.tryParse(_rightHostId!) : null;

      if (leftHostId != null && leftHostId > 0) {
        await _pollUserGiftsReceived(leftHostId);
      }

      if (rightHostId != null && rightHostId > 0) {
        await _pollUserGiftsReceived(rightHostId);
      }
    } catch (e) {
      debugPrint('❌ Error polling for PK battle gifts: $e');
    }
  }

  // Poll gifts received by specific user and display
  Future<void> _pollUserGiftsReceived(int targetUserId) async {
    try {
      final data = await ApiService.getUserGiftsReceived(
        userIdentifier: targetUserId,
      );
      if (data == null) return;
      final List<dynamic>? recentGifts = data['recent_gifts'] as List<dynamic>?;
      if (recentGifts == null || recentGifts.isEmpty) return;

      for (final dynamic g in recentGifts) {
        final Map<String, dynamic> gift = g as Map<String, dynamic>;
        // Time-based filtering to avoid replaying old gifts too frequently
        final String? receivedAtStr = gift['received_at'] as String?;
        if (receivedAtStr != null) {
          try {
            final receivedAt = DateTime.parse(receivedAtStr);
            if (!receivedAt.isAfter(_lastUserGiftsCheck)) {
              continue;
            }
          } catch (_) {}
        }

        // Deduplication by transaction_id
        final int? txnId =
            (gift['transaction_id'] is int)
                ? gift['transaction_id'] as int
                : int.tryParse('${gift['transaction_id']}');
        if (txnId == null) continue;
        final giftKey = 'user_${targetUserId.toString()}_txn_$txnId';
        if (_processedUserGiftTxnIds.contains(giftKey)) continue;
        _processedUserGiftTxnIds.add(giftKey);

        // Play audio (2s delay)
        final dynamic audioFilenameRaw = gift['audio_filename'];
        final String? audioFilename =
            (audioFilenameRaw is String)
                ? audioFilenameRaw
                : (audioFilenameRaw?.toString());
        if (audioFilename != null && audioFilename.isNotEmpty) {
          try {
            final audioUrl =
                'https://server.bharathchat.com/uploads/audio/$audioFilename';
            debugPrint(
              '🎁 (User $targetUserId) Playing received gift audio: $audioUrl',
            );
            // Use the existing 2-second delay method
            _playGiftAudioWithDelay(audioUrl);
          } catch (e) {
            debugPrint(
              '🎁 (User $targetUserId) Error playing received gift audio: $e',
            );
          }
        }

        // Animation
        String gifUrl;
        final dynamic gifUrlRaw = gift['gif_url'];
        if (gifUrlRaw is String && gifUrlRaw.isNotEmpty) {
          gifUrl =
              gifUrlRaw.startsWith('http')
                  ? gifUrlRaw
                  : 'https://server.bharathchat.com$gifUrlRaw';
        } else {
          final dynamic gifFilenameRaw = gift['gif_filename'];
          final String gifFilename =
              (gifFilenameRaw is String)
                  ? gifFilenameRaw
                  : (gifFilenameRaw?.toString() ?? '');
          gifUrl = 'https://server.bharathchat.com/uploads/gifts/$gifFilename';
        }
        final Map<String, dynamic>? sender =
            gift['sender'] as Map<String, dynamic>?;
        final String senderName =
            sender?['username'] as String? ??
            sender?['first_name'] as String? ??
            'User';
        final String giftName = gift['gift_name'] as String? ?? 'Gift';

        // Determine PK battle side if applicable
        String? pkBattleSide;
        if (PKEvents.currentPKBattleId != null) {
          final leftHostIdInt = int.tryParse(_leftHostId ?? '0');
          final rightHostIdInt = int.tryParse(_rightHostId ?? '0');
          if (targetUserId == leftHostIdInt) {
            pkBattleSide = 'left';
          } else if (targetUserId == rightHostIdInt) {
            pkBattleSide = 'right';
          }
        }

        _createGiftAnimation(giftName, gifUrl, senderName, pkBattleSide);
      }

      _lastUserGiftsCheck = DateTime.now();
    } catch (e) {
      debugPrint('❌ Error polling user gifts received: $e');
    }
  }

  // Helper method to play gift audio with 2-second delay
  Future<void> _playGiftAudioWithDelay(String audioUrl) async {
    try {
      // Wait 2 seconds before playing audio
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        await _giftAudioPlayer.setUrl(audioUrl);
        await _giftAudioPlayer.play();
      }
    } catch (e) {
      debugPrint('🎁 Error playing gift audio with delay: $e');
    }
  }

  // Set to track processed gifts to avoid duplicates
  final Set<String> _processedGifts = {};

  // Handle in-room commands for gift animations (legacy - kept for compatibility)
  void _handleInRoomCommand(String command) {
    try {
      final data = jsonDecode(command);
      if (data['type'] == 'gift') {
        debugPrint('🎁 Processing gift command: $data');

        // Play gift audio if available (with 2-second delay)
        final dynamic audioFilenameRaw = data['audio_filename'];
        final String? audioFilename =
            (audioFilenameRaw is String)
                ? audioFilenameRaw
                : (audioFilenameRaw?.toString());
        if (audioFilename != null && audioFilename.isNotEmpty) {
          try {
            final audioUrl =
                'https://server.bharathchat.com/uploads/audio/$audioFilename';
            debugPrint('🎁 Playing gift audio from command: $audioUrl');
            // Use the new 2-second delay method
            _playGiftAudioWithDelay(audioUrl);
          } catch (e) {
            debugPrint('🎁 Error setting up gift audio from command: $e');
          }
        }

        final dynamic gifFilenameRaw = data['gif_filename'];
        final String gifFilename =
            (gifFilenameRaw is String)
                ? gifFilenameRaw
                : (gifFilenameRaw?.toString() ?? '');
        final gifUrl =
            'https://server.bharathchat.com/uploads/gifts/$gifFilename';
        final senderName = data['sender_name'] ?? 'User';
        final giftName = data['gift_name'] ?? 'Gift';

        // Determine PK battle side if applicable
        String? pkBattleSide;
        final isPKBattle = PKEvents.currentPKBattleId != null;
        if (isPKBattle && data['receiver_id'] != null) {
          final receiverId = data['receiver_id'];
          if (receiverId == int.tryParse(_leftHostId ?? '0')) {
            pkBattleSide = 'left';
          } else if (receiverId == int.tryParse(_rightHostId ?? '0')) {
            pkBattleSide = 'right';
          }
        }

        // Create gift animation
        _createGiftAnimation(giftName, gifUrl, senderName, pkBattleSide);
      }
    } catch (e) {
      debugPrint('❌ Error processing in-room command: $e');
    }
  }

  // Create gift animation (reusable method)
  void _createGiftAnimation(
    String giftName,
    String gifUrl,
    String senderName,
    String? pkBattleSide,
  ) {
    debugPrint('🎁 Creating gift animation:');
    debugPrint('🎁   - Gift Name: $giftName');
    debugPrint('🎁   - GIF URL: $gifUrl');
    debugPrint('🎁   - Sender: $senderName');
    debugPrint('🎁   - PK Battle Side: $pkBattleSide');

    setState(() {
      _activeGiftAnimations.add(
        GiftAnimation(
          key: ValueKey('gift_anim_${_giftAnimKey++}'),
          giftName: giftName,
          gifUrl: gifUrl,
          senderName: senderName,
          isPKBattleGift: PKEvents.currentPKBattleId != null,
          pkBattleSide: pkBattleSide,
          onAnimationComplete: () {
            debugPrint('🎁 Gift animation completed, removing from list');
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

    // Play gift audio if available (with 2-second delay)
    // Note: Audio is now handled by the calling methods using _playGiftAudioWithDelay
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
        debugPrint(
          '⏰ Set local start time: ${PKEvents.currentPKBattleStartTime}',
        );
      }

      // Fetch PK battle ID if not available (with 2-second delay for backend timing)
      if (PKEvents.currentPKBattleId == null) {
        Future.delayed(Duration(seconds: 2), () {
          _fetchPKBattleDataFromServer();
        });
      }
    } else {
      debugPrint('🏁 Exiting PK battle state...');
      // Clear PK battle data when exiting (for both hosts and audience)
      PKEvents.setCurrentPKBattleId(null);
      setState(() {
        _showPKBattleTimer = false;
        _pkBattleId = null;
        _leftHostId = null;
        _rightHostId = null;
        _leftHostName = null;
        _rightHostName = null;
      });
      PKEvents.setCurrentPKBattleStartTime(null);
      debugPrint(
        '🎯 PK battle data cleared, returning to normal single host mode',
      );
    }
  }

  void _fetchPKBattleDataFromServer() async {
    debugPrint('🔍 Fetching PK battle data from server...');
    _logApiCall('PK Battle', 'Fetching PK battle data...');

    try {
      // Use stream ID for both hosts and audience
      final streamId = _debugInfo['stream_id'];

      if (streamId != null) {
        _logApiCall(
          'getActivePKBattleByStreamId',
          'Calling API with stream ID: $streamId',
        );

        debugPrint('🔍 Fetching PK battle for stream: $streamId');
        final pkBattle = await ApiService.getActivePKBattleByStreamId(streamId);

        if (pkBattle != null) {
          _logApiCall(
            'getActivePKBattleByStreamId',
            'Success: PK Battle ${pkBattle['pk_battle_id']} found',
          );
          _updateDebugInfo('pk_battle', pkBattle);

          // Set PK battle ID and start time
          debugPrint('🔧 Setting PK Battle ID: ${pkBattle['pk_battle_id']}');
          PKEvents.setCurrentPKBattleId(pkBattle['pk_battle_id']);
          debugPrint('🔧 PK Battle ID set to: ${PKEvents.currentPKBattleId}');

          // Restart polling for transactions when new PK battle starts
          _stopPKBattleTransactionsPolling();
          _startPKBattleTransactionsPolling();

          // Update local state for UI reactivity
          setState(() {
            _pkBattleId = pkBattle['pk_battle_id']?.toString();
          });

          if (pkBattle['start_time'] != null) {
            final serverStartTime = DateTime.parse(pkBattle['start_time']);
            PKEvents.setCurrentPKBattleStartTime(serverStartTime);
            debugPrint('⏰ Server start time: $serverStartTime');
            debugPrint(
              '⏰ End time will be: ${serverStartTime.add(Duration(minutes: 3))}',
            );
            _updateDebugInfo(
              'pk_battle_start_time',
              serverStartTime.toString(),
            );
          }

          // Set host information for both hosts and audience
          setState(() {
            _leftHostId = pkBattle['left_host_id']?.toString();
            _rightHostId = pkBattle['right_host_id']?.toString();
            _leftHostName = pkBattle['left_host_name'];
            _rightHostName = pkBattle['right_host_name'];
            _showPKBattleTimer = true;
          });

          debugPrint(
            '👤 Left Host: ${pkBattle['left_host_name']} (${pkBattle['left_host_id']})',
          );
          debugPrint(
            '👤 Right Host: ${pkBattle['right_host_name']} (${pkBattle['right_host_id']})',
          );

          // Update debug info with both hosts
          _updateDebugInfo('left_host_id', pkBattle['left_host_id']);
          _updateDebugInfo('right_host_id', pkBattle['right_host_id']);
          _updateDebugInfo('left_host_name', pkBattle['left_host_name']);
          _updateDebugInfo('right_host_name', pkBattle['right_host_name']);
          _updateDebugInfo('left_score', pkBattle['left_score']);
          _updateDebugInfo('right_score', pkBattle['right_score']);
          _updateDebugInfo('left_stream_id', pkBattle['left_stream_id']);
          _updateDebugInfo('right_stream_id', pkBattle['right_stream_id']);
          _updateDebugInfo('pk_battle_status', pkBattle['status']);

          debugPrint(
            '✅ Got PK battle data from server: ${pkBattle['pk_battle_id']}',
          );
          debugPrint(
            '✅ Left Host ID: ${pkBattle['left_host_id']}, Right Host ID: ${pkBattle['right_host_id']}',
          );
          debugPrint(
            '✅ Left Score: ${pkBattle['left_score']}, Right Score: ${pkBattle['right_score']}',
          );

          setState(() {}); // Refresh UI to show progress bar and timer
        } else {
          _logApiCall(
            'getActivePKBattleByStreamId',
            'No active PK battle found for stream: $streamId',
          );
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

    // Call PK battle end API on all devices (both host and audience)
    try {
      final endResult = await ApiService.endPKBattle(
        pkBattleId: pkBattleId,
        leftScore: leftScore,
        rightScore: rightScore,
        winnerId: winnerId,
      );
      debugPrint('✅ PK battle ended via API: $endResult');
    } catch (e) {
      debugPrint('❌ Error ending PK battle via API: $e');
    }

    // Stop polling for transactions when PK battle ends
    _stopPKBattleTransactionsPolling();

    // Clear PK battle ID and return to normal mode
    PKEvents.setCurrentPKBattleId(null);
    setState(() {
      _pkBattleId = null;
      _showPKBattleTimer = false;
      _leftHostId = null;
      _rightHostId = null;
      _leftHostName = null;
      _rightHostName = null;
    });
    debugPrint('🎯 PK battle ID cleared, returning to normal single host mode');

    // Show improved popup using the service for all users
    if (mounted) {
      // Use left/right instead of Unknown for usernames
      final leftHostName = _leftHostName ?? 'Left Host';
      final rightHostName = _rightHostName ?? 'Right Host';

      PKBattleEndedService.instance.showPKBattleEndedPopup(
        context: context,
        winnerId: winnerId,
        leftScore: leftScore,
        rightScore: rightScore,
        leftHostName: leftHostName,
        rightHostName: rightHostName,
        leftHostId: _leftHostId,
        rightHostId: _rightHostId,
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
    config.audioVideoView.showUserNameOnView = false;

    // Member button configuration with custom builder
    config.memberButton.builder = (int memberCount) {
      return Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [Colors.orange.shade300, Colors.orange.shade600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            const Icon(Icons.people, color: Colors.white, size: 18),
            if (memberCount > 0)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    memberCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    };

    // Member list configuration with custom item builder
    config.memberList.itemBuilder = (
      BuildContext context,
      Size size,
      ZegoUIKitUser user,
      Map<String, dynamic> extraInfo,
    ) {
      // Get user profile from our cached data
      final userProfile = _userProfiles[user.id];
      final profilePic = userProfile?['profile_pic'];
      final username =
          userProfile?['username'] ?? userProfile?['first_name'] ?? user.name;

      // Clean username by removing "user_" prefix and avatar info
      String cleanUsername = username;
      if (cleanUsername.startsWith('user_')) {
        cleanUsername = cleanUsername.substring(5);
      }
      if (cleanUsername.contains('|avatar:')) {
        cleanUsername = cleanUsername.split('|avatar:')[0];
      }

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            // User avatar
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.orange.shade300, width: 2),
              ),
              child: ClipOval(
                child:
                    profilePic != null && profilePic.isNotEmpty
                        ? CachedNetworkImage(
                          imageUrl:
                              profilePic.startsWith('http')
                                  ? profilePic
                                  : 'https://server.bharathchat.com/$profilePic',
                          fit: BoxFit.cover,
                          placeholder:
                              (context, url) => Container(
                                color: Colors.grey[300],
                                child: const Icon(
                                  Icons.person,
                                  color: Colors.grey,
                                ),
                              ),
                          errorWidget:
                              (context, url, error) => Container(
                                color: Colors.grey[300],
                                child: Text(
                                  cleanUsername.isNotEmpty
                                      ? cleanUsername[0].toUpperCase()
                                      : 'U',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                        )
                        : Container(
                          color: Colors.orange.shade300,
                          child: Text(
                            cleanUsername.isNotEmpty
                                ? cleanUsername[0].toUpperCase()
                                : 'U',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
              ),
            ),
            const SizedBox(width: 12),
            // User info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cleanUsername,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (user.id == widget.localUserID && widget.isHost)
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade400,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Host',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Online indicator
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1),
              ),
            ),
          ],
        ),
      );
    };

    // Custom start live button with app theme color
    config.startLiveButtonBuilder = (
      BuildContext context,
      VoidCallback startLive,
    ) {
      return Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              Colors.orange.shade300,
              Colors.orange,
              Colors.orange.shade700,
            ],
            center: Alignment.center,
            radius: 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withOpacity(0.4),
              blurRadius: 15,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.orange.withOpacity(0.2),
              blurRadius: 25,
              spreadRadius: 5,
              offset: const Offset(0, 0),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(30),
            onTap: startLive,
            child: Center(
              child: Image.asset(
                'assets/start.png',
                // width: 32,
                // height: 32,
                width: 65,
                height: 65,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      );
    };

    // Customize text message UI with profile pictures
    config.inRoomMessage.showAvatar = true;
    config.inRoomMessage.showName = true;
    config.inRoomMessage.backgroundColor = Colors.black.withOpacity(0.6);
    config.inRoomMessage.opacity = 0.8;
    config.inRoomMessage.maxLines = 1;
    config.inRoomMessage.borderRadius = BorderRadius.circular(12);
    config.inRoomMessage.paddings = const EdgeInsets.symmetric(
      horizontal: 8,
      vertical: 4,
    );
    config.inRoomMessage.nameTextStyle = const TextStyle(
      color: Colors.orange,
      fontSize: 12,
      fontWeight: FontWeight.bold,
    );
    config.inRoomMessage.messageTextStyle = const TextStyle(
      color: Colors.white,
      fontSize: 12,
    );
    // Add user ID and profile picture attributes
    config.inRoomMessage.attributes = () {
      return {
        'user_id': widget.profilePic != null ? 'current_user' : '',
        'profile_pic': widget.profilePic ?? '',
      };
    };
    // Custom item builder for enhanced profile picture display
    config.inRoomMessage.itemBuilder = (
      BuildContext context,
      ZegoInRoomMessage message,
      Map<String, dynamic> extraInfo,
    ) {
      // Get user ID and profile picture from attributes
      final attributes = message.attributes;
      final userId = attributes['user_id'] ?? '';
      final profilePic = attributes['profile_pic'] ?? '';

      // Clean username by removing "user_" prefix
      final cleanUsername =
          message.user.name.startsWith('user_')
              ? message.user.name.substring(5)
              : message.user.name;

      return GestureDetector(
        onTap: () {
          // Only show block popup for hosts
          if (widget.isHost) {
            _showBlockUserPopup(context, cleanUsername, message.user.id);
          }
        },
        child: Container(
          width: 160,
          // width: 50,
          // Further reduced width
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange.withOpacity(0.3), width: 1),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Picture
              Container(
                width: 20,
                height: 20,
                margin: const EdgeInsets.only(right: 6),
                child: ClipOval(
                  child: customAvatarBuilder(
                    context,
                    const Size(20, 20),
                    message.user,
                    extraInfo,
                    profilePic: profilePic.isNotEmpty ? profilePic : null,
                  ),
                ),
              ),
              // Message Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User Name
                    Text(
                      cleanUsername,
                      style: const TextStyle(
                        color: Colors.orange,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 1),
                    // Message Text
                    Text(
                      message.message,
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    };

    // Custom button styles for enhanced UI
    config
        .bottomMenuBar
        .buttonStyle = ZegoLiveStreamingBottomMenuBarButtonStyle(
      // Camera button icons with enhanced colors
      toggleCameraOnButtonIcon: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            // colors: [Color(0xFFFF512F), Color(0xFFF09819)],
            colors: [Color(0xFFD4FC79), Color(0xFF96E6A1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Icon(
          Icons.camera_alt_outlined,
          // color: Colors.white,
          color: Color(0xFF4A6B4F),
          size: 24,
        ),
      ),
      toggleCameraOffButtonIcon: const Icon(
        Icons.camera_alt_outlined,
        color: Colors.white,
        size: 24,
      ),

      // Microphone button icons with enhanced colors
      toggleMicrophoneOnButtonIcon: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            // colors: [Color(0xFF2193b0), Color(0xFF6dd5ed)],
            colors: [Color(0xFFFF9A9E), Color(0xFFFECFEF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Icon(
          Icons.mic_outlined,
          color: Color(0xFF7A4E4E),
          size: 24,
        ),
      ),
      toggleMicrophoneOffButtonIcon: const Icon(
        Icons.mic_off_outlined,
        color: Colors.red,
        size: 24,
      ),

      // Chat button icons with enhanced colors
      chatEnabledButtonIcon: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [Color(0xFFa18cd1), Color(0xFFfbc2eb)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Icon(
          Icons.chat_bubble_outline,
          color: Colors.white,
          size: 24,
        ),
      ),
      chatDisabledButtonIcon: const Icon(
        Icons.chat_bubble_outline,
        color: Colors.grey,
        size: 24,
      ),

      // Audio output button icons with enhanced colors
      switchAudioOutputToSpeakerButtonIcon: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [Color(0xFF2193b0), Color(0xFF6dd5ed)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Icon(
          Icons.volume_up_outlined,
          color: Colors.white,
          size: 24,
        ),
      ),
      switchAudioOutputToHeadphoneButtonIcon: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [Color(0xFF2193b0), Color(0xFF6dd5ed)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Icon(
          Icons.headphones_outlined,
          color: Colors.white,
          size: 24,
        ),
      ),
      switchAudioOutputToBluetoothButtonIcon: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [Color(0xFF2193b0), Color(0xFF6dd5ed)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Icon(
          Icons.bluetooth_outlined,
          color: Colors.white,
          size: 24,
        ),
      ),

      // Leave button icon with enhanced color
      leaveButtonIcon: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [Color(0xFFffa030), Color(0xFFfe9b00)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Icon(
          Icons.call_end_outlined,
          color: Colors.white,
          size: 24,
        ),
      ),

      // Beauty effect button icon
      beautyEffectButtonIcon: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            // colors: [Color(0xFFf00000), Color(0xFFff9966)],
            colors: [Color(0xFFFFDEE9), Color(0xFFB5FFFC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Icon(
          Icons.face_outlined,
          color: Color(0xFF7A7A7A),
          size: 24,
        ),
      ),

      // Sound effect button icon
      soundEffectButtonIcon: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            // colors: [Color(0xFF00b09b), Color(0xFF96c93d)],
            colors: [Color(0xFFE0C3FC), Color(0xFF8EC5FC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Icon(
          Icons.graphic_eq_outlined,
          // color: Colors.white,
          color: Color(0xFF5B5B8F),
          size: 24,
        ),
      ),
      switchCameraButtonIcon: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            // colors: [Color(0xFF00b09b), Color(0xFF96c93d)],
            colors: [Color(0xFFa1c4fd), Color(0xFFc2e9fb)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Icon(
          Icons.flip_camera_ios,
          color: Color(0xFF425C78),
          size: 24,
        ),
      ),
    );

    // If pkBattle is not a valid property, comment or remove the next line
    // config.pkBattle = pkConfig();

    // Configure host avatar in top menu bar
    config.topMenuBar.hostAvatarBuilder = (ZegoUIKitUser host) {
      return Container(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Host avatar
            customAvatarBuilder(
              context,
              const Size(40, 40),
              host,
              {},
              profilePic: _hostProfilePic ?? widget.profilePic,
            ),
            const SizedBox(width: 8),
            // Host username
            if (_hostUsername != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _hostUsername!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      );
    };

    config.topMenuBar.buttons = [
      // ZegoLiveStreamingMenuBarButtonName.minimizingButton,
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
              userName: widget.localUserID,
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
            // VS Image overlay - positioned between progress bar and timer
            if (_showPKBattleTimer)
              Positioned(
                top:
                    MediaQuery.of(context).size.height * 0.55 +
                    60, // Between progress bar and timer
                left: 0,
                right: 0,
                child: Center(
                  child: Image.asset(
                    'assets/vs.png',
                    height: 40,
                    width: 40,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.9),
                        ),
                        child: const Center(
                          child: Text(
                            'VS',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            // PK Battle notification overlay - disabled
            // PK Battle timer overlay - positioned below progress bar
            if (_showPKBattleTimer)
              Positioned(
                top:
                    MediaQuery.of(context).size.height * 0.55 +
                    100, // Just below the VS image
                left: 0,
                right: 0,
                child: Center(
                  child:
                      PKEvents.currentPKBattleStartTime != null
                          ? PKBattleTimer(
                            battleStartTime: PKEvents.currentPKBattleStartTime!,
                            onTimerEnd: _onPKBattleTimerEnd,
                          )
                          : Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF4CAF50),
                                  Color(0xFFFFEB3B),
                                  Color(0xFF4CAF50),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Loading Timer...',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                ),
              ),
            // PK Battle progress bar overlay
            if (_showPKBattleTimer)
              Positioned(
                top: MediaQuery.of(context).size.height * 0.55,
                left: 0,
                right: 0,
                child: Center(
                  child: Builder(
                    builder: (context) {
                      debugPrint(
                        'Progress Bar - LeftName: $_leftHostName, RightName: $_rightHostName, PKID: ${PKEvents.currentPKBattleId}',
                      );
                      return PKEvents.currentPKBattleId != null
                          ? PKBattleProgressBar(
                            pkBattleId: PKEvents.currentPKBattleId!,
                            leftHostName: _leftHostName,
                            rightHostName: _rightHostName,
                            onScoreUpdate: () {
                              debugPrint('🎯 PK Battle score update received');
                              setState(() {}); // Refresh UI
                            },
                          )
                          : Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: Colors.yellow,
                                width: 2,
                              ),
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
            // if (_showPKBattleTimer)
            //   Positioned(
            //     bottom: 300,
            //     left: 0,
            //     right: 0,
            //     child: Center(
            //       child: Container(
            //         padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            //         decoration: BoxDecoration(
            //           gradient: const LinearGradient(
            //             colors: [Color(0xFF4CAF50), Color(0xFFFFEB3B), Color(0xFF4CAF50)],
            //             begin: Alignment.topLeft,
            //             end: Alignment.bottomRight,
            //           ),
            //           borderRadius: BorderRadius.circular(20),
            //           boxShadow: [
            //             BoxShadow(
            //               color: Colors.black.withOpacity(0.3),
            //               blurRadius: 8,
            //               offset: const Offset(0, 4),
            //             ),
            //           ],
            //         ),
            //         child: Text(
            //           'PK Battle ID: ${_pkBattleId ?? PKEvents.currentPKBattleId ?? "Loading..."}',
            //           style: const TextStyle(
            //             color: Colors.white,
            //             fontWeight: FontWeight.bold,
            //             fontSize: 18,
            //           ),
            //         ),
            //       ),
            //     ),
            //   ),
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
            // Debug indicator for gift status (audience only)
            // if (!widget.isHost)
            //   Positioned(
            //     left: 12,
            //     bottom: 160,
            //     child: Container(
            //       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            //       decoration: BoxDecoration(
            //         color: Colors.black.withOpacity(0.7),
            //         borderRadius: BorderRadius.circular(8),
            //       ),
            //       child: Text(
            //         'Gifts: ${_gifts.length} | Loading: $_giftsLoading | Diamonds: ${_currentUser?['diamonds'] ?? 'N/A'}',
            //         style: const TextStyle(
            //           color: Colors.white,
            //           fontSize: 10,
            //         ),
            //       ),
            //     ),
            //   ),
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
                                ? () {
                                  debugPrint('🎁 Gift tapped: ${gift['name']}');
                                  debugPrint(
                                    '🎁 Can afford: $canAfford, Sending: $_sendingGift',
                                  );
                                  _showGiftConfirmationDialog(
                                    gift,
                                    gift['diamond_amount'],
                                    DateTime.now().millisecondsSinceEpoch
                                        .toString(),
                                    () => _sendGiftFromList(gift),
                                  );
                                }
                                : () {
                                  debugPrint(
                                    '❌ Gift not clickable: ${gift['name']}',
                                  );
                                  debugPrint(
                                    '❌ Can afford: $canAfford, Sending: $_sendingGift',
                                  );
                                  debugPrint(
                                    '❌ User diamonds: ${_currentUser?['diamonds']}, Gift cost: ${gift['diamond_amount']}',
                                  );
                                },
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

            // Floating Debug Button
            // Positioned(
            //   top: 50,
            //   right: 12,
            //   child: GestureDetector(
            //     onTap: () {
            //       setState(() {
            //         _showDebugInfo = !_showDebugInfo;
            //       });
            //     },
            //     child: Container(
            //       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            //       decoration: BoxDecoration(
            //         color: _showDebugInfo ? Colors.orange : Colors.black.withOpacity(0.8),
            //         borderRadius: BorderRadius.circular(20),
            //         border: Border.all(color: Colors.orange, width: 2),
            //         boxShadow: [
            //           BoxShadow(
            //             color: Colors.black.withOpacity(0.3),
            //             blurRadius: 8,
            //             offset: const Offset(0, 2),
            //           ),
            //         ],
            //       ),
            //       // child: Row(
            //       //   mainAxisSize: MainAxisSize.min,
            //       //   children: [
            //       //     Icon(
            //       //       _showDebugInfo ? Icons.bug_report : Icons.bug_report_outlined,
            //       //       color: _showDebugInfo ? Colors.black : Colors.orange,
            //       //       size: 16,
            //       //     ),
            //       //     const SizedBox(width: 4),
            //       //     Text(
            //       //       'DEBUG',
            //       //       style: TextStyle(
            //       //         color: _showDebugInfo ? Colors.black : Colors.orange,
            //       //         fontSize: 12,
            //       //         fontWeight: FontWeight.bold,
            //       //       ),
            //       //     ),
            //       //   ],
            //       // ),
            //     ),
            //   ),
            // ),

            // Debug Overlay Panel
            if (_showDebugInfo)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.8),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Row(
                            children: [
                              const Icon(
                                Icons.bug_report,
                                color: Colors.orange,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'LIVE DEBUG PANEL',
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              const Spacer(),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _showDebugInfo = false;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.8),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Scrollable content
                          Expanded(
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Basic Info Section
                                  _buildDebugSection('📱 BASIC INFO', {
                                    'Is Host': widget.isHost.toString(),
                                    'Live ID': widget.liveID,
                                    'Local User ID': widget.localUserID,
                                    'Receiver ID': widget.receiverId.toString(),
                                    'Has Active PK Battle':
                                        (widget.activePKBattle != null)
                                            .toString(),
                                  }),

                                  const SizedBox(height: 16),

                                  // User Info Section
                                  _buildDebugSection('👤 USER INFO', {
                                    'User ID':
                                        '${_currentUser?['id'] ?? 'N/A'}',
                                    'Username':
                                        '${_currentUser?['username'] ?? 'N/A'}',
                                    'Name':
                                        '${_currentUser?['first_name'] ?? ''} ${_currentUser?['last_name'] ?? ''}'
                                            .trim(),
                                    'Diamonds':
                                        '${_currentUser?['diamonds'] ?? 'N/A'}',
                                    'Sending Gift': _sendingGift.toString(),
                                  }),

                                  const SizedBox(height: 16),

                                  // PK Battle Info Section
                                  if (PKEvents.currentPKBattleId != null)
                                    _buildDebugSection('🎮 PK BATTLE INFO', {
                                      'PK Battle ID':
                                          PKEvents.currentPKBattleId.toString(),
                                      'Left Host':
                                          '${_debugInfo['left_host_name'] ?? _leftHostName ?? 'Unknown'} (${_leftHostId ?? 'N/A'})',
                                      'Right Host':
                                          '${_debugInfo['right_host_name'] ?? _rightHostName ?? 'Unknown'} (${_rightHostId ?? 'N/A'})',
                                      'Left Score':
                                          _debugInfo['left_score']
                                              ?.toString() ??
                                          '0',
                                      'Right Score':
                                          _debugInfo['right_score']
                                              ?.toString() ??
                                          '0',
                                      'Status':
                                          _debugInfo['pk_battle_status']
                                              ?.toString() ??
                                          'N/A',
                                      'Show Timer':
                                          _showPKBattleTimer.toString(),
                                      'Show Notification':
                                          _showPKBattleNotification.toString(),
                                    }),

                                  const SizedBox(height: 16),

                                  // Gift Info Section
                                  _buildDebugSection('🎁 GIFT INFO', {
                                    'Gifts Loaded': '${_gifts.length}',
                                    'Gifts Loading': _giftsLoading.toString(),
                                    'Active Animations':
                                        '${_activeGiftAnimations.length}',
                                    'Live State':
                                        liveStateNotifier.value.toString(),
                                    'Stream ID':
                                        _debugInfo['stream_id']?.toString() ??
                                        'N/A',
                                  }),

                                  // PK Battle Gift Log Section
                                  if (ApiService.lastPKBattleGiftLog != null)
                                    _buildDebugSection('📡 PK BATTLE GIFT LOG', {
                                      'Timestamp':
                                          ApiService
                                              .lastPKBattleGiftLog!['timestamp'] ??
                                          'N/A',
                                      'Request ID':
                                          ApiService
                                              .lastPKBattleGiftLog!['request_id'] ??
                                          'N/A',
                                      'Success':
                                          ApiService
                                              .lastPKBattleGiftLog!['success']
                                              ?.toString() ??
                                          'N/A',
                                      'Status Code':
                                          ApiService
                                              .lastPKBattleGiftLog!['response_status']
                                              ?.toString() ??
                                          'N/A',
                                      'API Duration':
                                          ApiService
                                              .lastPKBattleGiftLog!['api_call_duration'] ??
                                          'N/A',
                                      'Total Duration':
                                          ApiService
                                              .lastPKBattleGiftLog!['total_duration'] ??
                                          'N/A',
                                      'PK Battle ID':
                                          ApiService
                                              .lastPKBattleGiftLog!['request']?['pk_battle_id']
                                              ?.toString() ??
                                          'N/A',
                                      'Sender ID':
                                          ApiService
                                              .lastPKBattleGiftLog!['request']?['sender_id']
                                              ?.toString() ??
                                          'N/A',
                                      'Receiver ID':
                                          ApiService
                                              .lastPKBattleGiftLog!['request']?['receiver_id']
                                              ?.toString() ??
                                          'N/A',
                                      'Gift ID':
                                          ApiService
                                              .lastPKBattleGiftLog!['request']?['gift_id']
                                              ?.toString() ??
                                          'N/A',
                                      'Amount':
                                          ApiService
                                              .lastPKBattleGiftLog!['request']?['amount']
                                              ?.toString() ??
                                          'N/A',
                                      'Response Status':
                                          ApiService
                                              .lastPKBattleGiftLog!['response_data']?['status']
                                              ?.toString() ??
                                          'N/A',
                                      'Left Score':
                                          ApiService
                                              .lastPKBattleGiftLog!['response_data']?['left_score']
                                              ?.toString() ??
                                          'N/A',
                                      'Right Score':
                                          ApiService
                                              .lastPKBattleGiftLog!['response_data']?['right_score']
                                              ?.toString() ??
                                          'N/A',
                                    }),

                                  const SizedBox(height: 16),

                                  // Test Buttons Section
                                  _buildDebugSection('🧪 TEST ACTIONS', {}),
                                  const SizedBox(height: 8),

                                  // Test Gift Button
                                  if (_gifts.isNotEmpty)
                                    GestureDetector(
                                      onTap: () {
                                        debugPrint(
                                          '🎁 Testing gift sending with first gift: ${_gifts.first['name']}',
                                        );
                                        _sendGiftFromList(_gifts.first);
                                      },
                                      child: Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withOpacity(0.8),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: const Text(
                                          '🎁 TEST GIFT SEND',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),

                                  const SizedBox(height: 8),

                                  // Test Host Selection Button
                                  if (liveStateNotifier.value ==
                                          ZegoLiveStreamingState.inPKBattle &&
                                      !widget.isHost)
                                    GestureDetector(
                                      onTap: () async {
                                        debugPrint(
                                          '🎁 Testing host selection dialog',
                                        );
                                        final result =
                                            await _showHostSelectionDialog();
                                        debugPrint(
                                          '🎁 Host selection result: $result',
                                        );
                                      },
                                      child: Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.withOpacity(0.8),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: const Text(
                                          '👥 TEST HOST SELECTION',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),

                                  const SizedBox(height: 8),

                                  // Test Host Name Fetching Button
                                  if (_leftHostId != null ||
                                      _rightHostId != null)
                                    GestureDetector(
                                      onTap: () async {
                                        debugPrint(
                                          '🧪 Testing host name fetching',
                                        );
                                        if (_leftHostId != null) {
                                          await ApiService.testGetUserById(
                                            int.tryParse(_leftHostId!) ?? 0,
                                          );
                                        }
                                        if (_rightHostId != null) {
                                          await ApiService.testGetUserById(
                                            int.tryParse(_rightHostId!) ?? 0,
                                          );
                                        }
                                      },
                                      child: Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.purple.withOpacity(0.8),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: const Text(
                                          '🧪 TEST HOST NAME FETCH',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),

                                  const SizedBox(height: 16),

                                  // API Logs Section
                                  _buildDebugSection(
                                    '📡 API LOGS (Last 10)',
                                    {},
                                  ),
                                  const SizedBox(height: 8),

                                  Container(
                                    height: 200,
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[900],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: ListView.builder(
                                      itemCount: _allApiLogs.take(10).length,
                                      itemBuilder: (context, index) {
                                        final log =
                                            _allApiLogs
                                                .take(10)
                                                .toList()[index];
                                        Color logColor = Colors.white;

                                        if (log.contains('🎁'))
                                          logColor = Colors.green;
                                        else if (log.contains('❌'))
                                          logColor = Colors.red;
                                        else if (log.contains('🎯'))
                                          logColor = Colors.orange;
                                        else if (log.contains('🚀'))
                                          logColor = Colors.blue;

                                        return Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 1,
                                          ),
                                          child: Text(
                                            log,
                                            style: TextStyle(
                                              color: logColor,
                                              fontSize: 10,
                                              fontFamily: 'monospace',
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
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
                          color: Colors.white,
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
                    // GestureDetector(
                    //   onTap: () {
                    //     setState(() {
                    //       _showDebugInfo = !_showDebugInfo;
                    //     });
                    //   },
                    //   child: Container(
                    //     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    //     decoration: BoxDecoration(
                    //       color: _showDebugInfo ? Colors.orange : Colors.black.withOpacity(0.7),
                    //       borderRadius: BorderRadius.circular(20),
                    //       border: Border.all(color: Colors.orange, width: 1),
                    //     ),
                    //     child: Text(
                    //       _showDebugInfo ? 'Hide Info' : 'Show Info',
                    //       style: TextStyle(
                    //         color: _showDebugInfo ? Colors.black : Colors.orange,
                    //         fontSize: 12,
                    //         fontWeight: FontWeight.bold,
                    //       ),
                    //     ),
                    //   ),
                    // ),
                    const SizedBox(height: 8),
                    // Debug Info button
                    // GestureDetector(
                    //   onTap: () {
                    //     Navigator.push(
                    //       context,
                    //       MaterialPageRoute(
                    //         builder: (context) => PKBattleDebugScreen(
                    //           streamId: _debugInfo['stream_id'],
                    //         ),
                    //       ),
                    //     );
                    //   },
                    //   child: Container(
                    //     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    //     decoration: BoxDecoration(
                    //       color: Colors.purple.withOpacity(0.8),
                    //       borderRadius: BorderRadius.circular(20),
                    //       border: Border.all(color: Colors.purple, width: 1),
                    //     ),
                    //     child: const Text(
                    //       'Debug Info',
                    //       style: TextStyle(
                    //         color: Colors.white,
                    //         fontSize: 12,
                    //         fontWeight: FontWeight.bold,
                    //       ),
                    //     ),
                    //   ),
                    // ),
                    // Debug Info Panel
                    if (_showDebugInfo && 1 > 2)
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
                                const Icon(
                                  Icons.info_outline,
                                  color: Colors.orange,
                                  size: 16,
                                ),
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
                                  child: const Icon(
                                    Icons.clear,
                                    color: Colors.grey,
                                    size: 16,
                                  ),
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
                              'Has Active PK Battle':
                                  (widget.activePKBattle != null).toString(),
                            }),

                            const SizedBox(height: 8),

                            // PK Battle Info
                            if (PKEvents.currentPKBattleId != null)
                              _buildInfoSection('PK Battle Info', {
                                'PK Battle ID':
                                    PKEvents.currentPKBattleId.toString(),
                                'Left Host ID':
                                    _debugInfo['left_host_id']?.toString() ??
                                    'N/A',
                                'Right Host ID':
                                    _debugInfo['right_host_id']?.toString() ??
                                    'N/A',
                                'Left Score':
                                    _debugInfo['left_score']?.toString() ?? '0',
                                'Right Score':
                                    _debugInfo['right_score']?.toString() ??
                                    '0',
                                'Left Stream ID':
                                    _debugInfo['left_stream_id']?.toString() ??
                                    'N/A',
                                'Right Stream ID':
                                    _debugInfo['right_stream_id']?.toString() ??
                                    'N/A',
                                'Status':
                                    _debugInfo['pk_battle_status']
                                        ?.toString() ??
                                    'N/A',
                                'Start Time':
                                    _debugInfo['pk_battle_start_time']
                                        ?.toString() ??
                                    'N/A',
                              }),

                            const SizedBox(height: 8),

                            // User Info
                            if (_debugInfo['current_user'] != null)
                              _buildInfoSection('User Info', {
                                'User ID':
                                    _debugInfo['current_user']['id']
                                        ?.toString() ??
                                    'N/A',
                                'Username':
                                    _debugInfo['current_user']['username']
                                        ?.toString() ??
                                    'N/A',
                                'Diamonds':
                                    _debugInfo['current_user']['diamonds']
                                        ?.toString() ??
                                    '0',
                                'Name':
                                    '${_debugInfo['current_user']['first_name'] ?? ''} ${_debugInfo['current_user']['last_name'] ?? ''}'
                                        .trim(),
                              }),

                            const SizedBox(height: 8),

                            // Stream Info
                            _buildInfoSection('Stream Info', {
                              'Stream ID':
                                  _debugInfo['stream_id']?.toString() ?? 'N/A',
                              'Gifts Count':
                                  _debugInfo['gifts_count']?.toString() ?? '0',
                              'Show PK Timer': _showPKBattleTimer.toString(),
                              'Show PK Notification':
                                  _showPKBattleNotification.toString(),
                            }),

                            const SizedBox(height: 8),

                            // Gift Info
                            _buildInfoSection('Gift Info', {
                              'Current User':
                                  '${_currentUser?['id'] ?? 'N/A'} - ${_currentUser?['first_name'] ?? 'Unknown'}',
                              'User Diamonds':
                                  '${_currentUser?['diamonds'] ?? 'N/A'}',
                              'Sending Gift': _sendingGift.toString(),
                              'Live State': liveStateNotifier.value.toString(),
                              'Is Host': widget.isHost.toString(),
                              'Left Host':
                                  '${_leftHostName ?? 'Unknown'} (${_leftHostId ?? 'N/A'})',
                              'Right Host':
                                  '${_rightHostName ?? 'Unknown'} (${_rightHostId ?? 'N/A'})',
                              'Active Gift Animations':
                                  _activeGiftAnimations.length.toString(),
                              'Transaction Polling':
                                  _pkBattleTransactionsTimer != null
                                      ? 'Active'
                                      : 'Inactive',
                              'Processed Transactions':
                                  _processedTransactionIds.length.toString(),
                              'Gifts Loaded': '${_gifts.length}',
                              'Gifts Loading': _giftsLoading.toString(),
                            }),

                            const SizedBox(height: 8),

                            // Test Gift Button
                            if (_gifts.isNotEmpty)
                              GestureDetector(
                                onTap: () {
                                  debugPrint(
                                    '🎁 Testing gift sending with first gift: ${_gifts.first['name']}',
                                  );
                                  _sendGiftFromList(_gifts.first);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.8),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.green,
                                      width: 1,
                                    ),
                                  ),
                                  child: const Text(
                                    'Test Gift Send',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),

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
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
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
      ],
    );
  }

  // Show insufficient diamonds dialog
  void _showInsufficientDiamondsDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              'Insufficient Diamonds',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            content: Text(
              'You don\'t have enough diamonds to send this gift.',
              style: TextStyle(color: Colors.white),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('OK', style: TextStyle(color: Colors.orange)),
              ),
            ],
          ),
    );
  }

  // Show block user popup
  void _showBlockUserPopup(
    BuildContext context,
    String userName,
    String userId,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF23272F),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Block User',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          content: Text(
            'Are you sure you want to block $userName?',
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.grey,
                side: const BorderSide(color: Colors.grey),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () async {
                Navigator.of(context).pop();
                await _blockUser(userId);
              },
              child: const Text('Block', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  // Check if current user is blocked by the host
  Future<bool> _checkIfUserIsBlocked() async {
    try {
      if (widget.isHost)
        return false; // Hosts can't be blocked in their own stream

      final currentUser = await ApiService.getCurrentUser();
      if (currentUser == null) return false;

      // Get the host's blocked users list using the correct API
      final relations = await ApiService.getUserSimpleRelations(
        widget.receiverId,
      );
      final blockedIds = List<int>.from(relations['blocked'] ?? []);

      // Check if current user is in the blocked list
      return blockedIds.contains(currentUser['id']);
    } catch (e) {
      debugPrint('Error checking if user is blocked: $e');
      return false;
    }
  }

  // Block checking timer
  Timer? _blockCheckTimer;
  bool _isUserBlocked = false;

  void _startBlockChecking() {
    if (widget.isHost) return; // Only check for audience members

    _blockCheckTimer?.cancel();
    _blockCheckTimer = Timer.periodic(const Duration(seconds: 5), (
      timer,
    ) async {
      final isBlocked = await _checkIfUserIsBlocked();
      if (isBlocked && !_isUserBlocked) {
        setState(() {
          _isUserBlocked = true;
        });
        if (mounted) {
          // Show blocking message and navigate back
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'You have been blocked by the host and cannot view this live stream',
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
          // Navigate back to previous screen after a short delay
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) {
              Navigator.of(context).pop();
            }
          });
        }
      } else if (!isBlocked && _isUserBlocked) {
        setState(() {
          _isUserBlocked = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You have been unblocked by the host'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    });
  }

  void _stopBlockChecking() {
    _blockCheckTimer?.cancel();
    _blockCheckTimer = null;
  }

  // Block user method
  Future<void> _blockUser(String userId) async {
    try {
      // Handle different user ID formats from live streaming
      int userIdInt;

      // First, try to get the user ID from the app's user list by username
      // This is the most reliable way since we need the actual database user ID
      final allUsers = await ApiService.getAllUsers();

      // Clean the username by removing any prefixes
      String cleanUsername = userId;
      if (userId.startsWith('user_')) {
        cleanUsername = userId.substring(5);
      }

      // Try to find the user by username first
      final user = allUsers.firstWhere(
        (u) =>
            u['username'] == cleanUsername ||
            u['id'].toString() == cleanUsername,
        orElse: () => null,
      );

      if (user != null) {
        userIdInt = user['id'] as int;
      } else {
        // Fallback: try to parse as integer
        try {
          userIdInt = int.parse(cleanUsername);
        } catch (e) {
          throw Exception('User not found in the system');
        }
      }

      await ApiService.blockUser(userIdInt);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User blocked successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      String errorMsg = 'Failed to block user';
      if (e is Exception && e.toString().contains('Exception:')) {
        errorMsg = e.toString().replaceFirst('Exception: ', '');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
      );
    }
  }

  // Function to fetch all users for member list
  Future<void> _fetchAllUsers() async {
    try {
      final users = await ApiService.getUsers();
      setState(() {
        _allUsers = users;
      });
    } catch (e) {
      debugPrint('Error fetching all users: $e');
    }
  }

  // Function to map Zego users to profiles
  void _mapZegoUsersToProfiles(List zegoUsers) {
    for (var zUser in zegoUsers) {
      final userId = zUser.id ?? zUser.userID ?? zUser['userID'] ?? zUser['id'];
      if (userId != null && !_userProfiles.containsKey(userId)) {
        // Try to find user in _allUsers by username or id
        final match = _allUsers.firstWhere(
          (u) =>
              u['username'] == userId ||
              u['id'].toString() == userId.toString(),
          orElse: () => null,
        );
        if (match != null) {
          setState(() {
            _userProfiles[userId] = match;
          });
        }
      }
    }
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
