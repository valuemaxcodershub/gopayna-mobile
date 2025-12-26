import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to handle automatic logout after idle timeout.
/// Tracks user activity and logs out after specified duration of inactivity.
class IdleTimeoutService {
  static final IdleTimeoutService _instance = IdleTimeoutService._internal();
  factory IdleTimeoutService() => _instance;
  IdleTimeoutService._internal();

  /// Duration of inactivity before auto-logout (15 minutes)
  static const Duration idleTimeout = Duration(minutes: 15);

  Timer? _idleTimer;
  VoidCallback? _onTimeout;
  bool _isActive = false;

  /// Initialize the service with a callback for when timeout occurs
  void initialize({required VoidCallback onTimeout}) {
    _onTimeout = onTimeout;
    _isActive = true;
    _resetTimer();
  }

  /// Call this method on any user activity to reset the idle timer
  void resetIdleTimer() {
    if (_isActive) {
      _resetTimer();
    }
  }

  void _resetTimer() {
    _idleTimer?.cancel();
    _idleTimer = Timer(idleTimeout, _handleTimeout);
  }

  void _handleTimeout() {
    if (_isActive && _onTimeout != null) {
      _onTimeout!();
    }
  }

  /// Stop tracking idle time (e.g., when user logs out manually)
  void dispose() {
    _isActive = false;
    _idleTimer?.cancel();
    _idleTimer = null;
    _onTimeout = null;
  }

  /// Check if the service is currently active
  bool get isActive => _isActive;
}

/// A widget that wraps the app and detects user activity
class IdleDetector extends StatelessWidget {
  final Widget child;
  final VoidCallback? onActivity;

  const IdleDetector({
    super.key,
    required this.child,
    this.onActivity,
  });

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _handleActivity(),
      onPointerMove: (_) => _handleActivity(),
      onPointerUp: (_) => _handleActivity(),
      child: child,
    );
  }

  void _handleActivity() {
    IdleTimeoutService().resetIdleTimer();
    onActivity?.call();
  }
}

/// Mixin to add idle timeout support to any StatefulWidget
mixin IdleTimeoutMixin<T extends StatefulWidget> on State<T> {
  /// Override this to handle logout
  Future<void> handleIdleLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt');
    // Navigate to login - override this in your implementation
  }

  /// Initialize idle timeout with custom logout handler
  void initIdleTimeout({VoidCallback? customLogoutHandler}) {
    IdleTimeoutService().initialize(
      onTimeout: customLogoutHandler ?? () => handleIdleLogout(),
    );
  }

  /// Dispose idle timeout when widget is disposed
  void disposeIdleTimeout() {
    IdleTimeoutService().dispose();
  }
}
