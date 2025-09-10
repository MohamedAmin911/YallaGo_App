import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:taxi_app/bloc/auth/auth_cubit.dart';
import 'package:taxi_app/bloc/customer/customer_cubit.dart';
import 'package:taxi_app/bloc/customer/customer_states.dart';
import 'package:taxi_app/common/extensions.dart';
import 'package:taxi_app/common/text_style.dart';
import 'package:taxi_app/common_widgets/rounded_button.dart';
import 'package:taxi_app/UI/customer%20home/screens/drawer_screens/customer_profile_screen.dart';
import 'package:taxi_app/UI/customer%20home/screens/drawer_screens/payment_methods_screen.dart';
import 'package:taxi_app/UI/customer%20home/screens/drawer_screens/ride_history.dart';

class CustomerAppDrawer extends StatelessWidget {
  const CustomerAppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final _auth = FirebaseAuth.instance;
    return Drawer(
      backgroundColor: KColor.bg,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
        bottomRight: Radius.circular(22.r),
        topRight: Radius.circular(22.r),
      )),
      child: Column(
        children: <Widget>[
          BlocBuilder<CustomerCubit, CustomerState>(
            builder: (context, state) {
              String customerName = "Loading...";
              String? customerImageUrl;

              if (state is CustomerLoaded) {
                customerName = state.customer.fullName ?? "Customer";
                customerImageUrl = state.customer.profileImageUrl;
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
                        borderRadius: BorderRadius.circular(10.r),
                        elevation: 5,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10.r),
                          child: (customerImageUrl != null &&
                                  customerImageUrl.isNotEmpty)
                              ? Image.network(
                                  customerImageUrl,
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
                              customerName,
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
                MaterialPageRoute(
                    builder: (_) => const CustomerProfileScreen()),
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
              'Payment Methods',
              style: appStyle(
                  size: 15.sp,
                  color: KColor.placeholder,
                  fontWeight: FontWeight.bold),
            ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => PaymentMethodsScreen(
                          customerUid: _auth.currentUser!.uid,
                        )),
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
