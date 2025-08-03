import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taxi_app/bloc/customer/customer_cubit.dart';
import 'package:taxi_app/bloc/driver/driver_cubit.dart';
import 'package:taxi_app/view/auth/customer_or_driver_screen.dart';
import 'package:taxi_app/view/customer%20home/home_screen.dart';
import 'package:taxi_app/view/driver%20home/driver_home_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _redirectUser();
    });
  }

  Future<void> _redirectUser() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // If no one is logged in, go to the screen where they choose their role.
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const CustomerOrDriverScreen()),
        (route) => false,
      );
      return;
    }

    // If a user IS logged in, check their role in the database.
    final customerCubit = context.read<CustomerCubit>();
    // final driverCubit = context.read<DriverCubit>();

    final isCustomer = await customerCubit.checkIfUserExists(user.uid);
    if (isCustomer) {
      // If they have a customer profile, start listening to their data and go to the customer home.
      customerCubit.listenToCustomer(user.uid);
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
      return;
    }

    // final isDriver = await driverCubit.checkIfDriverExists(user.uid);
    // if (isDriver) {
    //   // If they have a driver profile, go to the driver home.
    //   // You would also start listening to driver data here.
    //   Navigator.of(context).pushAndRemoveUntil(
    //     MaterialPageRoute(builder: (_) => const DriverHomeScreen()),
    //     (route) => false,
    //   );
    //   return;
    // }

    // Fallback: If the user is logged in but has no profile (e.g., they closed the app
    // during sign-up), send them back to the start.
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const CustomerOrDriverScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
