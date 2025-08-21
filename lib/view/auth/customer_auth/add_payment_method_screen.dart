import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taxi_app/bloc/payment/payment_method_cubit.dart';
import 'package:taxi_app/bloc/payment/payment_states.dart';
import 'package:taxi_app/common/extensions.dart';
import 'package:taxi_app/common_widgets/rounded_button.dart';
import 'package:taxi_app/view/auth/customer_auth/enter_mobile_number_login.dart';

class AddPaymentMethod extends StatelessWidget {
  final String email;
  final String phoneNumber;
  final String fullName;
  final String customerUid;

  const AddPaymentMethod({
    super.key,
    required this.email,
    required this.phoneNumber,
    required this.fullName,
    required this.customerUid,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Payment Method")),
      body: BlocListener<PaymentCubit, PaymentState>(
        listener: (context, state) {
          if (state is PaymentMethodAdded) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text(
                      "Card saved successfully! Please wait a moment for it to appear.")),
            );
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                  builder: (_) => const EnterMobileNumberViewLogin()),
              (route) => false,
            );
          } else if (state is PaymentError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(state.message), backgroundColor: Colors.red),
            );
          }
        },
        child: BlocBuilder<PaymentCubit, PaymentState>(
          builder: (context, state) {
            final isLoading = state is PaymentLoading;
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // CustomTxtField1(
                  //   controller: cardholderNameController,
                  //   hintText: "Cardholder Name",
                  // ),
                  const SizedBox(height: 40),
                  isLoading
                      ? const CircularProgressIndicator()
                      : RoundButton(
                          title: "CONTINUE TO SECURE FORM",
                          color: KColor.primary,
                          onPressed: () {
                            context.read<PaymentCubit>().saveCard(
                                  context,
                                  cardholderName: fullName,
                                  customerUid: customerUid,
                                  customerEmail: email,
                                  customerPhone: phoneNumber,
                                );
                          },
                        ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
