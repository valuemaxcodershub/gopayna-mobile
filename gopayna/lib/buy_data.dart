import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

class _BuyDataScreenState extends State<BuyDataScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController(text: '08051237666');

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
      'color': const Color(0xFF00B82E),
      'icon': Icons.sim_card,
      'textColor': Colors.white,
    },
    {
      'id': '9mobile',
      'name': '9Mobile',
      'color': const Color(0xFF006633),
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
      networkColor: const Color(0xFF00B82E),
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
          const SnackBar(
            content: Text('Please select a data plan'),
            backgroundColor: Colors.red,
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
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Please confirm your data purchase details:',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
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
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _processPurchase();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00B82E),
                foregroundColor: Colors.white,
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
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ),
        const Text(': '),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
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
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF00B82E), Color(0xFF00A327)],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: isTablet ? 100 : 80,
                  height: isTablet ? 100 : 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: isTablet ? 60 : 50,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Data Purchase Successful!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'You successfully purchased ${selectedPlan['bundle']} ${selectedNetworkData['name']} data for ${_phoneController.text}',
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
                      foregroundColor: const Color(0xFF00B82E),
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
    
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: const Color(0xFF00B82E),
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back,
            color: Colors.white,
            size: isTablet ? 28 : 20,
          ),
        ),
        title: Text(
          'Data',
          style: TextStyle(
            color: Colors.white,
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
                color: Colors.white,
                fontSize: isTablet ? 20 : 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isTablet ? 32 : 20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Network Selection
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.1),
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
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              _showNetworkList 
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              color: Colors.grey.shade600,
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
                          color: Colors.grey.shade50,
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
                                      ? const Color(0xFF00B82E).withValues(alpha: 0.1)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _selectedNetwork == network['id']
                                        ? const Color(0xFF00B82E)
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
                                            ? const Color(0xFF00B82E)
                                            : Colors.black87,
                                      ),
                                    ),
                                    const Spacer(),
                                    if (_selectedNetwork == network['id'])
                                      const Icon(
                                        Icons.check_circle,
                                        color: Color(0xFF00B82E),
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    prefixIcon: Icon(
                      Icons.phone,
                      color: Color(0xFF00B82E),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(16)),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.all(20),
                  ),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF00B82E),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFF00B82E),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(14),
                          topRight: Radius.circular(14),
                        ),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.data_usage,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _selectedDataPlan.isEmpty 
                                ? 'Select Data Plan'
                                : _selectedDataPlan,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          if (_selectedDataPlan.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check,
                                color: Color(0xFF00B82E),
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
                          const Text(
                            'Available Data Plans',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
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
                                        ? const Color(0xFF00B82E).withValues(alpha: 0.1)
                                        : Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
                                    border: Border.all(
                                      color: isSelected
                                          ? const Color(0xFF00B82E)
                                          : Colors.grey.shade200,
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
                                            ? const Color(0xFF00B82E)
                                            : Colors.grey.shade600,
                                        size: 16,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        plan['bundle']!.split(' - ')[0], // Just the GB part
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: isSelected
                                              ? const Color(0xFF00B82E)
                                              : Colors.black87,
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
                                              ? const Color(0xFF00B82E).withValues(alpha: 0.8)
                                              : Colors.grey.shade600,
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
                                                  ? const Color(0xFF00B82E)
                                                  : Colors.black87,
                                            ),
                                          ),
                                          if (isSelected) ...[
                                            const SizedBox(width: 3),
                                            const Icon(
                                              Icons.check_circle,
                                              color: Color(0xFF00B82E),
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

              SizedBox(height: isTablet ? 16 : 12),

              // Wallet Balance Info
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  'Wallet Balance: ₦${_walletBalance.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: isTablet ? 14 : 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),

              SizedBox(height: isTablet ? 48 : 40),

              // Buy Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_isLoading || _selectedDataPlan.isEmpty) ? null : _buyData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00B82E),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: isTablet ? 20 : 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
                    ),
                    elevation: 8,
                    shadowColor: const Color(0xFF00B82E).withValues(alpha: 0.3),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          height: isTablet ? 28 : 20,
                          width: isTablet ? 28 : 20,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.1),
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
                            const Icon(
                              Icons.history,
                              color: Color(0xFF00B82E),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Recent Data Purchases',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
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
                              child: const Text(
                                'View All',
                                style: TextStyle(
                                  color: Color(0xFF00B82E),
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
                          color: Colors.grey.shade100,
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
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.black87,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            '₦${transaction.amount}',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        transaction.dataBundle,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Text(
                                            transaction.phoneNumber,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
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
                                                  ? const Color(0xFF00B82E).withValues(alpha: 0.1)
                                                  : Colors.red.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              transaction.isSuccessful ? 'Success' : 'Failed',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w500,
                                                color: transaction.isSuccessful
                                                    ? const Color(0xFF00B82E)
                                                    : Colors.red,
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
                                          color: Colors.grey.shade500,
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