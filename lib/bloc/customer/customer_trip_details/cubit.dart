import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:taxi_app/bloc/customer/customer_trip_details/states.dart';
import 'package:taxi_app/data_models/driver_model.dart';

class TripDetailsCubit extends Cubit<TripDetailsState> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  TripDetailsCubit() : super(TripDetailsLoading());

  /// Fetches the details for a specific driver from Firestore.
  Future<void> fetchDriverDetails(String driverUid) async {
    try {
      emit(TripDetailsLoading());
      final doc = await _db.collection('drivers').doc(driverUid).get();

      if (doc.exists) {
        final driver = DriverModel.fromMap(doc.data()!);
        emit(TripDetailsLoaded(driver: driver));
      } else {
        emit(const TripDetailsError(message: "Driver details not found."));
      }
    } catch (e) {
      emit(TripDetailsError(message: "Failed to load driver details: $e"));
    }
  }
}
