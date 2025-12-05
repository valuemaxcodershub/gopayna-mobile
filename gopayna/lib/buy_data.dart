import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_service.dart' as api;
import 'widgets/wallet_visibility_builder.dart';
import 'widgets/themed_screen_helpers.dart';

class DataTransaction {
  final String network;
  final String phoneNumber;
  final String dataBundle;
  final String amount;
  final DateTime date;
  final bool isSuccessful;
  final Color networkColor;

  DataTransaction({
    required this.network,
    required this.phoneNumber,
    required this.dataBundle,
    required this.amount,
    required this.date,
    required this.isSuccessful,
    required this.networkColor,
  });
}

class BuyDataScreen extends StatefulWidget {
  const BuyDataScreen({super.key});

  @override
  State<BuyDataScreen> createState() => _BuyDataScreenState();
}

class _BuyDataScreenState extends State<BuyDataScreen>
    with ThemedScreenHelpers, SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();

  String _selectedNetwork = 'mtn';
  String _selectedDataPlan = '';
  String _selectedPlanCode = '';
  bool _isLoading = false;
  bool _isLoadingPlans = false;
  bool _showNetworkList = false;
  double _walletBalance = 0.0;
  String? _token;
  List<DataTransaction> _recentTransactions = [];

  // Dynamic data plans fetched from API
  List<Map<String, dynamic>> _fetchedDataPlans = [];

  // Validity filter tabs
  late TabController _validityTabController;
  final List<String> _validityTabs = [
    'All',
    'Daily',
    'Weekly',
    'Monthly',
    '2+ Months'
  ];
  String _selectedValidity = 'All';

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

  // Fallback static data plans (used when API fails)
  final Map<String, List<Map<String, String>>> _fallbackDataPlans = {
    'mtn': [
      {'bundle': '500MB - 30 Days', 'price': '130', 'code': '500'},
      {'bundle': '1GB - 30 Days', 'price': '250', 'code': 'M1024'},
      {'bundle': '2GB - 30 Days', 'price': '500', 'code': 'M2024'},
      {'bundle': '3GB - 30 Days', 'price': '750', 'code': '3000'},
      {'bundle': '5GB - 30 Days', 'price': '1250', 'code': '5000'},
      {'bundle': '10GB - 30 Days', 'price': '2500', 'code': '10000'},
    ],
    'airtel': [
      {'bundle': '500MB - 30 Days', 'price': '130', 'code': 'AIRT500'},
      {'bundle': '1GB - 30 Days', 'price': '250', 'code': 'AIRT1GB'},
      {'bundle': '2GB - 30 Days', 'price': '500', 'code': 'AIRT2GB'},
      {'bundle': '5GB - 30 Days', 'price': '1250', 'code': 'AIRT5GB'},
      {'bundle': '10GB - 30 Days', 'price': '2500', 'code': 'AIRT10GB'},
      {'bundle': '15GB - 30 Days', 'price': '3750', 'code': 'AIRT15GB'},
    ],
    'glo': [
      {'bundle': '500MB - 30 Days', 'price': '130', 'code': 'G500'},
      {'bundle': '1GB - 30 Days', 'price': '250', 'code': 'G1000'},
      {'bundle': '2GB - 30 Days', 'price': '500', 'code': 'G2000'},
      {'bundle': '3GB - 30 Days', 'price': '750', 'code': 'G3000'},
      {'bundle': '5GB - 30 Days', 'price': '1250', 'code': 'G5000'},
      {'bundle': '10GB - 30 Days', 'price': '2500', 'code': 'G10000'},
    ],
    '9mobile': [
      {'bundle': '500MB - 30 Days', 'price': '130', 'code': '9MOB500'},
      {'bundle': '1GB - 30 Days', 'price': '250', 'code': '9MOB1GB'},
      {'bundle': '2GB - 30 Days', 'price': '500', 'code': '9MOB2GB'},
      {'bundle': '3GB - 30 Days', 'price': '750', 'code': '9MOB3GB'},
      {'bundle': '5GB - 30 Days', 'price': '1250', 'code': '9MOB5GB'},
      {'bundle': '10GB - 30 Days', 'price': '2500', 'code': '9MOB10GB'},
    ],
  };

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

  // Get current data plans (fetched or fallback), filtered by validity
  List<Map<String, dynamic>> get _currentDataPlans {
    List<Map<String, dynamic>> plans;
    if (_fetchedDataPlans.isNotEmpty) {
      plans = _fetchedDataPlans;
    } else {
      // Convert fallback plans to same format
      plans = (_fallbackDataPlans[_selectedNetwork] ?? [])
          .map((p) => Map<String, dynamic>.from(p))
          .toList();
    }

    // Filter by selected validity
    if (_selectedValidity == 'All') {
      return plans;
    }

    return plans.where((plan) {
      final validity = _getValidityCategory(plan);
      return validity == _selectedValidity;
    }).toList();
  }

  // Extract validity category from plan data or name
  String _getValidityCategory(Map<String, dynamic> plan) {
    // First try to use the validity field from backend
    final validity = (plan['validity'] ?? '').toString().toLowerCase();
    final planName =
        (plan['bundle'] ?? plan['name'] ?? '').toString().toLowerCase();

    // Check validity field first (e.g., "1 day", "7 days", "30 days")
    if (validity.isNotEmpty) {
      final dayMatch = RegExp(r'(\d+)\s*day').firstMatch(validity);
      if (dayMatch != null) {
        final days = int.tryParse(dayMatch.group(1) ?? '0') ?? 0;
        if (days <= 3) return 'Daily';
        if (days <= 14) return 'Weekly';
        if (days <= 31) return 'Monthly';
        return '2+ Months';
      }

      if (validity.contains('week')) return 'Weekly';
      if (validity.contains('month')) {
        if (validity.contains('2') ||
            validity.contains('3') ||
            validity.contains('6') ||
            validity.contains('12')) {
          return '2+ Months';
        }
        return 'Monthly';
      }
      if (validity.contains('year')) return '2+ Months';
    }

    // Fallback to parsing from plan name
    // Daily: 1 day, 2 days, 3 days
    if (planName.contains('1 day') ||
        planName.contains('2 day') ||
        planName.contains('3 day') ||
        planName.contains('daily')) {
      return 'Daily';
    }

    // Weekly: 7 days, 14 days
    if (planName.contains('7 day') ||
        planName.contains('14 day') ||
        planName.contains('week')) {
      return 'Weekly';
    }

    // Monthly: 30 days
    if (planName.contains('30 day') ||
        (planName.contains('month') &&
            !planName.contains('2-month') &&
            !planName.contains('3-month'))) {
      return 'Monthly';
    }

    // 2+ Months: 60 days, 90 days, 180 days, 365 days
    if (planName.contains('60 day') ||
        planName.contains('90 day') ||
        planName.contains('180 day') ||
        planName.contains('365 day') ||
        planName.contains('2-month') ||
        planName.contains('3-month') ||
        planName.contains('year')) {
      return '2+ Months';
    }

    // Default to Monthly for plans without clear validity
    return 'Monthly';
  }

  // Get count of plans for each validity category
  Map<String, int> get _validityCounts {
    final counts = <String, int>{
      'All': 0,
      'Daily': 0,
      'Weekly': 0,
      'Monthly': 0,
      '2+ Months': 0
    };

    List<Map<String, dynamic>> plans;
    if (_fetchedDataPlans.isNotEmpty) {
      plans = _fetchedDataPlans;
    } else {
      plans = (_fallbackDataPlans[_selectedNetwork] ?? [])
          .map((p) => Map<String, dynamic>.from(p))
          .toList();
    }

    counts['All'] = plans.length;
    for (final plan in plans) {
      final validity = _getValidityCategory(plan);
      counts[validity] = (counts[validity] ?? 0) + 1;
    }

    return counts;
  }

  // Extract data size from plan name (e.g., "500 MB", "1 GB", "1.5GB")
  String _extractDataSize(String planName) {
    // Match patterns like "500 MB", "1GB", "1.5 GB", "100MB", "1TB"
    final regex = RegExp(r'(\d+\.?\d*)\s*(MB|GB|TB)', caseSensitive: false);
    final match = regex.firstMatch(planName);
    if (match != null) {
      final size = match.group(1);
      final unit = match.group(2)?.toUpperCase();
      return '$size $unit';
    }
    // Fallback: return first part before " - "
    final parts = planName.split(' - ');
    if (parts.isNotEmpty) {
      return parts[0].trim();
    }
    return planName;
  }

  // Extract validity from plan name (e.g., "7 days", "30 days", "1 day")
  String _extractValidity(String planName) {
    final lowerName = planName.toLowerCase();

    // Match patterns like "7 days", "30 days", "1 day"
    final daysRegex = RegExp(r'(\d+)\s*day[s]?', caseSensitive: false);
    final daysMatch = daysRegex.firstMatch(planName);
    if (daysMatch != null) {
      final days = int.tryParse(daysMatch.group(1) ?? '0') ?? 0;
      if (days == 1) return '1 Day';
      if (days <= 3) return '$days Days';
      if (days <= 7) return '1 Week';
      if (days <= 14) return '2 Weeks';
      if (days <= 30) return '1 Month';
      if (days <= 60) return '2 Months';
      if (days <= 90) return '3 Months';
      if (days <= 180) return '6 Months';
      if (days <= 365) return '1 Year';
      return '$days Days';
    }

    // Check for keywords
    if (lowerName.contains('daily')) return '1 Day';
    if (lowerName.contains('weekly')) return '1 Week';
    if (lowerName.contains('monthly')) return '1 Month';
    if (lowerName.contains('weekend')) return 'Weekend';
    if (lowerName.contains('night')) return 'Night Plan';

    // Check for plan type in parentheses
    final typeRegex = RegExp(r'\(([^)]+)\)');
    final typeMatch = typeRegex.firstMatch(planName);
    if (typeMatch != null) {
      final type = typeMatch.group(1) ?? '';
      if (type.toLowerCase().contains('sme')) return 'SME Plan';
      if (type.toLowerCase().contains('direct')) return 'Direct Data';
      if (type.toLowerCase().contains('awoof')) return 'Awoof Data';
      return type;
    }

    return '';
  }

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
    _validityTabController =
        TabController(length: _validityTabs.length, vsync: this);
    _validityTabController.addListener(_onValidityTabChanged);
    _phoneController.addListener(_onPhoneNumberChanged);
    _loadWalletData();
    _loadRecentTransactions();
  }

  void _onValidityTabChanged() {
    if (_validityTabController.indexIsChanging) return;
    setState(() {
      _selectedValidity = _validityTabs[_validityTabController.index];
      _selectedDataPlan = '';
      _selectedPlanCode = '';
    });
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
          _selectedDataPlan = '';
          _selectedPlanCode = '';
        });
        _fetchDataPlansForNetwork(detectedNetwork);
        HapticFeedback.selectionClick();
      }
    }
  }

  Future<void> _loadRecentTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt');
    if (token == null) return;

    final result = await api.fetchVTUHistory(token, type: 'data', limit: 5);
    if (mounted && result['success'] == true) {
      final data = result['data'] as List? ?? [];
      setState(() {
        _recentTransactions = data.map((tx) {
          final details = tx['details'] as Map<String, dynamic>? ?? {};
          return DataTransaction(
            network: details['network']?.toString().toUpperCase() ?? 'Unknown',
            phoneNumber: details['phone']?.toString() ?? '',
            dataBundle: tx['description']?.toString() ?? '',
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
      // Load data plans for the selected network
      _fetchDataPlansForNetwork(_selectedNetwork);
    }
  }

  Future<void> _fetchDataPlansForNetwork(String networkId) async {
    if (_token == null) return;

    setState(() {
      _isLoadingPlans = true;
      _fetchedDataPlans = [];
      _selectedValidity = 'All';
      _validityTabController.index = 0;
    });

    try {
      final result = await api.fetchDataPlans(_token!, networkId);
      if (mounted) {
        if (result['success'] == true) {
          final data = result['data'];
          List<Map<String, dynamic>> plans = [];

          // Backend returns: { "success": true, "plans": [...] }
          // Each plan: { id, code, network, networkCode, name, price, validity, category }
          if (data is Map) {
            if (data['plans'] != null && data['plans'] is List) {
              // Standard backend response format
              plans = (data['plans'] as List)
                  .map((p) => Map<String, dynamic>.from(p))
                  .toList();
            } else if (data['data'] != null && data['data'] is List) {
              // Alternative format
              plans = (data['data'] as List)
                  .map((p) => Map<String, dynamic>.from(p))
                  .toList();
            }
          } else if (data is List) {
            plans = data.map((p) => Map<String, dynamic>.from(p)).toList();
          }

          // Format plans for UI - use backend-standardized fields
          final formattedPlans = plans.map((plan) {
            // Backend provides: name, price, code, validity, category
            final name =
                plan['name'] ?? plan['PRODUCT_NAME'] ?? plan['bundle'] ?? '';
            final priceValue =
                plan['price'] ?? plan['PRODUCT_AMOUNT'] ?? plan['amount'] ?? 0;
            final price = (priceValue is num)
                ? priceValue.round()
                : (int.tryParse(priceValue.toString()) ?? 0);
            final code =
                (plan['code'] ?? plan['PRODUCT_CODE'] ?? plan['id'] ?? '')
                    .toString();
            final validity = plan['validity'] ?? plan['VALIDITY'] ?? '';
            final category = plan['category'] ?? '';

            return {
              'bundle': name,
              'name': name,
              'price': price.toString(),
              'code': code,
              'validity': validity,
              'category': category,
              'sortPrice': price,
            };
          }).toList();

          // Sort by price ascending
          formattedPlans.sort((a, b) =>
              (a['sortPrice'] as int).compareTo(b['sortPrice'] as int));

          setState(() {
            _fetchedDataPlans = formattedPlans;
            _isLoadingPlans = false;
          });
        } else {
          // Use fallback plans on API error
          setState(() {
            _fetchedDataPlans = [];
            _isLoadingPlans = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching data plans: $e');
      if (mounted) {
        setState(() {
          _fetchedDataPlans = [];
          _isLoadingPlans = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _validityTabController.removeListener(_onValidityTabChanged);
    _validityTabController.dispose();
    _phoneController.removeListener(_onPhoneNumberChanged);
    _phoneController.dispose();
    super.dispose();
  }

  void _buyData() {
    if (_formKey.currentState!.validate()) {
      if (_selectedDataPlan.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please select a data plan'),
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
    final selectedPlan = _currentDataPlans.firstWhere(
      (plan) => '${plan['bundle']} - ₦${plan['price']}' == _selectedDataPlan,
    );
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
                'Please confirm your data purchase details:',
                style: TextStyle(
                  fontSize: 14,
                  color: muted,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(12),
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
                        'Data Plan', selectedPlan['bundle'] ?? ''),
                    const SizedBox(height: 8),
                    _buildConfirmationRow(
                        'Validity', selectedPlan['validity'] ?? ''),
                    const SizedBox(height: 8),
                    _buildConfirmationRow(
                        'Amount', '₦${selectedPlan['price']}'),
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

    // Get the selected plan details
    Map<String, dynamic>? selectedPlan;

    try {
      selectedPlan = _currentDataPlans.firstWhere(
        (plan) => '${plan['bundle']} - ₦${plan['price']}' == _selectedDataPlan,
      );
    } catch (e) {
      _showErrorDialog('Please select a valid data plan.');
      return;
    }

    final amount = double.tryParse(selectedPlan['price'] ?? '0') ?? 0;

    if (amount > _walletBalance) {
      _showErrorDialog('Insufficient wallet balance.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Send network name (mtn, glo, airtel, 9mobile) not the code
    final result = await api.buyData(
      _token!,
      network: _selectedNetwork, // Send network name directly
      phone: _phoneController.text,
      planId: _selectedPlanCode.isNotEmpty
          ? _selectedPlanCode
          : selectedPlan['code'] ?? selectedPlan['bundle'] ?? '',
      amount: amount,
    );

    setState(() {
      _isLoading = false;
    });

    if (!mounted) return;

    if (result['success'] == true) {
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
    final selectedPlan = _currentDataPlans.firstWhere(
      (plan) => '${plan['bundle']} - ₦${plan['price']}' == _selectedDataPlan,
    );
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
                const SizedBox(height: 20),
                Text(
                  'Data Purchase Successful!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: cs.onPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'You successfully purchased ${selectedPlan['bundle']} ${selectedNetworkData['name']} data for ${_phoneController.text}',
                  style: TextStyle(
                    fontSize: 14,
                    color: cs.onPrimary,
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
                      backgroundColor: cs.onPrimary,
                      foregroundColor: cs.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Done',
                      style: TextStyle(
                        fontSize: 16,
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
          'Data',
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
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: _selectedNetworkData['color'],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.asset(
                                  _selectedNetworkData['logo'],
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Icon(
                                    Icons.sim_card,
                                    color: _selectedNetworkData['textColor'],
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _selectedNetworkData['name'],
                              style: TextStyle(
                                fontSize: 16,
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
                                  _selectedDataPlan = '';
                                  _selectedPlanCode = '';
                                  _showNetworkList = false;
                                });
                                _fetchDataPlansForNetwork(network['id']);
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

              const SizedBox(height: 24),

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
                    border: OutlineInputBorder(
                      borderRadius: const BorderRadius.all(Radius.circular(16)),
                      borderSide: BorderSide(color: border),
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
                    errorBorder: OutlineInputBorder(
                      borderRadius: const BorderRadius.all(Radius.circular(16)),
                      borderSide: BorderSide(color: cs.error, width: 2),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: const BorderRadius.all(Radius.circular(16)),
                      borderSide: BorderSide(color: cs.error, width: 2),
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

              const SizedBox(height: 24),

              // Data Plans Section
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
                            Icons.data_usage,
                            color: cs.onPrimary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _selectedDataPlan.isEmpty
                                  ? 'Select Data Plan'
                                  : _selectedDataPlan,
                              style: TextStyle(
                                color: cs.onPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          if (_selectedDataPlan.isNotEmpty)
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
                          Row(
                            children: [
                              Text(
                                'Available Data Plans',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: cs.onSurface,
                                ),
                              ),
                              if (_isLoadingPlans) ...[
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        cs.primary),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Validity filter tabs
                          if (!_isLoadingPlans && _fetchedDataPlans.isNotEmpty)
                            Container(
                              height: 36,
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _validityTabs.length,
                                itemBuilder: (context, index) {
                                  final tab = _validityTabs[index];
                                  final count = _validityCounts[tab] ?? 0;
                                  final isSelected = _selectedValidity == tab;

                                  // Hide tabs with 0 plans (except 'All')
                                  if (count == 0 && tab != 'All') {
                                    return const SizedBox.shrink();
                                  }

                                  return Padding(
                                    padding: EdgeInsets.only(
                                        right: index < _validityTabs.length - 1
                                            ? 8
                                            : 0),
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _selectedValidity = tab;
                                          _validityTabController.index = index;
                                          _selectedDataPlan = '';
                                          _selectedPlanCode = '';
                                        });
                                        HapticFeedback.selectionClick();
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? cs.primary
                                              : cs.primary
                                                  .withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(18),
                                          border: Border.all(
                                            color: isSelected
                                                ? cs.primary
                                                : cs.primary
                                                    .withValues(alpha: 0.3),
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              tab,
                                              style: TextStyle(
                                                color: isSelected
                                                    ? cs.onPrimary
                                                    : cs.primary,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            if (tab != 'All') ...[
                                              const SizedBox(width: 4),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 6,
                                                        vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: isSelected
                                                      ? cs.onPrimary.withValues(
                                                          alpha: 0.2)
                                                      : cs.primary.withValues(
                                                          alpha: 0.15),
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                child: Text(
                                                  count.toString(),
                                                  style: TextStyle(
                                                    color: isSelected
                                                        ? cs.onPrimary
                                                        : cs.primary,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          if (_isLoadingPlans)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  children: [
                                    CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          cs.primary),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Loading data plans...',
                                      style:
                                          TextStyle(color: muted, fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else if (_currentDataPlans.isEmpty)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Text(
                                  _fetchedDataPlans.isEmpty
                                      ? 'No data plans available'
                                      : 'No ${_selectedValidity.toLowerCase()} plans available',
                                  style: TextStyle(color: muted, fontSize: 14),
                                ),
                              ),
                            )
                          else
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: isTablet ? 3 : 2,
                                childAspectRatio: isTablet ? 1.4 : 1.5,
                                crossAxisSpacing: isTablet ? 16 : 10,
                                mainAxisSpacing: isTablet ? 16 : 10,
                              ),
                              itemCount: _currentDataPlans.length,
                              itemBuilder: (context, index) {
                                final plan = _currentDataPlans[index];
                                final planName =
                                    plan['bundle'] ?? plan['name'] ?? '';
                                final planPrice = plan['price'] ?? '0';
                                final planDisplay = '$planName - ₦$planPrice';
                                final isSelected =
                                    _selectedDataPlan == planDisplay;

                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedDataPlan = planDisplay;
                                      _selectedPlanCode = plan['code'] ?? '';
                                    });
                                    HapticFeedback.lightImpact();
                                  },
                                  child: Container(
                                    padding: EdgeInsets.all(isTablet ? 10 : 8),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? cs.primary.withValues(alpha: 0.1)
                                          : surfaceVariant,
                                      borderRadius: BorderRadius.circular(
                                          isTablet ? 16 : 12),
                                      border: Border.all(
                                        color: isSelected ? cs.primary : border,
                                        width: 2,
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Data size (extract from plan name)
                                        Text(
                                          _extractDataSize(planName),
                                          style: TextStyle(
                                            fontSize: isTablet ? 14 : 12,
                                            fontWeight: FontWeight.bold,
                                            color: isSelected
                                                ? cs.primary
                                                : cs.onSurface,
                                          ),
                                          textAlign: TextAlign.center,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        // Validity period
                                        Text(
                                          _extractValidity(planName),
                                          style: TextStyle(
                                            fontSize: isTablet ? 10 : 9,
                                            fontWeight: FontWeight.w500,
                                            color: isSelected
                                                ? cs.primary
                                                    .withValues(alpha: 0.8)
                                                : muted,
                                          ),
                                          textAlign: TextAlign.center,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        // Price
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? cs.primary
                                                : cs.primary
                                                    .withValues(alpha: 0.1),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                '₦$planPrice',
                                                style: TextStyle(
                                                  fontSize: isTablet ? 12 : 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: isSelected
                                                      ? cs.onPrimary
                                                      : cs.primary,
                                                ),
                                              ),
                                              if (isSelected) ...[
                                                const SizedBox(width: 4),
                                                Icon(
                                                  Icons.check_circle,
                                                  color: cs.onPrimary,
                                                  size: 12,
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
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
                  onPressed: (_isLoading || _selectedDataPlan.isEmpty)
                      ? null
                      : _buyData,
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
                                'Recent Data Purchases',
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
                                    Icons.data_usage,
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
                                          Expanded(
                                            child: Text(
                                              '${transaction.network} Data',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: cs.onSurface,
                                              ),
                                            ),
                                          ),
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
                                      Text(
                                        transaction.dataBundle,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: muted,
                                        ),
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
