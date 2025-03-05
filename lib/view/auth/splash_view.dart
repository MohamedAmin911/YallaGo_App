// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:taxi_app/common/extensions.dart';
import 'package:taxi_app/common/images.dart';
import 'package:taxi_app/view/auth/change_language_view.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  @override
  void initState() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.leanBack);
    super.initState();
    load();
  }

//wait 3 sec then push to next screen
  void load() async {
    await Future.delayed(const Duration(seconds: 3));
    context.push(const ChangeLanguageView());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            color: TColor.primary,
            width: context.width,
            height: context.height,
            child: Image.asset(
              TImage.logo,
              width: context.width * 0.25,
            ),
          )
        ],
      ),
    );
  }
}
