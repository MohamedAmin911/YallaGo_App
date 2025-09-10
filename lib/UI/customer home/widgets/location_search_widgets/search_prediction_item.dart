import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:taxi_app/common/extensions.dart';

import 'package:taxi_app/common/text_style.dart';
import 'package:taxi_app/common/images.dart';

class SearchPredictionItem extends StatelessWidget {
  final Prediction prediction;
  final VoidCallback onTap;

  const SearchPredictionItem({
    super.key,
    required this.prediction,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 5.h),
      child: Material(
        borderRadius: BorderRadius.circular(22.r),
        child: ListTile(
          titleTextStyle: appStyle(
              size: 16.sp,
              color: KColor.primaryText,
              fontWeight: FontWeight.w500),
          tileColor: KColor.bg,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(22.r)),
          leading: Image.asset(
            KImage.destinationIcon,
            width: 30.w,
          ),
          title: Text(prediction.structuredFormatting?.mainText ?? ''),
          subtitle: Text(prediction.structuredFormatting?.secondaryText ?? ''),
          onTap: onTap,
        ),
      ),
    );
  }
}
