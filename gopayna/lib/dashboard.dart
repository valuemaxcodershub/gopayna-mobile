import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login.dart';
import 'dart:convert';
import 'setting.dart';
import 'referral_screen.dart';
import 'all_transactions_history.dart';
import 'support.dart';
import 'fund_wallet.dart';
import 'withdraw_fund.dart';
import 'buy_airtime.dart';
import 'buy_data.dart';
import 'buy_electricity.dart';
import 'buy_tv_subscription.dart';
import 'buy_education_pin.dart';
import 'notification.dart';
import 'dart:developer';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  String? _userName;
  double? _walletBalance;

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

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
    _checkAuthentication();
    // _lastActivity = DateTime.now();
    // Removed observer logic and undefined _DashboardLifecycleObserver
  }

  void _updateActivity() {
    setState(() {
      // _lastActivity = DateTime.now();
    });
  }


  // Removed lifecycle observer method
  final List<Transaction> _transactions = [
    Transaction(
      title: 'Transfer to FATIMOH FOLAKE A......',
      amount: -2100.00,
      date: 'Jun 3rd, 09:56',
      status: 'Successful',
      isIncoming: false,
    ),
    Transaction(
      title: 'Transfer to AMINAT OLUWAKE......',
      amount: -14700.00,
      date: 'Jun 2nd, 09:56',
      status: 'Successful',
      isIncoming: false,
    ),
    Transaction(
      title: 'Transfer to IFEOLUWA OLUWAKE......',
      amount: -2100.00,
      date: 'Jun 2nd, 09:56',
      status: 'Successful',
      isIncoming: false,
    ),
    Transaction(
      title: 'Transfer to EBERE NNOILI......',
      amount: -4100.00,
      date: 'Jun 2nd, 09:56',
      status: 'Successful',
      isIncoming: false,
    ),
  ];

  // Remove duplicate initState

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
      // Reset activity time on login
      // _lastActivity = DateTime.now();
    }
  }

  Future<void> _loadUserInfo(String token) async {
    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        throw const FormatException('Invalid token format');
      }

      final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      final data = json.decode(payload);

      // Accept tokens with id, email, phone (from backend)
      if (data is! Map) {
        throw const FormatException('Invalid token payload');
      }

      String? name;
      if (data.containsKey('firstName') && data['firstName'] != null && data['firstName'].toString().isNotEmpty) {
        name = data['firstName'];
      } else if (data.containsKey('lastName') && data['lastName'] != null && data['lastName'].toString().isNotEmpty) {
        name = data['lastName'];
      } else if (data.containsKey('email')) {
        // Only fallback to email if no name is available
        name = '';
      } else if (data.containsKey('phone')) {
        name = '';
      } else if (data.containsKey('id')) {
        name = '';
      } else {
        throw const FormatException('Invalid token payload');
      }

      double? walletBalance;
      if (data.containsKey('wallet_balance')) {
        walletBalance = double.tryParse(data['wallet_balance'].toString());
      }
      setState(() {
        _userName = name ?? '';
        _walletBalance = walletBalance;
      });
    } catch (e) {
      log('Failed to load user info: $e', name: '_DashboardScreenState');
      setState(() {
        _userName = null; // Reset user name on error
      });
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt');
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
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
    setState(() {
      _balanceVisible = !_balanceVisible;
    });
    if (_balanceVisible) {
      if (mounted && !_balanceController.isAnimating) {
        _balanceController.forward();
      }
    } else {
      if (mounted && !_balanceController.isAnimating) {
        _balanceController.reverse();
      }
    }
    HapticFeedback.lightImpact();
  }

  @override
  void dispose() {
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

    // Listen for user activity
    return GestureDetector(
      onTap: _updateActivity,
      onPanDown: (_) => _updateActivity(),
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: const Color(0xFF00B82E),
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
                    border: Border.all(color: Color.fromRGBO(255,255,255,0.3), width: 2),
                    color: Color.fromRGBO(255,255,255,0.15),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
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
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationScreen(),
                  ),
                );
              },
              tooltip: 'Notifications',
            ),
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              onPressed: _logout,
              tooltip: 'Logout',
            ),
          ],
          systemOverlayStyle: SystemUiOverlayStyle.light,
        ),
        backgroundColor: const Color(0xFFF8F9FA),
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
            colors: Theme.of(context).brightness == Brightness.dark
                ? [const Color(0xFF1E3A1E), const Color(0xFF0F5F0F)]
                : [const Color(0xFF00B82E), const Color(0xFF00A525)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
          boxShadow: [
            BoxShadow(
              color: Color.fromRGBO(0,184,46,0.3),
              blurRadius: 20,
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
                  color: Colors.white,
                  size: isTablet ? 24 : 20,
                ),
                SizedBox(width: isTablet ? 12 : 8),
                Text(
                  'Available Balance',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isTablet ? 16 : 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: _toggleBalance,
                  child: Icon(
                    _balanceVisible ? Icons.visibility_off : Icons.visibility,
                    color: Colors.white,
                    size: isTablet ? 24 : 20,
                  ),
                ),
                SizedBox(width: isTablet ? 12 : 8),
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
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            'Transaction History',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isTablet ? 12 : 9,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: isTablet ? 6 : 2),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.white,
                          size: isTablet ? 14 : 12,
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
                            ? (_walletBalance != null ? '₦${_walletBalance!.toStringAsFixed(2)}' : '₦0.00')
                            : '*************',
                        style: TextStyle(
                          color: Colors.white,
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
                          color: Color.fromRGBO(255,255,255,0.2),
                          borderRadius: BorderRadius.circular(isTablet ? 25 : 20),
                          border: Border.all(
                            color: Color.fromRGBO(255,255,255,0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.add,
                              color: Colors.white,
                              size: isTablet ? 20 : 16,
                            ),
                            SizedBox(width: isTablet ? 8 : 4),
                            Text(
                              'Add Money',
                              style: TextStyle(
                                color: Colors.white,
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
      ServiceItem(icon: Icons.credit_card, title: 'Data', color: const Color(0xFF00B82E)),
      ServiceItem(icon: Icons.airplanemode_active, title: 'Airtime', color: const Color(0xFF00B82E)),
      ServiceItem(icon: Icons.electrical_services, title: 'Electricity', color: const Color(0xFF00B82E)),
      ServiceItem(icon: Icons.tv, title: 'TV', color: const Color(0xFF00B82E)),
      ServiceItem(icon: Icons.school, title: 'Education', color: const Color(0xFF00B82E)),
      ServiceItem(icon: Icons.money, title: 'Withdraw Fund', color: const Color(0xFF00B82E)),
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
    return AnimatedContainer(
      duration: Duration(milliseconds: 200 + (index * 50)),
      curve: Curves.easeOutCubic,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          if (service.title == 'Withdraw Fund') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const WithdrawFundScreen(),
              ),
            );
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
            boxShadow: [
              BoxShadow(
                color: Color.fromRGBO(0,0,0,0.05),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(isTablet ? 14 : 10),
                decoration: BoxDecoration(
                  color: Color.fromRGBO((service.color.r * 255.0).round() & 0xff, (service.color.g * 255.0).round() & 0xff, (service.color.b * 255.0).round() & 0xff, 0.1),
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
                    color: Colors.black87,
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
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: EdgeInsets.only(
          left: isTablet ? 32 : 20,
          right: isTablet ? 32 : 20,
          top: isTablet ? 24 : 20,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(isTablet ? 24 : 20),
            topRight: Radius.circular(isTablet ? 24 : 20),
          ),
          boxShadow: [
            BoxShadow(
              color: Color.fromRGBO(0,0,0,0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(isTablet ? 24 : 20),
              child: Row(
                children: [
                  Text(
                    'Recent Transactions',
                    style: TextStyle(
                      fontSize: isTablet ? 20 : 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const Spacer(),
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
                      'See all',
                      style: TextStyle(
                        fontSize: isTablet ? 16 : 14,
                        color: const Color(0xFF00B82E),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: isTablet ? 260 : 180, // Fixed height for transaction list
              child: ListView.builder(
                padding: EdgeInsets.only(
                  left: isTablet ? 24 : 20,
                  right: isTablet ? 24 : 20,
                  bottom: isTablet ? 100 : 80,
                ),
                itemCount: _transactions.length,
                itemBuilder: (context, index) {
                  return _buildTransactionItem(_transactions[index], isTablet, index);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionItem(Transaction transaction, bool isTablet, int index) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300 + (index * 100)),
      curve: Curves.easeOutCubic,
      margin: EdgeInsets.only(bottom: isTablet ? 16 : 12),
      child: Container(
        padding: EdgeInsets.all(isTablet ? 16 : 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(isTablet ? 12 : 8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(isTablet ? 12 : 8),
              decoration: const BoxDecoration(
                color: Color(0xFF00B82E),
                shape: BoxShape.circle,
              ),
              child: Icon(
                transaction.isIncoming ? Icons.arrow_downward : Icons.arrow_upward,
                color: Colors.white,
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
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: isTablet ? 6 : 4),
                  Text(
                    transaction.date,
                    style: TextStyle(
                      fontSize: isTablet ? 14 : 12,
                      color: Colors.grey.shade600,
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
                    color: transaction.isIncoming ? const Color(0xFF00B82E) : Colors.red,
                  ),
                ),
                SizedBox(height: isTablet ? 6 : 4),
                Text(
                  transaction.status,
                  style: TextStyle(
                    fontSize: isTablet ? 12 : 10,
                    color: const Color(0xFF00B82E),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigation(bool isTablet) {
    return Container(
      height: isTablet ? 90 : 80,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(isTablet ? 24 : 20),
          topRight: Radius.circular(isTablet ? 24 : 20),
        ),
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(0,0,0,0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
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
              color: isSelected ? const Color(0xFF00B82E) : Colors.grey.shade600,
              size: isTablet ? 28 : 24,
            ),
            SizedBox(height: isTablet ? 6 : 4),
            Text(
              label,
              style: TextStyle(
                fontSize: isTablet ? 14 : 12,
                color: isSelected ? const Color(0xFF00B82E) : Colors.grey.shade600,
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

  Transaction({
    required this.title,
    required this.amount,
    required this.date,
    required this.status,
    required this.isIncoming,
  });
}