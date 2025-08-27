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
      final stripeCustomerId = await _ensureStripeCustomer(
        customerUid: customerUid,
        email: email,
        name: fullName,
        phone: phone,
      );

// Create SetupIntent
      final r = await http.post(
        Uri.parse('$base/create_setup_intent'),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': KapiKeys.pipedreamApiKey,
        },
        body: json.encode({'customerId': stripeCustomerId}),
      );
      final data = json.decode(r.body) as Map<String, dynamic>;
      final clientSecret = data['setupIntent']['client_secret'] as String;

// Confirm on device
      final billing =
          BillingDetails(name: fullName, email: email, phone: phone);
      final setupIntent = await Stripe.instance.confirmSetupIntent(
        paymentIntentClientSecret: clientSecret,
        params: PaymentMethodParams.card(
          paymentMethodData: PaymentMethodData(billingDetails: billing),
        ),
      );

// Find the saved PM
      String? createdPmId = setupIntent.paymentMethodId;
      Map<String, dynamic>? pm;

      final listRes = await http.post(
        Uri.parse('$base/list_payment_methods'),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': KapiKeys.pipedreamApiKey,
        },
        body: json.encode({'customerId': stripeCustomerId}),
      );
      final listData = json.decode(listRes.body) as Map<String, dynamic>;
      final pmList = (listData['paymentMethods'] as List?) ?? [];

      if (createdPmId.isNotEmpty) {
        pm = pmList.cast<Map<String, dynamic>?>().firstWhere(
              (e) => e?['id'] == createdPmId,
              orElse: () => null,
            );
      }
      if (pm == null) {
        if (pmList.isEmpty) {
          throw Exception('No payment methods found after setup.');
        }
        pmList.sort((a, b) =>
            ((b['created'] ?? 0) as int).compareTo((a['created'] ?? 0) as int));
        pm = pmList.first as Map<String, dynamic>;
        createdPmId = pm['id'] as String;
      }

      final brand = ((pm['card']?['brand'] as String?) ?? 'card').toUpperCase();
      final last4 = (pm['card']?['last4'] as String?) ?? '••••';

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
    }
  }

  Future<String?> stripeCharge({
    required String customerUid,
    required int amountCents,
    String currency = 'usd',
    String? paymentMethodId,
  }) async {
    emit(PaymentLoading());
    try {
      final userDoc = await _db.collection('customers').doc(customerUid).get();
      final stripeCustomerId = userDoc.data()?['stripeCustomerId'] as String?;
      if (stripeCustomerId == null) throw Exception('No stripeCustomerId');

      String pmId = paymentMethodId ?? '';
      if (pmId.isEmpty) {
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

      final data = json.decode(r.body) as Map<String, dynamic>;
      final pi = data['paymentIntent'] as Map<String, dynamic>?;
      if (pi == null || pi['status'] != 'succeeded') {
        throw Exception('Charge not succeeded');
      }
      final piId = pi['id'] as String;

// Optional: emit success; or keep as-is if UI doesn’t react here
// emit(PaymentSuccess(piId));
      emit(PaymentMethodAdded());
      return piId;
    } catch (e) {
      emit(PaymentError(message: 'Stripe charge failed: $e'));
      return null;
    }
  }

  Future<void> detachPaymentMethod({
    required String customerUid,
    required String paymentMethodId,
  }) async {
    emit(PaymentLoading());
    try {
// 1) Call Pipedream to detach from Stripe Customer (keeps Stripe clean)
      final res = await http.post(
        Uri.parse('$base/detach_payment_method'),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': KapiKeys.pipedreamApiKey,
        },
        body: json.encode({'paymentMethodId': paymentMethodId}),
      );
      final data = json.decode(res.body) as Map<String, dynamic>;
      if (data['ok'] == false) {
        throw Exception(data['error'] ?? 'Detach failed');
      }

// 2) Delete from Firestore
      final col = _db
          .collection('customers')
          .doc(customerUid)
          .collection('payment_methods');
      final docRef = col.doc(paymentMethodId);
      final doc = await docRef.get();
      final wasDefault = (doc.data()?['isDefault'] as bool?) ?? false;

      await docRef.delete();

// 3) If it was default, promote another one
      if (wasDefault) {
        final others = await col.limit(1).get();
        if (others.docs.isNotEmpty) {
          await col.doc(others.docs.first.id).update({'isDefault': true});
        }
      }

      emit(PaymentMethodAdded()); // reuse for "list changed"
    } catch (e) {
      emit(PaymentError(message: 'Detach failed: $e'));
    }
  }

  Future<void> setDefaultPaymentMethod({
    required String customerUid,
    required String paymentMethodId,
  }) async {
    emit(PaymentLoading());
    try {
      final col = _db
          .collection('customers')
          .doc(customerUid)
          .collection('payment_methods');
      final batch = _db.batch();

      final all = await col.get();
      for (final d in all.docs) {
        batch.update(d.reference, {'isDefault': d.id == paymentMethodId});
      }
      await batch.commit();

// Optional: set default on Stripe customer too (uncomment if you add the route)
// final userDoc = await _db.collection('customers').doc(customerUid).get();
// final customerId = userDoc.data()?['stripeCustomerId'] as String?;
// if (customerId != null) {
//   await http.post(
//     Uri.parse('$base/set_default_payment_method'),
//     headers: {'Content-Type': 'application/json', 'x-api-key': KapiKeys.pipedreamApiKey},
//     body: json.encode({'customerId': customerId, 'paymentMethodId': paymentMethodId}),
//   );
// }

      emit(PaymentMethodAdded());
    } catch (e) {
      emit(PaymentError(message: 'Set default failed: $e'));
    }
  }
}
