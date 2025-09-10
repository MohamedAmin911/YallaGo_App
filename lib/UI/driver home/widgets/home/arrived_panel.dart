import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:taxi_app/UI/common%20widgets/chat_bottom_sheet.dart';

import 'package:taxi_app/bloc/auth/auth_cubit.dart';
import 'package:taxi_app/bloc/driver/home/driver_home_cubit.dart';
import 'package:taxi_app/bloc/driver/home/driver_home_states.dart';
import 'package:taxi_app/common/extensions.dart';
import 'package:taxi_app/common/text_style.dart';
import 'package:taxi_app/common_widgets/rounded_button.dart';

Widget buildArrivedPanel(BuildContext context, DriverArrivedAtPickup state) {
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
            Text("Wait for customer to get in the car.",
                style: appStyle(
                    size: 15.sp,
                    color: KColor.placeholder,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Badge(
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
                              child: ChatBottomSheet(
                                  tripId: state.acceptedTrip.tripId ?? ""),
                            );
                          },
                        );
                      },
                      color: KColor.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: RoundButton(
                    title: "START TRIP",
                    onPressed: () {
                      context.read<DriverHomeCubit>().startTrip();
                    },
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
