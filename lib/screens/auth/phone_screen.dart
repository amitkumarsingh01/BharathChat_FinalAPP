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
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: const Alignment(-0.95, -0.95),
                          radius: 2.3,
                          colors: [
                            Color(0xFFFE9B00),
                            Color(0xFFFE9B00).withOpacity(0.85),
                            Colors.transparent,
                          ],
                          stops: [0.0, 0.5, 1.0],
                        ),
                      ),
                    ),
                  ),
                  // Bottom right orange glow (even larger)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: const Alignment(0.85, 0.85),
                          radius: 2.1,
                          colors: [
                            Color(0xFFFE9B00),
                            Color(0xFFFE9B00).withOpacity(0.7),
                            Colors.transparent,
                          ],
                          stops: [0.0, 0.45, 1.0],
                        ),
                      ),
                    ),
                  ),
                  // Main content with slightly less transparent black background
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      // Use a gradient overlay for more control
                      gradient: RadialGradient(
                        center: Alignment.center,
                        radius: 1.2,
                        colors: [
                          Colors.black.withOpacity(0.65), // Center is darker
                          Colors.black.withOpacity(
                            0.35,
                          ), // Edges are more transparent
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
                          Text.rich(
                            TextSpan(
                              text: 'By continuing you agree to our ',
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 13,
                              ),
                              children: [
                                TextSpan(
                                  text: 'T&C',
                                  style: const TextStyle(
                                    // color: Color(0xFFFFC107),
                                    color: Color(0xFFFE9B00),
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                                const TextSpan(text: ' and '),
                                TextSpan(
                                  text: 'Privacy Policy',
                                  style: const TextStyle(
                                    // color: Color(0xFFFFC107),
                                    color: Color(0xFFFE9B00),
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
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
}
