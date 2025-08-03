import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:taxi_app/common/extensions.dart';
import 'package:taxi_app/common/images.dart';
import 'package:taxi_app/common/text_style.dart';
import 'package:taxi_app/common_widgets/rounded_button.dart';
import 'package:taxi_app/view/auth/driver_auth/driver_enter_mobile_number_view.dart';
import 'package:taxi_app/view/auth/driver_auth/driver_login_screen.dart';

class DriverSignupOrLogingScreen extends StatefulWidget {
  const DriverSignupOrLogingScreen({super.key});

  @override
  State<DriverSignupOrLogingScreen> createState() =>
      _DriverSignupOrLogingScreenState();
}

class _DriverSignupOrLogingScreenState
    extends State<DriverSignupOrLogingScreen> {
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
            color: Colors.black.withValues(alpha: 0.7),
          ),
          Positioned(
            top: 30.h,
            left: 16.w,
            child: IconButton(
              onPressed: context.pop,
              icon: Icon(
                Icons.arrow_back_ios,
                color: KColor.bg,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                SizedBox(height: 250.h),
                Image.asset(
                  KImage.logo4,
                  width: 300.w,
                ),
                // const Spacer(),
                SizedBox(height: 150.h),

                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: RoundButton(
                    color: KColor.primary,
                    title: "SIGN IN",
                    onPressed: () {
                      context.push(const DriverEnterMobileNumberViewLogin());
                    },
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: TextButton(
                    onPressed: () {
                      context.push(const DriverEnterMobileNumberView());
                    },
                    child: Text(
                      "SIGN UP",
                      style: appStyle(
                        color: KColor.primaryTextW,
                        size: 16.r,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
