import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:taxi_app/bloc/payment/payment_states.dart';
import 'package:taxi_app/common/api_keys.dart';
import 'package:taxi_app/view/payment/paymob_webview_screen.dart';

class PaymentCubit extends Cubit<PaymentState> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  PaymentCubit() : super(PaymentInitial());

  /// Handles the entire process of saving a customer's card with Paymob.
  Future<void> saveCard(
    BuildContext context, {
    required String cardholderName,
    required String customerUid,
    required String customerEmail,
    required String customerPhone,
  }) async {
    emit(PaymentLoading());
    try {
      // Step 1: Get an authentication token from Paymob.
      final authResponse = await http.post(
        Uri.parse("https://accept.paymob.com/api/auth/tokens"),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({"api_key": KapiKeys.payMobApiKey}),
      );
      final authToken = json.decode(authResponse.body)['token'];

      // Step 2: Register an order with Paymob.
      final orderResponse = await http.post(
        Uri.parse("https://accept.paymob.com/api/ecommerce/orders"),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          "auth_token": authToken,
          "delivery_needed": "false",
          "amount_cents": "100", // A small amount to authorize the card
          "currency": "EGP",
        }),
      );
      final orderId = json.decode(orderResponse.body)['id'];

      // Step 2.5: Create the temporary lookup document in Firestore.
      await _db.collection('paymob_orders').doc(orderId.toString()).set({
        'customerUid': customerUid,
      });

      // Step 3: Get a temporary Payment Key for the WebView.
      final paymentKeyResponse = await http.post(
        Uri.parse("https://accept.paymob.com/api/acceptance/payment_keys"),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          "auth_token": authToken,
          "amount_cents": "100",
          "order_id": orderId,
          "expiration": 3600,
          "billing_data": {
            "email": customerEmail,
            "phone_number": customerPhone,
            "first_name": cardholderName,
            "last_name": "NA",
            "apartment": customerUid,
            "floor": "NA",
            "street": "NA",
            "building": "NA",
            "shipping_method": "NA",
            "postal_code": "NA",
            "city": "NA",
            "country": "EG",
            "state": "NA"
          },
          "currency": "EGP",
          "integration_id": KapiKeys.payMobIntegrationId,
        }),
      );

      // --- THE FIX IS HERE ---
      // We now check the response and print the error if it fails.
      final paymentKeyResponseData = json.decode(paymentKeyResponse.body);

      if (paymentKeyResponse.statusCode != 201) {
        // If the status code is not 201 (Created), something went wrong.
        print("Paymob Payment Key Error: ${paymentKeyResponse.body}");
        throw Exception(
            "Failed to get payment token from Paymob: ${paymentKeyResponseData['message'] ?? 'Unknown error'}");
      }

      final paymentToken = paymentKeyResponseData['token'];
      // --- END FIX ---

      // Step 4: Navigate to the WebView. The webhook will handle saving the card.
      final result = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => PaymobWebViewScreen(paymentToken: paymentToken),
        ),
      );

      if (result == true) {
        // The user successfully entered their card. Now we wait for the webhook.
        emit(PaymentMethodAdded());
      } else {
        throw Exception("Card process was cancelled or failed.");
      }
    } catch (e) {
      emit(PaymentError(message: "Failed to save card: ${e.toString()}"));
    }
  }
}
