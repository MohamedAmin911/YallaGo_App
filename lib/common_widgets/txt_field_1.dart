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
    this.validator, // ADDED: New optional validator parameter
  });

  final TextEditingController controller;
  final bool isObscure;
  final String hintText;
  final String errorText;
  bool obscureText;
  final TextInputType keyboardType;
  final Function(String)? onChanged;
  // ADDED: New optional validator property
  final String? Function(String?)? validator;

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
                    // Note: This toggle will not visually update correctly
                    // because this is a StatelessWidget.
                    obscureText = !obscureText;
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
              color: KColor.lightGray,
              fontWeight: FontWeight.w600),
          hintText: hintText,
        ),
        // --- THE EDIT IS HERE ---
        // It uses the provided validator if it exists, otherwise it falls back
        // to your original default validation logic.
        validator: validator ??
            (value) {
              if (value == null || value.isEmpty) {
                return errorText;
              }
              return null;
            },
      ),
    );
  }
}
