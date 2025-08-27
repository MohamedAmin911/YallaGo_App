import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:taxi_app/bloc/driver/driver_cubit.dart';
import 'package:taxi_app/bloc/driver/driver_states.dart';
import 'package:taxi_app/common/extensions.dart';
import 'package:taxi_app/common/text_style.dart';
import 'package:taxi_app/data_models/driver_model.dart';
import 'package:taxi_app/view/driver%20home/drawer_screens/ride_history_screen.dart';

class DriverProfileScreen extends StatelessWidget {
  const DriverProfileScreen({super.key});

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
      body: BlocBuilder<DriverCubit, DriverState>(
        builder: (context, state) {
          if (state is! DriverLoaded) {
            // Show a loading indicator until the driver's data is available
            return Center(
                child: CircularProgressIndicator(color: KColor.primary));
          }
          final driver = state.driver;

          return ListView(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            children: [
              SizedBox(height: 22.h),
              //title
              Text(
                "My Profile",
                style: appStyle(
                  size: 25.sp,
                  color: KColor.primaryText,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 30.h),
              // --- Profile Header ---
              _buildProfileHeader(driver),
              SizedBox(height: 30.h),
              // --- Key Stats ---
              _buildStatsRow(driver),
              const Divider(height: 40),
              // --- Vehicle Information ---
              _buildSectionTitle("My Vehicle"),
              SizedBox(height: 16.h),
              _buildVehicleInfoCard(driver),
              const Divider(height: 40),
              // --- Action Buttons ---
              _buildSectionTitle("Account"),
              SizedBox(height: 8.h),
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
              _buildActionTile(
                icon: Icons.account_balance_wallet,
                title: "Payouts",
                onTap: () {
                  // TODO: Navigate to Payouts Screen
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
        // --- Profile Picture ---
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
        _buildStatItem("Status", driver.isOnline ? "Online" : "Offline",
            valueColor: driver.isOnline ? Colors.green : Colors.red),
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
              fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 4.h),
        Text(
          value,
          style: appStyle(
              size: 18.sp,
              fontWeight: FontWeight.bold,
              color: valueColor ?? KColor.primaryText),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: appStyle(
          size: 18.sp, fontWeight: FontWeight.w800, color: KColor.placeholder),
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
            // Car Image
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
            // Car Details
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
                        color: KColor.primaryText),
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    driver.licensePlate,
                    style: appStyle(
                        size: 20.sp,
                        color: KColor.secondaryText,
                        fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10.h),
                  Container(
                    width: 50.w,
                    height: 10.h,
                    decoration: BoxDecoration(
                      color: Color(int.parse(
                          "0xff${driver.carColor.replaceFirst('#', '')}")),
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
      title: Text(title,
          style: appStyle(
              size: 16.sp,
              color: KColor.primaryText,
              fontWeight: FontWeight.bold)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}
