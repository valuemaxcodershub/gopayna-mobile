import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'notification.dart';
import 'profile.dart';
import 'referral_screen.dart';
import 'support.dart';
import 'legal.dart';
import 'app_settings.dart';
import 'api_service.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen>
    with TickerProviderStateMixin {
  late final AppSettings _appSettings;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _profileController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _profileAnimation;

  bool _isDarkMode = false;
  bool _showWalletBalance = true;
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _resetOtpController = TextEditingController();
  final TextEditingController _resetNewPasswordController =
      TextEditingController();
  final TextEditingController _resetConfirmPasswordController =
      TextEditingController();
  bool _obscurePin = true;
  String? _userEmail;
  String? _userPhone;
  String? _userDisplayName;
  String? _userProfileImagePath;
  bool _profileSummaryLoading = false;
  bool _submittingDeactivation = false;

  @override
  void initState() {
    super.initState();
    _appSettings = AppSettings();
    _isDarkMode = _appSettings.isDarkMode;
    _showWalletBalance = _appSettings.showWalletBalance;
    _initializeAnimations();
    _startAnimations();
    _loadStoredUserContact();
    _loadProfileSummary();
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
    _profileController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.elasticOut),
    );
    _profileAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _profileController, curve: Curves.elasticOut),
    );
  }

  Future<void> _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (mounted) _fadeController.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    if (mounted) _slideController.forward();
    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted) _profileController.forward();
  }

  Future<void> _loadStoredUserContact({bool force = false}) async {
    if (!force && (_userEmail != null || _userPhone != null)) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt');
      if (token == null || token.isEmpty) return;
      final parts = token.split('.');
      if (parts.length != 3) return;
      final payload = utf8.decode(
        base64Url.decode(
          base64Url.normalize(parts[1]),
        ),
      );
      final decoded = json.decode(payload);
      if (decoded is! Map) return;
      final email = _sanitizeContact(decoded['email']);
      final phone = _sanitizeContact(decoded['phone']);
      if (!context.mounted) return;
      if (email != _userEmail || phone != _userPhone) {
        setState(() {
          _userEmail = email;
          _userPhone = phone;
        });
      }
    } catch (e) {
      debugPrint('Failed to load user contact info: $e');
    }
  }

  String? _sanitizeContact(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  Future<void> _loadProfileSummary() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt');
      if (token == null) return;
      if (mounted) {
        setState(() {
          _profileSummaryLoading = true;
        });
      }
      final result = await fetchUserProfile(token);
      if (!mounted) return;
      setState(() {
        _profileSummaryLoading = false;
      });
      if (result['error'] != null) {
        debugPrint('Profile summary error: ${result['error']}');
        return;
      }
      final user = result['user'] as Map<String, dynamic>?;
      if (user == null) return;
      final firstName = (user['firstName'] ?? user['first_name'])?.toString();
      final lastName = (user['lastName'] ?? user['last_name'])?.toString();
      setState(() {
        _userDisplayName = _composeDisplayName(firstName, lastName, user);
        _userProfileImagePath = user['profileImageUrl']?.toString();
        _userEmail ??= user['email']?.toString();
        _userPhone ??= user['phone']?.toString();
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _profileSummaryLoading = false;
        });
      }
      debugPrint('Failed to load profile summary: $e');
    }
  }

  String _composeDisplayName(
    String? firstName,
    String? lastName,
    Map<String, dynamic> user,
  ) {
    final trimmedFirst = firstName?.trim();
    final trimmedLast = lastName?.trim();
    final combined = [trimmedFirst, trimmedLast]
        .whereType<String>()
        .where((value) => value.isNotEmpty)
        .join(' ');
    if (combined.isNotEmpty) return combined;
    final email = user['email']?.toString();
    if (email != null && email.contains('@')) {
      return email.split('@').first;
    }
    final phone = user['phone']?.toString();
    if (phone != null && phone.isNotEmpty) return phone;
    return 'there';
  }

  String? _resolveProfileImageUrl(String? relativePath) {
    if (relativePath == null || relativePath.isEmpty) return null;
    if (relativePath.startsWith('http')) return relativePath;
    return '$apiOrigin$relativePath';
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _profileController.dispose();
    _resetOtpController.dispose();
    _resetNewPasswordController.dispose();
    _resetConfirmPasswordController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    final statusBarHeight = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Column(
        children: [
          _buildCustomStatusBar(statusBarHeight),
          _buildHeader(isTablet),
          Expanded(
            child: _buildContent(isTablet),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomStatusBar(double statusBarHeight) {
    return Container(
      height: statusBarHeight,
      color: Theme.of(context).colorScheme.surface,
    );
  }

  Widget _buildHeader(bool isTablet) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 32 : 20,
          vertical: isTablet ? 20 : 16,
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: EdgeInsets.all(isTablet ? 12 : 8),
                decoration: BoxDecoration(
                  color: isDark
                      ? colorScheme.surfaceContainerHighest
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.3 : 0.1,
                      ),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.arrow_back,
                  color: colorScheme.onSurface,
                  size: isTablet ? 24 : 20,
                ),
              ),
            ),
            SizedBox(width: isTablet ? 16 : 12),
            Icon(
              Icons.settings,
              color: colorScheme.primary,
              size: isTablet ? 28 : 24,
            ),
            SizedBox(width: isTablet ? 12 : 8),
            Text(
              'Settings',
              style: TextStyle(
                fontSize: isTablet ? 24 : 20,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(bool isTablet) {
    return SlideTransition(
      position: _slideAnimation,
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 32 : 20,
        ),
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildProfileSection(isTablet),
            const SizedBox(height: 30),
            _buildSettingsOptions(isTablet),
            SizedBox(height: isTablet ? 60 : 40),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection(bool isTablet) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final resolvedPhoto = _resolveProfileImageUrl(_userProfileImagePath);
    final placeholderColor =
        isDark ? colorScheme.surfaceContainerLow : Colors.grey.shade200;
    final displayName = _userDisplayName ??
        (_profileSummaryLoading ? 'Loading profileâ€¦' : 'Hello there');
    return ScaleTransition(
      scale: _profileAnimation,
      child: Container(
        padding: EdgeInsets.all(isTablet ? 20 : 16),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: isDark ? 0.55 : 0.08,
              ),
              blurRadius: 14,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: isTablet ? 60 : 50,
              height: isTablet ? 60 : 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: placeholderColor,
              ),
              child: ClipOval(
                child: resolvedPhoto != null
                    ? Image.network(resolvedPhoto, fit: BoxFit.cover)
                    : Icon(
                        Icons.person,
                        size: isTablet ? 30 : 25,
                        color: isDark ? Colors.white70 : Colors.grey.shade500,
                      ),
              ),
            ),
            SizedBox(width: isTablet ? 16 : 12),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      displayName,
                      style: TextStyle(
                        fontSize: isTablet ? 20 : 18,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  if (_profileSummaryLoading)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            GestureDetector(
              onTap: _handleLogout,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 16 : 12,
                  vertical: isTablet ? 8 : 6,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? colorScheme.errorContainer.withValues(alpha: 0.25)
                      : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark
                        ? colorScheme.error.withValues(alpha: 0.4)
                        : Colors.red.shade200,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.logout,
                      color: colorScheme.error,
                      size: isTablet ? 18 : 16,
                    ),
                    SizedBox(width: isTablet ? 6 : 4),
                    Text(
                      'Logout',
                      style: TextStyle(
                        fontSize: isTablet ? 14 : 12,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.error,
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

  Widget _buildSettingsOptions(bool isTablet) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Account', isTablet, colorScheme),
          const SizedBox(height: 16),
          _buildSettingsCard(
            SettingsItem(
              icon: Icons.person_outline,
              title: 'My Profile',
              hasSwitch: false,
              onTap: () => _handleSettingsTap('My Profile'),
            ),
            isTablet,
            0,
            colorScheme,
            isDark,
          ),
          _buildSettingsCard(
            SettingsItem(
              icon: Icons.notifications_outlined,
              title: 'Notifications',
              hasSwitch: false,
              onTap: _handleNotificationTap,
            ),
            isTablet,
            1,
            colorScheme,
            isDark,
          ),
          _buildSettingsCard(
            SettingsItem(
              icon: Icons.people_outline,
              title: 'Referrals',
              hasSwitch: false,
              onTap: () => _handleSettingsTap('Referrals'),
            ),
            isTablet,
            2,
            colorScheme,
            isDark,
          ),
          _buildSettingsCard(
            SettingsItem(
              icon: Icons.help_outline,
              title: 'Help and support',
              hasSwitch: false,
              onTap: () => _handleSettingsTap('Help and support'),
            ),
            isTablet,
            3,
            colorScheme,
            isDark,
          ),
          const SizedBox(height: 32),
          _buildSectionTitle('Preference', isTablet, colorScheme),
          const SizedBox(height: 16),
          _buildSettingsCard(
            SettingsItem(
              icon: Icons.dark_mode_outlined,
              title: 'Dark Mode',
              hasSwitch: true,
              switchValue: _isDarkMode,
              onTap: () {},
              onSwitchChanged: (value) =>
                  _handleSwitchChange('Dark Mode', value),
            ),
            isTablet,
            4,
            colorScheme,
            isDark,
          ),
          _buildSettingsCard(
            SettingsItem(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Wallet Balance',
              hasSwitch: true,
              switchValue: _showWalletBalance,
              onTap: () {},
              onSwitchChanged: (value) =>
                  _handleSwitchChange('Wallet Balance', value),
            ),
            isTablet,
            5,
            colorScheme,
            isDark,
          ),
          const SizedBox(height: 32),
          _buildSectionTitle('Privacy and Security', isTablet, colorScheme),
          const SizedBox(height: 16),
          _buildSettingsCard(
            SettingsItem(
              icon: Icons.lock_reset_outlined,
              title: 'Reset Password',
              hasSwitch: false,
              onTap: _showResetPasswordModal,
            ),
            isTablet,
            6,
            colorScheme,
            isDark,
          ),
          _buildSettingsCard(
            SettingsItem(
              icon: Icons.pin_outlined,
              title: 'Set/Reset Withdrawal PIN',
              hasSwitch: false,
              onTap: _showWithdrawalPinModal,
            ),
            isTablet,
            7,
            colorScheme,
            isDark,
          ),
          const SizedBox(height: 32),
          _buildSectionTitle('More', isTablet, colorScheme),
          const SizedBox(height: 16),
          _buildSettingsCard(
            SettingsItem(
              icon: Icons.gavel_outlined,
              title: 'Legal',
              hasSwitch: false,
              onTap: () => _handleSettingsTap('Legal'),
            ),
            isTablet,
            8,
            colorScheme,
            isDark,
          ),
          _buildSettingsCard(
            SettingsItem(
              icon: Icons.delete_outline,
              title: 'Deactivate/Delete Account',
              hasSwitch: false,
              isDestructive: true,
              onTap: _handleDeactivateAccount,
            ),
            isTablet,
            9,
            colorScheme,
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(
    String title,
    bool isTablet,
    ColorScheme colorScheme,
  ) {
    return Text(
      title,
      style: TextStyle(
        fontSize: isTablet ? 20 : 18,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
    );
  }

  Widget _buildSettingsCard(
    SettingsItem item,
    bool isTablet,
    int index,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300 + (index * 100)),
      curve: Curves.easeOutCubic,
      margin: EdgeInsets.only(bottom: isTablet ? 12 : 8),
      child: GestureDetector(
        onTap: item.hasSwitch
            ? null
            : () {
                HapticFeedback.lightImpact();
                item.onTap();
              },
        child: Container(
          padding: EdgeInsets.all(isTablet ? 16 : 12),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.04),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: isDark ? 0.6 : 0.06,
                ),
                blurRadius: 12,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                item.icon,
                color: item.isDestructive
                    ? colorScheme.error
                    : colorScheme.primary,
                size: isTablet ? 24 : 20,
              ),
              SizedBox(width: isTablet ? 16 : 12),
              Expanded(
                child: Text(
                  item.title,
                  style: TextStyle(
                    fontSize: isTablet ? 16 : 14,
                    fontWeight: FontWeight.w500,
                    color: item.isDestructive
                        ? colorScheme.error
                        : colorScheme.onSurface,
                  ),
                ),
              ),
              if (item.hasSwitch)
                Switch(
                  value: item.switchValue ?? false,
                  onChanged: item.onSwitchChanged,
                  activeThumbColor: colorScheme.onPrimary,
                  activeTrackColor: colorScheme.primary.withValues(alpha: 0.4),
                  inactiveThumbColor:
                      isDark ? Colors.white54 : Colors.grey.shade400,
                  inactiveTrackColor:
                      isDark ? Colors.white24 : Colors.grey.shade300,
                ),
              if (!item.hasSwitch && !item.isDestructive)
                Icon(
                  Icons.arrow_forward_ios,
                  color: isDark ? Colors.white38 : Colors.grey.shade400,
                  size: isTablet ? 16 : 14,
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleSettingsTap(String setting) {
    switch (setting) {
      case 'My Profile':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ProfileScreen(),
          ),
        );
        break;
      case 'Referrals':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ReferrerPage(),
          ),
        );
        break;
      case 'Help and support':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const SupportScreen(),
          ),
        );
        break;
      case 'Legal':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const LegalScreen(),
          ),
        );
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$setting feature coming soon!'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  void _handleNotificationTap() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NotificationScreen(),
      ),
    );
  }

  void _handleSwitchChange(String setting, bool value) {
    setState(() {
      if (setting == 'Dark Mode') {
        _isDarkMode = value;
        _appSettings.toggleDarkMode(value);
      } else if (setting == 'Wallet Balance') {
        _showWalletBalance = value;
        _appSettings.toggleWalletBalance(value);
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$setting ${value ? "enabled" : "disabled"}'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.7),
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/login',
                (route) => false,
              );
            },
            child: Text(
              'Logout',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showResetPasswordModal() async {
    await _loadStoredUserContact(force: true);
    if (!mounted) return;
    final otpController = _resetOtpController..text = '';
    final newPasswordController = _resetNewPasswordController..text = '';
    final confirmPasswordController = _resetConfirmPasswordController
      ..text = '';
    final formKey = GlobalKey<FormState>();
    bool obscureNew = true;
    bool obscureConfirm = true;
    bool isSendingOtp = false;
    bool isResetting = false;
    String? otpError;
    String? contactError;
    String? otpSuccess;
    Timer? countdownTimer;
    Duration remaining = Duration.zero;

    void startTimer(StateSetter setModalState) {
      countdownTimer?.cancel();
      remaining = const Duration(minutes: 2);
      countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (remaining.inSeconds <= 1) {
          timer.cancel();
          remaining = Duration.zero;
          setModalState(() {});
        } else {
          remaining -= const Duration(seconds: 1);
          setModalState(() {});
        }
      });
    }

    Future<void> sendOtp(StateSetter setModalState) async {
      contactError = null;
      otpError = null;
      otpSuccess = null;
      final email = _userEmail?.trim();
      final phone = _userPhone?.trim();
      final hasEmail = email != null && email.isNotEmpty;
      final hasPhone = phone != null && phone.isNotEmpty;
      if (!hasEmail && !hasPhone) {
        setModalState(() {
          contactError =
              'No contact information found for this account. Please log in again.';
        });
        return;
      }
      final messenger = ScaffoldMessenger.of(context);
      final snackColorScheme = Theme.of(context).colorScheme;
      setModalState(() {
        isSendingOtp = true;
      });
      final result = await sendPasswordResetOtp(
        hasEmail ? email : null,
        hasEmail ? null : phone,
      );
      if (!context.mounted) return;
      setModalState(() {
        isSendingOtp = false;
      });
      if (result['error'] != null) {
        setModalState(() {
          contactError = result['error'].toString();
        });
        return;
      }
      setModalState(() {
        otpSuccess = 'OTP sent successfully';
      });
      startTimer(setModalState);
      messenger.showSnackBar(
        SnackBar(
          content: Text('OTP sent to your ${hasEmail ? 'email' : 'phone'}'),
          backgroundColor: snackColorScheme.primary,
        ),
      );
    }

    Future<void> submitReset(StateSetter setModalState) async {
      otpError = null;
      contactError = null;
      otpSuccess = null;
      if (!formKey.currentState!.validate()) {
        setModalState(() {});
        return;
      }
      final email = _userEmail?.trim();
      if (email == null || email.isEmpty) {
        setModalState(() {
          contactError =
              'Unable to determine your registered email. Please log in again.';
        });
        return;
      }
      final otp = otpController.text.trim();
      final newPassword = newPasswordController.text.trim();
      final navigator = Navigator.of(context);
      final messenger = ScaffoldMessenger.of(context);
      final snackColorScheme = Theme.of(context).colorScheme;

      setModalState(() {
        isResetting = true;
      });
      final result = await resetPassword(email, otp, newPassword);
      if (!context.mounted) return;
      setModalState(() {
        isResetting = false;
      });
      if (result['error'] != null) {
        setModalState(() {
          otpError = result['error'].toString();
        });
        return;
      }

      countdownTimer?.cancel();
      if (!mounted) return;
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(
          content: const Text('Password reset successful!'),
          backgroundColor: snackColorScheme.primary,
        ),
      );
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: isDark ? 0.7 : 0.12,
                  ),
                  blurRadius: 32,
                  offset: const Offset(0, -10),
                ),
              ],
            ),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      height: 4,
                      width: 40,
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: colorScheme.outlineVariant
                            .withValues(alpha: isDark ? 0.6 : 0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text(
                    'Reset Password',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Request a one-time passcode to create a new password.',
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.textTheme.bodySmall?.color?.withValues(
                            alpha: 0.8,
                          ) ??
                          colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(
                        alpha: isDark ? 0.18 : 0.08,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.mail_outline,
                          size: 20,
                          color: colorScheme.onPrimaryContainer,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _userEmail != null
                                ? 'OTP will be sent to ${_userEmail!}'
                                : _userPhone != null
                                    ? 'OTP will be sent to ${_userPhone!}'
                                    : 'We could not detect your registered contact. Please log in again.',
                            style: TextStyle(
                              color: colorScheme.onPrimaryContainer,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (contactError != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      contactError!,
                      style: TextStyle(
                        color: colorScheme.error,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: newPasswordController,
                    obscureText: obscureNew,
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureNew ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () {
                          setModalState(() {
                            obscureNew = !obscureNew;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Choose a new password';
                      }
                      if (value.length < 6 || value.length > 15) {
                        return 'Password must be 6-15 characters long';
                      }
                      final hasUpper = value.contains(RegExp(r'[A-Z]'));
                      final hasLower = value.contains(RegExp(r'[a-z]'));
                      if (!hasUpper || !hasLower) {
                        return 'Include both uppercase and lowercase letters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: confirmPasswordController,
                    obscureText: obscureConfirm,
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureConfirm
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setModalState(() {
                            obscureConfirm = !obscureConfirm;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Confirm your password';
                      }
                      if (value != newPasswordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: otpController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Enter OTP',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            errorText: otpError,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Enter the OTP you received';
                            }
                            if (value.length < 4) {
                              return 'OTP must be at least 4 digits';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: (isSendingOtp || remaining.inSeconds > 0)
                            ? null
                            : () => sendOtp(setModalState),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isSendingOtp
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Send OTP'),
                      ),
                    ],
                  ),
                  if (otpSuccess != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      otpSuccess!,
                      style: const TextStyle(
                        color: Color(0xFF00CA44),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  if (remaining.inSeconds > 0)
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'OTP expires in ${remaining.inMinutes.remainder(60).toString().padLeft(2, '0')}:${remaining.inSeconds.remainder(60).toString().padLeft(2, '0')}',
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            countdownTimer?.cancel();
                            Navigator.pop(context);
                          },
                          child: const Text(
                            'Cancel',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isResetting
                              ? null
                              : () => submitReset(setModalState),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: isResetting
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Reset Password',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    ).whenComplete(() {
      countdownTimer?.cancel();
      otpController.clear();
      newPasswordController.clear();
      confirmPasswordController.clear();
    });
  }

  void _showWithdrawalPinModal() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: isDark ? 0.7 : 0.1,
                  ),
                  blurRadius: 30,
                  offset: const Offset(0, -12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 4,
                  width: 40,
                  decoration: BoxDecoration(
                    color: colorScheme.outlineVariant
                        .withValues(alpha: isDark ? 0.6 : 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                Icon(
                  Icons.lock_outline,
                  size: 64,
                  color: colorScheme.primary,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Set/Reset Withdrawal PIN',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Create a secure 4-digit PIN for withdrawals and sensitive operations',
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.textTheme.bodySmall?.color?.withValues(
                          alpha: 0.8,
                        ) ??
                        colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _pinController,
                  keyboardType: TextInputType.number,
                  obscureText: _obscurePin,
                  maxLength: 4,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 8,
                  ),
                  decoration: InputDecoration(
                    hintText: '****',
                    hintStyle: TextStyle(
                      color: theme.inputDecorationTheme.hintStyle?.color ??
                          Colors.grey.shade500,
                      letterSpacing: 8,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: colorScheme.primary.withValues(alpha: 0.6),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: colorScheme.primary,
                        width: 2,
                      ),
                    ),
                    counterText: '',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePin ? Icons.visibility_off : Icons.visibility,
                      ),
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                      onPressed: () {
                        setModalState(() {
                          _obscurePin = !_obscurePin;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          _pinController.clear();
                          Navigator.pop(context);
                        },
                        child: const Text(
                          'Cancel',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (_pinController.text.length == 4) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text(
                                  'Withdrawal PIN updated successfully',
                                ),
                                backgroundColor: colorScheme.primary,
                              ),
                            );
                            _pinController.clear();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text(
                                  'Please enter a 4-digit PIN',
                                ),
                                backgroundColor: colorScheme.error,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Set PIN',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? theme.colorScheme.error : theme.colorScheme.primary,
      ),
    );
  }

  Future<void> _submitDeactivationRequest() async {
    if (_submittingDeactivation || !mounted) return;
    setState(() => _submittingDeactivation = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt');
    if (token == null || token.isEmpty) {
      if (mounted) {
        setState(() => _submittingDeactivation = false);
        _showSnack('Please log in again to continue.', isError: true);
      }
      return;
    }

    if (!mounted) {
      _submittingDeactivation = false;
      return;
    }
    final navigator = Navigator.of(context, rootNavigator: true);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final response = await requestAccountDeactivation(
        token: token,
        reason: 'User initiated account deactivation from the mobile app.',
      );
      navigator.pop();
      if (!mounted) return;
      if (response['error'] != null) {
        _showSnack(response['error'].toString(), isError: true);
      } else {
        _showSnack('Support (support@gopayna.com) has been notified.');
      }
    } catch (e) {
      navigator.pop();
      if (mounted) {
        _showSnack('Could not submit the request. Please try again.',
            isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _submittingDeactivation = false);
      } else {
        _submittingDeactivation = false;
      }
    }
  }

  void _handleDeactivateAccount() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Deactivate Account'),
        content: const Text(
          'Are you sure you want to deactivate your account? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.7),
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _submitDeactivationRequest();
            },
            child: Text(
              'Deactivate',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SettingsItem {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isDestructive;
  final bool hasSwitch;
  final bool? switchValue;
  final Function(bool)? onSwitchChanged;

  SettingsItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.isDestructive = false,
    this.hasSwitch = false,
    this.switchValue,
    this.onSwitchChanged,
  });
}

