import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_service.dart';
import 'widgets/transaction_receipt.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _listController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _listAnimation;

  String _selectedPeriod = 'This Month';
  final List<String> _periods = [
    'This Month',
    'Last Month',
    'Last 3 Months',
    'Last 6 Months',
    'This Year',
    'Custom Date'
  ];
  bool _loading = false;
  String? _error;
  DateTimeRange? _customRange;
  final DateFormat _dateFormatter = DateFormat('MMM d, yyyy • h:mma');
  List<WalletTransactionItem> _transactions = [];

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

    final response = await fetchWalletTransactions(token: token, limit: 50);
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
        .map((tx) => WalletTransactionItem.fromMap(tx, _dateFormatter))
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

  void _showPeriodSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final cs = Theme.of(context).colorScheme;
        return SafeArea(
          top: false,
          child: Container(
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    height: 4,
                    width: 40,
                    decoration: BoxDecoration(
                      color: cs.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'Select Period',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ..._periods.map((period) => ListTile(
                        leading: Icon(
                          period == _selectedPeriod
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          color: cs.primary,
                        ),
                        title: Text(period),
                        onTap: () => _handlePeriodSelection(period),
                      )),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _handlePeriodSelection(String period) {
    Navigator.pop(context);
    if (period == 'Custom Date') {
      _showCustomDatePicker();
      return;
    }
    setState(() {
      _selectedPeriod = period;
      _customRange = null;
    });
  }

  void _showCustomDatePicker() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: const Color(0xFF00CA44),
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _customRange = DateTimeRange(
          start: picked.start,
          end: picked.end,
        );
        _selectedPeriod = 'Custom: ${_formatDateRange(picked)}';
      });
    }
  }

  List<WalletTransactionItem> _filteredTransactions() {
    if (_transactions.isEmpty) return [];
    final range = _currentRange();
    if (range == null) {
      return List<WalletTransactionItem>.from(_transactions);
    }
    return _transactions.where((tx) {
      final created = tx.createdAt;
      if (created == null) return false;
      return !created.isBefore(range.start) && !created.isAfter(range.end);
    }).toList();
  }

  DateTimeRange? _currentRange() {
    if (_selectedPeriod.startsWith('Custom') && _customRange != null) {
      return DateTimeRange(
          start: _customRange!.start, end: _endOfDay(_customRange!.end));
    }

    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 'This Month':
        return DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: _endOfDay(DateTime(now.year, now.month + 1, 0)),
        );
      case 'Last Month':
        final lastMonthStart = DateTime(now.year, now.month - 1, 1);
        final lastMonthEnd = DateTime(now.year, now.month, 0);
        return DateTimeRange(
            start: lastMonthStart, end: _endOfDay(lastMonthEnd));
      case 'Last 3 Months':
        final start = DateTime(now.year, now.month - 2, 1);
        return DateTimeRange(
            start: start, end: _endOfDay(DateTime(now.year, now.month + 1, 0)));
      case 'Last 6 Months':
        final start = DateTime(now.year, now.month - 5, 1);
        return DateTimeRange(
            start: start, end: _endOfDay(DateTime(now.year, now.month + 1, 0)));
      case 'This Year':
        return DateTimeRange(
          start: DateTime(now.year, 1, 1),
          end: _endOfDay(DateTime(now.year, 12, 31)),
        );
      default:
        return null;
    }
  }

  DateTime _endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
  }

  String _formatDateRange(DateTimeRange range) {
    return '${range.start.day}/${range.start.month} - ${range.end.day}/${range.end.month}';
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _listController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    final statusBarHeight = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Column(
        children: [
          _buildCustomStatusBar(statusBarHeight),
          _buildHeader(isTablet),
          Expanded(
            child: SlideTransition(
              position: _slideAnimation,
              child: ScaleTransition(
                scale: _listAnimation,
                child: _buildTransactionList(isTablet),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomStatusBar(double statusBarHeight) {
    return Container(
      height: statusBarHeight,
      color: Theme.of(context).colorScheme.surface,
    );
  }

  Widget _buildHeader(bool isTablet) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 32 : 20,
          vertical: isTablet ? 20 : 16,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.black.withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: EdgeInsets.all(isTablet ? 12 : 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.arrow_back,
                  color: Colors.black87,
                  size: isTablet ? 24 : 20,
                ),
              ),
            ),
            SizedBox(width: isTablet ? 16 : 12),
            Icon(
              Icons.history,
              color: const Color(0xFF00CA44),
              size: isTablet ? 28 : 24,
            ),
            SizedBox(width: isTablet ? 12 : 8),
            Expanded(
              child: Text(
                'All Transactions',
                style: TextStyle(
                  fontSize: isTablet ? 24 : 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionList(bool isTablet) {
    final transactions = _filteredTransactions();

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isTablet ? 32 : 20,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(isTablet ? 24 : 20),
          topRight: Radius.circular(isTablet ? 24 : 20),
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildPeriodSelector(isTablet),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _buildErrorState(isTablet)
                    : transactions.isEmpty
                        ? _buildEmptyState(isTablet)
                        : Column(
                            children: [
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isTablet ? 24 : 20,
                                  vertical: isTablet ? 16 : 12,
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      _selectedPeriod,
                                      style: TextStyle(
                                        fontSize: isTablet ? 20 : 18,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      '${transactions.length} transactions',
                                      style: TextStyle(
                                        fontSize: isTablet ? 14 : 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: RefreshIndicator(
                                  onRefresh: _loadTransactions,
                                  child: ListView.builder(
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    padding: EdgeInsets.only(
                                      left: isTablet ? 24 : 20,
                                      right: isTablet ? 24 : 20,
                                      bottom: isTablet ? 24 : 20,
                                    ),
                                    itemCount: transactions.length,
                                    itemBuilder: (context, index) {
                                      return _buildTransactionCard(
                                          transactions[index],
                                          isTablet,
                                          index,
                                          0);
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector(bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 24 : 20),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.calendar_today,
            color: const Color(0xFF00CA44),
            size: isTablet ? 24 : 20,
          ),
          SizedBox(width: isTablet ? 12 : 8),
          Text(
            'Filter by Period',
            style: TextStyle(
              fontSize: isTablet ? 16 : 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: _showPeriodSelector,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 16 : 12,
                vertical: isTablet ? 10 : 8,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF00CA44).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF00CA44),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _selectedPeriod,
                    style: TextStyle(
                      color: const Color(0xFF00CA44),
                      fontSize: isTablet ? 14 : 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: isTablet ? 8 : 4),
                  Icon(
                    Icons.keyboard_arrow_down,
                    color: const Color(0xFF00CA44),
                    size: isTablet ? 18 : 16,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isTablet) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: isTablet ? 120 : 100,
            color: Colors.grey.shade300,
          ),
          SizedBox(height: isTablet ? 24 : 20),
          Text(
            'No Transactions',
            style: TextStyle(
              fontSize: isTablet ? 24 : 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500,
            ),
          ),
          SizedBox(height: isTablet ? 12 : 8),
          Text(
            'No transactions found for this period.',
            style: TextStyle(
              fontSize: isTablet ? 16 : 14,
              color: Colors.grey.shade400,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(bool isTablet) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: isTablet ? 80 : 64,
            color: Colors.red.withValues(alpha: 0.7),
          ),
          SizedBox(height: isTablet ? 20 : 16),
          Text(
            _error ?? 'Unable to load transactions right now.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isTablet ? 18 : 16,
              color: Colors.red,
            ),
          ),
          SizedBox(height: isTablet ? 16 : 12),
          ElevatedButton.icon(
            onPressed: _loading ? null : _loadTransactions,
            icon: const Icon(Icons.refresh),
            label: const Text('Try again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00CA44),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(WalletTransactionItem transaction, bool isTablet,
      int index, int sectionIndex) {
    final isIncoming = transaction.isIncoming;
    final statusColor = transaction.statusColor;
    const brandColor = Color(0xFF00CA44);
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedContainer(
      duration:
          Duration(milliseconds: 400 + (index * 100) + (sectionIndex * 200)),
      curve: Curves.easeOutCubic,
      margin: EdgeInsets.only(bottom: isTablet ? 16 : 12),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          showTransactionReceipt(
            context: context,
            data: transaction.toReceiptData(),
          );
        },
        child: Container(
          padding: EdgeInsets.all(isTablet ? 20 : 16),
          decoration: BoxDecoration(
            color: isDark
                ? brandColor.withValues(alpha: isIncoming ? 0.12 : 0.06)
                : brandColor.withValues(alpha: isIncoming ? 0.08 : 0.04),
            borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
            border: Border.all(
              color: brandColor.withValues(alpha: isIncoming ? 0.3 : 0.1),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(isTablet ? 14 : 12),
                decoration: BoxDecoration(
                  color: brandColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(isTablet ? 14 : 12),
                ),
                child: Icon(
                  transaction.icon,
                  color: brandColor,
                  size: isTablet ? 24 : 20,
                ),
              ),
              SizedBox(width: isTablet ? 16 : 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.title,
                      style: TextStyle(
                        fontSize: isTablet ? 17 : 15,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: isTablet ? 6 : 5),
                    Text(
                      transaction.dateLabel,
                      style: TextStyle(
                        fontSize: isTablet ? 13 : 11,
                        color: cs.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: isTablet ? 12 : 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isIncoming)
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Icon(
                            Icons.add_circle,
                            color: brandColor,
                            size: isTablet ? 16 : 14,
                          ),
                        ),
                      Text(
                        '${isIncoming ? '+' : '-'}₦${transaction.amount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: isTablet ? 17 : 15,
                          fontWeight: FontWeight.bold,
                          color: isIncoming ? brandColor : cs.onSurface,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isTablet ? 8 : 6),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 12 : 10,
                      vertical: isTablet ? 5 : 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(isTablet ? 8 : 6),
                    ),
                    child: Text(
                      transaction.statusLabel,
                      style: TextStyle(
                        fontSize: isTablet ? 11 : 9,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class WalletTransactionItem {
  final String title;
  final double amount;
  final String dateLabel;
  final DateTime? createdAt;
  final String statusLabel;
  final String statusKey;
  final IconData icon;
  final bool isIncoming;
  final String reference;
  final String channelLabel;

  WalletTransactionItem({
    required this.title,
    required this.amount,
    required this.dateLabel,
    required this.createdAt,
    required this.statusLabel,
    required this.statusKey,
    required this.icon,
    required this.isIncoming,
    required this.reference,
    required this.channelLabel,
    this.metadata,
  });

  final Map<String, dynamic>? metadata;

  factory WalletTransactionItem.fromMap(
      Map<String, dynamic> data, DateFormat formatter) {
    final rawStatus = (data['status'] ?? 'pending').toString();
    final createdAt =
        DateTime.tryParse(data['created_at']?.toString() ?? '')?.toLocal();
    final amountValue = double.tryParse(data['amount']?.toString() ?? '') ?? 0;
    final direction =
        (data['type'] ?? data['transaction_type'] ?? data['direction'] ?? '')
            .toString()
            .toLowerCase();
    final isIncoming =
        direction.isNotEmpty ? direction != 'debit' : amountValue >= 0;

    // Parse metadata - handle both string and map types
    Map<String, dynamic>? metadata;
    final rawMetadata = data['metadata'];
    if (rawMetadata is Map<String, dynamic>) {
      metadata = rawMetadata;
    } else if (rawMetadata is String && rawMetadata.isNotEmpty) {
      try {
        // Handle double-encoded JSON (escaped string)
        String jsonStr = rawMetadata;
        if (jsonStr.startsWith('"') && jsonStr.endsWith('"')) {
          jsonStr = jsonStr
              .substring(1, jsonStr.length - 1)
              .replaceAll(r'\"', '"')
              .replaceAll(r'\\', r'\');
        }
        // Parse the JSON properly
        if (jsonStr.startsWith('{')) {
          metadata = _parseJsonSafely(jsonStr);
        }
      } catch (_) {
        metadata = null;
      }
    }

    // Get service type and build title from metadata
    final serviceType = metadata?['serviceType']?.toString() ?? '';
    final metadataDesc = metadata?['description']?.toString() ?? '';
    final metadataChannel = metadata?['channel']?.toString() ?? '';

    final channel =
        (data['channel'] ?? serviceType ?? metadataChannel ?? 'wallet')
            .toString()
            .trim();
    final reference = (data['reference'] ?? '').toString();

    // Build a better title based on service type
    String title;
    if (serviceType == 'airtime') {
      title = 'Airtime Purchase';
    } else if (serviceType == 'data') {
      title = 'Data Purchase';
    } else if (serviceType == 'electricity') {
      title = 'Electricity Purchase';
    } else if (serviceType == 'tv') {
      title = 'TV Subscription';
    } else if (serviceType == 'education') {
      title = 'Education PIN';
    } else if (serviceType == 'refund') {
      title = 'Refund';
    } else if (channel.isNotEmpty && channel != 'wallet' && channel != 'vtu') {
      title = _titleCase(channel);
    } else if (metadataDesc.isNotEmpty) {
      // Extract title from description
      if (metadataDesc.toLowerCase().contains('airtime')) {
        title = 'Airtime Purchase';
      } else if (metadataDesc.toLowerCase().contains('data')) {
        title = 'Data Purchase';
      } else if (metadataDesc.toLowerCase().contains('electric')) {
        title = 'Electricity Purchase';
      } else if (metadataDesc.toLowerCase().contains('tv')) {
        title = 'TV Subscription';
      } else if (metadataDesc.toLowerCase().contains('education') ||
          metadataDesc.toLowerCase().contains('waec') ||
          metadataDesc.toLowerCase().contains('jamb')) {
        title = 'Education PIN';
      } else {
        title = 'Wallet Transaction';
      }
    } else {
      title = channel.isEmpty ? 'Wallet Transaction' : _titleCase(channel);
    }

    final formattedDate =
        createdAt != null ? formatter.format(createdAt) : '--';

    return WalletTransactionItem(
      title: title,
      amount: amountValue.abs(),
      dateLabel: formattedDate,
      createdAt: createdAt,
      statusLabel: _formatStatus(rawStatus),
      statusKey: rawStatus.toLowerCase(),
      icon: _iconForChannel(serviceType.isNotEmpty ? serviceType : channel),
      isIncoming: isIncoming,
      reference: reference,
      channelLabel: serviceType.isNotEmpty
          ? _titleCase(serviceType)
          : (channel.isEmpty ? 'Wallet' : _titleCase(channel)),
      metadata: metadata,
    );
  }

  static Map<String, dynamic>? _parseJsonSafely(String jsonStr) {
    try {
      // Simple JSON parsing for our known structure
      final result = <String, dynamic>{};
      // Remove outer braces and split by commas (not inside quotes)
      final content = jsonStr.substring(1, jsonStr.length - 1);
      final regex = RegExp(r'"([^"]+)"\s*:\s*("([^"]*)"|([^,}]+))');
      for (final match in regex.allMatches(content)) {
        final key = match.group(1) ?? '';
        var value = match.group(3) ?? match.group(4) ?? '';
        value = value.trim();
        if (value == 'null') {
          result[key] = null;
        } else if (value == 'true') {
          result[key] = true;
        } else if (value == 'false') {
          result[key] = false;
        } else if (double.tryParse(value) != null) {
          result[key] = double.parse(value);
        } else {
          result[key] = value;
        }
      }
      return result.isEmpty ? null : result;
    } catch (_) {
      return null;
    }
  }

  TransactionReceiptData toReceiptData() {
    final amountPrefix = isIncoming ? '+' : '-';

    // Build extra details from metadata
    final List<ReceiptField> extraDetails = [];

    if (metadata != null) {
      final serviceType = metadata!['serviceType']?.toString() ?? '';

      // Add network for airtime/data
      final network = metadata!['network']?.toString();
      if (network != null && network.isNotEmpty) {
        extraDetails.add(ReceiptField(label: 'Network', value: network));
      }

      // Add phone number
      final phone = metadata!['phone']?.toString();
      if (phone != null && phone.isNotEmpty) {
        extraDetails.add(ReceiptField(label: 'Phone Number', value: phone));
      }

      // Add airtime value if different from amount (for discounted purchases)
      final airtimeValue = metadata!['airtimeValue'];
      if (airtimeValue != null && serviceType == 'airtime') {
        extraDetails.add(ReceiptField(
            label: 'Airtime Value', value: '₦${airtimeValue.toString()}'));
      }

      // Add discount if applicable
      final discount = metadata!['discount'];
      if (discount != null && discount > 0) {
        extraDetails
            .add(ReceiptField(label: 'Discount', value: '$discount%'));
      }

      // Add plan ID for data
      final planId = metadata!['planId']?.toString();
      if (planId != null && planId.isNotEmpty && serviceType == 'data') {
        extraDetails.add(ReceiptField(label: 'Plan ID', value: planId));
      }

      // Add disco and meter for electricity
      final disco = metadata!['disco']?.toString();
      if (disco != null && disco.isNotEmpty) {
        extraDetails.add(ReceiptField(label: 'Disco', value: disco));
      }

      final meterNumber = metadata!['meterNumber']?.toString();
      if (meterNumber != null && meterNumber.isNotEmpty) {
        extraDetails
            .add(ReceiptField(label: 'Meter Number', value: meterNumber));
      }

      // Add electricity amount and service charge
      final electricityAmount = metadata!['electricityAmount'];
      if (electricityAmount != null) {
        extraDetails.add(ReceiptField(
            label: 'Electricity Amount',
            value: '₦${electricityAmount.toString()}'));
      }

      final serviceCharge = metadata!['serviceCharge'];
      if (serviceCharge != null && serviceCharge > 0) {
        extraDetails.add(ReceiptField(
            label: 'Service Charge', value: '₦${serviceCharge.toString()}'));
      }

      // Add provider and smartcard for TV
      final provider = metadata!['provider']?.toString();
      if (provider != null && provider.isNotEmpty && serviceType == 'tv') {
        extraDetails.add(ReceiptField(label: 'Provider', value: provider));
      }

      final smartcardNumber = metadata!['smartcardNumber']?.toString();
      if (smartcardNumber != null && smartcardNumber.isNotEmpty) {
        extraDetails.add(
            ReceiptField(label: 'Smartcard Number', value: smartcardNumber));
      }

      // Add exam details for education
      final examType = metadata!['examType']?.toString();
      if (examType != null && examType.isNotEmpty) {
        extraDetails.add(ReceiptField(label: 'Exam Type', value: examType));
      }

      final examCode = metadata!['examCode']?.toString();
      if (examCode != null && examCode.isNotEmpty) {
        extraDetails.add(ReceiptField(label: 'Exam Code', value: examCode));
      }

      // Add timestamp from metadata
      final timestamp = metadata!['timestamp']?.toString();
      if (timestamp != null && timestamp.isNotEmpty) {
        try {
          final dt = DateTime.parse(timestamp).toLocal();
          extraDetails.add(ReceiptField(
              label: 'Transaction Time',
              value: DateFormat('MMM d, yyyy • h:mm:ss a').format(dt)));
        } catch (_) {}
      }
    }

    return TransactionReceiptData(
      title: title,
      amountDisplay: '$amountPrefix₦${amount.toStringAsFixed(2)}',
      isCredit: isIncoming,
      statusLabel: statusLabel,
      statusColor: statusColor,
      dateLabel: dateLabel,
      channel: channelLabel,
      reference: reference,
      icon: icon,
      extraDetails: extraDetails,
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

  static IconData _iconForChannel(String channel) {
    final value = channel.toLowerCase();
    if (value.contains('airtime')) return Icons.phone;
    if (value.contains('data')) return Icons.wifi;
    if (value.contains('electric')) return Icons.electrical_services;
    if (value.contains('tv')) return Icons.tv;
    if (value.contains('education')) return Icons.school;
    return Icons.account_balance_wallet;
  }

  static String _titleCase(String value) {
    if (value.isEmpty) return value;
    return value
        .split(' ')
        .where((word) => word.isNotEmpty)
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
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
}
