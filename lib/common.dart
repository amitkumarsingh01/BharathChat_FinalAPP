// Flutter imports:
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';

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
    name: 'Hindi',
    nativeName: 'हिंदी',
    code: 'hi',
    backgroundColor: Color(0xFF8B4513), // Brown
  ),
  Language(
    name: 'Kannada',
    nativeName: 'ಕನ್ನಡ',
    code: 'kn',
    backgroundColor: Color(0xFF4B0082), // Purple
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
  // If we have a profile picture URL, use it
  if (profilePic != null && profilePic.isNotEmpty) {
    // Handle both full URLs and relative paths
    String imageUrl;
    if (profilePic.startsWith('http')) {
      imageUrl = profilePic;
    } else {
      imageUrl = 'https://server.bharathchat.com/$profilePic';
    }

    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: size.width,
        height: size.height,
        fit: BoxFit.cover,
        placeholder:
            (context, url) => Container(
              width: size.width,
              height: size.height,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[300],
              ),
              child: Icon(
                Icons.person,
                size: size.width * 0.5,
                color: Colors.grey[600],
              ),
            ),
        errorWidget:
            (context, url, error) => Container(
              width: size.width,
              height: size.height,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[300],
              ),
              child: Icon(
                Icons.person,
                size: size.width * 0.5,
                color: Colors.grey[600],
              ),
            ),
      ),
    );
  }

  // Return a simple avatar without any username or user information
  return Container(
    width: size.width,
    height: size.height,
    decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.grey[300]),
    child: Icon(Icons.person, size: size.width * 0.5, color: Colors.grey[600]),
  );
}
