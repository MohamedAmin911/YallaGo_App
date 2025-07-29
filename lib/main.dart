import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:taxi_app/bloc/auth/auth_cubit.dart';
import 'package:taxi_app/bloc/customer/customer_cubit.dart';
import 'package:taxi_app/bloc/payment/payment_method_cubit.dart';
import 'package:taxi_app/common/api_keys.dart';
import 'package:taxi_app/common/extensions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:taxi_app/view/auth/splash_view.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await Future.delayed(const Duration(seconds: 2));
  FlutterNativeSplash.remove();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.leanBack);
  Stripe.publishableKey = KapiKeys.stripePublishableKey;
  await Stripe.instance.applySettings();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>(create: (context) => AuthCubit()),
        BlocProvider<CustomerCubit>(create: (context) => CustomerCubit()),
        BlocProvider<PaymentCubit>(create: (context) => PaymentCubit()),
      ],
      child: ScreenUtilInit(
          designSize: Size(MediaQuery.of(context).copyWith().size.width,
              MediaQuery.of(context).copyWith().size.height),
          minTextAdapt: true,
          splitScreenMode: true,
          builder: (_, child) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'Taxi App',
              theme: ThemeData(
                fontFamily: "NunitoSans",
                scaffoldBackgroundColor: KColor.bg,
                colorScheme: ColorScheme.fromSeed(seedColor: KColor.primary),
                useMaterial3: false,
              ),
              home: const SplashScreen(),
              // const AuthGate(),
            );
          }),
    );
  }
}
