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

      // Upload all images in parallel for better performance
      await Future.wait([
        if (profileImageFile != null)
          _uploadImageToCloudinary(profileImageFile, uid)
              .then((url) => profileImageUrl = url),
        if (carImageFile != null)
          _uploadImageToCloudinary(carImageFile, '${uid}_car')
              .then((url) => carImageUrl = url),

        // --- NEW UPLOADS ---
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

      await _db.collection('drivers').doc(uid).set(newDriver.toMap());

      emit(DriverProfileCreated());
    } catch (e) {
      emit(DriverError(message: "Failed to create driver profile: $e"));
    }
  }

  /// Creates a real Stripe Connect account and returns the account ID.
  Future<String?> initiateStripeConnectOnboarding(
      {required String email, required String phone}) async {
    emit(DriverLoading());
    try {
      final response = await http.post(
        Uri.parse("https://api.stripe.com/v1/accounts"),
        headers: {
          'Authorization': 'Bearer ${KapiKeys.stripeSecretKey}',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'type': 'standard',
          'country': 'US',
          'email': email,
          'business_type': 'individual',
          'individual[email]': email,
          // 'individual[phone]': phone,
        },
      );

      if (response.statusCode == 200) {
        final accountData = json.decode(response.body);
        final accountId = accountData['id'];
        print("Successfully created Stripe Connect account: $accountId");
        return accountId;
      } else {
        // If the API call fails, throw an error
        final errorData = json.decode(response.body);
        print(
            'Failed to create Stripe account: ${errorData['error']['message']}');
        throw Exception(
            'Failed to create Stripe account: ${errorData['error']['message']}');
      }
    } catch (e) {
      // --- THE FIX IS HERE ---
      // Emit an error state so the UI stops loading and shows the message.
      emit(DriverError(message: e.toString()));
      return null; // Return null to indicate failure.
    }
  }

  /// Private helper to upload an image to Cloudinary and return the secure URL.
  Future<String?> _uploadImageToCloudinary(
      File imageFile, String publicId) async {
    final url = Uri.parse(
        "https://api.cloudinary.com/v1_1/${KapiKeys.cloudinaryCloudName}/image/upload");
    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = KapiKeys.cloudinaryUploadPreset
      ..fields['public_id'] = publicId // Use the UID as the filename
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    final response = await request.send();
    if (response.statusCode == 200) {
      final responseData = await response.stream.toBytes();
      final responseString = String.fromCharCodes(responseData);
      final jsonMap = json.decode(responseString);
      return jsonMap['secure_url'];
    } else {
      print('Cloudinary Error: ${await response.stream.bytesToString()}');
      throw Exception('Failed to upload image to Cloudinary.');
    }
  }

  /// Checks if a driver document exists in Firestore for a given UID.
  Future<bool> checkIfDriverExists(String uid) async {
    print("Checking if driver exists: $uid");
    try {
      final doc = await _db.collection('drivers').doc(uid).get();
      return doc.exists;
    } catch (e) {
      print("Error checking if driver exists: $e");
      return false;
    }
  }

  /// Listens to real-time updates for a specific driver.
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

  /// Updates a driver's document with the given data.
  Future<void> updateDriver(String uid, Map<String, dynamic> data) async {
    try {
      await _db.collection('drivers').doc(uid).update(data);
    } catch (e) {
      emit(DriverError(message: "Error updating driver: $e"));
    }
  }

  @override
  Future<void> close() {
    _driverSubscription?.cancel();
    return super.close();
  }
}
