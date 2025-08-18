import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:taxi_app/bloc/customer/home/customer_home_cubit.dart';
import 'package:taxi_app/bloc/customer/home/customer_home_states.dart';
import 'package:taxi_app/common/extensions.dart';
import 'package:taxi_app/common/text_style.dart';
import 'package:taxi_app/common_widgets/rounded_button.dart';

Widget buildSearchingPanel(BuildContext context, HomeSearchingForDriver state) {
  return Positioned(
    left: 0,
    right: 0,
    bottom: 0,
    child: Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.r)),
      margin: const EdgeInsets.all(20),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Text("Searching for nearby drivers...",
                style: appStyle(
                    color: KColor.primaryText,
                    fontWeight: FontWeight.bold,
                    size: 18.sp)),
            const SizedBox(height: 16),
            RoundButton(
                title: "Cancel Ride",
                onPressed: () {
                  context.read<HomeCubit>().cancelTripRequest(state.tripId);
                },
                color: KColor.red)
          ],
        ),
      ),
    ),
  );
}
