import 'package:flutter/material.dart';

import '../api_service.dart';
import '../design/gopayna_design.dart';
import '../services/auth_token_storage.dart';
import 'purchase_navigation.dart';
import 'transaction_receipt.dart';
import 'wallet_receipt_helpers.dart';

/// Full-screen receipt after purchase. No back — Done returns to dashboard.
class TransactionReceiptPage extends StatefulWidget {
  const TransactionReceiptPage({super.key, required this.reference});

  final String reference;

  @override
  State<TransactionReceiptPage> createState() => _TransactionReceiptPageState();
}

class _TransactionReceiptPageState extends State<TransactionReceiptPage> {
  final GlobalKey _receiptCaptureKey = GlobalKey();
  TransactionReceiptData? _receiptData;
  String? _error;
  bool _loading = true;
  bool _sharing = false;

  @override
  void initState() {
    super.initState();
    _loadReceipt();
  }

  Future<void> _loadReceipt() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final token = await AuthTokenStorage.readJwt();
    if (token == null || token.isEmpty) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Please sign in again to view this receipt.';
      });
      return;
    }

    Map<String, dynamic>? row;
    for (var attempt = 0; attempt < 6; attempt++) {
      final res = await fetchWalletTransactions(
        token: token,
        reference: widget.reference,
        limit: 1,
      );
      if (res['success'] == true) {
        final list = res['data'] as List<dynamic>? ?? [];
        if (list.isNotEmpty && list.first is Map) {
          row = Map<String, dynamic>.from(list.first as Map);
          break;
        }
      }
      if (attempt < 5) {
        await Future.delayed(const Duration(milliseconds: 450));
      }
    }

    if (!mounted) return;
    final receiptRow = row;
    if (receiptRow == null) {
      setState(() {
        _loading = false;
        _error =
            'Receipt is not ready yet. Pull to refresh or open this order from History in a moment.';
      });
      return;
    }

    setState(() {
      _receiptData = receiptDataFromWalletRow(receiptRow);
      _loading = false;
    });
  }

  Future<void> _shareImage() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      await shareReceiptAsImage(_receiptCaptureKey);
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Receipt'),
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 20),
                        FilledButton(
                          onPressed: _loadReceipt,
                          child: const Text('Try again'),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                          child: TransactionReceiptView(
                            data: _receiptData!,
                            receiptCaptureKey: _receiptCaptureKey,
                          ),
                        ),
                      ),
                      SafeArea(
                        top: false,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                          child: Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _sharing ? null : _shareImage,
                                  icon: _sharing
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        )
                                      : const Icon(Icons.ios_share_rounded),
                                  label: Text(_sharing ? 'Preparing…' : 'Share image'),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    side: const BorderSide(color: GoPaynaColors.primary),
                                    foregroundColor: GoPaynaColors.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: FilledButton(
                                  onPressed: () => finishPurchaseFlow(context),
                                  style: FilledButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                  ),
                                  child: const Text('Done'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}
