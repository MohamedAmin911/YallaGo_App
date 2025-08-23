import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'package:taxi_app/common/api_keys.dart';
import 'payment_states.dart';

class PaymentCubit extends Cubit<PaymentState> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  PaymentCubit() : super(PaymentInitial());

  final String base =
      'https://eocyz9fe1kyb8l0.m.pipedream.net'; // root for your endpoints

  Future<String> _ensureStripeCustomer({
    required String customerUid,
    required String email,
    required String name,
    required String phone,
  }) async {
    // Try to read existing stripeCustomerId
    final doc = await _db.collection('customers').doc(customerUid).get();
    final existing = doc.data()?['stripeCustomerId'] as String?;
    if (existing != null && existing.isNotEmpty) return existing;

    final r = await http.post(
      Uri.parse('$base/create_stripe_customer'),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': KapiKeys.pipedreamApiKey,
      },
      body: json.encode({
        'email': email,
        'name': name,
        'phone': phone,
        'appCustomerUid': customerUid,
      }),
    );
    final data = json.decode(r.body);
    final customerId = data['customer']['id'];
    await _db.collection('customers').doc(customerUid).update({
      'stripeCustomerId': customerId,
    });
    return customerId;
  }

  Future<void> stripeSaveCard({
    required String customerUid,
    required String fullName,
    required String email,
    required String phone,
  }) async {
    emit(PaymentLoading());
    try {
      // 1) Ensure Stripe customer
      final stripeCustomerId = await _ensureStripeCustomer(
        customerUid: customerUid,
        email: email,
        name: fullName,
        phone: phone,
      );

      // 2) Create SetupIntent
      final r = await http.post(
        Uri.parse('$base/create_setup_intent'),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': KapiKeys.pipedreamApiKey,
        },
        body: json.encode({'customerId': stripeCustomerId}),
      );
      final data = json.decode(r.body);
      final clientSecret = data['setupIntent']['client_secret'] as String;

      // 3) Confirm SetupIntent with the card entered in CardField
      final billing = BillingDetails(
        name: fullName,
        email: email,
        phone: phone,
      );

      // Correct call: first arg is the clientSecret (positional), not named
      final setupIntent = await Stripe.instance.confirmSetupIntent(
        paymentIntentClientSecret: clientSecret,
        params: PaymentMethodParams.card(
          paymentMethodData: PaymentMethodData(
            billingDetails: billing, // now 'billing' is used
          ),
        ),
      );

      // 4) Get the created payment method (prefer the one returned from setupIntent)
      String? createdPmId = setupIntent.paymentMethodId;

      Map<String, dynamic>? pm; // Stripe PM object (to get brand/last4)
      if (createdPmId.isNotEmpty) {
        // Fetch the PM details from your backend or list and pick by id
        final listRes = await http.post(
          Uri.parse('$base/list_payment_methods'),
          headers: {
            'Content-Type': 'application/json',
            'x-api-key': KapiKeys.pipedreamApiKey,
          },
          body: json.encode({'customerId': stripeCustomerId}),
        );
        final listData = json.decode(listRes.body);
        final pmList = (listData['paymentMethods'] as List?) ?? [];
        pm = pmList
            .cast<Map<String, dynamic>?>()
            .firstWhere((e) => e?['id'] == createdPmId, orElse: () => null);
        // Fallback: if not found by id (rare), pick newest
        pm ??= (pmList.isNotEmpty)
            ? (pmList
                  ..sort((a, b) => ((b['created'] ?? 0) as int)
                      .compareTo((a['created'] ?? 0) as int)))
                .first
            : null;
        createdPmId = pm?['id'] ?? createdPmId; // keep id
      } else {
        // No id on setupIntent (older plugin versions) → list and pick newest
        final listRes = await http.post(
          Uri.parse('$base/list_payment_methods'),
          headers: {
            'Content-Type': 'application/json',
            'x-api-key': KapiKeys.pipedreamApiKey,
          },
          body: json.encode({'customerId': stripeCustomerId}),
        );
        final listData = json.decode(listRes.body);
        final pmList = (listData['paymentMethods'] as List?) ?? [];
        if (pmList.isEmpty)
          throw Exception('No payment methods found after setup.');
        pmList.sort((a, b) {
          final ta = (a['created'] as int?) ?? 0;
          final tb = (b['created'] as int?) ?? 0;
          return tb.compareTo(ta);
        });
        pm = pmList.first as Map<String, dynamic>;
        createdPmId = pm['id'] as String;
      }

      final brand =
          ((pm?['card']?['brand'] as String?) ?? 'card').toUpperCase();
      final last4 = (pm?['card']?['last4'] as String?) ?? '••••';

      // 5) Save to Firestore subcollection
      await _db
          .collection('customers')
          .doc(customerUid)
          .collection('payment_methods')
          .doc(createdPmId)
          .set({
        'paymentMethodId': createdPmId,
        'cardBrand': brand,
        'last4': last4,
        'isDefault': true,
        'addedAt': Timestamp.now(),
      }, SetOptions(merge: true));

      emit(PaymentMethodAdded());
    } catch (e) {
      emit(PaymentError(message: 'Stripe save card failed: $e'));
      print('Stripe save card failed: $e');
    }
  }

  Future<void> stripeCharge({
    required String customerUid,
    required int amountCents, // e.g., 500 = $5.00
    String currency = 'usd',
    String? paymentMethodId, // if null, fetch default (first)
  }) async {
    emit(PaymentLoading());
    try {
      final userDoc = await _db.collection('customers').doc(customerUid).get();
      final stripeCustomerId = userDoc.data()?['stripeCustomerId'] as String?;
      if (stripeCustomerId == null) throw Exception('No stripeCustomerId');

      String pmId = paymentMethodId ?? '';
      if (pmId.isEmpty) {
        // get first saved pm from Firestore
        final pmSnap = await _db
            .collection('customers')
            .doc(customerUid)
            .collection('payment_methods')
            .limit(1)
            .get();
        if (pmSnap.docs.isEmpty) throw Exception('No saved payment method');
        pmId = pmSnap.docs.first.id;
      }

      final r = await http.post(
        Uri.parse('$base/charge_saved_card'),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': KapiKeys.pipedreamApiKey,
        },
        body: json.encode({
          'customerId': stripeCustomerId,
          'paymentMethodId': pmId,
          'amountCents': amountCents,
          'currency': currency,
        }),
      );
      final data = json.decode(r.body);
      if (data['paymentIntent']?['status'] != 'succeeded') {
        throw Exception('Charge not succeeded');
      }

      emit(PaymentMethodAdded()); // or new PaymentSuccess state if you add it
    } catch (e) {
      emit(PaymentError(message: 'Stripe charge failed: $e'));
    }
  }
}
