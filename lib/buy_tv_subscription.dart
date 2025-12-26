import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_service.dart' as api;
import 'service_transaction_history.dart';
import 'widgets/wallet_visibility_builder.dart';
import 'widgets/themed_screen_helpers.dart';

class TVTransaction {
  final String id;
  final String provider;
  final String smartCardNumber;
  final String customerName;
  final String package;
  final double amount;
  final DateTime date;
  final String status;
  final Color providerColor;

  TVTransaction({
    required this.id,
    required this.provider,
    required this.smartCardNumber,
    required this.customerName,
    required this.package,
    required this.amount,
    required this.date,
    required this.status,
    required this.providerColor,
  });
}

class BuyTVSubscriptionScreen extends StatefulWidget {
  const BuyTVSubscriptionScreen({super.key});

  @override
  State<BuyTVSubscriptionScreen> createState() =>
      _BuyTVSubscriptionScreenState();
}

class _BuyTVSubscriptionScreenState extends State<BuyTVSubscriptionScreen>
    with ThemedScreenHelpers {
  final _formKey = GlobalKey<FormState>();
  final _smartCardController = TextEditingController();
  final _emailController = TextEditingController();

  String _selectedProvider = 'dstv';
  String _selectedPackage = '';
  bool _isLoading = false;
  bool _isVerifying = false;
  bool _isSmartCardVerified = false;
  bool _showProviderList = false;
  bool _showPackageList = false;
  String? _verifiedCustomerName;
  double _walletBalance = 0.0;
  String? _token;
  List<TVTransaction> _recentTransactions = [];

  // NelloByte supported providers: dstv, gotv, startimes
  final List<Map<String, dynamic>> _providers = [
    {
      'id': 'dstv',
      'name': 'DStv',
      'color': const Color(0xFF0066CC),
      'logo': 'dstv_logo.png',
      'textColor': Colors.white,
    },
    {
      'id': 'gotv',
      'name': 'GOtv',
      'color': const Color(0xFF00A651),
      'logo': 'gotv_logo.png',
      'textColor': Colors.white,
    },
    {
      'id': 'startimes',
      'name': 'StarTimes',
      'color': const Color(0xFFE4002B),
      'logo': 'startimes_logo.png',
      'textColor': Colors.white,
    },
  ];

  // NelloByte package codes from documentation (fallback values)
  // DStv: 77=DSTV Padi, 78=DSTV Yanga, 79=DSTV Confam, 63=DSTV Compact, 66=DSTV CompactPlus, 67=DSTV Premium
  // GOtv: 64=GOtv Smallie, 61=GOtv Jinja, 62=GOtv Jolli, 65=GOtv Max, 90=GOtv Supa
  // StarTimes: 6=Nova, 7=Basic, 8=Smart, 9=Classic, 10=Super
  final Map<String, List<Map<String, dynamic>>> _packages = {
    'dstv': [
      {
        'bundle': 'DStv Padi',
        'code': '77',
        'price': 2500,
        'duration': '30 Days'
      },
      {
        'bundle': 'DStv Yanga',
        'code': '78',
        'price': 3500,
        'duration': '30 Days'
      },
      {
        'bundle': 'DStv Confam',
        'code': '79',
        'price': 5500,
        'duration': '30 Days'
      },
      {
        'bundle': 'DStv Compact',
        'code': '63',
        'price': 10500,
        'duration': '30 Days'
      },
      {
        'bundle': 'DStv Compact Plus',
        'code': '66',
        'price': 16600,
        'duration': '30 Days'
      },
      {
        'bundle': 'DStv Premium',
        'code': '67',
        'price': 24500,
        'duration': '30 Days'
      },
    ],
    'gotv': [
      {
        'bundle': 'GOtv Smallie',
        'code': '64',
        'price': 1300,
        'duration': '30 Days'
      },
      {
        'bundle': 'GOtv Jinja',
        'code': '61',
        'price': 2700,
        'duration': '30 Days'
      },
      {
        'bundle': 'GOtv Jolli',
        'code': '62',
        'price': 3950,
        'duration': '30 Days'
      },
      {
        'bundle': 'GOtv Max',
        'code': '65',
        'price': 5700,
        'duration': '30 Days'
      },
      {
        'bundle': 'GOtv Supa',
        'code': '90',
        'price': 7400,
        'duration': '30 Days'
      },
    ],
    'startimes': [
      {
        'bundle': 'Nova Bouquet',
        'code': '6',
        'price': 1300,
        'duration': '30 Days'
      },
      {
        'bundle': 'Basic Bouquet',
        'code': '7',
        'price': 2200,
        'duration': '30 Days'
      },
      {
        'bundle': 'Smart Bouquet',
        'code': '8',
        'price': 2900,
        'duration': '30 Days'
      },
      {
        'bundle': 'Classic Bouquet',
        'code': '9',
        'price': 3500,
        'duration': '30 Days'
      },
      {
        'bundle': 'Super Bouquet',
        'code': '10',
        'price': 5200,
        'duration': '30 Days'
      },
    ],
  };

  @override
  void initState() {
    super.initState();
    _loadWalletData();
    _loadRecentTransactions();
    _fetchTvPricing();
  }

  Future<void> _fetchTvPricing() async {
    try {
      final result = await api.fetchTvPricing();
      if (mounted && result['success'] == true) {
        final packages = result['packages'] as List? ?? [];
        if (packages.isNotEmpty) {
          // Group by provider
          final Map<String, List<Map<String, dynamic>>> grouped = {};
          for (final item in packages) {
            final providerId =
                (item['provider'] ?? item['providerId'] ?? 'dstv')
                    .toString()
                    .toLowerCase();

            if (!grouped.containsKey(providerId)) {
              grouped[providerId] = [];
            }
            grouped[providerId]!.add({
              'bundle': item['name'] ?? item['planName'] ?? 'Package',
              'code': item['code'] ?? item['id'] ?? '',
              'price': item['price'] ?? item['sellingPrice'] ?? 0,
              'duration': '30 Days',
            });
          }

          setState(() {
            // Merge with existing packages, preferring fetched prices
            grouped.forEach((key, value) {
              if (value.isNotEmpty) {
                _packages[key] = value;
              }
            });
          });
        }
      }
    } catch (e) {
      // Use fallback prices
    }
  }

  Future<void> _loadRecentTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt');
    if (token == null) return;

    final result = await api.fetchVTUHistory(token, type: 'tv', limit: 8);
    if (mounted && result['success'] == true) {
      final data = result['data'] as List? ?? [];
      setState(() {
        _recentTransactions = data.map((tx) {
          final details = tx['details'] as Map<String, dynamic>? ?? {};
          return TVTransaction(
            id: tx['reference']?.toString() ?? '',
            provider:
                details['provider']?.toString().toUpperCase() ?? 'Unknown',
            smartCardNumber: details['smartCardNumber']?.toString() ?? '',
            customerName: details['customerName']?.toString() ?? '',
            package: tx['description']?.toString() ?? '',
            amount: (tx['amount'] as num?)?.toDouble() ?? 0,
            date: DateTime.tryParse(tx['createdAt']?.toString() ?? '') ??
                DateTime.now(),
            status: tx['status'] == 'success' ? 'Successful' : 'Failed',
            providerColor: const Color(0xFF0066CC),
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

  /// Verify smart card/IUC number with NelloByte API
  Future<void> _verifySmartCard() async {
    final smartCard = _smartCardController.text.trim();
    debugPrint(
        '[TV] Verifying smart card: $smartCard for provider: $_selectedProvider');

    if (smartCard.isEmpty || smartCard.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a valid smart card number'),
          backgroundColor: colorScheme.error,
        ),
      );
      return;
    }

    debugPrint('[TV] Token present: ${_token != null}');
    if (_token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please login again'),
          backgroundColor: colorScheme.error,
        ),
      );
      return;
    }

    setState(() {
      _isVerifying = true;
      _isSmartCardVerified = false;
      _verifiedCustomerName = null;
    });

    debugPrint('[TV] Calling verifySmartCard API...');
    final result =
        await api.verifySmartCard(_token!, _selectedProvider, smartCard);
    debugPrint('[TV] API result: $result');

    if (mounted) {
      setState(() {
        _isVerifying = false;
      });

      if (result['success'] == true && result['data'] != null) {
        final customerName = result['data']['customerName']?.toString() ?? '';
        debugPrint('[TV] Customer name: $customerName');
        if (customerName.isNotEmpty && customerName != 'INVALID_SMARTCARDNO') {
          setState(() {
            _isSmartCardVerified = true;
            _verifiedCustomerName = customerName;
          });
          HapticFeedback.mediumImpact();
        } else {
          _showErrorSnackBar(
              'Invalid smart card number. Please check and try again.');
        }
      } else {
        _showErrorSnackBar(result['error']?.toString() ??
            'Failed to verify smart card. Please try again.');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: colorScheme.error,
      ),
    );
  }

  @override
  void dispose() {
    _smartCardController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _buyTVSubscription() {
    if (_formKey.currentState!.validate()) {
      if (_selectedPackage.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please select a package'),
            backgroundColor: colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      _showConfirmationDialog();
    }
  }

  void _showConfirmationDialog() {
    final isTablet = MediaQuery.of(context).size.width > 600;
    final selectedPackage = _packages[_selectedProvider]!.firstWhere(
      (package) =>
          '${package['bundle']} - ${package['duration']}' == _selectedPackage,
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
          ),
          backgroundColor: cardColor,
          title: Text(
            'Confirm Purchase',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isTablet ? 22 : 18,
              color: colorScheme.onSurface,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Please confirm your TV subscription details:',
                style: TextStyle(
                  fontSize: 14,
                  color: mutedTextColor,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surface.withValues(
                    alpha: isDarkMode ? 0.4 : 0.3,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  children: [
                    _buildConfirmationRow(
                        'Provider', _selectedProviderData['name']),
                    const SizedBox(height: 8),
                    _buildConfirmationRow(
                        'Smart Card', _smartCardController.text),
                    const SizedBox(height: 8),
                    _buildConfirmationRow(
                        'Email for Notification', _emailController.text),
                    const SizedBox(height: 8),
                    _buildConfirmationRow(
                        'Package', selectedPackage['bundle'] ?? ''),
                    const SizedBox(height: 8),
                    _buildConfirmationRow(
                        'Duration', selectedPackage['duration'] ?? ''),
                    const SizedBox(height: 8),
                    _buildConfirmationRow(
                        'Amount', '₦${selectedPackage['price']}'),
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
                  color: mutedTextColor,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _processPurchase();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
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
          width: 80,
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

    // Get the selected package details
    Map<String, dynamic>? selectedPackage;
    try {
      selectedPackage = _packages[_selectedProvider]!.firstWhere(
        (package) =>
            '${package['bundle']} - ${package['duration']}' == _selectedPackage,
      );
    } catch (e) {
      _showErrorDialog('Please select a valid package.');
      return;
    }

    final amount = (selectedPackage['price'] as num?)?.toDouble() ?? 0;

    if (amount > _walletBalance) {
      _showErrorDialog('Insufficient wallet balance.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Use the package code from the selected package
    // NelloByte expects numeric package codes (e.g., 77 for DStv Padi)
    final packageCode = selectedPackage['code']?.toString() ?? '';

    final result = await api.buyTVSubscription(
      _token!,
      provider:
          _selectedProvider, // Send provider ID directly (dstv, gotv, startimes)
      smartCardNumber: _smartCardController.text,
      packageCode: packageCode,
      amount: amount,
      email: _emailController.text,
    );

    setState(() {
      _isLoading = false;
    });

    if (!mounted) return;

    if (result['success'] == true) {
      _loadWalletData();
      _showSuccessDialog();
    } else {
      _showErrorDialog(
          result['error'] ?? 'Transaction failed. Please try again.');
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
    final selectedProviderData =
        _providers.firstWhere((p) => p['id'] == _selectedProvider);
    final selectedPackage = _packages[_selectedProvider]!.firstWhere(
      (package) =>
          '${package['bundle']} - ${package['duration']}' == _selectedPackage,
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [colorScheme.primary, colorScheme.primaryContainer],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: colorScheme.onPrimary.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: 50,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'TV Subscription Successful!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'You successfully purchased ${selectedPackage['bundle']} ${selectedProviderData['name']} subscription for ${_smartCardController.text}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.onPrimary,
                      foregroundColor: colorScheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Done',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
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

  Map<String, dynamic> get _selectedProviderData =>
      _providers.firstWhere((p) => p['id'] == _selectedProvider);

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
    final theme = Theme.of(context);
    final colorScheme = this.colorScheme;
    final cardColor = this.cardColor;
    final borderColor = this.borderColor;
    final mutedTextColor = this.mutedTextColor;
    final shadowColor = this.shadowColor;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: colorScheme.primary,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back,
            color: colorScheme.onPrimary,
            size: isTablet ? 28 : 20,
          ),
        ),
        title: Text(
          'TV Subscription',
          style: TextStyle(
            color: colorScheme.onPrimary,
            fontSize: isTablet ? 24 : 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ServiceTransactionHistoryScreen(
                    serviceType: ServiceType.tv,
                  ),
                ),
              );
            },
            child: Text(
              'History',
              style: TextStyle(
                color: colorScheme.onPrimary,
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
                    'Wallet Balance: $balanceText',
                    style: TextStyle(
                      fontSize: isTablet ? 14 : 12,
                      color: mutedTextColor,
                    ),
                  );
                },
              ),

              SizedBox(height: isTablet ? 24 : 16),

              // Provider Selection
              Container(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                  boxShadow: isDarkMode
                      ? null
                      : [
                          BoxShadow(
                            color: shadowColor,
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                ),
                child: Column(
                  children: [
                    // Selected Provider Display (tappable dropdown)
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _showProviderList = !_showProviderList;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: _selectedProviderData['color'],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.asset(
                                  'assets/${_selectedProviderData['logo']}',
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Icon(
                                    Icons.live_tv,
                                    color: _selectedProviderData['textColor'],
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _selectedProviderData['name'],
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              _showProviderList
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              color: mutedTextColor,
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Provider Options List
                    if (_showProviderList)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(16),
                            bottomRight: Radius.circular(16),
                          ),
                        ),
                        child: Column(
                          children: _providers.map((provider) {
                            final isSelected =
                                _selectedProvider == provider['id'];
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedProvider = provider['id'];
                                  _selectedPackage = '';
                                  _isSmartCardVerified = false;
                                  _verifiedCustomerName = null;
                                  _showProviderList = false;
                                  _showPackageList = false;
                                });
                                HapticFeedback.lightImpact();
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? colorScheme.primary
                                          .withValues(alpha: 0.08)
                                      : cardColor,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? colorScheme.primary
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: provider['color'],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.asset(
                                          'assets/${provider['logo']}',
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  Icon(
                                            Icons.live_tv,
                                            color: provider['textColor'],
                                            size: 18,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      provider['name'],
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: isSelected
                                            ? colorScheme.primary
                                            : colorScheme.onSurface,
                                      ),
                                    ),
                                    const Spacer(),
                                    if (isSelected)
                                      Icon(
                                        Icons.check_circle,
                                        color: colorScheme.primary,
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

              const SizedBox(height: 20),

              // Smart Card Number Field with Verify Button
              Container(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: _isSmartCardVerified ? Colors.green : borderColor),
                  boxShadow: isDarkMode
                      ? null
                      : [
                          BoxShadow(
                            color: shadowColor,
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _smartCardController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (value) {
                        // Reset verification when smart card changes
                        if (_isSmartCardVerified) {
                          setState(() {
                            _isSmartCardVerified = false;
                            _verifiedCustomerName = null;
                          });
                        }
                      },
                      decoration: InputDecoration(
                        labelText: 'Smart Card / IUC Number',
                        prefixIcon: Icon(
                          Icons.credit_card,
                          color: colorScheme.primary,
                        ),
                        suffixIcon: _isVerifying
                            ? Padding(
                                padding: const EdgeInsets.all(12),
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        colorScheme.primary),
                                  ),
                                ),
                              )
                            : TextButton(
                                onPressed: _verifySmartCard,
                                child: Text(
                                  'Verify',
                                  style: TextStyle(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                        border: OutlineInputBorder(
                          borderRadius:
                              const BorderRadius.all(Radius.circular(16)),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        filled: true,
                        fillColor: cardColor,
                        contentPadding: const EdgeInsets.all(20),
                        enabledBorder: OutlineInputBorder(
                          borderRadius:
                              const BorderRadius.all(Radius.circular(16)),
                          borderSide: BorderSide(
                              color: _isSmartCardVerified
                                  ? Colors.green
                                  : borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius:
                              const BorderRadius.all(Radius.circular(16)),
                          borderSide: BorderSide(
                              color: colorScheme.primary, width: 1.5),
                        ),
                      ),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter smart card number';
                        }
                        if (value.length < 10) {
                          return 'Smart card number must be at least 10 digits';
                        }
                        return null;
                      },
                    ),
                    // Show verified customer name
                    if (_isSmartCardVerified && _verifiedCustomerName != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(16),
                            bottomRight: Radius.circular(16),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle,
                                color: Colors.green, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Customer: $_verifiedCustomerName',
                                style: TextStyle(
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Email Field for Notifications
              Container(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                  boxShadow: isDarkMode
                      ? null
                      : [
                          BoxShadow(
                            color: shadowColor,
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                ),
                child: TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email for Notification',
                    hintText: 'Subscription confirmation will be sent here',
                    prefixIcon: Icon(
                      Icons.email,
                      color: colorScheme.primary,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: const BorderRadius.all(Radius.circular(16)),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    filled: true,
                    fillColor: cardColor,
                    contentPadding: const EdgeInsets.all(20),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: const BorderRadius.all(Radius.circular(16)),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: const BorderRadius.all(Radius.circular(16)),
                      borderSide:
                          BorderSide(color: colorScheme.primary, width: 1.5),
                    ),
                  ),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter email address';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                ),
              ),

              const SizedBox(height: 20),

              // Package Selection
              Container(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                  boxShadow: isDarkMode
                      ? null
                      : [
                          BoxShadow(
                            color: shadowColor,
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'Select Package',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                    // Selected Package Display (tappable dropdown)
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _showPackageList = !_showPackageList;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color:
                                    colorScheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.subscriptions_outlined,
                                color: colorScheme.primary,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _selectedPackage.isEmpty
                                  ? Text(
                                      'Tap to select a package',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: mutedTextColor,
                                      ),
                                    )
                                  : Builder(builder: (context) {
                                      final selectedPkg =
                                          _packages[_selectedProvider]!
                                              .firstWhere(
                                        (p) =>
                                            '${p['bundle']} - ${p['duration']}' ==
                                            _selectedPackage,
                                        orElse: () => {},
                                      );
                                      if (selectedPkg.isEmpty) {
                                        return Text(
                                          'Tap to select a package',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: mutedTextColor,
                                          ),
                                        );
                                      }
                                      return Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            selectedPkg['bundle'] ?? '',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: colorScheme.onSurface,
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              Text(
                                                selectedPkg['duration'] ?? '',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: mutedTextColor,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                '₦${selectedPkg['price']}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: colorScheme.primary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      );
                                    }),
                            ),
                            Icon(
                              _showPackageList
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              color: mutedTextColor,
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Package Options List (expandable)
                    AnimatedSize(
                      duration: const Duration(milliseconds: 200),
                      child: _showPackageList
                          ? Container(
                              margin: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                              constraints: const BoxConstraints(maxHeight: 300),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListView.builder(
                                shrinkWrap: true,
                                padding: const EdgeInsets.all(8),
                                itemCount: _packages[_selectedProvider]!.length,
                                itemBuilder: (context, index) {
                                  final package =
                                      _packages[_selectedProvider]![index];
                                  final packageId =
                                      '${package['bundle']} - ${package['duration']}';
                                  final isSelected =
                                      _selectedPackage == packageId;
                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedPackage = packageId;
                                        _showPackageList = false;
                                      });
                                      HapticFeedback.lightImpact();
                                    },
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(
                                          vertical: 4),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? colorScheme.primary
                                                .withValues(alpha: 0.08)
                                            : cardColor,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: isSelected
                                              ? colorScheme.primary
                                              : Colors.transparent,
                                          width: 2,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  package['bundle'],
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                    color:
                                                        colorScheme.onSurface,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  package['duration'],
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: mutedTextColor,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Text(
                                            '₦${package['price']}',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: colorScheme.primary,
                                            ),
                                          ),
                                          if (isSelected) ...[
                                            const SizedBox(width: 8),
                                            Icon(
                                              Icons.check_circle,
                                              color: colorScheme.primary,
                                              size: 20,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            )
                          : const SizedBox(height: 20),
                    ),
                  ],
                ),
              ),

              SizedBox(height: isTablet ? 40 : 30),

              // Purchase Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _buyTVSubscription,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    padding: EdgeInsets.symmetric(vertical: isTablet ? 20 : 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
                    ),
                    elevation: isDarkMode ? 0 : 8,
                    shadowColor: colorScheme.primary.withValues(alpha: 0.3),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          height: isTablet ? 28 : 20,
                          width: isTablet ? 28 : 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                colorScheme.onPrimary),
                          ),
                        )
                      : Text(
                          'Complete Purchase',
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
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor),
                    boxShadow: isDarkMode
                        ? null
                        : [
                            BoxShadow(
                              color: shadowColor,
                              blurRadius: 12,
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
                              color: colorScheme.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Recent TV Subscriptions',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurface,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const ServiceTransactionHistoryScreen(
                                      serviceType: ServiceType.tv,
                                    ),
                                  ),
                                );
                              },
                              style: TextButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                'View All',
                                style: TextStyle(
                                  color: colorScheme.primary,
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
                        itemCount: _recentTransactions.take(5).length,
                        separatorBuilder: (context, index) => Divider(
                          color: borderColor,
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
                                    color: transaction.providerColor
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: transaction.providerColor
                                          .withValues(alpha: 0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.tv,
                                    color: transaction.providerColor,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        transaction.package,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: colorScheme.onSurface,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${transaction.provider} - ${transaction.smartCardNumber}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: mutedTextColor,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _formatDate(transaction.date),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: mutedTextColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '₦${transaction.amount.toStringAsFixed(0)}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            (transaction.status == 'Successful'
                                                    ? colorScheme.primary
                                                    : colorScheme.error)
                                                .withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        transaction.status,
                                        style: TextStyle(
                                          color:
                                              transaction.status == 'Successful'
                                                  ? colorScheme.primary
                                                  : colorScheme.error,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
