import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:taxi_app/data_models/trip_model.dart';

abstract class DriverHomeState extends Equatable {
  const DriverHomeState();

  @override
  List<Object> get props => [];
}

/// The initial state when the screen is loading.
class DriverHomeLoading extends DriverHomeState {}

/// The state when the driver is offline and not tracking their location.
class DriverOffline extends DriverHomeState {
  final LatLng lastKnownPosition;

  const DriverOffline({required this.lastKnownPosition});

  @override
  List<Object> get props => [lastKnownPosition];
}

/// The state when the driver is online and actively tracking their location.
class DriverOnline extends DriverHomeState {
  final LatLng currentPosition;
  final Set<Marker> markers;

  const DriverOnline({required this.currentPosition, required this.markers});

  @override
  List<Object> get props => [currentPosition, markers];
}

/// State for handling any errors.
class DriverHomeError extends DriverHomeState {
  final String message;

  const DriverHomeError({required this.message});

  @override
  List<Object> get props => [message];
}

class NewTripAvailable extends DriverHomeState {
  final TripModel trip;
  const NewTripAvailable({required this.trip});
}

class TripAccepted extends DriverHomeState {
  final TripModel trip;
  const TripAccepted({required this.trip});
}
