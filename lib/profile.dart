import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_service.dart';
import 'widgets/wallet_visibility_builder.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final ImagePicker _picker = ImagePicker();

  bool _loadingProfile = true;
  bool _uploadingPhoto = false;
  String? _fullName;
  String? _email;
  String? _phone;
  String? _profileImagePath;
  String? _walletBalance;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
    _loadProfile();
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

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutBack),
    );
  }

  Future<void> _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (mounted) _fadeController.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    if (mounted) _slideController.forward();
  }

  Future<void> _loadProfile() async {
    setState(() => _loadingProfile = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt');
      if (token == null) {
        setState(() {
          _fullName = 'Guest';
          _email = null;
          _phone = null;
        });
        return;
      }

      final result = await fetchUserProfile(token);
      if (!mounted) return;

      if (result['error'] != null) {
        _showMessage(result['error'].toString(), isError: true);
        return;
      }

      final user = result['user'] as Map<String, dynamic>?;
      if (user == null) return;

      final firstName = (user['firstName'] ?? user['first_name'])?.toString();
      final lastName = (user['lastName'] ?? user['last_name'])?.toString();
      final balance = user['walletBalance'] ?? user['wallet_balance'];

      setState(() {
        _fullName = _composeName(firstName, lastName, user);
        _email = user['email']?.toString();
        _phone = user['phone']?.toString();
        _profileImagePath = user['profileImageUrl']?.toString();
        _walletBalance = balance?.toString();
      });
    } catch (_) {
      _showMessage('Could not load profile. Please try again.', isError: true);
    } finally {
      if (mounted) {
        setState(() => _loadingProfile = false);
      }
    }
  }

  String _composeName(
    String? firstName,
    String? lastName,
    Map<String, dynamic> user,
  ) {
    final trimmedFirst = firstName?.trim();
    final trimmedLast = lastName?.trim();
    final combined = [trimmedFirst, trimmedLast]
        .whereType<String>()
        .where((part) => part.isNotEmpty)
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

  void _showImageOptions() {
    if (_loadingProfile) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 12),
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _handleImageSelection(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _handleImageSelection(ImageSource.gallery);
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleImageSelection(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source, imageQuality: 80);
      if (picked == null) return;
      await _uploadProfileImage(File(picked.path));
    } on PlatformException {
      _showMessage(
        'Permission denied. Please enable camera/gallery access.',
        isError: true,
      );
    }
  }

  Future<void> _uploadProfileImage(File file) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt');
    if (token == null) {
      _showMessage('Please log in again to update your photo.', isError: true);
      return;
    }
    setState(() {
      _uploadingPhoto = true;
    });
    try {
      final result = await uploadProfilePhoto(token: token, photo: file);
      if (!mounted) return;
      if (result['error'] != null) {
        _showMessage(result['error'].toString(), isError: true);
        return;
      }
      final newPath = result['profileImageUrl']?.toString();
      setState(() {
        _profileImagePath = newPath;
      });
      _showMessage('Profile photo updated');
    } catch (e) {
      _showMessage('Failed to upload photo. Please try again.', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _uploadingPhoto = false;
        });
      }
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).colorScheme.primary,
      ),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
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
            child: _loadingProfile
                ? const Center(child: CircularProgressIndicator())
                : _buildProfileContent(isTablet),
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
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 32 : 20,
          vertical: isTablet ? 20 : 16,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
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
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.arrow_back,
                  color: Theme.of(context).colorScheme.onSurface,
                  size: isTablet ? 24 : 20,
                ),
              ),
            ),
            SizedBox(width: isTablet ? 16 : 12),
            Icon(
              Icons.person,
              color: Theme.of(context).colorScheme.primary,
              size: isTablet ? 28 : 24,
            ),
            SizedBox(width: isTablet ? 12 : 8),
            Text(
              'My Profile',
              style: TextStyle(
                fontSize: isTablet ? 24 : 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const Spacer(),
            IconButton(
              tooltip: 'Refresh profile',
              onPressed: _loadProfile,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileContent(bool isTablet) {
    return SlideTransition(
      position: _slideAnimation,
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 32 : 20,
          vertical: isTablet ? 24 : 20,
        ),
        child: Column(
          children: [
            _buildProfilePicture(isTablet),
            SizedBox(height: isTablet ? 32 : 24),
            _buildIdentityCard(isTablet),
            SizedBox(height: isTablet ? 32 : 24),
            _buildContactCard(isTablet),
            SizedBox(height: isTablet ? 32 : 24),
            _buildAccountCard(isTablet),
          ],
        ),
      ),
    );
  }

  Widget _buildProfilePicture(bool isTablet) {
    final resolvedImage = _resolveProfileImageUrl(_profileImagePath);
    final placeholderColor =
        Theme.of(context).colorScheme.surfaceContainerHighest;
    return Center(
      child: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: isTablet ? 150 : 130,
            height: isTablet ? 150 : 130,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).colorScheme.primary,
                width: 4,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipOval(
              child: resolvedImage != null
                  ? Image.network(resolvedImage, fit: BoxFit.cover)
                  : Container(
                      color: placeholderColor,
                      child: Icon(
                        Icons.person,
                        size: isTablet ? 72 : 60,
                        color: Colors.grey.shade500,
                      ),
                    ),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _uploadingPhoto ? null : _showImageOptions,
              child: Container(
                padding: EdgeInsets.all(isTablet ? 12 : 10),
                decoration: BoxDecoration(
                  color: _uploadingPhoto
                      ? Colors.grey
                      : Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: _uploadingPhoto
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.camera_alt,
                        color: Colors.white, size: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdentityCard(bool isTablet) {
    return _InfoCard(
      title: 'Identity',
      isTablet: isTablet,
      children: [
        _InfoRow(label: 'Full Name', value: _fullName ?? 'Unknown user'),
      ],
    );
  }

  Widget _buildContactCard(bool isTablet) {
    return _InfoCard(
      title: 'Contact',
      isTablet: isTablet,
      children: [
        _InfoRow(label: 'Email', value: _email ?? 'Not provided'),
        _InfoRow(label: 'Phone', value: _phone ?? 'Not provided'),
      ],
    );
  }

  Widget _buildAccountCard(bool isTablet) {
    return _InfoCard(
      title: 'Account',
      isTablet: isTablet,
      children: [
        _InfoRow(
          label: 'Wallet Balance',
          valueWidget: WalletVisibilityBuilder(
            builder: (context, showBalance) {
              final colorScheme = Theme.of(context).colorScheme;
              final hasBalance = _walletBalance != null;
              final visibleValue =
                  hasBalance ? '₦$_walletBalance' : 'Unavailable';
              final displayValue = showBalance
                  ? visibleValue
                  : hasBalance
                      ? '*************'
                      : 'Unavailable';
              return Text(
                displayValue,
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.children,
    required this.isTablet,
  });

  final String title;
  final List<_InfoRow> children;
  final bool isTablet;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isTablet ? 24 : 18),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: isTablet ? 18 : 16,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    this.value,
    this.valueWidget,
  }) : assert(value != null || valueWidget != null);

  final String label;
  final String? value;
  final Widget? valueWidget;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: valueWidget != null
                ? Align(alignment: Alignment.centerRight, child: valueWidget!)
                : Text(
                    value ?? '',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}


