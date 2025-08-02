import 'package:cloud_firestore/cloud_firestore.dart';

class DriverModel {
  final String uid;
  final String phoneNumber;
  final Timestamp createdAt;

  final String fullName;
  final String? profileImageUrl;

  final String carModel;
  final String licensePlate;
  final String carColor;
  final String? carImageUrl;

  final bool isOnline;
  final double rating;
  final int totalRides;

  final GeoPoint? currentLocation;

  final String? fcmToken;

  DriverModel({
    required this.uid,
    required this.phoneNumber,
    required this.createdAt,
    required this.fullName,
    this.profileImageUrl,
    required this.carModel,
    required this.licensePlate,
    required this.carColor,
    this.carImageUrl,
    this.isOnline = false,
    this.rating = 5.0,
    this.totalRides = 0,
    this.currentLocation,
    this.fcmToken,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'phoneNumber': phoneNumber,
      'createdAt': createdAt,
      'fullName': fullName,
      'profileImageUrl': profileImageUrl,
      'carModel': carModel,
      'licensePlate': licensePlate,
      'carColor': carColor,
      'carImageUrl': carImageUrl,
      'isOnline': isOnline,
      'rating': rating,
      'totalRides': totalRides,
      'currentLocation': currentLocation,
      'fcmToken': fcmToken,
    };
  }

  factory DriverModel.fromMap(Map<String, dynamic> map) {
    return DriverModel(
      uid: map['uid'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      createdAt: map['createdAt'] ?? Timestamp.now(),
      fullName: map['fullName'] ?? '',
      profileImageUrl: map['profileImageUrl'],
      carModel: map['carModel'] ?? '',
      licensePlate: map['licensePlate'] ?? '',
      carColor: map['carColor'] ?? '',
      carImageUrl: map['carImageUrl'],
      isOnline: map['isOnline'] ?? false,
      rating: (map['rating'] as num?)?.toDouble() ?? 5.0,
      totalRides: map['totalRides'] as int? ?? 0,
      currentLocation: map['currentLocation'],
      fcmToken: map['fcmToken'],
    );
  }
}
