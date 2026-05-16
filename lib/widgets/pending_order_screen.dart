import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../api_service.dart';
import '../design/gopayna_design.dart';
import '../services/auth_token_storage.dart';
import '../support.dart';
import 'transaction_receipt.dart';

/// Full-screen pending UX: refresh status, optional VTU requery, support.
class PendingOrderScreen extends StatefulWidget {
  const PendingOrderScreen({
    super.key,
    required this.reference,
    required this.serviceTitle,
    this.summaryLine,
    this.orderId,
    this.requestId,
  });

  final String reference;
  final String serviceTitle;
  final String? summaryLine;
  final String? orderId;
  final String? requestId;

  @override
  State<PendingOrderScreen> createState() => _PendingOrderScreenState();
}

class _PendingOrderScreenState extends State<PendingOrderScreen> {
  bool _loading = false;
  String? _statusHint;
  Map<String, dynamic>? _lastTx;

  Future<void> _refreshWalletRow() async {
    final token = await AuthTokenStorage.readJwt();
    if (token == null || token.isEmpty) return;
    setState(() => _loading = true);
    try {
      final res = await fetchWalletTransactions(
        token: token,
        reference: widget.reference,
        limit: 1,
      );
      if (!mounted) return;
      if (res['success'] == true) {
        final list = res['data'] as List<dynamic>? ?? [];
        if (list.isNotEmpty) {
          final row = list.first as Map<String, dynamic>;
          setState(() {
            _lastTx = row;
            final st = (row['status'] ?? '').toString().toLowerCase();
            if (st == 'success' || st == 'completed') {
              _statusHint = 'Confirmed — this order completed.';
            } else if (st == 'failed') {
              _statusHint =
                  'Marked as failed. If your wallet was debited incorrectly, contact support with this reference.';
            } else {
              _statusHint = 'Still waiting on provider confirmation.';
            }
          });
        } else {
          setState(() => _statusHint = 'Transaction not found yet — try again shortly.');
        }
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _requeryProvider() async {
    final oid = widget.orderId?.trim() ?? '';
    final rid = widget.requestId?.trim() ?? '';
    if (oid.isEmpty && rid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No provider order id yet — refresh status from wallet first.'),
        ),
      );
      return;
    }
    final token = await AuthTokenStorage.readJwt();
    if (token == null || token.isEmpty) return;
    setState(() => _loading = true);
    try {
      final res = await queryTransaction(
        token,
        orderId: oid.isNotEmpty ? oid : null,
        requestId: rid.isNotEmpty ? rid : null,
      );
      if (!mounted) return;
      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Provider query sent. Check status again in a moment.')),
        );
        await _refreshWalletRow();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['error']?.toString() ?? 'Could not requery.')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openSupport() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SupportScreen()),
    );
  }

  void _maybeShowReceipt() {
    final row = _lastTx;
    if (row == null) return;
    final status = (row['status'] ?? '').toString().toLowerCase();
    final amount = double.tryParse(row['amount']?.toString() ?? '') ?? 0;
    final isCredit = amount > 0;
    final receipt = TransactionReceiptData(
      title: widget.serviceTitle,
      amountDisplay:
          '${isCredit ? '+' : '-'}₦${amount.abs().toStringAsFixed(2)}',
      isCredit: isCredit,
      statusLabel: status.isEmpty ? 'Pending' : status,
      statusColor: status == 'failed'
          ? GoPaynaColors.statusFailed
          : (status == 'success' || status == 'completed')
              ? GoPaynaColors.statusSuccess
              : GoPaynaColors.statusPending,
      dateLabel: DateTime.now().toLocal().toString().split('.').first,
      channel: (row['channel'] ?? 'service').toString(),
      reference: widget.reference,
      icon: Icons.receipt_long,
      outcome: _receiptOutcomeFor(status, row),
      outcomeMessage: _receiptMessageFor(status, row),
    );
    showTransactionReceipt(context: context, data: receipt);
  }

  ReceiptOutcome? _receiptOutcomeFor(String status, Map<String, dynamic> row) {
    final meta = row['metadata'];
    Map<String, dynamic>? m;
    if (meta is Map<String, dynamic>) m = meta;
    if (m != null && m['refunded'] == true) return ReceiptOutcome.refunded;
    switch (status) {
      case 'success':
      case 'completed':
        return ReceiptOutcome.success;
      case 'failed':
        return ReceiptOutcome.failed;
      default:
        return ReceiptOutcome.pending;
    }
  }

  String? _receiptMessageFor(String status, Map<String, dynamic> row) {
    final meta = row['metadata'];
    if (meta is Map && meta['refunded'] == true) {
      return GoPaynaStrings.receiptBannerRefunded;
    }
    switch (status) {
      case 'success':
      case 'completed':
        return GoPaynaStrings.receiptBannerSuccess;
      case 'failed':
        return GoPaynaStrings.receiptBannerFailed;
      default:
        return GoPaynaStrings.receiptBannerPending;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshWalletRow());
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order status'),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
      ),
      body: RefreshIndicator(
        color: GoPaynaColors.primary,
        onRefresh: _refreshWalletRow,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            Icon(Icons.hourglass_top_rounded,
                size: 56, color: GoPaynaColors.statusPending),
            const SizedBox(height: 16),
            Text(
              GoPaynaStrings.orderPendingHeadline,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              GoPaynaStrings.orderPendingSubtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.75),
                    height: 1.45,
                  ),
            ),
            if (widget.summaryLine != null &&
                widget.summaryLine!.trim().isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                widget.summaryLine!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: GoPaynaColors.surfaceMuted,
                borderRadius: BorderRadius.circular(GoPaynaRadii.card),
                border: Border.all(color: GoPaynaColors.borderSubtle),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reference',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
                  const SizedBox(height: 6),
                  SelectableText(
                    widget.reference,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: GoPaynaColors.statusPending.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(GoPaynaRadii.card),
                border: Border.all(
                  color: GoPaynaColors.statusPending.withValues(alpha: 0.25),
                ),
              ),
              child: Text(
                '${GoPaynaStrings.walletChargedNotice}\n\n${GoPaynaStrings.providerDelayHint}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      height: 1.5,
                      color: cs.onSurface.withValues(alpha: 0.85),
                    ),
              ),
            ),
            if (_statusHint != null) ...[
              const SizedBox(height: 16),
              Text(
                _statusHint!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: cs.primary,
                    ),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _loading ? null : _refreshWalletRow,
              icon: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh_rounded),
              label: Text(_loading ? 'Checking…' : 'Refresh status'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _loading ? null : _requeryProvider,
              icon: const Icon(Icons.sync_alt_rounded),
              label: const Text('Requery provider'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _openSupport,
              icon: const Icon(Icons.support_agent_rounded),
              label: const Text('Contact support'),
            ),
            if (_lastTx != null) ...[
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: _maybeShowReceipt,
                icon: const Icon(Icons.receipt_long_outlined),
                label: const Text('Preview receipt from last check'),
              ),
            ],
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: widget.reference));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Reference copied')),
                );
              },
              child: const Text('Copy reference'),
            ),
          ],
        ),
      ),
    );
  }
}
