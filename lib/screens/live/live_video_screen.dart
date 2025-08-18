import 'package:flutter/material.dart';
import 'package:zego_uikit_prebuilt_live_streaming/zego_uikit_prebuilt_live_streaming.dart';
import 'package:permission_handler/permission_handler.dart';
import 'gift_panel.dart';
import 'gift_animation.dart';
import '../../services/api_service.dart';
import '../../services/live_stream_service.dart';
import 'package:finalchat/pk_widgets/config.dart';
import 'package:finalchat/pk_widgets/events.dart';
import 'package:finalchat/pk_widgets/surface.dart';
import 'package:finalchat/pk_widgets/widgets/mute_button.dart';
import 'package:finalchat/common.dart';
import 'package:finalchat/constants.dart';
import 'live_page.dart';

class LiveVideoScreen extends StatefulWidget {
  final String liveID;
  final String localUserID;
  final bool isHost;
  final int hostId;
  final Map<String, dynamic>? activePKBattle; // Add this parameter

  const LiveVideoScreen({
    Key? key,
    required this.liveID,
    required this.localUserID,
    required this.hostId,
    this.isHost = false,
    this.activePKBattle, // Add this parameter
  }) : super(key: key);

  @override
  State<LiveVideoScreen> createState() => _LiveVideoScreenState();
}

class _LiveVideoScreenState extends State<LiveVideoScreen> {
  bool showGiftPanel = false;
  List<Map<String, dynamic>> giftAnimations = [];
  Map<String, dynamic>? user;
  bool isPKBattleActive = true; // TODO: Replace with real PK state

  @override
  void initState() {
    super.initState();
    _fetchUser();
  }

  Future<void> _fetchUser() async {
    final userData = await ApiService.getCurrentUser();
    setState(() {
      user = userData;
    });
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
        FutureBuilder<Map<String, dynamic>>(
          future: ApiService.getCurrentUser(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final user = snapshot.data!;
            return LivePage(
              liveID: widget.liveID,
              localUserID: widget.localUserID,
              isHost: widget.isHost,
              
              onGiftButtonPressed: _showGiftPanel, // NEW
              receiverId: widget.hostId, // <-- pass hostId
              activePKBattle: widget.activePKBattle, // Pass the new parameter
            );
          },
        ),
        // Gift Button (audience only, PK battle active)
        // (Removed: FloatingActionButton for gifts)
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
                      roomId: widget.liveID,
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
