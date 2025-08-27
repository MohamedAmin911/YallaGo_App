import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:taxi_app/bloc/customer/customer_cubit.dart';
import 'package:taxi_app/bloc/driver/driver_cubit.dart';
import 'package:taxi_app/bloc/payment/payment_method_cubit.dart';
import 'package:taxi_app/bloc/trip/trip_states.dart';
import 'package:taxi_app/data_models/trip_model.dart';

// --- STATES for Trip ---

// --- CUBIT for Trip ---
class TripCubit extends Cubit<TripState> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  StreamSubscription? _tripSubscription;

  TripCubit() : super(TripInitial());

  /// Creates a new trip request in Firestore with a "searching" status.
  Future<void> createTripRequest({
    required String customerUid,
    required LatLng pickupPosition,
    required String pickupAddress,
    required LatLng destinationPosition,
    required String destinationAddress,
    required double estimatedFare,
    required String customerName,
    String? customerImageUrl,
  }) async {
    emit(TripLoading());
    try {
      final trip = TripModel(
        customerUid: customerUid,
        pickupAddress: pickupAddress,
        pickupLocation:
            GeoPoint(pickupPosition.latitude, pickupPosition.longitude),
        destinationAddress: destinationAddress,
        destinationLocation: GeoPoint(
            destinationPosition.latitude, destinationPosition.longitude),
        status: "searching", // This is the key status for drivers to find
        requestedAt: Timestamp.now(),
        estimatedFare: estimatedFare,
        customerName: customerName,
        customerImageUrl: customerImageUrl,
      );

      final docRef = await _db.collection('trips').add(trip.toMap());

      // Emit a success state with the new trip's ID
      emit(TripCreated(tripId: docRef.id));
    } catch (e) {
      emit(
          TripError(message: "Failed to create trip request: ${e.toString()}"));
    }
  }

  /// Creates a new trip request in Firestore.
  Future<void> createTrip(TripModel trip) async {
    emit(TripLoading());
    try {
      final docRef = await _db.collection('trips').add(trip.toMap());
      emit(TripCreated(tripId: docRef.id));
    } catch (e) {
      emit(TripError(message: "Error creating trip: $e"));
    }
  }

  /// Listens to a single trip for real-time updates (e.g., for live map tracking).
  void listenToTrip(String tripId) {
    _tripSubscription?.cancel();
    _tripSubscription =
        _db.collection('trips').doc(tripId).snapshots().listen((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        final trip = TripModel.fromMap(snapshot.data()!, snapshot.id);
        emit(TripInProgress(trip: trip));
      }
      if (snapshot.exists && snapshot.data() != null) {
        final trip = TripModel.fromMap(snapshot.data()!, snapshot.id);
        if (trip.status == 'arrived_at_destination') {
          emit(TripArrivedAtPickup());
        }
        emit(TripInProgress(trip: trip));
      }
    }, onError: (error) {
      emit(TripError(message: error.toString()));
    });
  }

  /// Fetches a list of past trips for a specific customer.
  Future<void> fetchTripHistory(String customerUid) async {
    emit(TripLoading());
    try {
      final snapshot = await _db
          .collection('trips')
          .where('customerUid', isEqualTo: customerUid)
          .orderBy('requestedAt', descending: true)
          .get();

      final trips = snapshot.docs
          .map((doc) => TripModel.fromMap(doc.data(), doc.id))
          .toList();

      emit(TripHistoryLoaded(trips: trips));
    } catch (e) {
      emit(TripError(message: "Error fetching trip history: $e"));
    }
  }

  Future<void> processTripPayment({
    required TripModel trip,
    required CustomerCubit customerCubit,
    required DriverCubit driverCubit,
    required PaymentCubit paymentCubit, // inject it
    required double rating,
  }) async {
    if (trip.driverUid == null || trip.tripId == null) return;
    final tripRef = _db.collection('trips').doc(trip.tripId);

    try {
      emit(TripLoading());

      final int amountCents = (trip.estimatedFare * 100).round();

// 1) Charge rider
      final piId = await paymentCubit.stripeCharge(
        customerUid: trip.customerUid,
        amountCents: amountCents,
        currency: 'usd',
      );
      if (piId == null) throw Exception('Payment failed');

// 2) Immediately mark as paid so driver unblocks
      await tripRef.update({
        'paymentStatus': 'succeeded',
        'paymentIntentId': piId,
        'status': 'paid',
        'paidAt': FieldValue.serverTimestamp(),
      });

// 3) Add driver share to internal balance (no live transfer needed)
      const commission = 0.20;
      final driverShareCents = (amountCents * (1 - commission)).round();
      await driverCubit.addEarningsToBalance(
          trip.driverUid!, driverShareCents / 100.0);

// 4) Stats and finalize
      await driverCubit.updateDriverRating(trip.driverUid!, rating);
      await driverCubit.incrementTotalRides(trip.driverUid!);
      await customerCubit.incrementTotalRides(trip.customerUid);

      await tripRef.update({
        'status': 'completed',
        'ratingForDriver': rating,
      });

      emit(TripCompleted());
    } catch (e) {
      await tripRef.update({
        'paymentStatus': 'failed',
        'status': 'waiting_for_payment',
        'paymentError': e.toString(),
      }).catchError((_) {});
      emit(TripError(message: 'Stripe trip payment failed: $e'));
    }
  }

  @override
  Future<void> close() {
    _tripSubscription?.cancel();
    return super.close();
  }
}
