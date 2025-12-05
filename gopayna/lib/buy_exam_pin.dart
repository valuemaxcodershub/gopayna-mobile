import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_service.dart' as api;
import 'widgets/wallet_visibility_builder.dart';
import 'widgets/themed_screen_helpers.dart';

class EducationTransaction {
  final String id;
  final String provider;
  final String candidateNumber;
  final String candidateName;
  final String package;
  final double amount;
  final DateTime date;
  final String status;
  final Color providerColor;

  EducationTransaction({
    required this.id,
    required this.provider,
    required this.candidateNumber,
    required this.candidateName,
    required this.package,
    required this.amount,
    required this.date,
    required this.status,
    required this.providerColor,
  });
}

class BuyEducationPinScreen extends StatefulWidget {
  const BuyEducationPinScreen({super.key});

  @override
  State<BuyEducationPinScreen> createState() => _BuyEducationPinScreenState();
}

class _BuyEducationPinScreenState extends State<BuyEducationPinScreen>
    with ThemedScreenHelpers {
  final _formKey = GlobalKey<FormState>();
  final _candidateNumberController = TextEditingController();
  final _phoneController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');

  String _selectedProvider = 'waec';
  String _selectedPackage = '';
  bool _isLoading = false;
  double _walletBalance = 0.0;
  String? _token;

  // NelloByte supported providers: waec and jamb only
  final List<Map<String, dynamic>> _providers = [
    {
      'id': 'waec',
      'name': 'WAEC',
      'fullName': 'West African Examinations Council',
      'color': const Color(0xFF0066CC),
      'logo': 'assets/waec_logo.png',
      'textColor': Colors.white,
    },
    {
      'id': 'jamb',
      'name': 'JAMB',
      'fullName': 'Joint Admissions and Matriculation Board',
      'color': const Color(0xFF006400),
      'logo': 'assets/jamb_logo.png',
      'textColor': Colors.white,
    },
  ];

  // NelloByte exam codes from documentation
  // WAEC: waec (Result Checker), waec-registration (Registration)
  // JAMB: utme (UTME PIN), de (Direct Entry PIN)
  final Map<String, List<Map<String, dynamic>>> _packages = {
    'waec': [
      {
        'bundle': 'WAEC Result Checker Pin',
        'code': 'waec',
        'price': 4500,
        'type': 'Result Checker'
      },
      {
        'bundle': 'WAEC Registration Pin',
        'code': 'waec-registration',
        'price': 18900,
        'type': 'Registration'
      },
    ],
    'jamb': [
      {
        'bundle': 'JAMB UTME Registration Pin',
        'code': 'utme',
        'price': 5500,
        'type': 'Registration',
        'needsProfileId': true
      },
      {
        'bundle': 'JAMB Direct Entry Pin',
        'code': 'de',
        'price': 5500,
        'type': 'Registration',
        'needsProfileId': true
      },
    ],
  };

  final List<EducationTransaction> _recentTransactions = [
    EducationTransaction(
      id: 'EDU001',
      provider: 'JAMB',
      candidateNumber: '12345678',
      candidateName: 'JOHN DOE',
      package: 'JAMB UTME Registration',
      amount: 4700,
      date: DateTime.now().subtract(const Duration(hours: 2)),
      status: 'Successful',
      providerColor: const Color(0xFFDC143C),
    ),
    EducationTransaction(
      id: 'EDU002',
      provider: 'WAEC',
      candidateNumber: '87654321',
      candidateName: 'JANE SMITH',
      package: 'WAEC Result Checker Pin',
      amount: 1850,
      date: DateTime.now().subtract(const Duration(days: 1)),
      status: 'Successful',
      providerColor: const Color(0xFF0066CC),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadWalletData();
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
    _candidateNumberController.dispose();
    _phoneController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _buyEducationPin() {
    final colorScheme = this.colorScheme;
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
          '${package['bundle']} - ${package['type']}' == _selectedPackage,
    );
    final colorScheme = this.colorScheme;
    final cardColor = this.cardColor;
    final borderColor = this.borderColor;
    final mutedTextColor = this.mutedTextColor;

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
                'Please confirm your education pin details:',
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
                    alpha: isDarkMode ? 0.35 : 0.5,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  children: [
                    _buildConfirmationRow(
                        'Provider', _selectedProviderData['fullName']),
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
                style: TextStyle(
                  color: mutedTextColor,
                  fontWeight: FontWeight.w500,
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
              color: mutedTextColor,
            ),
          ),
        ),
        const SizedBox(width: 8),
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

    final quantity = int.tryParse(_quantityController.text) ?? 1;
    final unitPrice = (selectedPackage['price'] as num?)?.toDouble() ?? 0;
    final amount = unitPrice * quantity;

    if (amount > _walletBalance) {
      _showErrorDialog('Insufficient wallet balance.');
      return;
    }

    // JAMB requires a profile ID for verification
    final needsProfileId = selectedPackage['needsProfileId'] == true;
    if (needsProfileId && _candidateNumberController.text.isEmpty) {
      _showErrorDialog('Please enter your JAMB Profile Code.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // NelloByte uses examType (waec/jamb) and examCode (waec, waec-registration, utme, de)
    final examCode = selectedPackage['code']?.toString() ?? '';

    final result = await api.buyEducationPin(
      _token!,
      examType: _selectedProvider, // waec or jamb
      examCode: examCode, // waec, waec-registration, utme, de
      phone: _phoneController.text,
      amount: amount,
      profileId: needsProfileId ? _candidateNumberController.text : null,
    );

    setState(() {
      _isLoading = false;
    });

    if (!mounted) return;

    if (result['success'] == true) {
      _loadWalletData();
      // Show PIN/serial in success dialog if returned
      final data = result['data'];
      if (data != null && (data['pin'] != null || data['serial'] != null)) {
        _showSuccessDialogWithPin(data['pin'] ?? '', data['serial'] ?? '');
      } else {
        _showSuccessDialog();
      }
    } else {
      _showErrorDialog(
          result['error'] ?? 'Transaction failed. Please try again.');
    }
  }

  void _showSuccessDialogWithPin(String pin, String serial) {
    final selectedProviderData =
        _providers.firstWhere((p) => p['id'] == _selectedProvider);
    final selectedPackage = _packages[_selectedProvider]!.firstWhere(
      (package) =>
          '${package['bundle']} - ${package['type']}' == _selectedPackage,
    );
    final colorScheme = this.colorScheme;

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
                  child: Icon(
                    Icons.check_circle,
                    color: colorScheme.onPrimary,
                    size: 50,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Purchase Successful!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'You successfully purchased ${selectedPackage['bundle']} for ${selectedProviderData['fullName']}',
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (pin.isNotEmpty || serial.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.onPrimary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        if (serial.isNotEmpty) ...[
                          Text(
                            'Serial: $serial',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                        ],
                        if (pin.isNotEmpty)
                          Text(
                            'PIN: $pin',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onPrimary,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
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
    final colorScheme = this.colorScheme;

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
                  child: Icon(
                    Icons.check_circle,
                    color: colorScheme.onPrimary,
                    size: 50,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Purchase Successful!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'You successfully purchased ${selectedPackage['bundle']} for ${selectedProviderData['fullName']}',
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onPrimary,
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
          'Education Pin',
          style: TextStyle(
            color: colorScheme.onPrimary,
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'Select Exam Body',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                    // Selected Provider Display
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedProviderData['name'],
                                  style: TextStyle(
                                    color: _selectedProviderData['textColor'],
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  _selectedProviderData['fullName'],
                                  style: TextStyle(
                                    color: _selectedProviderData['textColor']
                                        .withValues(alpha: 0.8),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Provider Grid
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.1,
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
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? provider['color'].withValues(alpha: 0.15)
                                    : cardColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? provider['color']
                                      : borderColor,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.asset(
                                      provider['logo'],
                                      width: 40,
                                      height: 40,
                                      fit: BoxFit.contain,
                                      errorBuilder: (_, __, ___) => Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: provider['color'],
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Center(
                                          child: Text(
                                            provider['name']
                                                .toString()
                                                .substring(0, 1),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    provider['name'],
                                    style: TextStyle(
                                      color: isSelected
                                          ? provider['color']
                                          : colorScheme.onSurface,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
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

              const SizedBox(height: 20),

              // JAMB Profile Code Field (only shown for JAMB)
              if (_selectedProvider == 'jamb')
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
                    controller: _candidateNumberController,
                    keyboardType: TextInputType.text,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      labelText: 'JAMB Profile Code',
                      hintText: 'e.g., 1234567890XX',
                      prefixIcon: Icon(
                        Icons.badge_outlined,
                        color: colorScheme.primary,
                      ),
                      border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: cardColor,
                      contentPadding: const EdgeInsets.all(20),
                    ),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurface,
                    ),
                    validator: (value) {
                      if (_selectedProvider == 'jamb') {
                        if (value == null || value.isEmpty) {
                          return 'Enter JAMB Profile Code';
                        }
                        if (value.length < 10) {
                          return 'Profile code looks too short';
                        }
                      }
                      return null;
                    },
                  ),
                ),

              if (_selectedProvider == 'jamb') const SizedBox(height: 20),

              // Phone Number Field
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
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    prefixIcon: Icon(
                      Icons.phone,
                      color: colorScheme.primary,
                    ),
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(16)),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: cardColor,
                    contentPadding: const EdgeInsets.all(20),
                  ),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface,
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
                        'Select Service',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 1,
                          crossAxisSpacing: 6,
                          mainAxisSpacing: 6,
                          childAspectRatio: 4.0,
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
                              margin: const EdgeInsets.all(3),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? colorScheme.primary
                                        .withValues(alpha: 0.12)
                                    : cardColor,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected
                                      ? colorScheme.primary
                                      : borderColor,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          package['bundle'],
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: colorScheme.onSurface,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          package['type'],
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
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (isSelected)
                                    Icon(
                                      Icons.check_circle,
                                      color: colorScheme.primary,
                                      size: 16,
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
                  onPressed: _isLoading ? null : _buyEducationPin,
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
                          'Purchase PIN',
                          style: TextStyle(
                            fontSize: isTablet ? 22 : 18,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onPrimary,
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
                                'Recent Education Pins',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurface,
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
                        itemCount: _recentTransactions.take(3).length,
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
                                    Icons.school,
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
                                        transaction.provider,
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
