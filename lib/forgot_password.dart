import 'package:flutter/material.dart';

// Removed unused import
import 'api_service.dart';
import 'otp_verification.dart';


class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _userController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  String? _errorText;

  @override
  void dispose() {
    _userController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ...existing code...
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF00CA44),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Forgot Password',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color.fromRGBO(0, 0, 0, 0.05),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.lock_outline, color: Color(0xFF00CA44), size: 48),
                  const SizedBox(height: 16),
                  const Text(
                    'Reset Your Password',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF00CA44),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Enter your email or phone number to receive a secure OTP.',
                    style: TextStyle(fontSize: 15, color: Colors.black87),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _userController,
                    keyboardType: TextInputType.text,
                    decoration: InputDecoration(
                      labelText: 'Email or Phone',
                      labelStyle: const TextStyle(color: Color(0xFF00CA44)),
                      prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF00CA44)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF00CA44)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF00CA44)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (_errorText != null) ...[
                    Text(_errorText!, style: const TextStyle(color: Colors.red, fontSize: 14)),
                    const SizedBox(height: 8),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _sendOtp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00CA44),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoading
                          ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Send OTP', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  // ...existing code...

  Future<void> _sendOtp() async {
    setState(() {
      _isLoading = true;
      _errorText = null;
    });
    final input = _userController.text.trim();
    final isEmail = input.contains('@');
    final result = await sendPasswordResetOtp(isEmail ? input : null, isEmail ? null : input);
    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });
    if (result['error'] != null) {
      final errorCode = result['code']?.toString();
      String errorMsg = result['error'].toString().toLowerCase();
      String displayMsg;
      
      // Check if account is suspended by admin
      if (errorCode == 'ACCOUNT_DEACTIVATED') {
        displayMsg = result['error'].toString();
      } else if (errorMsg.contains('not found')) {
        displayMsg = 'The detail you entered was not found. Please check and try again.';
      } else {
        displayMsg = result['error'].toString();
      }
      if (!mounted) return;
      setState(() {
        _errorText = displayMsg;
      });
    } else {
      // Navigate to OTP verification screen for password reset
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => OtpVerificationScreen(
            email: _userController.text.trim(),
            purpose: OtpPurpose.passwordReset,
          ),
        ),
      );
    }
  }
  // Password reset logic now handled in OtpVerificationScreen
}

