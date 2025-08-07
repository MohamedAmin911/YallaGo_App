import 'package:cloud_firestore/cloud_firestore.dart';

class TripModel {
  final String? tripId;
  final String customerUid;
  final String? driverUid;
  final String status;
  final Timestamp requestedAt;
  final String pickupAddress;
  final GeoPoint pickupLocation;
  final String destinationAddress;
  final GeoPoint destinationLocation;
  final double estimatedFare;
  final double? actualFare;
  final String? paymentMethodId;
  final int? ratingForDriver;

  TripModel({
    this.tripId,
    required this.customerUid,
    this.driverUid,
    required this.status,
    required this.requestedAt,
    required this.pickupAddress,
    required this.pickupLocation,
    required this.destinationAddress,
    required this.destinationLocation,
    required this.estimatedFare,
    this.actualFare,
    this.paymentMethodId,
    this.ratingForDriver,
  });

  /// Converts this TripModel instance into a Map for Firestore.
  Map<String, dynamic> toMap() {
    return {
      // tripId is not stored in the map, as it's the document ID
      'customerUid': customerUid,
      'driverUid': driverUid,
      'status': status,
      'requestedAt': requestedAt,
      'pickupAddress': pickupAddress,
      'pickupLocation': pickupLocation,
      'destinationAddress': destinationAddress,
      'destinationLocation': destinationLocation,
      'estimatedFare': estimatedFare,
      'actualFare': actualFare,
      'paymentMethodId': paymentMethodId,
      'ratingForDriver': ratingForDriver,
    };
  }

  /// Creates a TripModel instance from a Firestore map.
  factory TripModel.fromMap(Map<String, dynamic> map, String documentId) {
    return TripModel(
      tripId: documentId,
      customerUid: map['customerUid'] ?? '',
      driverUid: map['driverUid'],
      status: map['status'] ?? 'unknown',
      requestedAt: map['requestedAt'] ?? Timestamp.now(),
      pickupAddress: map['pickupAddress'] ?? '',
      pickupLocation: map['pickupLocation'] ?? const GeoPoint(0, 0),
      destinationAddress: map['destinationAddress'] ?? '',
      destinationLocation: map['destinationLocation'] ?? const GeoPoint(0, 0),
      estimatedFare: (map['estimatedFare'] as num?)?.toDouble() ?? 0.0,
      actualFare: (map['actualFare'] as num?)?.toDouble(),
      paymentMethodId: map['paymentMethodId'],
      ratingForDriver: map['ratingForDriver'] as int?,
    );
  }

  TripModel copyWith({
    String? tripId,
    String? customerUid,
    String? driverUid,
    String? status,
    // ... add all other fields here
  }) {
    return TripModel(
        tripId: tripId ?? this.tripId,
        customerUid: customerUid ?? this.customerUid,
        driverUid: driverUid ?? this.driverUid,
        status: status ?? this.status,
        destinationAddress: destinationAddress,
        destinationLocation: destinationLocation,
        pickupAddress: pickupAddress,
        pickupLocation: pickupLocation,
        estimatedFare: estimatedFare,
        actualFare: actualFare,
        paymentMethodId: paymentMethodId,
        ratingForDriver: ratingForDriver,
        requestedAt: requestedAt);
  }
}
