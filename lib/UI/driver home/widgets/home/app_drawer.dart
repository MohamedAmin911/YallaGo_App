import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:taxi_app/bloc/auth/auth_cubit.dart';
import 'package:taxi_app/bloc/driver/driver_cubit.dart';
import 'package:taxi_app/bloc/driver/driver_states.dart';
import 'package:taxi_app/common/extensions.dart';
import 'package:taxi_app/common/text_style.dart';
import 'package:taxi_app/common_widgets/rounded_button.dart';
import 'package:taxi_app/UI/driver%20home/screens/driver_profile_screen.dart';
import 'package:taxi_app/UI/driver%20home/screens/payout_history_screen.dart';
import 'package:taxi_app/UI/driver%20home/screens/ride_history_screen.dart';

class DriverAppDrawer extends StatelessWidget {
  const DriverAppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: KColor.bg,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
        bottomRight: Radius.circular(22.r),
        topRight: Radius.circular(22.r),
      )),
      child: Column(
        children: <Widget>[
          BlocBuilder<DriverCubit, DriverState>(
            builder: (context, state) {
              String driverName = "Loading...";
              String? driverImageUrl;

              if (state is DriverLoaded) {
                driverName = state.driver.fullName;
                driverImageUrl = state.driver.profileImageUrl;
              }

              return DrawerHeader(
                padding: EdgeInsets.only(left: 16.w, top: 20.h),
                decoration: BoxDecoration(
                    color: KColor.bg,
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(22.r),
                    )),
                child: Center(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Material(
                        elevation: 5,
                        borderRadius: BorderRadius.circular(10.r),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10.r),
                          child: (driverImageUrl != null &&
                                  driverImageUrl.isNotEmpty)
                              ? Image.network(
                                  driverImageUrl,
                                  width: 120.w,
                                  height: 120.h,
                                  fit: BoxFit.fitWidth,
                                )
                              : null,
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 10.h),
                          Text(
                            "welcome",
                            style: appStyle(
                              size: 14.sp,
                              color: KColor.placeholder,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(
                            width: 150.w,
                            child: Text(
                              driverName,
                              maxLines: 2,
                              style: appStyle(
                                size: 25.sp,
                                color: KColor.primaryText,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(
              Icons.person_2_rounded,
              color: KColor.primary,
              size: 30.sp,
            ),
            title: Text(
              'Profile',
              style: appStyle(
                  size: 15.sp,
                  color: KColor.placeholder,
                  fontWeight: FontWeight.bold),
            ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const DriverProfileScreen()),
              );
            },
          ),
          ListTile(
            leading: Icon(
              Icons.payment_rounded,
              color: KColor.primary,
              size: 30.sp,
            ),
            title: Text(
              'Payout History',
              style: appStyle(
                  size: 15.sp,
                  color: KColor.placeholder,
                  fontWeight: FontWeight.bold),
            ),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PayoutHistoryScreen()),
              );
            },
          ),
          ListTile(
            leading: Icon(
              Icons.history_rounded,
              color: KColor.primary,
              size: 30.sp,
            ),
            title: Text(
              'Ride History',
              style: appStyle(
                  size: 15.sp,
                  color: KColor.placeholder,
                  fontWeight: FontWeight.bold),
            ),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const RideHistoryScreen()),
              );
            },
          ),
          const Spacer(),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 10.h),
            child: RoundButton(
                title: "SIGN OUT",
                onPressed: () {
                  context.read<AuthCubit>().signOut();
                },
                color: KColor.placeholder),
          ),
        ],
      ),
    );
  }
}
