import 'package:flutter/material.dart';

import '../design/gopayna_design.dart';
import 'purchase_navigation.dart';

/// Shown right after a successful or pending purchase. No back — only View receipt.
class PurchaseOutcomeScreen extends StatelessWidget {
  const PurchaseOutcomeScreen({
    super.key,
    required this.reference,
    required this.isPending,
    this.summaryLine,
    this.customerName,
    this.successMessage,
  });

  final String reference;
  final bool isPending;
  final String? summaryLine;
  final String? customerName;
  final String? successMessage;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final message = isPending
        ? GoPaynaStrings.orderPendingShortMessage
        : (successMessage ??
            'Your purchase was successful. Your wallet has been debited. View your receipt below.');

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(isPending ? 'Order received' : 'Purchase complete'),
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(
                isPending ? Icons.hourglass_top_rounded : Icons.check_circle_rounded,
                size: 56,
                color: isPending ? GoPaynaColors.statusPending : GoPaynaColors.statusSuccess,
              ),
              const SizedBox(height: 20),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      height: 1.5,
                      color: cs.onSurface.withValues(alpha: 0.88),
                    ),
              ),
              if (summaryLine != null && summaryLine!.trim().isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  summaryLine!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
              if (customerName != null && customerName!.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Customer: ${customerName!.trim()}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.75),
                      ),
                ),
              ],
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => openTransactionReceiptPage(context, reference: reference),
                  icon: const Icon(Icons.receipt_long_outlined),
                  label: const Text(GoPaynaStrings.viewReceiptButton),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
