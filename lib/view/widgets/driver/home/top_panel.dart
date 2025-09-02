import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:taxi_app/bloc/driver/driver_cubit.dart';
import 'package:taxi_app/bloc/driver/driver_states.dart';

import 'package:taxi_app/bloc/driver/home/driver_home_cubit.dart';
import 'package:taxi_app/bloc/driver/home/driver_home_states.dart';
import 'package:taxi_app/common/text_style.dart';
import 'package:taxi_app/common_widgets/rounded_button.dart';
import 'package:taxi_app/common/extensions.dart';

Widget buildTopPanel(BuildContext context, DriverHomeState state) {
  bool isOnline = state is DriverOnline ||
      state is DriverEnRouteToPickup ||
      state is DriverArrivedAtPickup ||
      state is DriverArrivedAtPickup ||
      state is DriverTripInProgress;

  return SafeArea(
    child: Padding(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 16.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          BlocBuilder<DriverCubit, DriverState>(
            builder: (context, driverState) {
              double balance = 0.0;
              if (driverState is DriverLoaded) {
                balance = driverState.driver.balance;
              }
              return Material(
                borderRadius: BorderRadius.circular(30.r),
                elevation: 3,
                child: Container(
                  height: 55.h,
                  padding:
                      EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                  decoration: BoxDecoration(
                    color: KColor.bg,
                    borderRadius: BorderRadius.circular(30.r),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.menu_rounded,
                          weight: 3,
                          size: 25.sp,
                          color: KColor.primaryText,
                        ),
                        onPressed: () => Scaffold.of(context).openDrawer(),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 10.w, vertical: 8.h),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(30.r),
                        ),
                        child: Text(
                          "EGP",
                          style: appStyle(
                              size: 13.sp,
                              color: KColor.bg,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      Text(
                        ' ${balance.toStringAsFixed(2)} ',
                        style: appStyle(
                            size: 13.sp,
                            color: KColor.primaryText,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          Material(
            elevation: 3,
            color: isOnline ? KColor.red : KColor.primary,
            borderRadius: BorderRadius.circular(40.r),
            child: Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: KColor.bg,
                borderRadius: BorderRadius.circular(40.r),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 110.w,
                    child: RoundButton(
                      size: 12.sp,
                      fontWeight: FontWeight.w900,
                      title: isOnline ? "GO OFFLINE" : "GO ONLINE",
                      onPressed: () {
                        if (isOnline) {
                          context.read<DriverHomeCubit>().goOffline();
                        } else {
                          context.read<DriverHomeCubit>().goOnline();
                        }
                      },
                      color: isOnline ? KColor.red : KColor.primary,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10.w),
                    child: Icon(
                      size: 25.sp,
                      isOnline
                          ? Icons.gps_off_rounded
                          : Icons.gps_fixed_rounded,
                      color: isOnline ? KColor.red : KColor.primary,
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
