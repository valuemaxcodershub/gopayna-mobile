import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

class _BuyElectricityScreenState extends State<BuyElectricityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _meterNumberController = TextEditingController();
  final _phoneController = TextEditingController();

  String _selectedProvider = 'eko';
  String _selectedPackage = '';
  bool _isLoading = false;
  final double _walletBalance = 4700.00;

  final List<Map<String, dynamic>> _providers = [
    {
      'id': 'eko',
      'name': 'Eko Electricity (EKEDC)',
      'color': const Color(0xFF0066CC),
      'icon': Icons.electric_bolt,
      'textColor': Colors.white,
    },
    {
      'id': 'ikeja',
      'name': 'Ikeja Electric (IE)',
      'color': const Color(0xFFFF6600),
      'icon': Icons.electric_bolt,
      'textColor': Colors.white,
    },
    {
      'id': 'abuja',
      'name': 'Abuja Electricity (AEDC)',
      'color': const Color(0xFF800080),
      'icon': Icons.electric_bolt,
      'textColor': Colors.white,
    },
    {
      'id': 'kano',
      'name': 'Kano Electricity (KEDCO)',
      'color': const Color(0xFF008000),
      'icon': Icons.electric_bolt,
      'textColor': Colors.white,
    },
    {
      'id': 'portharcourt',
      'name': 'Port Harcourt Electric (PHED)',
      'color': const Color(0xFFDC143C),
      'icon': Icons.electric_bolt,
      'textColor': Colors.white,
    },
    {
      'id': 'jos',
      'name': 'Jos Electricity (JED)',
      'color': const Color(0xFF4B0082),
      'icon': Icons.electric_bolt,
      'textColor': Colors.white,
    },
    {
      'id': 'kaduna',
      'name': 'Kaduna Electric (KAEDCO)',
      'color': const Color(0xFF228B22),
      'icon': Icons.electric_bolt,
      'textColor': Colors.white,
    },
    {
      'id': 'ibadan',
      'name': 'Ibadan Electricity (IBEDC)',
      'color': const Color(0xFFFF4500),
      'icon': Icons.electric_bolt,
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

  final List<ElectricityTransaction> _recentTransactions = [
    ElectricityTransaction(
      id: 'ELE001',
      provider: 'Eko Electricity',
      meterNumber: '12345678901',
      customerName: 'JOHN DOE',
      package: '₦2,000',
      amount: 2000,
      date: DateTime.now().subtract(const Duration(hours: 2)),
      status: 'Successful',
      providerColor: const Color(0xFF0066CC),
    ),
    ElectricityTransaction(
      id: 'ELE002',
      provider: 'Ikeja Electric',
      meterNumber: '98765432109',
      customerName: 'JANE SMITH',
      package: '₦5,000',
      amount: 5000,
      date: DateTime.now().subtract(const Duration(days: 1)),
      status: 'Successful',
      providerColor: const Color(0xFFFF6600),
    ),
  ];

  @override
  void dispose() {
    _meterNumberController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _buyElectricity() {
    if (_formKey.currentState!.validate()) {
      if (_selectedPackage.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a package'),
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
    final selectedPackage = _packages[_selectedProvider]!.firstWhere(
      (package) => '${package['bundle']} - ${package['type']}' == _selectedPackage,
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
                'Please confirm your electricity purchase details:',
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
                    _buildConfirmationRow('Provider', _selectedProviderData['name']),
                    const SizedBox(height: 8),
                    _buildConfirmationRow('Meter Number', _meterNumberController.text),
                    const SizedBox(height: 8),
                    _buildConfirmationRow('Phone Number', _phoneController.text),
                    const SizedBox(height: 8),
                    _buildConfirmationRow('Package', selectedPackage['bundle'] ?? ''),
                    const SizedBox(height: 8),
                    _buildConfirmationRow('Type', selectedPackage['type'] ?? ''),
                    const SizedBox(height: 8),
                    _buildConfirmationRow('Amount', '₦${selectedPackage['price']}'),
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
    final selectedProviderData = _providers.firstWhere((p) => p['id'] == _selectedProvider);
    final selectedPackage = _packages[_selectedProvider]!.firstWhere(
      (package) => '${package['bundle']} - ${package['type']}' == _selectedPackage,
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
          'Electricity',
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
              // Wallet Balance Card
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(isTablet ? 28 : 20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF00B82E), Color(0xFF00A327)],
                  ),
                  borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Wallet Balance',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isTablet ? 18 : 14,
                            ),
                          ),
                          SizedBox(height: isTablet ? 12 : 8),
                          Text(
                            '₦${_walletBalance.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isTablet ? 32 : 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.all(isTablet ? 16 : 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
                      ),
                      child: Icon(
                        Icons.account_balance_wallet,
                        color: Colors.white,
                        size: isTablet ? 32 : 24,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Provider Selection
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
                    const Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        'Select Provider',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
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
                    // Provider Grid
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: isTablet ? 3 : 2,
                          crossAxisSpacing: isTablet ? 16 : 12,
                          mainAxisSpacing: isTablet ? 16 : 12,
                          childAspectRatio: isTablet ? 3.2 : 3.5,
                        ),
                        itemCount: _providers.length,
                        itemBuilder: (context, index) {
                          final provider = _providers[index];
                          final isSelected = _selectedProvider == provider['id'];
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
                              padding: EdgeInsets.all(isTablet ? 16 : 12),
                              decoration: BoxDecoration(
                                color: isSelected 
                                    ? provider['color'].withValues(alpha: 0.1)
                                    : Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(isTablet ? 12 : 8),
                                border: Border.all(
                                  color: isSelected 
                                      ? provider['color']
                                      : Colors.grey.shade300,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    provider['icon'],
                                    color: provider['color'],
                                    size: isTablet ? 20 : 16,
                                  ),
                                  SizedBox(width: isTablet ? 12 : 8),
                                  Expanded(
                                    child: Text(
                                      provider['name'].split(' ')[0],
                                      style: TextStyle(
                                        color: provider['color'],
                                        fontSize: isTablet ? 14 : 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.1),
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
                    labelStyle: TextStyle(fontSize: isTablet ? 18 : 16),
                    prefixIcon: Icon(
                      Icons.electric_meter,
                      color: const Color(0xFF00B82E),
                      size: isTablet ? 28 : 24,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(isTablet ? 20 : 16)),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.all(isTablet ? 28 : 20),
                  ),
                  style: TextStyle(
                    fontSize: isTablet ? 20 : 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
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

              const SizedBox(height: 20),

              // Package Selection
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
                    const Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        'Select Package',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
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
                          final packageId = '${package['bundle']} - ${package['type']}';
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
                                    ? const Color(0xFF00B82E).withValues(alpha: 0.1)
                                    : Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(isTablet ? 12 : 8),
                                border: Border.all(
                                  color: isSelected 
                                      ? const Color(0xFF00B82E)
                                      : Colors.grey.shade300,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        package['bundle'],
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                          color: Colors.black87,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (isSelected)
                                        const Icon(
                                          Icons.check_circle,
                                          color: Color(0xFF00B82E),
                                          size: 13,
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    package['type'],
                                    style: const TextStyle(
                                      fontSize: 8,
                                      color: Colors.black54,
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
                                'Recent Electricity Purchases',
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
                                    color: transaction.providerColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: transaction.providerColor.withValues(alpha: 0.3),
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
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        transaction.provider,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Meter: ${transaction.meterNumber}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.black54,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _formatDate(transaction.date),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.black54,
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
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: transaction.status == 'Successful'
                                            ? Colors.green.shade100
                                            : Colors.red.shade100,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        transaction.status,
                                        style: TextStyle(
                                          color: transaction.status == 'Successful'
                                              ? Colors.green.shade700
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