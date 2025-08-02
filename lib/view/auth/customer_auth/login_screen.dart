import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:taxi_app/common/extensions.dart';
import 'package:taxi_app/common/text_style.dart';
import 'package:taxi_app/common_widgets/rounded_button.dart';
import 'package:taxi_app/common_widgets/txt_field_1.dart';

class LogInScreen extends StatefulWidget {
  const LogInScreen({super.key});

  @override
  State<LogInScreen> createState() => _LogInScreenState();
}

class _LogInScreenState extends State<LogInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _password = TextEditingController();
  @override
  void dispose() {
    _phoneController.dispose();
    _password.dispose();
    super.dispose();
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
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 22.h),
                Text(
                  "Sign In",
                  style: appStyle(
                    size: 25.sp,
                    color: KColor.primaryText,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 17.h),
                // Phone number input
                CustomTxtField1(
                  isObscure: false,
                  controller: _phoneController,
                  hintText: "Phone Number",
                  obscureText: false,
                  keyboardType: TextInputType.phone,
                  errorText: "Please enter your phone number",
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
                SizedBox(height: 40.h),
                //SignIn button
                RoundButton(
                  color: KColor.primary,
                  title: "SIGN IN",
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      // Handle login logic
                      print(
                          "Phone: ${_phoneController.text}, Password: ${_password.text}");
                    }
                  },
                ),

                Center(
                  child: TextButton(
                    onPressed: () {},
                    child: Text(
                      "FORGOT PASSWORD?",
                      style: appStyle(
                        size: 12.sp,
                        color: KColor.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
