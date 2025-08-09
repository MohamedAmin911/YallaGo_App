import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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

class HomeError extends HomeState {
  final String message;

  const HomeError({required this.message});

  @override
  List<Object> get props => [message];
}
