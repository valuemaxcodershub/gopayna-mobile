import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ReferrerPage extends StatefulWidget {
  const ReferrerPage({super.key});

  @override
  State<ReferrerPage> createState() => _ReferrerPageState();
}

class _ReferrerPageState extends State<ReferrerPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  final String _referralCode = 'WFCZFF600';
  bool _showHistory = false;
  
  final List<ReferralEarning> _earnings = [
    ReferralEarning(
      referredUser: 'John Adebayo',
      amount: 500.00,
      date: 'Nov 18, 2025 - 03:45 PM',
      status: 'Completed',
      type: 'Registration Bonus',
    ),
    ReferralEarning(
      referredUser: 'Mary Okonkwo',
      amount: 250.00,
      date: 'Nov 17, 2025 - 11:20 AM',
      status: 'Completed',
      type: 'Transaction Bonus',
    ),
    ReferralEarning(
      referredUser: 'Ibrahim Hassan',
      amount: 500.00,
      date: 'Nov 15, 2025 - 07:30 PM',
      status: 'Completed',
      type: 'Registration Bonus',
    ),
    ReferralEarning(
      referredUser: 'Grace Okoro',
      amount: 150.00,
      date: 'Nov 12, 2025 - 02:15 PM',
      status: 'Completed',
      type: 'Transaction Bonus',
    ),
    ReferralEarning(
      referredUser: 'David Ogunbiyi',
      amount: 500.00,
      date: 'Nov 10, 2025 - 09:45 AM',
      status: 'Pending',
      type: 'Registration Bonus',
    ),
    ReferralEarning(
      referredUser: 'Fatima Abdul',
      amount: 300.00,
      date: 'Nov 8, 2025 - 05:20 PM',
      status: 'Completed',
      type: 'Transaction Bonus',
    ),
    ReferralEarning(
      referredUser: 'Chidi Okwu',
      amount: 500.00,
      date: 'Nov 5, 2025 - 01:10 PM',
      status: 'Completed',
      type: 'Registration Bonus',
    ),
    ReferralEarning(
      referredUser: 'Aisha Mohammed',
      amount: 200.00,
      date: 'Nov 3, 2025 - 04:35 PM',
      status: 'Completed',
      type: 'Transaction Bonus',
    ),
  ];

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
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1200),
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
  }

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 100));
    _fadeController.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    _slideController.forward();
    await Future.delayed(const Duration(milliseconds: 400));
    _scaleController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    final statusBarHeight = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
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
      color: const Color(0xFFF8F9FA),
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
          color: Colors.white,
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
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.arrow_back,
                  color: Colors.black87,
                  size: isTablet ? 24 : 20,
                ),
              ),
            ),
            SizedBox(width: isTablet ? 16 : 12),
            Icon(
              Icons.group,
              color: const Color(0xFF00B82E),
              size: isTablet ? 28 : 24,
            ),
            SizedBox(width: isTablet ? 12 : 8),
            Expanded(
              child: Text(
                'Refferals',
                style: TextStyle(
                  fontSize: isTablet ? 24 : 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  _showHistory = !_showHistory;
                });
              },
              child: Container(
                padding: EdgeInsets.all(isTablet ? 12 : 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF00B82E).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.history,
                  color: const Color(0xFF00B82E),
                  size: isTablet ? 24 : 20,
                ),
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
      child: _showHistory 
          ? _buildHistoryView(isTablet)
          : _buildReferralView(isTablet),
    );
  }

  Widget _buildReferralView(bool isTablet) {
    return SingleChildScrollView(
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: isTablet ? 32 : 20,
        ),
        child: Column(
          children: [
            SizedBox(height: isTablet ? 24 : 16),
            _buildEarningsCard(isTablet),
            SizedBox(height: isTablet ? 40 : 30),
            _buildTitleSection(isTablet),
            SizedBox(height: isTablet ? 32 : 24),
            _buildReferralCodeSection(isTablet),
            SizedBox(height: isTablet ? 24 : 20),
            _buildShareButton(isTablet),
            SizedBox(height: isTablet ? 32 : 24),
            _buildRecentEarningsSection(isTablet),
            SizedBox(height: isTablet ? 24 : 16),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryView(bool isTablet) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isTablet ? 32 : 20,
        vertical: isTablet ? 16 : 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
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
                  'All Earnings',
                  style: TextStyle(
                    fontSize: isTablet ? 20 : 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_earnings.length} records',
                  style: TextStyle(
                    fontSize: isTablet ? 14 : 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.only(
                left: isTablet ? 24 : 20,
                right: isTablet ? 24 : 20,
                bottom: isTablet ? 24 : 20,
              ),
              itemCount: _earnings.length,
              itemBuilder: (context, index) {
                return _buildEarningItemCard(_earnings[index], isTablet, index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsCard(bool isTablet) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: EdgeInsets.all(isTablet ? 24 : 20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF00B82E), Color(0xFF00A525)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00B82E).withValues(alpha: 0.3),
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
                Text(
                  'Total Referral Earnings',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isTablet ? 16 : 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.trending_up,
                  color: Colors.white,
                  size: isTablet ? 24 : 20,
                ),
              ],
            ),
            SizedBox(height: isTablet ? 16 : 12),
            Text(
              '₦2,700.00',
              style: TextStyle(
                color: Colors.white,
                fontSize: isTablet ? 36 : 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: isTablet ? 8 : 6),
            Row(
              children: [
                Icon(
                  Icons.group,
                  color: Colors.white.withValues(alpha: 0.8),
                  size: isTablet ? 16 : 14,
                ),
                SizedBox(width: isTablet ? 8 : 6),
                Text(
                  '7 successful referrals',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: isTablet ? 14 : 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentEarningsSection(bool isTablet) {
    final recentEarnings = [
      {'name': 'John Adebayo', 'amount': '₦500', 'type': 'Registration'},
      {'name': 'Mary Okonkwo', 'amount': '₦250', 'type': 'Transaction'},
      {'name': 'Ibrahim Hassan', 'amount': '₦500', 'type': 'Registration'},
    ];

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: EdgeInsets.all(isTablet ? 24 : 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Recent Earnings',
                  style: TextStyle(
                    fontSize: isTablet ? 20 : 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _showHistory = !_showHistory;
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 12 : 8,
                      vertical: isTablet ? 6 : 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00B82E).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'See all',
                      style: TextStyle(
                        color: const Color(0xFF00B82E),
                        fontSize: isTablet ? 14 : 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: isTablet ? 20 : 16),
            ...recentEarnings.map((earning) => Container(
              margin: EdgeInsets.only(bottom: isTablet ? 16 : 12),
              padding: EdgeInsets.all(isTablet ? 16 : 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F8F0),
                borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
                border: Border.all(
                  color: const Color(0xFF00B82E).withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(isTablet ? 10 : 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00B82E).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      earning['type'] == 'Registration' 
                          ? Icons.person_add 
                          : Icons.monetization_on,
                      color: const Color(0xFF00B82E),
                      size: isTablet ? 20 : 16,
                    ),
                  ),
                  SizedBox(width: isTablet ? 16 : 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          earning['name']!,
                          style: TextStyle(
                            fontSize: isTablet ? 16 : 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: isTablet ? 4 : 2),
                        Text(
                          '${earning['type']} Bonus',
                          style: TextStyle(
                            fontSize: isTablet ? 12 : 10,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    earning['amount']!,
                    style: TextStyle(
                      fontSize: isTablet ? 16 : 14,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF00B82E),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleSection(bool isTablet) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Column(
        children: [
          Text(
            'Refer friends and earn ₦6\ninstantly',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isTablet ? 28 : 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              height: 1.3,
            ),
          ),
          SizedBox(height: isTablet ? 20 : 16),
          Text(
            'Invite friends to Gopayna and earn ₦6 on each\nreferrals first transaction',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isTablet ? 18 : 16,
              color: Colors.grey.shade600,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReferralCodeSection(bool isTablet) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 24 : 20,
          vertical: isTablet ? 20 : 16,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
          border: Border.all(
            color: const Color(0xFF00B82E),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _referralCode,
              style: TextStyle(
                fontSize: isTablet ? 24 : 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF00B82E),
                letterSpacing: 2,
              ),
            ),
            SizedBox(width: isTablet ? 16 : 12),
            GestureDetector(
              onTap: _copyReferralCode,
              child: Container(
                padding: EdgeInsets.all(isTablet ? 12 : 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF00B82E).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(isTablet ? 10 : 8),
                ),
                child: Icon(
                  Icons.copy,
                  color: const Color(0xFF00B82E),
                  size: isTablet ? 24 : 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShareButton(bool isTablet) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: SizedBox(
        width: double.infinity,
        height: isTablet ? 60 : 56,
        child: ElevatedButton(
          onPressed: _shareReferralCode,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00B82E),
            foregroundColor: Colors.white,
            elevation: 8,
            shadowColor: const Color(0xFF00B82E).withValues(alpha: 0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
            ),
          ),
          child: Text(
            'Share referral code',
            style: TextStyle(
              fontSize: isTablet ? 18 : 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEarningItemCard(ReferralEarning earning, bool isTablet, int index) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300 + (index * 100)),
      curve: Curves.easeOutCubic,
      margin: EdgeInsets.only(bottom: isTablet ? 16 : 12),
      child: Container(
        padding: EdgeInsets.all(isTablet ? 20 : 16),
        decoration: BoxDecoration(
          color: earning.status == 'Completed' 
              ? const Color(0xFFF0F8F0) 
              : Colors.orange.shade50,
          borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
          border: Border.all(
            color: earning.status == 'Completed'
                ? const Color(0xFF00B82E).withValues(alpha: 0.2)
                : Colors.orange.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(isTablet ? 12 : 8),
                  decoration: BoxDecoration(
                    color: earning.status == 'Completed'
                        ? const Color(0xFF00B82E).withValues(alpha: 0.1)
                        : Colors.orange.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    earning.type == 'Registration Bonus' 
                        ? Icons.person_add 
                        : Icons.monetization_on,
                    color: earning.status == 'Completed'
                        ? const Color(0xFF00B82E)
                        : Colors.orange,
                    size: isTablet ? 24 : 20,
                  ),
                ),
                SizedBox(width: isTablet ? 16 : 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        earning.referredUser,
                        style: TextStyle(
                          fontSize: isTablet ? 16 : 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: isTablet ? 4 : 2),
                      Text(
                        earning.type,
                        style: TextStyle(
                          fontSize: isTablet ? 12 : 10,
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
                      '₦${earning.amount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: isTablet ? 18 : 16,
                        fontWeight: FontWeight.bold,
                        color: earning.status == 'Completed'
                            ? const Color(0xFF00B82E)
                            : Colors.orange,
                      ),
                    ),
                    SizedBox(height: isTablet ? 4 : 2),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isTablet ? 8 : 6,
                        vertical: isTablet ? 4 : 2,
                      ),
                      decoration: BoxDecoration(
                        color: earning.status == 'Completed'
                            ? const Color(0xFF00B82E)
                            : Colors.orange,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        earning.status,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isTablet ? 10 : 8,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: isTablet ? 12 : 8),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: isTablet ? 16 : 14,
                  color: Colors.grey.shade500,
                ),
                SizedBox(width: isTablet ? 8 : 4),
                Text(
                  earning.date,
                  style: TextStyle(
                    fontSize: isTablet ? 12 : 10,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _copyReferralCode() {
    Clipboard.setData(ClipboardData(text: _referralCode));
    HapticFeedback.lightImpact();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text('Referral code $_referralCode copied!'),
          ],
        ),
        backgroundColor: const Color(0xFF00B82E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _shareReferralCode() {
    HapticFeedback.lightImpact();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Share Referral Code'),
        content: Text(
          'Join me on Gopayna and we both earn ₦6! Use my referral code: $_referralCode\n\nDownload the app now and start earning!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _copyReferralCode();
            },
            child: const Text(
              'Copy & Share',
              style: TextStyle(
                color: Color(0xFF00B82E),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ReferralEarning {
  final String referredUser;
  final double amount;
  final String date;
  final String status;
  final String type;

  ReferralEarning({
    required this.referredUser,
    required this.amount,
    required this.date,
    required this.status,
    required this.type,
  });
}