import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

class _BuyDataScreenState extends State<BuyDataScreen> with ThemedScreenHelpers {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController(text: '08051237666');

  String _selectedNetwork = 'glo';
  String _selectedDataPlan = '';
  bool _isLoading = false;
  bool _showNetworkList = false;
  final double _walletBalance = 50000.00;

  final List<Map<String, dynamic>> _networks = [
    {
      'id': 'mtn',
      'name': 'MTN',
      'color': const Color(0xFFFFCC00),
      'icon': Icons.sim_card,
      'textColor': Colors.black,
    },
    {
      'id': 'airtel',
      'name': 'Airtel',
      'color': const Color(0xFFE60026),
      'icon': Icons.sim_card,
      'textColor': Colors.white,
    },
    {
      'id': 'glo',
      'name': 'GLO',
      'color': const Color(0xFF00CA44),
      'icon': Icons.sim_card,
      'textColor': Colors.white,
    },
    {
      'id': '9mobile',
      'name': '9Mobile',
      'color': const Color(0xFF00CA44),
      'icon': Icons.sim_card,
      'textColor': Colors.white,
    },
  ];

  final Map<String, List<Map<String, String>>> _dataPlans = {
    'mtn': [
      {'bundle': '1GB - 30 days', 'price': '1200'},
      {'bundle': '2GB - 30 days', 'price': '2000'},
      {'bundle': '3GB - 30 days', 'price': '2500'},
      {'bundle': '5GB - 30 days', 'price': '3500'},
      {'bundle': '10GB - 30 days', 'price': '5000'},
      {'bundle': '20GB - 30 days', 'price': '8000'},
    ],
    'airtel': [
      {'bundle': '1GB - 30 days', 'price': '1000'},
      {'bundle': '2GB - 30 days', 'price': '1800'},
      {'bundle': '3GB - 30 days', 'price': '2300'},
      {'bundle': '5GB - 30 days', 'price': '3000'},
      {'bundle': '10GB - 30 days', 'price': '4500'},
      {'bundle': '15GB - 30 days', 'price': '6500'},
    ],
    'glo': [
      {'bundle': '1GB - 30 days', 'price': '1100'},
      {'bundle': '2GB - 30 days', 'price': '1900'},
      {'bundle': '3GB - 30 days', 'price': '2400'},
      {'bundle': '5GB - 30 days', 'price': '3200'},
      {'bundle': '10GB - 30 days', 'price': '4800'},
      {'bundle': '12GB - 30 days', 'price': '5500'},
    ],
    '9mobile': [
      {'bundle': '1GB - 30 days', 'price': '1300'},
      {'bundle': '2GB - 30 days', 'price': '2100'},
      {'bundle': '3GB - 30 days', 'price': '2600'},
      {'bundle': '5GB - 30 days', 'price': '3600'},
      {'bundle': '10GB - 30 days', 'price': '5200'},
      {'bundle': '15GB - 30 days', 'price': '7000'},
    ],
  };

  final List<DataTransaction> _recentTransactions = [
    DataTransaction(
      network: 'MTN',
      phoneNumber: '08012345678',
      dataBundle: '5GB - 30 days',
      amount: '3500',
      date: DateTime.now().subtract(const Duration(hours: 3)),
      isSuccessful: true,
      networkColor: const Color(0xFFFFCC00),
    ),
    DataTransaction(
      network: 'GLO',
      phoneNumber: '08051237666',
      dataBundle: '2GB - 30 days',
      amount: '1900',
      date: DateTime.now().subtract(const Duration(days: 1)),
      isSuccessful: true,
      networkColor: const Color(0xFF00CA44),
    ),
    DataTransaction(
      network: 'Airtel',
      phoneNumber: '08098765432',
      dataBundle: '1GB - 30 days',
      amount: '1000',
      date: DateTime.now().subtract(const Duration(days: 2)),
      isSuccessful: false,
      networkColor: const Color(0xFFE60026),
    ),
  ];

  @override
  void dispose() {
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
    final selectedPlan = _dataPlans[_selectedNetwork]!.firstWhere(
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
                    _buildConfirmationRow('Network', _selectedNetworkData['name']),
                    const SizedBox(height: 8),
                    _buildConfirmationRow('Phone Number', _phoneController.text),
                    const SizedBox(height: 8),
                    _buildConfirmationRow('Data Plan', selectedPlan['bundle'] ?? ''),
                    const SizedBox(height: 8),
                    _buildConfirmationRow('Validity', selectedPlan['validity'] ?? ''),
                    const SizedBox(height: 8),
                    _buildConfirmationRow('Amount', '₦${selectedPlan['price']}'),
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
    setState(() {
      _isLoading = true;
    });

    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isLoading = false;
    });

    if (mounted) {
      _showSuccessDialog();
    }
  }

  void _showSuccessDialog() {
    final isTablet = MediaQuery.of(context).size.width > 600;
    final selectedNetworkData = _networks.firstWhere((n) => n['id'] == _selectedNetwork);
    final selectedPlan = _dataPlans[_selectedNetwork]!.firstWhere(
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
                              child: Icon(
                                _selectedNetworkData['icon'],
                                color: _selectedNetworkData['textColor'],
                                size: 20,
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
                                      child: Icon(
                                        network['icon'],
                                        color: network['textColor'],
                                        size: 16,
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
                          Text(
                            _selectedDataPlan.isEmpty 
                                ? 'Select Data Plan'
                                : _selectedDataPlan,
                            style: TextStyle(
                              color: cs.onPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
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
                          Text(
                            'Available Data Plans',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface,
                            ),
                          ),
                          const SizedBox(height: 12),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: isTablet ? 3 : 2,
                              childAspectRatio: isTablet ? 1.4 : 1.5,
                              crossAxisSpacing: isTablet ? 16 : 12,
                              mainAxisSpacing: isTablet ? 16 : 12,
                            ),
                            itemCount: (_dataPlans[_selectedNetwork] ?? []).length,
                            itemBuilder: (context, index) {
                              final plan = (_dataPlans[_selectedNetwork] ?? [])[index];
                              final planDisplay = '${plan['bundle']} - ₦${plan['price']}';
                              final isSelected = _selectedDataPlan == planDisplay;
                              
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedDataPlan = planDisplay;
                                  });
                                  HapticFeedback.lightImpact();
                                },
                                child: Container(
                                  padding: EdgeInsets.all(isTablet ? 10 : 6),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? cs.primary.withValues(alpha: 0.1)
                                        : surfaceVariant,
                                    borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
                                    border: Border.all(
                                      color: isSelected
                                          ? cs.primary
                                          : border,
                                      width: 2,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.data_usage,
                                        color: isSelected
                                            ? cs.primary
                                            : muted,
                                        size: 16,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        plan['bundle']!.split(' - ')[0], // Just the GB part
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: isSelected
                                              ? cs.primary
                                              : cs.onSurface,
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        plan['bundle']!.split(' - ')[1], // The duration
                                        style: TextStyle(
                                          fontSize: 7,
                                          color: isSelected
                                              ? cs.primary.withValues(alpha: 0.8)
                                              : muted,
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 1),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            '₦${plan['price']}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: isSelected
                                                  ? cs.primary
                                                  : cs.onSurface,
                                            ),
                                          ),
                                          if (isSelected) ...[
                                            const SizedBox(width: 3),
                                            Icon(
                                              Icons.check_circle,
                                              color: cs.primary,
                                              size: 8,
                                            ),
                                          ],
                                        ],
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
                  onPressed: (_isLoading || _selectedDataPlan.isEmpty) ? null : _buyData,
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
                            valueColor: AlwaysStoppedAnimation<Color>(cs.onPrimary),
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
                                padding: const EdgeInsets.symmetric(horizontal: 8),
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
                                    color: transaction.networkColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: transaction.networkColor.withValues(alpha: 0.3),
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
                                    crossAxisAlignment: CrossAxisAlignment.start,
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
                                                  ? cs.primary.withValues(alpha: 0.1)
                                                  : cs.error.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              transaction.isSuccessful ? 'Success' : 'Failed',
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


