import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:taxi_app/bloc/auth/auth_cubit.dart';
import 'package:taxi_app/bloc/customer/home/customer_home_states.dart';
import 'package:taxi_app/common/extensions.dart';
import 'package:taxi_app/common/text_style.dart';
import 'package:taxi_app/common_widgets/rounded_button.dart';
import 'package:taxi_app/data_models/driver_model.dart';
import 'package:taxi_app/view/widgets/chat_bottom_sheet.dart';

Widget buildDriverArrivedPanel(BuildContext context, DriverModel driver,
    String tripId, HomeDriverArrived state) {
  return Positioned(
    left: 0,
    right: 0,
    bottom: 0,
    child: Card(
      elevation: 3,
      margin: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.r)),
      color: KColor.bg,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 40),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Your driver has arrived!",
                          style: appStyle(
                              color: KColor.primaryText,
                              fontWeight: FontWeight.bold,
                              size: 18.sp)),
                      Text(
                        "Meet ${driver.fullName} outside.",
                        style: appStyle(
                            color: KColor.placeholder,
                            fontWeight: FontWeight.w500,
                            size: 14.sp),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.h),
            Badge(
              isLabelVisible: state.unreadMessageCount > 0,
              label: Text(state.unreadMessageCount.toString()),
              child: RoundButton(
                  title: "CHAT",
                  onPressed: () {
                    showModalBottomSheet(
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.r)),
                      context: context,
                      isScrollControlled: true,
                      builder: (sheetContext) {
                        return BlocProvider.value(
                          value: BlocProvider.of<AuthCubit>(context),
                          child: ChatBottomSheet(tripId: tripId),
                        );
                      },
                    );
                  },
                  color: KColor.primary),
            ),
          ],
        ),
      ),
    ),
  );
}
