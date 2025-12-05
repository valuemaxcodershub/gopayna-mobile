import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_service.dart' as api;
import 'widgets/wallet_visibility_builder.dart';
import 'widgets/themed_screen_helpers.dart';

class AirtimeTransaction {
  final String network;
  final String phoneNumber;
  final String amount;
  final DateTime date;
  final bool isSuccessful;
  final Color networkColor;

  AirtimeTransaction({
    required this.network,
    required this.phoneNumber,
    required this.amount,
    required this.date,
    required this.isSuccessful,
    required this.networkColor,
  });
}

class BuyAirtimeScreen extends StatefulWidget {
  const BuyAirtimeScreen({super.key});

  @override
  State<BuyAirtimeScreen> createState() => _BuyAirtimeScreenState();
}

class _BuyAirtimeScreenState extends State<BuyAirtimeScreen>
    with ThemedScreenHelpers {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _amountController = TextEditingController();

  String _selectedNetwork = 'mtn';
  bool _isLoading = false;
  bool _showNetworkList = false;
  double _walletBalance = 0.0;
  String? _token;
  List<AirtimeTransaction> _recentTransactions = [];

  // Nigerian mobile number prefixes for auto-detection
  static const Map<String, List<String>> _networkPrefixes = {
    'mtn': [
      '0803',
      '0806',
      '0703',
      '0706',
      '0813',
      '0816',
      '0810',
      '0814',
      '0903',
      '0906',
      '0913',
      '0916'
    ],
    'glo': ['0805', '0807', '0705', '0815', '0811', '0905', '0915'],
    'airtel': [
      '0802',
      '0808',
      '0708',
      '0812',
      '0701',
      '0901',
      '0902',
      '0907',
      '0912'
    ],
    '9mobile': ['0809', '0818', '0817', '0909', '0908'],
  };

  final List<Map<String, dynamic>> _networks = [
    {
      'id': 'mtn',
      'name': 'MTN',
      'color': const Color(0xFFFFCC00),
      'logo': 'assets/mtn_logo.png',
      'textColor': Colors.black,
    },
    {
      'id': 'airtel',
      'name': 'Airtel',
      'color': const Color(0xFFE60026),
      'logo': 'assets/airtel_logo.png',
      'textColor': Colors.white,
    },
    {
      'id': 'glo',
      'name': 'GLO',
      'color': const Color(0xFF00CA44),
      'logo': 'assets/glo_logo.png',
      'textColor': Colors.white,
    },
    {
      'id': '9mobile',
      'name': '9Mobile',
      'color': const Color(0xFF006B3F),
      'logo': 'assets/9mobile_logo.png',
      'textColor': Colors.white,
    },
  ];

  final List<String> _quickAmounts = [
    '100',
    '200',
    '500',
    '1000',
    '2000',
    '5000'
  ];

  // Network colors for transaction display
  Color _getNetworkColor(String network) {
    switch (network.toLowerCase()) {
      case 'mtn':
        return const Color(0xFFFFCC00);
      case 'glo':
        return const Color(0xFF00CA44);
      case 'airtel':
        return const Color(0xFFE60026);
      case '9mobile':
        return const Color(0xFF006B3F);
      default:
        return Colors.grey;
    }
  }

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(_onPhoneNumberChanged);
    _loadWalletData();
    _loadRecentTransactions();
  }

  /// Detect network from phone number prefix
  String? _detectNetworkFromPhone(String phone) {
    if (phone.length < 4) return null;
    final prefix = phone.substring(0, 4);
    for (final entry in _networkPrefixes.entries) {
      if (entry.value.contains(prefix)) {
        return entry.key;
      }
    }
    return null;
  }

  /// Called when phone number changes - auto-detect network
  void _onPhoneNumberChanged() {
    final phone = _phoneController.text.trim();
    if (phone.length >= 4) {
      final detectedNetwork = _detectNetworkFromPhone(phone);
      if (detectedNetwork != null && detectedNetwork != _selectedNetwork) {
        setState(() {
          _selectedNetwork = detectedNetwork;
        });
        HapticFeedback.selectionClick();
      }
    }
  }

  Future<void> _loadRecentTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt');
    if (token == null) return;

    final result = await api.fetchVTUHistory(token, type: 'airtime', limit: 5);
    if (mounted && result['success'] == true) {
      final data = result['data'] as List? ?? [];
      setState(() {
        _recentTransactions = data.map((tx) {
          final details = tx['details'] as Map<String, dynamic>? ?? {};
          return AirtimeTransaction(
            network: details['network']?.toString().toUpperCase() ?? 'Unknown',
            phoneNumber: details['phone']?.toString() ?? '',
            amount: tx['amount']?.toString() ?? '0',
            date: DateTime.tryParse(tx['createdAt']?.toString() ?? '') ??
                DateTime.now(),
            isSuccessful: tx['status'] == 'success',
            networkColor:
                _getNetworkColor(details['network']?.toString() ?? ''),
          );
        }).toList();
      });
    }
  }

  Future<void> _loadWalletData() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('jwt');
    if (_token != null) {
      final balance = await api.fetchWalletBalance(_token!);
      if (mounted && balance != null) {
        setState(() {
          _walletBalance = balance;
        });
      }
    }
  }

  @override
  void dispose() {
    _phoneController.removeListener(_onPhoneNumberChanged);
    _phoneController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _selectQuickAmount(String amount) {
    setState(() {
      _amountController.text = amount;
    });
    HapticFeedback.lightImpact();
  }

  void _buyAirtime() {
    if (_formKey.currentState!.validate()) {
      _showConfirmationDialog();
    }
  }

  void _showConfirmationDialog() {
    final isTablet = MediaQuery.of(context).size.width > 600;
    final cs = colorScheme;
    final card = cardColor;
    final muted = mutedTextColor;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
          ),
          title: Text(
            'Confirm Purchase',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isTablet ? 22 : 18,
              color: cs.onSurface,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Please confirm your airtime purchase details:',
                style: TextStyle(
                  fontSize: isTablet ? 16 : 14,
                  color: muted,
                ),
              ),
              SizedBox(height: isTablet ? 20 : 16),
              Container(
                padding: EdgeInsets.all(isTablet ? 20 : 16),
                decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
                ),
                child: Column(
                  children: [
                    _buildConfirmationRow(
                        'Network', _selectedNetworkData['name']),
                    const SizedBox(height: 8),
                    _buildConfirmationRow(
                        'Phone Number', _phoneController.text),
                    const SizedBox(height: 8),
                    _buildConfirmationRow(
                        'Amount', '₦${_amountController.text}'),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: muted,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _processPurchase();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.primary,
                foregroundColor: cs.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildConfirmationRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface,
            ),
          ),
        ),
        const Text(': '),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }

  void _processPurchase() async {
    if (_token == null) {
      _showErrorDialog('Session expired. Please login again.');
      return;
    }

    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) {
      _showErrorDialog('Please enter a valid amount.');
      return;
    }

    if (amount > _walletBalance) {
      _showErrorDialog('Insufficient wallet balance.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Send network name (mtn, glo, airtel, 9mobile) not the code
    final result = await api.buyAirtime(
      _token!,
      network: _selectedNetwork, // Send network name directly
      phone: _phoneController.text,
      amount: amount,
    );

    setState(() {
      _isLoading = false;
    });

    if (!mounted) return;

    if (result['success'] == true) {
      // Refresh wallet balance after successful purchase
      _loadWalletData();
      _loadRecentTransactions();
      _showSuccessDialog();
    } else {
      // Reload wallet data in case of refund
      if (result['refunded'] == true) {
        _loadWalletData();
      }
      String errorMessage =
          result['error'] ?? 'Transaction failed. Please try again.';
      // Add refund notice if applicable
      if (result['refunded'] == true) {
        errorMessage += '\n\nYour wallet has been refunded.';
      }
      _showErrorDialog(errorMessage);
    }
  }

  void _showErrorDialog(String message) {
    final isTablet = MediaQuery.of(context).size.width > 600;
    final cs = colorScheme;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
          ),
          title: Row(
            children: [
              Icon(Icons.error_outline,
                  color: Colors.red, size: isTablet ? 32 : 24),
              SizedBox(width: isTablet ? 12 : 8),
              Text(
                'Error',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: isTablet ? 22 : 18,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: TextStyle(
              fontSize: isTablet ? 16 : 14,
              color: cs.onSurface,
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.primary,
                foregroundColor: cs.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showSuccessDialog() {
    final isTablet = MediaQuery.of(context).size.width > 600;
    final selectedNetworkData =
        _networks.firstWhere((n) => n['id'] == _selectedNetwork);
    final cs = colorScheme;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isTablet ? 24 : 20),
          ),
          child: Container(
            padding: EdgeInsets.all(isTablet ? 32 : 24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(isTablet ? 24 : 20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [cs.primary, cs.primary.withValues(alpha: 0.85)],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: isTablet ? 100 : 80,
                  height: isTablet ? 100 : 80,
                  decoration: BoxDecoration(
                    color: cs.onPrimary.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle,
                    color: cs.onPrimary,
                    size: isTablet ? 60 : 50,
                  ),
                ),
                SizedBox(height: isTablet ? 28 : 20),
                Text(
                  'Airtime Purchase Successful!',
                  style: TextStyle(
                    fontSize: isTablet ? 26 : 20,
                    fontWeight: FontWeight.bold,
                    color: cs.onPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: isTablet ? 16 : 12),
                Text(
                  'You successfully purchased ₦${_amountController.text} ${selectedNetworkData['name']} airtime for ${_phoneController.text}',
                  style: TextStyle(
                    fontSize: isTablet ? 16 : 14,
                    color: cs.onPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: isTablet ? 32 : 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cs.onPrimary,
                      foregroundColor: cs.primary,
                      padding:
                          EdgeInsets.symmetric(vertical: isTablet ? 16 : 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
                      ),
                    ),
                    child: Text(
                      'Done',
                      style: TextStyle(
                        fontSize: isTablet ? 20 : 16,
                        fontWeight: FontWeight.w600,
                        color: cs.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Map<String, dynamic> get _selectedNetworkData =>
      _networks.firstWhere((n) => n['id'] == _selectedNetwork);

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} min ago';
      }
      return '${difference.inHours} hr ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else {
      return '${difference.inDays} days ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;
    final cs = colorScheme;
    final muted = mutedTextColor;
    final card = cardColor;
    final border = borderColor;
    final shadow = shadowColor;
    final surfaceVariant = cs.surfaceContainerHighest;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.primary,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back,
            color: cs.onPrimary,
            size: isTablet ? 28 : 20,
          ),
        ),
        title: Text(
          'Airtime',
          style: TextStyle(
            color: cs.onPrimary,
            fontSize: isTablet ? 24 : 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
        actions: [
          TextButton(
            onPressed: () {},
            child: Text(
              'History',
              style: TextStyle(
                color: cs.onPrimary,
                fontSize: isTablet ? 20 : 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
        systemOverlayStyle: statusBarStyle,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isTablet ? 32 : 20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              WalletVisibilityBuilder(
                builder: (_, showBalance) {
                  final balanceText = showBalance
                      ? '₦${_walletBalance.toStringAsFixed(2)}'
                      : '*************';
                  return Text(
                    'Wallet Balance: $balanceText | Min: ₦50',
                    style: TextStyle(
                      fontSize: isTablet ? 14 : 12,
                      color: muted,
                    ),
                  );
                },
              ),

              SizedBox(height: isTablet ? 24 : 16),

              // Network Selection
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
                child: Column(
                  children: [
                    // Selected Network Display
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _showNetworkList = !_showNetworkList;
                        });
                      },
                      child: Container(
                        padding: EdgeInsets.all(isTablet ? 24 : 16),
                        child: Row(
                          children: [
                            Container(
                              width: isTablet ? 56 : 40,
                              height: isTablet ? 56 : 40,
                              decoration: BoxDecoration(
                                color: _selectedNetworkData['color'],
                                borderRadius:
                                    BorderRadius.circular(isTablet ? 12 : 8),
                              ),
                              child: ClipRRect(
                                borderRadius:
                                    BorderRadius.circular(isTablet ? 12 : 8),
                                child: Image.asset(
                                  _selectedNetworkData['logo'],
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Icon(
                                    Icons.sim_card,
                                    color: _selectedNetworkData['textColor'],
                                    size: isTablet ? 28 : 20,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: isTablet ? 16 : 12),
                            Text(
                              _selectedNetworkData['name'],
                              style: TextStyle(
                                fontSize: isTablet ? 20 : 16,
                                fontWeight: FontWeight.w600,
                                color: cs.onSurface,
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              _showNetworkList
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              color: muted,
                              size: isTablet ? 28 : 24,
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Network Options
                    if (_showNetworkList)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: surfaceVariant,
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(16),
                            bottomRight: Radius.circular(16),
                          ),
                        ),
                        child: Column(
                          children: _networks.map((network) {
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedNetwork = network['id'];
                                  _showNetworkList = false;
                                });
                                HapticFeedback.lightImpact();
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: _selectedNetwork == network['id']
                                      ? cs.primary.withValues(alpha: 0.08)
                                      : card,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _selectedNetwork == network['id']
                                        ? cs.primary
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: network['color'],
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(6),
                                        child: Image.asset(
                                          network['logo'],
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  Icon(
                                            Icons.sim_card,
                                            color: network['textColor'],
                                            size: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      network['name'],
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: _selectedNetwork == network['id']
                                            ? cs.primary
                                            : cs.onSurface,
                                      ),
                                    ),
                                    const Spacer(),
                                    if (_selectedNetwork == network['id'])
                                      Icon(
                                        Icons.check_circle,
                                        color: cs.primary,
                                        size: 20,
                                      ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                  ],
                ),
              ),

              SizedBox(height: isTablet ? 32 : 24),

              // Phone Number Field
              Container(
                decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
                  boxShadow: [
                    BoxShadow(
                      color: shadow,
                      blurRadius: isTablet ? 16 : 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    labelStyle: TextStyle(
                      fontSize: isTablet ? 18 : 16,
                      color: muted,
                    ),
                    prefixIcon: Icon(
                      Icons.phone,
                      color: cs.primary,
                      size: isTablet ? 28 : 24,
                    ),
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.all(Radius.circular(isTablet ? 20 : 16)),
                      borderSide: BorderSide(color: border),
                    ),
                    filled: true,
                    fillColor: card,
                    enabledBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.all(Radius.circular(isTablet ? 20 : 16)),
                      borderSide: BorderSide(color: border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.all(Radius.circular(isTablet ? 20 : 16)),
                      borderSide: BorderSide(color: cs.primary, width: 2),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.all(Radius.circular(isTablet ? 20 : 16)),
                      borderSide: BorderSide(color: cs.error, width: 2),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.all(Radius.circular(isTablet ? 20 : 16)),
                      borderSide: BorderSide(color: cs.error, width: 2),
                    ),
                    contentPadding: EdgeInsets.all(isTablet ? 28 : 20),
                  ),
                  style: TextStyle(
                    fontSize: isTablet ? 20 : 16,
                    fontWeight: FontWeight.w500,
                    color: cs.onSurface,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter phone number';
                    }
                    if (value.length != 11) {
                      return 'Phone number must be 11 digits';
                    }
                    return null;
                  },
                ),
              ),

              const SizedBox(height: 24),

              // Amount Section
              Container(
                decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: cs.primary,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: shadow,
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: cs.primary,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(14),
                          topRight: Radius.circular(14),
                        ),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.money,
                            color: cs.onPrimary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _amountController.text.isEmpty
                                ? 'Select Amount'
                                : '₦${_amountController.text}',
                            style: TextStyle(
                              color: cs.onPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          if (_amountController.text.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: cs.onPrimary,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.check,
                                color: cs.primary,
                                size: 16,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            controller: _amountController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                            decoration: InputDecoration(
                              labelText: 'Enter Amount',
                              labelStyle: TextStyle(color: muted),
                              border: const OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(12)),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: card,
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: border),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: cs.primary, width: 2),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: cs.error, width: 2),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: cs.error, width: 2),
                              ),
                              contentPadding: const EdgeInsets.all(16),
                            ),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter amount';
                              }
                              final amount = double.tryParse(value);
                              if (amount == null || amount < 50) {
                                return 'Minimum airtime amount is ₦50';
                              }
                              if (amount > _walletBalance) {
                                return 'Insufficient wallet balance';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Quick Selection',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _quickAmounts.map((amount) {
                              final isSelected =
                                  _amountController.text == amount;
                              return GestureDetector(
                                onTap: () => _selectQuickAmount(amount),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? cs.primary
                                        : surfaceVariant,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isSelected ? cs.primary : border,
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    '₦$amount',
                                    style: TextStyle(
                                      color: isSelected
                                          ? cs.onPrimary
                                          : cs.onSurface,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: isTablet ? 48 : 40),

              // Buy Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _buyAirtime,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cs.primary,
                    foregroundColor: cs.onPrimary,
                    padding: EdgeInsets.symmetric(vertical: isTablet ? 20 : 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
                    ),
                    elevation: 8,
                    shadowColor: cs.primary.withValues(alpha: 0.3),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          height: isTablet ? 28 : 20,
                          width: isTablet ? 28 : 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(cs.onPrimary),
                          ),
                        )
                      : Text(
                          'BUY',
                          style: TextStyle(
                            fontSize: isTablet ? 22 : 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 20),

              // Recent Transactions
              if (_recentTransactions.isNotEmpty) ...[
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Icon(
                              Icons.history,
                              color: cs.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Recent Airtime Purchases',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: cs.onSurface,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            TextButton(
                              onPressed: () {},
                              style: TextButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                'View All',
                                style: TextStyle(
                                  color: cs.primary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _recentTransactions.take(3).length,
                        separatorBuilder: (context, index) => Divider(
                          color: border,
                          height: 1,
                        ),
                        itemBuilder: (context, index) {
                          final transaction = _recentTransactions[index];
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: transaction.networkColor
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: transaction.networkColor
                                          .withValues(alpha: 0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.sim_card,
                                    color: transaction.networkColor,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            '${transaction.network} Airtime',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: cs.onSurface,
                                            ),
                                          ),
                                          const Spacer(),
                                          Text(
                                            '₦${transaction.amount}',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: cs.onSurface,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Text(
                                            transaction.phoneNumber,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: muted,
                                            ),
                                          ),
                                          const Spacer(),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: transaction.isSuccessful
                                                  ? cs.primary
                                                      .withValues(alpha: 0.1)
                                                  : cs.error
                                                      .withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              transaction.isSuccessful
                                                  ? 'Success'
                                                  : 'Failed',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w500,
                                                color: transaction.isSuccessful
                                                    ? cs.primary
                                                    : cs.error,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _formatDate(transaction.date),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: muted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
