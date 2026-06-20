import 'package:intl/intl.dart';

import '../all_transactions_history.dart';
import 'transaction_receipt.dart';

/// Builds receipt UI data from a wallet transaction API row.
TransactionReceiptData receiptDataFromWalletRow(Map<String, dynamic> row) {
  final formatter = DateFormat('MMM d, yyyy • h:mma');
  final item = WalletTransactionItem.fromMap(row, formatter);
  final base = item.toReceiptData();

  final metadata = item.metadata ?? {};
  final serviceType = (metadata['serviceType'] ?? '').toString().toLowerCase();
  final meterType = (metadata['meterType'] ?? '01').toString();
  final sk = item.statusKey;
  final showProviderRequery = (sk == 'pending' || sk == 'processing') &&
      serviceType == 'electricity' &&
      meterType == '01';
  final providerOrderId = metadata['orderId']?.toString() ??
      metadata['providerOrderId']?.toString() ??
      metadata['nellobyteOrderId']?.toString();
  final clubkonnectRequestId = metadata['clubkonnectRequestId']?.toString();

  return TransactionReceiptData(
    title: base.title,
    amountDisplay: base.amountDisplay,
    isCredit: base.isCredit,
    statusLabel: base.statusLabel,
    statusColor: base.statusColor,
    dateLabel: base.dateLabel,
    channel: base.channel,
    reference: base.reference,
    icon: base.icon,
    extraDetails: base.extraDetails,
    outcome: base.outcome,
    outcomeMessage: base.outcomeMessage,
    showProviderRequery: showProviderRequery,
    providerOrderId: providerOrderId,
    clubkonnectRequestId:
        clubkonnectRequestId?.isNotEmpty == true ? clubkonnectRequestId : base.reference,
  );
}
