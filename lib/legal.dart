import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'idle_timeout_service.dart';

class LegalScreen extends StatefulWidget {
  const LegalScreen({super.key, this.showLogout = true});

  /// Whether to show the logout button in the header.
  /// Set to false when accessed from registration flow.
  final bool showLogout;

  @override
  State<LegalScreen> createState() => _LegalScreenState();
}

class _LegalScreenState extends State<LegalScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  ColorScheme get _colorScheme => Theme.of(context).colorScheme;
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _cardColor => _colorScheme.surface;
  Color get _mutedText => _colorScheme.onSurface.withValues(alpha: 0.72);
  Color get _shadowColor => Colors.black.withValues(alpha: _isDark ? 0.4 : 0.08);

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.elasticOut,
    ));
  }

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 100));
    _fadeController.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout from your account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: _mutedText),
            ),
          ),
          TextButton(
            onPressed: () async {
              // Stop idle timeout tracking
              IdleTimeoutService().dispose();
              
              // Clear JWT token
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('jwt');
              
              if (!context.mounted) return;
              Navigator.pop(context); // Close dialog
              Navigator.popUntil(context, (route) => route.isFirst); // Go to main screen
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Logged out successfully'),
                  backgroundColor: _colorScheme.error,
                ),
              );
            },
            child: Text(
              'Logout',
              style: TextStyle(color: _colorScheme.error, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    final statusBarHeight = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          _buildCustomStatusBar(statusBarHeight),
          _buildHeader(isTablet),
          Expanded(
            child: _buildLegalContent(isTablet),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomStatusBar(double statusBarHeight) {
    return Container(
      height: statusBarHeight,
      color: Theme.of(context).scaffoldBackgroundColor,
    );
  }

  Widget _buildHeader(bool isTablet) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 32 : 20,
          vertical: isTablet ? 20 : 16,
        ),
        decoration: BoxDecoration(
          color: _cardColor,
          boxShadow: [
            BoxShadow(
              color: _shadowColor,
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: EdgeInsets.all(isTablet ? 12 : 8),
                decoration: BoxDecoration(
                  color: _isDark
                      ? _colorScheme.surfaceContainerHighest
                      : _colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.arrow_back,
                  color: _colorScheme.onSurface,
                  size: isTablet ? 24 : 20,
                ),
              ),
            ),
            SizedBox(width: isTablet ? 16 : 12),
            Icon(
              Icons.gavel,
              color: _colorScheme.primary,
              size: isTablet ? 28 : 24,
            ),
            SizedBox(width: isTablet ? 12 : 8),
            Expanded(
              child: Text(
                'Legal',
                style: TextStyle(
                  fontSize: isTablet ? 24 : 20,
                  fontWeight: FontWeight.bold,
                  color: _colorScheme.onSurface,
                ),
              ),
            ),
            if (widget.showLogout)
              GestureDetector(
                onTap: _handleLogout,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 16 : 12,
                    vertical: isTablet ? 10 : 8,
                  ),
                  decoration: BoxDecoration(
                    color: _colorScheme.error.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _colorScheme.error,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.logout,
                        color: _colorScheme.error,
                        size: isTablet ? 18 : 16,
                      ),
                      SizedBox(width: isTablet ? 8 : 4),
                      Text(
                        'Logout',
                        style: TextStyle(
                          color: _colorScheme.error,
                          fontSize: isTablet ? 14 : 12,
                          fontWeight: FontWeight.w600,
                        ),
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

  Widget _buildLegalContent(bool isTablet) {
    return SlideTransition(
      position: _slideAnimation,
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 32 : 20,
          vertical: isTablet ? 24 : 20,
        ),
        child: Column(
          children: [
            _buildLegalSection(
              'Terms of Service',
              _getTermsOfService(),
              isTablet,
            ),
            SizedBox(height: isTablet ? 32 : 24),
            _buildLegalSection(
              'Privacy Policy',
              _getPrivacyPolicy(),
              isTablet,
            ),
            SizedBox(height: isTablet ? 32 : 24),
            _buildLegalSection(
              'Cookie Policy',
              _getCookiePolicy(),
              isTablet,
            ),
            SizedBox(height: isTablet ? 32 : 24),
            _buildLegalSection(
              'Disclaimer',
              _getDisclaimer(),
              isTablet,
            ),
            SizedBox(height: isTablet ? 40 : 30),
          ],
        ),
      ),
    );
  }

  Widget _buildLegalSection(String title, String content, bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 24 : 20),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
        boxShadow: [
          BoxShadow(
            color: _shadowColor,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: isTablet ? 20 : 18,
              fontWeight: FontWeight.bold,
              color: _colorScheme.primary,
            ),
          ),
          SizedBox(height: isTablet ? 16 : 12),
          Text(
            content,
            style: TextStyle(
              fontSize: isTablet ? 14 : 12,
              color: _mutedText,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  String _getTermsOfService() {
    return '''Welcome to Gopayna. By using our mobile application, you agree to be bound by these Terms of Service.

1. ACCEPTANCE OF TERMS
By accessing and using Gopayna, you accept and agree to be bound by the terms and provision of this agreement.

2. SERVICE DESCRIPTION
Gopayna is a mobile payment platform that allows users to purchase airtime, data, pay electricity bills, TV subscriptions, and education pins.

3. USER RESPONSIBILITIES
- You must provide accurate and complete information
- You are responsible for maintaining the confidentiality of your account
- You must not use the service for any illegal purposes
- You agree to pay all charges incurred by your account

4. PAYMENT TERMS
- All payments are processed securely
- Refunds are subject to our refund policy
- Service charges may apply to certain transactions

5. LIMITATION OF LIABILITY
Gopayna shall not be liable for any indirect, incidental, special, or consequential damages.

6. TERMINATION
We reserve the right to terminate or suspend your account at any time for violation of these terms.

7. GOVERNING LAW
These terms shall be governed by the laws of the Federal Republic of Nigeria.

For questions about these Terms of Service, please contact our support team.

Last updated: November 2025''';
  }

  String _getPrivacyPolicy() {
    return '''Gopayna is committed to protecting your privacy. This Privacy Policy explains how we collect, use, and protect your information.

1. INFORMATION WE COLLECT
- Personal information (name, phone number, email)
- Transaction data and payment information
- Device information and usage data
- Location information (with your permission)

2. HOW WE USE YOUR INFORMATION
- To process your transactions
- To provide customer support
- To improve our services
- To send important notifications
- To detect and prevent fraud

3. INFORMATION SHARING
We do not sell, trade, or rent your personal information to third parties. We may share information:
- With service providers who help us operate our platform
- When required by law or legal process
- To protect our rights and prevent fraud

4. DATA SECURITY
We implement industry-standard security measures to protect your personal information:
- Encryption of sensitive data
- Secure payment processing
- Regular security audits
- Access controls and monitoring

5. YOUR RIGHTS
You have the right to:
- Access your personal information
- Update or correct your data
- Delete your account and data
- Opt-out of marketing communications

6. COOKIES AND TRACKING
We use cookies and similar technologies to enhance your experience and analyze usage patterns.

7. DATA RETENTION
We retain your information only as long as necessary to provide our services and comply with legal obligations.

8. CONTACT US
For privacy-related questions, contact us at privacy@gopayna.com

Last updated: November 2025''';
  }

  String _getCookiePolicy() {
    return '''This Cookie Policy explains how Gopayna uses cookies and similar technologies.

1. WHAT ARE COOKIES
Cookies are small text files stored on your device that help us provide and improve our services.

2. TYPES OF COOKIES WE USE
- Essential Cookies: Necessary for the app to function properly
- Performance Cookies: Help us understand how you use our app
- Functional Cookies: Remember your preferences and settings
- Analytics Cookies: Help us analyze usage and improve our services

3. HOW WE USE COOKIES
- To keep you logged in
- To remember your preferences
- To improve app performance
- To analyze usage patterns
- To enhance security

4. MANAGING COOKIES
You can control cookies through your device settings. However, disabling cookies may affect app functionality.

5. THIRD-PARTY COOKIES
We may use third-party services that set cookies:
- Analytics providers
- Payment processors
- Customer support tools

6. UPDATES TO THIS POLICY
We may update this Cookie Policy from time to time. Check this page for the latest version.

For questions about cookies, contact our support team.

Last updated: November 2025''';
  }

  String _getDisclaimer() {
    return '''IMPORTANT DISCLAIMER - PLEASE READ CAREFULLY

1. GENERAL DISCLAIMER
The information and services provided by Gopayna are on an "as is" basis. We make no warranties or guarantees about the accuracy, reliability, or availability of our services.

2. SERVICE AVAILABILITY
- Services may be temporarily unavailable due to maintenance or technical issues
- We are not responsible for service interruptions by third-party providers
- Transaction processing times may vary

3. FINANCIAL TRANSACTIONS
- All transactions are final once processed
- We are not responsible for errors in recipient information provided by users
- Refunds are subject to our refund policy and provider terms

4. THIRD-PARTY SERVICES
- We partner with various service providers (network operators, utility companies)
- We are not responsible for the quality or availability of third-party services
- Issues with third-party services should be directed to the respective providers

5. SECURITY
- While we implement security measures, no system is 100% secure
- Users are responsible for protecting their account credentials
- Report any suspicious activity immediately

6. TECHNICAL REQUIREMENTS
- Our app requires compatible devices and internet connectivity
- We are not responsible for device compatibility issues
- Regular app updates may be required

7. LIMITATION OF LIABILITY
In no event shall Gopayna be liable for any direct, indirect, incidental, special, or consequential damages arising from the use of our services.

8. INDEMNIFICATION
Users agree to indemnify and hold Gopayna harmless from any claims arising from their use of our services.

By using Gopayna, you acknowledge that you have read, understood, and agree to this disclaimer.

Last updated: November 2025''';
  }
}
