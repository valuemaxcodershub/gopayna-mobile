import 'package:flutter/material.dart';

/// GoPayna brand & UX tokens — keep aligned with [DESIGN_GUIDE.md](../../../DESIGN_GUIDE.md).
class GoPaynaColors {
  static const Color primary = Color(0xFF00CA44);
  static const Color primaryDark = Color(0xFF0F8F43);
  static const Color surfaceMuted = Color(0xFFF7F8FA);
  static const Color borderSubtle = Color(0xFFE8EAEE);

  static const Color statusPending = Color(0xFFE78C00);
  static const Color statusSuccess = Color(0xFF00CA44);
  static const Color statusFailed = Color(0xFFD32F2F);
  static const Color statusRefunded = Color(0xFF6A4C93);
  static const Color statusInfo = Color(0xFF1565C0);
}

class GoPaynaRadii {
  static const double card = 16;
  static const double sheet = 24;
  static const double button = 14;
}

class GoPaynaStrings {
  static const String orderPendingHeadline = 'Order received';
  static const String orderPendingSubtitle =
      'Waiting for provider confirmation. This usually takes a few moments — thank you for your patience.';

  static const String walletChargedNotice =
      'Your wallet has been debited for this order. If the provider is slow, your transaction history will update automatically when it completes.';

  static const String providerDelayHint =
      'Providers occasionally experience delays. Pull to refresh in History, or contact support with your reference if nothing changes after several minutes.';

  static const String refundHint =
      'Your wallet was not charged for this order, or it has been refunded. You can try again in a few minutes.';

  static const String downtimeHint =
      'Our service partner is temporarily unavailable. Please try again shortly. If urgent, contact support.';

  static const String receiptBannerPending =
      'Provider confirmation is still pending. This receipt may update when the order completes.';

  static const String receiptBannerSuccess =
      'This order completed successfully.';

  static const String receiptBannerFailed =
      'This order did not complete. Check details below or contact support with your reference.';

  static const String receiptBannerRefunded =
      'A refund was applied for this order. Your wallet balance should reflect the correction.';
}

class GoPaynaUxHelpers {
  GoPaynaUxHelpers._();

  static String augmentProviderError(String message) {
    final m = message.toLowerCase();
    if (m.contains('provider') ||
        m.contains('unavailable') ||
        m.contains('try again soon') ||
        m.contains('cannot handle')) {
      if (message.contains(GoPaynaStrings.downtimeHint)) return message;
      return '$message\n\n${GoPaynaStrings.downtimeHint}';
    }
    return message;
  }
}
