import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:taxi_app/bloc/driver/payout_history/payout_history_cubit.dart';
import 'package:taxi_app/bloc/driver/payout_history/payout_history_states.dart';

import 'package:taxi_app/common/extensions.dart';
import 'package:taxi_app/common/text_style.dart';
import 'package:taxi_app/data_models/payout_request.dart';
import 'package:taxi_app/view/driver%20home/drawer_screens/payout_details_screen.dart';

class PayoutHistoryScreen extends StatelessWidget {
  const PayoutHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text("Error: Not logged in.")));
    }

    return BlocProvider(
      create: (_) => PayoutHistoryCubit()..fetchHistory(user.uid),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            onPressed: context.pop,
            icon: Icon(Icons.arrow_back_ios, color: KColor.primaryText),
          ),
        ),
        backgroundColor: KColor.bg,
        body: BlocBuilder<PayoutHistoryCubit, PayoutHistoryState>(
          builder: (context, state) {
            if (state is PayoutHistoryLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is PayoutHistoryLoaded) {
              final payouts = state.payouts;
              if (payouts.isEmpty) {
                return const Center(child: Text("You have no payouts yet."));
              }
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 22.h),
                    Text(
                      "Payout History",
                      style: appStyle(
                        size: 25.sp,
                        color: KColor.primaryText,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 30.h),
                    Expanded(
                      child: ListView.builder(
                        padding: EdgeInsets.symmetric(vertical: 8.h),
                        itemCount: payouts.length,
                        itemBuilder: (context, index) {
                          final p = payouts[index];
                          return _buildPayoutCard(context, p);
                        },
                      ),
                    ),
                  ],
                ),
              );
            }
            if (state is PayoutHistoryError) {
              print(state.message);
              return Center(child: Text(state.message));
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildPayoutCard(BuildContext context, PayoutRequest p) {
    final amount = (p.amountCents / 100).toStringAsFixed(2);
    final curr = p.currency.toUpperCase();
    final created =
        DateFormat('MMM d, yyyy - hh:mm a').format(p.createdAt.toDate());

    // Color by status
    Color amountColor;
    switch (p.status.toLowerCase()) {
      case 'paid':
      case 'approved':
        amountColor = Colors.green;
        break;
      case 'pending':
        amountColor = Colors.orange;
        break;
      case 'rejected':
      case 'failed':
        amountColor = Colors.red;
        break;
      default:
        amountColor = KColor.primaryText;
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => PayoutDetailsScreen(req: p)),
          );
        },
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Row(
            children: [
              Icon(Icons.account_balance_wallet_outlined,
                  color: KColor.primary, size: 30.sp),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Payout • ${_pretty(p.status)}',
                      style: appStyle(
                        size: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: KColor.primaryText,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      created,
                      style: appStyle(
                        size: 12.sp,
                        color: KColor.secondaryText,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 16.w),
              Text(
                "$curr $amount",
                style: appStyle(
                  size: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: amountColor,
                ),
              ),
            ],
          ),
        ),
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
}
