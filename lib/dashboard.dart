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
    with TickerProviderStateMixin, WidgetsBindingObserver {
  String? _userName;
  double? _walletBalance;
  String? _userProfileImageUrl;
  late final AppSettings _appSettings;

  late AnimationController _slideController;
  late AnimationController _scaleController;
  late AnimationController _balanceController;

  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _balanceAnimation;

  bool _balanceVisible = false;
  int _selectedTab = 0;
  
  List<Transaction> _recentTransactions = [];
  bool _transactionsLoading = false;

  DateTime? _lastActivity;
  int _unreadNotificationCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _appSettings = AppSettings();
    _balanceVisible = _appSettings.showWalletBalance;
    _initializeAnimations();
    _balanceController.value = _balanceVisible ? 1 : 0;
    _appSettings.addListener(_handleWalletVisibilityChanged);
    _startAnimations();
    _checkAuthentication();
    _loadRecentTransactions();
  }

  Future<void> _loadRecentTransactions() async {
    if (!mounted) return;
    setState(() {
      _transactionsLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt');
      if (token == null || token.isEmpty) return;

      final response = await fetchWalletTransactions(token: token, limit: 7);
      if (!mounted) return;

      if (response['error'] == null) {
        final dataRaw = response['data'] as List<dynamic>? ?? [];
        final DateFormat formatter = DateFormat('MMM d, yyyy • h:mma');
        final parsed = dataRaw
            .cast<Map<String, dynamic>>()
            .map((tx) => Transaction.fromApi(tx, formatter))
            .where((tx) => tx.isDisplayable)
            .take(7)
            .toList();

        setState(() {
          _recentTransactions = parsed;
        });
      }
    } catch (e) {
      log('Error loading recent transactions: $e', name: '_DashboardScreenState');
    } finally {
      if (mounted) {
        setState(() {
          _transactionsLoading = false;
        });
      }
    }
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

  // Format currency with thousands separator
  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,##0.00');
    return '₦${formatter.format(amount)}';
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
      _fetchUnreadNotificationCount(token: token);
      // Reset activity time on login
      // _lastActivity = DateTime.now();
    }
  }


  Future<void> _refreshWalletBalance({String? token}) async {
    token ??= (await SharedPreferences.getInstance()).getString('jwt');
    if (token == null || token.isEmpty) return;
    final balance = await fetchWalletBalance(token);
    if (!mounted) return;
    setState(() {
      _walletBalance = balance;
    });
    // Also refresh recent transactions
    _loadRecentTransactions();
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
    WidgetsBinding.instance.removeObserver(this);
    _appSettings.removeListener(_handleWalletVisibilityChanged);
    _slideController.dispose();
    _scaleController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Refresh wallet balance when app comes to foreground
      _refreshWalletBalance();
    }
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
              _buildRecentTransactions(isTablet),
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
              ],
            ),
            SizedBox(height: isTablet ? 20 : 16),
            AnimatedBuilder(
              animation: _balanceAnimation,
              builder: (context, child) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _balanceVisible
                          ? (_walletBalance != null
                              ? _formatCurrency(_walletBalance!)
                              : '₦0.00')
                          : '*************',
                      style: TextStyle(
                        color: colorScheme.onPrimary,
                        fontSize: _balanceVisible
                            ? (isTablet ? 28 : 22) // Reduced font size for better fit
                            : (isTablet ? 18 : 16),
                        fontWeight: FontWeight.bold,
                        letterSpacing: _balanceVisible ? 1 : 2,
                      ),
                    ),
                    SizedBox(height: isTablet ? 16 : 12),
                    Row(
                      children: [
                        Flexible(
                          child: GestureDetector(
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
                                horizontal: isTablet ? 18 : 12,
                                vertical: isTablet ? 10 : 8,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.onPrimary.withValues(alpha: 0.2),
                                borderRadius:
                                    BorderRadius.circular(isTablet ? 22 : 18),
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
                                    size: isTablet ? 18 : 14,
                                  ),
                                  SizedBox(width: isTablet ? 6 : 4),
                                  Flexible(
                                    child: Text(
                                      'Add Money',
                                      style: TextStyle(
                                        color: colorScheme.onPrimary,
                                        fontSize: isTablet ? 13 : 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: isTablet ? 12 : 6),
                        Flexible(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const TransactionHistoryScreen(),
                                ),
                              );
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isTablet ? 16 : 10,
                                vertical: isTablet ? 10 : 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius:
                                    BorderRadius.circular(isTablet ? 22 : 18),
                                border: Border.all(
                                  color:
                                      Colors.white.withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.receipt_long_outlined,
                                    color: Colors.white,
                                    size: isTablet ? 16 : 14,
                                  ),
                                  SizedBox(width: isTablet ? 6 : 4),
                                  Flexible(
                                    child: Text(
                                      isTablet ? 'Transaction History' : 'History',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: isTablet ? 12 : 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
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
          title: 'Education',
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
            } else if (service.title == 'Education') {
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
                      fontSize: isTablet ? 14 : 11,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ));
  }

  Widget _buildRecentTransactions(bool isTablet) {
    final colorScheme = Theme.of(context).colorScheme;
    
    if (_recentTransactions.isEmpty && !_transactionsLoading) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isTablet ? 32 : 20,
        vertical: isTablet ? 16 : 12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Transactions',
                style: TextStyle(
                  fontSize: isTablet ? 20 : 18,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              if (_recentTransactions.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TransactionHistoryScreen(),
                      ),
                    );
                  },
                  child: Text(
                    'View All',
                    style: TextStyle(
                      fontSize: isTablet ? 14 : 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF00CA44),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: isTablet ? 16 : 12),
          if (_transactionsLoading)
            Container(
              padding: EdgeInsets.all(isTablet ? 32 : 24),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF00CA44),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _recentTransactions.length,
              separatorBuilder: (context, index) => SizedBox(height: isTablet ? 12 : 8),
              itemBuilder: (context, index) {
                return _buildRecentTransactionItem(_recentTransactions[index], isTablet);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactionItem(Transaction transaction, bool isTablet) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isIncoming = transaction.isIncoming;
    final statusColor = transaction.statusColor;
    const brandColor = Color(0xFF00CA44);

    return Container(
      padding: EdgeInsets.all(isTablet ? 16 : 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isTablet ? 10 : 8),
            decoration: BoxDecoration(
              color: brandColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(isTablet ? 10 : 8),
            ),
            child: Icon(
              transaction.icon,
              color: brandColor,
              size: isTablet ? 20 : 16,
            ),
          ),
          SizedBox(width: isTablet ? 12 : 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.title,
                  style: TextStyle(
                    fontSize: isTablet ? 14 : 12,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: isTablet ? 4 : 2),
                Text(
                  transaction.date,
                  style: TextStyle(
                    fontSize: isTablet ? 11 : 9,
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isIncoming ? '+' : '-'}₦${transaction.amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: isTablet ? 14 : 12,
                  fontWeight: FontWeight.bold,
                  color: isIncoming ? brandColor : colorScheme.onSurface,
                ),
              ),
              SizedBox(height: isTablet ? 4 : 2),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 8 : 6,
                  vertical: isTablet ? 3 : 2,
                ),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(isTablet ? 10 : 8),
                ),
                child: Text(
                  transaction.status,
                  style: TextStyle(
                    fontSize: isTablet ? 9 : 8,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
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
      title = _titleCaseStatic(channel);
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
      title = channel.isEmpty ? 'Wallet Transaction' : _titleCaseStatic(channel);
    }

    final formattedDate =
        createdAt != null ? formatter.format(createdAt) : '--';

    return Transaction(
      title: title,
      amount: rawAmount.abs(),
      date: formattedDate,
      status: _formatStatusStatic(rawStatus),
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
      
      // Add Service Type
      String serviceDisplayName = _getServiceDisplayName(serviceType);
      if (serviceDisplayName.isNotEmpty) {
        extraDetails.add(ReceiptField(label: 'Service', value: serviceDisplayName));
      }
      
      // Add Service Provider
      String serviceProvider = _getServiceProvider(serviceType, metadata!);
      if (serviceProvider.isNotEmpty) {
        extraDetails.add(ReceiptField(label: 'Service Provider', value: serviceProvider));
      }
      
      // Add Recipient (Phone/Meter/Smart Card/Email)
      String recipient = _getRecipient(serviceType, metadata!);
      if (recipient.isNotEmpty) {
        extraDetails.add(ReceiptField(label: _getRecipientLabel(serviceType), value: recipient));
      }
      
      // Add additional service-specific details
      _addServiceSpecificDetails(serviceType, metadata!, extraDetails);
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
  
  // Helper function to get service display name
  String _getServiceDisplayName(String serviceType) {
    switch (serviceType.toLowerCase()) {
      case 'airtime':
        return 'Airtime';
      case 'data':
        return 'Data';
      case 'electricity':
        return 'Electricity';
      case 'tv':
        return 'TV Subscription';
      case 'education':
        return 'Exam Pin';
      default:
        return serviceType.isNotEmpty ? serviceType.toUpperCase() : '';
    }
  }
  
  // Helper function to get service provider
  String _getServiceProvider(String serviceType, Map<String, dynamic> metadata) {
    switch (serviceType.toLowerCase()) {
      case 'airtime':
      case 'data':
        final network = metadata['network']?.toString();
        return network?.toUpperCase() ?? '';
      case 'electricity':
        final disco = metadata['disco']?.toString();
        return _getDiscoDisplayName(disco ?? '');
      case 'tv':
        final provider = metadata['provider']?.toString();
        return provider?.toUpperCase() ?? '';
      case 'education':
        final examType = metadata['examType']?.toString();
        return examType?.toUpperCase() ?? 'WAEC';
      default:
        return '';
    }
  }
  
  // Helper function to get recipient
  String _getRecipient(String serviceType, Map<String, dynamic> metadata) {
    switch (serviceType.toLowerCase()) {
      case 'airtime':
      case 'data':
        return metadata['phone']?.toString() ?? '';
      case 'electricity':
        // Check for email first (new format), then meter number
        final email = metadata['email']?.toString();
        if (email != null && email.isNotEmpty) {
          return email;
        }
        return metadata['meterNumber']?.toString() ?? '';
      case 'tv':
        return metadata['smartcardNumber']?.toString() ?? metadata['smartCardNumber']?.toString() ?? '';
      case 'education':
        final email = metadata['email']?.toString();
        if (email != null && email.isNotEmpty) {
          return email;
        }
        return metadata['candidateNumber']?.toString() ?? '';
      default:
        return '';
    }
  }
  
  // Helper function to get recipient label
  String _getRecipientLabel(String serviceType) {
    switch (serviceType.toLowerCase()) {
      case 'airtime':
      case 'data':
        return 'Phone Number';
      case 'electricity':
        return 'Purchase To'; // Can be email or meter number
      case 'tv':
        return 'Smart Card Number';
      case 'education':
        return 'Purchase To'; // Can be email or candidate number  
      default:
        return 'Recipient';
    }
  }
  
  // Helper function to get disco display name
  String _getDiscoDisplayName(String disco) {
    switch (disco.toUpperCase()) {
      case '01':
      case 'EKEDC':
        return 'Eko Electric (EKEDC)';
      case '02':
      case 'IKEDC':
        return 'Ikeja Electric (IKEDC)';
      case '03':
      case 'KEDCO':
        return 'Kano Electric (KEDCO)';
      case '04':
      case 'PHEDC':
        return 'Port Harcourt Electric (PHEDC)';
      case '05':
      case 'JEDC':
        return 'Jos Electric (JEDC)';
      case '06':
      case 'IBEDC':
        return 'Ibadan Electric (IBEDC)';
      case '07':
      case 'KAEDC':
        return 'Kaduna Electric (KAEDC)';
      case '08':
      case 'AEDC':
        return 'Abuja Electric (AEDC)';
      case '09':
      case 'BEDC':
        return 'Benin Electric (BEDC)';
      case '10':
      case 'EEDC':
        return 'Enugu Electric (EEDC)';
      default:
        return disco.isNotEmpty ? disco.toUpperCase() : 'Unknown';
    }
  }
  
  // Helper function to add service-specific additional details
  void _addServiceSpecificDetails(String serviceType, Map<String, dynamic> metadata, List<ReceiptField> extraDetails) {
    switch (serviceType.toLowerCase()) {
      case 'airtime':
        // Add airtime value if different from amount (discounted purchases)
        final airtimeValue = metadata['airtimeValue'];
        if (airtimeValue != null) {
          extraDetails.add(ReceiptField(
              label: 'Airtime Value', value: '₦${airtimeValue.toString()}'));
        }
        
        // Add discount if applicable
        final discount = metadata['discount'];
        if (discount != null && discount > 0) {
          extraDetails.add(ReceiptField(label: 'Discount', value: '$discount%'));
        }
        break;
        
      case 'data':
        // Add plan ID for data
        final planId = metadata['planId']?.toString();
        if (planId != null && planId.isNotEmpty) {
          extraDetails.add(ReceiptField(label: 'Plan ID', value: planId));
        }
        break;
        
      case 'electricity':
        // Add meter number if email was primary recipient
        final email = metadata['email']?.toString();
        final meterNumber = metadata['meterNumber']?.toString();
        if (email != null && email.isNotEmpty && meterNumber != null && meterNumber.isNotEmpty) {
          extraDetails.add(ReceiptField(label: 'Meter Number', value: meterNumber));
        }
        
        // Add electricity amount and service charge
        final electricityAmount = metadata['electricityAmount'];
        if (electricityAmount != null) {
          extraDetails.add(ReceiptField(
              label: 'Electricity Amount', value: '₦${electricityAmount.toString()}'));
        }
        
        final serviceCharge = metadata['serviceCharge'];
        if (serviceCharge != null && serviceCharge > 0) {
          extraDetails.add(ReceiptField(
              label: 'Service Charge', value: '₦${serviceCharge.toString()}'));
        }
        break;
        
      case 'tv':
        // Add customer name if available
        final customerName = metadata['customerName']?.toString();
        if (customerName != null && customerName.isNotEmpty) {
          extraDetails.add(ReceiptField(label: 'Customer Name', value: customerName));
        }
        break;
        
      case 'education':
        // Add exam code
        final examCode = metadata['examCode']?.toString();
        if (examCode != null && examCode.isNotEmpty) {
          extraDetails.add(ReceiptField(label: 'Exam Code', value: examCode));
        }
        
        // Add candidate details if email was primary
        final email = metadata['email']?.toString();
        final candidateNumber = metadata['candidateNumber']?.toString();
        if (email != null && email.isNotEmpty && candidateNumber != null && candidateNumber.isNotEmpty) {
          extraDetails.add(ReceiptField(label: 'Candidate Number', value: candidateNumber));
        }
        break;
    }
  }

  String _titleCase(String value) {
    if (value.isEmpty) return value;
    return value
        .split(' ')
        .where((word) => word.isNotEmpty)
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }

  // Static version of _titleCase for use in factory constructor
  static String _titleCaseStatic(String value) {
    if (value.isEmpty) return value;
    return value
        .split(' ')
        .where((word) => word.isNotEmpty)
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }

  // Static version of _formatStatus for use in factory constructor
  static String _formatStatusStatic(String status) {
    switch (status.toLowerCase()) {
      case 'success':
        return 'Successful';
      case 'failed':
        return 'Failed';
      case 'pending':
        return 'Pending';
      case 'cancelled':
        return 'Cancelled';
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
