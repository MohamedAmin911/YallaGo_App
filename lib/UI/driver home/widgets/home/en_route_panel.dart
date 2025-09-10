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

Widget buildEnRouteToPickupPanel(
    BuildContext context, DriverEnRouteToPickup state) {
  final trip = state.acceptedTrip;

  return Positioned(
    left: 0,
    right: 0,
    bottom: 0,
    child: Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.r)),
      margin: const EdgeInsets.all(20),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24.r,
                  backgroundImage: (trip.customerImageUrl != null &&
                          trip.customerImageUrl!.isNotEmpty)
                      ? NetworkImage(trip.customerImageUrl!)
                      : null,
                  child: (trip.customerImageUrl == null ||
                          trip.customerImageUrl!.isEmpty)
                      ? const Icon(Icons.person)
                      : null,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    trip.customerName ?? "Customer",
                    style: appStyle(
                      size: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: KColor.primaryText,
                    ),
                  ),
                ),
                SizedBox(
                  width: 85.w,
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
              ],
            ),
            const Divider(height: 24),
            IntrinsicHeight(
              child: Row(
                children: [
                  Column(
                    children: [
                      Icon(Icons.circle, color: KColor.primary, size: 17.sp),
                      Expanded(
                          child: Container(width: 1.w, color: KColor.primary)),
                      Icon(Icons.location_on,
                          color: KColor.primary, size: 20.sp),
                    ],
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("PICKUP",
                            style: appStyle(
                                size: 12.sp,
                                color: KColor.placeholder,
                                fontWeight: FontWeight.bold)),
                        Text(trip.pickupAddress,
                            style: appStyle(
                                size: 16.sp,
                                color: KColor.primaryText,
                                fontWeight: FontWeight.bold),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                        SizedBox(height: 12.h),
                        Text("DESTINATION",
                            style: appStyle(
                                size: 12.sp,
                                color: KColor.placeholder,
                                fontWeight: FontWeight.bold)),
                        Text(trip.destinationAddress,
                            style: appStyle(
                                size: 16.sp,
                                color: KColor.primaryText,
                                fontWeight: FontWeight.bold),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: RoundButton(
                    title: "ARRIVED",
                    onPressed: () {
                      context.read<DriverHomeCubit>().driverArrivedAtPickup();
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
