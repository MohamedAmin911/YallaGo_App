import 'dart:io';

import 'package:taxi_app/common/extensions.dart';
import 'package:taxi_app/common/text_style.dart';
import 'package:taxi_app/view/driver%20home/driver_home_screen.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:taxi_app/bloc/auth/auth_cubit.dart';
import 'package:taxi_app/bloc/auth/auth_states.dart';
import 'package:taxi_app/bloc/driver/driver_cubit.dart';
import 'package:taxi_app/bloc/driver/driver_states.dart';
import 'package:taxi_app/common_widgets/rounded_button.dart';

class DriverPayoutScreen extends StatelessWidget {
  // Receives ALL data from the entire sign-up flow
  final String fullName;
  final String email;
  final File? profileImageFile;
  final String carModel;
  final String licensePlate;
  final String carColor;
  final File? carImageFile;
  final File nationalIdFile;
  final File driversLicenseFile;
  final File carLicenseFile;
  final File criminalRecordFile;

  const DriverPayoutScreen({
    super.key,
    required this.fullName,
    required this.email,
    this.profileImageFile,
    required this.carModel,
    required this.licensePlate,
    required this.carColor,
    this.carImageFile,
    required this.nationalIdFile,
    required this.driversLicenseFile,
    required this.carLicenseFile,
    required this.criminalRecordFile,
  });

  void _connectStripeAndFinish(BuildContext context) async {
    final driverCubit = context.read<DriverCubit>();
    final authState = context.read<AuthCubit>().state;

    if (authState is! AuthLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error: User not logged in.")),
      );
      return;
    }

    try {
      // This simulates the Stripe Connect onboarding and returns the account ID
      final stripeAccountId = await driverCubit.initiateStripeConnectOnboarding(
        email: email,
        phone: authState.user.phoneNumber ?? "",
      );

      // Now, call the final upload function with all the data
      await driverCubit.createDriverProfile(
        uid: authState.user.uid,
        phoneNumber: authState.user.phoneNumber ?? "N/A",
        fullName: fullName,
        email: email,
        profileImageFile: profileImageFile,
        carModel: carModel,
        licensePlate: licensePlate,
        carColor: carColor,
        carImageFile: carImageFile,
        nationalIdFile: nationalIdFile,
        driversLicenseFile: driversLicenseFile,
        carLicenseFile: carLicenseFile,
        criminalRecordFile: criminalRecordFile,
        stripeConnectAccountId: stripeAccountId ?? "",
      );
    } catch (e) {
      // The cubit will emit an error state which is handled by the listener
    }
  }

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
      body: BlocListener<DriverCubit, DriverState>(
        listener: (context, state) {
          if (state is DriverProfileCreated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Sign up completed.")),
            );
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const DriverHomeScreen()),
              (route) => false,
            );
          } else if (state is DriverError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 22.h),
              //title
              Text(
                "Add Payout Information",
                style: appStyle(
                  size: 25.sp,
                  color: KColor.primaryText,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 30.h),
              Center(
                child: Icon(Icons.account_balance_wallet_outlined,
                    size: 80.r, color: KColor.primary),
              ),
              SizedBox(height: 20.h),

              Text(
                "We partner with Stripe for secure financial services. Tap below to set up your payout account on Stripe's secure website.",
                textAlign: TextAlign.center,
                style: appStyle(
                    color: KColor.placeholder,
                    fontWeight: FontWeight.w500,
                    size: 16.sp),
              ),
              SizedBox(height: 40.h),
              BlocBuilder<DriverCubit, DriverState>(
                builder: (context, state) {
                  final isLoading = state is DriverLoading;
                  return isLoading
                      ? Center(
                          child:
                              CircularProgressIndicator(color: KColor.primary))
                      : RoundButton(
                          title: "Connect with Stripe",
                          color: KColor.primary,
                          onPressed: () => _connectStripeAndFinish(context),
                        );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
