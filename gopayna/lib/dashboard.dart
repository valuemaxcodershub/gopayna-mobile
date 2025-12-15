import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login.dart';
import 'dart:convert';
import 'setting.dart';
import 'referral_screen.dart';
import 'all_transactions_history.dart';
import 'support.dart';
import 'fund_wallet.dart';
// import 'withdraw_fund.dart'; // TODO: Re-enable when withdrawal feature is ready
import 'buy_airtime.dart';
import 'buy_data.dart';
import 'buy_electricity.dart';
import 'buy_tv_subscription.dart';
import 'buy_exam_pin.dart';
import 'notification.dart';
import 'dart:developer';
import 'api_service.dart';
import 'idle_timeout_service.dart';
import 'app_settings.dart';
import 'widgets/transaction_receipt.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  String? _userName;
  double? _walletBalance;
  String? _userProfileImageUrl;
  late final AppSettings _appSettings;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late AnimationController _balanceController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _balanceAnimation;

  bool _balanceVisible = false;
  int _selectedTab = 0;
  bool _transactionsLoading = false;
  String? _transactionsError;
  final DateFormat _transactionDateFormat = DateFormat('MMM d, yyyy • h:mma');
  List<Transaction> _transactions = [];
  DateTime? _lastActivity;
  int _unreadNotificationCount = 0;

  @override
  void initState() {
    super.initState();
    _appSettings = AppSettings();
    _balanceVisible = _appSettings.showWalletBalance;
    _initializeAnimations();
    _balanceController.value = _balanceVisible ? 1 : 0;
    _appSettings.addListener(_handleWalletVisibilityChanged);
    _startAnimations();
    _checkAuthentication();
  }

  void _updateActivity() {
    final now = DateTime.now();
    final previous = _lastActivity;
    if (previous == null || now.difference(previous).inSeconds >= 30) {
      log(
        'User activity detected after ${previous == null ? 'app launch' : '${now.difference(previous).inSeconds}s idle'}',
        name: '_DashboardScreenState',
      );
    }
    _lastActivity = now;
  }

  void _handleWalletVisibilityChanged() {
    if (!mounted) return;
    final shouldShow = _appSettings.showWalletBalance;
    if (_balanceVisible == shouldShow) {
      return;
    }
    setState(() {
      _balanceVisible = shouldShow;
    });
    if (shouldShow) {
      if (!_balanceController.isAnimating) {
        _balanceController.forward();
      }
    } else {
      if (!_balanceController.isAnimating) {
        _balanceController.reverse();
      }
    }
  }

  // Removed lifecycle observer method

  Future<void> _checkAuthentication() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt');
    if (token == null || token.isEmpty) {
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } else {
      _loadUserInfo(token);
      _refreshWalletBalance(token: token);
      _loadRecentTransactions(token: token);
      _fetchUnreadNotificationCount(token: token);
      // Reset activity time on login
      // _lastActivity = DateTime.now();
    }
  }

  Future<void> _loadRecentTransactions({String? token}) async {
    token ??= (await SharedPreferences.getInstance()).getString('jwt');
    if (token == null || token.isEmpty) return;
    if (!mounted) return;
    setState(() {
      _transactionsLoading = true;
      _transactionsError = null;
    });

    final response = await fetchWalletTransactions(token: token, limit: 20);
    if (!mounted) return;

    if (response['error'] != null) {
      setState(() {
        _transactionsError = response['error'].toString();
        _transactionsLoading = false;
      });
      return;
    }

    final dataRaw = response['data'] as List<dynamic>? ?? [];
    final parsed = dataRaw
        .cast<Map<String, dynamic>>()
        .map((tx) => Transaction.fromApi(tx, _transactionDateFormat))
        .where((tx) => tx.isDisplayable)
        .take(8)
        .toList();

    setState(() {
      _transactions = parsed;
      _transactionsLoading = false;
    });
  }

  Future<void> _refreshWalletBalance({String? token}) async {
    token ??= (await SharedPreferences.getInstance()).getString('jwt');
    if (token == null || token.isEmpty) return;
    final balance = await fetchWalletBalance(token);
    if (!mounted) return;
    setState(() {
      _walletBalance = balance;
    });
  }

  Future<void> _fetchUnreadNotificationCount({String? token}) async {
    token ??= (await SharedPreferences.getInstance()).getString('jwt');
    if (token == null || token.isEmpty) return;
    final result = await getUnreadNotificationCount(token);
    if (!mounted) return;
    if (result.containsKey('success') && result['success'] == true) {
      setState(() {
        _unreadNotificationCount = result['unreadCount'] ?? 0;
      });
    }
  }

  Future<void> _loadUserInfo(String token) async {
    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        throw const FormatException('Invalid token format');
      }

      final payload =
          utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      final data = json.decode(payload);

      // Accept tokens with id, email, phone (from backend)
      if (data is! Map) {
        throw const FormatException('Invalid token payload');
      }

      final name = _deriveDisplayName(data);

      double? walletBalance;
      if (data.containsKey('wallet_balance')) {
        walletBalance = double.tryParse(data['wallet_balance'].toString());
      }
      setState(() {
        _userName = name;
        _walletBalance = walletBalance ?? _walletBalance;
      });

      // Fetch profile to get profile image
      await _loadProfileImage(token);
    } catch (e) {
      log('Failed to load user info: $e', name: '_DashboardScreenState');
      setState(() {
        _userName = null; // Reset user name on error
      });
    }
  }

  Future<void> _loadProfileImage(String token) async {
    try {
      final result = await fetchUserProfile(token);
      if (!mounted) return;
      if (result['error'] != null) {
        log('Profile fetch error: ${result['error']}',
            name: '_DashboardScreenState');
        return;
      }
      final user = result['user'] as Map<String, dynamic>?;
      if (user == null) return;
      final imageUrl = user['profileImageUrl']?.toString();
      setState(() {
        _userProfileImageUrl = _resolveProfileImageUrl(imageUrl);
      });
    } catch (e) {
      log('Failed to load profile image: $e', name: '_DashboardScreenState');
    }
  }

  String? _resolveProfileImageUrl(String? relativePath) {
    if (relativePath == null || relativePath.isEmpty) return null;
    if (relativePath.startsWith('http')) return relativePath;
    return '$apiOrigin$relativePath';
  }

  String _deriveDisplayName(Map<dynamic, dynamic> data) {
    String? sanitize(dynamic value) {
      if (value == null) return null;
      final text = value.toString().trim();
      return text.isEmpty ? null : text;
    }

    final candidates = [
      sanitize(data['firstName']),
      sanitize(data['first_name']),
      sanitize(data['lastName']),
      sanitize(data['last_name']),
    ];

    for (final candidate in candidates) {
      if (candidate != null) return candidate;
    }

    final email = sanitize(data['email']);
    if (email != null && email.contains('@')) {
      return email.split('@').first;
    }

    final phone = sanitize(data['phone']);
    if (phone != null) return phone;

    final idValue = sanitize(data['id']);
    if (idValue != null) {
      return 'User $idValue';
    }

    return 'there';
  }

  Future<void> _logout() async {
    // Stop idle timeout tracking
    IdleTimeoutService().dispose();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt');
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(redirectToIntroOnExit: true),
      ),
      (route) => false,
    );
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _balanceController = AnimationController(
      duration: const Duration(milliseconds: 300),
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
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );
    _balanceAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _balanceController, curve: Curves.easeInOut),
    );
  }

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (mounted && !_fadeController.isAnimating) {
      _fadeController.forward();
    }
    await Future.delayed(const Duration(milliseconds: 200));
    if (mounted && !_slideController.isAnimating) {
      _slideController.forward();
    }
    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted && !_scaleController.isAnimating) {
      _scaleController.forward();
    }
  }

  void _toggleBalance() {
    final nextValue = !_appSettings.showWalletBalance;
    _appSettings.toggleWalletBalance(nextValue);
    HapticFeedback.lightImpact();
  }

  @override
  void dispose() {
    _appSettings.removeListener(_handleWalletVisibilityChanged);
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Listen for user activity
    return GestureDetector(
      onTap: _updateActivity,
      onPanDown: (_) => _updateActivity(),
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: colorScheme.primary,
          elevation: 0,
          title: Row(
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingScreen(),
                    ),
                  );
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: colorScheme.onPrimary.withValues(alpha: 0.35),
                      width: 2,
                    ),
                    color: colorScheme.onPrimary.withValues(alpha: 0.18),
                  ),
                  child: _userProfileImageUrl != null
                      ? ClipOval(
                          child: Image.network(
                            _userProfileImageUrl!,
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.person,
                              color: colorScheme.onPrimary,
                              size: 22,
                            ),
                          ),
                        )
                      : Icon(
                          Icons.person,
                          color: colorScheme.onPrimary,
                          size: 22,
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  (_userName != null && _userName!.isNotEmpty)
                      ? 'Hello, ${_userName!.split(' ').first}'
                      : 'Hello',
                  style: TextStyle(
                    color: colorScheme.onPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Stack(
                children: [
                  IconButton(
                    icon: Icon(Icons.notifications_outlined,
                        color: colorScheme.onPrimary),
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationScreen(),
                        ),
                      );
                      // Refresh notification count after returning from notifications
                      _fetchUnreadNotificationCount();
                    },
                    tooltip: 'Notifications',
                  ),
                  if (_unreadNotificationCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          _unreadNotificationCount > 99
                              ? '99+'
                              : '$_unreadNotificationCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                icon: Icon(Icons.logout, color: colorScheme.onPrimary),
                onPressed: _logout,
                tooltip: 'Logout',
              ),
            ),
          ],
          systemOverlayStyle: SystemUiOverlayStyle.light,
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SingleChildScrollView(
          child: Column(
            children: [
              // ...existing code...
              _buildCustomStatusBar(statusBarHeight, isTablet),
              _buildBalanceCard(isTablet),
              _buildServiceGrid(isTablet),
              _buildTransactionHistory(isTablet),
            ],
          ),
        ),
        bottomNavigationBar: _buildBottomNavigation(isTablet),
      ),
    );
  }

  Widget _buildCustomStatusBar(double statusBarHeight, bool isTablet) {
    return SizedBox(
      height: statusBarHeight,
    );
  }

  Widget _buildBalanceCard(bool isTablet) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: isTablet ? 32 : 20,
          vertical: isTablet ? 16 : 12,
        ),
        padding: EdgeInsets.all(isTablet ? 24 : 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colorScheme.primary,
              colorScheme.secondary,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
          boxShadow: [
            BoxShadow(
              color:
                  colorScheme.primary.withValues(alpha: isDark ? 0.45 : 0.25),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.account_balance_wallet,
                  color: colorScheme.onPrimary,
                  size: isTablet ? 24 : 20,
                ),
                SizedBox(width: isTablet ? 12 : 8),
                Text(
                  'Available Balance',
                  style: TextStyle(
                    color: colorScheme.onPrimary,
                    fontSize: isTablet ? 16 : 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: _toggleBalance,
                  child: Icon(
                    _balanceVisible ? Icons.visibility_off : Icons.visibility,
                    color: colorScheme.onPrimary,
                    size: isTablet ? 24 : 20,
                  ),
                ),
                SizedBox(width: isTablet ? 12 : 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const TransactionHistoryScreen(),
                        ),
                      );
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Flexible(
                          child: Text(
                            'Transaction History',
                            style: TextStyle(
                              color: colorScheme.onPrimary,
                              fontSize: isTablet ? 12 : 9,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: isTablet ? 6 : 2),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: colorScheme.onPrimary,
                          size: isTablet ? 14 : 10,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: isTablet ? 20 : 16),
            AnimatedBuilder(
              animation: _balanceAnimation,
              builder: (context, child) {
                return Row(
                  children: [
                    Expanded(
                      child: Text(
                        _balanceVisible
                            ? (_walletBalance != null
                                ? '₦${_walletBalance!.toStringAsFixed(2)}'
                                : '₦0.00')
                            : '*************',
                        style: TextStyle(
                          color: colorScheme.onPrimary,
                          fontSize: _balanceVisible
                              ? (isTablet ? 32 : 28)
                              : (isTablet ? 20 : 18),
                          fontWeight: FontWeight.bold,
                          letterSpacing: _balanceVisible ? 1 : 2,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const FundWalletScreen(),
                          ),
                        );
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isTablet ? 20 : 16,
                          vertical: isTablet ? 12 : 10,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.onPrimary.withValues(alpha: 0.2),
                          borderRadius:
                              BorderRadius.circular(isTablet ? 25 : 20),
                          border: Border.all(
                            color:
                                colorScheme.onPrimary.withValues(alpha: 0.35),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.add,
                              color: colorScheme.onPrimary,
                              size: isTablet ? 20 : 16,
                            ),
                            SizedBox(width: isTablet ? 8 : 4),
                            Text(
                              'Add Money',
                              style: TextStyle(
                                color: colorScheme.onPrimary,
                                fontSize: isTablet ? 14 : 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceGrid(bool isTablet) {
    final services = [
      ServiceItem(
          icon: Icons.credit_card,
          title: 'Data',
          color: const Color(0xFF00CA44)),
      ServiceItem(
          icon: Icons.airplanemode_active,
          title: 'Airtime',
          color: const Color(0xFF00CA44)),
      ServiceItem(
          icon: Icons.electrical_services,
          title: 'Electricity',
          color: const Color(0xFF00CA44)),
      ServiceItem(icon: Icons.tv, title: 'TV', color: const Color(0xFF00CA44)),
      ServiceItem(
          icon: Icons.school,
          title: 'Exam Pin',
          color: const Color(0xFF00CA44)),
      ServiceItem(
          icon: Icons.money, title: 'Betting', color: const Color(0xFF00CA44)),
    ];

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: isTablet ? 32 : 20,
          vertical: isTablet ? 16 : 12,
        ),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: isTablet ? 1.3 : 1.1,
            crossAxisSpacing: isTablet ? 16 : 10,
            mainAxisSpacing: isTablet ? 16 : 10,
          ),
          itemCount: services.length,
          itemBuilder: (context, index) {
            return _buildServiceCard(services[index], isTablet, index);
          },
        ),
      ),
    );
  }

  Widget _buildServiceCard(ServiceItem service, bool isTablet, int index) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedContainer(
        duration: Duration(milliseconds: 200 + (index * 50)),
        curve: Curves.easeOutCubic,
        child: GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            if (service.title == 'Betting') {
              // Withdrawal functionality temporarily disabled
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Betting feature coming soon!'),
                  backgroundColor: colorScheme.primary,
                  behavior: SnackBarBehavior.floating,
                ),
              );
              // TODO: Re-enable when ready
              // Navigator.push(
              //   context,
              //   MaterialPageRoute(
              //     builder: (context) => const WithdrawFundScreen(),
              //   ),
              // );
            } else if (service.title == 'Airtime') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BuyAirtimeScreen(),
                ),
              );
            } else if (service.title == 'Data') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BuyDataScreen(),
                ),
              );
            } else if (service.title == 'Electricity') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BuyElectricityScreen(),
                ),
              );
            } else if (service.title == 'TV') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BuyTVSubscriptionScreen(),
                ),
              );
            } else if (service.title == 'Exam Pin') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BuyEducationPinScreen(),
                ),
              );
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.06),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(isTablet ? 14 : 10),
                  decoration: BoxDecoration(
                    color: service.color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    service.icon,
                    color: service.color,
                    size: isTablet ? 26 : 20,
                  ),
                ),
                SizedBox(height: isTablet ? 10 : 6),
                Flexible(
                  child: Text(
                    service.title,
                    style: TextStyle(
                      fontSize: isTablet ? 14 : 12,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ));
  }

  Widget _buildTransactionHistory(bool isTablet) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: EdgeInsets.only(
          left: isTablet ? 32 : 20,
          right: isTablet ? 32 : 20,
          top: isTablet ? 24 : 20,
        ),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(isTablet ? 24 : 20),
            topRight: Radius.circular(isTablet ? 24 : 20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.08),
              blurRadius: 18,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(isTablet ? 24 : 20),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Recent Transactions',
                      style: TextStyle(
                        fontSize: isTablet ? 20 : 18,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: _transactionsLoading
                        ? null
                        : () => _loadRecentTransactions(),
                    icon: Icon(
                      Icons.refresh,
                      color: _transactionsLoading
                          ? colorScheme.onSurface.withValues(alpha: 0.3)
                          : colorScheme.primary,
                      size: isTablet ? 22 : 20,
                    ),
                    tooltip: 'Refresh transactions',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const TransactionHistoryScreen(),
                        ),
                      );
                    },
                    child: Text(
                      'See all',
                      style: TextStyle(
                        fontSize: isTablet ? 16 : 14,
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: isTablet ? 260 : 180, // Fixed height for transaction list
              child: _transactionsLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _transactionsError != null
                      ? _buildTransactionErrorState(isTablet)
                      : _transactions.isEmpty
                          ? _buildTransactionEmptyState(isTablet)
                          : ListView.builder(
                              padding: EdgeInsets.only(
                                left: isTablet ? 24 : 20,
                                right: isTablet ? 24 : 20,
                                bottom: isTablet ? 100 : 80,
                              ),
                              itemCount: _transactions.length,
                              itemBuilder: (context, index) {
                                final transaction = _transactions[index];
                                return _buildTransactionItem(
                                    transaction, isTablet, index);
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionEmptyState(bool isTablet) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Text(
        'No recent transactions yet.',
        style: TextStyle(
          color: colorScheme.onSurface.withValues(alpha: 0.6),
          fontSize: isTablet ? 16 : 14,
        ),
      ),
    );
  }

  Widget _buildTransactionErrorState(bool isTablet) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _transactionsError ?? 'Unable to load transactions',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colorScheme.error,
              fontSize: isTablet ? 16 : 14,
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed:
                _transactionsLoading ? null : () => _loadRecentTransactions(),
            child: const Text('Try again'),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(
      Transaction transaction, bool isTablet, int index) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final statusColor = transaction.statusKey == 'success'
        ? colorScheme.primary
        : transaction.statusKey == 'failed'
            ? colorScheme.error
            : transaction.statusColor;
    final tileColor = isDark
        ? colorScheme.surfaceContainerHighest
        : colorScheme.surfaceContainerLow;
    return AnimatedContainer(
      duration: Duration(milliseconds: 300 + (index * 100)),
      curve: Curves.easeOutCubic,
      margin: EdgeInsets.only(bottom: isTablet ? 16 : 12),
      child: GestureDetector(
        onTap: () => showTransactionReceipt(
          context: context,
          data: transaction.toReceiptData(_transactionDateFormat),
        ),
        child: Container(
          padding: EdgeInsets.all(isTablet ? 16 : 12),
          decoration: BoxDecoration(
            color: tileColor,
            borderRadius: BorderRadius.circular(isTablet ? 12 : 8),
            border: Border.all(
              color: colorScheme.outlineVariant,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(isTablet ? 12 : 8),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  transaction.isIncoming
                      ? Icons.arrow_downward
                      : Icons.arrow_upward,
                  color: colorScheme.onPrimary,
                  size: isTablet ? 20 : 16,
                ),
              ),
              SizedBox(width: isTablet ? 16 : 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.title,
                      style: TextStyle(
                        fontSize: isTablet ? 16 : 14,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: isTablet ? 6 : 4),
                    Text(
                      transaction.date,
                      style: TextStyle(
                        fontSize: isTablet ? 14 : 12,
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₦${transaction.amount.abs().toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: isTablet ? 16 : 14,
                      fontWeight: FontWeight.bold,
                      color: transaction.isIncoming
                          ? colorScheme.primary
                          : colorScheme.error,
                    ),
                  ),
                  SizedBox(height: isTablet ? 6 : 4),
                  Text(
                    transaction.status,
                    style: TextStyle(
                      fontSize: isTablet ? 12 : 10,
                      color: statusColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigation(bool isTablet) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: isTablet ? 90 : 80,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(isTablet ? 24 : 20),
          topRight: Radius.circular(isTablet ? 24 : 20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
            blurRadius: 18,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(Icons.home, 'Home', 0, isTablet),
            _buildNavItem(Icons.headset_mic, 'Help', 1, isTablet),
            _buildNavItem(Icons.people, 'Reffer', 2, isTablet),
            _buildNavItem(Icons.settings, 'Settings', 3, isTablet),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index, bool isTablet) {
    final isSelected = _selectedTab == index;
    final colorScheme = Theme.of(context).colorScheme;
    final unselectedColor = colorScheme.onSurface.withValues(alpha: 0.55);
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = index;
        });
        HapticFeedback.lightImpact();

        // Navigate to Settings screen when Settings tab is tapped
        if (index == 3 && label == 'Settings') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SettingScreen(),
            ),
          );
        }

        // Navigate to Referrer page when Reffer tab is tapped
        if (index == 2 && label == 'Reffer') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ReferrerPage(),
            ),
          );
        }

        // Navigate to Support page when Help tab is tapped
        if (index == 1 && label == 'Help') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SupportScreen(),
            ),
          );
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          vertical: isTablet ? 12 : 8,
          horizontal: isTablet ? 16 : 12,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? colorScheme.primary : unselectedColor,
              size: isTablet ? 28 : 24,
            ),
            SizedBox(height: isTablet ? 6 : 4),
            Text(
              label,
              style: TextStyle(
                fontSize: isTablet ? 14 : 12,
                color: isSelected ? colorScheme.primary : unselectedColor,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ServiceItem {
  final IconData icon;
  final String title;
  final Color color;

  ServiceItem({
    required this.icon,
    required this.title,
    required this.color,
  });
}

class Transaction {
  final String title;
  final double amount;
  final String date;
  final String status;
  final bool isIncoming;
  final String statusKey;
  final String channel;
  final String reference;
  final IconData icon;
  final DateTime? createdAt;
  final Map<String, dynamic>? metadata;

  Transaction({
    required this.title,
    required this.amount,
    required this.date,
    required this.status,
    required this.isIncoming,
    required this.statusKey,
    required this.channel,
    required this.reference,
    required this.icon,
    required this.createdAt,
    this.metadata,
  });

  factory Transaction.fromApi(Map<String, dynamic> data, DateFormat formatter) {
    final rawStatus = (data['status'] ?? 'pending').toString();
    final createdAt =
        DateTime.tryParse(data['created_at']?.toString() ?? '')?.toLocal();
    final rawAmount = double.tryParse(data['amount']?.toString() ?? '') ?? 0;
    final direction =
        (data['type'] ?? data['transaction_type'] ?? data['direction'] ?? '')
            .toString()
            .toLowerCase();
    final isIncoming =
        direction.isNotEmpty ? direction != 'debit' : rawAmount >= 0;

    // Parse metadata - handle both string and map types
    Map<String, dynamic>? metadata;
    final rawMetadata = data['metadata'];
    if (rawMetadata is Map<String, dynamic>) {
      metadata = rawMetadata;
    } else if (rawMetadata is String && rawMetadata.isNotEmpty) {
      try {
        metadata = _parseJsonSafely(rawMetadata);
      } catch (_) {
        metadata = null;
      }
    }

    // Get service type and build title from metadata
    final serviceType = metadata?['serviceType']?.toString() ?? '';
    final metadataDesc = metadata?['description']?.toString() ?? '';
    final metadataChannel = metadata?['channel']?.toString() ?? '';

    final channel =
        (data['channel'] ?? serviceType ?? metadataChannel ?? 'wallet')
            .toString()
            .trim();
    final reference = (data['reference'] ?? '').toString();

    // Build a better title based on service type
    String title;
    
    // Check if this is a wallet funding (credit) transaction
    if (isIncoming && (channel == 'card' || channel == 'paystack' || channel == 'bank' || channel == 'transfer')) {
      title = 'Wallet Funding';
    } else if (serviceType == 'airtime') {
      title = 'Airtime Purchase';
    } else if (serviceType == 'data') {
      title = 'Data Purchase';
    } else if (serviceType == 'electricity') {
      title = 'Electricity Purchase';
    } else if (serviceType == 'tv') {
      title = 'TV Subscription';
    } else if (serviceType == 'education') {
      title = 'Education PIN';
    } else if (serviceType == 'refund') {
      title = 'Refund';
    } else if (channel.isNotEmpty && channel != 'wallet' && channel != 'vtu') {
      title = _titleCase(channel);
    } else if (metadataDesc.isNotEmpty) {
      if (metadataDesc.toLowerCase().contains('airtime')) {
        title = 'Airtime Purchase';
      } else if (metadataDesc.toLowerCase().contains('data')) {
        title = 'Data Purchase';
      } else if (metadataDesc.toLowerCase().contains('electric')) {
        title = 'Electricity Purchase';
      } else if (metadataDesc.toLowerCase().contains('tv')) {
        title = 'TV Subscription';
      } else if (metadataDesc.toLowerCase().contains('education') ||
          metadataDesc.toLowerCase().contains('waec') ||
          metadataDesc.toLowerCase().contains('jamb')) {
        title = 'Education PIN';
      } else {
        title = 'Wallet Transaction';
      }
    } else {
      title = channel.isEmpty ? 'Wallet Transaction' : _titleCase(channel);
    }

    final formattedDate =
        createdAt != null ? formatter.format(createdAt) : '--';

    return Transaction(
      title: title,
      amount: rawAmount.abs(),
      date: formattedDate,
      status: _formatStatus(rawStatus),
      isIncoming: isIncoming,
      statusKey: rawStatus.toLowerCase(),
      channel: serviceType.isNotEmpty ? serviceType : channel,
      reference: reference,
      icon: _iconForChannel(serviceType.isNotEmpty ? serviceType : channel),
      createdAt: createdAt,
      metadata: metadata,
    );
  }

  static Map<String, dynamic>? _parseJsonSafely(String jsonStr) {
    try {
      final result = <String, dynamic>{};
      String content = jsonStr;
      // Handle double-encoded JSON
      if (content.startsWith('"') && content.endsWith('"')) {
        content = content
            .substring(1, content.length - 1)
            .replaceAll(r'\"', '"')
            .replaceAll(r'\\', r'\');
      }
      if (!content.startsWith('{')) return null;
      content = content.substring(1, content.length - 1);
      final regex = RegExp(r'"([^"]+)"\s*:\s*("([^"]*)"|([^,}]+))');
      for (final match in regex.allMatches(content)) {
        final key = match.group(1) ?? '';
        var value = match.group(3) ?? match.group(4) ?? '';
        value = value.trim();
        if (value == 'null') {
          result[key] = null;
        } else if (value == 'true') {
          result[key] = true;
        } else if (value == 'false') {
          result[key] = false;
        } else if (double.tryParse(value) != null) {
          result[key] = double.parse(value);
        } else {
          result[key] = value;
        }
      }
      return result.isEmpty ? null : result;
    } catch (_) {
      return null;
    }
  }

  bool get isDisplayable => statusKey == 'success' || statusKey == 'failed';

  Color get statusColor {
    switch (statusKey) {
      case 'success':
        return const Color(0xFF00CA44);
      case 'failed':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  TransactionReceiptData toReceiptData(DateFormat formatter) {
    final amountPrefix = isIncoming ? '+' : '-';
    final computedDate =
        createdAt != null ? formatter.format(createdAt!) : date;

    // Build extra details from metadata
    final List<ReceiptField> extraDetails = [];

    if (metadata != null) {
      final serviceType = metadata!['serviceType']?.toString() ?? '';

      // Add network for airtime/data
      final network = metadata!['network']?.toString();
      if (network != null && network.isNotEmpty) {
        extraDetails.add(ReceiptField(label: 'Network', value: network));
      }

      // Add phone number
      final phone = metadata!['phone']?.toString();
      if (phone != null && phone.isNotEmpty) {
        extraDetails.add(ReceiptField(label: 'Phone Number', value: phone));
      }

      // Add airtime value if different from amount (for discounted purchases)
      final airtimeValue = metadata!['airtimeValue'];
      if (airtimeValue != null && serviceType == 'airtime') {
        extraDetails.add(ReceiptField(
            label: 'Airtime Value', value: '₦${airtimeValue.toString()}'));
      }

      // Add discount if applicable
      final discount = metadata!['discount'];
      if (discount != null && discount > 0) {
        extraDetails.add(ReceiptField(label: 'Discount', value: '$discount%'));
      }

      // Add plan ID for data
      final planId = metadata!['planId']?.toString();
      if (planId != null && planId.isNotEmpty && serviceType == 'data') {
        extraDetails.add(ReceiptField(label: 'Plan ID', value: planId));
      }

      // Add disco and meter for electricity
      final disco = metadata!['disco']?.toString();
      if (disco != null && disco.isNotEmpty) {
        extraDetails.add(ReceiptField(label: 'Disco', value: disco));
      }

      final meterNumber = metadata!['meterNumber']?.toString();
      if (meterNumber != null && meterNumber.isNotEmpty) {
        extraDetails
            .add(ReceiptField(label: 'Meter Number', value: meterNumber));
      }

      // Add electricity amount and service charge
      final electricityAmount = metadata!['electricityAmount'];
      if (electricityAmount != null) {
        extraDetails.add(ReceiptField(
            label: 'Electricity Amount',
            value: '₦${electricityAmount.toString()}'));
      }

      final serviceCharge = metadata!['serviceCharge'];
      if (serviceCharge != null && serviceCharge > 0) {
        extraDetails.add(ReceiptField(
            label: 'Service Charge', value: '₦${serviceCharge.toString()}'));
      }

      // Add provider and smartcard for TV
      final provider = metadata!['provider']?.toString();
      if (provider != null && provider.isNotEmpty && serviceType == 'tv') {
        extraDetails.add(ReceiptField(label: 'Provider', value: provider));
      }

      final smartcardNumber = metadata!['smartcardNumber']?.toString();
      if (smartcardNumber != null && smartcardNumber.isNotEmpty) {
        extraDetails.add(
            ReceiptField(label: 'Smartcard Number', value: smartcardNumber));
      }

      // Add exam details for education
      final examType = metadata!['examType']?.toString();
      if (examType != null && examType.isNotEmpty) {
        extraDetails.add(ReceiptField(label: 'Exam Type', value: examType));
      }

      final examCode = metadata!['examCode']?.toString();
      if (examCode != null && examCode.isNotEmpty) {
        extraDetails.add(ReceiptField(label: 'Exam Code', value: examCode));
      }
    }

    return TransactionReceiptData(
      title: title,
      amountDisplay: '$amountPrefix₦${amount.toStringAsFixed(2)}',
      isCredit: isIncoming,
      statusLabel: status,
      statusColor: statusColor,
      dateLabel: computedDate,
      channel: _titleCase(channel),
      reference: reference,
      icon: icon,
      extraDetails: extraDetails,
    );
  }

  static String _titleCase(String value) {
    if (value.isEmpty) return value;
    return value
        .split(' ')
        .where((word) => word.isNotEmpty)
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }

  static String _formatStatus(String status) {
    switch (status.toLowerCase()) {
      case 'success':
        return 'Successful';
      case 'failed':
        return 'Failed';
      default:
        return status.isEmpty
            ? 'Pending'
            : status[0].toUpperCase() + status.substring(1).toLowerCase();
    }
  }

  static IconData _iconForChannel(String channel) {
    final value = channel.toLowerCase();
    if (value.contains('airtime')) return Icons.phone;
    if (value.contains('data')) return Icons.wifi;
    if (value.contains('electric')) return Icons.electrical_services;
    if (value.contains('tv')) return Icons.tv;
    if (value.contains('education')) return Icons.school;
    if (value.contains('wallet')) return Icons.account_balance_wallet;
    return Icons.swap_horiz;
  }
}
