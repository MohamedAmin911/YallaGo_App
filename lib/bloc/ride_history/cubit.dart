// --- Cubit ---
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taxi_app/bloc/ride_history/states.dart';
import 'package:taxi_app/data_models/trip_model.dart';

class RideHistoryCubit extends Cubit<RideHistoryState> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  RideHistoryCubit() : super(RideHistoryLoading());

  /// Fetches all completed trips for a specific driver.
  Future<void> fetchHistory(String driverUid) async {
    try {
      emit(RideHistoryLoading());
      final querySnapshot = await _db
          .collection('trips')
          .where('driverUid', isEqualTo: driverUid)
          .where('status', isEqualTo: 'completed')
          .orderBy('requestedAt', descending: true) // Show newest trips first
          .get();

      final trips = querySnapshot.docs
          .map((doc) => TripModel.fromMap(doc.data(), doc.id))
          .toList();

      emit(RideHistoryLoaded(trips: trips));
    } catch (e) {
      emit(RideHistoryError(message: "Failed to load ride history: $e"));
    }
  }
}
