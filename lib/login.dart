import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:developer';
import 'register.dart';
import 'api_service.dart';
import 'otp_verification.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dashboard.dart';
import 'forgot_password.dart';
import 'intro_screen.dart';
import 'services/credentials_service.dart';
import 'services/inactivity_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.redirectToIntroOnExit = false});

  final bool redirectToIntroOnExit;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _buttonController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _buttonScale;
  final Color _brandColor = const Color(0xFF00CA44);

  bool _handleBackNavigation() {
    if (!widget.redirectToIntroOnExit) {
      return true;
    }

    if (Navigator.of(context).canPop()) {
      return true;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoadingPage()),
    );
    return false;
  }

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(duration: const Duration(milliseconds: 1000), vsync: this);
    _slideController = AnimationController(duration: const Duration(milliseconds: 1200), vsync: this);
    _buttonController = AnimationController(duration: const Duration(milliseconds: 800), vsync: this);
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));
    _buttonScale = Tween<double>(begin: 0.8, end: 1.0).animate(CurvedAnimation(parent: _buttonController, curve: Curves.elasticOut));
    _loadSavedUsername();
    _startAnimations();
  }

  void _loadSavedUsername() async {
    try {
      final savedUsername = await CredentialsService.getSavedUsername();
      if (savedUsername != null) {
        setState(() {
          _usernameController.text = savedUsername;
        });
      }
    } catch (e) {
      log('Error loading saved username: $e');
    }
  }

  void _startAnimations() async {
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
    _usernameController.dispose();
    _passwordController.dispose();
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
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final labelColor = cs.onSurface.withValues(alpha: 0.87);
    final fieldStyle =
        TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: labelColor);
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: labelColor,
                  letterSpacing: 0.2)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2)),
              ],
            ),
            child: TextFormField(
              controller: controller,
              keyboardType: keyboardType,
              obscureText: obscureText,
              validator: validator,
              style: fieldStyle,
              decoration: InputDecoration(
                filled: true,
                fillColor: theme.inputDecorationTheme.fillColor ??
                    (theme.brightness == Brightness.dark
                        ? cs.surfaceContainerHighest
                        : Colors.white),
                prefixIcon: prefixIcon,
                suffixIcon: suffixIcon,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: _brandColor.withValues(alpha: 0.3), width: 1.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: _brandColor.withValues(alpha: 0.3), width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: _brandColor, width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.red, width: 1.5),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.red, width: 2),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      HapticFeedback.lightImpact();
      setState(() => _isLoading = true);
      
      // Get device ID for single-device login enforcement
      final deviceInfo = await CredentialsService.getDeviceIdInfo();
      
      final result = await loginUser(
        _usernameController.text,
        _passwordController.text,
        deviceId: deviceInfo.deviceId,
        forceLogin: deviceInfo.isNew,
      );
      if (!mounted) return;
      setState(() => _isLoading = false);
      
      if (result['error'] != null) {
        final errorCode = result['code']?.toString();
        final errorMsg = result['error'].toString();
        
        // Check if account is deactivated by admin
        if (errorCode == 'ACCOUNT_DEACTIVATED') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMsg),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
          return;
        }
        
        // Check for device conflict
        if (errorCode == 'DEVICE_CONFLICT') {
          final shouldForce = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Active session detected'),
                  content: const Text(
                      'This account is already logged in on another device. Do you want to sign out from other devices and continue here?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Continue'),
                    ),
                  ],
                ),
              ) ??
              false;

          if (!shouldForce) {
            return;
          }

          setState(() => _isLoading = true);
          final retryResult = await loginUser(
            _usernameController.text,
            _passwordController.text,
            deviceId: deviceInfo.deviceId,
            forceLogin: true,
          );
          if (!mounted) return;
          setState(() => _isLoading = false);

          if (retryResult['error'] != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(retryResult['error'].toString()), backgroundColor: Colors.red),
            );
            return;
          }

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('jwt', retryResult['token']);
          await CredentialsService.saveUsername(_usernameController.text.trim());
          InactivityService().resetTimer();
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const DashboardScreen()),
          );
          return;
        }
        
        // If error is for email verification, redirect to OTP page
        if (errorMsg.contains('verify your email with OTP') || errorMsg.contains('verify your email')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Please verify your email.'), backgroundColor: Colors.orange),
          );
          await Future.delayed(const Duration(seconds: 1));
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => OtpVerificationScreen(
                email: result['email'] ?? _usernameController.text.trim(),
                purpose: OtpPurpose.login,
                password: _passwordController.text,
              ),
            ),
          );
        } else {
          // Show other errors
          log('Login error: $errorMsg', name: 'login_screen');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
          );
        }
      } else {
        // Save JWT token
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt', result['token']);
        
        // Save username for future logins
        await CredentialsService.saveUsername(_usernameController.text.trim());
        
        // Start inactivity timer
        InactivityService().resetTimer();
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login successful!'), backgroundColor: _brandColor),
        );
        await Future.delayed(const Duration(seconds: 1));
        if (!mounted) return;
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DashboardScreen()));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return PopScope(
      canPop: !widget.redirectToIntroOnExit,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop || !widget.redirectToIntroOnExit) {
          return;
        }
        _handleBackNavigation();
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
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
                      color: cs.surface,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 2))],
                    ),
                    child: IconButton(
                      icon: Icon(Icons.arrow_back, color: cs.onSurface),
                      onPressed: () {
                        if (_handleBackNavigation() && Navigator.of(context).canPop()) {
                          Navigator.pop(context);
                        }
                      },
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
                              label: 'Email or Phone Number',
                              controller: _usernameController,
                              keyboardType: TextInputType.text,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your email or phone number';
                                }
                                return null;
                              },
                            ),
                            _buildTextField(
                              label: 'Password',
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              suffixIcon: IconButton(
                                icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: theme.iconTheme.color?.withValues(alpha: 0.65)),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Please enter your password';
                                if (value.length < 6) return 'Password must be at least 6 characters';
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => ForgotPasswordScreen()),
                                  );
                                },
                                child: Text(
                                  'Forgot Password?',
                                  style: TextStyle(
                                    color: _brandColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                            ScaleTransition(
                              scale: _buttonScale,
                              child: SizedBox(
                                width: double.infinity,
                                height: isTablet ? 58 : 54,
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(27),
                                    boxShadow: [
                                      BoxShadow(
                                        color: _brandColor.withValues(alpha: 0.4),
                                        blurRadius: 16,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _handleLogin,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _brandColor,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shadowColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(27),
                                      ),
                                    ),
                                    child: _isLoading
                                        ? const CircularProgressIndicator(color: Colors.white)
                                        : Text(
                                            'LOGIN',
                                            style: TextStyle(
                                              fontSize: isTablet ? 18 : 16,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 1.2,
                                            ),
                                          ),
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
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const RegisterScreen(),
                                      ),
                                    );
                                  },
                                  child: RichText(
                                    text: TextSpan(
                                      text: "Don't have an Account? ",
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: cs.onSurface.withValues(alpha: 0.87),
                                        fontWeight: FontWeight.w400,
                                      ),
                                      children: [
                                        TextSpan(
                                          text: 'Register',
                                          style: TextStyle(
                                            color: _brandColor,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
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
      ),
    );
  }
}


