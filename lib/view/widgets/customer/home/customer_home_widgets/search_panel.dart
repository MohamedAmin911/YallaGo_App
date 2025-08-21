import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:taxi_app/bloc/customer/home/customer_home_states.dart';
import 'package:taxi_app/common/extensions.dart';
import 'package:taxi_app/common/images.dart';
import 'package:taxi_app/view/widgets/driver/home/location_field.dart';

Widget buildSearchPanel(BuildContext context, HomeMapReady state,
    Function(BuildContext, LatLng) navigateToSearch) {
  return Positioned(
    left: 0,
    right: 0,
    bottom: 0,
    child: Card(
      elevation: 8,
      color: KColor.bg,
      margin: EdgeInsets.all(15.w),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22.r),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Padding(
                padding: EdgeInsets.only(top: 15.h, bottom: 8.h),
                child: Column(
                  children: [
                    Icon(Icons.circle, color: KColor.primary, size: 20.sp),
                    Expanded(
                        child: Container(
                      width: 2.w,
                      decoration: BoxDecoration(
                        color: KColor.primary,
                        borderRadius: BorderRadius.circular(22.r),
                      ),
                    )),
                    SizedBox(height: 1.h),
                    Image.asset(
                      KImage.destinationIcon,
                      width: 20.w,
                    ),
                  ],
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  children: [
                    buildLocationField(
                      text: state.currentAddress,
                      onTap: () {},
                    ),
                    SizedBox(height: 12.h),
                    buildLocationField(
                      text: "Where to?",
                      isHint: true,
                      onTap: () =>
                          navigateToSearch(context, state.currentPosition),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
