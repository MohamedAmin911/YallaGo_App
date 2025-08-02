// ignore_for_file: avoid_print

import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:taxi_app/bloc/auth/auth_cubit.dart';
import 'package:taxi_app/bloc/auth/auth_states.dart';
import 'package:taxi_app/common/extensions.dart';
import 'package:taxi_app/common/text_style.dart';
import 'package:taxi_app/common_widgets/rounded_button.dart';
import 'package:taxi_app/view/auth/driver_auth/driver_otp_verification_screen.dart';
import 'package:taxi_app/view/widgets/auth_widgets/phone_no_input_field.dart';
import 'package:taxi_app/view/widgets/auth_widgets/terms_And_conditions.dart';

class DriverEnterMobileNumberView extends StatefulWidget {
  const DriverEnterMobileNumberView({super.key});

  @override
  State<DriverEnterMobileNumberView> createState() =>
      _DriverEnterMobileNumberViewState();
}

class _DriverEnterMobileNumberViewState
    extends State<DriverEnterMobileNumberView> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  String _countryCode = '+20'; // Default to Egypt

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
            context.pushRlacement(DriverOtpVerificationView(
              phoneNumber: '$_countryCode${_phoneController.text.trim()}',
            ));
          } else if (state is AuthError) {
            // Show an error message if something goes wrong
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: KColor.red,
              ),
            );
          }
        },
        builder: (context, state) {
          // The UI is built based on the current state
          final isLoading = state is AuthLoading;

          return SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Text
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
                  SizedBox(height: 16.h),
                  const TermsAndConditions(),
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
