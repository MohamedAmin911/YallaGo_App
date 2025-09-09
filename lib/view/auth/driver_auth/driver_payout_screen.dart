import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:taxi_app/common/extensions.dart';
import 'package:taxi_app/common/text_style.dart';
import 'package:taxi_app/data_models/push_token_service.dart';
import 'package:taxi_app/view/auth/driver_auth/driver_signup_or_loging_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:taxi_app/bloc/auth/auth_cubit.dart';
import 'package:taxi_app/bloc/auth/auth_states.dart';
import 'package:taxi_app/bloc/driver/driver_cubit.dart';
import 'package:taxi_app/bloc/driver/driver_states.dart';
import 'package:taxi_app/common_widgets/rounded_button.dart';
import 'package:webview_flutter/webview_flutter.dart';

class DriverPayoutScreen extends StatelessWidget {
  // Receives ALL data from the entire sign-up flow
  final String fullName;
  final String email;
  final File? profileImageFile;
  final String carModel;
  final String licensePlate;
  final String carColor;
  final File? carImageFile;
  final File nationalIdFile;
  final File driversLicenseFile;
  final File carLicenseFile;
  final File criminalRecordFile;

  const DriverPayoutScreen({
    super.key,
    required this.fullName,
    required this.email,
    this.profileImageFile,
    required this.carModel,
    required this.licensePlate,
    required this.carColor,
    this.carImageFile,
    required this.nationalIdFile,
    required this.driversLicenseFile,
    required this.carLicenseFile,
    required this.criminalRecordFile,
  });

  // Choose any HTTPS URLs you control (or temporary ones).
  // We’ll detect these inside the WebView to know when onboarding finished/failed.
  static const String _stripeReturnUrl = 'https://example.com/stripe-return';
  static const String _stripeRefreshUrl = 'https://example.com/stripe-refresh';

  Future<void> _connectStripeAndFinish(BuildContext context) async {
    final driverCubit = context.read<DriverCubit>();
    final authState = context.read<AuthCubit>().state;

    if (authState is! AuthLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error: User not logged in.")),
      );
      return;
    }

    final driverUid = authState.user.uid;
    final phone = authState.user.phoneNumber ?? "";

    try {
      // 1) Create (or reuse) a Stripe Connect account via your backend (Pipedream).
      // Make sure createDriverConnectAccount returns the accountId (String?)
      final accountId = await driverCubit.createDriverConnectAccount(
        driverUid: driverUid,
        email: email,
      );

      if (accountId == null || accountId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to create Stripe account.")),
        );
        return;
      }

      // 2) Create onboarding link and open in WebView
      final onboardingUrl = await driverCubit.createDriverOnboardingLink(
        accountId: accountId,
        returnUrl: _stripeReturnUrl,
        refreshUrl: _stripeRefreshUrl,
      );

      if (onboardingUrl == null || onboardingUrl.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to get onboarding link.")),
        );
        return;
      }

      final completed = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => _StripeOnboardingWebView(
            startUrl: onboardingUrl,
            returnUrl: _stripeReturnUrl,
            refreshUrl: _stripeRefreshUrl,
          ),
        ),
      );

      if (completed != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Onboarding was cancelled.")),
        );
        return;
      }

      // 3) Finish driver profile creation (uploads + Firestore)
      await driverCubit.createDriverProfile(
        uid: driverUid,
        phoneNumber: phone,
        fullName: fullName,
        email: email,
        profileImageFile: profileImageFile,
        carModel: carModel,
        licensePlate: licensePlate,
        carColor: carColor,
        carImageFile: carImageFile,
        nationalIdFile: nationalIdFile,
        driversLicenseFile: driversLicenseFile,
        carLicenseFile: carLicenseFile,
        criminalRecordFile: criminalRecordFile,
        stripeConnectAccountId: accountId, // IMPORTANT: save it
      );
    } catch (e) {
      // Errors are also emitted via DriverCubit -> DriverError
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Stripe onboarding error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final _auth = FirebaseAuth.instance;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: context.pop,
          icon: Icon(
            Icons.arrow_back_ios,
            color: KColor.primaryText,
          ),
        ),
      ),
      body: BlocListener<DriverCubit, DriverState>(
        listener: (context, state) async {
          if (state is DriverProfileCreated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Sign up completed.")),
            );

            await PushTokenService().register(_auth.currentUser!.uid);

            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                  builder: (_) => const DriverSignupOrLogingScreen()),
              (route) => false,
            );
          } else if (state is DriverError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 22.h),
              Text(
                "Add Payout Information",
                style: appStyle(
                  size: 25.sp,
                  color: KColor.primaryText,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 30.h),
              Center(
                child: Icon(Icons.account_balance_wallet_outlined,
                    size: 80.r, color: KColor.primary),
              ),
              SizedBox(height: 20.h),
              Text(
                "We partner with Stripe for secure financial services. Tap below to set up your payout account on Stripe's secure website.",
                textAlign: TextAlign.center,
                style: appStyle(
                  color: KColor.placeholder,
                  fontWeight: FontWeight.w500,
                  size: 16.sp,
                ),
              ),
              SizedBox(height: 40.h),
              BlocBuilder<DriverCubit, DriverState>(
                builder: (context, state) {
                  final isLoading = state is DriverLoading;
                  return isLoading
                      ? Center(
                          child:
                              CircularProgressIndicator(color: KColor.primary))
                      : RoundButton(
                          title: "Connect with Stripe",
                          color: KColor.primary,
                          onPressed: () => _connectStripeAndFinish(context),
                        );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Simple WebView that completes when it navigates to returnUrl or refreshUrl
class _StripeOnboardingWebView extends StatefulWidget {
  final String startUrl;
  final String returnUrl;
  final String refreshUrl;

  const _StripeOnboardingWebView({
    required this.startUrl,
    required this.returnUrl,
    required this.refreshUrl,
  });

  @override
  State<_StripeOnboardingWebView> createState() =>
      _StripeOnboardingWebViewState();
}

class _StripeOnboardingWebViewState extends State<_StripeOnboardingWebView> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (req) {
            final url = req.url;
            if (url.startsWith(widget.returnUrl)) {
              Navigator.of(context).pop(true); // onboarding done
              return NavigationDecision.prevent;
            }
            if (url.startsWith(widget.refreshUrl)) {
              Navigator.of(context).pop(false); // user cancelled / refresh
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.startUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Stripe Onboarding")),
      body: WebViewWidget(controller: _controller),
    );
  }
}
