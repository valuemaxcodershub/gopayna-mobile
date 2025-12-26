import 'package:flutter/material.dart';

import '../app_settings.dart';

/// Helper widget that rebuilds its child whenever the wallet visibility
/// preference changes, allowing screens to mask balances consistently.
class WalletVisibilityBuilder extends StatelessWidget {
  const WalletVisibilityBuilder({
    super.key,
    required this.builder,
  });

  final Widget Function(BuildContext context, bool showBalance) builder;

  @override
  Widget build(BuildContext context) {
    final settings = AppSettings();
    return AnimatedBuilder(
      animation: settings,
      builder: (context, _) => builder(context, settings.showWalletBalance),
    );
  }
}

