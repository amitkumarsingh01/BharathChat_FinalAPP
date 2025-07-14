// Flutter imports:
import 'package:flutter/material.dart';
import 'dart:convert';

// Package imports:
import 'package:cached_network_image/cached_network_image.dart';
import 'package:zego_uikit_prebuilt_live_streaming/zego_uikit_prebuilt_live_streaming.dart';

Widget customAvatarBuilder(
  BuildContext context,
  Size size,
  ZegoUIKitUser? user,
  Map<String, dynamic> extraInfo, {
  String? profilePic,
}) {
  if (profilePic != null && profilePic.isNotEmpty) {
    try {
      return Container(
        width: size.width,
        height: size.height,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          image: DecorationImage(
            image: MemoryImage(
              base64Decode(profilePic),
            ),
            fit: BoxFit.cover,
          ),
        ),
      );
    } catch (e) {
      // fallback to default
    }
  }
  return CachedNetworkImage(
    imageUrl: 'https://robohash.org/${user?.id}.png',
    imageBuilder: (context, imageProvider) => Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        image: DecorationImage(
          image: imageProvider,
          fit: BoxFit.cover,
        ),
      ),
    ),
    progressIndicatorBuilder: (context, url, downloadProgress) =>
        CircularProgressIndicator(value: downloadProgress.progress),
    errorWidget: (context, url, error) {
      return ZegoAvatar(user: user, avatarSize: size);
    },
  );
} 