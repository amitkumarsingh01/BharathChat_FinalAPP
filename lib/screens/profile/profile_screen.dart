import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../services/api_service.dart';
import '../auth/phone_screen.dart';
import 'edit_profile_screen.dart';

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
      try {
        return MemoryImage(base64Decode(_user!['profile_pic']));
      } catch (e) {
        print('Error decoding profile image: $e');
        return null;
      }
    }
    return null;
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
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _pickedImage = null;
                    });
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
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Profile',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.orange),
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
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Colors.orange),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Profile Picture with edit icon overlay
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.orange,
                          backgroundImage: _getProfileImage(),
                          child:
                              _getProfileImage() == null
                                  ? Text(
                                    (_user?['first_name'] ?? 'U')
                                        .substring(0, 1)
                                        .toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 40,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                  : null,
                        ),
                        Positioned(
                          bottom: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: _showImageSourceDialog,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black87,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              padding: const EdgeInsets.all(6),
                              child: const Icon(
                                Icons.edit,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // User Info
                    Text(
                      _user?['first_name'] ?? 'User',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _user?['phone_number'] ?? '',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Diamond Balance
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.transparent),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/diamond.png',
                            width: 30,
                            height: 30,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${_user?['diamonds'] ?? 0} Diamonds',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

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
                    _buildProfileOption('Diamond History', Icons.history, () {
                      // Navigate to diamond history
                    }),
                    _buildProfileOption('Blocked Users', Icons.block, () {
                      // Navigate to blocked users
                    }),
                    _buildProfileOption('Settings', Icons.settings, () {
                      // Navigate to settings
                    }),
                    _buildProfileOption('Help & Support', Icons.help, () {
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
                          backgroundColor: Colors.red,
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
    );
  }

  Widget _buildProfileOption(String title, IconData icon, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.transparent),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.orange),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          color: Colors.orange,
          size: 16,
        ),
        onTap: onTap,
      ),
    );
  }
}
