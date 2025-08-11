// ignore: depend_on_referenced_packages
import 'package:meta/meta.dart';
import 'package:taxi_app/data_models/trip_model.dart';

@immutable
abstract class TripState {}

class TripInitial extends TripState {}

class TripLoading extends TripState {}

class TripCreated extends TripState {
  final String tripId;
  TripCreated({required this.tripId});
}

// class TripInProgress extends TripState {
//   final TripModel trip;
//   TripInProgress({required this.trip});
// }

class TripHistoryLoaded extends TripState {
  final List<TripModel> trips;
  TripHistoryLoaded({required this.trips});
}

class TripError extends TripState {
  final String message;
  TripError({required this.message});
}
