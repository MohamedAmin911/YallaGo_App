import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:taxi_app/bloc/driver/home/driver_home_cubit.dart';
import 'package:taxi_app/common/extensions.dart' show KColor;
import 'package:taxi_app/common/text_style.dart';
import 'package:taxi_app/common_widgets/rounded_button.dart';
import 'package:taxi_app/data_models/trip_model.dart';
import 'package:taxi_app/UI/driver%20home/widgets/home/location_field.dart';

Widget newRideFields(String text, String fieldName, Color color) {
  return Container(
    padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 3.h),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20.r),
      border: Border.all(color: color, width: 2.w),
    ),
    child: Row(
      children: [
        Container(
            width: 70.w,
            height: 50.h,
            padding: EdgeInsets.symmetric(vertical: 10.h),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(15.r),
            ),
            child: Center(
              child: Text(
                fieldName,
                style: appStyle(
                    size: 18.sp, color: KColor.bg, fontWeight: FontWeight.bold),
              ),
            )),
        Expanded(child: buildLocationField(text: text, onTap: () {}))
      ],
    ),
  );
}

void showRideRequestDialog(BuildContext context, TripModel trip) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.r)),
        title: Text(
          "New Ride Request",
          style: appStyle(
              size: 20.sp, color: KColor.primary, fontWeight: FontWeight.bold),
        ),
        content: IntrinsicHeight(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              newRideFields(trip.pickupAddress, "From", KColor.primary),
              SizedBox(height: 8.h),
              newRideFields(trip.destinationAddress, "To", KColor.primary),
              SizedBox(height: 8.h),
              newRideFields("${trip.estimatedFare.toStringAsFixed(2)} EGP",
                  "Fare", Colors.green),
              SizedBox(height: 20.h),
              const Divider(),
            ],
          ),
        ),
        actions: [
          Column(
            children: [
              RoundButton(
                title: "ACCEPT",
                onPressed: () {
                  context.read<DriverHomeCubit>().acceptTrip(trip);
                  Navigator.of(dialogContext).pop();
                },
                color: KColor.primary,
              ),
              SizedBox(height: 10.h),
              RoundButton(
                title: "DECLINE",
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  context.read<DriverHomeCubit>().goOnline();
                },
                color: KColor.red,
              ),
            ],
          )
        ],
      );
    },
  );
}
