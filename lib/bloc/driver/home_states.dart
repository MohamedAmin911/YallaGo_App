import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:taxi_app/data_models/trip_model.dart';

abstract class DriverHomeState extends Equatable {
  const DriverHomeState();

  @override
  List<Object?> get props => [];
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
  final TripModel? newTripRequest;

  const DriverOnline({
    required this.currentPosition,
    required this.markers,
    this.newTripRequest,
  });

  @override
  List<Object?> get props => [currentPosition, markers, newTripRequest];
}

/// State for when the driver has arrived at the customer's pickup location.
class DriverArrivedAtPickup extends DriverHomeState {
  final TripModel acceptedTrip;
  final Set<Marker> markers;

  const DriverArrivedAtPickup({
    required this.acceptedTrip,
    required this.markers,
  });

  @override
  List<Object?> get props => [acceptedTrip, markers];
}

class DriverEnRouteToPickup extends DriverHomeState {
  final LatLng driverPosition;
  final TripModel acceptedTrip;
  final Set<Marker> markers;
  final Set<Polyline> polylines; // The route to the customer

  const DriverEnRouteToPickup({
    required this.driverPosition,
    required this.acceptedTrip,
    required this.markers,
    required this.polylines,
  });

  @override
  List<Object?> get props => [driverPosition, acceptedTrip, markers, polylines];
}

class DriverHomeError extends DriverHomeState {
  final String message;

  const DriverHomeError({required this.message});

  @override
  List<Object> get props => [message];
}

// class NewTripAvailable extends DriverHomeState {
//   final TripModel trip;
//   const NewTripAvailable({required this.trip});
// }

// class TripAccepted extends DriverHomeState {
//   final TripModel trip;
//   const TripAccepted({required this.trip});
// }
