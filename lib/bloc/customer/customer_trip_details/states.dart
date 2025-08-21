import 'package:equatable/equatable.dart';
import 'package:taxi_app/data_models/driver_model.dart';

// --- States ---
abstract class TripDetailsState extends Equatable {
  const TripDetailsState();
  @override
  List<Object> get props => [];
}

class TripDetailsLoading extends TripDetailsState {}

class TripDetailsLoaded extends TripDetailsState {
  final DriverModel driver;
  const TripDetailsLoaded({required this.driver});
  @override
  List<Object> get props => [driver];
}

class TripDetailsError extends TripDetailsState {
  final String message;
  const TripDetailsError({required this.message});
  @override
  List<Object> get props => [message];
}
