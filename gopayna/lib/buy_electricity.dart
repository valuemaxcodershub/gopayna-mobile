import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_service.dart' as api;
import 'service_transaction_history.dart';
import 'widgets/wallet_visibility_builder.dart';
import 'widgets/themed_screen_helpers.dart';

class ElectricityTransaction {
  final String id;
  final String provider;
  final String meterNumber;
  final String customerName;
  final String package;
  final double amount;
  final DateTime date;
  final String status;
  final Color providerColor;

  ElectricityTransaction({
    required this.id,
    required this.provider,
    required this.meterNumber,
    required this.customerName,
    required this.package,
    required this.amount,
    required this.date,
    required this.status,
    required this.providerColor,
  });
}

class BuyElectricityScreen extends StatefulWidget {
  const BuyElectricityScreen({super.key});

  @override
  State<BuyElectricityScreen> createState() => _BuyElectricityScreenState();
}

class _BuyElectricityScreenState extends State<BuyElectricityScreen>
    with ThemedScreenHelpers {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _meterNumberController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  String _selectedProvider = 'eko';
  String _selectedMeterType = 'prepaid'; // prepaid or postpaid
  bool _isLoading = false;
  bool _isVerifying = false;
  bool _isMeterVerified = false;
  bool _showProviderList = false;
  String? _verifiedCustomerName;
  double _walletBalance = 0.0;
  String? _token;
  double _serviceCharge = 100; // Default service charge, fetched from API
  List<ElectricityTransaction> _recentTransactions = [];

  // NelloByte Disco codes: 01=IKEDC, 02=EKEDC, 03=AEDC, 04=KEDCO, 05=EEDC, 06=PHED, 07=IBEDC, 08=KAEDCO, 09=JED, 10=BEDC, 11=YEDC
  final List<Map<String, dynamic>> _providers = [
    {
      'id': 'ikeja',
      'code': '02', // IKEDC
      'name': 'Ikeja Electric (IKEDC)',
      'shortName': 'IKEDC',
      'color': const Color(0xFFFF6600),
      'logo': 'assets/ikedc_logo.png',
      'icon': Icons.bolt_outlined,
      'textColor': Colors.white,
    },
    {
      'id': 'eko',
      'code': '01', // EKEDC
      'name': 'Eko Electricity (EKEDC)',
      'shortName': 'EKEDC',
      'color': const Color(0xFF0066CC),
      'logo': 'assets/ekedc_logo.png',
      'icon': Icons.bolt_outlined,
      'textColor': Colors.white,
    },
    {
      'id': 'abuja',
      'code': '03', // AEDC
      'name': 'Abuja Electricity (AEDC)',
      'shortName': 'AEDC',
      'color': const Color(0xFF800080),
      'logo': 'assets/aedc_logo.png',
      'icon': Icons.bolt_outlined,
      'textColor': Colors.white,
    },
    {
      'id': 'kano',
      'code': '04', // KEDCO
      'name': 'Kano Electricity (KEDCO)',
      'shortName': 'KEDCO',
      'color': const Color(0xFF00CA44),
      'logo': 'assets/kedco_logo.png',
      'icon': Icons.bolt_outlined,
      'textColor': Colors.white,
    },
    {
      'id': 'enugu',
      'code': '05', // EEDC
      'name': 'Enugu Electricity (EEDC)',
      'shortName': 'EEDC',
      'color': const Color(0xFF9932CC),
      'logo': 'assets/eedc_logo.png',
      'icon': Icons.bolt_outlined,
      'textColor': Colors.white,
    },
    {
      'id': 'portharcourt',
      'code': '06', // PHED
      'name': 'Port Harcourt Electric (PHED)',
      'shortName': 'PHED',
      'color': const Color(0xFFDC143C),
      'logo': 'assets/phed_logo.png',
      'icon': Icons.bolt_outlined,
      'textColor': Colors.white,
    },
    {
      'id': 'ibadan',
      'code': '07', // IBEDC
      'name': 'Ibadan Electricity (IBEDC)',
      'shortName': 'IBEDC',
      'color': const Color(0xFFFF4500),
      'logo': 'assets/ibedc_logo.png',
      'icon': Icons.bolt_outlined,
      'textColor': Colors.white,
    },
    {
      'id': 'kaduna',
      'code': '08', // KAEDCO
      'name': 'Kaduna Electric (KAEDCO)',
      'shortName': 'KAEDCO',
      'color': const Color(0xFF228B22),
      'logo': 'assets/kaedco_logo.png',
      'icon': Icons.bolt_outlined,
      'textColor': Colors.white,
    },
    {
      'id': 'jos',
      'code': '09', // JED
      'name': 'Jos Electricity (JED)',
      'shortName': 'JED',
      'color': const Color(0xFF4B0082),
      'logo': 'assets/jed_logo.png',
      'icon': Icons.bolt_outlined,
      'textColor': Colors.white,
    },
    {
      'id': 'benin',
      'code': '10', // BEDC
      'name': 'Benin Electricity (BEDC)',
      'shortName': 'BEDC',
      'color': const Color(0xFF8B4513),
      'logo': 'assets/bedc_logo.png',
      'icon': Icons.bolt_outlined,
      'textColor': Colors.white,
    },
    {
      'id': 'yola',
      'code': '11', // YEDC
      'name': 'Yola Electricity (YEDC)',
      'shortName': 'YEDC',
      'color': const Color(0xFF2E8B57),
      'logo': 'assets/yedc_logo.png',
      'icon': Icons.bolt_outlined,
      'textColor': Colors.white,
    },
  ];

  // Quick amount options for electricity
  final List<int> _quickAmounts = [500, 1000, 2000, 5000, 10000, 20000];

  @override
  void initState() {
    super.initState();
    _loadWalletData();
    _loadRecentTransactions();
    _fetchElectricityPricing();
  }

  Future<void> _fetchElectricityPricing() async {
    try {
      final result = await api.fetchElectricityPricing();
      if (mounted && result['success'] == true) {
        // Get service charge from API response
        final serviceCharge =
            (result['serviceCharge'] as num?)?.toDouble() ?? 100;
        setState(() {
          _serviceCharge = serviceCharge;
        });
      }
    } catch (e) {
      // Use default service charge
      debugPrint('Error fetching electricity pricing: $e');
    }
  }

  Future<void> _loadRecentTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt');
    if (token == null) return;

    final result =
        await api.fetchVTUHistory(token, type: 'electricity', limit: 8);
    if (mounted && result['success'] == true) {
      final data = result['data'] as List? ?? [];
      setState(() {
        _recentTransactions = data.map((tx) {
          final details = tx['details'] as Map<String, dynamic>? ?? {};
          return ElectricityTransaction(
            id: tx['reference']?.toString() ?? '',
            provider: details['disco']?.toString() ?? 'Unknown',
            meterNumber: details['meterNumber']?.toString() ?? '',
            customerName: details['customerName']?.toString() ?? '',
            package: '₦${tx['amount']}',
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

  /// Verify meter number with NelloByte API
  Future<void> _verifyMeterNumber() async {
    final meterNumber = _meterNumberController.text.trim();
    if (meterNumber.isEmpty || meterNumber.length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a valid meter number'),
          backgroundColor: colorScheme.error,
        ),
      );
      return;
    }

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
      _isMeterVerified = false;
      _verifiedCustomerName = null;
    });

    final discoCode = _getDiscoCode(_selectedProvider);
    // Pass meter type: 01=Prepaid, 02=Postpaid
    final meterTypeCode = _selectedMeterType == 'prepaid' ? '01' : '02';
    final result = await api.verifyMeter(_token!, discoCode, meterNumber,
        meterType: meterTypeCode);

    if (mounted) {
      setState(() {
        _isVerifying = false;
      });

      if (result['success'] == true && result['data'] != null) {
        final customerName = result['data']['customerName']?.toString() ?? '';
        if (customerName.isNotEmpty && customerName != 'INVALID_METERNO') {
          setState(() {
            _isMeterVerified = true;
            _verifiedCustomerName = customerName;
          });
          HapticFeedback.mediumImpact();
        } else {
          _showErrorSnackBar(
              'Invalid meter number. Please check and try again.');
        }
      } else {
        _showErrorSnackBar(result['error']?.toString() ??
            'Failed to verify meter. Please try again.');
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

  // Get disco code from provider - use the code property from _providers list
  String _getDiscoCode(String providerId) {
    final provider = _providers.firstWhere(
      (p) => p['id'] == providerId,
      orElse: () => {'code': '01'},
    );
    return provider['code']?.toString() ?? '01';
  }

  @override
  void dispose() {
    _meterNumberController.dispose();
    _phoneController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _buyElectricity() {
    if (_formKey.currentState!.validate()) {
      final amount = double.tryParse(_amountController.text) ?? 0;
      if (amount < 500) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Minimum amount is ₦500'),
            backgroundColor: colorScheme.error,
          ),
        );
        return;
      }
      _showConfirmationDialog();
    }
  }

  void _showConfirmationDialog() {
    final isTablet = MediaQuery.of(context).size.width > 600;
    final amount = double.tryParse(_amountController.text) ?? 0;
    final total = amount + _serviceCharge;
    final meterType = _selectedMeterType == 'prepaid' ? 'Prepaid' : 'Postpaid';
    final cs = colorScheme;
    final card = cardColor;
    final muted = mutedTextColor;
    final surfaceVariant = cs.surfaceContainerHighest;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
          ),
          backgroundColor: card,
          title: Text(
            'Confirm Purchase',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isTablet ? 22 : 18,
              color: cs.onSurface,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Please confirm your electricity purchase details:',
                  style: TextStyle(
                    fontSize: 14,
                    color: muted,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _buildConfirmationRow(
                          'Provider', _selectedProviderData['name']),
                      const SizedBox(height: 8),
                      _buildConfirmationRow(
                          'Meter Number', _meterNumberController.text),
                      const SizedBox(height: 8),
                      _buildConfirmationRow(
                          'Phone Number', _phoneController.text),
                      const SizedBox(height: 8),
                      _buildConfirmationRow('Meter Type', meterType),
                      const SizedBox(height: 8),
                      _buildConfirmationRow(
                          'Electricity', '₦${amount.toStringAsFixed(0)}'),
                      const SizedBox(height: 8),
                      _buildConfirmationRow('Service Charge',
                          '₦${_serviceCharge.toStringAsFixed(0)}'),
                      const Divider(height: 16),
                      _buildConfirmationRow(
                          'Total to Pay', '₦${total.toStringAsFixed(0)}',
                          highlight: true),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: muted),
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

  Widget _buildConfirmationRow(String label, String value,
      {bool highlight = false}) {
    return Row(
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: TextStyle(
              fontSize: highlight ? 15 : 14,
              fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
              color: highlight ? colorScheme.primary : colorScheme.onSurface,
            ),
          ),
        ),
        const Text(': '),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: highlight ? 16 : 14,
              fontWeight: FontWeight.w600,
              color: highlight ? colorScheme.primary : colorScheme.onSurface,
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
    final totalToPay = amount + _serviceCharge;

    if (amount < 500) {
      _showErrorDialog('Minimum amount is ₦500.');
      return;
    }

    if (totalToPay > _walletBalance) {
      _showErrorDialog(
          'Insufficient wallet balance. You need ₦${totalToPay.toStringAsFixed(0)} (₦${amount.toStringAsFixed(0)} + ₦${_serviceCharge.toStringAsFixed(0)} service charge).');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Convert provider ID to NelloByte disco code
    final discoCode = _getDiscoCode(_selectedProvider);
    // Meter type: 01=Prepaid, 02=Postpaid
    final meterTypeCode = _selectedMeterType == 'prepaid' ? '01' : '02';

    final result = await api.buyElectricity(
      _token!,
      disco: discoCode,
      meterType: meterTypeCode,
      meterNumber: _meterNumberController.text,
      amount:
          amount, // Send electricity amount only, backend adds service charge
      phone: _phoneController.text,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (result['success'] == true) {
      _loadWalletData();
      // Show token if returned
      final data = result['data']?['data'];
      if (data != null && data['token'] != null) {
        _showSuccessDialogWithToken(data['token']);
      } else {
        _showSuccessDialog();
      }
    } else {
      _showErrorDialog(
          result['error'] ?? 'Transaction failed. Please try again.');
    }
  }

  void _showSuccessDialogWithToken(String token) {
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
              Icon(Icons.check_circle,
                  color: Colors.green, size: isTablet ? 32 : 24),
              SizedBox(width: isTablet ? 12 : 8),
              Text(
                'Success',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: isTablet ? 22 : 18,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Electricity purchase successful!',
                style: TextStyle(
                    fontSize: isTablet ? 16 : 14, color: cs.onSurface),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: Colors.green.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Token:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      token,
                      style: TextStyle(
                        fontSize: isTablet ? 18 : 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        color: Colors.green.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: token));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Token copied to clipboard')),
                );
              },
              child: const Text('Copy Token'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.primary,
                foregroundColor: cs.onPrimary,
              ),
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
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
    final amount = double.tryParse(_amountController.text) ?? 0;

    final cs = colorScheme;

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
                colors: [cs.primary, cs.primary.withValues(alpha: 0.85)],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
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
                  'Electricity Purchase Successful!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'You successfully purchased ₦${amount.toStringAsFixed(0)} ${selectedProviderData['name']} electricity for meter ${_meterNumberController.text}',
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
                      backgroundColor: Colors.white,
                      foregroundColor: cs.primary,
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
          'Electricity',
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
                    'Wallet Balance: $balanceText',
                    style: TextStyle(
                      fontSize: isTablet ? 14 : 12,
                      color: muted,
                    ),
                  );
                },
              ),
              SizedBox(height: isTablet ? 24 : 16),

              // Provider Selection Dropdown
              Container(
                decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: border),
                  boxShadow: isDarkMode
                      ? null
                      : [
                          BoxShadow(
                            color: shadow,
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                      child: Text(
                        'Select Provider',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                    // Selected Provider Display (tappable dropdown)
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _showProviderList = !_showProviderList;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: border),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: _selectedProviderData['color'],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.asset(
                                  _selectedProviderData['logo'],
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Icon(
                                    _selectedProviderData['icon'],
                                    color: _selectedProviderData['textColor'],
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                _selectedProviderData['name'],
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: cs.onSurface,
                                ),
                              ),
                            ),
                            Icon(
                              _showProviderList
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              color: muted,
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Provider Options List (expandable)
                    AnimatedSize(
                      duration: const Duration(milliseconds: 200),
                      child: _showProviderList
                          ? Container(
                              margin: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: cs.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: _providers.map((provider) {
                                  final isSelected =
                                      _selectedProvider == provider['id'];
                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedProvider = provider['id'];
                                        _isMeterVerified = false;
                                        _verifiedCustomerName = null;
                                        _showProviderList = false;
                                      });
                                      HapticFeedback.lightImpact();
                                    },
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(
                                          vertical: 4),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? cs.primary.withValues(alpha: 0.08)
                                            : card,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: isSelected
                                              ? cs.primary
                                              : Colors.transparent,
                                          width: 2,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              color: provider['color'],
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: Image.asset(
                                                provider['logo'],
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error,
                                                        stackTrace) =>
                                                    Icon(
                                                  provider['icon'],
                                                  color: Colors.white,
                                                  size: 22,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              provider['name'],
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                                color: cs.onSurface,
                                              ),
                                            ),
                                          ),
                                          if (isSelected)
                                            Icon(
                                              Icons.check_circle,
                                              color: cs.primary,
                                              size: 22,
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            )
                          : const SizedBox(height: 20),
                    ),
                  ],
                ),
              ),

              SizedBox(height: isTablet ? 20 : 16),

              // Meter Type Selection (Prepaid/Postpaid)
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
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                      child: Text(
                        'Meter Type',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      decoration: BoxDecoration(
                        color: surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedMeterType,
                          isExpanded: true,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          borderRadius: BorderRadius.circular(12),
                          dropdownColor: card,
                          icon: Icon(Icons.keyboard_arrow_down,
                              color: cs.primary),
                          items: [
                            DropdownMenuItem<String>(
                              value: 'prepaid',
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.green.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.flash_on,
                                        color: Colors.green, size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Prepaid Meter',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: cs.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            DropdownMenuItem<String>(
                              value: 'postpaid',
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.receipt_long,
                                        color: Colors.blue, size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Postpaid Meter',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: cs.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedMeterType = value;
                              });
                              HapticFeedback.selectionClick();
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: isTablet ? 20 : 16),

              // Meter Number Field with Verify Button
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _meterNumberController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (value) {
                        // Reset verification when meter number changes
                        if (_isMeterVerified) {
                          setState(() {
                            _isMeterVerified = false;
                            _verifiedCustomerName = null;
                          });
                        }
                      },
                      decoration: InputDecoration(
                        labelText: 'Meter Number',
                        labelStyle: TextStyle(
                          fontSize: isTablet ? 18 : 16,
                          color: muted,
                        ),
                        prefixIcon: Icon(
                          Icons.electric_meter,
                          color: cs.primary,
                          size: isTablet ? 28 : 24,
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
                                        cs.primary),
                                  ),
                                ),
                              )
                            : TextButton(
                                onPressed: _verifyMeterNumber,
                                child: Text(
                                  'Verify',
                                  style: TextStyle(
                                    color: cs.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(
                              Radius.circular(isTablet ? 20 : 16)),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: card,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(
                              Radius.circular(isTablet ? 20 : 16)),
                          borderSide: BorderSide(
                              color: _isMeterVerified ? Colors.green : border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(
                              Radius.circular(isTablet ? 20 : 16)),
                          borderSide: BorderSide(color: cs.primary, width: 2),
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
                          return 'Please enter meter number';
                        }
                        if (value.length < 10) {
                          return 'Meter number must be at least 10 digits';
                        }
                        return null;
                      },
                    ),
                    // Show verified customer name
                    if (_isMeterVerified && _verifiedCustomerName != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(isTablet ? 20 : 16),
                            bottomRight: Radius.circular(isTablet ? 20 : 16),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle,
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

              // Phone Number Field
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
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    labelStyle: TextStyle(color: muted),
                    prefixIcon: Icon(
                      Icons.phone,
                      color: cs.primary,
                    ),
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(16)),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: card,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: const BorderRadius.all(Radius.circular(16)),
                      borderSide: BorderSide(color: border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: const BorderRadius.all(Radius.circular(16)),
                      borderSide: BorderSide(color: cs.primary, width: 2),
                    ),
                    contentPadding: const EdgeInsets.all(20),
                  ),
                  style: TextStyle(
                    fontSize: 16,
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

              const SizedBox(height: 20),

              // Amount Input Field
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
                    TextFormField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        labelText: 'Amount (₦)',
                        hintText: 'Enter amount (Min: ₦500)',
                        labelStyle: TextStyle(color: muted),
                        hintStyle:
                            TextStyle(color: muted.withValues(alpha: 0.6)),
                        prefixIcon: Icon(
                          Icons.payments_outlined,
                          color: cs.primary,
                        ),
                        prefixText: '₦ ',
                        prefixStyle: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                        border: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(16)),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: card,
                        enabledBorder: OutlineInputBorder(
                          borderRadius:
                              const BorderRadius.all(Radius.circular(16)),
                          borderSide: BorderSide(color: border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius:
                              const BorderRadius.all(Radius.circular(16)),
                          borderSide: BorderSide(color: cs.primary, width: 2),
                        ),
                        contentPadding: const EdgeInsets.all(20),
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
                        final amount = double.tryParse(value) ?? 0;
                        if (amount < 500) {
                          return 'Minimum amount is ₦500';
                        }
                        return null;
                      },
                    ),
                    // Quick amount buttons
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Quick Select',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: muted,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _quickAmounts.map((amount) {
                              final isSelected =
                                  _amountController.text == amount.toString();
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _amountController.text = amount.toString();
                                  });
                                  HapticFeedback.lightImpact();
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? cs.primary
                                        : surfaceVariant,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isSelected ? cs.primary : border,
                                    ),
                                  ),
                                  child: Text(
                                    '₦${amount >= 1000 ? '${(amount / 1000).toStringAsFixed(amount % 1000 == 0 ? 0 : 1)}k' : amount}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected
                                          ? cs.onPrimary
                                          : cs.onSurface,
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

              SizedBox(height: isTablet ? 40 : 30),

              // Purchase Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _buyElectricity,
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
                          'Buy Electricity',
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
                                'Recent Electricity Purchases',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: cs.onSurface,
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
                                      serviceType: ServiceType.electricity,
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
                        itemCount: _recentTransactions.take(8).length,
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
                                    color: transaction.providerColor
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: transaction.providerColor
                                          .withValues(alpha: 0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.electric_bolt,
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
                                        transaction.provider,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: cs.onSurface,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Meter: ${transaction.meterNumber}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: muted,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _formatDate(transaction.date),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: muted,
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
                                        color: cs.onSurface,
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
                                            transaction.status == 'Successful'
                                                ? const Color(0xFF00CA44)
                                                    .withValues(alpha: 0.15)
                                                : Colors.red
                                                    .withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        transaction.status,
                                        style: TextStyle(
                                          color:
                                              transaction.status == 'Successful'
                                                  ? const Color(0xFF00CA44)
                                                  : Colors.red.shade700,
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
