import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taxi_app/bloc/customer/customer_cubit.dart';
import 'package:taxi_app/view/auth/customer_or_driver_screen.dart';
import 'package:taxi_app/view/customer%20home/home_screen.dart';

/// A widget that acts as a gate, deciding which screen to show on app startup
/// based on the user's authentication state.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    // Use a post-frame callback to ensure the context is available for navigation.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _redirect();
    });
  }

  /// Checks the current user's auth state and navigates to the appropriate screen.
  void _redirect() {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // If the user is already logged in with Firebase:
      // 1. Start listening to their profile data in the CustomerCubit.
      context.read<CustomerCubit>().listenToCustomer(user.uid);
      // 2. Navigate them directly to the home screen.
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } else {
      // If the user is not logged in:
      // Navigate them to the phone number entry screen.
      // The initState of that screen will handle loading the "Remember Me" number.
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const CustomerOrDriverScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show a simple loading indicator while the check is being performed.
    // This is usually so fast the user won't see it.
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
