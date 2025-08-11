import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/api_service.dart';
import 'otp_screen.dart';

class PhoneScreen extends StatefulWidget {
  const PhoneScreen({Key? key}) : super(key: key);

  @override
  State<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends State<PhoneScreen> {
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false;

  void _showTermsAndConditions() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _buildTermsDialog();
      },
    );
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _buildPrivacyDialog();
      },
    );
  }

  void _sendOtp() async {
    if (_phoneController.text.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid 10-digit phone number'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ApiService.sendOtp(_phoneController.text);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OtpScreen(phoneNumber: _phoneController.text),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
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
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // GIF at the top
          Column(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
                child: Image.network(
                  'https://assets-v2.lottiefiles.com/a/f6bdc21c-1166-11ee-9666-373bb5c99115/k8b0B8d26M.gif',
                  height: MediaQuery.of(context).size.height * 0.75,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ],
          ),
          // Overlay card with logo, input, button
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
              child: Stack(
                children: [
                  // Top left strong orange overlay (optional, for a solid effect)
                  Positioned(
                    left: 0,
                    top: 0,
                    child: Container(
                      width: 80, // adjust as needed
                      height: 80, // adjust as needed
                      decoration: BoxDecoration(
                        color: Color(0xFFFE9B00),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(30),
                        ),
                      ),
                    ),
                  ),
                  // Top left orange glow (even larger and less transparent)
                  // Positioned.fill(
                  //   child: Container(
                  //     decoration: BoxDecoration(
                  //       gradient: RadialGradient(
                  //         center: const Alignment(-0.95, -0.95),
                  //         radius: 2.3,
                  //         colors: [
                  //           Color(0xFFFE9B00),
                  //           Color(0xFFFE9B00).withOpacity(0.85),
                  //           Colors.transparent,
                  //         ],
                  //         stops: [0.0, 0.5, 1.0],
                  //       ),
                  //     ),
                  //   ),
                  // ),
                  // // Bottom right orange glow (even larger)
                  // Positioned.fill(
                  //   child: Container(
                  //     decoration: BoxDecoration(
                  //       gradient: RadialGradient(
                  //         center: const Alignment(0.85, 0.85),
                  //         radius: 2.1,
                  //         colors: [
                  //           Color(0xFFFE9B00),
                  //           Color(0xFFFE9B00).withOpacity(0.7),
                  //           Colors.transparent,
                  //         ],
                  //         stops: [0.0, 0.45, 1.0],
                  //       ),
                  //     ),
                  //   ),
                  // ),
                  // Main content with slightly less transparent black background
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      // Use a gradient overlay for more control
                      gradient: RadialGradient(
                        center: Alignment.center,
                        radius: 1.2,
                        colors: [
                          // Colors.black.withOpacity(0.65), // Center is darker
                          // Colors.black.withOpacity(
                          //   0.35,
                          // ), // Edges are more transparent
                          Colors.black,
                          Colors.black,
                        ],
                        stops: [0.6, 1.0],
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black54,
                          blurRadius: 16,
                          offset: Offset(0, -4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 32,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Logo
                          Image.asset('assets/logo.png', height: 48),
                          const SizedBox(height: 16),
                          const Text(
                            'Enter your mobile number',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'We will send you an OTP to verify your number',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 15,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 28),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[900],
                              borderRadius: BorderRadius.circular(12),
                              // border: Border.all(color: Colors.orange),
                              border: Border.all(color: Color(0xFFFE9B00)),
                            ),
                            child: Row(
                              children: [
                                // Country code dropdown
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12.0,
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: '+91',
                                      items: const [
                                        DropdownMenuItem(
                                          value: '+91',
                                          child: Text(
                                            '+91',
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        // Add more country codes here if needed
                                      ],
                                      onChanged: (value) {},
                                      dropdownColor: Colors.grey[900],
                                      icon: const Icon(
                                        Icons.arrow_drop_down,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 30,
                                  // color: Colors.orange,
                                  color: Color(0xFFFE9B00),
                                ),
                                Expanded(
                                  child: TextField(
                                    controller: _phoneController,
                                    keyboardType: TextInputType.phone,
                                    style: const TextStyle(color: Colors.white),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(10),
                                    ],
                                    decoration: const InputDecoration(
                                      hintText: 'Enter phone number',
                                      hintStyle: TextStyle(
                                        color: Colors.white54,
                                      ),
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.all(16),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),
                          Container(
                            width: double.infinity,
                            height: 50,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFFffa030),
                                  Color(0xFFfe9b00),
                                  Color(0xFFf67d00),
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _sendOtp,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child:
                                  _isLoading
                                      ? const CircularProgressIndicator(
                                        color: Colors.white,
                                      )
                                      : const Text(
                                        'Get OTP',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          GestureDetector(
                            onTap: () {
                              // This will be handled by the individual text spans
                            },
                            child: Text.rich(
                              TextSpan(
                                text: 'By continuing you agree to our ',
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 13,
                                ),
                                children: [
                                  WidgetSpan(
                                    child: GestureDetector(
                                      onTap: _showTermsAndConditions,
                                      child: const Text(
                                        'T&C',
                                        style: TextStyle(
                                          color: Color(0xFFFE9B00),
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const TextSpan(text: ' and '),
                                  WidgetSpan(
                                    child: GestureDetector(
                                      onTap: _showPrivacyPolicy,
                                      child: const Text(
                                        'Privacy Policy',
                                        style: TextStyle(
                                          color: Color(0xFFFE9B00),
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
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

  Widget _buildTermsDialog() {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF23272F), Color(0xFF181A20)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFFE9B00), width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFffa030),
                    Color(0xFFfe9b00),
                    Color(0xFFf67d00),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.description, color: Colors.black, size: 24),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Terms & Conditions',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.black,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTermsSection(
                      '1. Acceptance of Terms',
                      'By accessing and using Bharath Chat, you accept and agree to be bound by the terms and provision of this agreement.',
                    ),
                    _buildTermsSection(
                      '2. User Registration',
                      'You must provide accurate and complete information when creating your account. You are responsible for maintaining the security of your account.',
                    ),
                    _buildTermsSection(
                      '3. Acceptable Use',
                      'You agree not to use the service for any unlawful purpose or to violate any applicable laws or regulations.',
                    ),
                    _buildTermsSection(
                      '4. Content Guidelines',
                      'Users are responsible for the content they share. Prohibited content includes harassment, hate speech, and illegal activities.',
                    ),
                    _buildTermsSection(
                      '5. Live Streaming Rules',
                      'When using live streaming features, you must comply with community guidelines and respect other users.',
                    ),
                    _buildTermsSection(
                      '6. Intellectual Property',
                      'All content and materials available on Bharath Chat are protected by intellectual property rights.',
                    ),
                    _buildTermsSection(
                      '7. Termination',
                      'We reserve the right to terminate or suspend your account for violations of these terms.',
                    ),
                    _buildTermsSection(
                      '8. Modifications',
                      'We may modify these terms at any time. Continued use of the service constitutes acceptance of modified terms.',
                    ),
                    _buildTermsSection(
                      '9. Contact Information',
                      'For questions about these terms, please contact us through the app support section.',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyDialog() {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        // width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxHeight: 600),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF23272F), Color(0xFF181A20)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFFE9B00), width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFffa030),
                    Color(0xFFfe9b00),
                    Color(0xFFf67d00),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.privacy_tip, color: Colors.black, size: 24),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Privacy Policy',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.black,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPrivacySection(
                      '1. Information We Collect',
                      'We collect information you provide directly to us, such as your name, phone number, and profile information.',
                    ),
                    _buildPrivacySection(
                      '2. How We Use Your Information',
                      'We use your information to provide, maintain, and improve our services, communicate with you, and ensure security.',
                    ),
                    _buildPrivacySection(
                      '3. Information Sharing',
                      'We do not sell, trade, or otherwise transfer your personal information to third parties without your consent.',
                    ),
                    _buildPrivacySection(
                      '4. Data Security',
                      'We implement appropriate security measures to protect your personal information from unauthorized access.',
                    ),
                    _buildPrivacySection(
                      '5. Live Streaming Privacy',
                      'When using live streaming features, your content may be visible to other users. Please be mindful of what you share.',
                    ),
                    _buildPrivacySection(
                      '6. Camera and Microphone Access',
                      'We request camera and microphone permissions for live streaming features. You can control these permissions in your device settings.',
                    ),
                    _buildPrivacySection(
                      '7. Data Retention',
                      'We retain your information for as long as necessary to provide our services and comply with legal obligations.',
                    ),
                    _buildPrivacySection(
                      '8. Your Rights',
                      'You have the right to access, update, or delete your personal information through the app settings.',
                    ),
                    _buildPrivacySection(
                      '9. Children\'s Privacy',
                      'Our service is not intended for children under 13. We do not knowingly collect personal information from children under 13.',
                    ),
                    _buildPrivacySection(
                      '10. Changes to Policy',
                      'We may update this privacy policy from time to time. We will notify you of any material changes.',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTermsSection(String title, String content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFFFE9B00),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacySection(String title, String content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFFFE9B00),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
