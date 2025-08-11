import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../main/main_screen.dart';
import 'registration_screen.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

class OtpScreen extends StatefulWidget {
  final String phoneNumber;

  const OtpScreen({Key? key, required this.phoneNumber}) : super(key: key);

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final TextEditingController _otpController = TextEditingController();
  bool _isLoading = false;

  void _verifyOTP() async {
    if (_otpController.text.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid 6-digit OTP'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ApiService.verifyOtp(
        widget.phoneNumber,
        _otpController.text,
      );

      await ApiService.setToken(response['access_token']);
      await ApiService.setUserId(response['user_id']);

      // Now check if user profile is complete by calling getCurrentUser
      try {
        final userData = await ApiService.getCurrentUser();
        print('User data after OTP verification: $userData'); // Debug log
        
        // Check if user has complete profile (first_name, last_name, username)
        if (userData['first_name'] != null &&
            userData['last_name'] != null &&
            userData['username'] != null &&
            userData['first_name'].toString().isNotEmpty &&
            userData['last_name'].toString().isNotEmpty &&
            userData['username'].toString().isNotEmpty) {
          print('Profile is complete, navigating to MainScreen'); // Debug log
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainScreen()),
          );
        } else {
          print('Profile is incomplete, navigating to RegistrationScreen'); // Debug log
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => RegistrationScreen(
                phoneNumber: widget.phoneNumber,
                token: response['access_token'],
              ),
            ),
          );
        }
      } catch (profileError) {
        print('Error checking user profile: $profileError'); // Debug log
        // If we can't get user profile, assume it's incomplete
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => RegistrationScreen(
              phoneNumber: widget.phoneNumber,
              token: response['access_token'],
            ),
          ),
        );
      }
    } catch (e) {
      print('OTP verification error: $e'); // Debug log
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid OTP. Please try again.'),
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
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Enter OTP',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Enter the 6-digit code sent to your phone',
              style: TextStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            PinCodeTextField(
              appContext: context,
              length: 6,
              controller: _otpController,
              keyboardType: TextInputType.number,
              autoFocus: true,
              animationType: AnimationType.fade,
              pinTheme: PinTheme(
                shape: PinCodeFieldShape.box,
                borderRadius: BorderRadius.circular(10),
                fieldHeight: 50,
                fieldWidth: 40,
                activeFillColor: Colors.grey[900],
                inactiveFillColor: Colors.grey[900],
                selectedFillColor: Colors.grey[850],
                activeColor: Colors.orange,
                selectedColor: Colors.orange,
                inactiveColor: Colors.grey,
                borderWidth: 1.5,
              ),
              textStyle: const TextStyle(color: Colors.white, fontSize: 20),
              backgroundColor: Colors.transparent,
              enableActiveFill: true,
              onChanged: (value) {},
            ),
            const SizedBox(height: 30),
            SizedBox(
              height: 50,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFFffa030),
                      Color(0xFFfe9b00),
                      Color(0xFFf67d00),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _verifyOTP,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child:
                      _isLoading
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                          : const Text(
                            'Verify OTP',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }
}