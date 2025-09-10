import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:taxi_app/bloc/driver/home/driver_home_states.dart';
import 'package:taxi_app/common/extensions.dart';

import 'package:taxi_app/common/text_style.dart';
import 'package:taxi_app/common_widgets/rounded_button.dart';

Widget buildArrivedAtDestinationPanel(
    BuildContext context, DriverArrivedAtDestination state) {
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
            Text("You have arrived.",
                style: appStyle(
                    size: 20.sp,
                    color: KColor.primaryText,
                    fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text("Wait for customer to pay.",
                style: appStyle(
                    size: 16.sp,
                    color: KColor.placeholder,
                    fontWeight: FontWeight.bold)),
            SizedBox(height: 16.h),
            LinearProgressIndicator(
              minHeight: 5.h,
              color: KColor.primary,
              borderRadius: BorderRadius.circular(30.r),
            ),
            Divider(height: 40.h),
            RoundButton(
              title: "Report a problem",
              onPressed: () {
                // TODO: Handle report logic
              },
              color: KColor.red,
            ),
          ],
        ),
      ),
    ),
  );
}
