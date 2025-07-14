import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _bioController = TextEditingController();

  String? _selectedGender;
  DateTime? _selectedDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() async {
    try {
      final user = await ApiService.getCurrentUser();
      setState(() {
        _firstNameController.text = user['first_name'] ?? '';
        _lastNameController.text = user['last_name'] ?? '';
        _usernameController.text = user['username'] ?? '';
        _emailController.text = user['email'] ?? '';
        _bioController.text = user['bio'] ?? '';
        _selectedGender = user['gender'];
        if (user['dob'] != null) {
          _selectedDate = DateTime.parse(user['dob']);
        }
      });
    } catch (e) {
      // Handle error
    }
  }

  void _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await ApiService.updateUser({
        'first_name': _firstNameController.text,
        'last_name': _lastNameController.text,
        'username': _usernameController.text,
        'email': _emailController.text,
        'bio': _bioController.text,
        'gender': _selectedGender,
        'dob': _selectedDate?.toIso8601String(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update profile'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Edit Profile',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Profile Picture
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFFffa030),
                      Color(0xFFfe9b00),
                      Color(0xFFf67d00),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Center(
                  child: Icon(Icons.camera_alt, size: 40, color: Colors.white),
                ),
              ),
              const SizedBox(height: 30),

              // First Name
              TextFormField(
                controller: _firstNameController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('First Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your first name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Last Name
              TextFormField(
                controller: _lastNameController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('Last Name'),
              ),
              const SizedBox(height: 16),

              // Username
              TextFormField(
                controller: _usernameController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('Username'),
              ),
              const SizedBox(height: 16),

              // Email
              TextFormField(
                controller: _emailController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),

              // Gender
              DropdownButtonFormField<String>(
                value: _selectedGender,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('Gender'),
                dropdownColor: Colors.grey[900],
                items:
                    ['Male', 'Female', 'Other'].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(
                          value,
                          style: const TextStyle(color: Colors.white),
                        ),
                      );
                    }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedGender = newValue;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Date of Birth
              GestureDetector(
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate ?? DateTime.now(),
                    firstDate: DateTime(1950),
                    lastDate: DateTime.now(),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.dark(
                            primary: Colors.orange,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null && picked != _selectedDate) {
                    setState(() {
                      _selectedDate = picked;
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Color(0xFFCACACA)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedDate != null
                            ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                            : 'Select Date of Birth',
                        style: TextStyle(
                          color:
                              _selectedDate != null
                                  ? Colors.white
                                  : Colors.white54,
                        ),
                      ),
                      const Icon(Icons.calendar_today, color: Colors.grey),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Bio
              TextFormField(
                controller: _bioController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('Bio'),
                maxLines: 3,
              ),
              const SizedBox(height: 30),

              // Update Button
              Container(
                width: double.infinity,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFFffa030),
                      Color(0xFFfe9b00),
                      Color(0xFFf67d00),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child:
                      _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                            'Update Profile',
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
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFFCACACA)),
      border: OutlineInputBorder(
        borderSide: const BorderSide(color: Color(0xFFCACACA)),
        borderRadius: BorderRadius.circular(8),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Color(0xFFCACACA)),
        borderRadius: BorderRadius.circular(8),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.orange, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    super.dispose();
  }
}
