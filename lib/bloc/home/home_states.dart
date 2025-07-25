import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// Base class for all home states
abstract class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object?> get props => [];
}

// Initial state before anything has loaded
class HomeInitial extends HomeState {}

// State for when the cubit is fetching location or route data
class HomeLoading extends HomeState {}

// State when the map is ready, showing the user's current location as the pickup point
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

// State after a destination has been selected and a route is displayed
class HomeRouteReady extends HomeState {
  final String pickupAddress;
  final String destinationAddress;
  final Set<Marker> markers;
  final Set<Polyline> polylines;

  const HomeRouteReady({
    required this.pickupAddress,
    required this.destinationAddress,
    required this.markers,
    required this.polylines,
  });

  @override
  List<Object?> get props =>
      [pickupAddress, destinationAddress, markers, polylines];
}

// State for handling any errors
class HomeError extends HomeState {
  final String message;

  const HomeError({required this.message});

  @override
  List<Object> get props => [message];
}
