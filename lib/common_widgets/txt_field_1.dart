import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:taxi_app/common/extensions.dart';
import 'package:taxi_app/common/text_style.dart';

// ignore: must_be_immutable
class CustomTxtField1 extends StatelessWidget {
  CustomTxtField1({
    super.key,
    required this.controller,
    required this.hintText,
    required this.obscureText,
    required this.keyboardType,
    required this.errorText,
    required this.isObscure,
    this.onChanged,
  });

  final TextEditingController controller;
  final bool isObscure; // Assuming this is always true
  final String hintText;
  final String errorText;
  bool obscureText;
  final TextInputType keyboardType;
  final Function(String)? onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 78.h,
      child: TextFormField(
        onChanged: onChanged,
        controller: controller,
        cursorColor: KColor.primary,
        cursorHeight: 17.h,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: appStyle(
            size: 16.sp,
            color: KColor.primaryText,
            fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: KColor.lightGray, width: 2.w),
            borderRadius: BorderRadius.circular(15.r),
          ),
          disabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: KColor.lightGray, width: 2.w),
            borderRadius: BorderRadius.circular(15.r),
          ),
          suffixIcon: isObscure
              ? IconButton(
                  icon: Icon(
                    size: 18.sp,
                    obscureText ? Icons.visibility : Icons.visibility_off,
                    color: KColor.primary,
                  ),
                  onPressed: () {
                    // Toggle obscureText state
                    obscureText = !obscureText;
                    // Update the UI
                    (context as Element).markNeedsBuild();
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderSide: BorderSide(color: KColor.primary, width: 2.w),
            borderRadius: BorderRadius.circular(15.r),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: KColor.primary, width: 2.w),
            borderRadius: BorderRadius.circular(15.r),
          ),
          hintStyle: appStyle(
              size: 15.sp,
              color: KColor.placeholder,
              fontWeight: FontWeight.w600),
          hintText: hintText,
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return errorText;
          }
          return null;
        },
      ),
    );
  }
}
