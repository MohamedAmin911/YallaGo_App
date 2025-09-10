import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import 'package:taxi_app/common/extensions.dart';
import 'package:taxi_app/common/text_style.dart';
import 'package:taxi_app/data_models/payout_request.dart';

class PayoutDetailsScreen extends StatelessWidget {
  final PayoutRequest req;
  const PayoutDetailsScreen({super.key, required this.req});

  @override
  Widget build(BuildContext context) {
    final amount = (req.amountCents / 100).toStringAsFixed(2);
    final curr = req.currency.toUpperCase();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: context.pop,
          icon: Icon(
            Icons.arrow_back_ios,
            color: KColor.primaryText,
          ),
        ),
      ),
      backgroundColor: KColor.bg,
      body: ListView(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
        children: [
          SizedBox(height: 22.h),
          // title
          Text(
            "Payout Details",
            style: appStyle(
              size: 25.sp,
              color: KColor.primaryText,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 30.h),

          // Header (mirrors _buildCustomerHeader)
          _buildHeader(req),

          SizedBox(height: 24.h),

          // Info Card (mirrors _buildInfoCard)
          _buildInfoCard(
            children: [
              // Date
              _buildDetailRow(
                icon: Icons.calendar_today,
                title: "Date",
                value: DateFormat('MMM d, yyyy - hh:mm a')
                    .format(req.createdAt.toDate()),
              ),
              const Divider(),

              // Status
              _buildDetailRow(
                icon: Icons.verified_outlined,
                title: "Status",
                value: _pretty(req.status),
              ),
              const Divider(),

              // Transfer ID
              _buildDetailRow(
                icon: Icons.swap_horiz,
                title: "Transfer ID",
                value:
                    req.transferId?.isNotEmpty == true ? req.transferId! : '-',
              ),
              const Divider(),

              // Payout ID
              _buildDetailRow(
                icon: Icons.account_balance,
                title: "Payout ID",
                value: req.payoutId?.isNotEmpty == true ? req.payoutId! : '-',
              ),
              const Divider(),

              // Approved At
              _buildDetailRow(
                icon: Icons.schedule,
                title: "Approved At",
                value: req.approvedAt != null
                    ? DateFormat('MMM d, yyyy - hh:mm a')
                        .format(req.approvedAt!.toDate())
                    : '-',
              ),
              const Divider(),

              // Processed At
              _buildDetailRow(
                icon: Icons.done_all,
                title: "Processed At",
                value: req.processedAt != null
                    ? DateFormat('MMM d, yyyy - hh:mm a')
                        .format(req.processedAt!.toDate())
                    : '-',
              ),

              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: const Divider(),
              ),

              // Final Amount (mirrors “Final Fare” style)
              _buildDetailRow(
                icon: Icons.attach_money,
                title: "Final Amount",
                value: "$curr $amount",
                valueColor: Colors.green,
              ),

              // Optional: failure reason / note (kept inside the same card)
              if ((req.failureReason ?? '').isNotEmpty) ...[
                const Divider(),
                _buildDetailRow(
                  icon: Icons.error_outline,
                  title: "Failure Reason",
                  value: req.failureReason!,
                  valueColor: Colors.red,
                ),
              ],
              if ((req.note ?? '').isNotEmpty) ...[
                const Divider(),
                _buildDetailRow(
                  icon: Icons.note_outlined,
                  title: "Note",
                  value: req.note!,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(PayoutRequest req) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar-style box (like customer image in trip screen)
        ClipRRect(
          borderRadius: BorderRadius.circular(8.r),
          child: Container(
            width: 100.w,
            height: 100.h,
            color: Colors.grey[200],
            child: Icon(Icons.account_balance_wallet_outlined, size: 40.r),
          ),
        ),
        SizedBox(width: 16.w),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Paid to",
              style: appStyle(
                size: 14.sp,
                color: KColor.secondaryText,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              _shortAcct(req.driverStripeAccountId),
              style: appStyle(
                size: 20.sp,
                fontWeight: FontWeight.bold,
                color: KColor.primaryText,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoCard({required List<Widget> children}) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String title,
    required String value,
    Color? valueColor,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: KColor.primary, size: 20.sp),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: appStyle(
                    size: 12.sp,
                    color: KColor.secondaryText,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  value,
                  style: appStyle(
                    size: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: valueColor ?? KColor.primaryText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _pretty(String s) {
    final l = s.toLowerCase();
    if (l == 'pending') return 'Pending';
    if (l == 'approved') return 'Approved';
    if (l == 'paid') return 'Paid';
    if (l == 'rejected') return 'Rejected';
    if (l == 'failed') return 'Failed';
    return l.isEmpty ? '-' : l[0].toUpperCase() + l.substring(1);
  }

  String _shortAcct(String acct) {
    if (acct.isEmpty) return 'Stripe Account';
    if (acct.length <= 10) return acct;
    // show head/tail like acct_1Rz...T0rK
    final head = acct.substring(0, 6);
    final tail = acct.substring(acct.length - 4);
    return '$head…$tail';
  }
}
