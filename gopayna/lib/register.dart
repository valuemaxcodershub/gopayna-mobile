import 'dart:async';
import 'dart:developer'; // Import for logging
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:app_links/app_links.dart';
import 'login.dart';

import 'api_service.dart';
import 'otp_verification.dart';
import 'app_settings.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, this.initialReferralCode});

  final String? initialReferralCode;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _referralCodeController = TextEditingController(); // Add a TextEditingController for the referral code

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _buttonController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _buttonScale;

  final Color _brandColor = AppSettings.brandColorLight;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  StreamSubscription<String?>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(duration: const Duration(milliseconds: 1000), vsync: this);
    _slideController = AnimationController(duration: const Duration(milliseconds: 1200), vsync: this);
    _buttonController = AnimationController(duration: const Duration(milliseconds: 800), vsync: this);
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));
    _buttonScale = Tween<double>(begin: 0.8, end: 1.0).animate(CurvedAnimation(parent: _buttonController, curve: Curves.elasticOut));
    if (widget.initialReferralCode != null && widget.initialReferralCode!.isNotEmpty) {
      _referralCodeController.text = widget.initialReferralCode!;
    }
    _initializeDeepLinks();
    _startAnimations();
  }
  Future<void> _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 100));
    _fadeController.forward();
    _slideController.forward();
    await Future.delayed(const Duration(milliseconds: 600));
    _buttonController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _buttonController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _referralCodeController.dispose();
    _linkSubscription?.cancel();
    super.dispose();
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    Widget? prefixIcon,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87, letterSpacing: 0.2),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2)),
              ],
            ),
            child: TextFormField(
              controller: controller,
              keyboardType: keyboardType,
              obscureText: obscureText,
              validator: validator,
              inputFormatters: inputFormatters,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                prefixIcon: prefixIcon,
                suffixIcon: suffixIcon,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: _brandColor.withValues(alpha: 0.3), width: 1.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: _brandColor.withValues(alpha: 0.3), width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: _brandColor, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _initializeDeepLinks() async {
    if (kIsWeb) return; // app_links handles web differently
    final appLinks = AppLinks();
    await _handleReferralLink(appLinks);
    _linkSubscription = appLinks.uriLinkStream.map((uri) => uri.toString()).listen(
      (link) => _applyReferralCodeFromLink(link),
      onError: (_) {},
    );
  }

  Future<void> _handleReferralLink(AppLinks appLinks) async {
    final initialLink = await appLinks.getInitialLink();
    _applyReferralCodeFromLink(initialLink?.toString());
  }

  void _applyReferralCodeFromLink(String? link) {
    if (link == null || link.isEmpty) return;
    final uri = Uri.tryParse(link);
    if (uri == null) return;
    final referralCode = uri.queryParameters['referral'];
    if (referralCode != null && referralCode.isNotEmpty) {
      setState(() {
        _referralCodeController.text = referralCode;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            // Header with back button and logo
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: IconButton(
                      icon: Icon(Icons.arrow_back, color: Colors.black87),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(color: _brandColor, shape: BoxShape.circle),
                          child: Center(
                            child: Image.asset('assets/logowhite.png', width: 30, height: 30, fit: BoxFit.contain),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // Form content
            Expanded(
              child: SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: isTablet ? 40 : 24, vertical: 20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTextField(
                            label: 'First Name',
                            controller: _firstNameController,
                            keyboardType: TextInputType.name,
                            validator: (value) => value == null || value.isEmpty ? 'Please enter your first name' : null,
                          ),
                          _buildTextField(
                            label: 'Last Name',
                            controller: _lastNameController,
                            keyboardType: TextInputType.name,
                            validator: (value) => value == null || value.isEmpty ? 'Please enter your last name' : null,
                          ),
                          _buildTextField(
                            label: 'Phone Number',
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(11),
                            ],
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your phone number';
                                }
                                if (!RegExp(r'^\d{11}$').hasMatch(value)) {
                                  return 'Phone number must be exactly 11 digits';
                                }
                                return null;
                              },
                          ),
                          _buildTextField(
                            label: 'Email',
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Please enter your email';
                              // Improved email format check
                              final emailRegex = RegExp(r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$');
                              if (!emailRegex.hasMatch(value)) return 'Enter a valid email address';
                              return null;
                            },
                          ),
                          _buildTextField(
                            label: 'Password',
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey[600]),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Please enter your password';
                              if (value.length < 6 || value.length > 11) return 'Password must be 6-11 characters';
                              final upper = RegExp(r'[A-Z]');
                              final lower = RegExp(r'[a-z]');
                              final digit = RegExp(r'[0-9]');
                              if (!upper.hasMatch(value)) return 'Password must contain an uppercase letter';
                              if (!lower.hasMatch(value)) return 'Password must contain a lowercase letter';
                              if (!digit.hasMatch(value)) return 'Password must contain a number';
                              return null;
                            },
                          ),
                          _buildTextField(
                            label: 'Confirm Password',
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirmPassword,
                            suffixIcon: IconButton(
                              icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey[600]),
                              onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Please confirm your password';
                              if (value != _passwordController.text) return 'Passwords do not match';
                              return null;
                            },
                          ),
                          _buildTextField(
                            label: 'Referral Code (Optional)',
                            controller: _referralCodeController,
                            keyboardType: TextInputType.text,
                          ),
                          const SizedBox(height: 20),
                          ScaleTransition(
                            scale: _buttonScale,
                            child: SizedBox(
                              width: double.infinity,
                              height: isTablet ? 58 : 54,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(27),
                                  boxShadow: [
                                    BoxShadow(color: _brandColor.withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 6)),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : () async {
                                    if (_formKey.currentState!.validate()) {
                                      HapticFeedback.lightImpact();
                                      setState(() => _isLoading = true);
                                      final result = await registerUser(
                                        _firstNameController.text,
                                        _lastNameController.text,
                                        _phoneController.text,
                                        _emailController.text,
                                        _passwordController.text,
                                        _referralCodeController.text, // Pass referral code
                                      );
                                      if (!mounted) return; // Check if the widget is still mounted
                                      setState(() => _isLoading = false);
                                      log('Registration result: $result', name: 'RegisterScreen'); // Log the result
                                      if (result['error'] != null) {
                                        if (!context.mounted) return;
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text(result['error']), backgroundColor: Colors.red),
                                        );
                                      } else {
                                        if (!context.mounted) return;
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Registration successful! Please verify your email.'),
                                            backgroundColor: Color(0xFF00CA44),
                                          ),
                                        );
                                        await Future.delayed(const Duration(seconds: 2));
                                        if (!context.mounted) return; // Check if the widget is still mounted before navigation
                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => OtpVerificationScreen(
                                              email: _emailController.text.trim(),
                                              purpose: OtpPurpose.registration,
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _brandColor,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(27)),
                                  ),
                                  child: _isLoading
                                      ? const CircularProgressIndicator(color: Colors.white)
                                      : Text('NEXT', style: TextStyle(fontSize: isTablet ? 18 : 16, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Center(
                            child: FadeTransition(
                              opacity: _fadeAnimation,
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
                                },
                                child: RichText(
                                  text: TextSpan(
                                    text: 'Already have an Account? ',
                                    style: TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w400),
                                    children: [
                                      TextSpan(text: 'Log in', style: TextStyle(color: _brandColor, fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: isTablet ? 40 : 30),
                        ],
                      ),
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
}

