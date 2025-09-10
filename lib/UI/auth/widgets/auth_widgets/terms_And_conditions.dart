import 'package:flutter/material.dart';
import 'package:taxi_app/common/extensions.dart';
import 'package:taxi_app/common/text_style.dart';

class TermsAndConditions extends StatelessWidget {
  const TermsAndConditions({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: const TextStyle(fontSize: 18, color: Colors.black),
          children: [
            TextSpan(
              text:
                  'By continuing, I confirm that i have read & agree to the\n',
              style: appStyle(
                  size: 11,
                  color: KColor.placeholder,
                  fontWeight: FontWeight.w400),
            ),
            WidgetSpan(
              child: GestureDetector(
                onTap: () {
                  print('Button clicked!');
                },
                child: Text(
                  'Terms & conditions',
                  style: appStyle(
                      size: 11,
                      color: KColor.primaryText,
                      fontWeight: FontWeight.w400),
                ),
              ),
            ),
            TextSpan(
              text: ' and ',
              style: appStyle(
                  size: 11,
                  color: KColor.placeholder,
                  fontWeight: FontWeight.w400),
            ),
            WidgetSpan(
              child: GestureDetector(
                onTap: () {
                  print('Button clicked!');
                },
                child: Text(
                  'Privacy policy',
                  style: appStyle(
                      size: 11,
                      color: KColor.primaryText,
                      fontWeight: FontWeight.w400),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
