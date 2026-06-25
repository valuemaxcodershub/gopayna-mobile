import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'api_service.dart' as api;
import 'services/auth_token_storage.dart';
import 'service_transaction_history.dart';
import 'fund_wallet.dart';
import 'widgets/wallet_visibility_builder.dart';
import 'widgets/themed_screen_helpers.dart';
import 'widgets/purchase_navigation.dart';
import 'design/gopayna_design.dart';

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
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  String _selectedProvider = '';
  String _selectedMeterType = 'prepaid'; // prepaid or postpaid
  bool _isLoading = false;
  bool _isVerifying = false;
  bool _isMeterVerified = false;
  bool _isFetchingBill = false;
  bool _showProviderList = false;
  String? _verifiedCustomerName;
  double _outstandingBill = 0.0;
  double _minimumPayment = 0.0;
  double _walletBalance = 0.0;
  String? _token;
  double _serviceCharge = 100; // Default service charge, fetched from API
  String _electricityProvidersEmptyMessage =
      'No synced electricity providers available';
  List<ElectricityTransaction> _recentTransactions = [];
  Map<String, double> _discoMinAmounts = {};
  Map<String, double> _discoMaxAmounts = {};

  final List<Map<String, dynamic>> _providers = [];

  static const Map<String, Map<String, dynamic>> _providerVisuals = {
    '01': {
      'id': 'eko',
      'color': Color(0xFF0066CC),
      'logo': 'assets/ekedc_logo.png',
      'icon': Icons.bolt_outlined,
      'textColor': Colors.white,
    },
    'IKEDC': {
      'id': 'ikeja',
      'color': Color(0xFFFF6600),
      'logo': 'assets/ikedc_logo.png',
      'icon': Icons.bolt_outlined,
      'textColor': Colors.white,
    },
    '02': {
      'id': 'ikeja',
      'color': Color(0xFFFF6600),
      'logo': 'assets/ikedc_logo.png',
      'icon': Icons.bolt_outlined,
      'textColor': Colors.white,
    },
    'EKEDC': {
      'id': 'eko',
      'color': Color(0xFF0066CC),
      'logo': 'assets/ekedc_logo.png',
      'icon': Icons.bolt_outlined,
      'textColor': Colors.white,
    },
    'AEDC': {
      'id': 'abuja',
      'color': Color(0xFF800080),
      'logo': 'assets/aedc_logo.png',
      'icon': Icons.bolt_outlined,
      'textColor': Colors.white,
    },
    '03': {
      'id': 'abuja',
      'color': Color(0xFF800080),
      'logo': 'assets/aedc_logo.png',
      'icon': Icons.bolt_outlined,
      'textColor': Colors.white,
    },
    'KEDCO': {
      'id': 'kano',
      'color': Color(0xFF00CA44),
      'logo': 'assets/kedco_logo.png',
      'icon': Icons.bolt_outlined,
      'textColor': Colors.white,
    },
    '04': {
      'id': 'kano',
      'color': Color(0xFF00CA44),
      'logo': 'assets/kedco_logo.png',
      'icon': Icons.bolt_outlined,
      'textColor': Colors.white,
    },
    'EEDC': {
      'id': 'enugu',
      'color': Color(0xFF9932CC),
      'logo': 'assets/eedc_logo.png',
      'icon': Icons.bolt_outlined,
      'textColor': Colors.white,
    },
    '09': {
      'id': 'enugu',
      'color': Color(0xFF9932CC),
      'logo': 'assets/eedc_logo.png',
      'icon': Icons.bolt_outlined,
      'textColor': Colors.white,
    },
    'PHED': {
      'id': 'portharcourt',
      'color': Color(0xFFDC143C),
      'logo': 'assets/phed_logo.png',
      'icon': Icons.bolt_outlined,
      'textColor': Colors.white,
    },
    'PHEDC': {
      'id': 'portharcourt',
      'color': Color(0xFFDC143C),
      'logo': 'assets/phed_logo.png',
      'icon': Icons.bolt_outlined,
      'textColor': Colors.white,
    },
    '05': {
      'id': 'portharcourt',
      'color': Color(0xFFDC143C),
      'logo': 'assets/phed_logo.png',
      'icon': Icons.bolt_outlined,
      'textColor': Colors.white,
    },
    'IBEDC': {
      'id': 'ibadan',
      'color': Color(0xFFFF4500),
      'logo': 'assets/ibedc_logo.png',
      'icon': Icons.bolt_outlined,
      'textColor': Colors.white,
    },
    '07': {
      'id': 'ibadan',
      'color': Color(0xFFFF4500),
      'logo': 'assets/ibedc_logo.png',
      'icon': Icons.bolt_outlined,
      'textColor': Colors.white,
    },
    'KAEDCO': {
      'id': 'kaduna',
      'color': Color(0xFF228B22),
      'logo': 'assets/kaedco_logo.png',
      'icon': Icons.bolt_outlined,
      'textColor': Colors.white,
    },
    'KAEDC': {
      'id': 'kaduna',
      'color': Color(0xFF228B22),
      'logo': 'assets/kaedco_logo.png',
      'icon': Icons.bolt_outlined,
      'textColor': Colors.white,
    },
    '08': {
      'id': 'kaduna',
      'color': Color(0xFF228B22),
      'logo': 'assets/kaedco_logo.png',
      'icon': Icons.bolt_outlined,
      'textColor': Colors.white,
    },
    'JED': {
      'id': 'jos',
      'color': Color(0xFF4B0082),
      'logo': 'assets/jed_logo.png',
      'icon': Icons.bolt_outlined,
      'textColor': Colors.white,
    },
    'JEDC': {
      'id': 'jos',
      'color': Color(0xFF4B0082),
      'logo': 'assets/jed_logo.png',
      'icon': Icons.bolt_outlined,
      'textColor': Colors.white,
    },
    '06': {
      'id': 'jos',
      'color': Color(0xFF4B0082),
      'logo': 'assets/jed_logo.png',
      'icon': Icons.bolt_outlined,
      'textColor': Colors.white,
    },
    'BEDC': {
      'id': 'benin',
      'color': Color(0xFF8B4513),
      'logo': 'assets/bedc_logo.png',
      'icon': Icons.bolt_outlined,
      'textColor': Colors.white,
    },
    '10': {
      'id': 'benin',
      'color': Color(0xFF8B4513),
      'logo': 'assets/bedc_logo.png',
      'icon': Icons.bolt_outlined,
      'textColor': Colors.white,
    },
    'YEDC': {
      'id': 'yola',
      'color': Color(0xFF2E8B57),
      'logo': 'assets/yedc_logo.png',
      'icon': Icons.bolt_outlined,
      'textColor': Colors.white,
    },
    '11': {
      'id': 'yola',
      'color': Color(0xFF2E8B57),
      'logo': 'assets/yedc_logo.png',
      'icon': Icons.bolt_outlined,
      'textColor': Colors.white,
    },
    '12': {
      'id': 'aba',
      'color': Color(0xFF1F6F8B),
      'logo': 'assets/aple_logo.png',
      'icon': Icons.bolt_outlined,
      'textColor': Colors.white,
    },
    'APLE': {
      'id': 'aba',
      'color': Color(0xFF1F6F8B),
      'logo': 'assets/aple_logo.png',
      'icon': Icons.bolt_outlined,
      'textColor': Colors.white,
    },
  };

  Widget _buildProviderAvatar(
    Map<String, dynamic> provider, {
    required double size,
    required double radius,
    Color? iconColor,
    double? iconSize,
  }) {
    final logoPath = provider['logo']?.toString() ?? '';
    final resolvedIconColor = iconColor ?? provider['textColor'] as Color? ?? Colors.white;
    final resolvedIconSize = iconSize ?? size * 0.55;

    if (logoPath.isEmpty) {
      return Icon(
        provider['icon'] as IconData? ?? Icons.bolt_outlined,
        color: resolvedIconColor,
        size: resolvedIconSize,
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.asset(
        logoPath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Icon(
          provider['icon'] as IconData? ?? Icons.bolt_outlined,
          color: resolvedIconColor,
          size: resolvedIconSize,
        ),
      ),
    );
  }

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
        final data = result['data'] as List? ?? [];
        final minAmounts = Map<String, double>.from(_discoMinAmounts);
        final maxAmounts = Map<String, double>.from(_discoMaxAmounts);
        final providersByCode = <String, Map<String, dynamic>>{};

        for (final item in data) {
          if (item is Map) {
            final normalizedItem = Map<String, dynamic>.from(item);
            final metadata = _parsePricingMetadata(normalizedItem['metadata']);
            final codeValue =
                _normalizeElectricityProviderCode(normalizedItem);
            if (codeValue.isEmpty) continue;

            final minAmount = _parsePositiveAmountValue(
                  normalizedItem['minAmount'],
                ) ??
                _parsePositiveAmountValue(metadata['minAmount']);
            if (minAmount != null && minAmount > 0) {
              final currentMin = minAmounts[codeValue];
              if (currentMin == null || minAmount < currentMin) {
                minAmounts[codeValue] = minAmount;
              }
            }

            final maxAmount = _parsePositiveAmountValue(
                  normalizedItem['maxAmount'],
                ) ??
                _parsePositiveAmountValue(metadata['maxAmount']);
            if (maxAmount != null && maxAmount > 0) {
              final currentMax = maxAmounts[codeValue];
              if (currentMax == null || maxAmount > currentMax) {
                maxAmounts[codeValue] = maxAmount;
              }
            }

            final visual = _providerVisuals[codeValue] ??
                {
                  'id': codeValue.toLowerCase(),
                  'color': const Color(0xFF0066CC),
                  'logo': '',
                  'icon': Icons.bolt_outlined,
                  'textColor': Colors.white,
                };

            providersByCode.putIfAbsent(codeValue, () {
              return {
                'id': visual['id'],
                'code': codeValue,
                'name': normalizedItem['providerName']?.toString() ??
                    normalizedItem['name']?.toString() ??
                    codeValue,
                'shortName': codeValue,
                'color': visual['color'],
                'logo': visual['logo'],
                'icon': visual['icon'],
                'textColor': visual['textColor'],
              };
            });
          }
        }

        final providers = providersByCode.values.toList();

        setState(() {
          _serviceCharge = serviceCharge;
          _discoMinAmounts = minAmounts;
          _discoMaxAmounts = maxAmounts;
          _providers
            ..clear()
            ..addAll(providers);
          if (_providers.isNotEmpty) {
            final hasSelected = _providers
                .any((provider) => provider['id'] == _selectedProvider);
            if (!hasSelected) {
              _selectedProvider = _providers.first['id']?.toString() ?? '';
            }
            _electricityProvidersEmptyMessage =
                'No synced electricity providers available';
          } else {
            _selectedProvider = '';
            _electricityProvidersEmptyMessage =
                'No synced electricity providers available';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _providers.clear();
          _discoMinAmounts = {};
          _discoMaxAmounts = {};
          _selectedProvider = '';
          _electricityProvidersEmptyMessage =
              'Unable to load synced electricity providers right now';
        });
      }
    }
  }

  Future<void> _loadRecentTransactions() async {
    final token = await AuthTokenStorage.readJwt();
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
            status: () {
              final s = tx['status']?.toString().toLowerCase() ?? '';
              if (s == 'success') return 'Successful';
              if (s == 'pending' || s == 'processing') return 'Pending';
              return 'Failed';
            }(),
            providerColor: const Color(0xFF0066CC),
          );
        }).toList();
      });
    }
  }

  Future<void> _loadWalletData() async {
    _token = await AuthTokenStorage.readJwt();
    if (_token != null) {
      final balance = await api.fetchWalletBalance(_token!);
      if (mounted && balance != null) {
        setState(() {
          _walletBalance = balance;
        });
      }
    }
  }

  bool _isRealElectricityCustomerName(String name) {
    final normalized = name.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.isEmpty || normalized.length < 3) {
      return false;
    }
    final upper = normalized.toUpperCase();
    const blocked = {
      'N/A',
      'NA',
      'NOT AVAILABLE',
      'UNKNOWN',
      'PREPAID CUSTOMER',
      'POSTPAID CUSTOMER',
      'PREPAID',
      'POSTPAID',
      'CUSTOMER',
      'METER CUSTOMER',
      'METER OWNER',
      'INVALID_METERNO',
    };
    if (blocked.contains(upper)) return false;
    if (upper.contains('INVALID')) return false;
    if (RegExp(r'^(PREPAID|POSTPAID)(\s+CUSTOMER)?$').hasMatch(upper)) {
      return false;
    }
    return RegExp(r'[A-Za-z]').hasMatch(normalized);
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
      _outstandingBill = 0.0;
      _minimumPayment = 0.0;
    });

    final discoCode = _getDiscoCode(_selectedProvider);
    if (discoCode.isEmpty) {
      _showErrorSnackBar('No synced electricity provider available for verification.');
      return;
    }
    final meterTypeCode = _selectedMeterType == 'prepaid' ? '01' : '02';
    final result = await api.verifyMeter(_token!, discoCode, meterNumber,
        meterType: meterTypeCode);

    if (mounted) {
      setState(() {
        _isVerifying = false;
      });

      if (result['success'] == true && result['data'] != null) {
        final customerName = result['data']['customerName']?.toString() ?? '';
        if (_isRealElectricityCustomerName(customerName)) {
            final verifiedMinAmount =
              _parsePositiveAmountValue(result['data']['minAmount']);
            final verifiedMaxAmount =
              _parsePositiveAmountValue(result['data']['maxAmount']);
          setState(() {
            _isMeterVerified = true;
            _verifiedCustomerName = customerName;
            if (verifiedMinAmount != null && verifiedMinAmount > 0) {
              _discoMinAmounts[discoCode] = verifiedMinAmount;
            }
            if (verifiedMaxAmount != null && verifiedMaxAmount > 0) {
              _discoMaxAmounts[discoCode] = verifiedMaxAmount;
            }
          });

          await _fetchElectricityPricing();

          // For postpaid meters, fetch outstanding bill
          if (_selectedMeterType == 'postpaid') {
            await _fetchOutstandingBill(discoCode, meterNumber);
          }

          HapticFeedback.mediumImpact();
        } else {
          _showErrorSnackBar(
            'Could not confirm the meter owner name. Check the meter number and selected electricity provider, then verify again.',
          );
        }
      } else {
        final providerName =
            _selectedProviderData['name']?.toString() ?? 'Selected provider';
        final providerCode = _getDiscoCode(_selectedProvider);
        final errorMessage = result['error']?.toString() ??
            'Could not verify this meter. Check the meter number and selected electricity provider.';
        _showErrorSnackBar('$errorMessage ($providerName, code $providerCode)');
      }
    }
  }

  /// Fetch outstanding bill for postpaid meters
  Future<void> _fetchOutstandingBill(
      String discoCode, String meterNumber) async {
    setState(() {
      _isFetchingBill = true;
    });

    try {
      final result =
          await api.fetchElectricityBill(_token!, discoCode, meterNumber, '02');

      setState(() {
        _isFetchingBill = false;
      });

      if (result['success'] == true && result['data'] != null) {
        final billData = result['data'];
        setState(() {
          _outstandingBill = (billData['outstandingBill'] ?? 0).toDouble();
          _minimumPayment = (billData['minimumPayment'] ?? 1000).toDouble();
        });

        if (_outstandingBill > 0 && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Outstanding bill: ₦${_outstandingBill.toStringAsFixed(0)}. Minimum payment: ₦${_minimumPayment.toStringAsFixed(0)}'),
              backgroundColor: Colors.blue,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } else {
        // Fallback values if bill fetch fails
        setState(() {
          _minimumPayment = 0.0;
          _outstandingBill = 0.0;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                  'Postpaid bill inquiry is unavailable right now. You can still proceed if the meter details are correct.'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isFetchingBill = false;
        _minimumPayment = 0.0;
        _outstandingBill = 0.0;
      });

      // Don't show error to user, just set default minimum
    }
  }

  double _parseAmount(String value) {
    // Remove commas and parse the number
    final cleanValue = value.replaceAll(',', '');
    return double.tryParse(cleanValue) ?? 0.0;
  }

  double? _parsePositiveAmountValue(dynamic value) {
    if (value == null) return null;
    if (value is num) {
      final amount = value.toDouble();
      return amount > 0 ? amount : null;
    }

    final normalized = value.toString().replaceAll(',', '').trim();
    if (normalized.isEmpty) return null;

    final amount = double.tryParse(normalized);
    if (amount == null || amount <= 0) return null;
    return amount;
  }

  Map<String, dynamic> _parsePricingMetadata(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return const {};
  }

  String _normalizeElectricityProviderCode(Map<String, dynamic> item) {
    final metadata = _parsePricingMetadata(item['metadata']);
    final candidates = [
      item['providerCode'],
      metadata['discoCode'],
      item['code'],
      item['providerId'],
      metadata['serviceId'],
      item['providerName'],
      item['name'],
    ];

    for (final candidate in candidates) {
      final value = candidate?.toString().trim();
      if (value == null || value.isEmpty) {
        continue;
      }

      final upperValue = value.toUpperCase();
      if (_providerVisuals.containsKey(upperValue)) {
        return upperValue;
      }

      if (upperValue.contains('ABA') || upperValue.contains('APLE')) {
        return 'APLE';
      }
      if (upperValue.contains('PORT') || upperValue.contains('PHED')) {
        return 'PHED';
      }
      if (upperValue.contains('KADUNA') || upperValue.contains('KAED')) {
        return 'KAEDC';
      }
      if (upperValue.contains('JOS') || upperValue.contains('JED')) {
        return 'JEDC';
      }
      if (upperValue.contains('IBADAN') || upperValue.contains('IBEDC')) {
        return '07';
      }
      if (upperValue.contains('IKEJA') || upperValue.contains('IKEDC')) {
        return '02';
      }
      if (upperValue.contains('EKO') || upperValue.contains('EKEDC')) {
        return '01';
      }
      if (RegExp(r'^\d{1,2}$').hasMatch(upperValue)) {
        return upperValue.padLeft(2, '0');
      }
    }

    return '';
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: colorScheme.error,
      ),
    );
  }

  Future<void> _showInsufficientWalletDialog(double totalToPay) async {
    final isTablet = MediaQuery.of(context).size.width > 600;
    final cs = colorScheme;
    final muted = mutedTextColor;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
        ),
        title: Text(
          'Insufficient Balance',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isTablet ? 20 : 18,
            color: cs.onSurface,
          ),
        ),
        content: Text(
          'You need ₦${totalToPay.toStringAsFixed(0)} to complete this purchase. Please fund your wallet.',
          style: TextStyle(
            fontSize: isTablet ? 14 : 13,
            color: muted,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel', style: TextStyle(color: muted)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FundWalletScreen(),
                ),
              );
              if (mounted) _loadWalletData();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: cs.primary,
              foregroundColor: cs.onPrimary,
            ),
            child: const Text('Fund Wallet'),
          ),
        ],
      ),
    );
  }

  // Get disco code from provider - use the code property from _providers list
  String _getDiscoCode(String providerId) {
    final provider = _providers.firstWhere(
      (p) => p['id'] == providerId,
      orElse: () => {'code': ''},
    );
    return provider['code']?.toString() ?? '';
  }

  double? _getSupportedMinimumAmountForProvider(String providerId) {
    final code = _getDiscoCode(providerId);
    final minAmount = _discoMinAmounts[code];
    if (minAmount != null && minAmount > 0) {
      return minAmount;
    }
    return null;
  }

  double? _getSupportedMaximumAmountForProvider(String providerId) {
    final code = _getDiscoCode(providerId);
    final maxAmount = _discoMaxAmounts[code];
    if (maxAmount != null && maxAmount > 0) {
      return maxAmount;
    }
    return null;
  }

  bool _hasProviderAmountSupport(String providerId) {
    return _getSupportedMinimumAmountForProvider(providerId) != null &&
        _getSupportedMaximumAmountForProvider(providerId) != null;
  }

  double _getMinimumAmountForProvider(String providerId) {
    final minAmount = _getSupportedMinimumAmountForProvider(providerId);
    return minAmount ?? 0;
  }

  double _getMaximumAmountForProvider(String providerId) {
    final maxAmount = _getSupportedMaximumAmountForProvider(providerId);
    return maxAmount ?? 0;
  }

  String _formatCurrencyLabel(double amount) {
    return '₦${NumberFormat('#,##0').format(amount)}';
  }

  String _formatProviderLabel(Map<String, dynamic> provider) {
    final name = provider['name']?.toString() ?? 'Select Provider';
    final code = provider['code']?.toString();
    if (code == null || code.isEmpty) {
      return name;
    }
    return '$name (Code: $code)';
  }

  @override
  void dispose() {
    _meterNumberController.dispose();
    _emailController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _buyElectricity() {
    if (_formKey.currentState!.validate()) {
      if (!_isMeterVerified ||
          !_isRealElectricityCustomerName(_verifiedCustomerName ?? '')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Verify the meter first. A real account holder name is required before you can pay.',
            ),
            backgroundColor: colorScheme.error,
          ),
        );
        return;
      }
      if (_providers.isEmpty || _selectedProvider.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('No synced electricity providers available'),
            backgroundColor: colorScheme.error,
          ),
        );
        return;
      }
      if (!_hasProviderAmountSupport(_selectedProvider)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Provider amount limits are not available yet. Verify the meter first or refresh synced pricing.'),
            backgroundColor: colorScheme.error,
          ),
        );
        return;
      }
      final amount = _parseAmount(_amountController.text);
      final minimumAmount = _selectedMeterType == 'prepaid'
          ? _getMinimumAmountForProvider(_selectedProvider)
          : (_minimumPayment > 0
            ? _minimumPayment
            : _getMinimumAmountForProvider(_selectedProvider));
      final maximumAmount = _getMaximumAmountForProvider(_selectedProvider);
      if (amount < minimumAmount) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_selectedMeterType == 'prepaid'
                ? 'Minimum amount is ₦${minimumAmount.toStringAsFixed(0)}'
                : 'Minimum payment is ₦${_minimumPayment.toStringAsFixed(0)}'),
            backgroundColor: colorScheme.error,
          ),
        );
        return;
      }
      if (amount > maximumAmount) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Maximum amount is ₦${maximumAmount.toStringAsFixed(0)} for this provider'),
            backgroundColor: colorScheme.error,
          ),
        );
        return;
      }
      final totalToPay = amount + _serviceCharge;
      if (totalToPay > _walletBalance) {
        _showInsufficientWalletDialog(totalToPay);
        return;
      }
      _showConfirmationDialog();
    }
  }

  void _showConfirmationDialog() {
    final isTablet = MediaQuery.of(context).size.width > 600;
    final amount = _parseAmount(_amountController.text);
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
                          'Delivery Email', _emailController.text),
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

  Widget _buildAmountSupportRow({
    required String label,
    required String value,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  void _processPurchase() async {
    if (_token == null) {
      _showErrorDialog('Session expired. Please login again.');
      return;
    }

    if (!_isMeterVerified ||
        !_isRealElectricityCustomerName(_verifiedCustomerName ?? '')) {
      _showErrorDialog(
        'Verify the meter and confirm the account holder name before paying.',
      );
      return;
    }

    final amount = _parseAmount(_amountController.text);
    final totalToPay = amount + _serviceCharge;
    if (!_hasProviderAmountSupport(_selectedProvider)) {
      _showErrorDialog('Provider amount limits are not available yet. Verify the meter first or refresh synced pricing.');
      return;
    }
    final minimumAmount = _selectedMeterType == 'prepaid'
        ? _getMinimumAmountForProvider(_selectedProvider)
      : (_minimumPayment > 0
        ? _minimumPayment
        : _getMinimumAmountForProvider(_selectedProvider));
    final maximumAmount = _getMaximumAmountForProvider(_selectedProvider);

    if (amount < minimumAmount) {
      _showErrorDialog(_selectedMeterType == 'prepaid'
          ? 'Minimum amount is ₦${minimumAmount.toStringAsFixed(0)}.'
          : 'Minimum payment is ₦${_minimumPayment.toStringAsFixed(0)}.');
      return;
    }

    if (amount > maximumAmount) {
      _showErrorDialog(
          'Maximum amount is ₦${maximumAmount.toStringAsFixed(0)} for this provider.');
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

    final discoCode = _getDiscoCode(_selectedProvider);
    if (discoCode.isEmpty) {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('No synced electricity provider available for this purchase.');
      return;
    }

    final meterTypeCode = _selectedMeterType == 'prepaid' ? '01' : '02';

    final result = await api.buyElectricity(
      _token!,
      disco: discoCode,
      meterType: meterTypeCode,
      meterNumber: _meterNumberController.text,
      amount: amount,
      email: _emailController.text.trim(),
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (result['success'] == true) {
      _loadWalletData();
      final root = result['data'];
      Map<String, dynamic>? data;
      if (root is Map<String, dynamic>) {
        final inner = root['data'];
        if (inner is Map<String, dynamic>) {
          data = inner;
        } else {
          data = root;
        }
      }
      final isPending = result['pending'] == true || data?['isPending'] == true;
      if (!mounted) return;
      final ref = (data?['reference'] ?? 'Unknown').toString();
      final customerName = (data?['customerName']?.toString().trim().isNotEmpty == true)
          ? data!['customerName'].toString().trim()
          : _verifiedCustomerName?.trim();
      openPurchaseOutcome(
        context,
        reference: ref,
        isPending: isPending,
        summaryLine:
            '${_selectedMeterType == 'prepaid' ? 'Prepaid' : 'Postpaid'} · ${_formatProviderLabel(_selectedProviderData)} · Meter ${_meterNumberController.text}',
        customerName: customerName,
        successMessage: isPending
            ? null
            : (data != null && data['token'] != null
                ? 'Your electricity token is ready. Open your receipt below.'
                : 'Your electricity purchase was successful. Open your receipt below.'),
      );
    } else {
      // Handle different error types
      final isRefunded = result['refunded'] == true;
      final referenceText = result['reference']?.toString().trim();
      final reference = (referenceText == null || referenceText.isEmpty)
          ? null
          : referenceText;

      if (isRefunded) {
        _showRefundedErrorDialog(
            result['error'] ??
                'Transaction failed. Your wallet has been refunded.',
            reference ?? 'Unavailable');
      } else {
        _showErrorDialog(GoPaynaUxHelpers.augmentProviderError(
            result['error'] ?? 'Transaction failed. Please try again.'));
      }
    }
  }

  void _showErrorDialog(String message, [String? reference]) {
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
                'Transaction Failed',
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
                message,
                style: TextStyle(
                  fontSize: isTablet ? 16 : 14,
                  color: cs.onSurface,
                ),
              ),
              if (reference != null) ...[
                const SizedBox(height: 12),
                Text(
                  'Reference: $reference',
                  style: TextStyle(
                    fontSize: isTablet ? 12 : 10,
                    color: cs.onSurface.withValues(alpha: 0.7),
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ],
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

  void _showRefundedErrorDialog(String message, String reference) {
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
              Icon(Icons.account_balance_wallet,
                  color: Colors.blue, size: isTablet ? 32 : 24),
              SizedBox(width: isTablet ? 12 : 8),
              Text(
                'Wallet Refunded',
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
                message,
                style: TextStyle(
                  fontSize: isTablet ? 16 : 14,
                  color: cs.onSurface,
                ),
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
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Your wallet has been automatically refunded',
                        style: TextStyle(
                          fontSize: isTablet ? 14 : 12,
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Reference: $reference',
                style: TextStyle(
                  fontSize: isTablet ? 12 : 10,
                  color: cs.onSurface.withValues(alpha: 0.7),
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: reference));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Reference copied to clipboard')),
                );
              },
              child: const Text('Copy Reference'),
            ),
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

  Map<String, dynamic> get _selectedProviderData => _providers.firstWhere(
        (p) => p['id'] == _selectedProvider,
        orElse: () => {
          'id': '',
          'code': '',
          'name': 'Select Provider',
          'shortName': '',
          'color': const Color(0xFF0066CC),
          'logo': '',
          'icon': Icons.bolt_outlined,
          'textColor': Colors.white,
        },
      );

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
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ServiceTransactionHistoryScreen(
                    serviceType: ServiceType.electricity,
                  ),
                ),
              );
            },
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
      body: SafeArea(
        child: SingleChildScrollView(
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
                        onTap: _providers.isEmpty
                            ? null
                            : () {
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
                                child: _buildProviderAvatar(
                                  _selectedProviderData,
                                  size: 44,
                                  radius: 10,
                                  iconSize: 24,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  _formatProviderLabel(_selectedProviderData),
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
                        child: _providers.isEmpty
                            ? Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(20, 8, 20, 20),
                                child: Text(
                                  _electricityProvidersEmptyMessage,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: muted,
                                  ),
                                ),
                              )
                            : _showProviderList
                                ? Container(
                                    margin: const EdgeInsets.fromLTRB(
                                        20, 8, 20, 20),
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
                                              _selectedProvider =
                                                  provider['id'];
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
                                                  ? cs.primary
                                                      .withValues(alpha: 0.08)
                                                  : card,
                                              borderRadius:
                                                  BorderRadius.circular(10),
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
                                                        BorderRadius.circular(
                                                            8),
                                                  ),
                                                  child: _buildProviderAvatar(
                                                    provider,
                                                    size: 40,
                                                    radius: 8,
                                                    iconColor: Colors.white,
                                                    iconSize: 22,
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Text(
                                                    _formatProviderLabel(
                                                        provider),
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w500,
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
                                        color:
                                            Colors.blue.withValues(alpha: 0.1),
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
                                  // Reset verification when meter type changes
                                  _isMeterVerified = false;
                                  _verifiedCustomerName = null;
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
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
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
                                color:
                                    _isMeterVerified ? Colors.green : border),
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

                // Email Field
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
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Delivery Email (required)',
                      hintText:
                          'GoPayna sends your token receipt to this email',
                      labelStyle: TextStyle(color: muted),
                      prefixIcon: Icon(
                        Icons.email,
                        color: cs.primary,
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
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: cs.onSurface,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter email address';
                      }
                      if (!value.contains('@') || !value.contains('.')) {
                        return 'Please enter a valid email address';
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
                      if (_hasProviderAmountSupport(_selectedProvider))
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Provider Purchase amount supported',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: cs.onSurface,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _buildAmountSupportRow(
                                label: 'Minimum amount:',
                                value: _formatCurrencyLabel(
                                  _getSupportedMinimumAmountForProvider(
                                      _selectedProvider)!,
                                ),
                              ),
                              const SizedBox(height: 10),
                              _buildAmountSupportRow(
                                label: 'Maximum amount:',
                                value: _formatCurrencyLabel(
                                  _getSupportedMaximumAmountForProvider(
                                      _selectedProvider)!,
                                ),
                              ),
                            ],
                          ),
                        ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          16,
                          _hasProviderAmountSupport(_selectedProvider)
                              ? 0
                              : 16,
                          16,
                          12,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_selectedMeterType == 'postpaid' &&
                                _minimumPayment > 0) ...[
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color:
                                        Colors.orange.withValues(alpha: 0.16),
                                  ),
                                ),
                                child: Text(
                                  'Current postpaid minimum due: ${_formatCurrencyLabel(_minimumPayment)}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: cs.onSurface,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      TextFormField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          TextInputFormatter.withFunction(
                            (oldValue, newValue) {
                              if (newValue.text.isEmpty) return newValue;
                              final value = int.tryParse(newValue.text) ?? 0;
                              final formatted =
                                  NumberFormat('#,##0').format(value);
                              return newValue.copyWith(
                                text: formatted,
                                selection: TextSelection.collapsed(
                                    offset: formatted.length),
                              );
                            },
                          ),
                        ],
                        decoration: InputDecoration(
                          labelText: 'Amount (₦)',
                          hintText: _selectedMeterType == 'prepaid'
                            ? (_hasProviderAmountSupport(_selectedProvider)
                              ? 'Enter amount (min. ${_formatCurrencyLabel(_getSupportedMinimumAmountForProvider(_selectedProvider)!)} )'
                              : 'Verify meter to load provider min/max amount')
                              : _outstandingBill > 0
                              ? 'Outstanding: ${_formatCurrencyLabel(_outstandingBill)}, Min: ${_formatCurrencyLabel(_minimumPayment)}'
                              : (_getSupportedMinimumAmountForProvider(
                                    _selectedProvider) !=
                                  null
                                ? 'Enter amount (min. ${_formatCurrencyLabel(_getSupportedMinimumAmountForProvider(_selectedProvider)!)} )'
                                : 'Enter amount'),
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
                          suffixIcon: _isFetchingBill
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: Padding(
                                    padding: EdgeInsets.all(12.0),
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  ),
                                )
                              : null,
                        ),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                        enabled:
                            !_isLoading, // Allow amount entry even before meter verification
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter amount';
                          }

                          final amount = _parseAmount(value);
                          if (_selectedMeterType == 'prepaid') {
                            final minAmount =
                                _getMinimumAmountForProvider(_selectedProvider);
                            if (minAmount <= 0) {
                              return 'Provider amount limits are not available yet. Verify meter first.';
                            }
                            if (amount < minAmount) {
                              return 'Minimum amount is ₦${minAmount.toStringAsFixed(0)}';
                            }
                          } else {
                            // postpaid
                            final minAmount =
                                _minimumPayment > 0
                                    ? _minimumPayment
                                    : _getMinimumAmountForProvider(
                                        _selectedProvider);
                            if (minAmount <= 0) {
                              return 'Provider amount limits are not available yet. Verify meter first.';
                            }
                            if (amount < minAmount) {
                              return 'Minimum amount is ₦${minAmount.toStringAsFixed(0)}';
                            }
                            if (_outstandingBill > 0 &&
                                amount > _outstandingBill) {
                              return 'Amount cannot exceed outstanding bill of ₦${_outstandingBill.toStringAsFixed(0)}';
                            }
                          }

                          final maxAmount =
                              _getMaximumAmountForProvider(_selectedProvider);
                          if (amount > maxAmount) {
                            return 'Maximum amount is ₦${maxAmount.toStringAsFixed(0)}';
                          }

                          return null;
                        },
                      ),

                      // Outstanding Bill Info for Postpaid
                      if (_selectedMeterType == 'postpaid' &&
                          _isMeterVerified &&
                          _outstandingBill > 0)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: Colors.blue.withValues(alpha: 0.3)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Outstanding Bill: ₦${_outstandingBill.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Minimum Payment: ₦${_minimumPayment.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue.shade600,
                                  ),
                                ),
                              ],
                            ),
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
                      padding:
                          EdgeInsets.symmetric(vertical: isTablet ? 20 : 16),
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
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
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
                          itemCount: _recentTransactions.take(5).length,
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
                                          transaction.meterNumber,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: cs.onSurface,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${transaction.provider} - ${transaction.package}',
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
                                          color: (transaction.status ==
                                                  'Successful'
                                              ? const Color(0xFF00CA44)
                                              : transaction.status == 'Pending'
                                                  ? GoPaynaColors.statusPending
                                                  : Colors.red)
                                              .withValues(alpha: 0.15),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          transaction.status,
                                          style: TextStyle(
                                            color: transaction.status ==
                                                    'Successful'
                                                ? const Color(0xFF00CA44)
                                                : transaction.status ==
                                                        'Pending'
                                                    ? GoPaynaColors
                                                        .statusPending
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
      ),
    );
  }
}
