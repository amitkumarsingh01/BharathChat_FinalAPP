import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/api_service.dart';
import 'package:zego_uikit/zego_uikit.dart';
import 'dart:convert';

class GiftPanel extends StatefulWidget {
  final int receiverId;
  final int? liveStreamId;
  final String? liveStreamType;
  final String roomId;
  final Function()? onGiftSent;
  final Function(String giftName, String gifUrl, String senderName)?
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

  @override
  void initState() {
    super.initState();
    _loadGifts();
    _loadCurrentUser();
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

  Future<void> _sendGift(dynamic gift) async {
    try {
      if (currentUser != null) {
        setState(() {
          currentUser!['diamonds'] -= gift['diamond_amount'];
        });
      }
      print(
        '[GiftPanel] Sending gift API call: receiverId=${widget.receiverId}, giftId=${gift['id']}, liveStreamId=${widget.liveStreamId}, liveStreamType=${widget.liveStreamType}',
      );
      final success = await ApiService.sendGift(
        receiverId: widget.receiverId,
        giftId: gift['id'],
        liveStreamId: widget.liveStreamId ?? 0,
        liveStreamType: widget.liveStreamType ?? '',
      );
      print('[GiftPanel] API call result: $success');

      if (success) {
        // Send ZEGOCLOUD in-room command for gift notification
        final message = jsonEncode({
          "type": "gift",
          "sender_id": currentUser?['id'],
          "sender_name": currentUser?['first_name'] ?? 'User',
          "gift_id": gift['id'],
          "gift_name": gift['name'],
          "gift_amount": gift['diamond_amount'],
          "gif_filename": gift['gif_filename'],
          "timestamp": DateTime.now().millisecondsSinceEpoch,
        });
        print(
          '[GiftPanel] Sending in-room command to roomId=${widget.roomId}: $message',
        );
        await ZegoUIKit().sendInRoomCommand(widget.roomId, [message]);
        print('[GiftPanel] In-room command sent.');

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
        // Trigger gift animation
        final gifUrl =
            'https://server.bharathchat.com/uploads/gifts/' +
            gift['gif_filename'];
        final senderName = currentUser?['first_name'] ?? 'User';
        widget.onGiftAnimation?.call(gift['name'], gifUrl, senderName);
        // Call callback
        widget.onGiftSent?.call();
      } else {
        throw Exception('Gift send failed');
      }
    } catch (e) {
      print('[GiftPanel] Error sending gift: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending gift: $e'),
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
