import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:taxi_app/data_models/driver_model.dart';
import 'package:taxi_app/data_models/trip_model.dart';

abstract class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object?> get props => [];
}

class HomeInitial extends HomeState {}

class HomeLoading extends HomeState {}

class HomeMapReady extends HomeState {
  final LatLng currentPosition;
  final String currentAddress;
  final Set<Marker> markers;

  const HomeMapReady({
    required this.currentPosition,
    required this.currentAddress,
    required this.markers,
  });

  @override
  List<Object?> get props => [currentPosition, currentAddress, markers];
}

class HomeRouteReady extends HomeState {
  final LatLng pickupPosition;
  final String pickupAddress;
  final String destinationAddress;
  final Set<Marker> markers;
  final Set<Polyline> polylines;
  final String distance;
  final String duration;
  final String estimatedPrice;

  const HomeRouteReady({
    required this.pickupPosition,
    required this.pickupAddress,
    required this.destinationAddress,
    required this.markers,
    required this.polylines,
    required this.distance,
    required this.duration,
    required this.estimatedPrice,
  });

  @override
  List<Object?> get props => [
        pickupPosition,
        pickupAddress,
        destinationAddress,
        markers,
        polylines,
        distance,
        duration,
        estimatedPrice
      ];
}

/// State for when the app is actively searching for a driver.
class HomeSearchingForDriver extends HomeState {}

/// State for when a driver has accepted the trip and is on their way.
class HomeDriverEnRoute extends HomeState {
  final TripModel trip;
  final DriverModel driver;
  final Set<Marker> markers;
  final Set<Polyline> polylines;
  final String arrivalEta;

  const HomeDriverEnRoute({
    required this.trip,
    required this.driver,
    required this.markers,
    required this.polylines,
    required this.arrivalEta,
  });

  @override
  List<Object?> get props => [trip, driver, markers, polylines, arrivalEta];
}

/// State for when the driver has arrived at the pickup location.
class HomeDriverArrived extends HomeState {
  final TripModel trip;
  final DriverModel driver;
  final Set<Marker> markers;
  const HomeDriverArrived({
    required this.trip,
    required this.driver,
    required this.markers,
  });

  @override
  List<Object?> get props => [trip, driver, markers];
}

class HomeError extends HomeState {
  final String message;

  const HomeError({required this.message});

  @override
  List<Object> get props => [message];
}
