import 'package:finalchat/screens/profile/BankDetailsScreen.dart';
import 'package:finalchat/screens/profile/BlockedUser.dart';
import 'package:finalchat/screens/profile/FollowedUser.dart';
import 'package:finalchat/screens/profile/HelpSupport.dart';
import 'package:finalchat/screens/profile/WithdrawDiamond.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../services/api_service.dart';
import '../auth/phone_screen.dart';
import 'edit_profile_screen.dart';
import 'diamond_history_screen.dart';
import 'star_history_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _user;
  bool _isLoading = true;
  File? _pickedImage;

  ImageProvider? _getProfileImage() {
    if (_pickedImage != null) {
      return FileImage(_pickedImage!);
    }
    if (_user?['profile_pic'] != null &&
        _user!['profile_pic'].toString().isNotEmpty) {
      final profilePic = _user!['profile_pic'].toString();
      // If it's already a full URL, use as is; otherwise, prepend server URL
      final isFullUrl =
          profilePic.startsWith('http://') || profilePic.startsWith('https://');
      final url =
          isFullUrl
              ? profilePic
              : 'https://server.bharathchat.com/' + profilePic;
      return NetworkImage(url);
    }
    return null;
  }

  String _getUserInitial() {
    if (_user?['first_name'] != null &&
        _user!['first_name'].toString().isNotEmpty) {
      return _user!['first_name'].toString().substring(0, 1).toUpperCase();
    }
    return 'U';
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 85);
    if (pickedFile != null) {
      setState(() {
        _pickedImage = File(pickedFile.path);
      });
      // Here you can also upload the image to your backend if needed
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => SafeArea(
            child: Wrap(
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Select from Camera'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Select from Gallery'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_forever, color: Colors.red),
                  title: const Text(
                    'Remove Profile Image',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    setState(() {
                      _pickedImage = null;
                      // Also clear the profile_pic from user data
                      if (_user != null) {
                        _user!['profile_pic'] = null;
                      }
                    });
                    if (_user != null && _user!['id'] != null) {
                      try {
                        await ApiService.removeUserProfilePic(_user!['id']);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Profile picture removed successfully',
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Failed to remove profile picture'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    }
                  },
                ),
              ],
            ),
          ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() async {
    try {
      final user = await ApiService.getCurrentUser();
      setState(() {
        _user = user;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const PhoneScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF181A20),
        body: const Center(
          child: CircularProgressIndicator(color: Colors.orange),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF181A20),
      body: CustomScrollView(
        slivers: [
          // App Bar with background image
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: const Color(0xFF181A20),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.white),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EditProfileScreen(),
                    ),
                  ).then((_) => _loadUserData());
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Background image (using profile pic as background)
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.blue.withOpacity(0.8),
                          Colors.purple.withOpacity(0.6),
                        ],
                      ),
                    ),
                    child:
                        _getProfileImage() != null
                            ? Image(
                              image: _getProfileImage()!,
                              fit: BoxFit.cover,
                            )
                            : Container(color: Colors.grey[800]),
                  ),
                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Profile content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),

                  // User name with star icon
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        _user?['first_name'] ?? 'User',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _user?['phone_number'] ?? '',
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 16),

                  // Followers and Following stats
                  FutureBuilder<Map<String, dynamic>>(
                    future: ApiService.getUserRelations(
                      _user?['id'] ?? _user?['user_id'],
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Colors.orange,
                          ),
                        );
                      }
                      if (snapshot.hasError) {
                        return const SizedBox();
                      }
                      final relations = snapshot.data;
                      final followers = relations?['followers_count'] ?? 0;
                      final following = relations?['following_count'] ?? 0;
                      return Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const FollowedUser(),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey[800],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      '$following',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Following',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) =>
                                            const FollowedUser(), // Replace with Followers screen if exists
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey[800],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      '$followers',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Followers',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  // Profile Options
                  _buildProfileOption(
                    'Personal Information',
                    Icons.person,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EditProfileScreen(),
                      ),
                    ).then((_) => _loadUserData()),
                  ),
                  _buildProfileOption(
                    'Bank Details',
                    Icons.account_balance,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const BankDetailsScreen(),
                      ),
                    ).then((_) => _loadUserData()),
                  ),
                  _buildProfileOption('Diamond History', Icons.history, () {
                    if (_user?['id'] != null || _user?['user_id'] != null) {
                      final userId = _user?['id'] ?? _user?['user_id'];
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => DiamondHistoryScreen(userId: userId),
                        ),
                      );
                    }
                  }),
                  _buildProfileOption('Star History', Icons.star, () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => StarHistoryScreen(
                              userId: _user?['id'] ?? _user?['user_id'],
                            ),
                      ),
                    );
                  }),
                  _buildProfileOption('Withdraw Diamonds', Icons.money, () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const WithdrawDiamond(),
                      ),
                    );
                  }),
                  _buildProfileOption('Blocked Users', Icons.block, () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const BlockedUser(),
                      ),
                    );
                    // Navigate to blocked users
                  }),
                  _buildProfileOption('Followed Users', Icons.person_add, () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FollowedUser(),
                      ),
                    );
                  }),
                  _buildProfileOption('Help & Support', Icons.help, () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HelpSupport(),
                      ),
                    );
                    // Navigate to help
                  }),
                  const SizedBox(height: 20),

                  // Logout Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _logout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[800],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Logout',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileOption(String title, IconData icon, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        // color: Colors.grey[900],
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.transparent),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.white),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          color: Colors.white,
          size: 16,
        ),
        onTap: onTap,
      ),
    );
  }
}
