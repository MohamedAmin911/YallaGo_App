import 'package:flutter/material.dart';

class KColor {
  static Color get primary => const Color(0xfffcbd01);
  static Color get secondary => const Color(0xFF5433FF);

  static Color get primaryText => const Color(0xff282F39);
  static Color get primaryTextW => const Color(0xffFFFFFF);
  static Color get secondaryText => const Color(0xff7F7F7F);
  static Color get placeholder => const Color(0xffBBBBBB);
  static Color get lightGray => const Color(0xffDADEE3);
  static Color get lightWhite => const Color(0xffF2F5F7);

  static Color get red => const Color.fromARGB(255, 223, 52, 75);

  static Color get bg => Colors.white;
}

extension AppContext on BuildContext {
  Size get size => MediaQuery.sizeOf(this);
  double get width => size.width;
  double get height => size.height;

  Future push(Widget widget) async {
    return Navigator.push(
      this,
      MaterialPageRoute(
        builder: (context) => widget,
      ),
    );
  }

  void pop() async {
    return Navigator.pop(this);
  }

  Future pushRlacement(Widget widget) async {
    return Navigator.pushReplacement(
      this,
      MaterialPageRoute(
        builder: (context) => widget,
      ),
    );
  }
}
