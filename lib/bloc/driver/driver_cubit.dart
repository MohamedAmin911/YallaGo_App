import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:taxi_app/bloc/driver/driver_states.dart';
import 'package:taxi_app/common/api_keys.dart';
import 'package:taxi_app/data_models/driver_model.dart';

class DriverCubit extends Cubit<DriverState> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  StreamSubscription? _driverSubscription;

  DriverCubit() : super(DriverInitial());

// Pipedream base (no trailing slash)
  final String base = 'https://eocyz9fe1kyb8l0.m.pipedream.net';

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'x-api-key': KapiKeys
            .pipedreamApiKey, // must match APP_API_KEY (env) in Pipedream
      };

  Future<Map<String, dynamic>> _postJson(
      String path, Map<String, dynamic> body) async {
    final res = await http.post(
      Uri.parse('$base$path'),
      headers: _headers,
      body: json.encode(body),
    );
    final raw = res.body.isEmpty ? '{}' : res.body;
    Map<String, dynamic> data;
    try {
      data = json.decode(raw) as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Bad JSON from $path: $raw');
    }
    if (data['ok'] == false) {
      throw Exception('API error on $path: ${data['error']}');
    }
    return data;
  }

  /// Creates a complete driver profile, including uploading images and saving to Firestore.
  Future<void> createDriverProfile({
    required String uid,
    required String email,
    required String phoneNumber,
    required String fullName,
    String? carModel,
    String? licensePlate,
    String? carColor,
    File? profileImageFile,
    File? carImageFile,
    required File nationalIdFile,
    required File driversLicenseFile,
    required File carLicenseFile,
    required File criminalRecordFile,
    required String stripeConnectAccountId,
  }) async {
    emit(DriverLoading());
    try {
      String? profileImageUrl,
          carImageUrl,
          nationalIdUrl,
          driversLicenseUrl,
          carLicenseUrl,
          criminalRecordUrl;
      // Upload files in parallel
      await Future.wait([
        if (profileImageFile != null)
          _uploadImageToCloudinary(profileImageFile, uid)
              .then((url) => profileImageUrl = url),
        if (carImageFile != null)
          _uploadImageToCloudinary(carImageFile, '${uid}_car')
              .then((url) => carImageUrl = url),
        _uploadImageToCloudinary(nationalIdFile, '${uid}_national_id')
            .then((url) => nationalIdUrl = url),
        _uploadImageToCloudinary(driversLicenseFile, '${uid}_drivers_license')
            .then((url) => driversLicenseUrl = url),
        _uploadImageToCloudinary(carLicenseFile, '${uid}_car_license')
            .then((url) => carLicenseUrl = url),
        _uploadImageToCloudinary(criminalRecordFile, '${uid}_criminal_record')
            .then((url) => criminalRecordUrl = url),
      ]);

      final newDriver = DriverModel(
        uid: uid,
        phoneNumber: phoneNumber,
        createdAt: Timestamp.now(),
        fullName: fullName,
        email: email,
        profileImageUrl: profileImageUrl,
        carModel: carModel ?? "",
        licensePlate: licensePlate ?? "",
        carColor: carColor ?? "",
        carImageUrl: carImageUrl,
        nationalIdUrl: nationalIdUrl,
        driversLicenseUrl: driversLicenseUrl,
        carLicenseUrl: carLicenseUrl,
        criminalRecordUrl: criminalRecordUrl,
        stripeConnectAccountId: stripeConnectAccountId,
      );

      // set() creates or overwrites (safe)
      await _db.collection('drivers').doc(uid).set(newDriver.toMap());
      emit(DriverProfileCreated());
    } catch (e) {
      emit(DriverError(message: "Failed to create driver profile: $e"));
    }
  }

  /// Create a Stripe Connect Express account. Returns acct_...; does NOT write to Firestore.
  Future<String?> createDriverConnectAccount({
    required String driverUid,
    required String email,
  }) async {
    emit(DriverLoading());
    try {
      final data = await _postJson('/connect_create_driver', {
        'email': email,
        'appDriverUid': driverUid,
      });

      final account = data['account'] as Map<String, dynamic>?;
      final accountId = account?['id'] as String?;
      if (accountId == null || accountId.isEmpty) {
        throw Exception('No account id in response: $data');
      }

      emit(DriverInitial());
      return accountId;
    } catch (e) {
      emit(DriverError(message: 'Failed to create Connect account: $e'));
      return null;
    }
  }

  /// Generate onboarding link for the driver account (open in WebView).
  Future<String?> createDriverOnboardingLink({
    required String accountId,
    required String returnUrl,
    required String refreshUrl,
  }) async {
    try {
      final data = await _postJson('/connect_account_link', {
        'accountId': accountId,
        'returnUrl': returnUrl,
        'refreshUrl': refreshUrl,
      });
      final link = data['link'] as Map<String, dynamic>?;
      return link?['url'] as String?;
    } catch (e) {
      emit(DriverError(message: 'Failed to create onboarding link: $e'));
      return null;
    }
  }

  Future<void> requestPayout({
    required String driverUid,
    required int amountCents, // e.g., 100.00 EGP => 10000
    String currency = 'usd', // or 'egp' for your tests
    int minThresholdCents = 5000, // e.g., $50
  }) async {
    try {
      if (amountCents <= 0) {
        emit(DriverError(message: 'Amount must be greater than 0.'));
        return;
      }

      emit(DriverLoading());

      final driverRef = _db.collection('drivers').doc(driverUid);

      await _db.runTransaction((tx) async {
        final snap = await tx.get(driverRef);
        if (!snap.exists) {
          throw Exception('Driver not found');
        }

        final data = snap.data() as Map<String, dynamic>;
        final stripeAccountId =
            (data['stripeConnectAccountId'] as String?) ?? '';
        final fullName = (data['fullName'] as String?) ?? 'Driver';

        final balanceDouble = ((data['balance'] ?? 0.0) as num).toDouble();
        final balanceCents = (balanceDouble * 100).round();

        if (stripeAccountId.isEmpty) {
          throw Exception('Stripe account not connected');
        }
        if (amountCents < minThresholdCents) {
          throw Exception('Below minimum payout amount');
        }
        if (amountCents > balanceCents) {
          throw Exception('Insufficient balance');
        }

        // Deduct immediately to avoid double spending
        final newBalanceCents = balanceCents - amountCents;
        final newBalance = newBalanceCents / 100.0;

        tx.update(driverRef, {'balance': newBalance});

        // Create payout request (root-level collection)
        final payoutRef = _db.collection('payouts').doc();
        tx.set(payoutRef, {
          'driverUid': driverUid,
          'driverName': fullName,
          'driverStripeAccountId': stripeAccountId,
          'amountCents': amountCents,
          'currency': currency,
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
          'balanceSnapshotCents': balanceCents,
        });
      });

      // Reload and emit updated driver
      final updatedSnap = await _db.collection('drivers').doc(driverUid).get();
      final updatedData = updatedSnap.data();
      if (updatedData == null) {
        emit(DriverError(message: 'Driver not found after payout request.'));
        return;
      }
      emit(DriverLoaded(driver: DriverModel.fromMap(updatedData)));
    } catch (e) {
      emit(DriverError(message: 'Payout request failed: $e'));
    }
  }

  /// Transfer funds (simulated in test mode) to the driver’s Connect account.
  Future<void> transferToDriver({
    required String accountId,
    required int amountCents,
    String currency = 'usd',
  }) async {
    try {
      final data = await _postJson('/connect_transfer_to_driver', {
        'destinationAccountId': accountId,
        'amountCents': amountCents,
        'currency': currency,
      });

      final transfer = data['transfer'] as Map<String, dynamic>?;
      if (transfer == null || transfer['id'] == null) {
        throw Exception('Transfer failed: $data');
      }
      // Optionally update internal ledger here (driver balance)
    } catch (e) {
      emit(DriverError(message: 'Transfer error: $e'));
    }
  }

  /// Upload to Cloudinary
  Future<String?> _uploadImageToCloudinary(
      File imageFile, String publicId) async {
    final url = Uri.parse(
      "https://api.cloudinary.com/v1_1/${KapiKeys.cloudinaryCloudName}/image/upload",
    );
    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = KapiKeys.cloudinaryUploadPreset
      ..fields['public_id'] = publicId
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    final response = await request.send();
    if (response.statusCode == 200) {
      final bytes = await response.stream.toBytes();
      final jsonMap = json.decode(String.fromCharCodes(bytes));
      return jsonMap['secure_url'] as String?;
    } else {
      final err = await response.stream.bytesToString();
      throw Exception('Cloudinary upload failed: $err');
    }
  }

  /// Check if a driver doc exists
  Future<bool> checkIfDriverExists(String uid) async {
    try {
      final doc = await _db.collection('drivers').doc(uid).get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  /// Listen to a driver doc
  void listenToDriver(String uid) {
    emit(DriverLoading());
    _driverSubscription?.cancel();
    _driverSubscription =
        _db.collection('drivers').doc(uid).snapshots().listen((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        final driver = DriverModel.fromMap(snapshot.data()!);
        emit(DriverLoaded(driver: driver));
      }
    }, onError: (error) {
      emit(DriverError(message: error.toString()));
    });
  }

  /// Update driver doc (requires doc to exist)
  Future<void> updateDriver(String uid, Map<String, dynamic> data) async {
    try {
      await _db.collection('drivers').doc(uid).update(data);
    } catch (e) {
      emit(DriverError(message: "Error updating driver: $e"));
    }
  }

  Future<void> addEarningsToBalance(String driverId, double earnings) async {
    try {
      await _db.collection('drivers').doc(driverId).update({
        'balance': FieldValue.increment(earnings),
      });
    } catch (e) {
// Swallow error in test; consider emitting state if needed
    }
  }

  Future<void> incrementTotalRides(String driverId) async {
    try {
      await _db.collection('drivers').doc(driverId).update({
        'totalRides': FieldValue.increment(1),
      });
    } catch (e) {
// Swallow error in test
    }
  }

  Future<void> updateDriverRating(String driverId, double newRating) async {
    final ref = _db.collection('drivers').doc(driverId);
    try {
      await _db.runTransaction((tx) async {
        final snap = await tx.get(ref);
        if (!snap.exists) throw Exception("Driver not found!");
        final driver = DriverModel.fromMap(snap.data()!);
        final oldRating = driver.rating;
        final totalRides = driver.totalRides;
        final avg = ((oldRating * totalRides) + newRating) / (totalRides + 1);
        tx.update(ref, {'rating': avg});
      });
    } catch (e) {
// Log only
    }
  }

  @override
  Future<void> close() {
    _driverSubscription?.cancel();
    return super.close();
  }
}
