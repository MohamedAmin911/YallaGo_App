import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:taxi_app/common/extensions.dart';
import 'package:taxi_app/common/text_style.dart';

class ChangeLanguageView extends StatefulWidget {
  const ChangeLanguageView({super.key});

  @override
  State<ChangeLanguageView> createState() => _ChangeLanguageViewState();
}

class _ChangeLanguageViewState extends State<ChangeLanguageView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.only(left: 24.w, top: 62.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Change Language",
              style: appStyle(
                  size: 25,
                  color: KColor.primaryText,
                  fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 19.h),
            ListTile(
              selectedColor: KColor.primary,
              selected: true,
              title: Text(
                "English",
                style: appStyle(
                    size: 16,
                    color: KColor.primary,
                    fontWeight: FontWeight.w500),
              ),
              trailing: Icon(
                Icons.check_rounded,
                size: 20.sp,
                color: KColor.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
