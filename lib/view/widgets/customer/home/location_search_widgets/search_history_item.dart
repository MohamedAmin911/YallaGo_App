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

  String _getTitle(Map<String, dynamic> item) {
    // Priority: main_text → structured_formatting.main_text → title → first chunk of address/description
    String? title = (item['title'] as String?)?.trim();

    if ((title == null || title.isEmpty) &&
        item['structured_formatting'] is Map) {
      final sf = item['structured_formatting'] as Map;
      title = (sf['main_text'] as String?)?.trim();
    }
    title ??= (item['title'] as String?)?.trim();

    if (title == null || title.isEmpty) {
      final addr = (item['address'] as String?)?.trim() ??
          (item['description'] as String?)?.trim();
      if (addr != null && addr.isNotEmpty) {
        final first = addr.split(',').first.trim();
        title = first.isEmpty ? 'Unknown place' : first;
      } else {
        title = 'Unknown place';
      }
    }
    return title;
  }

  String? _getSubtitle(Map<String, dynamic> item, String title) {
    // Subtitle must be the full description if available
    String? subtitle = (item['address'] as String?)?.trim();

    // Fallbacks if description missing
    subtitle ??= (item['subtitle'] as String?)?.trim();
    subtitle ??= (item['secondary_text'] as String?)?.trim();
    if (subtitle == null || subtitle.isEmpty) {
      subtitle = (item['address'] as String?)?.trim();
    }

    if (subtitle == null || subtitle.isEmpty) return null;

    // Avoid showing the same text twice
    if (subtitle.toLowerCase() == title.toLowerCase()) return null;

    return subtitle;
  }

  @override
  Widget build(BuildContext context) {
    final title = _getTitle(historyItem);
    final subtitle = _getSubtitle(historyItem, title);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 5.h),
      child: Material(
        borderRadius: BorderRadius.circular(22.r),
        child: ListTile(
          tileColor: KColor.bg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22.r),
          ),
          leading: Icon(
            Icons
                .history_toggle_off_rounded, // change to Icons.place_outlined if you prefer
            size: 30.sp,
            color: KColor.primary,
          ),
          title: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: appStyle(
              size: 16.sp,
              color: KColor.primaryText,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: (subtitle == null || subtitle.isEmpty)
              ? null
              : Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: appStyle(
                    size: 13.sp,
                    color: KColor.primaryText.withOpacity(0.6),
                    fontWeight: FontWeight.w400,
                  ),
                ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          onTap: onTap,
        ),
      ),
    );
  }
}
