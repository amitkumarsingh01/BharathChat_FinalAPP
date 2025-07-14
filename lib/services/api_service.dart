import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'https://server.bharathchat.com';
  static String? _token;
  static int? _currentUserId;
  static Map<String, dynamic>? _currentUserData;

  static int? get currentUserId => _currentUserId;
  static Map<String, dynamic>? get currentUserData => _currentUserData;

  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    _currentUserId = prefs.getInt('user_id');
    if (_token != null) {
      try {
        _currentUserData = await getCurrentUser();
      } catch (_) {}
    }
  }

  static Future<void> setToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  static Future<void> setUserId(int userId) async {
    _currentUserId = userId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('user_id', userId);
  }

  static Future<void> clearToken() async {
    _token = null;
    _currentUserId = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user_id');
  }

  static Map<String, String> get _headers {
    return {
      'Content-Type': 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token',
    };
  }

  static Future<List<dynamic>> getConversations() async {
    final response = await http.get(
      Uri.parse('$baseUrl/conversations/'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load conversations');
    }
  }

  static Future<List<dynamic>> getAllUsers() async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load users');
    }
  }

  static Future<List<dynamic>> getMessages(int userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/messages/?user_id=$userId'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load messages');
    }
  }

  static Future<void> sendMessage(int receiverId, String message) async {
    final response = await http.post(
      Uri.parse('$baseUrl/messages/'),
      headers: _headers,
      body: json.encode({'receiver_id': receiverId, 'message': message}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to send message');
    }
  }

  static Future<void> followUser(int userId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/follow/$userId'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to follow user');
    }
  }

  static Future<void> unfollowUser(int userId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/unfollow/$userId'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to unfollow user');
    }
  }

  static Future<void> blockUser(int userId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/block/$userId'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to block user');
    }
  }

  static Future<void> markMessageRead(int messageId) async {
    final response = await http.put(
      Uri.parse('$baseUrl/messages/$messageId/read'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to mark message as read');
    }
  }

  // Auth endpoints
  static Future<Map<String, dynamic>> sendOtp(String phoneNumber) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/send-otp?phone_number=$phoneNumber'),
      headers: _headers,
    );
    return json.decode(response.body);
  }

  static Future<Map<String, dynamic>> verifyOtp(
    String phoneNumber,
    String otp,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/verify-otp'),
      headers: _headers,
      body: json.encode({'phone_number': phoneNumber, 'otp': otp}),
    );
    return json.decode(response.body);
  }

  // User endpoints
  static Future<Map<String, dynamic>> getCurrentUser() async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/me'),
      headers: _headers,
    );
    final data = json.decode(response.body);
    _currentUserData = data;
    return data;
  }

  static Future<int> getCurrentUserDiamonds() async {
    try {
      final userData = await getCurrentUser();
      return userData['diamonds'] ?? 0;
    } catch (e) {
      print('Error getting user diamonds: $e');
      return 0;
    }
  }

  static Future<Map<String, dynamic>> updateUser(
    Map<String, dynamic> userData,
  ) async {
    final response = await http.put(
      Uri.parse('$baseUrl/users/me'),
      headers: _headers,
      body: json.encode(userData),
    );
    return json.decode(response.body);
  }

  // Slider endpoints
  static Future<List<dynamic>> getSliders() async {
    final response = await http.get(
      Uri.parse('$baseUrl/sliders/'),
      headers: _headers,
    );
    return json.decode(response.body);
  }

  // Live streaming endpoints
  static Future<List<dynamic>> getAudioLives() async {
    final response = await http.get(
      Uri.parse('$baseUrl/go-live-audio/'),
      headers: _headers,
    );
    return json.decode(response.body);
  }

  static Future<List<dynamic>> getVideoLives() async {
    final response = await http.get(
      Uri.parse('$baseUrl/go-live-video/'),
      headers: _headers,
    );
    return json.decode(response.body);
  }

  static Future<Map<String, dynamic>> createAudioLive(
    Map<String, dynamic> liveData,
  ) async {
    try {
      // Format the request according to backend expectations
      final requestData = {
        'title': liveData['title'],
        'chat_room': liveData['chat_room'],
        'hashtag':
            liveData['hashtag'] is List
                ? liveData['hashtag']
                : [liveData['hashtag']],
        'music_id': liveData['music_id'],
        'background_img': liveData['background_img'],
        'live_url': liveData['live_url'],
      };

      final response = await http.post(
        Uri.parse('$baseUrl/go-live-audio/'),
        headers: _headers,
        body: json.encode(requestData),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to create audio live: ${response.body}');
      }
    } catch (e) {
      print('Error creating audio live: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> createVideoLive(
    Map<String, dynamic> liveData,
  ) async {
    try {
      // Format the request according to backend expectations
      final requestData = {
        'category': liveData['category'],
        'hashtag':
            liveData['hashtag'] is List
                ? liveData['hashtag']
                : [liveData['hashtag']],
        'live_url': liveData['live_url'],
      };

      final response = await http.post(
        Uri.parse('$baseUrl/go-live-video/'),
        headers: _headers,
        body: json.encode(requestData),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to create video live: ${response.body}');
      }
    } catch (e) {
      print('Error creating video live: $e');
      rethrow;
    }
  }

  // Helper method to get music ID from filename
  static Future<int?> getMusicIdByFilename(String? filename) async {
    if (filename == null) return null;

    try {
      final music = await getMusic();
      final matchingMusic = music.firstWhere(
        (m) => m['filename'] == filename,
        orElse: () => null,
      );
      return matchingMusic?['id'];
    } catch (e) {
      print('Error getting music ID: $e');
      return null;
    }
  }

  // Shop endpoints
  static Future<List<dynamic>> getShopItems() async {
    final response = await http.get(
      Uri.parse('$baseUrl/shop/'),
      headers: _headers,
    );
    return json.decode(response.body);
  }

  // Gifts endpoints
  static Future<List<dynamic>> getGifts() async {
    final response = await http.get(
      Uri.parse('$baseUrl/gifts/'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load gifts');
    }
  }

  /// Send a gift from current user to a host (for PK battle)
  /// Returns true if successful, throws otherwise
  static Future<bool> sendGift({
    required int receiverId,
    required int giftId,
    int? liveStreamId,
    String? liveStreamType,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/gifts/send'),
      headers: _headers,
      body: json.encode({
        'receiver_id': receiverId,
        'gift_id': giftId,
        'live_stream_id': liveStreamId ?? 0,
        'live_stream_type': liveStreamType ?? '',
      }),
    );
    if (response.statusCode == 200) {
      return true;
    } else {
      throw Exception('Failed to send gift: \\${response.body}');
    }
  }

  // Diamond endpoints
  static Future<Map<String, dynamic>> addDiamonds(int amount) async {
    final response = await http.post(
      Uri.parse('$baseUrl/diamonds/add?amount=$amount'),
      headers: _headers,
    );
    return json.decode(response.body);
  }

  static Future<List<dynamic>> getDiamondHistory() async {
    final response = await http.get(
      Uri.parse('$baseUrl/diamonds/history'),
      headers: _headers,
    );
    return json.decode(response.body);
  }

  static Future<http.Response> updateUserProfile({
    required String firstName,
    required String lastName,
    required String username,
    String? profilePic,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/users/me'),
      headers: _headers,
      body: jsonEncode({
        'first_name': firstName,
        'last_name': lastName,
        'username': username,
        if (profilePic != null) 'profile_pic': profilePic,
      }),
    );
    return response;
  }

  static Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/user/profile'));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception('Failed to load user profile');
    } catch (e) {
      print('Error fetching user profile: $e');
      return {};
    }
  }

  static Future<List<dynamic>> getBackgroundImages() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/background-images/'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception('Failed to load background images');
    } catch (e) {
      print('Error fetching background images: $e');
      return [];
    }
  }

  static Future<List<dynamic>> getMusic() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/music/'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception('Failed to load music');
    } catch (e) {
      print('Error fetching music: $e');
      return [];
    }
  }

  static Future<List<dynamic>> getUsers() async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load users');
    }
  }
}
