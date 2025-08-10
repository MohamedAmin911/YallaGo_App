import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:taxi_app/bloc/auth/auth_cubit.dart';
import 'package:taxi_app/bloc/auth/auth_states.dart';
import 'package:taxi_app/bloc/payment/payment_method_cubit.dart';
import 'package:taxi_app/bloc/payment/payment_states.dart';
import 'package:taxi_app/common/extensions.dart';
import 'package:taxi_app/common/images.dart';
import 'package:taxi_app/common/text_style.dart';
import 'package:taxi_app/common_widgets/rounded_button.dart';
import 'package:taxi_app/common_widgets/txt_field_1.dart';
import 'package:taxi_app/view/customer%20home/customer_home_screen.dart';

class AddPaymentMethod extends StatefulWidget {
  const AddPaymentMethod({super.key});

  @override
  State<AddPaymentMethod> createState() => _AddPaymentMethodState();
}

class _AddPaymentMethodState extends State<AddPaymentMethod> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _cardholderNameController =
      TextEditingController();
  final _cardFieldController = CardEditController();
  @override
  void dispose() {
    _cardholderNameController.dispose();
    _cardFieldController.dispose();
    super.dispose();
  }

  void _submitCard() {
    FocusScope.of(context).unfocus();
    if (_cardholderNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please fill in all fields.")));
      return;
    }
    if (!_cardFieldController.complete) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enter all card details.")));
      return;
    }

    final authState = context.read<AuthCubit>().state;
    if (authState is AuthLoggedIn) {
      context.read<PaymentCubit>().createCustomerAndAttachCard(
            customerUid: authState.user.uid,
            cardholderName: _cardholderNameController.text.trim(),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: context.pop,
          icon: Icon(
            Icons.arrow_back_ios,
            color: KColor.primaryText,
          ),
        ),
      ),
      body: BlocConsumer<PaymentCubit, PaymentState>(
        listener: (context, state) {
          if (state is PaymentMethodAdded) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Card added successfully!")),
            );
            // Navigate to the home screen after successfully adding a card
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const HomeScreen()),
              (route) => false,
            );
          } else if (state is PaymentError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is PaymentLoading;
          return SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 22.h),
                    // Title
                    Text(
                      "Add Payment Method",
                      style: appStyle(
                        size: 25.sp,
                        color: KColor.primaryText,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    SizedBox(height: 50.h),
                    Center(
                      child: Image.asset(
                        KImage.paymentIcon,
                        width: 140.w,
                      ),
                    ),
                    SizedBox(height: 50.h),

                    // Cardholder Name
                    CustomTxtField1(
                      controller: _cardholderNameController,
                      hintText: "Cardholder Name",
                      obscureText: false,
                      keyboardType: TextInputType.name,
                      errorText: "Please enter the cardholder name",
                      isObscure: false,
                    ),
                    SizedBox(height: 18.h),
                    // Stripe Payment Method Form
                    CardField(
                      controller: _cardFieldController,
                      decoration: InputDecoration(
                        hintStyle: appStyle(
                          size: 14.sp,
                          color: KColor.placeholder,
                          fontWeight: FontWeight.w500,
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: KColor.lightGray, width: 2.w),
                          borderRadius: BorderRadius.circular(15.r),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: const Color(0xFF5433FF), width: 2.w),
                          borderRadius: BorderRadius.circular(15.r),
                        ),
                        disabledBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: KColor.lightGray, width: 2.w),
                          borderRadius: BorderRadius.circular(15.r),
                        ),
                        border: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: KColor.lightWhite, width: 2.w),
                          borderRadius: BorderRadius.circular(15.r),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: KColor.lightGray, width: 2.w),
                          borderRadius: BorderRadius.circular(15.r),
                        ),
                        labelText: 'Card Number, MM/YY, CVC',
                        labelStyle: appStyle(
                            size: 16.sp,
                            color: const Color(0xFF5433FF),
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                    SizedBox(height: 15.h),
                    //powered by Stripe
                    Row(
                      children: [
                        const Spacer(),
                        Text(
                          "Powered by",
                          style: appStyle(
                            size: 12.sp,
                            color: KColor.secondaryText,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(width: 5.h),
                        Image.asset(
                          KImage.stripeLogo,
                          width: 40.w,
                        ),
                        SizedBox(width: 8.h),
                      ],
                    ),

                    SizedBox(height: 40.h),

                    // Save Card Button
                    isLoading
                        ? Center(
                            child: CircularProgressIndicator(
                            color: KColor.primary,
                          ))
                        : RoundButton(
                            color: KColor.primary,
                            title: "SAVE CARD",
                            onPressed: _submitCard,
                          ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
