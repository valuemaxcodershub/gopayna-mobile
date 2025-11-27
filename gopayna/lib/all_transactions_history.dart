import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
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

  final Map<String, List<TransactionItem>> _groupedTransactions = {
    'This Month': [
      TransactionItem(
        type: 'Referral Earnings',
        amount: 500.00,
        date: 'Nov 18th, 15:30:12',
        status: 'Completed',
        icon: Icons.group,
        isIncoming: true,
      ),
      TransactionItem(
        type: 'Airtime',
        amount: 500.00,
        date: 'Nov 18th, 17:23:07',
        status: 'Successful',
        icon: Icons.phone,
      ),
      TransactionItem(
        type: 'Referral Earnings',
        amount: 250.00,
        date: 'Nov 17th, 12:45:33',
        status: 'Completed',
        icon: Icons.group,
        isIncoming: true,
      ),
      TransactionItem(
        type: 'Data Purchase',
        amount: 1200.00,
        date: 'Nov 17th, 14:15:22',
        status: 'Successful',
        icon: Icons.wifi,
      ),
      TransactionItem(
        type: 'Electricity Bill',
        amount: 5000.00,
        date: 'Nov 15th, 09:30:45',
        status: 'Successful',
        icon: Icons.electrical_services,
      ),
      TransactionItem(
        type: 'TV Subscription',
        amount: 4500.00,
        date: 'Nov 10th, 16:45:12',
        status: 'Successful',
        icon: Icons.tv,
      ),
      TransactionItem(
        type: 'Education Pin',
        amount: 2000.00,
        date: 'Nov 8th, 11:20:33',
        status: 'Successful',
        icon: Icons.school,
      ),
    ],
    'Last Month': [
      TransactionItem(
        type: 'Referral Earnings',
        amount: 500.00,
        date: 'Oct 30th, 09:15:22',
        status: 'Completed',
        icon: Icons.group,
        isIncoming: true,
      ),
      TransactionItem(
        type: 'Airtime',
        amount: 1000.00,
        date: 'Oct 28th, 12:45:07',
        status: 'Successful',
        icon: Icons.phone,
      ),
      TransactionItem(
        type: 'Data Purchase',
        amount: 2000.00,
        date: 'Oct 25th, 15:30:22',
        status: 'Failed',
        icon: Icons.wifi,
      ),
      TransactionItem(
        type: 'Wallet Funding',
        amount: 10000.00,
        date: 'Oct 20th, 08:15:45',
        status: 'Successful',
        icon: Icons.account_balance_wallet,
        isIncoming: true,
      ),
    ],
    'Jul 2025': [
      TransactionItem(
        type: 'Referral Earnings',
        amount: 300.00,
        date: 'Jul 10th, 16:20:15',
        status: 'Completed',
        icon: Icons.group,
        isIncoming: true,
      ),
      TransactionItem(
        type: 'Airtime',
        amount: 500.00,
        date: 'Jul 9th,13:25:08',
        status: 'Successful',
        icon: Icons.phone,
      ),
      TransactionItem(
        type: 'Airtime',
        amount: 500.00,
        date: 'Jul 8th,18:25:08',
        status: 'Successful',
        icon: Icons.phone,
      ),
      TransactionItem(
        type: 'Airtime',
        amount: 500.00,
        date: 'Jul 7th,17:25:08',
        status: 'Successful',
        icon: Icons.phone,
      ),
      TransactionItem(
        type: 'Airtime',
        amount: 400.00,
        date: 'Jul 6th,19:25:08',
        status: 'Successful',
        icon: Icons.phone,
      ),
    ],
  };

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
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
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              height: 4,
              width: 40,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
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
                color: const Color(0xFF00B82E),
              ),
              title: Text(period),
              onTap: () {
                setState(() {
                  _selectedPeriod = period;
                });
                Navigator.pop(context);
                if (period == 'Custom Date') {
                  _showCustomDatePicker();
                }
              },
            )),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
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
              primary: const Color(0xFF00B82E),
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        _selectedPeriod = 'Custom: ${_formatDateRange(picked)}';
      });
    } else {
      setState(() {
        _selectedPeriod = 'This Month';
      });
    }
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
              color: const Color(0xFF00B82E),
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
    final transactions = _groupedTransactions[_selectedPeriod] ?? [];
    
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
          transactions.isEmpty ? Expanded(child: _buildEmptyState(isTablet)) : Expanded(
            child: Column(
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
                          color: Theme.of(context).colorScheme.onSurface,
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
                  child: ListView.builder(
                    padding: EdgeInsets.only(
                      left: isTablet ? 24 : 20,
                      right: isTablet ? 24 : 20,
                      bottom: isTablet ? 24 : 20,
                    ),
                    itemCount: transactions.length,
                    itemBuilder: (context, index) {
                      return _buildTransactionCard(transactions[index], isTablet, index, 0);
                    },
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
            color: const Color(0xFF00B82E),
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
                color: const Color(0xFF00B82E).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF00B82E),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _selectedPeriod,
                    style: TextStyle(
                      color: const Color(0xFF00B82E),
                      fontSize: isTablet ? 14 : 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: isTablet ? 8 : 4),
                  Icon(
                    Icons.keyboard_arrow_down,
                    color: const Color(0xFF00B82E),
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

  Widget _buildTransactionCard(TransactionItem transaction, bool isTablet, int index, int sectionIndex) {
    final isIncoming = transaction.isIncoming;
    return AnimatedContainer(
      duration: Duration(milliseconds: 400 + (index * 100) + (sectionIndex * 200)),
      curve: Curves.easeOutCubic,
      margin: EdgeInsets.only(bottom: isTablet ? 16 : 12),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          _showTransactionDetails(transaction);
        },
        child: Container(
          padding: EdgeInsets.all(isTablet ? 20 : 16),
          decoration: BoxDecoration(
            color: isIncoming 
                ? Colors.green.shade50
                : const Color(0xFF00B82E).withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
            border: Border.all(
              color: isIncoming
                  ? Colors.green.withValues(alpha: 0.3)
                  : const Color(0xFF00B82E).withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(isTablet ? 14 : 12),
                decoration: BoxDecoration(
                  color: isIncoming
                      ? Colors.green.withValues(alpha: 0.1)
                      : const Color(0xFF00B82E).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(isTablet ? 14 : 12),
                ),
                child: Icon(
                  transaction.icon,
                  color: isIncoming ? Colors.green.shade600 : const Color(0xFF00B82E),
                  size: isTablet ? 24 : 20,
                ),
              ),
              SizedBox(width: isTablet ? 16 : 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.type,
                      style: TextStyle(
                        fontSize: isTablet ? 18 : 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: isTablet ? 6 : 4),
                    Text(
                      transaction.date,
                      style: TextStyle(
                        fontSize: isTablet ? 14 : 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isIncoming)
                        Icon(
                          Icons.add_circle,
                          color: Colors.green.shade600,
                          size: isTablet ? 16 : 14,
                        ),
                      if (isIncoming) SizedBox(width: 4),
                      Text(
                        '${isIncoming ? '+' : ''}₦${transaction.amount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: isTablet ? 18 : 16,
                          fontWeight: FontWeight.bold,
                          color: isIncoming ? Colors.green.shade600 : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isTablet ? 6 : 4),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 12 : 8,
                      vertical: isTablet ? 6 : 4,
                    ),
                    decoration: BoxDecoration(
                      color: isIncoming ? Colors.green.shade600 : const Color(0xFF00B82E),
                      borderRadius: BorderRadius.circular(isTablet ? 8 : 6),
                    ),
                    child: Text(
                      transaction.status,
                      style: TextStyle(
                        fontSize: isTablet ? 12 : 10,
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

  void _showTransactionDetails(TransactionItem transaction) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF00B82E).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  transaction.icon,
                  color: const Color(0xFF00B82E),
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Transaction Details',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              _buildDetailRow('Type', transaction.type),
              _buildDetailRow('Amount', '₦${transaction.amount.toStringAsFixed(2)}'),
              _buildDetailRow('Date', transaction.date),
              _buildDetailRow('Status', transaction.status),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00B82E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Close',
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
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

class TransactionItem {
  final String type;
  final double amount;
  final String date;
  final String status;
  final IconData icon;
  final bool isIncoming;

  TransactionItem({
    required this.type,
    required this.amount,
    required this.date,
    required this.status,
    required this.icon,
    this.isIncoming = false,
  });
}
