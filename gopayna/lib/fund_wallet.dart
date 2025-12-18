import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:intl/intl.dart';

import 'api_service.dart';
import 'widgets/wallet_visibility_builder.dart';
import 'widgets/themed_screen_helpers.dart';

const _brandGreen = Color(0xFF00CA44);
const _brandGreenDeep = Color(0xFF00CA44);

class FundWalletScreen extends StatefulWidget {
  const FundWalletScreen({super.key});

  @override
  State<FundWalletScreen> createState() => _FundWalletScreenState();
}

class _FundWalletScreenState extends State<FundWalletScreen>
  with TickerProviderStateMixin, ThemedScreenHelpers {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  bool _loading = false;
  double? _walletBalance;
  bool _isVerifying = false;
  PlatformSettings? _platformSettings;
  List<Map<String, dynamic>> _quickAmounts = [
    {'amount': 1000, 'label': '₦1,000'},
    {'amount': 5000, 'label': '₦5,000'},
    {'amount': 10000, 'label': '₦10,000'},
    {'amount': 20000, 'label': '₦20,000'},
    {'amount': 30000, 'label': '₦30,000'},
    {'amount': 40000, 'label': '₦40,000'},
  ];
  final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'en_NG', symbol: '₦');
  final DateFormat _transactionDateFormat = DateFormat('MMM d, yyyy • h:mma');
  List<Map<String, dynamic>> _recentTransactions = [];
  bool _transactionsLoading = false;
  String? _transactionsError;

  String generateReference() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand = Random();
    return List.generate(15, (index) => chars[rand.nextInt(chars.length)]).join();
  }

  Future<void> _loadWalletBalance() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt');
    if (token == null) return;
    final balance = await fetchWalletBalance(token);
    await _loadRecentTransactions(token: token);
    if (!mounted) return;
    setState(() => _walletBalance = balance);
  }

  Future<void> _loadRecentTransactions({String? token}) async {
    token ??= await _getAuthToken();
    if (token == null) return;
    if (!mounted) return;
    setState(() {
      _transactionsLoading = true;
      _transactionsError = null;
    });
    final response = await fetchWalletTransactions(token: token, limit: 8);
    if (!mounted) return;
    if (response['error'] != null) {
      setState(() {
        _transactionsError = response['error'].toString();
        _transactionsLoading = false;
      });
      return;
    }
    final dataRaw = response['data'] as List<dynamic>? ?? [];
    final data = dataRaw.cast<Map<String, dynamic>>();
    setState(() {
      _recentTransactions = data;
      _transactionsLoading = false;
    });
  }

  Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt');
    if (token == null) {
      if (!mounted) return null;
      _showSnack('Please log in again to continue.', isError: true);
    }
    return token;
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? colorScheme.error : _brandGreen,
      ),
    );
  }

  void _selectQuickAmount(int amount) {
    _amountController.text = amount.toString();
    setState(() {});
  }

  void _onAmountChanged(String value) {
    setState(() {});
  }

  void _fundWallet() async {
    if (_loading || _isVerifying) return;
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final amount = int.tryParse(_amountController.text);
    if (amount == null) {
      _showSnack('Enter a valid amount', isError: true);
      return;
    }

    // Use dynamic settings (fallback to defaults)
    final settings = _platformSettings ?? PlatformSettings.defaults;
    final maxFunding = settings.maxFundingAmount.toInt();
    final maxWallet = settings.maxWalletBalance.toInt();
    final minFunding = settings.minFundingAmount.toInt();

    if (amount < minFunding) {
      _showSnack('Minimum funding amount is ₦$minFunding.', isError: true);
      return;
    }

    if (amount > maxFunding) {
      _showSnack('Maximum funding per transaction is ₦${_currencyFormat.format(maxFunding).replaceAll('₦', '').trim()}.', isError: true);
      return;
    }

    final currentBalance = _walletBalance ?? 0;
    if (currentBalance + amount > maxWallet) {
      _showSnack('Wallet balance cannot exceed ₦${_currencyFormat.format(maxWallet).replaceAll('₦', '').trim()}. Reduce the amount and try again.', isError: true);
      return;
    }

    final confirmed = await _showFundingPreview(amount, currentBalance);
    if (confirmed != true) {
      return;
    }

    // Send base amount - backend calculates fee and sends total to Paystack
    await _startPaystackPayment(amount: amount);
  }

  double _calculatePaystackFee(int amount) {
    if (amount <= 2500) {
      return amount * 0.015;
    }
    return (amount * 0.015) + 100;
  }

  Future<bool?> _showFundingPreview(int amount, double currentBalance) {
    final fee = _calculatePaystackFee(amount);
    final total = amount + fee;
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Funding'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPreviewRow('Current balance', '₦${currentBalance.toStringAsFixed(2)}'),
              _buildPreviewRow('Amount to fund', '₦${amount.toStringAsFixed(2)}'),
              _buildPreviewRow('Paystack fee', '₦${fee.toStringAsFixed(2)}'),
              const Divider(height: 24),
              _buildPreviewRow(
                'Total to pay',
                '₦${total.toStringAsFixed(2)}',
                valueStyle: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: _brandGreen,
                foregroundColor: Colors.white,
                alignment: Alignment.center,
              ),
              child: const Text(
                'Continue to Paystack',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPreviewRow(String label, String value, {TextStyle? valueStyle}) {
    final muted = mutedTextColor;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(fontSize: 14, color: muted),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              style: valueStyle ?? const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(num value) => _currencyFormat.format(value);

  String _formatTransactionDate(String? isoString) {
    if (isoString == null) {
      return '--';
    }
    try {
      final date = DateTime.parse(isoString).toLocal();
      return _transactionDateFormat.format(date);
    } catch (_) {
      return isoString;
    }
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'success':
        return 'Successful';
      case 'failed':
        return 'Failed';
      default:
        return 'Pending';
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'success':
        return _brandGreen;
      case 'failed':
        return colorScheme.error;
      default:
        return colorScheme.tertiary;
    }
  }

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'success':
        return Icons.check_circle;
      case 'failed':
        return Icons.error;
      default:
        return Icons.schedule;
    }
  }

  Widget _buildTransactionTile(Map<String, dynamic> tx) {
    final status = (tx['status'] ?? 'pending').toString();
    final amount = double.tryParse(tx['amount']?.toString() ?? '') ?? 0;
    final reference = (tx['reference'] ?? '--').toString();
    final createdAt = tx['created_at']?.toString();
    final channel = (tx['channel'] ?? 'Paystack').toString();
    final card = cardColor;
    final muted = mutedTextColor;
    final border = borderColor;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _statusColor(status).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _statusIcon(status),
              color: _statusColor(status),
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        _formatCurrency(amount),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        _formatTransactionDate(createdAt),
                        style: TextStyle(fontSize: 12, color: muted),
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${_statusLabel(status)} - $channel',
                        style:
                            TextStyle(fontSize: 13, color: _statusColor(status)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Ref: ${reference.length > 12 ? reference.substring(reference.length - 12) : reference}',
                        style: TextStyle(fontSize: 12, color: muted),
                        textAlign: TextAlign.end,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startPaystackPayment({required int amount}) async {
    if (_loading || _isVerifying) return;

    final token = await _getAuthToken();
    if (token == null) {
      return;
    }

    setState(() => _loading = true);

    final initResponse = await initializePaystackPayment(
      token: token,
      amount: amount,
      reference: generateReference(),
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (initResponse['error'] != null) {
      _showSnack(initResponse['error'].toString(), isError: true);
      return;
    }

    final data = initResponse['data'] as Map<String, dynamic>?;
    final checkoutUrl = data?['authorization_url'] as String?;
    final reference = (data?['reference'] ?? data?['data']?['reference'])?.toString();
    final callbackUrl = data?['callback_url'] as String?;

    if (checkoutUrl == null || reference == null) {
      _showSnack('Unable to start Paystack checkout. Please try again.', isError: true);
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PaystackWebViewPage(
          authorizationUrl: checkoutUrl,
          reference: reference,
          callbackUrl: callbackUrl,
        ),
      ),
    );

    await _verifyAndFinalize(token, reference);
  }

  Future<void> _verifyAndFinalize(String token, String reference) async {
    setState(() {
      _loading = true;
      _isVerifying = true;
    });

    final verifyResult = await verifyPaystackPayment(token: token, reference: reference);

    if (!mounted) return;
    setState(() {
      _loading = false;
      _isVerifying = false;
    });

    if (verifyResult['error'] != null) {
      _showSnack(verifyResult['error'].toString(), isError: true);
      return;
    }

    final data = verifyResult['data'] as Map<String, dynamic>? ?? {};
    final walletBalanceValue = data['wallet_balance'];
    if (walletBalanceValue != null) {
      final parsed = double.tryParse(walletBalanceValue.toString());
      if (parsed != null && mounted) {
        setState(() => _walletBalance = parsed);
      }
    } else {
      await _loadWalletBalance();
    }

    await _loadRecentTransactions(token: token);

    final transaction = data['transaction'] as Map<String, dynamic>?;
    final creditedAmount = transaction != null
        ? double.tryParse(transaction['amount'].toString())
        : null;

    _amountController.clear();
    await _showSuccessDialog(creditedAmount);
  }

  Future<void> _showSuccessDialog(double? amount) async {
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Payment Verified'),
        content: Text(
          amount != null
              ? 'Your wallet has been credited with ₦${amount.toStringAsFixed(2)}.'
              : 'Your wallet has been credited successfully.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactionsSection() {
    final card = cardColor;
    final shadow = shadowColor;
    final muted = mutedTextColor;
    final cs = colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Wallet Activity',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            IconButton(
              tooltip: 'Refresh',
              onPressed: _transactionsLoading ? null : () => _loadRecentTransactions(),
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: shadow,
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: _transactionsLoading
              ? const Center(child: CircularProgressIndicator())
              : _transactionsError != null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _transactionsError!,
                          style: TextStyle(color: cs.error),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: () => _loadRecentTransactions(),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Try again'),
                        ),
                      ],
                    )
                  : _recentTransactions.isEmpty
                      ? Text(
                          'Your wallet transactions will appear here once you start funding.',
                          style: TextStyle(color: muted),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemBuilder: (context, index) => _buildTransactionTile(_recentTransactions[index]),
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemCount: _recentTransactions.length,
                        ),
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_fadeController);
    _slideAnimation = Tween<Offset>(begin: const Offset(0.0, 0.1), end: Offset.zero).animate(_slideController);
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(_scaleController);

    // Start the animations
    _fadeController.forward();
    _slideController.forward();
    _scaleController.forward();

    // Load platform settings and wallet balance
    _loadPlatformSettings();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadWalletBalance());
  }

  Future<void> _loadPlatformSettings() async {
    final settings = await fetchPlatformSettings();
    if (!mounted) return;
    setState(() {
      _platformSettings = settings;
      // Update quick amounts if max funding is different from default
      final maxFunding = settings.maxFundingAmount.toInt();
      if (maxFunding != 40000) {
        _quickAmounts = [
          {'amount': 1000, 'label': '₦1,000'},
          {'amount': 5000, 'label': '₦5,000'},
          {'amount': 10000, 'label': '₦10,000'},
          {'amount': 20000, 'label': '₦20,000'},
          if (maxFunding >= 30000) {'amount': 30000, 'label': '₦30,000'},
          if (maxFunding >= 40000) {'amount': maxFunding, 'label': '₦${_currencyFormat.format(maxFunding).replaceAll('₦', '').trim()}'},
        ];
      }
    });
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
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final cs = colorScheme;
    final card = cardColor;
    final muted = mutedTextColor;
    final shadow = shadowColor;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.primary,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back_ios,
            color: cs.onPrimary,
            size: 20,
          ),
        ),
        title: Text(
          'Fund Wallet',
          style: TextStyle(
            color: cs.onPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        systemOverlayStyle: statusBarStyle,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isTablet ? 32 : 20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Current Balance Card
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [_brandGreen, _brandGreenDeep],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: _brandGreen.withValues(alpha: 0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: cs.onPrimary.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.account_balance_wallet,
                                  color: cs.onPrimary,
                                  size: 24,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: cs.onPrimary.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'Main Wallet',
                                  style: TextStyle(
                                    color: cs.onPrimary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Current Balance',
                            style: TextStyle(
                              color: cs.onPrimary.withValues(alpha: 0.9),
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 8),
                          WalletVisibilityBuilder(
                            builder: (_, showBalance) => Text(
                              showBalance
                                  ? '₦${_walletBalance?.toStringAsFixed(2) ?? '0.00'}'
                                  : '************',
                              style: TextStyle(
                                color: cs.onPrimary,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),

                  // Amount Section
                  Text(
                    'Amount',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Quick Amount Selection
                  Container(
                    decoration: BoxDecoration(
                      color: card,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: shadow,
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Quick Select',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: muted,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: _quickAmounts.map((item) {
                            return GestureDetector(
                              onTap: () => _selectQuickAmount(item['amount']),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: _brandGreen.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: _brandGreen.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Text(
                                  item['label'],
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: _brandGreen,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Custom Amount Input
                  Container(
                    decoration: BoxDecoration(
                      color: card,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: shadow,
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextFormField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: _onAmountChanged,
                      decoration: InputDecoration(
                        labelText: 'Enter Amount',
                        prefixText: '₦ ',
                        prefixStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _brandGreen,
                        ),
                        border: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(16)),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: card,
                        contentPadding: const EdgeInsets.all(20),
                      ),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter an amount';
                        }
                        final amount = int.tryParse(value);
                        final settings = _platformSettings ?? PlatformSettings.defaults;
                        final minFunding = settings.minFundingAmount.toInt();
                        final maxFunding = settings.maxFundingAmount.toInt();
                        if (amount == null || amount < minFunding) {
                          return 'Minimum amount is ₦$minFunding';
                        }
                        if (amount > maxFunding) {
                          return 'Maximum amount you can fund at a time is ₦${_currencyFormat.format(maxFunding).replaceAll('₦', '').trim()}';
                        }
                        return null;
                      },
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Fund Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _fundWallet,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _brandGreen,
                        foregroundColor: cs.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 8,
                        shadowColor: _brandGreen.withValues(alpha: 0.3),
                      ),
                      child: _loading
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(cs.onPrimary),
                              ),
                            )
                          : const Text(
                              'Fund Wallet',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  _buildRecentTransactionsSection(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PaystackWebViewPage extends StatefulWidget {
  final String authorizationUrl;
  final String reference;
  final String? callbackUrl;

  const PaystackWebViewPage({
    super.key,
    required this.authorizationUrl,
    required this.reference,
    this.callbackUrl,
  });

  @override
  State<PaystackWebViewPage> createState() => _PaystackWebViewPageState();
}

class _PaystackWebViewPageState extends State<PaystackWebViewPage> {
  WebViewController? _controller;
  bool _pageLoading = true;
  bool _callbackReached = false;
  bool _externalCheckoutLaunched = false;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _launchExternalCheckout();
      return;
    }

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _pageLoading = true),
          onPageFinished: (_) => setState(() => _pageLoading = false),
          onNavigationRequest: (NavigationRequest request) {
            if (widget.callbackUrl != null && request.url.startsWith(widget.callbackUrl!)) {
              _callbackReached = true;
              Navigator.of(context).pop({'completed': true, 'reference': widget.reference});
              return NavigationDecision.prevent;
            }

            if (request.url.contains('close')) {
              Navigator.of(context).pop({'completed': _callbackReached, 'reference': widget.reference});
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.authorizationUrl));
  }

  Future<void> _launchExternalCheckout() async {
    final launched = await launchUrlString(
      widget.authorizationUrl,
      webOnlyWindowName: '_blank',
    );
    setState(() {
      _externalCheckoutLaunched = launched;
      _pageLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          Navigator.of(context).pop({
            'completed': _callbackReached,
            'reference': widget.reference,
          });
        },
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Pay with Paystack'),
            actions: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop({
                  'completed': _callbackReached,
                  'reference': widget.reference,
                }),
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _externalCheckoutLaunched
                      ? 'Complete your payment in the newly opened Paystack tab, then click the button below so we can verify it.'
                      : 'We could not automatically open the Paystack checkout. Use the button below to open it in a new tab.',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () async {
                    final ok = await launchUrlString(
                      widget.authorizationUrl,
                      webOnlyWindowName: '_blank',
                    );
                    if (ok) {
                      setState(() => _externalCheckoutLaunched = true);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.open_in_new, color: Colors.white),
                  label: const Text(
                    'Open Paystack Checkout',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    _callbackReached = true;
                    Navigator.of(context).pop({
                      'completed': true,
                      'reference': widget.reference,
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text(
                    'I have completed payment',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop({
                      'completed': false,
                      'reference': widget.reference,
                    });
                  },
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        Navigator.of(context).pop({
          'completed': _callbackReached,
          'reference': widget.reference,
        });
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Pay with Paystack'),
          actions: [
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop({
                'completed': _callbackReached,
                'reference': widget.reference,
              }),
            ),
          ],
        ),
        body: Stack(
          children: [
            if (_controller != null) WebViewWidget(controller: _controller!),
            if (_pageLoading)
              const Align(
                alignment: Alignment.topCenter,
                child: LinearProgressIndicator(minHeight: 2),
              ),
          ],
        ),
      ),
    );
  }
}



