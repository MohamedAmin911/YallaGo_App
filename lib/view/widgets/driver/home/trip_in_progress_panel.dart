import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:taxi_app/bloc/driver/home/driver_home_cubit.dart';
import 'package:taxi_app/bloc/driver/home/driver_home_states.dart';
import 'package:taxi_app/common/extensions.dart';
import 'package:taxi_app/common_widgets/rounded_button.dart';
import 'package:taxi_app/view/widgets/driver/home/location_field.dart';

Widget buildTripInProgressPanel(
    BuildContext context, DriverTripInProgress state) {
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
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: RoundButton(
                      title: "END TRIP",
                      onPressed: () {
                        context.read<DriverHomeCubit>().endTrip();
                      },
                      color: KColor.primary),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
