// Flutter imports:
import 'package:flutter/material.dart';
import 'dart:convert';

// Package imports:
import 'package:cached_network_image/cached_network_image.dart';
import 'package:zego_uikit_prebuilt_live_streaming/zego_uikit_prebuilt_live_streaming.dart';

class Language {
  final String name;
  final String nativeName;
  final String code;
  final Color backgroundColor;

  const Language({
    required this.name,
    required this.nativeName,
    required this.code,
    required this.backgroundColor,
  });
}

const List<Language> languages = [
  Language(
    name: 'Kannada',
    nativeName: 'ಕನ್ನಡ',
    code: 'kn',
    backgroundColor: Color(0xFF4B0082), // Purple
  ),
  Language(
    name: 'Hindi',
    nativeName: 'हिंदी',
    code: 'hi',
    backgroundColor: Color(0xFF8B4513), // Brown
  ),
  Language(
    name: 'Telugu',
    nativeName: 'తెలుగు',
    code: 'te',
    backgroundColor: Color(0xFF008080), // Teal
  ),
  Language(
    name: 'Tamil',
    nativeName: 'தமிழ்',
    code: 'ta',
    backgroundColor: Color(0xFF556B2F), // Olive
  ),
  Language(
    name: 'Bengali',
    nativeName: 'বাংলা',
    code: 'bn',
    backgroundColor: Color(0xFF800000), // Maroon
  ),
  Language(
    name: 'Marathi',
    nativeName: 'मराठी',
    code: 'mr',
    backgroundColor: Color(0xFF8B4513), // Brown
  ),
  Language(
    name: 'Punjabi',
    nativeName: 'ਪੰਜਾਬੀ',
    code: 'pa',
    backgroundColor: Color(0xFF000080), // Navy
  ),
  // Language(
  //   name: 'Kannada',
  //   nativeName: 'ಕನ್ನಡ',
  //   code: 'kn',
  //   backgroundColor: Color(0xFF4B0082), // Purple
  // ),
  Language(
    name: 'Malayalam',
    nativeName: 'മലയാളം',
    code: 'ml',
    backgroundColor: Color(0xFF006400), // Dark Green
  ),
];

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
            image: MemoryImage(base64Decode(profilePic)),
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
    imageBuilder:
        (context, imageProvider) => Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
          ),
        ),
    progressIndicatorBuilder:
        (context, url, downloadProgress) =>
            CircularProgressIndicator(value: downloadProgress.progress),
    errorWidget: (context, url, error) {
      return ZegoAvatar(user: user, avatarSize: size);
    },
  );
}
