import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:taxi_app/bloc/customer/home/customer_home_states.dart';
import 'package:taxi_app/common/extensions.dart';
import 'package:taxi_app/common/images.dart';
import 'package:taxi_app/data_models/driver_model.dart';
import 'package:taxi_app/data_models/trip_model.dart';
import 'package:taxi_app/services/notification_service.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit() : super(HomeInitial());
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  GoogleMapController? _mapController;
  StreamSubscription<Position>? _positionStreamSubscription;
  StreamSubscription? _tripSubscription;
  StreamSubscription? _assignedDriverSubscription;
  StreamSubscription? _unreadChatSubscription;
  final Dio _dio = Dio();
  Position? _currentUserPosition;
  StreamSubscription? _nearbyDriversSubscription;
  Set<Marker> _driverMarkers = {};
  BitmapDescriptor? _pickupIcon;
  BitmapDescriptor? _destinationIcon;
  BitmapDescriptor? _driverIcon;
  BitmapDescriptor? _carIcon;
  final NotificationService _notificationService = NotificationService();

  // Keep last seen position per driver to compute bearing if heading is missing.
  final Map<String, LatLng> _lastDriverPos = {};

  void setMapController(GoogleMapController controller) {
    _mapController = controller;
  }

  Future<void> loadCurrentUserLocation() async {
    try {
      emit(HomeLoading());

      _pickupIcon ??= await _bitmapDescriptorFromAsset(KImage.homeIcon, 90);
      _destinationIcon ??=
          await _bitmapDescriptorFromAsset(KImage.destinationIcon, 100);
      _driverIcon ??= await _bitmapDescriptorFromAsset(KImage.car2, 100);
      _carIcon ??= await _bitmapDescriptorFromAsset(KImage.carYellow, 100);
      _currentUserPosition = await _determinePosition();
      final userLatLng = LatLng(
          _currentUserPosition!.latitude, _currentUserPosition!.longitude);
      final address = await _getAddressFromLatLng(userLatLng);

      final pickupMarker = Marker(
        markerId: const MarkerId('currentLocation'),
        position: userLatLng,
        icon: _pickupIcon!,
      );
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(userLatLng, 16));

      emit(HomeMapReady(
        currentPosition: userLatLng,
        currentAddress: address,
        markers: {pickupMarker},
      ));

      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      );

      _positionStreamSubscription =
          Geolocator.getPositionStream(locationSettings: locationSettings)
              .listen((Position position) async {
        final currentState = state;
        _currentUserPosition = position;
        final newLatLng = LatLng(position.latitude, position.longitude);

        if (currentState is HomeMapReady) {
          final newAddress = await _getAddressFromLatLng(newLatLng);
          final updatedMarker = Marker(
            markerId: const MarkerId('currentLocation'),
            position: newLatLng,
            icon: _pickupIcon!,
          );

          emit(HomeMapReady(
            currentPosition: newLatLng,
            currentAddress: newAddress,
            markers: {updatedMarker, ..._driverMarkers},
          ));
        } else if (currentState is HomeRouteReady) {
          final destinationLatLng = currentState.markers
              .firstWhere((m) => m.markerId.value == 'destination')
              .position;

          final routeDetails =
              await _getRouteFromOSRM(newLatLng, destinationLatLng);
          if (routeDetails == null) return;

          final newPolylinePoints = routeDetails['polyline'] as List<LatLng>;
          final distanceInMeters = routeDetails['distance'] as double;
          final durationInSeconds = routeDetails['duration'] as double;
          final price = _calculatePrice(distanceInMeters, durationInSeconds);
          final distanceKm = (distanceInMeters / 1000).toStringAsFixed(1);
          final durationMinutes = (durationInSeconds / 60).ceil();

          final newRoutePolyline = Polyline(
            polylineId: const PolylineId('route'),
            color: KColor.primary,
            points: newPolylinePoints,
            width: 5,
          );

          final updatedPickupMarker = Marker(
            markerId: const MarkerId('pickup'),
            position: newLatLng,
            icon: _pickupIcon!,
          );

          emit(HomeRouteReady(
            pickupPosition: newLatLng,
            pickupAddress: currentState.pickupAddress,
            destinationAddress: currentState.destinationAddress,
            markers: {
              updatedPickupMarker,
              currentState.markers
                  .firstWhere((m) => m.markerId.value == 'destination'),
              ..._driverMarkers,
            },
            polylines: {newRoutePolyline},
            distance: "$distanceKm km",
            duration: "$durationMinutes min",
            estimatedPrice: price.toStringAsFixed(2),
          ));
        }
      });

      _listenForNearbyDrivers(userLatLng);
    } catch (e) {
      emit(HomeError(message: "Failed to get location: ${e.toString()}"));
    }
  }

  Future<void> planRoute(LatLng destination, String destinationAddress) async {
    final curr = state;

    if (_currentUserPosition == null) {
      emit(const HomeError(message: "Current location unknown."));
      return;
    }

    final LatLng pickupLatLng = LatLng(
      _currentUserPosition!.latitude,
      _currentUserPosition!.longitude,
    );

    String pickupAddress = '';
    if (curr is HomeMapReady) {
      pickupAddress = curr.currentAddress;
    } else if (curr is HomeRouteReady) {
      pickupAddress = curr.pickupAddress;
    }

    try {
      emit(HomeLoading());

      final routeDetails = await _getRouteFromOSRM(pickupLatLng, destination);
      if (routeDetails == null) {
        throw Exception("Could not find a route.");
      }

      final polylinePoints = routeDetails['polyline'] as List<LatLng>;
      final distanceInMeters = routeDetails['distance'] as double;
      final durationInSeconds = routeDetails['duration'] as double;

      final price = _calculatePrice(distanceInMeters, durationInSeconds);
      final distanceKm = (distanceInMeters / 1000).toStringAsFixed(1);
      final durationMinutes = (durationInSeconds / 60).ceil();

      final routeId = 'route_${DateTime.now().millisecondsSinceEpoch}';
      final routePolyline = Polyline(
        polylineId: PolylineId(routeId),
        color: KColor.primary,
        points: polylinePoints,
        width: 3,
        geodesic: true,
      );

      final pickupMarker = Marker(
        markerId: const MarkerId('pickup'),
        position: pickupLatLng,
        icon: _pickupIcon!,
      );
      final destMarker = Marker(
        markerId: const MarkerId('destination'),
        position: destination,
        icon: _destinationIcon!,
      );

      _mapController?.animateCamera(
        CameraUpdate.newLatLngBounds(
          _boundsFromLatLngList([pickupLatLng, destination]),
          150.0,
        ),
      );

      emit(
        HomeRouteReady(
          pickupPosition: pickupLatLng,
          pickupAddress: pickupAddress,
          destinationAddress: destinationAddress,
          markers: {pickupMarker, destMarker, ..._driverMarkers},
          polylines: {routePolyline},
          distance: "$distanceKm km",
          duration: "$durationMinutes min",
          estimatedPrice: price.toStringAsFixed(2),
        ),
      );
    } catch (e) {
      emit(HomeError(message: "Failed to plan route: ${e.toString()}"));
    }
  }

  Future<BitmapDescriptor> _bitmapDescriptorFromAsset(
      String assetName, int width) async {
    final ByteData data = await rootBundle.load(assetName);
    final ui.Codec codec = await ui
        .instantiateImageCodec(data.buffer.asUint8List(), targetWidth: width);
    final ui.FrameInfo fi = await codec.getNextFrame();
    final ByteData? byteData =
        await fi.image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
  }

  double _calculatePrice(double distanceInMeters, double durationInSeconds) {
    const double baseFare = 10.0;
    const double pricePerKm = 2.5;
    const double pricePerMinute = 0.5;

    final double distanceInKm = distanceInMeters / 1000;
    final double durationInMinutes = durationInSeconds / 60;

    final price = baseFare +
        (distanceInKm * pricePerKm) +
        (durationInMinutes * pricePerMinute);
    return price;
  }

  Future<Map<String, dynamic>?> _getRouteFromOSRM(
      LatLng start, LatLng end) async {
    final url =
        'http://router.project-osrm.org/route/v1/driving/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?overview=full&geometries=polyline';

    try {
      final response = await _dio.get(url);
      if (response.statusCode == 200) {
        final data = response.data;
        final route = data['routes'][0];
        final geometry = route['geometry'] as String;
        return {
          'polyline': _decodePolyline(geometry),
          'distance': route['distance'],
          'duration': route['duration'],
        };
      }
    } catch (e) {
      print("Error getting route from OSRM: $e");
    }
    return null;
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng((lat / 1E5), (lng / 1E5)));
    }
    return points;
  }

  LatLngBounds _boundsFromLatLngList(List<LatLng> list) {
    double? x0, x1, y0, y1;
    for (LatLng latLng in list) {
      if (x0 == null) {
        x0 = x1 = latLng.latitude;
        y0 = y1 = latLng.longitude;
      } else {
        if (latLng.latitude > x1!) x1 = latLng.latitude;
        if (latLng.latitude < x0) x0 = latLng.latitude;
        if (latLng.longitude > y1!) y1 = latLng.longitude;
        if (latLng.longitude < y0!) y0 = latLng.longitude;
      }
    }
    return LatLngBounds(
        northeast: LatLng(x1!, y1!), southwest: LatLng(x0!, y0!));
  }

  Future<String> _getAddressFromLatLng(LatLng position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        final Placemark place = placemarks.first;

        final street = place.street ?? '';
        final subLocality = place.subLocality ?? '';
        final locality = place.locality ?? '';

        if (street.isNotEmpty && !street.contains('+')) {
          return "$street, $locality";
        }
        if (subLocality.isNotEmpty) {
          return "$subLocality, $locality";
        }
        if (locality.isNotEmpty) {
          return locality;
        }
        return place.name ?? "Unnamed Location";
      }
      return "Unknown Location";
    } catch (e) {
      print("Error getting address: $e");
      return "Could not fetch address.";
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied.');
    }

    return await Geolocator.getCurrentPosition();
  }

  void _listenForNearbyDrivers(LatLng customerPosition) {
    _nearbyDriversSubscription?.cancel();
    _nearbyDriversSubscription = _db
        .collection('drivers')
        .where('isOnline', isEqualTo: true)
        .snapshots()
        .listen((querySnapshot) {
      _driverMarkers.clear();
      const double radiusInMeters = 5000;

      for (var doc in querySnapshot.docs) {
        final driver = DriverModel.fromMap(doc.data());
        if (driver.currentLocation != null) {
          final driverPosition = LatLng(
            driver.currentLocation!.latitude,
            driver.currentLocation!.longitude,
          );

          final distance = Geolocator.distanceBetween(
            customerPosition.latitude,
            customerPosition.longitude,
            driverPosition.latitude,
            driverPosition.longitude,
          );

          if (distance <= radiusInMeters) {
            // Compute rotation: prefer heading, else bearing from last to current
            final last = _lastDriverPos[driver.uid];
            double rotation = (driver.heading ?? 0).toDouble();
            if ((rotation == 0 || rotation.isNaN) &&
                last != null &&
                (last.latitude != driverPosition.latitude ||
                    last.longitude != driverPosition.longitude)) {
              rotation = _bearing(last, driverPosition);
            }
            _lastDriverPos[driver.uid] = driverPosition;

            _driverMarkers.add(
              Marker(
                markerId: MarkerId(driver.uid),
                position: driverPosition,
                icon: _driverIcon!,
                anchor: const Offset(0.5, 0.5),
                flat: true,
                rotation: rotation,
              ),
            );
          }
        }
      }

      // Combine the user's marker with the new driver markers
      final currentState = state;
      if (currentState is HomeMapReady) {
        final userMarker = currentState.markers
            .firstWhere((m) => m.markerId.value == 'currentLocation');
        emit(HomeMapReady(
          currentPosition: currentState.currentPosition,
          currentAddress: currentState.currentAddress,
          markers: {userMarker, ..._driverMarkers},
        ));
      } else if (currentState is HomeRouteReady) {
        emit(HomeRouteReady(
          pickupPosition: currentState.pickupPosition,
          pickupAddress: currentState.pickupAddress,
          destinationAddress: currentState.destinationAddress,
          markers: {
            currentState.markers
                .firstWhere((m) => m.markerId.value == 'pickup'),
            currentState.markers
                .firstWhere((m) => m.markerId.value == 'destination'),
            ..._driverMarkers
          },
          polylines: currentState.polylines,
          distance: currentState.distance,
          duration: currentState.duration,
          estimatedPrice: currentState.estimatedPrice,
        ));
      }
    });
  }

  void _handleDriverArrived(TripModel trip) async {
    final driverDoc = await _db.collection('drivers').doc(trip.driverUid).get();
    if (driverDoc.exists) {
      final driver = DriverModel.fromMap(driverDoc.data()!);

      _notificationService.showNotification(
        "Your driver has arrived!",
        "${driver.fullName} is waiting for you at the pickup location.",
      );

      final customerPosition =
          LatLng(trip.pickupLocation.latitude, trip.pickupLocation.longitude);
      final driverPosition = LatLng(
          driver.currentLocation!.latitude, driver.currentLocation!.longitude);

      final customerMarker = Marker(
          markerId: const MarkerId('pickup'),
          position: customerPosition,
          icon: _pickupIcon!);

      // Rotation for arrived driver marker
      final last = _lastDriverPos[driver.uid];
      double rotation = (driver.heading ?? 0).toDouble();
      if ((rotation == 0 || rotation.isNaN) &&
          last != null &&
          (last.latitude != driverPosition.latitude ||
              last.longitude != driverPosition.longitude)) {
        rotation = _bearing(last, driverPosition);
      }
      _lastDriverPos[driver.uid] = driverPosition;

      final driverMarker = Marker(
          markerId: MarkerId(driver.uid),
          position: driverPosition,
          icon: _driverIcon!,
          flat: true,
          rotation: rotation,
          anchor: const Offset(0.5, 0.5));

      emit(HomeDriverArrived(
        trip: trip,
        driver: driver,
        markers: {customerMarker, driverMarker},
      ));
    }
  }

  void listenToTripUpdates(String tripId) {
    final currentState = state;
    if (currentState is! HomeRouteReady) return;
    final customerMarker = currentState.markers.firstWhere(
      (m) => m.markerId.value == 'pickup',
      orElse: () => currentState.markers.first,
    );
    emit(HomeSearchingForDriver(
      tripId: tripId,
      currentPosition: currentState.pickupPosition,
      markers: {customerMarker},
    ));
    _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(currentState.pickupPosition, 15.5));
    // _tripSubscription?.cancel();
    // _assignedDriverSubscription?.cancel();

    _tripSubscription =
        _db.collection('trips').doc(tripId).snapshots().listen((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) return;
      final trip = TripModel.fromMap(snapshot.data()!, snapshot.id);

      switch (trip.status) {
        case 'driver_accepted':
          _listenToAssignedDriver(trip);
          break;
        case 'driver_arrived':
          _handleDriverArrived(trip);
          break;
        case 'in_progress':
          _handleTripInProgress(trip);
          break;
        case 'arrived_at_destination':
          _handleTripCompleted(trip);
          break;
        case 'cancelled':
          cancelTripRequest(tripId);
          break;
      }
    });
  }

  Future<void> cancelTripRequest(String tripId) async {
    try {
      await _db.collection('trips').doc(tripId).update({'status': 'cancelled'});
      await _tripSubscription?.cancel();
      loadCurrentUserLocation();
    } catch (e) {
      emit(HomeError(message: "Failed to cancel trip: ${e.toString()}"));
    }
  }

  void _listenToAssignedDriver(TripModel trip) {
    _assignedDriverSubscription?.cancel();
    _assignedDriverSubscription = _db
        .collection('drivers')
        .doc(trip.driverUid)
        .snapshots()
        .listen((snapshot) async {
      if (snapshot.exists && snapshot.data() != null) {
        final driver = DriverModel.fromMap(snapshot.data()!);
        final customerPosition =
            LatLng(trip.pickupLocation.latitude, trip.pickupLocation.longitude);
        final driverPosition = LatLng(driver.currentLocation!.latitude,
            driver.currentLocation!.longitude);
        final routeDetails =
            await _getRouteFromOSRM(driverPosition, customerPosition);
        if (routeDetails == null) return;
        final durationInSeconds = routeDetails['duration'] as double;
        final durationMinutes = (durationInSeconds / 60).ceil();

        final customerMarker = Marker(
            markerId: const MarkerId('pickup'),
            position: customerPosition,
            icon: _pickupIcon!);

        // Rotation for en-route driver marker
        final last = _lastDriverPos[driver.uid];
        double rotation = (driver.heading ?? 0).toDouble();
        if ((rotation == 0 || rotation.isNaN) &&
            last != null &&
            (last.latitude != driverPosition.latitude ||
                last.longitude != driverPosition.longitude)) {
          rotation = _bearing(last, driverPosition);
        }
        _lastDriverPos[driver.uid] = driverPosition;

        final driverMarker = Marker(
            markerId: MarkerId(driver.uid),
            position: driverPosition,
            icon: _driverIcon!,
            flat: true,
            rotation: rotation,
            anchor: const Offset(0.5, 0.5));

        emit(HomeDriverEnRoute(
          trip: trip,
          driver: driver,
          markers: {customerMarker, driverMarker},
          polylines: {},
          arrivalEta: "$durationMinutes min",
        ));
        final customerUid = FirebaseAuth.instance.currentUser!.uid;
        _listenForUnreadMessages(
            trip.tripId ?? "", customerUid, trip.driverUid!);
      }
    });
  }

  void _listenForUnreadMessages(
      String tripId, String currentUserId, String otherUserId) {
    _unreadChatSubscription?.cancel();
    _unreadChatSubscription = _db
        .collection('trips')
        .doc(tripId)
        .collection('messages')
        .where('senderUid', isEqualTo: otherUserId)
        .snapshots()
        .listen((snapshot) {
      final unreadCount = snapshot.docs.where((doc) {
        final readBy = List<String>.from(doc.data()['readBy'] ?? []);
        return !readBy.contains(currentUserId);
      }).length;

      final currentState = state;
      if (currentState is HomeDriverEnRoute) {
        emit(currentState.copyWith(unreadMessageCount: unreadCount));
      } else if (currentState is HomeDriverArrived) {
        emit(currentState.copyWith(unreadMessageCount: unreadCount));
      }
    });
  }

  void _handleTripInProgress(TripModel trip) {
    _assignedDriverSubscription?.cancel();
    _assignedDriverSubscription = _db
        .collection('drivers')
        .doc(trip.driverUid)
        .snapshots()
        .listen((snapshot) async {
      if (snapshot.exists && snapshot.data() != null) {
        final driver = DriverModel.fromMap(snapshot.data()!);
        final destinationPosition = LatLng(trip.destinationLocation.latitude,
            trip.destinationLocation.longitude);
        final driverPosition = LatLng(driver.currentLocation!.latitude,
            driver.currentLocation!.longitude);

        final routeDetails =
            await _getRouteFromOSRM(driverPosition, destinationPosition);
        if (routeDetails == null) return;

        final polylinePoints = routeDetails['polyline'] as List<LatLng>;
        final durationInSeconds = routeDetails['duration'] as double;
        final durationMinutes = (durationInSeconds / 60).ceil();

        final routeToDestination = Polyline(
          polylineId: const PolylineId('route_to_destination'),
          color: KColor.primary,
          points: polylinePoints,
          width: 5,
        );

        // Rotation for in-progress driver marker
        final last = _lastDriverPos[driver.uid];
        double rotation = (driver.heading ?? 0).toDouble();
        if ((rotation == 0 || rotation.isNaN) &&
            last != null &&
            (last.latitude != driverPosition.latitude ||
                last.longitude != driverPosition.longitude)) {
          rotation = _bearing(last, driverPosition);
        }
        _lastDriverPos[driver.uid] = driverPosition;

        final driverMarker = Marker(
          markerId: MarkerId(driver.uid),
          position: driverPosition,
          icon: _carIcon!,
          flat: true,
          rotation: rotation,
          anchor: const Offset(0.5, 0.5),
        );
        final destinationMarker = Marker(
          markerId: const MarkerId('destination'),
          position: destinationPosition,
          icon: _destinationIcon!,
        );

        emit(HomeTripInProgress(
          trip: trip,
          driver: driver,
          markers: {driverMarker, destinationMarker},
          polylines: {routeToDestination},
          arrivalEta: "$durationMinutes min",
        ));
      }
    });
  }

  void _handleTripCompleted(TripModel trip) async {
    _tripSubscription?.cancel();
    _assignedDriverSubscription?.cancel();

    try {
      final currentPosition = await _determinePosition();
      final customerFinalPosition =
          LatLng(currentPosition.latitude, currentPosition.longitude);

      final customerMarker = Marker(
        markerId: const MarkerId('currentLocation'),
        position: customerFinalPosition,
        icon: _pickupIcon!,
      );

      _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(customerFinalPosition, 16));

      emit(HomeTripCompleted(
        trip: trip,
        markers: {customerMarker},
      ));
    } catch (e) {
      emit(HomeError(message: "Could not get final location: $e"));
    }
  }

  @override
  Future<void> close() {
    _unreadChatSubscription?.cancel();
    _assignedDriverSubscription?.cancel();
    _tripSubscription?.cancel();
    _nearbyDriversSubscription?.cancel();
    _positionStreamSubscription?.cancel();
    return super.close();
  }

  // ---------- Bearing helpers ----------
  double _degToRad(double deg) => deg * (math.pi / 180.0);
  double _radToDeg(double rad) => rad * (180.0 / math.pi);

  double _bearing(LatLng from, LatLng to) {
    final lat1 = _degToRad(from.latitude);
    final lat2 = _degToRad(to.latitude);
    final dLon = _degToRad(to.longitude - from.longitude);
    final y = math.sin(dLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    return (_radToDeg(math.atan2(y, x)) + 360.0) % 360.0;
  }
}
