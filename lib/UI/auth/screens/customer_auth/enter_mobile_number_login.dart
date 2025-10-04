// ignore_for_file: avoid_print

import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taxi_app/bloc/auth/auth_cubit.dart';
import 'package:taxi_app/bloc/auth/auth_states.dart';
import 'package:taxi_app/common/extensions.dart';
import 'package:taxi_app/common/text_style.dart';
import 'package:taxi_app/common_widgets/rounded_button.dart';
import 'package:taxi_app/UI/auth/screens/customer_auth/otp_verification_screen.dart';
import 'package:taxi_app/UI/auth/widgets/auth_widgets/phone_no_input_field.dart';

class EnterMobileNumberViewLogin extends StatefulWidget {
  const EnterMobileNumberViewLogin({super.key});

  @override
  State<EnterMobileNumberViewLogin> createState() =>
      _EnterMobileNumberViewLoginState();
}

class _EnterMobileNumberViewLoginState
    extends State<EnterMobileNumberViewLogin> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  String _countryCode = '+20';
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _handleRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setBool('rememberMe', _rememberMe);
    } else {
      await prefs.setBool('rememberMe', _rememberMe);
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _onCountryChange(CountryCode countryCode) {
    _countryCode = countryCode.dialCode ?? '+20';
  }

  void _submitPhoneNumber() {
    FocusScope.of(context).unfocus();
    if (_formKey.currentState?.validate() ?? false) {
      final completeNumber = '$_countryCode${_phoneController.text.trim()}';
      _handleRememberMe();
      context.read<AuthCubit>().sendOtp(completeNumber);
    }
  }

  @override
  Widget build(BuildContext context) {
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
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthCodeSent) {
            context.pushRlacement(OtpVerificationView(
              phoneNumber: '$_countryCode${_phoneController.text.trim()}',
            ));
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: KColor.red,
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: 6.h, left: 24.w, right: 24.w),
                    child: Text(
                      "Enter Mobile Number",
                      style: appStyle(
                        size: 25,
                        color: KColor.primaryText,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  SizedBox(height: 29.h),
                  PhoneNumberInputField(
                    phoneController: _phoneController,
                    onCountryChanged: _onCountryChange,
                  ),
                  Row(
                    children: [
                      SizedBox(width: 24.w),
                      Checkbox(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4.r)),
                        value: _rememberMe,
                        onChanged: (value) {
                          setState(() {
                            _rememberMe = value ?? false;
                          });
                        },
                        activeColor: KColor.primary,
                      ),
                      Text(
                        "Remember Me",
                        style: appStyle(
                          size: 16.sp,
                          color: KColor.secondaryText,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    child: isLoading
                        ? Center(
                            child: CircularProgressIndicator(
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(KColor.primary),
                            ),
                          )
                        : RoundButton(
                            color: KColor.primary,
                            onPressed: isLoading ? () {} : _submitPhoneNumber,
                            title: "CONTINUE",
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
