import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';

import '../api_service.dart';
import '../design/gopayna_design.dart';
import '../services/auth_token_storage.dart';

/// Captures [boundaryKey] (wrap receipt in RepaintBoundary) and shares as PNG.
Future<void> shareReceiptAsImage(GlobalKey boundaryKey) async {
  final boundary =
      boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
  if (boundary == null) {
    return;
  }

  final image = await boundary.toImage(pixelRatio: 3.0);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  if (byteData == null) {
    return;
  }

  final pngBytes = byteData.buffer.asUint8List();
  await SharePlus.instance.share(
    ShareParams(
      files: [
        XFile.fromData(
          pngBytes,
          mimeType: 'image/png',
          name: 'gopaynow-receipt.png',
        ),
      ],
      subject: 'GoPayna receipt',
    ),
  );
}

String _formatReceiptToken(String value) {
  final compact = value.replaceAll(RegExp(r'\s+'), '');
  if (compact.isEmpty || compact.length < 8) {
    return value;
  }

  final chunks = <String>[];
  for (var index = 0; index < compact.length; index += 4) {
    final end = (index + 4 < compact.length) ? index + 4 : compact.length;
    chunks.add(compact.substring(index, end));
  }
  return chunks.join(' ');
}

/// Receipt state for user-visible messaging (pending, delivered, failed, refund).
enum ReceiptOutcome { pending, success, failed, refunded }

class TransactionReceiptData {
  const TransactionReceiptData({
    required this.title,
    required this.amountDisplay,
    required this.isCredit,
    required this.statusLabel,
    required this.statusColor,
    required this.dateLabel,
    required this.channel,
    required this.reference,
    required this.icon,
    this.extraDetails = const <ReceiptField>[],
    this.outcome,
    this.outcomeMessage,
    this.showProviderRequery = false,
    this.providerOrderId,
    this.clubkonnectRequestId,
  });

  final String title;
  final String amountDisplay;
  final bool isCredit;
  final String statusLabel;
  final Color statusColor;
  final String dateLabel;
  final String channel;
  final String reference;
  final IconData icon;
  final List<ReceiptField> extraDetails;
  final ReceiptOutcome? outcome;
  final String? outcomeMessage;
  final bool showProviderRequery;
  final String? providerOrderId;
  final String? clubkonnectRequestId;

  String get channelDisplay => channel.isEmpty ? 'Wallet transaction' : channel;

  String get referenceDisplay => reference.isEmpty ? '--' : reference;

  String buildShareMessage() {
    final buffer = StringBuffer()
      ..writeln('GoPayna Transaction Receipt')
      ..writeln('Type: $title')
      ..writeln('Amount: $amountDisplay')
      ..writeln('Status: $statusLabel')
      ..writeln('Date: $dateLabel')
      ..writeln('Channel: $channelDisplay')
      ..writeln('Reference: $referenceDisplay');

    for (final field in extraDetails) {
      final fieldValue =
          field.label.toLowerCase() == 'token' ? _formatReceiptToken(field.value) : field.value;
      buffer.writeln('${field.label}: $fieldValue');
    }

    buffer.writeln('\nShared via GoPayna');
    return buffer.toString();
  }
}

class ReceiptField {
  const ReceiptField({required this.label, required this.value});

  final String label;
  final String value;
}

Future<void> showTransactionReceipt({
  required BuildContext context,
  required TransactionReceiptData data,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => _TransactionReceiptSheet(data: data),
  );
}

class _TransactionReceiptSheet extends StatefulWidget {
  const _TransactionReceiptSheet({required this.data});

  final TransactionReceiptData data;

  @override
  State<_TransactionReceiptSheet> createState() => _TransactionReceiptSheetState();
}

class _TransactionReceiptSheetState extends State<_TransactionReceiptSheet> {
  bool _requeryLoading = false;
  final GlobalKey _receiptCaptureKey = GlobalKey();

  TransactionReceiptData get data => widget.data;

  Future<void> _requeryProvider() async {
    final token = await AuthTokenStorage.readJwt();
    if (token == null || token.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in again to requery this order.')),
      );
      return;
    }

    setState(() => _requeryLoading = true);
    try {
      final res = await queryTransaction(
        token,
        orderId: data.providerOrderId,
        requestId: data.clubkonnectRequestId ?? data.reference,
        walletReference: data.reference,
      );
      if (!mounted) return;
      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Provider query sent. Pull to refresh History in a moment.'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['error']?.toString() ?? 'Could not requery order.')),
        );
      }
    } finally {
      if (mounted) setState(() => _requeryLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomInset = mediaQuery.viewInsets.bottom;
    final isTablet = mediaQuery.size.width > 600;
    final tokenField = _findField('Token');
    final deliveryField = _findField('Delivery Receipt');
    final deliveryEmailField =
        tokenField != null ? _findField('Delivery Email') : null;
    final detailFields = data.extraDetails.where((field) {
      if (field.label == 'Token' || field.label == 'Delivery Receipt') {
        return false;
      }
      if (tokenField != null && field.label == 'Delivery Email') {
        return false;
      }
      return true;
    }).toList();

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(isTablet ? 28 : 24),
            topRight: Radius.circular(isTablet ? 28 : 24),
          ),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 32 : 24,
          vertical: isTablet ? 28 : 24,
        ),
        child: SingleChildScrollView(
          child: RepaintBoundary(
            key: _receiptCaptureKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(height: isTablet ? 24 : 20),
                if (data.outcome != null &&
                  (data.outcomeMessage != null &&
                      data.outcomeMessage!.trim().isNotEmpty)) ...[
                _OutcomeBanner(
                  outcome: data.outcome!,
                  message: data.outcomeMessage!,
                ),
                SizedBox(height: isTablet ? 18 : 14),
              ],
              Container(
                padding: EdgeInsets.all(isTablet ? 20 : 16),
                decoration: BoxDecoration(
                  color: GoPaynaColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  data.icon,
                  color: GoPaynaColors.primary,
                  size: isTablet ? 36 : 32,
                ),
              ),
              SizedBox(height: isTablet ? 20 : 16),
              Text(
                'Transaction Receipt',
                style: TextStyle(
                  fontSize: isTablet ? 22 : 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: isTablet ? 6 : 4),
              Text(
                data.title,
                style: TextStyle(
                  fontSize: isTablet ? 15 : 14,
                  color: Colors.grey.shade600,
                ),
              ),
              SizedBox(height: isTablet ? 20 : 16),
              _buildSectionTitle('Transaction Status'),
              const SizedBox(height: 10),
              _buildSectionCard(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatusMetric(
                          label: 'Amount',
                          value: data.amountDisplay,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatusChip(data.statusLabel, data.statusColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _buildDetailItem('Date', data.dateLabel),
                  const SizedBox(height: 12),
                  _buildDetailItem('Channel', data.channelDisplay),
                  const SizedBox(height: 12),
                  _buildDetailItem('Reference', data.referenceDisplay),
                ],
              ),
              if (tokenField != null) ...[
                SizedBox(height: isTablet ? 22 : 18),
                _buildSectionTitle('Token'),
                const SizedBox(height: 10),
                _buildTokenCard(
                  token: tokenField.value,
                  deliveryEmail: deliveryEmailField?.value,
                  deliveryMessage: deliveryField?.value,
                ),
              ],
              if (detailFields.isNotEmpty) ...[
                SizedBox(height: isTablet ? 22 : 18),
                _buildSectionTitle('Details'),
                const SizedBox(height: 10),
                _buildSectionCard(
                  children: [
                    for (var index = 0; index < detailFields.length; index++) ...[
                      _buildDetailItem(
                        detailFields[index].label,
                        detailFields[index].value,
                      ),
                      if (index != detailFields.length - 1) const SizedBox(height: 12),
                    ],
                    if (tokenField == null && deliveryField != null) ...[
                      if (detailFields.isNotEmpty) const SizedBox(height: 12),
                      _buildDetailItem(deliveryField.label, deliveryField.value),
                    ],
                  ],
                ),
              ],
              if (data.showProviderRequery) ...[
                SizedBox(height: isTablet ? 18 : 14),
                Text(
                  GoPaynaStrings.receiptRequeryHint,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: Colors.grey.shade700,
                  ),
                ),
                SizedBox(height: isTablet ? 12 : 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _requeryLoading ? null : _requeryProvider,
                    icon: _requeryLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.sync_alt_rounded),
                    label: Text(
                      _requeryLoading ? 'Querying…' : GoPaynaStrings.receiptRequeryButton,
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: isTablet ? 14 : 12),
                      side: const BorderSide(color: Color(0xFF00CA44)),
                      foregroundColor: const Color(0xFF00CA44),
                    ),
                  ),
                ),
              ],
              SizedBox(height: isTablet ? 28 : 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => shareReceiptAsImage(_receiptCaptureKey),
                      icon: const Icon(Icons.share),
                      label: const Text('Share Receipt'),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: isTablet ? 16 : 14),
                        side: const BorderSide(color: Color(0xFF00CA44)),
                        foregroundColor: const Color(0xFF00CA44),
                      ),
                    ),
                  ),
                  SizedBox(width: isTablet ? 16 : 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00CA44),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: isTablet ? 16 : 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Close',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  ReceiptField? _findField(String label) {
    for (final field in data.extraDetails) {
      if (field.label == label) {
        return field;
      }
    }
    return null;
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
          color: Colors.grey.shade700,
        ),
      ),
    );
  }

  Widget _buildSectionCard({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8EAEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildStatusMetric({required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Status',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTokenCard({
    required String token,
    String? deliveryEmail,
    String? deliveryMessage,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F8F43), Color(0xFF00CA44)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Electricity Token',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.88),
            ),
          ),
          const SizedBox(height: 12),
          SelectableText(
            _formatReceiptToken(token),
            style: const TextStyle(
              fontSize: 24,
              height: 1.35,
              letterSpacing: 1.1,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          if ((deliveryEmail != null && deliveryEmail.isNotEmpty) ||
              (deliveryMessage != null && deliveryMessage.isNotEmpty)) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (deliveryEmail != null && deliveryEmail.isNotEmpty) ...[
                    Text(
                      'Delivery Email',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.84),
                      ),
                    ),
                    const SizedBox(height: 6),
                    SelectableText(
                      deliveryEmail,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                  if (deliveryMessage != null && deliveryMessage.isNotEmpty) ...[
                    if (deliveryEmail != null && deliveryEmail.isNotEmpty)
                      const SizedBox(height: 12),
                    Text(
                      deliveryMessage,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.45,
                        color: Colors.white.withValues(alpha: 0.94),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        SelectableText(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            height: 1.4,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

}

/// Receipt content for full-screen page (same layout as bottom sheet body).
class TransactionReceiptView extends StatefulWidget {
  const TransactionReceiptView({
    super.key,
    required this.data,
    required this.receiptCaptureKey,
    this.showSheetHandle = false,
  });

  final TransactionReceiptData data;
  final GlobalKey receiptCaptureKey;
  final bool showSheetHandle;

  @override
  State<TransactionReceiptView> createState() => _TransactionReceiptViewState();
}

class _TransactionReceiptViewState extends State<TransactionReceiptView> {
  bool _requeryLoading = false;

  TransactionReceiptData get data => widget.data;

  Future<void> _requeryProvider() async {
    final token = await AuthTokenStorage.readJwt();
    if (token == null || token.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in again to requery this order.')),
      );
      return;
    }

    setState(() => _requeryLoading = true);
    try {
      final res = await queryTransaction(
        token,
        orderId: data.providerOrderId,
        requestId: data.clubkonnectRequestId ?? data.reference,
        walletReference: data.reference,
      );
      if (!mounted) return;
      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Provider query sent. Pull to refresh History in a moment.'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['error']?.toString() ?? 'Could not requery order.')),
        );
      }
    } finally {
      if (mounted) setState(() => _requeryLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;
    final tokenField = _findField('Token');
    final deliveryField = _findField('Delivery Receipt');
    final deliveryEmailField =
        tokenField != null ? _findField('Delivery Email') : null;
    final detailFields = data.extraDetails.where((field) {
      if (field.label == 'Token' || field.label == 'Delivery Receipt') {
        return false;
      }
      if (tokenField != null && field.label == 'Delivery Email') {
        return false;
      }
      return true;
    }).toList();

    return RepaintBoundary(
      key: widget.receiptCaptureKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.showSheetHandle) ...[
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ],
          if (data.outcome != null &&
              (data.outcomeMessage != null && data.outcomeMessage!.trim().isNotEmpty)) ...[
            _OutcomeBanner(outcome: data.outcome!, message: data.outcomeMessage!),
            const SizedBox(height: 14),
          ],
          Center(
            child: Container(
              padding: EdgeInsets.all(isTablet ? 20 : 16),
              decoration: BoxDecoration(
                color: GoPaynaColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                data.icon,
                color: GoPaynaColors.primary,
                size: isTablet ? 36 : 32,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Transaction Receipt',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isTablet ? 22 : 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: isTablet ? 15 : 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 20),
          _ReceiptSectionTitle(title: 'Transaction Status'),
          const SizedBox(height: 10),
          _ReceiptSectionCard(
            children: [
              Row(
                children: [
                  Expanded(child: _ReceiptStatusMetric(label: 'Amount', value: data.amountDisplay)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ReceiptStatusChip(data.statusLabel, data.statusColor),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _ReceiptDetailItem(label: 'Date', value: data.dateLabel),
              const SizedBox(height: 12),
              _ReceiptDetailItem(label: 'Channel', value: data.channelDisplay),
              const SizedBox(height: 12),
              _ReceiptDetailItem(label: 'Reference', value: data.referenceDisplay),
            ],
          ),
          if (tokenField != null) ...[
            const SizedBox(height: 18),
            _ReceiptSectionTitle(title: 'Token'),
            const SizedBox(height: 10),
            _ReceiptTokenCard(
              token: tokenField.value,
              deliveryEmail: deliveryEmailField?.value,
              deliveryMessage: deliveryField?.value,
            ),
          ],
          if (detailFields.isNotEmpty) ...[
            const SizedBox(height: 18),
            _ReceiptSectionTitle(title: 'Details'),
            const SizedBox(height: 10),
            _ReceiptSectionCard(
              children: [
                for (var index = 0; index < detailFields.length; index++) ...[
                  _ReceiptDetailItem(
                    label: detailFields[index].label,
                    value: detailFields[index].label.toLowerCase() == 'token'
                        ? _formatReceiptToken(detailFields[index].value)
                        : detailFields[index].value,
                  ),
                  if (index != detailFields.length - 1) const SizedBox(height: 12),
                ],
                if (tokenField == null && deliveryField != null) ...[
                  if (detailFields.isNotEmpty) const SizedBox(height: 12),
                  _ReceiptDetailItem(label: deliveryField.label, value: deliveryField.value),
                ],
              ],
            ),
          ],
          if (data.showProviderRequery) ...[
            const SizedBox(height: 14),
            Text(
              GoPaynaStrings.receiptRequeryHint,
              style: TextStyle(fontSize: 13, height: 1.45, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _requeryLoading ? null : _requeryProvider,
              icon: _requeryLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.sync_alt_rounded),
              label: Text(
                _requeryLoading ? 'Querying…' : GoPaynaStrings.receiptRequeryButton,
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF00CA44)),
                foregroundColor: const Color(0xFF00CA44),
              ),
            ),
          ],
        ],
      ),
    );
  }

  ReceiptField? _findField(String label) {
    for (final field in data.extraDetails) {
      if (field.label == label) return field;
    }
    return null;
  }
}

class _ReceiptSectionTitle extends StatelessWidget {
  const _ReceiptSectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
        color: Colors.grey.shade700,
      ),
    );
  }
}

class _ReceiptSectionCard extends StatelessWidget {
  const _ReceiptSectionCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8EAEE)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }
}

class _ReceiptStatusMetric extends StatelessWidget {
  const _ReceiptStatusMetric({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
          const SizedBox(height: 8),
          Text(value,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black87)),
        ],
      ),
    );
  }
}

class _ReceiptStatusChip extends StatelessWidget {
  const _ReceiptStatusChip(this.value, this.color);
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Status',
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}

class _ReceiptDetailItem extends StatelessWidget {
  const _ReceiptDetailItem({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
        const SizedBox(height: 4),
        SelectableText(value,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, height: 1.4, color: Colors.black87)),
      ],
    );
  }
}

class _ReceiptTokenCard extends StatelessWidget {
  const _ReceiptTokenCard({
    required this.token,
    this.deliveryEmail,
    this.deliveryMessage,
  });

  final String token;
  final String? deliveryEmail;
  final String? deliveryMessage;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F8F43), Color(0xFF00CA44)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Electricity Token',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.88))),
          const SizedBox(height: 12),
          SelectableText(
            _formatReceiptToken(token),
            style: const TextStyle(
              fontSize: 24,
              height: 1.35,
              letterSpacing: 1.1,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          if (deliveryEmail != null && deliveryEmail!.isNotEmpty) ...[
            const SizedBox(height: 12),
            SelectableText(deliveryEmail!,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
          ],
        ],
      ),
    );
  }
}

class _OutcomeBanner extends StatelessWidget {
  const _OutcomeBanner({required this.outcome, required this.message});

  final ReceiptOutcome outcome;
  final String message;

  @override
  Widget build(BuildContext context) {
    late Color bg;
    late Color border;
    late Color fg;
    late IconData icon;
    switch (outcome) {
      case ReceiptOutcome.pending:
        bg = GoPaynaColors.statusPending.withValues(alpha: 0.1);
        border = GoPaynaColors.statusPending.withValues(alpha: 0.35);
        fg = const Color(0xFF8A5300);
        icon = Icons.schedule_rounded;
        break;
      case ReceiptOutcome.success:
        bg = GoPaynaColors.statusSuccess.withValues(alpha: 0.1);
        border = GoPaynaColors.statusSuccess.withValues(alpha: 0.35);
        fg = GoPaynaColors.primaryDark;
        icon = Icons.check_circle_outline_rounded;
        break;
      case ReceiptOutcome.failed:
        bg = GoPaynaColors.statusFailed.withValues(alpha: 0.08);
        border = GoPaynaColors.statusFailed.withValues(alpha: 0.3);
        fg = GoPaynaColors.statusFailed;
        icon = Icons.error_outline_rounded;
        break;
      case ReceiptOutcome.refunded:
        bg = GoPaynaColors.statusRefunded.withValues(alpha: 0.1);
        border = GoPaynaColors.statusRefunded.withValues(alpha: 0.3);
        fg = GoPaynaColors.statusRefunded;
        icon = Icons.currency_exchange_rounded;
        break;
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: fg, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13,
                height: 1.45,
                fontWeight: FontWeight.w600,
                color: fg,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


