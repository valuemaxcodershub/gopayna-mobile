import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_service.dart' as api;
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
  String _selectedPackage = '';
  final String _selectedMeterType = 'prepaid';
  bool _isLoading = false;
  double _walletBalance = 0.0;
  String? _token;
  List<ElectricityTransaction> _recentTransactions = [];

  final List<Map<String, dynamic>> _providers = [
    {
      'id': 'eko',
      'name': 'Eko Electricity (EKEDC)',
      'shortName': 'EKEDC',
      'color': const Color(0xFF0066CC),
      'icon': Icons.bolt_outlined,
      'textColor': Colors.white,
    },
    {
      'id': 'ikeja',
      'name': 'Ikeja Electric (IE)',
      'shortName': 'IE',
      'color': const Color(0xFFFF6600),
      'icon': Icons.bolt_outlined,
      'textColor': Colors.white,
    },
    {
      'id': 'abuja',
      'name': 'Abuja Electricity (AEDC)',
      'shortName': 'AEDC',
      'color': const Color(0xFF800080),
      'icon': Icons.bolt_outlined,
      'textColor': Colors.white,
    },
    {
      'id': 'kano',
      'name': 'Kano Electricity (KEDCO)',
      'shortName': 'KEDCO',
      'color': const Color(0xFF00CA44),
      'icon': Icons.bolt_outlined,
      'textColor': Colors.white,
    },
    {
      'id': 'portharcourt',
      'name': 'Port Harcourt Electric (PHED)',
      'shortName': 'PHED',
      'color': const Color(0xFFDC143C),
      'icon': Icons.bolt_outlined,
      'textColor': Colors.white,
    },
    {
      'id': 'jos',
      'name': 'Jos Electricity (JED)',
      'shortName': 'JED',
      'color': const Color(0xFF4B0082),
      'icon': Icons.bolt_outlined,
      'textColor': Colors.white,
    },
    {
      'id': 'kaduna',
      'name': 'Kaduna Electric (KAEDCO)',
      'shortName': 'KAEDCO',
      'color': const Color(0xFF228B22),
      'icon': Icons.bolt_outlined,
      'textColor': Colors.white,
    },
    {
      'id': 'ibadan',
      'name': 'Ibadan Electricity (IBEDC)',
      'shortName': 'IBEDC',
      'color': const Color(0xFFFF4500),
      'icon': Icons.bolt_outlined,
      'textColor': Colors.white,
    },
  ];

  final Map<String, List<Map<String, dynamic>>> _packages = {
    'eko': [
      {'bundle': '₦500', 'price': 500, 'type': 'Prepaid'},
      {'bundle': '₦1,000', 'price': 1000, 'type': 'Prepaid'},
      {'bundle': '₦2,000', 'price': 2000, 'type': 'Prepaid'},
      {'bundle': '₦5,000', 'price': 5000, 'type': 'Prepaid'},
      {'bundle': '₦10,000', 'price': 10000, 'type': 'Prepaid'},
      {'bundle': '₦20,000', 'price': 20000, 'type': 'Prepaid'},
    ],
    'ikeja': [
      {'bundle': '₦500', 'price': 500, 'type': 'Prepaid'},
      {'bundle': '₦1,000', 'price': 1000, 'type': 'Prepaid'},
      {'bundle': '₦2,000', 'price': 2000, 'type': 'Prepaid'},
      {'bundle': '₦5,000', 'price': 5000, 'type': 'Prepaid'},
      {'bundle': '₦10,000', 'price': 10000, 'type': 'Prepaid'},
      {'bundle': '₦20,000', 'price': 20000, 'type': 'Prepaid'},
    ],
    'abuja': [
      {'bundle': '₦500', 'price': 500, 'type': 'Prepaid'},
      {'bundle': '₦1,000', 'price': 1000, 'type': 'Prepaid'},
      {'bundle': '₦2,000', 'price': 2000, 'type': 'Prepaid'},
      {'bundle': '₦5,000', 'price': 5000, 'type': 'Prepaid'},
      {'bundle': '₦10,000', 'price': 10000, 'type': 'Prepaid'},
      {'bundle': '₦20,000', 'price': 20000, 'type': 'Prepaid'},
    ],
    'kano': [
      {'bundle': '₦500', 'price': 500, 'type': 'Prepaid'},
      {'bundle': '₦1,000', 'price': 1000, 'type': 'Prepaid'},
      {'bundle': '₦2,000', 'price': 2000, 'type': 'Prepaid'},
      {'bundle': '₦5,000', 'price': 5000, 'type': 'Prepaid'},
      {'bundle': '₦10,000', 'price': 10000, 'type': 'Prepaid'},
      {'bundle': '₦20,000', 'price': 20000, 'type': 'Prepaid'},
    ],
    'portharcourt': [
      {'bundle': '₦500', 'price': 500, 'type': 'Prepaid'},
      {'bundle': '₦1,000', 'price': 1000, 'type': 'Prepaid'},
      {'bundle': '₦2,000', 'price': 2000, 'type': 'Prepaid'},
      {'bundle': '₦5,000', 'price': 5000, 'type': 'Prepaid'},
      {'bundle': '₦10,000', 'price': 10000, 'type': 'Prepaid'},
      {'bundle': '₦20,000', 'price': 20000, 'type': 'Prepaid'},
    ],
    'jos': [
      {'bundle': '₦500', 'price': 500, 'type': 'Prepaid'},
      {'bundle': '₦1,000', 'price': 1000, 'type': 'Prepaid'},
      {'bundle': '₦2,000', 'price': 2000, 'type': 'Prepaid'},
      {'bundle': '₦5,000', 'price': 5000, 'type': 'Prepaid'},
      {'bundle': '₦10,000', 'price': 10000, 'type': 'Prepaid'},
      {'bundle': '₦20,000', 'price': 20000, 'type': 'Prepaid'},
    ],
    'kaduna': [
      {'bundle': '₦500', 'price': 500, 'type': 'Prepaid'},
      {'bundle': '₦1,000', 'price': 1000, 'type': 'Prepaid'},
      {'bundle': '₦2,000', 'price': 2000, 'type': 'Prepaid'},
      {'bundle': '₦5,000', 'price': 5000, 'type': 'Prepaid'},
      {'bundle': '₦10,000', 'price': 10000, 'type': 'Prepaid'},
      {'bundle': '₦20,000', 'price': 20000, 'type': 'Prepaid'},
    ],
    'ibadan': [
      {'bundle': '₦500', 'price': 500, 'type': 'Prepaid'},
      {'bundle': '₦1,000', 'price': 1000, 'type': 'Prepaid'},
      {'bundle': '₦2,000', 'price': 2000, 'type': 'Prepaid'},
      {'bundle': '₦5,000', 'price': 5000, 'type': 'Prepaid'},
      {'bundle': '₦10,000', 'price': 10000, 'type': 'Prepaid'},
      {'bundle': '₦20,000', 'price': 20000, 'type': 'Prepaid'},
    ],
  };

  @override
  void initState() {
    super.initState();
    _loadWalletData();
    _loadRecentTransactions();
  }

  Future<void> _loadRecentTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt');
    if (token == null) return;

    final result =
        await api.fetchVTUHistory(token, type: 'electricity', limit: 5);
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

  // Map provider IDs to NelloByte disco codes
  String _getDiscoCode(String providerId) {
    switch (providerId) {
      case 'eko':
        return '01'; // Eko Electric - EKEDC
      case 'ikeja':
        return '02'; // Ikeja Electric - IKEDC
      case 'abuja':
        return '03'; // Abuja Electric - AEDC
      case 'kano':
        return '04'; // Kano Electric - KEDC
      case 'portharcourt':
        return '05'; // Port Harcourt Electric - PHEDC
      case 'jos':
        return '06'; // Jos Electric - JEDC
      case 'ibadan':
        return '07'; // Ibadan Electric - IBEDC
      case 'kaduna':
        return '08'; // Kaduna Electric - KAEDC
      case 'enugu':
        return '09'; // Enugu Electric - EEDC
      case 'benin':
        return '10'; // Benin Electric - BEDC
      case 'yola':
        return '11'; // Yola Electric - YEDC
      case 'aba':
        return '12'; // Aba Electric - APLE
      default:
        return '01';
    }
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
      if (_selectedPackage.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please select a package'),
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
    final selectedPackage = _packages[_selectedProvider]!.firstWhere(
      (package) =>
          '${package['bundle']} - ${package['type']}' == _selectedPackage,
    );
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
          content: Column(
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
                    _buildConfirmationRow(
                        'Package', selectedPackage['bundle'] ?? ''),
                    const SizedBox(height: 8),
                    _buildConfirmationRow(
                        'Type', selectedPackage['type'] ?? ''),
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

  Widget _buildConfirmationRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 110,
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
            '${package['bundle']} - ${package['type']}' == _selectedPackage,
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

    // Convert provider ID to NelloByte disco code
    final discoCode = _getDiscoCode(_selectedProvider);
    // Meter type: 01=Prepaid, 02=Postpaid
    final meterTypeCode = _selectedMeterType == 'prepaid' ? '01' : '02';

    final result = await api.buyElectricity(
      _token!,
      disco: discoCode,
      meterType: meterTypeCode,
      meterNumber: _meterNumberController.text,
      amount: amount,
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
    final selectedPackage = _packages[_selectedProvider]!.firstWhere(
      (package) =>
          '${package['bundle']} - ${package['type']}' == _selectedPackage,
    );

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
                  'You successfully purchased ${selectedPackage['bundle']} ${selectedProviderData['name']} electricity for meter ${_meterNumberController.text}',
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

              // Provider Selection
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
                      child: Text(
                        'Select Provider',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _selectedProviderData['color'],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _selectedProviderData['icon'],
                            color: _selectedProviderData['textColor'],
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _selectedProviderData['name'],
                              style: TextStyle(
                                color: _selectedProviderData['textColor'],
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: isTablet ? 4 : 4,
                          crossAxisSpacing: isTablet ? 12 : 8,
                          mainAxisSpacing: isTablet ? 12 : 8,
                          childAspectRatio: isTablet ? 1.0 : 0.85,
                        ),
                        itemCount: _providers.length,
                        itemBuilder: (context, index) {
                          final provider = _providers[index];
                          final isSelected =
                              _selectedProvider == provider['id'];
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedProvider = provider['id'];
                                _selectedPackage = '';
                              });
                              HapticFeedback.lightImpact();
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: EdgeInsets.all(isTablet ? 10 : 6),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? provider['color'].withValues(alpha: 0.15)
                                    : surfaceVariant,
                                borderRadius:
                                    BorderRadius.circular(isTablet ? 12 : 10),
                                border: Border.all(
                                  color:
                                      isSelected ? provider['color'] : border,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: isTablet ? 36 : 30,
                                    height: isTablet ? 36 : 30,
                                    decoration: BoxDecoration(
                                      color: provider['color'],
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Icon(
                                      provider['icon'],
                                      color: Colors.white,
                                      size: isTablet ? 20 : 16,
                                    ),
                                  ),
                                  SizedBox(height: isTablet ? 8 : 4),
                                  Text(
                                    provider['shortName'] ??
                                        provider['name'].split(' ')[0],
                                    style: TextStyle(
                                      color: isSelected
                                          ? provider['color']
                                          : cs.onSurface,
                                      fontSize: isTablet ? 11 : 9,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    textAlign: TextAlign.center,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),

              SizedBox(height: isTablet ? 28 : 20),

              // Meter Number Field
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
                  controller: _meterNumberController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.all(Radius.circular(isTablet ? 20 : 16)),
                      borderSide: BorderSide.none,
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

              // Package Selection
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
                      child: Text(
                        'Select Package',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: isTablet ? 3 : 2,
                          crossAxisSpacing: isTablet ? 10 : 6,
                          mainAxisSpacing: isTablet ? 10 : 6,
                          childAspectRatio: isTablet ? 1.6 : 1.8,
                        ),
                        itemCount: _packages[_selectedProvider]!.length,
                        itemBuilder: (context, index) {
                          final package = _packages[_selectedProvider]![index];
                          final packageId =
                              '${package['bundle']} - ${package['type']}';
                          final isSelected = _selectedPackage == packageId;

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedPackage = packageId;
                              });
                              HapticFeedback.lightImpact();
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: EdgeInsets.all(isTablet ? 4 : 3),
                              padding: EdgeInsets.all(isTablet ? 10 : 6),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? cs.primary.withValues(alpha: 0.08)
                                    : surfaceVariant,
                                borderRadius:
                                    BorderRadius.circular(isTablet ? 12 : 8),
                                border: Border.all(
                                  color: isSelected ? cs.primary : border,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        package['bundle'],
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                          color: isSelected
                                              ? cs.primary
                                              : cs.onSurface,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (isSelected)
                                        Icon(
                                          Icons.check_circle,
                                          color: cs.primary,
                                          size: 13,
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    package['type'],
                                    style: TextStyle(
                                      fontSize: 8,
                                      color: isSelected ? cs.primary : muted,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
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
