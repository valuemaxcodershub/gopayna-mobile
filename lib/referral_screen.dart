import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';

import 'api_service.dart';

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

  String? _referralCode;
  bool _showHistory = false;
  double? _referralBalance;
  double? _walletBalance;
  int _referralPendingCount = 0;
  bool _isProcessingWithdrawal = false;
  bool _isSummaryLoading = true;
  String? _summaryError;

  ColorScheme get _colorScheme => Theme.of(context).colorScheme;
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _onSurface => _colorScheme.onSurface;
  Color get _mutedText => _colorScheme.onSurface.withValues(alpha: 0.7);
  Color get _cardColor => _colorScheme.surface;
  Color get _shadowColor => Colors.black.withValues(alpha: _isDark ? 0.5 : 0.08);
  
  List<ReferralEarning> _earnings = [];
  bool _isHistoryLoading = false;
  String? _historyError;
  String? _authToken;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
    _loadReferralSummary();
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

  Future<String?> _getAuthToken() async {
    if (_authToken != null && _authToken!.isNotEmpty) {
      return _authToken;
    }
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt');
    if (token != null && token.isNotEmpty) {
      _authToken = token;
    }
    return _authToken;
  }

  Future<void> _loadReferralSummary() async {
    setState(() {
      _isSummaryLoading = true;
      _summaryError = null;
    });

    try {
      final token = await _getAuthToken();
      if (token == null || token.isEmpty) {
        if (!mounted) return;
        setState(() {
          _summaryError = 'Session expired. Please sign in again.';
          _isSummaryLoading = false;
        });
        return;
      }

      final response = await fetchUserProfile(token);
      if (!mounted) return;

      if (response['error'] != null) {
        setState(() {
          _summaryError = response['error'].toString();
          _isSummaryLoading = false;
        });
        return;
      }

      final user = response['user'] ?? response;
      setState(() {
        _referralCode = user['referralCode']?.toString();
        _referralBalance =
            double.tryParse(user['referralBonusWallet']?.toString() ?? '') ?? 0;
        _walletBalance =
            double.tryParse(user['walletBalance']?.toString() ?? '') ?? 0;
        _referralPendingCount =
            int.tryParse(user['referralPendingCount']?.toString() ?? '0') ?? 0;
        _isSummaryLoading = false;
      });

      await _loadReferralHistory(token: token);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _summaryError = 'Unable to load referral summary.';
        _isSummaryLoading = false;
      });
    }
  }

  double get _referralBalanceValue => _referralBalance ?? 0;
  double get _walletBalanceValue => _walletBalance ?? 0;
  bool get _canShareReferral =>
      !_isSummaryLoading && (_referralCode?.trim().isNotEmpty ?? false);

  Future<void> _loadReferralHistory({String? token, int? limitOverride}) async {
    final authToken = token ?? await _getAuthToken();
    if (authToken == null || authToken.isEmpty) {
      return;
    }

    final limit = limitOverride ?? (_showHistory ? 50 : 6);

    if (!mounted) return;
    setState(() {
      _isHistoryLoading = true;
      _historyError = null;
    });

    try {
      final response = await fetchReferralHistory(token: authToken, limit: limit);
      if (!mounted) return;

      if (response['error'] != null) {
        setState(() {
          _historyError = response['error'].toString();
          _isHistoryLoading = false;
        });
        return;
      }

      final dynamic rawData = response['data'];
      final List<dynamic> payload = rawData is List ? rawData : const [];
      final parsed = payload
          .whereType<Map<String, dynamic>>()
          .map(ReferralEarning.fromApi)
          .toList();

      setState(() {
        _earnings = parsed;
        _isHistoryLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _historyError = 'Unable to load referral activity right now.';
        _isHistoryLoading = false;
      });
    }
  }

  void _showSnack(String message, {Color? background}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: background ?? Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _toggleHistoryView() {
    setState(() {
      _showHistory = !_showHistory;
    });
    _loadReferralHistory(limitOverride: _showHistory ? 50 : 6);
  }

  Future<void> _withdrawReferralEarnings() async {
    if (_isProcessingWithdrawal) return;

    final available = _referralBalanceValue;
    if (available <= 0) {
      _showSnack(
        'No referral earnings available to withdraw yet.',
        background: Theme.of(context).colorScheme.error,
      );
      return;
    }

    final token = await _getAuthToken();
    if (!mounted) return;
    if (token == null || token.isEmpty) {
      _showSnack(
        'Session expired. Please sign in again.',
        background: Theme.of(context).colorScheme.error,
      );
      return;
    }

    if (!mounted) return;
    setState(() {
      _isProcessingWithdrawal = true;
    });

    try {
      final response = await transferReferralEarnings(token: token);
      if (!mounted) return;

      if (response['error'] != null) {
        _showSnack(
          response['error'].toString(),
          background: Theme.of(context).colorScheme.error,
        );
      } else {
        final data = response['data'] ?? response;
        final newReferralBalance =
            double.tryParse(data['referralBonusWallet']?.toString() ?? '') ?? _referralBalanceValue;
        final newWalletBalance =
            double.tryParse(data['walletBalance']?.toString() ?? '') ?? _walletBalanceValue;

        setState(() {
          _referralBalance = newReferralBalance;
          _walletBalance = newWalletBalance;
        });

        await _loadReferralHistory(limitOverride: _showHistory ? 50 : 6);
        if (!mounted) return;

        _showSnack(
          data['message']?.toString() ?? 'Referral earnings moved to wallet.',
        );
      }
    } catch (e) {
      if (!mounted) return;
      _showSnack(
        'Unable to withdraw referral earnings right now.',
        background: Theme.of(context).colorScheme.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingWithdrawal = false;
        });
      }
    }
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
          color: _colorScheme.surface,
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
              Icons.group,
              color: _colorScheme.primary,
              size: isTablet ? 28 : 24,
            ),
            SizedBox(width: isTablet ? 12 : 8),
            Expanded(
              child: Text(
                'Refferals',
                style: TextStyle(
                  fontSize: isTablet ? 24 : 20,
                  fontWeight: FontWeight.bold,
                  color: _colorScheme.onSurface,
                ),
              ),
            ),
            GestureDetector(
              onTap: _toggleHistoryView,
              child: Container(
                padding: EdgeInsets.all(isTablet ? 12 : 8),
                decoration: BoxDecoration(
                  color: _colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.history,
                  color: _colorScheme.primary,
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
            _buildSummaryBanner(isTablet),
            SizedBox(height: _summaryError != null || _isSummaryLoading ? 16 : 0),
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

  Widget _buildSummaryBanner(bool isTablet) {
    if (_isSummaryLoading) {
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 20 : 16,
          vertical: isTablet ? 14 : 12,
        ),
        decoration: BoxDecoration(
          color: _colorScheme.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(_colorScheme.primary),
              ),
            ),
            SizedBox(width: isTablet ? 12 : 10),
            Text(
              'Fetching referral details...',
              style: TextStyle(
                color: _colorScheme.primary,
                fontWeight: FontWeight.w600,
                fontSize: isTablet ? 16 : 14,
              ),
            ),
          ],
        ),
      );
    }

    if (_summaryError != null) {
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 20 : 16,
          vertical: isTablet ? 14 : 12,
        ),
        decoration: BoxDecoration(
          color: _colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
          border: Border.all(color: _colorScheme.error.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: _colorScheme.error),
            SizedBox(width: isTablet ? 12 : 10),
            Expanded(
              child: Text(
                _summaryError!,
                style: TextStyle(
                  color: _colorScheme.error,
                  fontWeight: FontWeight.w600,
                  fontSize: isTablet ? 15 : 13,
                ),
              ),
            ),
            TextButton(
              onPressed: _loadReferralSummary,
              child: Text('Retry', style: TextStyle(color: _colorScheme.error)),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildHistoryView(bool isTablet) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isTablet ? 32 : 20,
        vertical: isTablet ? 16 : 12,
      ),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
        boxShadow: [
          BoxShadow(
            color: _shadowColor,
            blurRadius: 12,
            offset: const Offset(0, 6),
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
                    color: _onSurface,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_earnings.length} records',
                  style: TextStyle(
                    fontSize: isTablet ? 14 : 12,
                    color: _mutedText,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isHistoryLoading && _earnings.isEmpty
                ? Center(
                    child: SizedBox(
                      width: isTablet ? 36 : 28,
                      height: isTablet ? 36 : 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(_colorScheme.primary),
                      ),
                    ),
                  )
                : (_historyError != null && _earnings.isEmpty)
                    ? _buildHistoryMessage(
                        _historyError!,
                        isTablet,
                        isError: true,
                      )
                    : _earnings.isEmpty
                        ? _buildHistoryMessage(
                            'No referral activity yet.',
                            isTablet,
                          )
                        : ListView.builder(
                            padding: EdgeInsets.only(
                              left: isTablet ? 24 : 20,
                              right: isTablet ? 24 : 20,
                              bottom: isTablet ? 24 : 20,
                            ),
                            itemCount: _earnings.length,
                            itemBuilder: (context, index) {
                              return _buildEarningItemCard(
                                  _earnings[index], isTablet, index);
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryMessage(String message, bool isTablet,
      {bool isError = false}) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 24 : 16),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isError ? _colorScheme.error : _mutedText,
            fontSize: isTablet ? 16 : 14,
            fontWeight: isError ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildEarningsCard(bool isTablet) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: EdgeInsets.all(isTablet ? 24 : 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_colorScheme.primary, _colorScheme.secondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
          boxShadow: [
            BoxShadow(
              color: _colorScheme.primary.withValues(alpha: 0.35),
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
                    color: _colorScheme.onPrimary,
                    fontSize: isTablet ? 16 : 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.trending_up,
                  color: _colorScheme.onPrimary,
                  size: isTablet ? 24 : 20,
                ),
              ],
            ),
            SizedBox(height: isTablet ? 16 : 12),
            Text(
              '₦${_referralBalanceValue.toStringAsFixed(2)}',
              style: TextStyle(
                color: _colorScheme.onPrimary,
                fontSize: isTablet ? 36 : 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: isTablet ? 8 : 6),
            Row(
              children: [
                Icon(
                  Icons.group,
                  color: _colorScheme.onPrimary.withValues(alpha: 0.85),
                  size: isTablet ? 16 : 14,
                ),
                SizedBox(width: isTablet ? 8 : 6),
                Text(
                  '$_referralPendingCount/3 pending referrals',
                  style: TextStyle(
                    color: _colorScheme.onPrimary.withValues(alpha: 0.85),
                    fontSize: isTablet ? 14 : 12,
                  ),
                ),
              ],
            ),
            SizedBox(height: isTablet ? 12 : 10),
            
            SizedBox(height: isTablet ? 20 : 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: (_referralBalanceValue <= 0 || _isProcessingWithdrawal || _isSummaryLoading)
                    ? null
                    : _withdrawReferralEarnings,
                icon: _isProcessingWithdrawal
                    ? SizedBox(
                        width: isTablet ? 22 : 18,
                        height: isTablet ? 22 : 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(_colorScheme.primary),
                        ),
                      )
                    : const Icon(Icons.account_balance_wallet_outlined),
                label: Text(
                  _referralBalanceValue <= 0
                      ? 'No earnings to withdraw'
                      : 'Withdraw earnings',
                  style: TextStyle(
                    fontSize: isTablet ? 16 : 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _colorScheme.onPrimary,
                  foregroundColor: _colorScheme.primary,
                  padding: EdgeInsets.symmetric(vertical: isTablet ? 16 : 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentEarningsSection(bool isTablet) {
    final recentEarnings = _earnings.take(3).toList();
    final showLoader = _isHistoryLoading && recentEarnings.isEmpty;
    final showError = _historyError != null && recentEarnings.isEmpty;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: EdgeInsets.all(isTablet ? 24 : 20),
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
          boxShadow: [
            BoxShadow(
              color: _shadowColor,
              blurRadius: 12,
              offset: const Offset(0, 6),
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
                    color: _onSurface,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: _toggleHistoryView,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 12 : 8,
                      vertical: isTablet ? 6 : 4,
                    ),
                    decoration: BoxDecoration(
                      color: _colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'See all',
                      style: TextStyle(
                        color: _colorScheme.primary,
                        fontSize: isTablet ? 14 : 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: isTablet ? 20 : 16),
            if (_isHistoryLoading && recentEarnings.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(bottom: isTablet ? 16 : 12),
                child: LinearProgressIndicator(
                  minHeight: 3,
                  backgroundColor: _colorScheme.primary.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(_colorScheme.primary),
                ),
              )
            else if (showLoader)
              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: isTablet ? 24 : 16),
                  child: SizedBox(
                    width: isTablet ? 28 : 22,
                    height: isTablet ? 28 : 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(_colorScheme.primary),
                    ),
                  ),
                ),
              )
            else if (showError)
              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: isTablet ? 24 : 16),
                  child: Text(
                    _historyError ?? 'Unable to load referral activity.',
                    style: TextStyle(
                      color: _colorScheme.error,
                      fontSize: isTablet ? 16 : 14,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else if (recentEarnings.isEmpty)
              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: isTablet ? 24 : 16),
                  child: Text(
                    'No referral activity yet.',
                    style: TextStyle(
                      color: _mutedText,
                      fontSize: isTablet ? 16 : 14,
                    ),
                  ),
                ),
              )
            else
              ...recentEarnings.map((earning) => Container(
                    margin: EdgeInsets.only(bottom: isTablet ? 16 : 12),
                    padding: EdgeInsets.all(isTablet ? 16 : 12),
                    decoration: BoxDecoration(
                      color: _colorScheme.primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
                      border: Border.all(
                        color: _colorScheme.primary.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(isTablet ? 10 : 8),
                          decoration: BoxDecoration(
                            color: _colorScheme.primary.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            earning.type
                                    .toLowerCase()
                                    .contains('withdraw')
                                ? Icons.account_balance_wallet
                                : Icons.card_giftcard,
                            color: _colorScheme.primary,
                            size: isTablet ? 20 : 16,
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
                                  fontWeight: FontWeight.w600,
                                  color: _onSurface,
                                ),
                              ),
                              SizedBox(height: isTablet ? 4 : 2),
                              Text(
                                earning.type,
                                style: TextStyle(
                                  fontSize: isTablet ? 12 : 10,
                                  color: _mutedText,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '₦${earning.amount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: isTablet ? 16 : 14,
                            fontWeight: FontWeight.bold,
                            color: _colorScheme.primary,
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
          // Text(
          //   'Refer friends and earn ₦6\ninstantly',
          //   textAlign: TextAlign.center,
          //   style: TextStyle(
          //     fontSize: isTablet ? 28 : 24,
          //     fontWeight: FontWeight.bold,
          //     color: _onSurface,
          //     height: 1.3,
          //   ),
          // ),
          SizedBox(height: isTablet ? 20 : 16),
          Text(
            'Invite friends to Gopayna and earn ₦6 on every 3 friends you referred.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isTablet ? 18 : 16,
              color: _mutedText,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReferralCodeSection(bool isTablet) {
    final codeText = _referralCode?.toUpperCase() ?? '------';
    final isDisabled = !_canShareReferral;
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 24 : 20,
          vertical: isTablet ? 20 : 16,
        ),
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
          border: Border.all(
            color: _colorScheme.primary,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: _shadowColor,
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              codeText,
              style: TextStyle(
                fontSize: isTablet ? 24 : 20,
                fontWeight: FontWeight.bold,
                color: _colorScheme.primary,
                letterSpacing: 2,
              ),
            ),
            SizedBox(width: isTablet ? 16 : 12),
            GestureDetector(
              onTap: isDisabled ? null : _copyReferralCode,
              child: Container(
                padding: EdgeInsets.all(isTablet ? 12 : 8),
                decoration: BoxDecoration(
                  color: isDisabled
                      ? _colorScheme.onSurface.withValues(alpha: 0.08)
                      : _colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(isTablet ? 10 : 8),
                ),
                child: Icon(
                  Icons.copy,
                  color: isDisabled
                      ? _colorScheme.onSurface.withValues(alpha: 0.4)
                      : _colorScheme.primary,
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
          onPressed: _canShareReferral ? _shareReferralCode : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: _colorScheme.primary,
            foregroundColor: _colorScheme.onPrimary,
            elevation: 8,
            shadowColor: _colorScheme.primary.withValues(alpha: 0.35),
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
    final isCompleted = earning.status == 'Completed';
    final Color accentColor = isCompleted ? _colorScheme.primary : _colorScheme.tertiary;
    final Color accentBg = accentColor.withValues(alpha: 0.12);
    return AnimatedContainer(
      duration: Duration(milliseconds: 300 + (index * 100)),
      curve: Curves.easeOutCubic,
      margin: EdgeInsets.only(bottom: isTablet ? 16 : 12),
      child: Container(
        padding: EdgeInsets.all(isTablet ? 20 : 16),
        decoration: BoxDecoration(
          color: accentColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
          border: Border.all(
            color: accentColor.withValues(alpha: 0.3),
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
                    color: accentBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    earning.type.toLowerCase().contains('withdraw')
                        ? Icons.account_balance_wallet
                        : Icons.card_giftcard,
                    color: accentColor,
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
                          color: _onSurface,
                        ),
                      ),
                      SizedBox(height: isTablet ? 4 : 2),
                      Text(
                        earning.type,
                        style: TextStyle(
                          fontSize: isTablet ? 12 : 10,
                          color: _mutedText,
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
                        color: earning.status.toLowerCase() == 'pending' 
                          ? _mutedText 
                          : earning.type.toLowerCase().contains('withdraw')
                            ? Colors.red
                            : accentColor,
                      ),
                    ),
                    SizedBox(height: isTablet ? 4 : 2),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isTablet ? 8 : 6,
                        vertical: isTablet ? 4 : 2,
                      ),
                      decoration: BoxDecoration(
                        color: earning.status.toLowerCase() == 'pending' 
                          ? Colors.orange 
                          : earning.status.toLowerCase() == 'completed'
                            ? accentColor
                            : Colors.red,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        earning.status,
                        style: TextStyle(
                          color: _colorScheme.onPrimary,
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
                  color: _mutedText,
                ),
                SizedBox(width: isTablet ? 8 : 4),
                Text(
                  earning.date,
                  style: TextStyle(
                    fontSize: isTablet ? 12 : 10,
                    color: _mutedText,
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
    final code = _referralCode?.trim();
    if (code == null || code.isEmpty) {
      _showSnack(
        'Referral code not available yet.',
        background: _colorScheme.error,
      );
      return;
    }
    final normalizedCode = code.toUpperCase();
    Clipboard.setData(ClipboardData(text: normalizedCode));
    HapticFeedback.lightImpact();
    _showSnack('Referral code copied! Share it with your friends.');
  }

  Future<void> _shareReferralCode() async {
    final code = _referralCode?.trim();
    if (code == null || code.isEmpty) {
      _showSnack(
        'Referral code not available yet.',
        background: _colorScheme.error,
      );
      return;
    }

    final normalizedCode = code.toUpperCase();
    final message =
        'Join me on Gopayna and we both earn ₦6! Use my referral code: $normalizedCode when you register.';

    HapticFeedback.lightImpact();
    try {
      await Share.share(message, subject: 'Join me on Gopayna');
    } catch (_) {
      Clipboard.setData(ClipboardData(text: message));
      _showSnack('Share unavailable. Referral message copied.');
    }
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

  factory ReferralEarning.fromApi(Map<String, dynamic> json) {
    final rawType = (json['type'] ?? 'referral_bonus').toString();
    final description = (json['description'] ?? '').toString().trim();
    Map<String, dynamic>? metadata;
    if (json['metadata'] is Map) {
      metadata = Map<String, dynamic>.from(json['metadata'] as Map);
    }

    Map<String, dynamic>? referredUserMeta;
    if (metadata?['referredUser'] is Map) {
      referredUserMeta =
          Map<String, dynamic>.from(metadata!['referredUser'] as Map);
    }

    String? referredUserName;
    if (referredUserMeta != null) {
      final first = (referredUserMeta['firstName'] ?? '').toString().trim();
      final last = (referredUserMeta['lastName'] ?? '').toString().trim();
      final combined = [first, last].where((part) => part.isNotEmpty).join(' ');
      referredUserName = combined.isNotEmpty
          ? combined
          : (referredUserMeta['email'] ?? referredUserMeta['phone'] ?? '')
              .toString()
              .trim();
    }

    final fallbackTitle = description.isNotEmpty
        ? description
        : rawType == 'withdrawal'
            ? 'Referral Withdrawal'
            : rawType == 'referral_progress'
                ? 'Referral Signup'
                : 'Referral Bonus';

    final title = rawType == 'referral_progress' &&
            (referredUserName != null && referredUserName.isNotEmpty)
        ? '$referredUserName joined via your code'
        : fallbackTitle;

    return ReferralEarning(
      referredUser: title,
      amount: double.tryParse(json['amount']?.toString() ?? '') ?? 0,
      date: _formatReferralActivityDate(json['createdAt'] ?? json['created_at']),
      status: _formatReferralStatus(json['status']),
      type: _deriveReferralType(rawType),
    );
  }
}

String _formatReferralActivityDate(dynamic raw) {
  if (raw == null) {
    return '--';
  }
  final parsed = DateTime.tryParse(raw.toString());
  if (parsed == null) {
    return '--';
  }
  return DateFormat('MMM d, yyyy - hh:mm a').format(parsed.toLocal());
}

String _formatReferralStatus(dynamic raw) {
  final text = (raw ?? '').toString();
  if (text.isEmpty) {
    return 'Completed';
  }
  return text[0].toUpperCase() + text.substring(1);
}

String _deriveReferralType(String rawType) {
  switch (rawType) {
    case 'withdrawal':
      return 'Referral Withdrawal';
    case 'referral_progress':
      return 'Referral Signup';
    case 'referral_bonus':
      return 'Referral Bonus';
    default:
      return 'Referral Bonus';
  }
}

