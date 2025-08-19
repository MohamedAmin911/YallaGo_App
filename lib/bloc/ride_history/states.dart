import 'package:equatable/equatable.dart';
import 'package:taxi_app/data_models/trip_model.dart';

abstract class RideHistoryState extends Equatable {
  const RideHistoryState();
  @override
  List<Object> get props => [];
}

class RideHistoryLoading extends RideHistoryState {}

class RideHistoryLoaded extends RideHistoryState {
  final List<TripModel> trips;
  const RideHistoryLoaded({required this.trips});
  @override
  List<Object> get props => [trips];
}

class RideHistoryError extends RideHistoryState {
  final String message;
  const RideHistoryError({required this.message});
  @override
  List<Object> get props => [message];
}
