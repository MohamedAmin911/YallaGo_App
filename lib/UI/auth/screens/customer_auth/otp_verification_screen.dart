// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sms_autofill/sms_autofill.dart';
import 'package:taxi_app/bloc/auth/auth_cubit.dart';
import 'package:taxi_app/bloc/auth/auth_states.dart';
import 'package:taxi_app/bloc/customer/customer_cubit.dart';
import 'package:taxi_app/common/extensions.dart';
import 'package:taxi_app/common/text_style.dart';
import 'package:taxi_app/common_widgets/rounded_button.dart';
import 'package:taxi_app/UI/auth/screens/customer_auth/create_profile_screen.dart';
import 'package:taxi_app/UI/auth/screens/customer_auth/enter_mobile_number_screen.dart';
import 'package:taxi_app/UI/auth/screens/auth_gate.dart';

class OtpVerificationView extends StatefulWidget {
  const OtpVerificationView({super.key, required this.phoneNumber});
  final String phoneNumber;
  @override
  State<OtpVerificationView> createState() => _OtpVerificationViewState();
}

class _OtpVerificationViewState extends State<OtpVerificationView>
    with CodeAutoFill {
  final TextEditingController _codeController = TextEditingController();
  Timer? _timer;
  final ValueNotifier<int> _timerNotifier = ValueNotifier(60);

  @override
  void initState() {
    super.initState();
    listenForCode();
    _startResendTimer();
  }

  @override
  void dispose() {
    cancel();
    _codeController.dispose();
    _timer?.cancel();
    _timerNotifier.dispose();
    super.dispose();
  }

  @override
  void codeUpdated() {
    setState(() {
      _codeController.text = code ?? '';

      if (_codeController.text.length == 6) {
        _submitOtp();
      }
    });
  }

  void _startResendTimer() {
    _timer?.cancel();
    _timerNotifier.value = 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timerNotifier.value > 0) {
        _timerNotifier.value--;
      } else {
        _timer?.cancel();
      }
    });
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return "${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}";
  }

  void _resendCode() {
    context.read<AuthCubit>().sendOtp(widget.phoneNumber);
    _startResendTimer();
  }

  void _submitOtp() {
    if (_codeController.text.length == 6) {
      context.read<AuthCubit>().verifyOtp(_codeController.text.trim());
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter the 6-digit code.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) async {
          if (state is AuthLoggedIn) {
            final customerCubit = context.read<CustomerCubit>();
            final userExists =
                await customerCubit.checkIfUserExists(state.user.uid);
            if (userExists) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Welcome back!")),
              );
              context.pushRlacement(const AuthGate());
              // context.pushRlacement(const HomeScreen());
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Success!")),
              );
              context.pushRlacement(const CreateProfileScreen());
            }
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(state.message), backgroundColor: KColor.red),
            );
          } else if (state is AuthCodeSent) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("A new code has been sent.")),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(top: 62.h, left: 24.w),
                  child: Text("OTP Verification",
                      style: appStyle(
                          size: 25,
                          color: KColor.primaryText,
                          fontWeight: FontWeight.w800)),
                ),
                SizedBox(height: 10.h),
                Padding(
                  padding: EdgeInsets.only(left: 24.w),
                  child: Text("Enter the 6-digit code sent to you at",
                      style: appStyle(
                          size: 16,
                          color: KColor.secondaryText,
                          fontWeight: FontWeight.w500)),
                ),
                Padding(
                  padding: EdgeInsets.only(left: 24.w),
                  child: Row(
                    children: [
                      Text(widget.phoneNumber,
                          style: appStyle(
                              size: 16,
                              color: KColor.primaryText,
                              fontWeight: FontWeight.w500)),
                      TextButton(
                        onPressed: () => context
                            .pushRlacement(const EnterMobileNumberView()),
                        child: Text("Edit",
                            style: appStyle(
                                size: 16,
                                color: KColor.primary,
                                fontWeight: FontWeight.bold)),
                      )
                    ],
                  ),
                ),
                SizedBox(height: 41.h),
                // PIN FIELD
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.h),
                  child: PinFieldAutoFill(
                    cursor: Cursor(
                        color: KColor.lightGray,
                        height: 8.h,
                        enabled: true,
                        offset: 0.1,
                        radius: Radius.circular(22.r),
                        width: 20.w),
                    controller: _codeController,
                    codeLength: 6,
                    decoration: UnderlineDecoration(
                      lineHeight: 3.h,
                      textStyle: appStyle(
                          size: 20,
                          color: KColor.primary,
                          fontWeight: FontWeight.bold),
                      colorBuilder:
                          FixedColorBuilder(KColor.primary.withOpacity(0.5)),
                      gapSpace: 10.w,
                    ),
                    // onCodeChanged: (code) {
                    //   if (code != null && code.length == 6) {
                    //     _submitOtp();
                    //   }
                    // },
                  ),
                ),
                SizedBox(height: 40.h),
                // BUTTON
                Center(
                  child: SizedBox(
                    width: context.width * 0.9,
                    child: isLoading
                        ? Center(
                            child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    KColor.primary)))
                        : RoundButton(
                            color: KColor.primary,
                            onPressed: isLoading ? () {} : _submitOtp,
                            title: "SUBMIT",
                          ),
                  ),
                ),
                SizedBox(height: 15.h),
                // RESEND CODE
                Center(
                  child: ValueListenableBuilder<int>(
                    valueListenable: _timerNotifier,
                    builder: (context, remainingSeconds, child) {
                      if (remainingSeconds > 0) {
                        return Text(
                          "Resend code in ${_formatTime(remainingSeconds)}",
                          style: appStyle(
                              size: 15,
                              color: KColor.secondaryText,
                              fontWeight: FontWeight.w500),
                        );
                      } else {
                        return TextButton(
                          onPressed: _resendCode,
                          child: Text(
                            "RESEND CODE",
                            style: appStyle(
                                size: 14,
                                color: KColor.primary,
                                fontWeight: FontWeight.bold),
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
