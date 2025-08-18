import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:taxi_app/bloc/auth/auth_cubit.dart';
import 'package:taxi_app/bloc/customer/home/customer_home_states.dart';
import 'package:taxi_app/common/extensions.dart';
import 'package:taxi_app/common/text_style.dart';
import 'package:taxi_app/common_widgets/rounded_button.dart';
import 'package:taxi_app/common/images.dart';
import 'package:taxi_app/view/widgets/chat_bottom_sheet.dart';

Widget buildDriverEnRoutePanel(BuildContext context, HomeDriverEnRoute state) {
  final driver = state.driver;
  return Positioned(
    left: 0,
    right: 0,
    bottom: 0,
    child: Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.r)),
      margin: const EdgeInsets.all(20),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(30.r),
                  child: driver.profileImageUrl != null
                      ? Image.network(
                          driver.profileImageUrl!,
                          width: 100.w,
                          height: 100.h,
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(driver.fullName,
                        style: appStyle(
                            color: KColor.primaryText,
                            fontWeight: FontWeight.bold,
                            size: 30.sp)),
                    SizedBox(height: 10.h),
                    Row(
                      children: [
                        Icon(
                          Icons.drive_eta_rounded,
                          size: 25.sp,
                          color: KColor.placeholder,
                        ),
                        SizedBox(width: 3.w),
                        Icon(
                          Icons.circle,
                          size: 20.sp,
                          color: Color(int.parse(
                              "0xff${driver.carColor.replaceFirst(RegExp(r'#'), "")}")),
                        ),
                        SizedBox(width: 3.w),
                        SizedBox(
                          width: 90.w,
                          child: Text(driver.carModel,
                              style: appStyle(
                                  color: KColor.primaryText,
                                  fontWeight: FontWeight.bold,
                                  size: 14.sp)),
                        ),
                      ],
                    ),
                    SizedBox(height: 5.h),
                    Row(
                      children: [
                        Image.asset(
                          KImage.licensePlate,
                          width: 25.w,
                          color: KColor.placeholder,
                        ),
                        Text(" ${driver.licensePlate}",
                            style: appStyle(
                                color: KColor.primaryText,
                                fontWeight: FontWeight.bold,
                                size: 14.sp)),
                      ],
                    ),
                    SizedBox(height: 5.h),
                    RatingBarIndicator(
                      rating: driver.rating,
                      itemBuilder: (context, index) => const Icon(
                        Icons.star_rate_rounded,
                        color: Colors.amber,
                      ),
                      itemCount: 5,
                      itemSize: 25.sp,
                      unratedColor: KColor.placeholder.withOpacity(0.5),
                      direction: Axis.horizontal,
                    ),
                    SizedBox(height: 5.h),
                  ],
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
                          child:
                              ChatBottomSheet(tripId: state.trip.tripId ?? ""),
                        );
                      },
                    );
                  },
                  color: KColor.primary),
            ),
            const Divider(height: 24),
            LinearProgressIndicator(
              minHeight: 5.h,
              color: KColor.primary,
              borderRadius: BorderRadius.circular(30.r),
            ),
            SizedBox(height: 10.h),
            Text("Your driver is on the way!",
                style: appStyle(
                    color: KColor.primaryText,
                    fontWeight: FontWeight.bold,
                    size: 15.sp)),
            SizedBox(height: 5.h),
            Text("Arriving in ${state.arrivalEta} minutes",
                style: appStyle(
                    color: KColor.placeholder,
                    fontWeight: FontWeight.w600,
                    size: 14.sp)),
          ],
        ),
      ),
    ),
  );
}
