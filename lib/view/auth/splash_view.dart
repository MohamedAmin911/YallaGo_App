import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:taxi_app/common/extensions.dart';
import 'package:taxi_app/common/images.dart';
import 'package:taxi_app/common/text_style.dart';
import 'package:taxi_app/common_widgets/rounded_button.dart';
import 'package:taxi_app/view/auth/auth_gate.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPrerequisites();
    });
  }

  Future<void> _checkPrerequisites() async {
    final startTime = DateTime.now();

    final allChecksPassed = await _runAllChecks();
    if (!mounted) return;

    if (allChecksPassed) {
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);
      const minDisplayTime = Duration(seconds: 3);

      if (duration < minDisplayTime) {
        final remainingTime = minDisplayTime - duration;
        await Future.delayed(remainingTime);
      }

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AuthGate()),
      );
    }
  }

  Future<bool> _runAllChecks() async {
    final connectivityResult = await (Connectivity().checkConnectivity());
    if (!mounted) return false;
    if (connectivityResult.contains(ConnectivityResult.none)) {
      _showErrorDialog(
        "No Internet Connection",
        "Please check your internet connection and try again.",
      );
      return false;
    }

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!mounted) return false;
    if (!serviceEnabled) {
      _showErrorDialog(
        "Location Services Disabled",
        "Please enable location services (GPS) to use this app.",
      );
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (!mounted) return false;
        _showErrorDialog(
          "Location Permission Denied",
          "Location permissions are required to use this app.",
        );
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (!mounted) return false;
      _showErrorDialog(
        "Location Permission Denied",
        "Location permissions are permanently denied. Please enable them from your phone's settings.",
      );
      return false;
    }

    return true;
  }

  void _showErrorDialog(String title, String content) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          titleTextStyle: appStyle(
              size: 20.sp, color: KColor.primary, fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          contentTextStyle: appStyle(
              size: 16.sp,
              color: KColor.primaryText,
              fontWeight: FontWeight.normal),
          title: Text(title),
          content: Text(content),
          actions: <Widget>[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: RoundButton(
                color: KColor.primary,
                title: 'RETRY',
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  _checkPrerequisites();
                },
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KColor.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(KImage.logo3, width: 300.w),
            SizedBox(height: 30.h),
            CircularProgressIndicator(color: KColor.primary),
          ],
        ),
      ),
    );
  }
}
