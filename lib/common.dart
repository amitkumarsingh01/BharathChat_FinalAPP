// Flutter imports:
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';

// Package imports:
import 'package:cached_network_image/cached_network_image.dart';
import 'package:zego_uikit_prebuilt_live_streaming/zego_uikit_prebuilt_live_streaming.dart';
import 'services/api_service.dart';

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

// Global cache for user profile pictures to avoid repeated API calls
final Map<String, String> _profilePicCache = {};
final Map<String, Future<String?>> _profilePicFutures = {};

Widget customAvatarBuilder(
  BuildContext context,
  Size size,
  ZegoUIKitUser? user,
  Map<String, dynamic> extraInfo,
) {
  // Check if profile picture URL is passed in extraInfo
  String? profilePicUrl = extraInfo['profile_pic_url'] as String?;

  if (profilePicUrl != null && profilePicUrl.isNotEmpty) {
    // Use the provided profile picture URL - exactly like the rest of the app
    String imageUrl;
    if (profilePicUrl.startsWith('http')) {
      imageUrl = profilePicUrl;
    } else {
      imageUrl = 'https://server.bharathchat.com/$profilePicUrl';
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

  // Check if user data is passed in extraInfo
  Map<String, dynamic>? userData =
      extraInfo['user_data'] as Map<String, dynamic>?;
  if (userData != null &&
      userData['profile_pic'] != null &&
      userData['profile_pic'].isNotEmpty) {
    // Use the user data profile picture - exactly like the rest of the app
    String imageUrl;
    if (userData['profile_pic'].startsWith('http')) {
      imageUrl = userData['profile_pic'];
    } else {
      imageUrl = 'https://server.bharathchat.com/${userData['profile_pic']}';
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

  // If no profile picture URL provided, fetch from backend based on user ID
  if (user != null && user.id.isNotEmpty) {
    return _AvatarWidget(userId: user.id, size: size);
  }

  // Return a simple avatar without any username or user information
  return Container(
    width: size.width,
    height: size.height,
    decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.grey[300]),
    child: Icon(Icons.person, size: size.width * 0.5, color: Colors.grey[600]),
  );
}

// StatefulWidget to handle profile picture fetching with stable state
class _AvatarWidget extends StatefulWidget {
  final String userId;
  final Size size;

  const _AvatarWidget({required this.userId, required this.size});

  @override
  State<_AvatarWidget> createState() => _AvatarWidgetState();
}

class _AvatarWidgetState extends State<_AvatarWidget> {
  String? _profilePicUrl;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadProfilePic();
  }

  @override
  void didUpdateWidget(_AvatarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      _loadProfilePic();
    }
  }

  Future<void> _loadProfilePic() async {
    // Check cache first
    if (_profilePicCache.containsKey(widget.userId)) {
      setState(() {
        _profilePicUrl = _profilePicCache[widget.userId];
        _isLoading = false;
        _hasError = false;
      });
      return;
    }

    // Check if we already have a future for this user
    if (_profilePicFutures.containsKey(widget.userId)) {
      try {
        final result = await _profilePicFutures[widget.userId]!;
        if (mounted) {
          setState(() {
            _profilePicUrl = result;
            _isLoading = false;
            _hasError = result == null;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _hasError = true;
          });
        }
      }
      return;
    }

    // Create new future and store it
    final future = _fetchUserProfilePic(widget.userId);
    _profilePicFutures[widget.userId] = future;

    try {
      final result = await future;
      if (mounted) {
        setState(() {
          _profilePicUrl = result;
          _isLoading = false;
          _hasError = result == null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    } finally {
      // Clean up the future
      _profilePicFutures.remove(widget.userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        width: widget.size.width,
        height: widget.size.height,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey[300],
        ),
        child: Icon(
          Icons.person,
          size: widget.size.width * 0.5,
          color: Colors.grey[600],
        ),
      );
    }

    if (_hasError || _profilePicUrl == null || _profilePicUrl!.isEmpty) {
      return Container(
        width: widget.size.width,
        height: widget.size.height,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey[300],
        ),
        child: Icon(
          Icons.person,
          size: widget.size.width * 0.5,
          color: Colors.grey[600],
        ),
      );
    }

    String imageUrl;
    if (_profilePicUrl!.startsWith('http')) {
      imageUrl = _profilePicUrl!;
    } else {
      imageUrl = 'https://server.bharathchat.com/$_profilePicUrl';
    }

    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: widget.size.width,
        height: widget.size.height,
        fit: BoxFit.cover,
        placeholder:
            (context, url) => Container(
              width: widget.size.width,
              height: widget.size.height,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[300],
              ),
              child: Icon(
                Icons.person,
                size: widget.size.width * 0.5,
                color: Colors.grey[600],
              ),
            ),
        errorWidget:
            (context, url, error) => Container(
              width: widget.size.width,
              height: widget.size.height,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[300],
              ),
              child: Icon(
                Icons.person,
                size: widget.size.width * 0.5,
                color: Colors.grey[600],
              ),
            ),
      ),
    );
  }
}

// Function to fetch user profile picture from backend
Future<String?> _fetchUserProfilePic(String userId) async {
  try {
    // Check cache first
    if (_profilePicCache.containsKey(userId)) {
      return _profilePicCache[userId];
    }

    // Try to parse userId as integer
    int? userIdInt = int.tryParse(userId);
    if (userIdInt == null) {
      // If userId is not a number, try to find user by username
      final allUsers = await ApiService.getAllUsers();
      final user = allUsers.firstWhere(
        (u) => u['username'] == userId || u['id'].toString() == userId,
        orElse: () => null,
      );

      if (user != null &&
          user['profile_pic'] != null &&
          user['profile_pic'].isNotEmpty) {
        _profilePicCache[userId] = user['profile_pic'];
        return user['profile_pic'];
      }
      return null;
    }

    // Fetch user data from backend using user ID
    final userData = await ApiService.getUserById(userIdInt);
    if (userData != null &&
        userData['profile_pic'] != null &&
        userData['profile_pic'].isNotEmpty) {
      _profilePicCache[userId] = userData['profile_pic'];
      return userData['profile_pic'];
    }

    return null;
  } catch (e) {
    print('Error fetching profile picture for user $userId: $e');
    return null;
  }
}
