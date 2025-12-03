import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_service.dart';
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
  final _bankSearchController = TextEditingController();

  PaystackBank? _selectedBank;
  List<PaystackBank> _banks = [];
  bool _isFetchingBanks = false;
  String? _banksError;

  double _availableBalance = 0;
  bool _isLoading = false;
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
  }

  @override
  void dispose() {
    _accountNumberController.dispose();
    _amountController.dispose();
    _pinController.dispose();
    _bankSearchController.dispose();
    super.dispose();
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
    final balance = await fetchWalletBalance(token);
    if (!mounted) return;
    setState(() {
      if (balance != null) {
        _availableBalance = balance;
      }
    });
  }

  Future<void> _fetchBanks() async {
    if (_isFetchingBanks || _banks.isNotEmpty) {
      return;
    }
    final token = await _ensureToken();
    if (token == null) return;
    setState(() {
      _isFetchingBanks = true;
      _banksError = null;
    });
    final response = await fetchPaystackBanks(token: token);
    if (!mounted) return;
    if (response['error'] != null) {
      setState(() {
        _isFetchingBanks = false;
        _banksError = response['error'].toString();
      });
      _showSnack(response['error'].toString());
      return;
    }
    final List<dynamic> payload = response['data'] as List<dynamic>? ?? [];
    final banks = payload
        .whereType<Map<String, dynamic>>()
        .map(PaystackBank.fromApi)
        .where((bank) => bank.isValid && bank.isNigerian)
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    setState(() {
      _banks = banks;
      _isFetchingBanks = false;
    });
  }

  Future<void> _openBankPicker() async {
    await _fetchBanks();
    if (!mounted) return;
    if (_banks.isEmpty) {
      _showSnack(_banksError ?? 'Unable to load banks. Please try again.');
      return;
    }

    _bankSearchController.clear();
    final selected = await showModalBottomSheet<PaystackBank>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BankPickerSheet(
        banks: _banks,
        searchController: _bankSearchController,
      ),
    );

    if (selected != null) {
      setState(() {
        _selectedBank = selected;
      });
      _invalidateAccountVerification();
    }
  }

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

  void _withdrawFunds() {
    FocusScope.of(context).unfocus();
    if (_isLoading) return;
    if (_formKey.currentState?.validate() != true) return;
    if (!_accountVerified || _verifiedAccount == null) {
      _showSnack('Please verify the beneficiary account before withdrawing.');
      return;
    }
    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    if (amount <= 0) {
      _showSnack('Enter the amount you wish to withdraw.');
      return;
    }
    final pin = _pinController.text.trim();
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

    await _showSuccessDialog(amount, message: message);
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
                          const SizedBox(height: 24),
                          _buildAccountNumberField(card, shadow),
                          const SizedBox(height: 16),
                          _buildBankField(card, shadow),
                          const SizedBox(height: 12),
                          _buildVerifyButton(),
                          const SizedBox(height: 8),
                          Text(
                            'Banks update in real-time from Paystack (Nigeria).',
                            style: TextStyle(fontSize: 12, color: muted),
                          ),
                          const SizedBox(height: 16),
                          if (_accountVerified) ...[
                            _buildAccountSummaryCard(cs, muted),
                            const SizedBox(height: 24),
                            _buildAmountCard(cs),
                            const SizedBox(height: 12),
                            _buildAmountHint(muted),
                            const SizedBox(height: 20),
                            _buildPinField(card, shadow),
                            const SizedBox(height: 32),
                            _buildSubmitButton(),
                            const SizedBox(height: 20),
                            Center(
                              child: TextButton(
                                onPressed: () => _promptSetPin(
                                  'Request an OTP to set your PIN before withdrawing.',
                                ),
                                child: const Text(
                                  'Yet to set your transaction pin? Click here',
                                  style: TextStyle(
                                    color: _brandGreen,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
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
              onPressed: _refreshWalletBalance,
              icon: const Icon(Icons.refresh, size: 20),
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
    final bankName = _selectedBank?.name ?? 'Tap to select bank';
    final cs = Theme.of(context).colorScheme;
    final labelColor = cs.onSurface.withValues(alpha: 0.6);
    final valueColor = _selectedBank == null
        ? cs.onSurface.withValues(alpha: 0.6)
        : cs.onSurface;
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _isFetchingBanks ? null : _openBankPicker,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Icon(Icons.account_balance, color: _brandGreen),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bank',
                        style: TextStyle(
                          fontSize: 12,
                          color: labelColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        bankName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: valueColor,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isFetchingBanks)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Icon(Icons.chevron_right,
                      color: cs.onSurface.withValues(alpha: 0.5)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVerifyButton() {
    final canVerify = !_verifyingAccount &&
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
    final surface = Theme.of(context).cardColor;
    final shadow = Colors.black.withValues(
        alpha: Theme.of(context).brightness == Brightness.dark ? 0.25 : 0.05);
    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _brandGreen.withValues(alpha: 0.4), width: 2),
        boxShadow: [
          BoxShadow(
            color: shadow,
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: const BoxDecoration(
              color: _brandGreen,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.money, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '₦${_amountController.text.isEmpty ? '0' : _amountController.text}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _accountVerified ? Icons.check : Icons.info,
                    color: _brandGreen,
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Amount to Withdraw (Min: ₦1,000)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.transparent,
                contentPadding: EdgeInsets.all(16),
              ),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter amount to withdraw';
                }
                final amount = double.tryParse(value);
                if (amount == null || amount < 1000) {
                  return 'Minimum withdrawal amount is ₦1,000';
                }
                if (amount > _availableBalance) {
                  return 'Insufficient balance';
                }
                return null;
              },
              onChanged: (_) => setState(() {}),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountHint(Color muted) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: WalletVisibilityBuilder(
        builder: (_, showBalance) {
          final balanceText = showBalance
              ? '₦${_availableBalance.toStringAsFixed(2)}'
              : '*************';
          return Text(
            'Minimum withdrawal amount is ₦1,000 | Available: $balanceText',
            style: TextStyle(fontSize: 12, color: muted),
          );
        },
      ),
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
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _withdrawFunds,
        style: ElevatedButton.styleFrom(
          backgroundColor: _brandGreen,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 8,
          shadowColor: _brandGreen.withValues(alpha: 0.3),
        ),
        child: _isLoading
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
              ),
      ),
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
