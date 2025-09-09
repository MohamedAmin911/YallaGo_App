import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:taxi_app/bloc/driver/driver_cubit.dart';
import 'package:taxi_app/bloc/driver/driver_states.dart';
import 'package:taxi_app/common/extensions.dart';
import 'package:taxi_app/common/text_style.dart';
import 'package:taxi_app/data_models/driver_model.dart';
import 'package:taxi_app/view/driver%20home/drawer_screens/payout_history_screen.dart';
import 'package:taxi_app/view/driver%20home/drawer_screens/ride_history_screen.dart';

class DriverProfileScreen extends StatelessWidget {
  const DriverProfileScreen({super.key});

  // Adjust these for your app
  static const String payoutCurrency = 'egp'; // or 'usd'
  static const int minThresholdCents = 5000; // e.g., 50.00 EGP/USD

  @override
  Widget build(BuildContext context) {
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
      body: BlocConsumer<DriverCubit, DriverState>(
        listener: (context, state) {
          if (state is DriverError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(state.message), backgroundColor: Colors.red),
            );
          } else if (state is DriverLoaded) {
            // optional success message after a payout request
            // ScaffoldMessenger.of(context).showSnackBar(
            //   const SnackBar(content: Text('Updated.')),
            // );
          }
        },
        builder: (context, state) {
          if (state is! DriverLoaded) {
            return Center(
                child: CircularProgressIndicator(color: KColor.primary));
          }
          final driver = state.driver;

          return ListView(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            children: [
              SizedBox(height: 22.h),
              Text(
                "My Profile",
                style: appStyle(
                  size: 25.sp,
                  color: KColor.primaryText,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 30.h),
              _buildProfileHeader(driver),
              SizedBox(height: 10.h),
              Text(
                driver.email ?? "",
                style: appStyle(
                    size: 15.sp,
                    color: KColor.lightGray,
                    fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 30.h),
              _buildStatsRow(driver),
              const Divider(height: 40),
              _buildSectionTitle("My Vehicle"),
              SizedBox(height: 16.h),
              _buildVehicleInfoCard(driver),
              const Divider(height: 40),
              _buildSectionTitle("Account"),
              SizedBox(height: 8.h),

              // Ride history
              _buildActionTile(
                icon: Icons.history,
                title: "Ride History",
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const RideHistoryScreen()),
                  );
                },
              ),

              // Request Payout (NEW)
              _buildActionTile(
                icon: Icons.payments_outlined,
                title: "Request Payout",
                onTap: () => _openPayoutSheet(context, driver),
              ),

              // Payouts list/history (you can implement later)
              _buildActionTile(
                icon: Icons.account_balance_wallet,
                title: "Payout History",
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const PayoutHistoryScreen()),
                  );
                },
              ),

              _buildActionTile(
                icon: Icons.support_agent,
                title: "Support",
                onTap: () {
                  // TODO: Navigate to Support Screen
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(DriverModel driver) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: KColor.primary,
            borderRadius: BorderRadius.circular(30.r),
          ),
          child: driver.profileImageUrl != null
              ? Material(
                  elevation: 5,
                  borderRadius: BorderRadius.circular(30.r),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30.r),
                    child: Image.network(
                      driver.profileImageUrl!,
                      width: 300.w,
                      height: 300.h,
                      fit: BoxFit.fitWidth,
                    ),
                  ),
                )
              : null,
        ),
        SizedBox(height: 20.h),
        RatingBarIndicator(
          rating: driver.rating,
          itemBuilder: (context, index) => const Icon(
            Icons.star_rate_rounded,
            color: Colors.amber,
          ),
          itemCount: 5,
          itemSize: 40.sp,
          unratedColor: KColor.placeholder.withOpacity(0.5),
          direction: Axis.horizontal,
        ),
      ],
    );
  }

  Widget _buildStatsRow(DriverModel driver) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatItem("Balance", "EGP ${driver.balance.toStringAsFixed(2)}"),
        _buildStatItem("Total Rides", driver.totalRides.toString()),
        _buildStatItem(
          "Status",
          driver.isOnline ? "Online" : "Offline",
          valueColor: driver.isOnline ? Colors.green : Colors.red,
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, {Color? valueColor}) {
    return Column(
      children: [
        Text(
          label,
          style: appStyle(
            size: 14.sp,
            color: KColor.secondaryText,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          value,
          style: appStyle(
            size: 18.sp,
            fontWeight: FontWeight.bold,
            color: valueColor ?? KColor.primaryText,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: appStyle(
        size: 18.sp,
        fontWeight: FontWeight.w800,
        color: KColor.placeholder,
      ),
    );
  }

  Widget _buildVehicleInfoCard(DriverModel driver) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8.r),
              child: driver.carImageUrl != null
                  ? Image.network(
                      driver.carImageUrl!,
                      width: 140.w,
                      height: 140.h,
                      fit: BoxFit.fitWidth,
                    )
                  : Container(
                      width: 100.w,
                      height: 80.h,
                      color: Colors.grey[200],
                      child: Icon(Icons.directions_car, size: 40.r),
                    ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    driver.carModel,
                    maxLines: 2,
                    style: appStyle(
                      size: 20.sp,
                      fontWeight: FontWeight.w900,
                      color: KColor.primaryText,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    driver.licensePlate,
                    style: appStyle(
                      size: 20.sp,
                      color: KColor.secondaryText,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Container(
                    width: 50.w,
                    height: 10.h,
                    decoration: BoxDecoration(
                      color: Color(
                        int.parse(
                            "0xff${driver.carColor.replaceFirst('#', '')}"),
                      ),
                      borderRadius: BorderRadius.circular(22.r),
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: KColor.primary),
      title: Text(
        title,
        style: appStyle(
            size: 16.sp,
            color: KColor.primaryText,
            fontWeight: FontWeight.bold),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  // NEW: Request Payout UI
  void _openPayoutSheet(BuildContext context, DriverModel driver) {
    if ((driver.stripeConnectAccountId ?? '').isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please connect your Stripe payout account first.')),
      );
      return;
    }

    final amountCtrl = TextEditingController(
      text: driver.balance.toStringAsFixed(2), // default to full balance
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16.r))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16.w,
            right: 16.w,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16.h,
            top: 16.h,
          ),
          child: BlocBuilder<DriverCubit, DriverState>(
            builder: (context, state) {
              final loading = state is DriverLoading;
              final minThreshold = (minThresholdCents / 100.0);
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40.w,
                      height: 4.h,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text('Request Payout',
                      style: appStyle(
                          size: 18.sp,
                          fontWeight: FontWeight.w800,
                          color: KColor.primaryText)),
                  SizedBox(height: 12.h),
                  Text(
                    'Available balance: ${payoutCurrency.toUpperCase()} ${driver.balance.toStringAsFixed(2)}\n'
                    'Minimum payout: ${payoutCurrency.toUpperCase()} ${minThreshold.toStringAsFixed(2)}',
                    style: appStyle(
                        size: 14.sp,
                        color: KColor.secondaryText,
                        fontWeight: FontWeight.w500),
                  ),
                  SizedBox(height: 12.h),
                  TextField(
                    controller: amountCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Amount (${payoutCurrency.toUpperCase()})',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r)),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: loading ? null : () => Navigator.pop(ctx),
                          child: const Text('Cancel'),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: loading
                              ? null
                              : () async {
                                  final txt = amountCtrl.text.trim();
                                  final amt = double.tryParse(txt) ?? 0.0;
                                  final amtCents = (amt * 100).round();
                                  final balanceCents =
                                      (driver.balance * 100).round();

                                  if (amt <= 0) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content:
                                              Text('Enter a valid amount.')),
                                    );
                                    return;
                                  }
                                  if (amtCents < minThresholdCents) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            'Minimum payout is ${payoutCurrency.toUpperCase()} ${minThreshold.toStringAsFixed(2)}'),
                                      ),
                                    );
                                    return;
                                  }
                                  if (amtCents > balanceCents) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Amount exceeds available balance.')),
                                    );
                                    return;
                                  }

                                  // Call cubit
                                  await context
                                      .read<DriverCubit>()
                                      .requestPayout(
                                        driverUid: driver
                                            .uid, // if your model uses id, replace with driver.id
                                        amountCents: amtCents,
                                        currency: payoutCurrency,
                                        minThresholdCents: minThresholdCents,
                                      );

                                  if (context.mounted) {
                                    Navigator.pop(ctx);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Payout request submitted.')),
                                    );
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                              backgroundColor: KColor.primary),
                          child: loading
                              ? SizedBox(
                                  height: 18.h,
                                  width: 18.h,
                                  child: const CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : const Text('Request'),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
