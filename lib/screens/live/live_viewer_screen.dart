import 'package:flutter/material.dart';
import 'package:zego_uikit_prebuilt_live_streaming/zego_uikit_prebuilt_live_streaming.dart';
import 'gift_panel.dart';
import 'gift_animation.dart';
import '../../services/api_service.dart';
import 'package:finalchat/pk_widgets/config.dart';
import 'package:finalchat/pk_widgets/events.dart';
import 'package:finalchat/pk_widgets/surface.dart';
import 'package:finalchat/pk_widgets/widgets/mute_button.dart';
import 'package:finalchat/common.dart';
import 'package:finalchat/constants.dart';
import 'live_page.dart';

class LiveViewerScreen extends StatefulWidget {
  final String channelName;
  final int liveId;
  final int hostId;
  final String liveType; // 'audio' or 'video'

  const LiveViewerScreen({
    Key? key,
    required this.channelName,
    required this.liveId,
    required this.hostId,
    required this.liveType,
  }) : super(key: key);

  @override
  State<LiveViewerScreen> createState() => _LiveViewerScreenState();
}

class _LiveViewerScreenState extends State<LiveViewerScreen> {
  final int appID = 615877954; // Your ZEGOCLOUD AppID
  final String appSign =
      "12e07321bd8231dda371ea9235e274178403bd97a7ccabcb09e22474c42da3a4"; // Your ZEGOCLOUD AppSign

  bool showGiftPanel = false;
  List<Map<String, dynamic>> giftAnimations = [];
  Map<String, dynamic>? currentUser;
  bool isPKBattleActive = true; // TODO: Replace with real PK state

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
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

  void _showGiftPanel() {
    setState(() {
      showGiftPanel = true;
    });
  }

  void _hideGiftPanel() {
    setState(() {
      showGiftPanel = false;
    });
  }

  void _onGiftSent() {
    _hideGiftPanel();
    // You can add additional logic here, like showing a notification
  }

  void _showGiftAnimation(
    String giftName,
    String gifUrl,
    String senderName, {
    String? pkBattleSide,
  }) {
    setState(() {
      giftAnimations.add({
        'giftName': giftName,
        'gifUrl': gifUrl,
        'senderName': senderName,
        'pkBattleSide': pkBattleSide,
        'id': DateTime.now().millisecondsSinceEpoch,
      });
    });
  }

  void _removeGiftAnimation(int id) {
    setState(() {
      giftAnimations.removeWhere((animation) => animation['id'] == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        LivePage(
          liveID: widget.channelName,
          localUserID:
              currentUser?['id']?.toString() ??
              'viewer_${DateTime.now().millisecondsSinceEpoch}',
          isHost: false,
          
          receiverId: widget.hostId, // <-- pass hostId
        ),
        // Gift Button (PK battle active)
        if (isPKBattleActive)
          Positioned(
            bottom: 300,
            left: 30,
            child: FloatingActionButton(
              backgroundColor: Colors.orange,
              child: const Icon(Icons.card_giftcard, color: Colors.white),
              onPressed: _showGiftPanel,
            ),
          ),
        // Gift Panel
        if (showGiftPanel)
          Positioned.fill(
            child: GestureDetector(
              onTap: _hideGiftPanel,
              child: Container(
                color: Colors.black54,
                child: Center(
                  child: FractionallySizedBox(
                    heightFactor: 0.5,
                    child: GiftPanel(
                      receiverId: widget.hostId,
                      roomId: widget.channelName,
                      onGiftSent: _hideGiftPanel,
                      onGiftAnimation: _showGiftAnimation,
                      onClose: _hideGiftPanel,
                    ),
                  ),
                ),
              ),
            ),
          ),
        // Gift Animations
        ...giftAnimations.map(
          (anim) => GiftAnimation(
            giftName: anim['giftName'],
            gifUrl: anim['gifUrl'],
            senderName: anim['senderName'],
            pkBattleSide: anim['pkBattleSide'],
            onAnimationComplete: () => _removeGiftAnimation(anim['id']),
          ),
        ),
      ],
    );
  }
}
