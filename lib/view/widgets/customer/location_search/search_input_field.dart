import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:taxi_app/common_widgets/txt_field_1.dart';

class SearchInputField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const SearchInputField({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 16.w, right: 16.w, top: 40.h),
      child: CustomTxtField1(
        onChanged: onChanged,
        controller: controller,
        hintText: "Search for a location...",
        obscureText: false,
        keyboardType: TextInputType.text,
        errorText: "Please enter a valid location",
        isObscure: false,
      ),
    );
  }
}
