import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:taxi_app/common/extensions.dart';

import 'package:taxi_app/common/text_style.dart';

Widget buildLocationField({
  required String text,
  bool isHint = false,
  required VoidCallback onTap,
}) {
  final controller = TextEditingController(text: text);

  return TextField(
    maxLines: 1,
    textAlign: TextAlign.left,
    controller: controller,
    readOnly: true,
    onTap: onTap,
    decoration: InputDecoration(
      fillColor: KColor.lightGray.withOpacity(0.3),
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22.r),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      hintText: isHint ? text : null,
      hintStyle: appStyle(
        size: 16.sp,
        color: KColor.placeholder,
        fontWeight: FontWeight.w500,
      ),
    ),
    style: appStyle(
      size: 16.sp,
      color: isHint ? KColor.placeholder : KColor.primaryText,
      fontWeight: FontWeight.w500,
    ),
  );
}
