import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/api_service.dart';
// import 'package:zego_uikit/zego_uikit.dart';
import 'dart:convert';
import 'package:just_audio/just_audio.dart';

class GiftPanel extends StatefulWidget {
  final int receiverId;
  final int? liveStreamId;
  final String? liveStreamType;
  final String roomId;
  final Function()? onGiftSent;
  final Function(
    String giftName,
    String gifUrl,
    String senderName, {
    String? pkBattleSide,
  })?
  onGiftAnimation;
  final VoidCallback? onClose;

  const GiftPanel({
    Key? key,
    required this.receiverId,
    this.liveStreamId,
    this.liveStreamType,
    required this.roomId,
    this.onGiftSent,
    this.onGiftAnimation,
    this.onClose,
  }) : super(key: key);

  @override
  State<GiftPanel> createState() => _GiftPanelState();
}

class _GiftPanelState extends State<GiftPanel> {
  List<dynamic> gifts = [];
  bool isLoading = true;
  Map<String, dynamic>? currentUser;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _loadGifts();
    _loadCurrentUser();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadGifts() async {
    try {
      final giftsData = await ApiService.getGifts();
      setState(() {
        gifts = giftsData;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading gifts: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadCurrentUser() async {
    try {
      final userData = await ApiService.getCurrentUser();
      setState(() {
        currentUser = userData;
      });
    } catch (e) {
      print('Error loading current user: $e');
    }
  }

  // Show gift confirmation dialog
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
      '🎁 [${requestId}] Current User: ${currentUser?['id']} - ${currentUser?['first_name']}',
    );
    debugPrint('🎁 [${requestId}] User Diamonds: ${currentUser?['diamonds']}');
    debugPrint(
      '🎁 [${requestId}] Can Afford: ${(currentUser?['diamonds'] ?? 0) >= giftCost}',
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
                // Close gift panel immediately
                widget.onGiftSent?.call();
                // Handle API call in background
                onConfirm();
              },
              child: const Text('Send', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _sendGift(dynamic gift) async {
    try {
      final requestId = DateTime.now().millisecondsSinceEpoch.toString();
      debugPrint('🎁 [$requestId] Starting gift send...');

      // Check if we have enough diamonds
      final currentDiamonds = await ApiService.getCurrentUserDiamonds();
      final giftCost = gift['diamond_amount'] as int? ?? 0;

      if (currentDiamonds < giftCost) {
        debugPrint(
          '❌ [$requestId] Insufficient diamonds: $currentDiamonds < $giftCost',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Insufficient diamonds to send this gift'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      debugPrint(
        '✅ [$requestId] Sufficient diamonds: $currentDiamonds >= $giftCost',
      );

      // Show confirmation dialog
      await _showGiftConfirmationDialog(gift, giftCost, requestId, () async {
        // Send gift via API
        final success = await ApiService.sendGift(
          receiverId: widget.receiverId,
          giftId: gift['id'],
          liveStreamId: widget.liveStreamId ?? 0,
          liveStreamType: widget.liveStreamType ?? 'audio',
        );

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
              // Wait 200ms before playing audio (reduced from 500ms)
              await Future.delayed(const Duration(milliseconds: 200));
              if (mounted) {
                await _audioPlayer.setUrl(audioUrl);
                await _audioPlayer.play();
              }
            } catch (e) {
              debugPrint(
                '🎁 [$requestId] Error playing gift audio (network). Falling back to asset: $e',
              );
              try {
                await _audioPlayer.setAsset('assets/gift_sound.mp3');
                await _audioPlayer.play();
              } catch (assetError) {
                debugPrint(
                  '🎁 [$requestId] Fallback asset playback failed: $assetError',
                );
              }
            }
          }

          // Immediately show animation for the sender (ensure URL correctness)
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
                currentUser?['username'] ?? currentUser?['first_name'] ?? 'You';
            final String giftName = gift['name'] ?? gift['gift_name'] ?? 'Gift';
            if (gifUrl != null) {
              // REMOVED: widget.onGiftAnimation?.call(giftName, gifUrl, senderName);
              // Animation will be handled by polling system to prevent duplicates
              debugPrint(
                '🎁 [$requestId] Gift animation will be shown via polling system',
              );
            }
          } catch (e) {
            debugPrint(
              '🎁 [$requestId] Error creating immediate gift animation: $e',
            );
          }

          // Send ZEGOCLOUD in-room command for synchronization
          final message = jsonEncode({
            "type": "gift",
            "sender_id": currentUser?['id'],
            "sender_name": currentUser?['first_name'] ?? 'User',
            "gift_id": gift['id'],
            "gift_name": gift['name'],
            "gift_amount": giftCost,
            "gif_filename": gift['gif_filename'],
            "audio_filename": gift['audio_filename'],
            "receiver_id": widget.receiverId,
            "timestamp": DateTime.now().millisecondsSinceEpoch,
          });

          debugPrint('🎁 [$requestId] Sending in-room command: $message');
          // Note: ZEGOCLOUD command sending is disabled due to API limitations
          // Gift animations will be synchronized through server-side polling
          debugPrint(
            '🎁 [$requestId] ZEGOCLOUD command sending disabled - using server polling for sync',
          );

          // Success message removed - gift sent silently
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
      });
    } catch (e) {
      debugPrint('❌ Error sending gift: $e');
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
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.9),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey[800]!)),
            ),
            child: Row(
              children: [
                const Text(
                  'Send Gift',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                // Diamond balance
                if (currentUser != null)
                  Row(
                    children: [
                      Image.asset('assets/diamond.png', width: 20, height: 20),
                      const SizedBox(width: 4),
                      Text(
                        '${currentUser!['diamonds']}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: widget.onClose,
                ),
              ],
            ),
          ),

          // Gifts grid
          Expanded(
            child:
                isLoading
                    ? const Center(
                      child: CircularProgressIndicator(color: Colors.orange),
                    )
                    : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 0.8,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                      itemCount: gifts.length,
                      itemBuilder: (context, index) {
                        final gift = gifts[index];
                        final canAfford =
                            currentUser != null &&
                            currentUser!['diamonds'] >= gift['diamond_amount'];

                        return GestureDetector(
                          onTap: canAfford ? () => _sendGift(gift) : null,
                          child: Container(
                            decoration: BoxDecoration(
                              color:
                                  canAfford
                                      ? Colors.grey[900]
                                      : Colors.grey[800],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color:
                                    canAfford
                                        ? Colors.transparent
                                        : Colors.grey[600]!,
                                width: 2,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Gift image
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: CachedNetworkImage(
                                      imageUrl:
                                          'https://server.bharathchat.com/uploads/gifts/' +
                                          gift['gif_filename'],
                                      fit: BoxFit.cover,
                                      placeholder:
                                          (context, url) => Container(
                                            color: Colors.grey[700],
                                            child: const Icon(
                                              Icons.card_giftcard,
                                              color: Colors.white,
                                              size: 30,
                                            ),
                                          ),
                                      errorWidget:
                                          (context, url, error) => Container(
                                            color: Colors.grey[700],
                                            child: const Icon(
                                              Icons.card_giftcard,
                                              color: Colors.white,
                                              size: 30,
                                            ),
                                          ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),

                                // Gift name
                                Text(
                                  gift['name'],
                                  style: TextStyle(
                                    color:
                                        canAfford
                                            ? Colors.white
                                            : Colors.grey[500],
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),

                                const SizedBox(height: 4),

                                // Diamond cost
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
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
