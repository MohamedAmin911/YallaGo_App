import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:taxi_app/common/text_style.dart';
import 'package:taxi_app/common/extensions.dart';

class PhoneNumberInputField extends StatelessWidget {
  final ValueChanged<CountryCode> onCountryChanged;
  final TextEditingController phoneController;

  const PhoneNumberInputField({
    super.key,
    required this.onCountryChanged,
    required this.phoneController,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Country Code Picker
          CountryCodePicker(
            flagWidth: 30.w,
            pickerStyle: PickerStyle.bottomSheet,
            padding: EdgeInsets.only(top: 10.h),
            margin: EdgeInsets.only(right: 10.w),
            flagDecoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5.r),
            ),
            onChanged: onCountryChanged,
            initialSelection: 'EG', // Set initial selection to Egypt
            favorite: const ['+20', 'EG'],
            showDropDownButton: false,
            dialogTextStyle: appStyle(
              size: 15,
              color: KColor.primaryText,
              fontWeight: FontWeight.w400,
            ),
            dialogItemPadding: EdgeInsets.only(left: 20.w),
            showCountryOnly: false,
            showOnlyCountryWhenClosed: false,
            alignLeft: false,
            barrierColor: KColor.lightGray.withOpacity(0.5),
            hideSearch: true,
            textStyle: appStyle(
              // Style for the selected code in the UI
              size: 16,
              color: KColor.primaryText,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(width: 15.w),
          // Phone Number Field
          Expanded(
            child: TextFormField(
              style: appStyle(
                size: 17.sp,
                color: KColor.primaryText,
                fontWeight: FontWeight.bold,
              ).copyWith(letterSpacing: 1.sp),
              controller: phoneController,
              cursorColor: KColor.primaryText,
              cursorHeight: 17.h,
              decoration: InputDecoration(
                helperText: ' ',
                errorStyle: appStyle(
                  size: 14,
                  color: KColor.red,
                  fontWeight: FontWeight.w400,
                ),
                hintText: 'Enter your phone number',
                hintStyle: appStyle(
                  size: 15.sp,
                  color: KColor.placeholder,
                  fontWeight: FontWeight.w400,
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.r),
                  borderSide: BorderSide(
                    color: KColor.lightGray,
                    width: 2.w,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.r),
                  borderSide: BorderSide(
                    color: KColor.primary,
                    width: 2.w,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.r),
                  borderSide: BorderSide(
                    color: KColor.lightGray,
                    width: 1.w,
                  ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.r),
                  borderSide: BorderSide(
                    color: KColor.primary,
                    width: 1.w,
                  ),
                ),
                filled: false,
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Phone number is required';
                }
                // New check: Ensure the input contains only digits
                final isDigitsOnly = RegExp(r'^[0-9]+$').hasMatch(value);
                if (!isDigitsOnly) {
                  return 'Only digits are allowed';
                }
                // Simple validation for length, adjust for your needs
                if (value.length < 9 || value.length > 11) {
                  return 'Invalid phone number length';
                }
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }
}
