import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final List<NotificationItem> _notifications = [
    NotificationItem(
      title: 'Transaction Successful',
      message: 'Your airtime purchase of ₦1000 was successful',
      time: '2 minutes ago',
      icon: Icons.check_circle,
      iconColor: const Color(0xFF00CA44),
      isRead: false,
    ),
    NotificationItem(
      title: 'New Feature Available',
      message: 'Try our new education pin purchase feature',
      time: '1 hour ago',
      icon: Icons.star,
      iconColor: Colors.amber,
      isRead: false,
    ),
    NotificationItem(
      title: 'Payment Reminder',
      message: 'Your electricity bill is due in 2 days',
      time: '3 hours ago',
      icon: Icons.electrical_services,
      iconColor: Colors.orange,
      isRead: true,
    ),
    NotificationItem(
      title: 'Wallet Funded',
      message: 'Your wallet has been credited with ₦5000',
      time: 'Yesterday',
      icon: Icons.account_balance_wallet,
      iconColor: const Color(0xFF00CA44),
      isRead: true,
    ),
    NotificationItem(
      title: 'Security Alert',
      message: 'New login detected from Windows device',
      time: '2 days ago',
      icon: Icons.security,
      iconColor: Colors.red,
      isRead: true,
    ),
    NotificationItem(
      title: 'Data Purchase',
      message: 'Successfully purchased 2GB data for ₦1200',
      time: '3 days ago',
      icon: Icons.wifi,
      iconColor: const Color(0xFF00CA44),
      isRead: true,
    ),
    NotificationItem(
      title: 'Welcome to Gopayna',
      message: 'Thank you for joining Gopayna! Enjoy seamless bill payments',
      time: '1 week ago',
      icon: Icons.celebration,
      iconColor: Colors.purple,
      isRead: true,
    ),
  ];

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
  }

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 100));
    _fadeController.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _markAsRead(int index) {
    setState(() {
      _notifications[index].isRead = true;
    });
  }

  void _markAllAsRead() {
    setState(() {
      for (var notification in _notifications) {
        notification.isRead = true;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All notifications marked as read'),
        backgroundColor: Color(0xFF00CA44),
      ),
    );
  }

  void _clearAll() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Clear All Notifications'),
        content: const Text('Are you sure you want to clear all notifications? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _notifications.clear();
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All notifications cleared'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: const Text(
              'Clear All',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final unreadCount = _notifications.where((n) => !n.isRead).length;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Column(
        children: [
          _buildCustomStatusBar(statusBarHeight),
          _buildHeader(isTablet, unreadCount),
          Expanded(
            child: _buildNotificationList(isTablet),
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

  Widget _buildHeader(bool isTablet, int unreadCount) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 32 : 20,
          vertical: isTablet ? 20 : 16,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
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
                  Icons.notifications,
                  color: const Color(0xFF00CA44),
                  size: isTablet ? 28 : 24,
                ),
                SizedBox(width: isTablet ? 12 : 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Notifications',
                        style: TextStyle(
                          fontSize: isTablet ? 24 : 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      if (unreadCount > 0)
                        Text(
                          '$unreadCount unread notifications',
                          style: TextStyle(
                            fontSize: isTablet ? 14 : 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    color: Colors.grey.shade600,
                    size: isTablet ? 24 : 20,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onSelected: (value) {
                    if (value == 'mark_all') {
                      _markAllAsRead();
                    } else if (value == 'clear_all') {
                      _clearAll();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'mark_all',
                      child: Row(
                        children: [
                          Icon(Icons.done_all, size: 20),
                          SizedBox(width: 12),
                          Text('Mark all as read'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'clear_all',
                      child: Row(
                        children: [
                          Icon(Icons.clear_all, size: 20, color: Colors.red),
                          SizedBox(width: 12),
                          Text('Clear all', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationList(bool isTablet) {
    if (_notifications.isEmpty) {
      return SlideTransition(
        position: _slideAnimation,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.notifications_none,
                size: isTablet ? 120 : 100,
                color: Colors.grey.shade300,
              ),
              SizedBox(height: isTablet ? 24 : 20),
              Text(
                'No Notifications',
                style: TextStyle(
                  fontSize: isTablet ? 24 : 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade500,
                ),
              ),
              SizedBox(height: isTablet ? 12 : 8),
              Text(
                'You\'re all caught up! Check back later for updates.',
                style: TextStyle(
                  fontSize: isTablet ? 16 : 14,
                  color: Colors.grey.shade400,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return SlideTransition(
      position: _slideAnimation,
      child: ListView.builder(
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 32 : 20,
          vertical: isTablet ? 24 : 20,
        ),
        itemCount: _notifications.length,
        itemBuilder: (context, index) {
          return _buildNotificationCard(_notifications[index], isTablet, index);
        },
      ),
    );
  }

  Widget _buildNotificationCard(NotificationItem notification, bool isTablet, int index) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300 + (index * 50)),
      curve: Curves.easeOutCubic,
      margin: EdgeInsets.only(bottom: isTablet ? 16 : 12),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          if (!notification.isRead) {
            _markAsRead(index);
          }
        },
        child: Container(
          padding: EdgeInsets.all(isTablet ? 20 : 16),
          decoration: BoxDecoration(
            color: notification.isRead ? Colors.white : const Color(0xFFF0F8F0),
            borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
            border: notification.isRead 
                ? Border.all(color: Colors.grey.shade200, width: 1)
                : Border.all(color: const Color(0xFF00CA44).withValues(alpha: 0.3), width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: notification.isRead ? 0.03 : 0.05),
                blurRadius: notification.isRead ? 6 : 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(isTablet ? 12 : 10),
                decoration: BoxDecoration(
                  color: notification.iconColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  notification.icon,
                  color: notification.iconColor,
                  size: isTablet ? 24 : 20,
                ),
              ),
              SizedBox(width: isTablet ? 16 : 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontSize: isTablet ? 16 : 14,
                              fontWeight: notification.isRead ? FontWeight.w600 : FontWeight.bold,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: isTablet ? 8 : 6,
                            height: isTablet ? 8 : 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF00CA44),
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: isTablet ? 8 : 6),
                    Text(
                      notification.message,
                      style: TextStyle(
                        fontSize: isTablet ? 14 : 12,
                        color: Colors.grey.shade600,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: isTablet ? 8 : 6),
                    Text(
                      notification.time,
                      style: TextStyle(
                        fontSize: isTablet ? 12 : 10,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NotificationItem {
  final String title;
  final String message;
  final String time;
  final IconData icon;
  final Color iconColor;
  bool isRead;

  NotificationItem({
    required this.title,
    required this.message,
    required this.time,
    required this.icon,
    required this.iconColor,
    this.isRead = false,
  });
}


