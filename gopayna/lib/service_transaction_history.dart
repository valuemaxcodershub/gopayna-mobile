import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_service.dart';
import 'widgets/transaction_receipt.dart';

/// Enum for service types to filter transactions
enum ServiceType {
  airtime('airtime', 'Airtime', Icons.phone),
  data('data', 'Data', Icons.wifi),
  electricity('electricity', 'Electricity', Icons.electrical_services),
  tv('tv', 'TV', Icons.tv),
  education('education', 'Education', Icons.school);

  final String apiValue;
  final String displayName;
  final IconData icon;

  const ServiceType(this.apiValue, this.displayName, this.icon);

  String get title => '$displayName Transaction History';
}

class ServiceTransactionHistoryScreen extends StatefulWidget {
  final ServiceType serviceType;

  const ServiceTransactionHistoryScreen({
    super.key,
    required this.serviceType,
  });

  @override
  State<ServiceTransactionHistoryScreen> createState() =>
      _ServiceTransactionHistoryScreenState();
}

class _ServiceTransactionHistoryScreenState
    extends State<ServiceTransactionHistoryScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _listController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _listAnimation;

  bool _loading = false;
  String? _error;
  final DateFormat _dateFormatter = DateFormat('MMM d, yyyy • h:mma');
  List<ServiceTransaction> _transactions = [];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt');
    if (token == null || token.isEmpty) {
      if (!mounted) return;
      setState(() {
        _error = 'Please log in again to view your history.';
        _loading = false;
      });
      return;
    }

    final response = await fetchVTUHistory(
      token,
      type: widget.serviceType.apiValue,
      limit: 50,
    );
    if (!mounted) return;

    if (response['error'] != null) {
      setState(() {
        _error = response['error'].toString();
        _loading = false;
      });
      return;
    }

    final dataRaw = response['data'] as List<dynamic>? ?? [];
    final parsed = dataRaw
        .cast<Map<String, dynamic>>()
        .map((tx) =>
            ServiceTransaction.fromMap(tx, _dateFormatter, widget.serviceType))
        .toList()
      ..sort((a, b) {
        if (a.createdAt == null && b.createdAt == null) return 0;
        if (a.createdAt == null) return 1;
        if (b.createdAt == null) return -1;
        return b.createdAt!.compareTo(a.createdAt!);
      });

    setState(() {
      _transactions = parsed;
      _loading = false;
    });
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _listController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.elasticOut,
    ));
    _listAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _listController, curve: Curves.elasticOut),
    );
  }

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 100));
    _fadeController.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    _slideController.forward();
    await Future.delayed(const Duration(milliseconds: 400));
    _listController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _listController.dispose();
    super.dispose();
  }

  void _showTransactionReceipt(ServiceTransaction tx) {
    showTransactionReceipt(context: context, data: tx.toReceiptData());
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final cardColor = cs.surface;
    final borderColor = cs.outlineVariant;
    final shadowColor = cs.shadow.withValues(alpha: 0.05);

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: cs.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.serviceType.title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: cs.onSurface,
          ),
        ),
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness:
              cs.brightness == Brightness.dark ? Brightness.light : Brightness.dark,
        ),
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: _buildContent(cs, cardColor, borderColor, shadowColor),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
      ColorScheme cs, Color cardColor, Color borderColor, Color shadowColor) {
    if (_loading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: cs.primary),
            const SizedBox(height: 16),
            Text(
              'Loading transactions...',
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: cs.error),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _loadTransactions,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (_transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              widget.serviceType.icon,
              size: 80,
              color: cs.outlineVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No ${widget.serviceType.displayName.toLowerCase()} transactions yet',
              style: TextStyle(
                fontSize: 16,
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your ${widget.serviceType.displayName.toLowerCase()} purchase history will appear here',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: cs.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTransactions,
      color: cs.primary,
      child: ScaleTransition(
        scale: _listAnimation,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _transactions.length,
          itemBuilder: (context, index) {
            final tx = _transactions[index];
            return _buildTransactionCard(
                tx, cs, cardColor, borderColor, shadowColor);
          },
        ),
      ),
    );
  }

  Widget _buildTransactionCard(ServiceTransaction tx, ColorScheme cs,
      Color cardColor, Color borderColor, Color shadowColor) {
    return GestureDetector(
      onTap: () => _showTransactionReceipt(tx),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 0.5),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: tx.iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  tx.icon,
                  color: tx.iconColor,
                  size: 24,
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
                            tx.title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '-₦${tx.amount.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            tx.subtitle,
                            style: TextStyle(
                              fontSize: 13,
                              color: cs.onSurfaceVariant,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: tx.statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            tx.statusLabel,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: tx.statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tx.dateLabel,
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: cs.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ServiceTransaction {
  final String title;
  final String subtitle;
  final double amount;
  final String dateLabel;
  final DateTime? createdAt;
  final String statusLabel;
  final String statusKey;
  final IconData icon;
  final Color iconColor;
  final String reference;
  final Map<String, dynamic>? details;
  final ServiceType serviceType;

  ServiceTransaction({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.dateLabel,
    required this.createdAt,
    required this.statusLabel,
    required this.statusKey,
    required this.icon,
    required this.iconColor,
    required this.reference,
    required this.details,
    required this.serviceType,
  });

  factory ServiceTransaction.fromMap(
    Map<String, dynamic> data,
    DateFormat formatter,
    ServiceType serviceType,
  ) {
    final rawStatus = (data['status'] ?? 'pending').toString();
    final createdAt =
        DateTime.tryParse(data['createdAt']?.toString() ?? '')?.toLocal();
    final amountValue = double.tryParse(data['amount']?.toString() ?? '') ?? 0;
    final details = data['details'] as Map<String, dynamic>? ?? {};
    final reference = data['reference']?.toString() ?? '';

    // Build title and subtitle based on service type
    String title;
    String subtitle;

    switch (serviceType) {
      case ServiceType.airtime:
        final network =
            details['network']?.toString().toUpperCase() ?? 'Unknown';
        final phone = details['phone']?.toString() ?? '';
        title = '$network Airtime';
        subtitle = phone.isNotEmpty ? phone : 'Airtime Purchase';
        break;
      case ServiceType.data:
        final network =
            details['network']?.toString().toUpperCase() ?? 'Unknown';
        final phone = details['phone']?.toString() ?? '';
        title = '$network Data';
        subtitle = phone.isNotEmpty ? phone : 'Data Purchase';
        break;
      case ServiceType.electricity:
        final disco = details['disco']?.toString().toUpperCase() ?? 'Unknown';
        final meterNumber = details['meterNumber']?.toString() ?? '';
        title = '$disco Electricity';
        subtitle = meterNumber.isNotEmpty ? meterNumber : 'Bill Payment';
        break;
      case ServiceType.tv:
        final provider =
            details['provider']?.toString().toUpperCase() ?? 'Unknown';
        final smartcard = details['smartcardNumber']?.toString() ?? '';
        title = '$provider Subscription';
        subtitle = smartcard.isNotEmpty ? smartcard : 'TV Subscription';
        break;
      case ServiceType.education:
        final examType =
            details['examType']?.toString().toUpperCase() ?? 'Unknown';
        title = '$examType PIN';
        subtitle = 'Education PIN';
        break;
    }

    final formattedDate =
        createdAt != null ? formatter.format(createdAt) : '--';

    return ServiceTransaction(
      title: title,
      subtitle: subtitle,
      amount: amountValue.abs(),
      dateLabel: formattedDate,
      createdAt: createdAt,
      statusLabel: _formatStatus(rawStatus),
      statusKey: rawStatus.toLowerCase(),
      icon: serviceType.icon,
      iconColor: _getServiceColor(serviceType, details),
      reference: reference,
      details: details,
      serviceType: serviceType,
    );
  }

  Color get statusColor {
    switch (statusKey) {
      case 'success':
        return const Color(0xFF00CA44);
      case 'failed':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  static Color _getServiceColor(
      ServiceType type, Map<String, dynamic> details) {
    final network = details['network']?.toString().toLowerCase() ?? '';

    // For airtime and data, use network colors
    if (type == ServiceType.airtime || type == ServiceType.data) {
      switch (network) {
        case 'mtn':
          return const Color(0xFFFFCC00);
        case 'glo':
          return const Color(0xFF00FF00);
        case 'airtel':
          return const Color(0xFFFF0000);
        case '9mobile':
          return const Color(0xFF006400);
        default:
          return Colors.blue;
      }
    }

    // Default colors by service type
    switch (type) {
      case ServiceType.electricity:
        return const Color(0xFFFF9800);
      case ServiceType.tv:
        return const Color(0xFF9C27B0);
      case ServiceType.education:
        return const Color(0xFF2196F3);
      default:
        return Colors.blue;
    }
  }

  static String _formatStatus(String status) {
    switch (status.toLowerCase()) {
      case 'success':
        return 'Successful';
      case 'failed':
        return 'Failed';
      default:
        return status.isEmpty
            ? 'Pending'
            : status[0].toUpperCase() + status.substring(1).toLowerCase();
    }
  }

  TransactionReceiptData toReceiptData() {
    final List<ReceiptField> extraDetails = [];

    if (details != null) {
      // Add network for airtime/data
      final network = details!['network']?.toString();
      if (network != null && network.isNotEmpty) {
        extraDetails
            .add(ReceiptField(label: 'Network', value: network.toUpperCase()));
      }

      // Add phone number
      final phone = details!['phone']?.toString();
      if (phone != null && phone.isNotEmpty) {
        extraDetails.add(ReceiptField(label: 'Phone Number', value: phone));
      }

      // Add airtime value if different from amount
      final airtimeValue = details!['airtimeValue'];
      if (airtimeValue != null && serviceType == ServiceType.airtime) {
        extraDetails.add(ReceiptField(
            label: 'Airtime Value', value: '₦${airtimeValue.toString()}'));
      }

      // Add discount if applicable
      final discount = details!['discount'];
      if (discount != null &&
          discount is num &&
          discount > 0) {
        extraDetails
            .add(ReceiptField(label: 'Discount', value: '$discount%'));
      }

      // Add plan ID for data
      final planId = details!['planId']?.toString();
      if (planId != null &&
          planId.isNotEmpty &&
          serviceType == ServiceType.data) {
        extraDetails.add(ReceiptField(label: 'Plan ID', value: planId));
      }

      // Add disco and meter for electricity
      final disco = details!['disco']?.toString();
      if (disco != null && disco.isNotEmpty) {
        extraDetails
            .add(ReceiptField(label: 'Disco', value: disco.toUpperCase()));
      }

      final meterNumber = details!['meterNumber']?.toString();
      if (meterNumber != null && meterNumber.isNotEmpty) {
        extraDetails
            .add(ReceiptField(label: 'Meter Number', value: meterNumber));
      }

      // Add electricity amount and service charge
      final electricityAmount = details!['electricityAmount'];
      if (electricityAmount != null) {
        extraDetails.add(ReceiptField(
            label: 'Electricity Amount',
            value: '₦${electricityAmount.toString()}'));
      }

      final serviceCharge = details!['serviceCharge'];
      if (serviceCharge != null && serviceCharge is num && serviceCharge > 0) {
        extraDetails.add(ReceiptField(
            label: 'Service Charge', value: '₦${serviceCharge.toString()}'));
      }

      // Add token for electricity
      final token = details!['token']?.toString();
      if (token != null && token.isNotEmpty) {
        extraDetails.add(ReceiptField(label: 'Token', value: token));
      }

      // Add provider and smartcard for TV
      final provider = details!['provider']?.toString();
      if (provider != null &&
          provider.isNotEmpty &&
          serviceType == ServiceType.tv) {
        extraDetails
            .add(ReceiptField(label: 'Provider', value: provider.toUpperCase()));
      }

      final smartcardNumber = details!['smartcardNumber']?.toString();
      if (smartcardNumber != null && smartcardNumber.isNotEmpty) {
        extraDetails.add(
            ReceiptField(label: 'Smartcard Number', value: smartcardNumber));
      }

      // Add exam details for education
      final examType = details!['examType']?.toString();
      if (examType != null && examType.isNotEmpty) {
        extraDetails
            .add(ReceiptField(label: 'Exam Type', value: examType.toUpperCase()));
      }

      final examCode = details!['examCode']?.toString();
      if (examCode != null && examCode.isNotEmpty) {
        extraDetails.add(ReceiptField(label: 'Exam Code', value: examCode));
      }

      // Add quantity for education
      final quantity = details!['quantity'];
      if (quantity != null && serviceType == ServiceType.education) {
        extraDetails.add(ReceiptField(label: 'Quantity', value: '$quantity'));
      }
    }

    return TransactionReceiptData(
      title: title,
      amountDisplay: '-₦${amount.toStringAsFixed(2)}',
      isCredit: false,
      statusLabel: statusLabel,
      statusColor: statusColor,
      dateLabel: dateLabel,
      channel: serviceType.displayName,
      reference: reference,
      icon: icon,
      extraDetails: extraDetails,
    );
  }
}
