import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_service.dart';
import 'setting.dart';
import 'widgets/themed_screen_helpers.dart';
import 'widgets/wallet_visibility_builder.dart';

const _brandGreen = Color(0xFF00CA44);
const _brandGreenDeep = Color(0xFF00CA44);

class WithdrawFundScreen extends StatefulWidget {
  const WithdrawFundScreen({super.key});

  @override
  State<WithdrawFundScreen> createState() => _WithdrawFundScreenState();
}

class _WithdrawFundScreenState extends State<WithdrawFundScreen>
    with ThemedScreenHelpers {
  final _formKey = GlobalKey<FormState>();
  final _accountNumberController = TextEditingController();
  final _amountController = TextEditingController();
  final _pinController = TextEditingController();

  PaystackBank? _selectedBank;
  List<PaystackBank> _banks = [];
  String? _banksError;
  bool _pinSet = false;
  bool _pinStatusLoading = false;
  String? _pinStatusError;

  double _availableBalance = 0;
  bool _isLoading = false;
  bool _balanceRefreshing = false;
  bool _verifyingAccount = false;
  bool _accountVerified = false;
  String? _accountName;
  VerifiedAccount? _verifiedAccount;

  String? _token;
  bool _bootstrapping = true;
  String? _sessionError;

  @override
  void initState() {
    super.initState();
    _bootstrap();
    _accountNumberController.addListener(_invalidateAccountVerification);
    _pinController.addListener(_handlePinChange);
  }

  @override
  void dispose() {
    _accountNumberController.dispose();
    _amountController.dispose();
    _pinController.removeListener(_handlePinChange);
    _pinController.dispose();
    super.dispose();
  }

  void _handlePinChange() {
    if (!mounted) return;
    setState(() {});
  }

  void _invalidateAccountVerification() {
    if (_accountVerified || _accountName != null || _verifiedAccount != null) {
      setState(() {
        _accountVerified = false;
        _accountName = null;
        _verifiedAccount = null;
      });
    }
  }

  Future<void> _bootstrap() async {
    final prefs = await SharedPreferences.getInstance();
    final storedToken = prefs.getString('jwt');
    if (!mounted) return;

    if (storedToken == null || storedToken.isEmpty) {
      setState(() {
        _bootstrapping = false;
        _sessionError =
            'Session expired. Please sign in again to withdraw funds.';
      });
      return;
    }

    setState(() {
      _token = storedToken;
      _sessionError = null;
    });
    await _refreshWalletBalance(tokenOverride: storedToken);
    _loadStaticBanks();
    await _loadPinStatus(tokenOverride: storedToken);
    if (mounted) {
      setState(() => _bootstrapping = false);
    }
  }

  Future<String?> _ensureToken() async {
    if (_token != null && _token!.isNotEmpty) {
      return _token;
    }
    final prefs = await SharedPreferences.getInstance();
    final storedToken = prefs.getString('jwt');
    if (storedToken == null || storedToken.isEmpty) {
      if (mounted) {
        setState(() {
          _sessionError = 'Session expired. Please sign in again.';
        });
        _showSnack('Please sign in again to continue.');
      }
      return null;
    }
    if (mounted) {
      setState(() {
        _token = storedToken;
        _sessionError = null;
      });
    }
    return storedToken;
  }

  Future<void> _refreshWalletBalance({String? tokenOverride}) async {
    final token = tokenOverride ?? await _ensureToken();
    if (token == null) return;
    if (mounted) {
      setState(() => _balanceRefreshing = true);
    }
    final balance = await fetchWalletBalance(token);
    if (!mounted) return;
    setState(() {
      if (balance != null) {
        _availableBalance = balance;
      }
      _balanceRefreshing = false;
    });
  }

  Future<void> _loadPinStatus({String? tokenOverride}) async {
    final token = tokenOverride ?? await _ensureToken();
    if (token == null) return;
    if (mounted) {
      setState(() {
        _pinStatusLoading = true;
        _pinStatusError = null;
      });
    }
    final response = await fetchWithdrawalPinStatus(token: token);
    if (!mounted) return;
    if (response['error'] != null) {
      setState(() {
        _pinStatusLoading = false;
        _pinStatusError = response['error'].toString();
      });
      return;
    }
    final pinSet = response['pinSet'] == true ||
        response['pin_set'] == true ||
        (response['data'] is Map && response['data']['pinSet'] == true);
    setState(() {
      _pinSet = pinSet;
      _pinStatusLoading = false;
      _pinStatusError = null;
    });
  }

  Future<void> _openWithdrawalPinSettings() async {
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const SettingScreen(
          launchWithdrawalPinSection: true,
        ),
      ),
    );
    if (mounted) {
      await _loadPinStatus();
    }
  }

  void _loadStaticBanks() {
    if (_banks.isNotEmpty) return;
    _banks = _nigerianBanks;
    setState(() {});
  }

  static const List<PaystackBank> _nigerianBanks = [
    PaystackBank(name: 'Access Bank', code: '044', country: 'Nigeria'),
    PaystackBank(name: 'Citibank Nigeria', code: '023', country: 'Nigeria'),
    PaystackBank(name: 'Ecobank Nigeria', code: '050', country: 'Nigeria'),
    PaystackBank(name: 'Fidelity Bank', code: '070', country: 'Nigeria'),
    PaystackBank(
        name: 'First Bank of Nigeria', code: '011', country: 'Nigeria'),
    PaystackBank(
        name: 'First City Monument Bank', code: '214', country: 'Nigeria'),
    PaystackBank(name: 'Guaranty Trust Bank', code: '058', country: 'Nigeria'),
    PaystackBank(name: 'Heritage Bank', code: '030', country: 'Nigeria'),
    PaystackBank(name: 'Keystone Bank', code: '082', country: 'Nigeria'),
    PaystackBank(name: 'Polaris Bank', code: '076', country: 'Nigeria'),
    PaystackBank(name: 'Providus Bank', code: '101', country: 'Nigeria'),
    PaystackBank(name: 'Stanbic IBTC Bank', code: '221', country: 'Nigeria'),
    PaystackBank(
        name: 'Standard Chartered Bank', code: '068', country: 'Nigeria'),
    PaystackBank(name: 'Sterling Bank', code: '232', country: 'Nigeria'),
    PaystackBank(
        name: 'Union Bank of Nigeria', code: '032', country: 'Nigeria'),
    PaystackBank(
        name: 'United Bank For Africa', code: '033', country: 'Nigeria'),
    PaystackBank(name: 'Unity Bank', code: '215', country: 'Nigeria'),
    PaystackBank(name: 'Wema Bank', code: '035', country: 'Nigeria'),
    PaystackBank(name: 'Zenith Bank', code: '057', country: 'Nigeria'),
    PaystackBank(name: 'Kuda Bank', code: '50211', country: 'Nigeria'),
    PaystackBank(name: 'Opay', code: '999992', country: 'Nigeria'),
    PaystackBank(name: 'PalmPay', code: '999991', country: 'Nigeria'),
    PaystackBank(name: 'Moniepoint', code: '50515', country: 'Nigeria'),
  ];

  Future<void> _verifyAccount() async {
    FocusScope.of(context).unfocus();
    final accountNumber = _accountNumberController.text.trim();
    if (accountNumber.length != 10) {
      _showSnack('Enter a valid 10-digit account number.');
      return;
    }
    final bank = _selectedBank;
    if (bank == null) {
      _showSnack('Please select your bank first.');
      return;
    }
    final token = await _ensureToken();
    if (token == null) return;

    setState(() {
      _verifyingAccount = true;
    });

    final response = await resolveBankAccount(
      token: token,
      accountNumber: accountNumber,
      bankCode: bank.code,
    );

    if (!mounted) return;
    setState(() {
      _verifyingAccount = false;
    });

    if (response['error'] != null) {
      _showSnack(response['error'].toString());
      return;
    }

    final data = response['data'] as Map<String, dynamic>?;
    final resolvedName = data?['account_name']?.toString() ?? '';
    final verified = VerifiedAccount(
      accountNumber: accountNumber,
      accountName: resolvedName.isEmpty ? 'Verified Account' : resolvedName,
      bankCode: bank.code,
      bankName: bank.name,
    );

    setState(() {
      _accountVerified = true;
      _accountName = verified.accountName;
      _verifiedAccount = verified;
    });

    _showSnack('Account verified successfully.', isError: false);
  }

  String? _validateAmount(double? amount) {
    if (amount == null || amount.isNaN) {
      return 'Please enter the amount you wish to withdraw.';
    }
    if (amount <= 0) {
      return 'Please enter the amount you wish to withdraw.';
    }
    if (amount < 1000) {
      return 'Minimum withdrawal amount is ₦1,000.';
    }
    if (amount > _availableBalance) {
      return 'Insufficient balance.';
    }
    return null;
  }

  bool get _pinInputComplete => _pinController.text.trim().length == 4;

  void _withdrawFunds() {
    FocusScope.of(context).unfocus();
    if (_isLoading) return;
    if (_formKey.currentState?.validate() != true) return;
    if (!_accountVerified || _verifiedAccount == null) {
      _showSnack('Please verify the beneficiary account before withdrawing.');
      return;
    }
    final amountValue = double.tryParse(_amountController.text.trim());
    final amountError = _validateAmount(amountValue);
    if (amountError != null) {
      _showSnack(amountError);
      return;
    }
    final amount = amountValue!;
    final pin = _pinController.text.trim();
    if (!_pinSet) {
      _showSnack('Set your 4-digit withdrawal PIN before making withdrawals.');
      _promptSetPin(
        'Your account needs a withdrawal PIN. Request an OTP from the security section to create one.',
      );
      return;
    }
    if (pin.length != 4) {
      _showSnack('Enter your 4-digit transaction PIN.');
      return;
    }
    _processWithdrawal(amount: amount, pin: pin);
  }

  Future<void> _processWithdrawal(
      {required double amount, required String pin}) async {
    final token = await _ensureToken();
    final account = _verifiedAccount;
    if (token == null || account == null) {
      return;
    }

    setState(() => _isLoading = true);

    final response = await withdrawToBank(
      token: token,
      amount: amount,
      accountNumber: account.accountNumber,
      bankCode: account.bankCode,
      bankName: account.bankName,
      accountName: account.accountName,
      pin: pin,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (response['error'] != null) {
      final errorMessage = response['error'].toString();
      _showSnack(errorMessage);
      if (errorMessage.toLowerCase().contains('set your withdrawal pin')) {
        _promptSetPin(errorMessage);
      }
      return;
    }

    final data = response['data'] as Map<String, dynamic>? ??
        response as Map<String, dynamic>? ??
        {};
    final message = data['message']?.toString() ??
        'Withdrawal request submitted successfully.';
    final newBalanceRaw = data['wallet_balance'] ?? data['walletBalance'];
    final newBalance = newBalanceRaw == null
        ? null
        : double.tryParse(newBalanceRaw.toString());
    if (newBalance != null) {
      setState(() => _availableBalance = newBalance);
    } else {
      await _refreshWalletBalance(tokenOverride: token);
    }

    _amountController.clear();
    _pinController.clear();
    final transaction = data['transaction'] as Map<String, dynamic>?;
    final txStatus = transaction?['status']?.toString().toLowerCase();
    final normalizedMessage = message.toLowerCase();
    final isPending = txStatus == 'pending' ||
        normalizedMessage.contains('processing') ||
        normalizedMessage.contains('notified') ||
        normalizedMessage.contains('being processed');

    if (isPending) {
      await _showPendingDialog(amount, message: message);
    } else {
      await _showSuccessDialog(amount, message: message);
    }
  }

  void _promptSetPin(String message) {
    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Withdrawal PIN'),
        content: Text(
          '$message\n\nHead to the security section to request an OTP and create your transaction PIN.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _showSuccessDialog(double amount, {required String message}) {
    final cs = colorScheme;
    final card = cardColor;
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_brandGreen, _brandGreenDeep],
            ),
            boxShadow: [
              BoxShadow(
                color: _brandGreen.withValues(alpha: 0.25),
                offset: const Offset(0, 12),
                blurRadius: 30,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 80,
                width: 80,
                decoration: BoxDecoration(
                  color: cs.onPrimary.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_circle, color: cs.onPrimary, size: 48),
              ),
              const SizedBox(height: 16),
              Text(
                'Withdrawal Successful!',
                style: TextStyle(
                  color: cs.onPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message.isNotEmpty
                    ? message
                    : 'Your withdrawal of ₦${amount.toStringAsFixed(2)} has been processed.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: cs.onPrimary.withValues(alpha: 0.9),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: card,
                    foregroundColor: _brandGreen,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showPendingDialog(double amount, {required String message}) {
    final cs = colorScheme;
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.hourglass_top, color: cs.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Withdrawal Processing',
                style: Theme.of(context).textTheme.titleMedium,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: TextStyle(color: cs.onSurface, fontSize: 14),
            ),
            const SizedBox(height: 12),
            Text(
              'Amount: ₦${amount.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Row(
              children: const [
                Expanded(
                  child: Text(
                    'We will notify you once Paystack confirms this transfer.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
                SizedBox(width: 12),
                SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _showSnack(String message, {bool isError = true}) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : _brandGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = colorScheme;
    final card = cardColor;
    final muted = mutedTextColor;
    final shadow = shadowColor;
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.primary,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back, color: cs.onPrimary),
        ),
        title: Text(
          'Withdraw Funds',
          style: TextStyle(color: cs.onPrimary, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        systemOverlayStyle: statusBarStyle,
      ),
      body: SafeArea(
        child: _bootstrapping
            ? const Center(child: CircularProgressIndicator())
            : _sessionError != null
                ? _buildSessionError(cs)
                : SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 32 : 20,
                      vertical: 24,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildBalanceHeader(muted),
                          const SizedBox(height: 16),
                          if (_pinStatusLoading ||
                              !_pinSet ||
                              _pinStatusError != null) ...[
                            _buildPinStatusBanner(cs, muted),
                            const SizedBox(height: 16),
                          ],
                          const SizedBox(height: 8),
                          _buildSectionHeader(
                            'Beneficiary Details',
                            muted,
                            icon: Icons.account_balance,
                            subtitle:
                                'Enter a valid 10-digit account and select a bank, then tap verify.',
                          ),
                          const SizedBox(height: 12),
                          _buildAccountNumberField(card, shadow),
                          const SizedBox(height: 16),
                          _buildBankField(card, shadow),
                          const SizedBox(height: 12),
                          _buildVerifyButton(),
                          _buildVerificationStatusText(muted),
                          const SizedBox(height: 24),
                          if (_accountVerified) ...[
                            _buildAccountSummaryCard(cs, muted),
                            const SizedBox(height: 24),
                            _buildSectionHeader(
                              'Withdrawal Details',
                              muted,
                              icon: Icons.payments,
                              subtitle:
                                  'Enter the amount to withdraw and confirm with your PIN.',
                            ),
                            const SizedBox(height: 12),
                            _buildAmountCard(cs),
                            const SizedBox(height: 20),
                            _buildPinField(card, shadow),
                            const SizedBox(height: 24),
                            _buildSubmitButton(),
                          ],
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }

  Widget _buildPinStatusBanner(ColorScheme cs, Color muted) {
    if (_pinStatusLoading) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Checking your withdrawal PIN status…',
                style: TextStyle(fontSize: 13, color: muted),
              ),
            ),
          ],
        ),
      );
    }

    if (_pinStatusError != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.error.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.error.withValues(alpha: 0.3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline, color: cs.error),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _pinStatusError!,
                    style:
                        TextStyle(color: cs.error, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Retry to confirm whether your withdrawal PIN is already set.',
                    style: TextStyle(color: cs.onSurface, fontSize: 13),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: _loadPinStatus,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_pinSet) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.lock_outline, color: Colors.orange),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Set your withdrawal PIN',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'You need a 4-digit PIN (protected by OTP) before you can send funds to a bank account.',
            style: TextStyle(fontSize: 13, color: cs.onSurface),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              ElevatedButton.icon(
                onPressed: _openWithdrawalPinSettings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _brandGreen,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.settings),
                label: const Text('Set/Reset Withdrawal PIN'),
              ),
              OutlinedButton(
                onPressed: _loadPinStatus,
                child: const Text('I have set my PIN'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color muted,
      {String? subtitle, IconData icon = Icons.checklist}) {
    final cs = colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: _brandGreen, size: 18),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(fontSize: 13, color: muted),
          ),
        ],
      ],
    );
  }

  Widget _buildVerificationStatusText(Color muted) {
    if (!_verifyingAccount && !_accountVerified) {
      return const SizedBox.shrink();
    }

    IconData icon;
    Color color;
    String text;

    if (_verifyingAccount) {
      icon = Icons.hourglass_top;
      color = Colors.orange;
      text = 'Verifying account with Paystack…';
    } else {
      icon = Icons.verified;
      color = _brandGreen;
      text = 'Account verified successfully. You can proceed.';
    }

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 12, color: color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceHeader(Color muted) {
    return WalletVisibilityBuilder(
      builder: (_, showBalance) {
        final balanceText = showBalance
            ? '₦${_availableBalance.toStringAsFixed(2)}'
            : '*************';
        return Row(
          children: [
            Expanded(
              child: Text(
                'Wallet Balance: $balanceText (Min withdrawal ₦1,000)',
                style: TextStyle(
                  fontSize: 13,
                  color: muted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            IconButton(
              onPressed:
                  _balanceRefreshing ? null : () => _refreshWalletBalance(),
              icon: _balanceRefreshing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh, size: 20),
              color: _brandGreen,
              tooltip: 'Refresh balance',
            ),
          ],
        );
      },
    );
  }

  Widget _buildSessionError(ColorScheme cs) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline, size: 48, color: cs.error),
            const SizedBox(height: 16),
            Text(
              _sessionError ?? 'Please sign in again to continue.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: cs.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _bootstrap,
              style: ElevatedButton.styleFrom(
                backgroundColor: _brandGreen,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountNumberField(Color card, Color shadow) {
    return Container(
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
        controller: _accountNumberController,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(10),
        ],
        decoration: const InputDecoration(
          labelText: 'Account Number',
          prefixIcon: Icon(Icons.tag, color: _brandGreen),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: EdgeInsets.all(20),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter the account number';
          }
          if (value.length != 10) {
            return 'Account number must be 10 digits';
          }
          return null;
        },
        onChanged: (_) => _invalidateAccountVerification(),
      ),
    );
  }

  Widget _buildBankField(Color card, Color shadow) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownSearch<PaystackBank>(
          items: _banks,
          selectedItem: _selectedBank,
          enabled: !_accountVerified,
          itemAsString: (bank) => bank.name,
          validator: (_) {
            if (_accountVerified || _selectedBank != null) {
              return null;
            }
            return 'Please select your bank';
          },
          onChanged: (bank) {
            if (bank == null) return;
            setState(() {
              _selectedBank = bank;
            });
            _invalidateAccountVerification();
          },
          dropdownButtonProps: const DropdownButtonProps(
            icon: Icon(Icons.keyboard_arrow_down_rounded),
          ),
          popupProps: PopupProps.menu(
            showSearchBox: true,
            itemBuilder: (context, bank, isSelected) => ListTile(
              title: Text(bank.name),
              subtitle: bank.longCode == null ? null : Text(bank.longCode!),
              trailing: isSelected ? const Icon(Icons.check) : null,
            ),
            searchFieldProps: TextFieldProps(
              decoration: InputDecoration(
                hintText: 'Search bank...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            emptyBuilder: (context, _) => const Padding(
              padding: EdgeInsets.all(16),
              child: Text('No banks found.'),
            ),
          ),
          dropdownBuilder: (context, bank) {
            final label = bank?.name ?? 'Select Bank';
            return Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            );
          },
          dropdownDecoratorProps: DropDownDecoratorProps(
            dropdownSearchDecoration: InputDecoration(
              labelText: 'Select Bank',
              prefixIcon: const Icon(Icons.account_balance, color: _brandGreen),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              filled: true,
              fillColor: card,
            ),
          ),
        ),
        if (_banksError != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _banksError!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildVerifyButton() {
    final canVerify = !_verifyingAccount &&
        !_accountVerified &&
        _selectedBank != null &&
        _accountNumberController.text.trim().length == 10;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: canVerify ? _verifyAccount : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: _brandGreen.withValues(alpha: 0.1),
          foregroundColor: _brandGreen,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: _verifyingAccount
            ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(_accountVerified ? 'Account Verified' : 'Verify Account'),
      ),
    );
  }

  Widget _buildAccountSummaryCard(ColorScheme cs, Color muted) {
    final summary = _verifiedAccount;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _brandGreen.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                _accountVerified ? 'Account verified' : 'Awaiting verification',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _accountVerified
                      ? _brandGreen.withValues(alpha: 0.15)
                      : cs.error.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _accountVerified ? 'Ready' : 'Action needed',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _accountVerified ? _brandGreen : cs.error,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Account Name: ${summary?.accountName ?? _accountName ?? 'Not verified'}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Bank: ${summary?.bankName ?? _selectedBank?.name ?? 'Not selected'}',
            style: TextStyle(fontSize: 14, color: muted),
          ),
          const SizedBox(height: 4),
          Text(
            'Account Number: ${_accountNumberController.text.isEmpty ? '--' : _accountNumberController.text}',
            style: TextStyle(fontSize: 14, color: muted),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountCard(ColorScheme cs) {
    final amountText = _amountController.text.trim();
    final amountValue = double.tryParse(amountText);
    final validation = amountText.isEmpty ? null : _validateAmount(amountValue);
    final isValid = validation == null;
    final suffixIcon = amountText.isEmpty
        ? null
        : Icon(
            isValid ? Icons.check_circle : Icons.error,
            color: isValid ? Colors.green : cs.error,
          );

    return WalletVisibilityBuilder(
      builder: (_, showBalance) {
        final helperText =
            'Minimum withdrawal amount is ₦1,000 | Available: ${showBalance ? '₦${_availableBalance.toStringAsFixed(2)}' : '*************'}';
        return TextFormField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            labelText: 'Amount to Withdraw (Min: ₦1,000)',
            prefixIcon: const Icon(Icons.money, color: _brandGreen),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            helperText: helperText,
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: Theme.of(context).cardColor,
          ),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: cs.onSurface,
          ),
          validator: (value) => _validateAmount(double.tryParse(value ?? '')),
          onChanged: (_) => setState(() {}),
        );
      },
    );
  }

  Widget _buildPinField(Color card, Color shadow) {
    return Container(
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
        controller: _pinController,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(4),
        ],
        obscureText: true,
        decoration: const InputDecoration(
          labelText: 'Enter Transaction PIN',
          prefixIcon: Icon(Icons.lock, color: _brandGreen),
          suffixText: '4/4',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: EdgeInsets.all(20),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter your transaction PIN';
          }
          if (value.length != 4) {
            return 'PIN must be 4 digits';
          }
          return null;
        },
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Widget _buildSubmitButton() {
    final canSubmit =
        !_isLoading && _accountVerified && _pinSet && _pinInputComplete;
    final child = _isLoading
        ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          )
        : const Text(
            'Confirm & Withdraw',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton(
          onPressed: canSubmit ? _withdrawFunds : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: _brandGreen,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: canSubmit ? 8 : 0,
            shadowColor: _brandGreen.withValues(alpha: 0.3),
          ),
          child: child,
        ),
        if (!_pinSet)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: GestureDetector(
              onTap: _openWithdrawalPinSettings,
              child: Text(
                'Set/Reset your withdrawal PIN to enable this action.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.orange.shade700,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class PaystackBank {
  final String name;
  final String code;
  final String? longCode;
  final String? slug;
  final String? country;

  const PaystackBank({
    required this.name,
    required this.code,
    this.longCode,
    this.slug,
    this.country,
  });

  factory PaystackBank.fromApi(Map<String, dynamic> json) {
    return PaystackBank(
      name: json['name']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      longCode: json['longcode']?.toString(),
      slug: json['slug']?.toString(),
      country: json['country']?.toString(),
    );
  }

  bool get isValid => name.isNotEmpty && code.isNotEmpty;

  bool get isNigerian {
    if (country == null || country!.isEmpty) {
      return true;
    }
    final normalized = country!.toLowerCase();
    return normalized == 'nigeria' || normalized == 'ng';
  }
}

class VerifiedAccount {
  final String accountNumber;
  final String accountName;
  final String bankCode;
  final String bankName;

  const VerifiedAccount({
    required this.accountNumber,
    required this.accountName,
    required this.bankCode,
    required this.bankName,
  });
}

class BankPickerSheet extends StatefulWidget {
  final List<PaystackBank> banks;
  final TextEditingController searchController;

  const BankPickerSheet({
    super.key,
    required this.banks,
    required this.searchController,
  });

  @override
  State<BankPickerSheet> createState() => _BankPickerSheetState();
}

class _BankPickerSheetState extends State<BankPickerSheet> {
  late List<PaystackBank> _filteredBanks;

  @override
  void initState() {
    super.initState();
    _filteredBanks = List<PaystackBank>.from(widget.banks);
    widget.searchController.addListener(_handleSearch);
  }

  @override
  void dispose() {
    widget.searchController.removeListener(_handleSearch);
    super.dispose();
  }

  void _handleSearch() {
    final query = widget.searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredBanks = List<PaystackBank>.from(widget.banks);
      } else {
        _filteredBanks = widget.banks
            .where((bank) =>
                bank.name.toLowerCase().contains(query) ||
                bank.code.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 64,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: widget.searchController,
                autofocus: true,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: 'Search bank name or code',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _filteredBanks.isEmpty
                  ? Center(
                      child: Text(
                        'No banks match your search.',
                        style: theme.textTheme.bodyMedium,
                      ),
                    )
                  : ListView.separated(
                      controller: scrollController,
                      itemCount: _filteredBanks.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final bank = _filteredBanks[index];
                        final subtitleBuffer =
                            StringBuffer('Code: ${bank.code}');
                        if (bank.longCode != null &&
                            bank.longCode!.isNotEmpty) {
                          subtitleBuffer.write(' • ${bank.longCode}');
                        }
                        return ListTile(
                          title: Text(bank.name),
                          subtitle: Text(subtitleBuffer.toString()),
                          onTap: () => Navigator.of(context).pop(bank),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
