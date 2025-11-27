import 'package:flutter/material.dart';
import 'dart:async';
import 'api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum OtpPurpose { registration, login, passwordReset }


class OtpVerificationScreen extends StatefulWidget {
  final String email;
  final OtpPurpose purpose;
  final String? password;

  const OtpVerificationScreen({super.key, required this.email, required this.purpose, this.password});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final int otpLength = 6;
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;
  bool _isLoading = false;
  late DateTime _otpExpiry;
  late Duration _remaining;
  Timer? _timer;
  bool _canRegenerate = false;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(otpLength, (_) => TextEditingController());
    _focusNodes = List.generate(otpLength, (_) => FocusNode());
    _startOtpTimer();
  }

  void _startOtpTimer() {
    _otpExpiry = DateTime.now().add(const Duration(minutes: 10));
    _remaining = _otpExpiry.difference(DateTime.now());
    _canRegenerate = false;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _remaining = _otpExpiry.difference(DateTime.now());
        if (_remaining.inSeconds <= 0) {
          _canRegenerate = true;
          _timer?.cancel();
        }
      });
    });
  }

  Future<void> _regenerateOtp() async {
    setState(() => _isLoading = true);
    Map<String, dynamic> result;
    switch (widget.purpose) {
      case OtpPurpose.registration:
        result = await sendVerificationOtp(widget.email);
        break;
      case OtpPurpose.login:
        result = await sendVerificationOtp(widget.email);
        break;
      case OtpPurpose.passwordReset:
        final isEmail = widget.email.contains('@');
        result = await sendPasswordResetOtp(isEmail ? widget.email : null, isEmail ? null : widget.email);
        break;
    }
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (result['error'] != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['error']), backgroundColor: Colors.red),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New OTP sent to your email!')),
      );
      _startOtpTimer();
      for (var c in _controllers) { c.clear(); }
      _focusNodes[0].requestFocus();
    }
  }

  @override
  void dispose() {
    for (var c in _controllers) { c.dispose(); }
    for (var f in _focusNodes) { f.dispose(); }
    _timer?.cancel();
    super.dispose();
  }

  void _onOtpChanged(int idx, String value) {
    
    if (value.length > 1) {
      for (int i = 0; i < otpLength; i++) {
        _controllers[i].text = i < value.length ? value[i] : '';
      }
      
      if (value.length >= otpLength) {
        _focusNodes[otpLength - 1].requestFocus();
      } else {
        _focusNodes[value.length].requestFocus();
      }
      return;
    }
   
    if (value.length == 1 && idx < otpLength - 1) {
      _focusNodes[idx + 1].requestFocus();
    } else if (value.isEmpty && idx > 0) {
      _focusNodes[idx - 1].requestFocus();
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _controllers.map((c) => c.text).join();
    if (otp.length != otpLength) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the complete OTP')),
      );
      return;
    }
    setState(() => _isLoading = true);
    final result = await verifyOtp(widget.email, otp);
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (result['error'] != null) {
      String errorMsg = result['error'].toString().toLowerCase();
      String displayMsg;
      if (errorMsg.contains('expired')) {
        displayMsg = 'The OTP has expired. Please generate a new OTP.';
      } else if (errorMsg.contains('invalid') || errorMsg.contains('incorrect')) {
        displayMsg = 'Incorrect OTP. Please check and retry.';
      } else {
        displayMsg = result['error'].toString();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(displayMsg), backgroundColor: Colors.red),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OTP verified! Logging you in...')),
      );

      // Save token and user info from OTP verification response
      if (result['token'] != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt', result['token']);
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/dashboard');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No token received after OTP verification.'), backgroundColor: Colors.red),
        );
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final brandColor = const Color(0xFF00B82E);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Email', style: TextStyle(color: Colors.white)),
        backgroundColor: brandColor,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Enter the 6-digit OTP sent to your email',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: brandColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              _canRegenerate
                  ? 'OTP expired. You can generate a new one.'
                  : 'OTP expires in: ${_remaining.inMinutes.remainder(60).toString().padLeft(2, '0')}:${(_remaining.inSeconds.remainder(60)).toString().padLeft(2, '0')}',
              style: TextStyle(fontSize: 16, color: _canRegenerate ? Colors.red : Colors.black54),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(otpLength, (idx) => Container(
                width: 44,
                height: 56,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: brandColor.withAlpha(20), blurRadius: 8, offset: const Offset(0, 2)),
                  ],
                  border: Border.all(color: brandColor.withAlpha(128), width: 1.5),
                ),
                child: TextField(
                  controller: _controllers[idx],
                  focusNode: _focusNodes[idx],
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 1,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2),
                  decoration: const InputDecoration(
                    counterText: '',
                    border: InputBorder.none,
                  ),
                  onChanged: (val) => _onOtpChanged(idx, val),
                  onTap: () => _controllers[idx].selection = TextSelection(baseOffset: 0, extentOffset: _controllers[idx].text.length),
                ),
              )),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isLoading || _canRegenerate ? null : _verifyOtp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: brandColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Verify', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 18),
            TextButton(
              onPressed: _isLoading ? null : () {
                for (var c in _controllers) { c.clear(); }
                _focusNodes[0].requestFocus();
              },
              child: Text('Clear OTP', style: TextStyle(color: brandColor, fontWeight: FontWeight.w500)),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: _canRegenerate && !_isLoading ? _regenerateOtp : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _canRegenerate ? brandColor : Colors.grey,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Generate New OTP'),
            ),
          ],
        ),
      ),
    );
  }
}