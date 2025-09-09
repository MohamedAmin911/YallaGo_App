import 'package:cloud_firestore/cloud_firestore.dart';

class PayoutRequest {
  final String id;
  final String driverUid;
  final String? driverName;
  final String driverStripeAccountId;
  final int amountCents;
  final String currency; // e.g., 'usd' or 'egp' (display only)
  final String status; // pending | approved | paid | rejected | failed
  final Timestamp createdAt;
  final Timestamp? approvedAt;
  final Timestamp? processedAt;
  final String? approvedBy;
  final String? transferId;
  final String? payoutId;
  final int? balanceSnapshotCents;
  final int? feeCents;
  final String? failureReason;
  final String? note;

  PayoutRequest({
    required this.id,
    required this.driverUid,
    required this.driverStripeAccountId,
    required this.amountCents,
    required this.currency,
    required this.status,
    required this.createdAt,
    this.driverName,
    this.approvedAt,
    this.processedAt,
    this.approvedBy,
    this.transferId,
    this.payoutId,
    this.balanceSnapshotCents,
    this.feeCents,
    this.failureReason,
    this.note,
  });

  factory PayoutRequest.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return PayoutRequest(
      id: doc.id,
      driverUid: (d['driverUid'] ?? '') as String,
      driverName: d['driverName'] as String?,
      driverStripeAccountId: (d['driverStripeAccountId'] ?? '') as String,
      amountCents: (d['amountCents'] ?? 0) as int,
      currency: (d['currency'] ?? 'usd') as String,
      status: (d['status'] ?? 'pending') as String,
      createdAt: (d['createdAt'] ?? Timestamp.now()) as Timestamp,
      approvedAt: d['approvedAt'] as Timestamp?,
      processedAt: d['processedAt'] as Timestamp?,
      approvedBy: d['approvedBy'] as String?,
      transferId: d['transferId'] as String?,
      payoutId: d['payoutId'] as String?,
      balanceSnapshotCents: d['balanceSnapshotCents'] as int?,
      feeCents: d['feeCents'] as int?,
      failureReason: d['failureReason'] as String?,
      note: d['note'] as String?,
    );
  }
}
