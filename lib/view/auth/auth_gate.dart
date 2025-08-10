import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taxi_app/bloc/customer/customer_cubit.dart';
import 'package:taxi_app/bloc/driver/driver_cubit.dart';
import 'package:taxi_app/common/extensions.dart';
import 'package:taxi_app/common/images.dart';
import 'package:taxi_app/view/auth/customer_or_driver_screen.dart';
import 'package:taxi_app/view/customer%20home/customer_home_screen.dart';
import 'package:taxi_app/view/driver%20home/driver_home_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool rememberMe = false;
  Future<void> _loadSavedPhoneNumber() async {
    final prefs = await SharedPreferences.getInstance();
    final isRememberMe = prefs.getBool("rememberMe");
    if (isRememberMe != null) {
      setState(() {
        rememberMe = isRememberMe;
      });
    }
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadSavedPhoneNumber();
      _redirectUser();
    });
  }

  Future<void> _redirectUser() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const CustomerOrDriverScreen()),
        (route) => false,
      );
      return;
    } else {
      if (rememberMe == false) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const CustomerOrDriverScreen()),
          (route) => false,
        );
      }

      if (rememberMe) {
        final customerCubit = context.read<CustomerCubit>();
        final driverCubit = context.read<DriverCubit>();

        final isCustomer = await customerCubit.checkIfUserExists(user.uid);
        if (isCustomer) {
          customerCubit.listenToCustomer(user.uid);
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
            (route) => false,
          );
          return;
        }

        final isDriver = await driverCubit.checkIfDriverExists(user.uid);
        if (isDriver) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const DriverHomeScreen()),
            (route) => false,
          );
          return;
        }
      }
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const CustomerOrDriverScreen()),
      (route) => false,
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
            CircularProgressIndicator(color: KColor.bg),
          ],
        ),
      ),
    );
  }
}
