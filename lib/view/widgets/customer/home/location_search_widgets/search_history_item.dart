import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:taxi_app/common/text_style.dart';
import 'package:taxi_app/common/extensions.dart';

class SearchHistoryItem extends StatelessWidget {
  final Map<String, dynamic> historyItem;
  final VoidCallback onTap;

  const SearchHistoryItem({
    super.key,
    required this.historyItem,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 5.h),
      child: Material(
        elevation: 0.2,
        borderRadius: BorderRadius.circular(22.r),
        child: ListTile(
          titleTextStyle: appStyle(
              size: 16.sp,
              color: KColor.primaryText,
              fontWeight: FontWeight.w500),
          tileColor: KColor.lightWhite.withOpacity(0.2),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(22.r)),
          leading: Icon(
            size: 40.sp,
            Icons.history,
            color: KColor.primary,
          ),
          title: Text(historyItem['address'] ?? 'Unknown Address'),
          onTap: onTap,
        ),
      ),
    );
  }
}
