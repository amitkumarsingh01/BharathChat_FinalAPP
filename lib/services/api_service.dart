import 'dart:convert';
import 'package:finalchat/models/diamond_history_model.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

// Custom logger function that can be called from anywhere
void apiLog(String message) {
  // Print to console
  print(message);

  // Try to capture in LivePage if available
  try {
    // This will be set by LivePage when it initializes
    if (LivePageLogger.captureLog != null) {
      LivePageLogger.captureLog!(message);
    }
  } catch (e) {
    // Ignore if LivePage is not available
  }
}

// Static class to hold the log capture function
class LivePageLogger {
  static Function(String)? captureLog;
}
// import 'package:video_live/models/diamond_history_model.dart';

class StarHistoryEntry {
  final int id;
  final int userId;
  final DateTime datetime;
  final int amount;
  final String status;

  StarHistoryEntry({
    required this.id,
    required this.userId,
    required this.datetime,
    required this.amount,
    required this.status,
  });

  factory StarHistoryEntry.fromJson(Map<String, dynamic> json) {
    return StarHistoryEntry(
      id: json['id'],
      userId: json['user_id'],
      datetime: DateTime.parse(json['datetime']),
      amount: json['amount'],
      status: json['status'],
    );
  }
}

class ApiService {
  static const String baseUrl = 'https://server.bharathchat.com';
  static String? _token;
  static int? _currentUserId;
  static Map<String, dynamic>? _currentUserData;
  static Map<String, dynamic>? _lastPKBattleGiftLog;

  static int? get currentUserId => _currentUserId;
  static Map<String, dynamic>? get currentUserData => _currentUserData;
  static Map<String, dynamic>? get lastPKBattleGiftLog => _lastPKBattleGiftLog;

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

  static Future<void> unblockUser(int userId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/unblock/$userId'),
      headers: _headers,
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to unblock user');
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
    try {
      print('🔐 [VERIFY_OTP] Starting OTP verification...'); // Debug log
      print('🔐 [VERIFY_OTP] Phone: $phoneNumber, OTP: $otp'); // Debug log
      print('🔐 [VERIFY_OTP] Headers: $_headers'); // Debug log

      final response = await http.post(
        Uri.parse('$baseUrl/auth/verify-otp'),
        headers: _headers,
        body: json.encode({'phone_number': phoneNumber, 'otp': otp}),
      );

      print(
        '🔐 [VERIFY_OTP] Response status: ${response.statusCode}',
      ); // Debug log
      print('🔐 [VERIFY_OTP] Response body: ${response.body}'); // Debug log

      final result = json.decode(response.body);
      print('✅ [VERIFY_OTP] Success: $result'); // Debug log
      return result;
    } catch (e) {
      print('❌ [VERIFY_OTP] Error: $e'); // Debug log
      rethrow;
    }
  }

  // User endpoints
  static Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      print('👤 [GET_CURRENT_USER] Starting...'); // Debug log
      print('👤 [GET_CURRENT_USER] Token: $_token'); // Debug log
      print('👤 [GET_CURRENT_USER] Headers: $_headers'); // Debug log

      final response = await http.get(
        Uri.parse('$baseUrl/users/me'),
        headers: _headers,
      );

      print(
        '👤 [GET_CURRENT_USER] Response status: ${response.statusCode}',
      ); // Debug log
      print(
        '👤 [GET_CURRENT_USER] Response body: ${response.body}',
      ); // Debug log

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _currentUserData = data;
        print('✅ [GET_CURRENT_USER] Success: $data'); // Debug log
        return data;
      } else {
        print(
          '❌ [GET_CURRENT_USER] Failed: ${response.statusCode} - ${response.body}',
        ); // Debug log
        throw Exception(
          'Failed to get current user: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('❌ [GET_CURRENT_USER] Error: $e'); // Debug log
      rethrow;
    }
  }

  static Future<Map<String, dynamic>?> getUserById(int userId) async {
    final requestId = DateTime.now().millisecondsSinceEpoch.toString();
    try {
      apiLog(
        '👤 [USER-$requestId] Fetching user $userId from $baseUrl/users/$userId',
      );
      apiLog('👤 [USER-$requestId] Headers: $_headers');

      final response = await http.get(
        Uri.parse('$baseUrl/users/$userId'),
        headers: _headers,
      );

      apiLog('👤 [USER-$requestId] Response status: ${response.statusCode}');
      apiLog('👤 [USER-$requestId] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final userData = json.decode(response.body);
        apiLog(
          '👤 [USER-$requestId] Successfully fetched user data: $userData',
        );
        apiLog('👤 [USER-$requestId] Username: ${userData['username']}');
        return userData;
      } else {
        apiLog(
          '❌ [USER-$requestId] Failed to get user $userId: ${response.statusCode} - ${response.body}',
        );
        return null;
      }
    } catch (e) {
      apiLog('❌ [USER-$requestId] Error getting user $userId: $e');
      return null;
    }
  }

  static Future<int> getCurrentUserDiamonds() async {
    try {
      final userData = await getCurrentUser();
      return userData['diamonds'] ?? 0;
    } catch (e) {
      apiLog('Error getting user diamonds: $e');
      return 0;
    }
  }

  static Future<Map<String, dynamic>> updateUser(
    Map<String, dynamic> userData,
  ) async {
    try {
      print('🔄 [UPDATE_USER] Starting user update...'); // Debug log
      print('🔄 [UPDATE_USER] User data: $userData'); // Debug log
      print('🔄 [UPDATE_USER] Token: $_token'); // Debug log

      final uri = Uri.parse('$baseUrl/users/me');
      final request = http.MultipartRequest('PUT', uri);
      if (_token != null) {
        request.headers['Authorization'] = 'Bearer $_token';
        print('🔄 [UPDATE_USER] Authorization header set'); // Debug log
      } else {
        print('❌ [UPDATE_USER] No token available'); // Debug log
      }

      // Add fields
      userData.forEach((key, value) {
        if (value != null && key != 'profile_pic') {
          request.fields[key] = value.toString();
          print('🔄 [UPDATE_USER] Added field: $key = $value'); // Debug log
        }
      });

      // Add profile_pic if it's a File
      if (userData['profile_pic'] != null && userData['profile_pic'] is File) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'profile_pic',
            (userData['profile_pic'] as File).path,
          ),
        );
        print('🔄 [UPDATE_USER] Added profile pic file'); // Debug log
      }

      print('🔄 [UPDATE_USER] Sending request to: $uri'); // Debug log
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print(
        '🔄 [UPDATE_USER] Response status: ${response.statusCode}',
      ); // Debug log
      print('🔄 [UPDATE_USER] Response body: ${response.body}'); // Debug log

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        print('✅ [UPDATE_USER] Update successful: $result'); // Debug log
        return result;
      } else {
        print(
          '❌ [UPDATE_USER] Update failed: ${response.statusCode} - ${response.body}',
        ); // Debug log
        throw Exception('Failed to update user: ' + response.body);
      }
    } catch (e) {
      print('❌ [UPDATE_USER] Error during update: $e'); // Debug log
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> createUser({
    required String firstName,
    required String lastName,
    required String username,
    required String phoneNumber,
    File? profileImage,
    String? language,
  }) async {
    final uri = Uri.parse('$baseUrl/users/');
    final request = http.MultipartRequest('POST', uri);
    if (_token != null) {
      request.headers['Authorization'] = 'Bearer $_token';
    }
    request.fields['first_name'] = firstName;
    request.fields['last_name'] = lastName;
    request.fields['username'] = username;
    request.fields['phone_number'] = phoneNumber;
    if (language != null) {
      request.fields['language'] = language;
    }
    if (profileImage != null) {
      request.files.add(
        await http.MultipartFile.fromPath('profile_pic', profileImage.path),
      );
    }
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to create user: ' + response.body);
    }
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
        if (liveData['language'] != null) 'language': liveData['language'],
        if (liveData['types'] != null) 'types': liveData['types'],
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
      apiLog('Error creating audio live: $e');
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
        if (liveData['language'] != null) 'language': liveData['language'],
        if (liveData['types'] != null) 'types': liveData['types'],
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
      apiLog('Error creating video live: $e');
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
      apiLog('Error getting music ID: $e');
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
    final url = '$baseUrl/gifts/';
    apiLog('➡️ [GET_GIFTS] Request URL: $url');
    apiLog('➡️ [GET_GIFTS] Headers: $_headers');
    final response = await http.get(Uri.parse(url), headers: _headers);
    apiLog('⬅️ [GET_GIFTS] Response status: ${response.statusCode}');
    apiLog('⬅️ [GET_GIFTS] Response body: ${response.body}');
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load gifts');
    }
  }

  /// Send a gift from current user to a host
  /// Returns true if successful, throws otherwise
  static Future<bool> sendGift({
    required int receiverId,
    required int giftId,
    int? liveStreamId,
    String? liveStreamType,
  }) async {
    final url = '$baseUrl/gifts/send';
    final body = json.encode({
      'receiver_id': receiverId,
      'gift_id': giftId,
      'live_stream_id': liveStreamId ?? 0,
      'live_stream_type': liveStreamType ?? '',
    });
    apiLog('➡️ [SEND_GIFT] Request URL: $url');
    apiLog('➡️ [SEND_GIFT] Headers: $_headers');
    apiLog('➡️ [SEND_GIFT] Request body: $body');
    final response = await http.post(
      Uri.parse(url),
      headers: _headers,
      body: body,
    );
    apiLog('⬅️ [SEND_GIFT] Response status: ${response.statusCode}');
    apiLog('⬅️ [SEND_GIFT] Response body: ${response.body}');
    if (response.statusCode == 200) {
      return true;
    } else {
      throw Exception('Failed to send gift: ${response.body}');
    }
  }

  /// Get recent gifts for a live stream since a specific time
  /// Returns list of recent gifts for synchronization
  static Future<List<dynamic>> getRecentGifts({
    required int liveStreamId,
    required DateTime since,
  }) async {
    final url =
        '$baseUrl/gifts/recent?live_stream_id=$liveStreamId&since=${since.toIso8601String()}';
    apiLog('➡️ [GET_RECENT_GIFTS] Request URL: $url');
    apiLog('➡️ [GET_RECENT_GIFTS] Headers: $_headers');
    final response = await http.get(Uri.parse(url), headers: _headers);
    apiLog('⬅️ [GET_RECENT_GIFTS] Response status: ${response.statusCode}');
    apiLog('⬅️ [GET_RECENT_GIFTS] Response body: ${response.body}');
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      apiLog(
        'Failed to get recent gifts: ${response.statusCode} - ${response.body}',
      );
      return [];
    }
  }

  /// Get gifts received by a specific user (host) using the new endpoint
  /// Returns the full response map containing user_info, wallet_info, and recent_gifts
  static Future<Map<String, dynamic>?> getUserGiftsReceived({
    required int userIdentifier,
  }) async {
    final url = '$baseUrl/user/gifts/received?user_identifier=$userIdentifier';
    apiLog('➡️ [GET_USER_GIFTS_RECEIVED] Request URL: $url');
    apiLog('➡️ [GET_USER_GIFTS_RECEIVED] Headers: $_headers');
    final response = await http.get(Uri.parse(url), headers: _headers);
    apiLog(
      '⬅️ [GET_USER_GIFTS_RECEIVED] Response status: ${response.statusCode}',
    );
    apiLog('⬅️ [GET_USER_GIFTS_RECEIVED] Response body: ${response.body}');
    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      apiLog(
        'Failed to get user gifts received: ${response.statusCode} - ${response.body}',
      );
      return null;
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

  // static Future<List<dynamic>> getDiamondHistory() async {
  //   final response = await http.get(
  //     Uri.parse('$baseUrl/diamonds/history'),
  //     headers: _headers,
  //   );
  //   return json.decode(response.body);
  // }

  static Future<List<DiamondHistoryEntry>> getDiamondHistory(int userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/diamond-history/$userId'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((e) => DiamondHistoryEntry.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load diamond history');
    }
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
      apiLog('Error fetching user profile: $e');
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
      apiLog('Error fetching background images: $e');
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
      apiLog('Error fetching music: $e');
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

  static Future<bool> isCurrentUserActive() async {
    final user = _currentUserData ?? await getCurrentUser();
    return user['is_active'] == true;
  }

  static Future<Map<String, dynamic>> getUserRelations(int? userId) async {
    if (userId == null) throw Exception('User ID is null');
    final response = await http.get(
      Uri.parse('$baseUrl/users/$userId/relations-full'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to fetch user relations');
    }
  }

  static Future<Map<String, dynamic>> getUserSimpleRelations(
    int? userId,
  ) async {
    if (userId == null) throw Exception('User ID is null');
    final response = await http.get(
      Uri.parse('$baseUrl/users/$userId/relations'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to fetch user relations');
    }
  }

  static Future<List<Map<String, dynamic>>> getUserFollowers(int userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/$userId/followers'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to get user followers: ${response.statusCode}');
    }
  }

  static Future<List<Map<String, dynamic>>> getUserFollowing(int userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/$userId/following'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to get user following: ${response.statusCode}');
    }
  }

  // Fetch user types
  static Future<List<dynamic>> getUserTypes() async {
    final response = await http.get(
      Uri.parse('$baseUrl/user/types'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load user types');
    }
  }

  // Fetch live approval list
  static Future<List<dynamic>> getLiveApproval() async {
    final response = await http.get(
      Uri.parse('$baseUrl/liveapproval'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load live approval list');
    }
  }

  // Fetch bank details for current user
  static Future<Map<String, dynamic>> getBankDetails() async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/me/bank-details'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to fetch bank details');
    }
  }

  // Update bank details for current user
  static Future<Map<String, dynamic>> updateBankDetails(
    Map<String, dynamic> data,
  ) async {
    final response = await http.put(
      Uri.parse('$baseUrl/users/me/bank-details'),
      headers: _headers,
      body: json.encode(data),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to update bank details');
    }
  }

  // Fetch bank details for any user by user_id
  static Future<Map<String, dynamic>> getBankDetailsByUserId(int userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/bank-details/$userId'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to fetch bank details for user');
    }
  }

  // Get withdraw star info (min, conversion rate)
  static Future<Map<String, dynamic>> getWithdrawStarInfo() async {
    final response = await http.get(
      Uri.parse('$baseUrl/withdraw-star-info'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to fetch withdraw star info');
    }
  }

  // Get all star withdrawals for the current user
  static Future<List<Map<String, dynamic>>> getUserStarWithdrawals(
    int userId,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/withdraw-star'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final List<dynamic> all = json.decode(response.body);
      return all
          .where((w) => w['user_id'] == userId)
          .cast<Map<String, dynamic>>()
          .toList();
    } else {
      throw Exception('Failed to fetch star withdrawals');
    }
  }

  // Create a new withdraw star request
  static Future<Map<String, dynamic>> createWithdrawStar({
    required int userId,
    required int starCount,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/withdraw-star'),
      headers: _headers,
      body: json.encode({'user_id': userId, 'star_count': starCount}),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to create withdraw star request');
    }
  }

  // Star endpoints
  static Future<List<StarHistoryEntry>> getStarHistory(int userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/star-history/$userId'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((e) => StarHistoryEntry.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load star history');
    }
  }

  static Future<int> getTotalStars(int userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/stars/$userId'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['total_stars'] ?? 0;
    } else {
      throw Exception('Failed to load total stars');
    }
  }

  static Future<String?> uploadProfilePic(File imageFile) async {
    if (_currentUserId == null) throw Exception('User not logged in');
    final uri = Uri.parse('$baseUrl/users/$_currentUserId/profile-pic');
    final request = http.MultipartRequest('PUT', uri);
    if (_token != null) {
      request.headers['Authorization'] = 'Bearer $_token';
    }
    request.files.add(
      await http.MultipartFile.fromPath('profile_pic', imageFile.path),
    );
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['profile_pic'];
    } else {
      throw Exception('Failed to upload profile picture');
    }
  }

  static Future<Map<String, dynamic>> removeUserProfilePic(int userId) async {
    final response = await http.put(
      Uri.parse('$baseUrl/users/$userId/remove-profile-pic'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to remove profile picture');
    }
  }

  /// Fetch all active live streams (video and audio)
  static Future<List<dynamic>> getAllLiveStreams() async {
    final response = await http.get(
      Uri.parse('$baseUrl/live-streams/'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to fetch all live streams');
    }
  }

  static Future<int?> getUserIdByUsername(String username) async {
    final response = await http.get(
      Uri.parse('$baseUrl/user-id-by-username?username=$username'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['id'] as int?;
    } else {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getUserDetailsByUsername(
    String username,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/user-id-by-username?username=$username'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return {'id': data['id'], 'username': data['username']};
    } else {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> startPKBattle({
    required int leftHostId,
    required int rightHostId,
    int leftStreamId = 0,
    int rightStreamId = 0,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/pk-battle/start'),
      headers: _headers,
      body: json.encode({
        'left_host_id': leftHostId,
        'right_host_id': rightHostId,
        'left_stream_id': leftStreamId,
        'right_stream_id': rightStreamId,
      }),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to start PK battle: ${response.statusCode}');
    }
  }

  static Future<Map<String, dynamic>?> endPKBattle({
    required int pkBattleId,
    required int leftScore,
    required int rightScore,
    required int winnerId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/pk-battle/end'),
      headers: _headers,
      body: json.encode({
        'pk_battle_id': pkBattleId,
        'left_score': leftScore,
        'right_score': rightScore,
        'winner_id': winnerId,
      }),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to end PK battle: \\${response.statusCode}');
    }
  }

  static Future<Map<String, dynamic>?> getPKBattleById(int pkBattleId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/pk-battle/$pkBattleId'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getLatestActivePKBattleForHosts(
    String? leftHostId,
    String? rightHostId,
  ) async {
    if (leftHostId == null || rightHostId == null) return null;
    final response = await http.get(
      Uri.parse(
        '$baseUrl/pk-battle/active?left_host_id=$leftHostId&right_host_id=$rightHostId',
      ),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data is List && data.isNotEmpty) {
        return data.first; // Return the latest active PK battle
      }
    }
    return null;
  }

  static Future<Map<String, dynamic>?> getLatestActivePKBattleForUser(
    int userId,
  ) async {
    final startTime = DateTime.now();
    final requestId = DateTime.now().millisecondsSinceEpoch.toString();

    try {
      apiLog(
        '🚀 [API-$requestId] Starting PK battle fetch for user $userId at ${startTime.toString()}',
      );
      apiLog(
        '🚀 [API-$requestId] Request URL: $baseUrl/pk-battle/user/$userId',
      );
      apiLog('🚀 [API-$requestId] Headers: $_headers');

      // Add 2 second delay before calling the API (reduced from 10 seconds)
      apiLog('⏳ [API-$requestId] Waiting 2 seconds before API call...');
      await Future.delayed(Duration(seconds: 2));

      final apiCallStartTime = DateTime.now();
      apiLog(
        '🔍 [API-$requestId] Making HTTP GET request at ${apiCallStartTime.toString()}',
      );

      final response = await http.get(
        Uri.parse('$baseUrl/pk-battle/user/$userId'),
        headers: _headers,
      );

      final apiCallEndTime = DateTime.now();
      final apiCallDuration = apiCallEndTime.difference(apiCallStartTime);
      final totalDuration = apiCallEndTime.difference(startTime);

      apiLog(
        '📡 [API-$requestId] API call completed at ${apiCallEndTime.toString()}',
      );
      apiLog(
        '📡 [API-$requestId] API call duration: ${apiCallDuration.inMilliseconds}ms',
      );
      apiLog(
        '📡 [API-$requestId] Total time including delay: ${totalDuration.inMilliseconds}ms',
      );
      apiLog('📡 [API-$requestId] HTTP Status: ${response.statusCode}');
      apiLog('📡 [API-$requestId] Response Headers: ${response.headers}');
      apiLog(
        '📡 [API-$requestId] Response Body Length: ${response.body.length} characters',
      );
      apiLog('📡 [API-$requestId] Full Response Body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final decoded = json.decode(response.body);
          if (decoded is List) {
            apiLog(
              '📡 [API-$requestId] JSON parsed as List with ${decoded.length} items',
            );
            if (decoded.isNotEmpty) {
              final latestBattle = decoded.first;
              apiLog('📡 [API-$requestId] Latest battle data: $latestBattle');
              apiLog(
                '📡 [API-$requestId] Latest battle keys: ${latestBattle.keys.toList()}',
              );
              final result = {
                'id': latestBattle['pk_battle_id'],
                'start_time': latestBattle['start_time'],
                'left_host_id': latestBattle['left_host_id'],
                'right_host_id': latestBattle['right_host_id'],
                'status': latestBattle['status'],
              };
              apiLog(
                '✅ [API-$requestId] SUCCESS! Found PK battle for user $userId',
              );
              apiLog('✅ [API-$requestId] PK Battle ID: ${result['id']}');
              apiLog('✅ [API-$requestId] Final result object: $result');
              return result;
            } else {
              apiLog(
                '⚠️ [API-$requestId] No battles found in response (empty list)',
              );
              return null;
            }
          } else if (decoded is Map) {
            apiLog('📡 [API-$requestId] JSON parsed as Map');
            apiLog('📡 [API-$requestId] Map keys: ${decoded.keys.toList()}');
            if (decoded['pk_battle_id'] != null) {
              final result = {
                'id': decoded['pk_battle_id'],
                'start_time': decoded['start_time'],
                'left_host_id': decoded['left_host_id'],
                'right_host_id': decoded['right_host_id'],
                'status': decoded['status'],
              };
              apiLog(
                '✅ [API-$requestId] SUCCESS! Found PK battle for user $userId (Map response)',
              );
              apiLog('✅ [API-$requestId] PK Battle ID: ${result['id']}');
              apiLog('✅ [API-$requestId] Final result object: $result');
              return result;
            } else {
              apiLog(
                '⚠️ [API-$requestId] Map response but no pk_battle_id field',
              );
              return null;
            }
          } else {
            apiLog(
              '❌ [API-$requestId] Unexpected response type: ${decoded.runtimeType}',
            );
            return null;
          }
        } catch (jsonError) {
          apiLog('❌ [API-$requestId] JSON parsing failed: $jsonError');
          apiLog(
            '❌ [API-$requestId] Raw response body that failed to parse: ${response.body}',
          );
          return null;
        }
      } else {
        apiLog('❌ [API-$requestId] HTTP request failed');
        apiLog('❌ [API-$requestId] Status code: ${response.statusCode}');
        apiLog('❌ [API-$requestId] Error response body: ${response.body}');
        return null;
      }
    } catch (e) {
      final totalDuration = DateTime.now().difference(startTime);
      apiLog(
        '💥 [API-$requestId] EXCEPTION occurred after ${totalDuration.inMilliseconds}ms',
      );
      apiLog('💥 [API-$requestId] Exception type: ${e.runtimeType}');
      apiLog('💥 [API-$requestId] Exception message: $e');
      apiLog('💥 [API-$requestId] Stack trace: ${StackTrace.current}');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getActivePKBattleByStreamId(
    int streamId,
  ) async {
    final startTime = DateTime.now();
    final requestId = DateTime.now().millisecondsSinceEpoch.toString();

    try {
      apiLog(
        '🚀 [API-$requestId] Starting PK battle fetch for stream $streamId at ${startTime.toString()}',
      );
      apiLog(
        '🚀 [API-$requestId] Request URL: $baseUrl/api/pk-battle/stream/$streamId',
      );
      apiLog('🚀 [API-$requestId] Headers: $_headers');

      // Try up to 3 times with 1-second intervals to handle backend timing
      for (int attempt = 1; attempt <= 3; attempt++) {
        final attemptStartTime = DateTime.now();
        apiLog(
          '🔍 [API-$requestId] Attempt $attempt started at ${attemptStartTime.toString()}',
        );
        apiLog(
          '🔍 [API-$requestId] Making HTTP GET request to: $baseUrl/api/pk-battle/stream/$streamId',
        );

        final response = await http.get(
          Uri.parse('$baseUrl/api/pk-battle/stream/$streamId'),
          headers: _headers,
        );

        final attemptEndTime = DateTime.now();
        final attemptDuration = attemptEndTime.difference(attemptStartTime);

        apiLog(
          '📡 [API-$requestId] Attempt $attempt completed at ${attemptEndTime.toString()}',
        );
        apiLog(
          '📡 [API-$requestId] Attempt $attempt duration: ${attemptDuration.inMilliseconds}ms',
        );
        apiLog(
          '📡 [API-$requestId] Attempt $attempt - HTTP Status: ${response.statusCode}',
        );
        apiLog(
          '📡 [API-$requestId] Attempt $attempt - Response Headers: ${response.headers}',
        );
        apiLog(
          '📡 [API-$requestId] Attempt $attempt - Response Body Length: ${response.body.length} characters',
        );
        apiLog(
          '📡 [API-$requestId] Attempt $attempt - Full Response Body: ${response.body}',
        );

        if (response.statusCode == 200) {
          try {
            final Map<String, dynamic> battle = json.decode(response.body);
            apiLog(
              '📡 [API-$requestId] Attempt $attempt - JSON parsed successfully',
            );
            apiLog(
              '📡 [API-$requestId] Attempt $attempt - Parsed Response Keys: ${battle.keys.toList()}',
            );
            apiLog(
              '📡 [API-$requestId] Attempt $attempt - Full Parsed Response: $battle',
            );

            // Return the battle data if pk_battle_id exists
            if (battle['pk_battle_id'] != null) {
              final totalDuration = DateTime.now().difference(startTime);
              apiLog('✅ [API-$requestId] SUCCESS on attempt $attempt!');
              apiLog(
                '✅ [API-$requestId] PK Battle ID found: ${battle['pk_battle_id']}',
              );
              apiLog(
                '✅ [API-$requestId] Total request duration: ${totalDuration.inMilliseconds}ms',
              );
              apiLog('✅ [API-$requestId] Returning PK battle data...');

              // Fetch host names
              String? leftHostName;
              String? rightHostName;

              try {
                if (battle['left_host_id'] != null) {
                  final leftHost = await getUserById(battle['left_host_id']);
                  leftHostName = leftHost?['username'] ?? 'Left host';
                  apiLog(
                    '👤 [API-$requestId] Left host name fetched: $leftHostName (ID: ${battle['left_host_id']})',
                  );
                }

                if (battle['right_host_id'] != null) {
                  final rightHost = await getUserById(battle['right_host_id']);
                  rightHostName = rightHost?['username'] ?? 'Right host';
                  apiLog(
                    '👤 [API-$requestId] Right host name fetched: $rightHostName (ID: ${battle['right_host_id']})',
                  );
                }
              } catch (e) {
                apiLog('⚠️ [API-$requestId] Error fetching host names: $e');
                leftHostName = 'Left host';
                rightHostName = 'Right host';
              }

              final result = {
                'pk_battle_id': battle['pk_battle_id'],
                'start_time': battle['start_time'],
                'left_host_id': battle['left_host_id'],
                'right_host_id': battle['right_host_id'],
                'left_host_name': leftHostName,
                'right_host_name': rightHostName,
                'left_stream_id': battle['left_stream_id'],
                'right_stream_id': battle['right_stream_id'],
                'left_score': battle['left_score'],
                'right_score': battle['right_score'],
                'status': battle['status'],
              };

              apiLog('✅ [API-$requestId] Final result object: $result');
              return result;
            } else {
              apiLog(
                '⚠️ [API-$requestId] PK battle ID is null on attempt $attempt',
              );
              apiLog(
                '⚠️ [API-$requestId] Available fields: ${battle.keys.toList()}',
              );
              apiLog('⚠️ [API-$requestId] Battle object: $battle');

              if (attempt < 3) {
                apiLog(
                  '⏳ [API-$requestId] Waiting 1 second before attempt ${attempt + 1}...',
                );
                await Future.delayed(Duration(seconds: 1));
              }
            }
          } catch (jsonError) {
            apiLog(
              '❌ [API-$requestId] JSON parsing failed on attempt $attempt: $jsonError',
            );
            apiLog(
              '❌ [API-$requestId] Raw response body that failed to parse: ${response.body}',
            );

            if (attempt < 3) {
              apiLog(
                '⏳ [API-$requestId] Waiting 1 second before attempt ${attempt + 1}...',
              );
              await Future.delayed(Duration(seconds: 1));
            }
          }
        } else {
          apiLog('❌ [API-$requestId] HTTP request failed on attempt $attempt');
          apiLog('❌ [API-$requestId] Status code: ${response.statusCode}');
          apiLog('❌ [API-$requestId] Error response body: ${response.body}');
          apiLog('❌ [API-$requestId] Response headers: ${response.headers}');

          if (attempt < 3) {
            apiLog(
              '⏳ [API-$requestId] Waiting 1 second before attempt ${attempt + 1}...',
            );
            await Future.delayed(Duration(seconds: 1));
          }
        }
      }

      final totalDuration = DateTime.now().difference(startTime);
      apiLog('❌ [API-$requestId] FAILED after 3 attempts');
      apiLog(
        '❌ [API-$requestId] Total time spent: ${totalDuration.inMilliseconds}ms',
      );
      apiLog('❌ [API-$requestId] No PK battle found for stream $streamId');
      return null;
    } catch (e) {
      final totalDuration = DateTime.now().difference(startTime);
      apiLog(
        '💥 [API-$requestId] EXCEPTION occurred after ${totalDuration.inMilliseconds}ms',
      );
      apiLog('💥 [API-$requestId] Exception type: ${e.runtimeType}');
      apiLog('💥 [API-$requestId] Exception message: $e');
      apiLog('💥 [API-$requestId] Stack trace: ${StackTrace.current}');
      return null;
    }
  }

  // Test method to manually fetch user information
  static Future<void> testGetUserById(int userId) async {
    final requestId = DateTime.now().millisecondsSinceEpoch.toString();
    apiLog('🧪 [TEST-$requestId] Testing user fetch for ID: $userId');

    try {
      final userData = await getUserById(userId);
      if (userData != null) {
        apiLog(
          '🧪 [TEST-$requestId] ✅ Successfully fetched user: ${userData['username']}',
        );
      } else {
        apiLog('🧪 [TEST-$requestId] ❌ Failed to fetch user $userId');
      }
    } catch (e) {
      apiLog('🧪 [TEST-$requestId] ❌ Exception: $e');
    }
  }

  static Future<bool> sendPKBattleGift({
    required int pkBattleId,
    required int senderId,
    required int receiverId,
    required int giftId,
    required int amount,
  }) async {
    final startTime = DateTime.now();
    final requestId = DateTime.now().millisecondsSinceEpoch.toString();

    try {
      apiLog(
        '🚀 [GIFT-$requestId] Starting PK battle gift send at ${startTime.toString()}',
      );
      apiLog('🚀 [GIFT-$requestId] Request URL: $baseUrl/pk-battle/gift');
      apiLog('🚀 [GIFT-$requestId] Headers: $_headers');

      final requestBody = {
        'pk_battle_id': pkBattleId,
        'sender_id': senderId,
        'receiver_id': receiverId,
        'gift_id': giftId,
        'amount': amount,
      };

      apiLog('🚀 [GIFT-$requestId] Request Body: $requestBody');
      apiLog(
        '🚀 [GIFT-$requestId] JSON encoded body: ${json.encode(requestBody)}',
      );

      final apiCallStartTime = DateTime.now();
      apiLog(
        '🔍 [GIFT-$requestId] Making HTTP POST request at ${apiCallStartTime.toString()}',
      );

      final response = await http.post(
        Uri.parse('$baseUrl/pk-battle/gift'),
        headers: _headers,
        body: json.encode(requestBody),
      );

      final apiCallEndTime = DateTime.now();
      final apiCallDuration = apiCallEndTime.difference(apiCallStartTime);
      final totalDuration = apiCallEndTime.difference(startTime);

      apiLog(
        '📡 [GIFT-$requestId] API call completed at ${apiCallEndTime.toString()}',
      );
      apiLog(
        '📡 [GIFT-$requestId] API call duration: ${apiCallDuration.inMilliseconds}ms',
      );
      apiLog(
        '📡 [GIFT-$requestId] Total request duration: ${totalDuration.inMilliseconds}ms',
      );
      apiLog('📡 [GIFT-$requestId] HTTP Status: ${response.statusCode}');
      apiLog('📡 [GIFT-$requestId] Response Headers: ${response.headers}');
      apiLog(
        '📡 [GIFT-$requestId] Response Body Length: ${response.body.length} characters',
      );
      apiLog('📡 [GIFT-$requestId] Full Response Body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final data = json.decode(response.body);
          apiLog('📡 [GIFT-$requestId] JSON parsed successfully');
          apiLog('📡 [GIFT-$requestId] Response data: $data');
          apiLog(
            '📡 [GIFT-$requestId] Response data keys: ${data.keys.toList()}',
          );

          final isSuccess = data['status'] == 'score updated';
          apiLog(
            '📡 [GIFT-$requestId] Status check: ${data['status']} == "score updated" = $isSuccess',
          );

          if (isSuccess) {
            apiLog('✅ [GIFT-$requestId] SUCCESS! Gift sent successfully');
            apiLog('✅ [GIFT-$requestId] PK Battle ID: $pkBattleId');
            apiLog('✅ [GIFT-$requestId] Sender ID: $senderId');
            apiLog('✅ [GIFT-$requestId] Receiver ID: $receiverId');
            apiLog('✅ [GIFT-$requestId] Gift ID: $giftId');
            apiLog('✅ [GIFT-$requestId] Amount: $amount');

            // Store the success log for debug display
            _lastPKBattleGiftLog = {
              'timestamp': DateTime.now().toString(),
              'request_id': requestId,
              'request': requestBody,
              'response_status': response.statusCode,
              'response_data': data,
              'success': true,
              'api_call_duration': '${apiCallDuration.inMilliseconds}ms',
              'total_duration': '${totalDuration.inMilliseconds}ms',
            };
          } else {
            apiLog(
              '⚠️ [GIFT-$requestId] Gift send failed - status not "score updated"',
            );
            apiLog('⚠️ [GIFT-$requestId] Actual status: ${data['status']}');

            // Store the failure log for debug display
            _lastPKBattleGiftLog = {
              'timestamp': DateTime.now().toString(),
              'request_id': requestId,
              'request': requestBody,
              'response_status': response.statusCode,
              'response_data': data,
              'success': false,
              'api_call_duration': '${apiCallDuration.inMilliseconds}ms',
              'total_duration': '${totalDuration.inMilliseconds}ms',
            };
          }

          return isSuccess;
        } catch (jsonError) {
          apiLog('❌ [GIFT-$requestId] JSON parsing failed: $jsonError');
          apiLog(
            '❌ [GIFT-$requestId] Raw response body that failed to parse: ${response.body}',
          );
          return false;
        }
      } else {
        apiLog('❌ [GIFT-$requestId] HTTP request failed');
        apiLog('❌ [GIFT-$requestId] Status code: ${response.statusCode}');
        apiLog('❌ [GIFT-$requestId] Error response body: ${response.body}');

        // Store the HTTP error log for debug display
        _lastPKBattleGiftLog = {
          'timestamp': DateTime.now().toString(),
          'request_id': requestId,
          'request': requestBody,
          'response_status': response.statusCode,
          'response_data': response.body,
          'success': false,
          'api_call_duration': '${apiCallDuration.inMilliseconds}ms',
          'total_duration': '${totalDuration.inMilliseconds}ms',
        };

        return false;
      }
    } catch (e) {
      final totalDuration = DateTime.now().difference(startTime);
      apiLog(
        '💥 [GIFT-$requestId] EXCEPTION occurred after ${totalDuration.inMilliseconds}ms',
      );
      apiLog('💥 [GIFT-$requestId] Exception type: ${e.runtimeType}');
      apiLog('💥 [GIFT-$requestId] Exception message: $e');
      apiLog('💥 [GIFT-$requestId] Stack trace: ${StackTrace.current}');

      // Store the exception log for debug display
      _lastPKBattleGiftLog = {
        'timestamp': DateTime.now().toString(),
        'request_id': requestId,
        'request': {
          'pk_battle_id': pkBattleId,
          'sender_id': senderId,
          'receiver_id': receiverId,
          'gift_id': giftId,
          'amount': amount,
        },
        'response_status': null,
        'response_data': e.toString(),
        'success': false,
        'api_call_duration': 'N/A',
        'total_duration': '${totalDuration.inMilliseconds}ms',
        'exception_type': e.runtimeType.toString(),
      };

      return false;
    }
  }

  // Get PK Battle Transactions
  static Future<Map<String, dynamic>> getPKBattleTransactions(
    int pkBattleId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/pk-battle/$pkBattleId/transactions'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        throw Exception(
          'Failed to load PK battle transactions: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching PK battle transactions: $e');
    }
  }

  // Get Live Video Streams
  static Future<List<Map<String, dynamic>>> getLiveVideoStreams() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/go-live-video/'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception(
          'Failed to load live video streams: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching live video streams: $e');
    }
  }
}
