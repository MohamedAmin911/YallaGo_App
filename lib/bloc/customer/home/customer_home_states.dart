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
class HomeSearchingForDriver extends HomeState {
  final String tripId;
<<<<<<< HEAD

=======
>>>>>>> aaebcea8bb1cb03a486314d2b65759aa9fa66b36
  const HomeSearchingForDriver({required this.tripId});

  @override
  List<Object?> get props => [tripId];
}

/// State for when a driver has accepted the trip and is on their way.
class HomeDriverEnRoute extends HomeState {
  final TripModel trip;
  final DriverModel driver;
  final Set<Marker> markers;
  final Set<Polyline> polylines;
  final String arrivalEta;
  final int unreadMessageCount;

  const HomeDriverEnRoute({
    required this.trip,
    required this.driver,
    required this.markers,
    required this.polylines,
    required this.arrivalEta,
    this.unreadMessageCount = 0,
  });

  @override
  List<Object?> get props =>
      [trip, driver, markers, polylines, arrivalEta, unreadMessageCount];

  HomeDriverEnRoute copyWith({int? unreadMessageCount}) {
    return HomeDriverEnRoute(
      trip: trip,
      driver: driver,
      markers: markers,
      polylines: polylines,
      arrivalEta: arrivalEta,
      unreadMessageCount: unreadMessageCount ?? this.unreadMessageCount,
    );
  }
}

/// State for when the driver has arrived at the pickup location.
class HomeDriverArrived extends HomeState {
  final TripModel trip;
  final DriverModel driver;
  final Set<Marker> markers;
  final int unreadMessageCount;
  const HomeDriverArrived({
    required this.trip,
    required this.driver,
    required this.markers,
    this.unreadMessageCount = 0,
  });

  @override
  List<Object?> get props => [trip, driver, markers, unreadMessageCount];
  HomeDriverArrived copyWith({int? unreadMessageCount}) {
    return HomeDriverArrived(
      trip: trip,
      driver: driver,
      markers: markers,
      unreadMessageCount: unreadMessageCount ?? this.unreadMessageCount,
    );
  }
}

class HomeError extends HomeState {
  final String message;

  const HomeError({required this.message});

  @override
  List<Object> get props => [message];
}
