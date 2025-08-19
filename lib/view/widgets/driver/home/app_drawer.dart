import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:taxi_app/bloc/auth/auth_cubit.dart';
import 'package:taxi_app/common/text_style.dart';
import 'package:taxi_app/common_widgets/rounded_button.dart';
import 'package:taxi_app/common/images.dart';
import 'package:taxi_app/common/extensions.dart';
import 'package:taxi_app/view/widgets/driver/drawer_screens/driver_profile_screen.dart';
import 'package:taxi_app/view/widgets/driver/drawer_screens/ride_history_screen.dart';

Widget buildAppDrawer(BuildContext context) {
  return Drawer(
    backgroundColor: KColor.bg,
    shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
      bottomRight: Radius.circular(22.r),
      topRight: Radius.circular(22.r),
    )),
    child: Column(
      children: <Widget>[
        DrawerHeader(
          padding: EdgeInsets.all(40.w),
          curve: Curves.bounceIn,
          decoration: BoxDecoration(
              color: KColor.primary,
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(22.r),
              )),
          child: Image.asset(KImage.logo4),
        ),
        ListTile(
          leading: Icon(
            Icons.person,
            color: KColor.placeholder,
            size: 25.sp,
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
            Icons.payment,
            color: KColor.placeholder,
            size: 25.sp,
          ),
          title: Text(
            'Payment',
            style: appStyle(
                size: 15.sp,
                color: KColor.placeholder,
                fontWeight: FontWeight.bold),
          ),
          onTap: () {},
        ),
        ListTile(
          leading: Icon(
            Icons.history,
            color: KColor.placeholder,
            size: 25.sp,
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
