import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a driver in the application.
class DriverModel {
  // --- Core Identification ---
  final String uid;
  final String phoneNumber;
  final Timestamp createdAt;

  // --- Profile Information ---
  final String fullName;
  final String? email;
  final String? profileImageUrl;

  // --- Vehicle Information ---
  final String carModel;
  final String licensePlate;
  final String carColor;
  final String? carImageUrl;

  // --- NEW: Legal Document URLs ---
  final String? nationalIdUrl;
  final String? driversLicenseUrl;
  final String? carLicenseUrl;
  final String? criminalRecordUrl;

  // --- Driver Status & Stats ---
  final String status;
  final bool isOnline;
  final double rating;
  final int totalRides;
  final double balance;

  // --- Real-time Data ---
  final GeoPoint? currentLocation;
  final double? heading;

  // --- Technical Metadata ---
  final String? fcmToken;

  final String? stripeConnectAccountId;

  DriverModel({
    required this.uid,
    required this.phoneNumber,
    required this.createdAt,
    required this.fullName,
    this.email,
    this.profileImageUrl,
    required this.carModel,
    required this.licensePlate,
    required this.carColor,
    this.carImageUrl,
    this.nationalIdUrl,
    this.driversLicenseUrl,
    this.carLicenseUrl,
    this.criminalRecordUrl,
    this.status = "pending_approval",
    this.isOnline = false,
    this.rating = 5.0,
    this.totalRides = 0,
    this.currentLocation,
    this.heading,
    this.fcmToken,
    this.stripeConnectAccountId,
    this.balance = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'phoneNumber': phoneNumber,
      'createdAt': createdAt,
      'fullName': fullName,
      'email': email,
      'profileImageUrl': profileImageUrl,
      'carModel': carModel,
      'licensePlate': licensePlate,
      'carColor': carColor,
      'carImageUrl': carImageUrl,
      'nationalIdUrl': nationalIdUrl,
      'driversLicenseUrl': driversLicenseUrl,
      'carLicenseUrl': carLicenseUrl,
      'criminalRecordUrl': criminalRecordUrl,
      'status': status,
      'isOnline': isOnline,
      'rating': rating,
      'totalRides': totalRides,
      'currentLocation': currentLocation,
      'heading': heading,
      'fcmToken': fcmToken,
      'stripeConnectAccountId': stripeConnectAccountId,
      'balance': balance,
    };
  }

  factory DriverModel.fromMap(Map<String, dynamic> map) {
    return DriverModel(
      uid: map['uid'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      createdAt: map['createdAt'] ?? Timestamp.now(),
      fullName: map['fullName'] ?? '',
      email: map['email'],
      profileImageUrl: map['profileImageUrl'],
      carModel: map['carModel'] ?? '',
      licensePlate: map['licensePlate'] ?? '',
      carColor: map['carColor'] ?? '',
      carImageUrl: map['carImageUrl'],
      nationalIdUrl: map['nationalIdUrl'],
      driversLicenseUrl: map['driversLicenseUrl'],
      carLicenseUrl: map['carLicenseUrl'],
      criminalRecordUrl: map['criminalRecordUrl'],
      status: map['status'] ?? 'pending_approval',
      isOnline: map['isOnline'] ?? false,
      rating: (map['rating'] as num?)?.toDouble() ?? 5.0,
      totalRides: map['totalRides'] as int? ?? 0,
      currentLocation: map['currentLocation'],
      heading: map['heading'],
      fcmToken: map['fcmToken'],
      stripeConnectAccountId: map['stripeConnectAccountId'],
      balance: (map['balance'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
