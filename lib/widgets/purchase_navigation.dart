import 'package:flutter/material.dart';

import '../dashboard.dart';
import 'purchase_outcome_screen.dart';
import 'transaction_receipt_page.dart';

/// After a debited purchase, replace the buy flow with the outcome screen (no back).
void openPurchaseOutcome(
  BuildContext context, {
  required String reference,
  required bool isPending,
  String? summaryLine,
  String? customerName,
  String? successMessage,
}) {
  Navigator.of(context).pushReplacement(
    MaterialPageRoute(
      builder: (_) => PurchaseOutcomeScreen(
        reference: reference,
        isPending: isPending,
        summaryLine: summaryLine,
        customerName: customerName,
        successMessage: successMessage,
      ),
    ),
  );
}

/// Full-screen receipt for a wallet reference (replaces current route).
void openTransactionReceiptPage(BuildContext context, {required String reference}) {
  Navigator.of(context).pushReplacement(
    MaterialPageRoute(
      builder: (_) => TransactionReceiptPage(reference: reference),
    ),
  );
}

/// Return to dashboard after purchase/receipt (keeps session; does not pop to intro/login).
void finishPurchaseFlow(BuildContext context) {
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const DashboardScreen()),
    (route) => false,
  );
}
