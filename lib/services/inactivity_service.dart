import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to handle user inactivity and auto-logout
class InactivityService {
  static final InactivityService _instance = InactivityService._internal();
  factory InactivityService() => _instance;
  InactivityService._internal();

  Timer? _inactivityTimer;
  static const Duration _inactivityDuration = Duration(minutes: 7);
  VoidCallback? _onInactivityTimeout;

  /// Initialize the inactivity service with a callback for when timeout occurs
  void initialize({required VoidCallback onTimeout}) {
    _onInactivityTimeout = onTimeout;
  }

  /// Start or restart the inactivity timer
  void resetTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(_inactivityDuration, () {
      _handleInactivityTimeout();
    });
  }

  /// Stop the inactivity timer (call when user logs out)
  void stopTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = null;
  }

  /// Handle inactivity timeout
  void _handleInactivityTimeout() async {
    // Clear stored session data
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt');
    
    // Call the logout callback
    _onInactivityTimeout?.call();
  }

  /// Dispose of resources
  void dispose() {
    _inactivityTimer?.cancel();
    _inactivityTimer = null;
    _onInactivityTimeout = null;
  }
}

/// Widget wrapper that detects user activity and resets inactivity timer
class InactivityDetector extends StatelessWidget {
  final Widget child;
  
  const InactivityDetector({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => InactivityService().resetTimer(),
      onScaleStart: (_) => InactivityService().resetTimer(),
      behavior: HitTestBehavior.translucent,
      child: Listener(
        onPointerDown: (_) => InactivityService().resetTimer(),
        onPointerMove: (_) => InactivityService().resetTimer(),
        child: child,
      ),
    );
  }
}