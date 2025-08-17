import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:taxi_app/bloc/customer/customer_states.dart';
import 'package:taxi_app/common/api_keys.dart';
import 'package:taxi_app/data_models/customer_model.dart';

class CustomerCubit extends Cubit<CustomerState> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  StreamSubscription? _customerSubscription;

  CustomerCubit() : super(CustomerInitial());

  Future<String> getCurrentAddress() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    final Position position = await Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    ).first;

    final List<Placemark> placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );

    if (placemarks.isNotEmpty) {
      final Placemark place = placemarks.first;
      return "${place.street}, ${place.locality}, ${place.country}";
    } else {
      throw Exception("Could not determine address from location.");
    }
  }

  Future<void> createCustomerProfile({
    required String uid,
    required String phoneNumber,
    required String fullName,
    required String email,
    required String homeAddress,
    required String password,
    File? imageFile,
  }) async {
    emit(CustomerLoading());
    try {
      String? profileImageUrl;

      if (imageFile != null) {
        profileImageUrl = await _uploadImageToCloudinary(imageFile, uid);
      }

      final newCustomer = CustomerModel(
        uid: uid,
        phoneNumber: phoneNumber,
        createdAt: Timestamp.now(),
        fullName: fullName,
        email: email,
        profileImageUrl: profileImageUrl,
        homeAddress: homeAddress,
      );

      // 3. Save the customer data to Firestore
      await _db.collection('customers').doc(uid).set(newCustomer.toMap());

      emit(CustomerProfileCreated()); // Emit success state
    } catch (e) {
      emit(CustomerError(message: "Failed to create profile: $e"));
      print(e);
    }
  }

  Future<bool> checkIfUserExists(String uid) async {
    try {
      final doc = await _db.collection('customers').doc(uid).get();
      return doc.exists;
    } catch (e) {
      // If there's an error, assume the user doesn't exist to be safe.
      print("Error checking if user exists: $e");
      return false;
    }
  }

  Future<String?> _uploadImageToCloudinary(
      File imageFile, String publicId) async {
    final url = Uri.parse(
        "https://api.cloudinary.com/v1_1/${KapiKeys.cloudinaryCloudName}/image/upload");
    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = KapiKeys.cloudinaryUploadPreset
      ..fields['public_id'] = publicId // Set the public_id to the user's uid
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

  void listenToCustomer(String uid) {
    emit(CustomerLoading());
    _customerSubscription?.cancel();
    _customerSubscription =
        _db.collection('customers').doc(uid).snapshots().listen((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        final customer = CustomerModel.fromMap(snapshot.data()!);
        emit(CustomerLoaded(customer: customer));
      } else {
        // This case can happen if the user is authenticated but their document doesn't exist yet.
        emit(CustomerInitial());
      }
    }, onError: (error) {
      emit(CustomerError(message: error.toString()));
    });
  }

  Future<void> updateCustomer(String uid, Map<String, dynamic> data) async {
    try {
      await _db.collection('customers').doc(uid).update(data);
      // No need to emit a new state, the stream will do it automatically.
    } catch (e) {
      emit(CustomerError(message: "Error updating customer: $e"));
    }
  }

  Future<void> addSearchToHistory(
      String uid, Map<String, dynamic> newSearch) async {
    final docRef = _db.collection('customers').doc(uid);
    try {
      final doc = await docRef.get();
      if (doc.exists) {
        final customer = CustomerModel.fromMap(doc.data()!);
        List<Map<String, dynamic>> history = customer.searchHistory ?? [];

        // Add a timestamp to the new search entry
        newSearch['timestamp'] = Timestamp.now();

        // Prevent duplicates by removing any existing entry with the same address
        history.removeWhere((item) => item['address'] == newSearch['address']);

        // Add the new search to the beginning of the list
        history.insert(0, newSearch);

        // Keep only the last 5 searches
        if (history.length > 5) {
          history = history.sublist(0, 5);
        }

        // Update the document in Firestore
        await docRef.update({'searchHistory': history});
      }
    } catch (e) {
      print("Error adding to search history: $e");
      // You could emit an error state here if you want to notify the user
    }
  }

  /// Increments the totalRides count for a customer.
  Future<void> incrementTotalRides(String customerId) async {
    try {
      await _db.collection('customers').doc(customerId).update({
        'totalRides': FieldValue.increment(1),
      });
    } catch (e) {
      print("Error incrementing customer rides: $e");
    }
  }

  @override
  Future<void> close() {
    _customerSubscription?.cancel();
    return super.close();
  }
}
