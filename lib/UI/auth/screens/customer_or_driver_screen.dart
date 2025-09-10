import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:taxi_app/common/extensions.dart';
import 'package:taxi_app/common/images.dart';
import 'package:taxi_app/common/text_style.dart';
import 'package:taxi_app/UI/auth/screens/customer_auth/signup_or_login_screen.dart';
import 'package:taxi_app/UI/auth/screens/driver_auth/driver_signup_or_loging_screen.dart';

class CustomerOrDriverScreen extends StatefulWidget {
  const CustomerOrDriverScreen({super.key});

  @override
  State<CustomerOrDriverScreen> createState() => _CustomerOrDriverScreenState();
}

class _CustomerOrDriverScreenState extends State<CustomerOrDriverScreen> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(const AssetImage(KImage.taxiImg), context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        alignment: Alignment.center,
        children: [
          CachedNetworkImage(
            imageUrl: KImage.taxiImg,
            fit: BoxFit.cover,
            width: 900.w,
            height: 900.h,
          ),
          Container(
            width: context.width,
            height: context.height,
            color: Colors.black.withValues(alpha: 0.8),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 230.h),
                Image.asset(
                  KImage.logo4,
                  width: 300.w,
                ),
                const Spacer(),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 50.w),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      //driver
                      InkWell(
                        onTap: () {
                          context.push(const DriverSignupOrLogingScreen());
                        },
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(30.r),
                          elevation: 100,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 300.w,
                                padding: EdgeInsets.symmetric(
                                    horizontal: 15.w, vertical: 15.h),
                                decoration: BoxDecoration(
                                  color: KColor.primary,
                                  borderRadius: BorderRadius.circular(30.r),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Image.asset(
                                      KImage.taxiPin,
                                      width: 35.w,
                                      color: KColor.bg,
                                    ),
                                    SizedBox(width: 10.w),
                                    Text(
                                      "DRIVER",
                                      style: appStyle(
                                          size: 30.sp,
                                          color: KColor.bg,
                                          fontWeight: FontWeight.w900),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 20.h),
                      //customer
                      InkWell(
                        onTap: () {
                          context.push(const SignUpOrLoginView());
                        },
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(30.r),
                          elevation: 100,
                          child: Container(
                            width: 300.w,
                            padding: EdgeInsets.symmetric(
                                horizontal: 15.w, vertical: 15.h),
                            decoration: BoxDecoration(
                              color: KColor.bg,
                              borderRadius: BorderRadius.circular(30.r),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  KImage.userPin,
                                  width: 35.w,
                                  color: KColor.primary,
                                ),
                                SizedBox(width: 10.w),
                                Text(
                                  "CUSTOMER",
                                  style: appStyle(
                                      size: 30.sp,
                                      color: KColor.primary,
                                      fontWeight: FontWeight.w900),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 50.h),
              ],
            ),
          )
        ],
      ),
    );
  }
}
