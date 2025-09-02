import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:taxi_app/common/extensions.dart';
import 'package:taxi_app/common/text_style.dart';

enum RoundButtonType { primary, secondary, red, boarded }

class RoundButton extends StatelessWidget {
  final String title;
  final RoundButtonType type;
  final double? size;
  final FontWeight? fontWeight;
  final VoidCallback onPressed;
  final Color color;
  const RoundButton(
      {super.key,
      required this.title,
      this.type = RoundButtonType.primary,
      this.size,
      this.fontWeight,
      required this.onPressed,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return MaterialButton(
      onPressed: onPressed,
      minWidth: double.maxFinite,
      elevation: 0,
      color: color,
      height: 45.h,
      shape: RoundedRectangleBorder(
          side: type == RoundButtonType.boarded
              ? BorderSide(color: KColor.secondaryText)
              : BorderSide.none,
          borderRadius: BorderRadius.circular(25.r)),
      child: Text(
        title,
        style: appStyle(
          color: type == RoundButtonType.boarded
              ? KColor.secondaryText
              : KColor.primaryTextW,
          size: size ?? 16.r,
          fontWeight: fontWeight ?? FontWeight.w600,
        ),
      ),
    );
  }
}
