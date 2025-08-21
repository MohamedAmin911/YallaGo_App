import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:taxi_app/bloc/customer/home/customer_home_states.dart';
import 'package:taxi_app/common/extensions.dart';
import 'package:taxi_app/common/text_style.dart';
import 'location_field.dart';

Widget buildTripInProgressPanel(
    BuildContext context, HomeTripInProgress state) {
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
            Text("Your trip is in progress",
                style: appStyle(
                    size: 18.sp,
                    color: KColor.primaryText,
                    fontWeight: FontWeight.bold)),
            SizedBox(height: 20.h),
            Row(
              children: [
                Icon(
                  Icons.place_rounded,
                  color: KColor.primary,
                  size: 40.sp,
                ),
                Expanded(
                  child: buildLocationField(
                    text: state.trip.destinationAddress,
                    onTap: () {},
                  ),
                ),
              ],
            ),
            SizedBox(height: 15.h),
            LinearProgressIndicator(
              minHeight: 5.h,
              color: KColor.primary,
              borderRadius: BorderRadius.circular(30.r),
            ),
            SizedBox(height: 15.h),
            Text("Estimated Arrival: ${state.arrivalEta}"),
          ],
        ),
      ),
    ),
  );
}
