import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:taxi_app/bloc/customer/home/customer_home_cubit.dart';

import 'package:taxi_app/bloc/customer/home/customer_home_states.dart';
import 'package:taxi_app/bloc/customer/customer_cubit.dart';
import 'package:taxi_app/bloc/driver/driver_cubit.dart';
import 'package:taxi_app/bloc/payment/payment_method_cubit.dart';
import 'package:taxi_app/bloc/trip/trip_cubit.dart';
import 'package:taxi_app/common/extensions.dart';
import 'package:taxi_app/common/text_style.dart';
import 'package:taxi_app/common_widgets/rounded_button.dart';

typedef OnRatingChanged = void Function(double rating);

Widget buildTripCompletedPanel(
  BuildContext context,
  HomeTripCompleted state,
  double currentRating,
  OnRatingChanged onRatingChanged,
) {
  return Positioned(
    left: 0,
    right: 0,
    bottom: 0,
    child: Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.r)),
      margin: const EdgeInsets.all(20),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text("You have arrived!",
                style: appStyle(
                    size: 20.sp,
                    color: KColor.primaryText,
                    fontWeight: FontWeight.bold)),
            SizedBox(height: 16.h),
            Text("Please rate your driver.",
                style: appStyle(
                    fontWeight: FontWeight.w600,
                    size: 14.sp,
                    color: KColor.secondaryText)),
            SizedBox(height: 8.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  icon: index < currentRating
                      ? Icon(
                          Icons.star_rate_rounded,
                          color: Colors.amber,
                          size: 35.sp,
                        )
                      : Icon(
                          Icons.star_rate_rounded,
                          color: KColor.lightGray,
                          size: 35.sp,
                        ),
                  onPressed: () {
                    onRatingChanged(index + 1.0);
                  },
                );
              }),
            ),
            Divider(height: 24.h),
            Container(
              padding: EdgeInsets.only(right: 2.w),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30.r),
                border: Border.all(color: Colors.green, width: 2.w),
              ),
              child: Row(
                children: [
                  Text("  EGP  ",
                      style: appStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w900,
                          size: 20.sp)),
                  Text(state.trip.estimatedFare.toStringAsFixed(2),
                      style: appStyle(
                          color: KColor.primaryText,
                          fontWeight: FontWeight.w600,
                          size: 20.sp)),
                  SizedBox(width: 20.w),
                  Expanded(
                    child: RoundButton(
                        title: "PAY",
                        onPressed: () {
                          final tripCubit = context.read<TripCubit>();
                          final driverCubit = context.read<DriverCubit>();
                          final customerCubit = context.read<CustomerCubit>();
                          final paymentCubit = context.read<PaymentCubit>();
                          tripCubit.processTripPayment(
                            paymentCubit: paymentCubit,
                            trip: state.trip,
                            driverCubit: driverCubit,
                            customerCubit: customerCubit,
                            rating: currentRating,
                          );

                          context.read<HomeCubit>().loadCurrentUserLocation();
                        },
                        color: Colors.green),
                  ),
                ],
              ),
            ),
            Divider(height: 24.h),
            RoundButton(
                title: "Report a problem", onPressed: () {}, color: KColor.red)
          ],
        ),
      ),
    ),
  );
}
