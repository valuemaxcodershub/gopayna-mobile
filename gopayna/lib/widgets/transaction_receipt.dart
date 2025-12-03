import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

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
      buffer.writeln('${field.label}: ${field.value}');
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

class _TransactionReceiptSheet extends StatelessWidget {
  const _TransactionReceiptSheet({required this.data});

  final TransactionReceiptData data;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomInset = mediaQuery.viewInsets.bottom;
    final isTablet = mediaQuery.size.width > 600;

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
              Container(
                padding: EdgeInsets.all(isTablet ? 20 : 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF00CA44).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  data.icon,
                  color: const Color(0xFF00CA44),
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
              SizedBox(height: isTablet ? 20 : 16),
              _buildDetailRow('Type', data.title),
              _buildDetailRow('Amount', data.amountDisplay),
              _buildDetailRow('Status', data.statusLabel, valueColor: data.statusColor),
              _buildDetailRow('Date', data.dateLabel),
              _buildDetailRow('Channel', data.channelDisplay),
              _buildDetailRow('Reference', data.referenceDisplay),
              for (final field in data.extraDetails)
                _buildDetailRow(field.label, field.value),
              SizedBox(height: isTablet ? 28 : 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _shareReceipt(data),
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
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: valueColor ?? Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _shareReceipt(TransactionReceiptData data) async {
    await Share.share(data.buildShareMessage(), subject: 'GoPayna Receipt');
  }
}


