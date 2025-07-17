import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:taxi_app/common_widgets/txt_field_1.dart';

class CustomerInputFields extends StatelessWidget {
  const CustomerInputFields({
    super.key,
    required TextEditingController firstNameController,
    required TextEditingController lastNameController,
    required TextEditingController homeAddressController,
    required TextEditingController password,
    required TextEditingController email,
  })  : _firstNameController = firstNameController,
        _lastNameController = lastNameController,
        _password = password,
        _email = email;

  final TextEditingController _firstNameController;
  final TextEditingController _lastNameController;
  final TextEditingController _password;
  final TextEditingController _email;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CustomTxtField1(
          isObscure: false,
          controller: _firstNameController,
          hintText: "First Name",
          obscureText: false,
          keyboardType: TextInputType.name,
          errorText: "Please enter your first name",
        ),
        SizedBox(height: 10.h),
        // Last Name input
        CustomTxtField1(
          isObscure: false,
          controller: _lastNameController,
          hintText: "Last Name",
          obscureText: false,
          keyboardType: TextInputType.name,
          errorText: "Please enter your last name",
        ),
        SizedBox(height: 10.h),

        // Password input
        CustomTxtField1(
          isObscure: true,
          controller: _password,
          hintText: "Password",
          obscureText: true,
          keyboardType: TextInputType.visiblePassword,
          errorText: "Please enter your password",
        ),
        SizedBox(height: 10.h),
        // Email input
        CustomTxtField1(
          isObscure: false,
          controller: _email,
          hintText: "Email",
          obscureText: false,
          keyboardType: TextInputType.emailAddress,
          errorText: "Please enter your email",
        ),
      ],
    );
  }
}
