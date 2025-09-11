import 'dart:async';
import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:taxi_app/bloc/driver/home/driver_home_states.dart';
import 'package:taxi_app/common/extensions.dart';
import 'package:taxi_app/common/images.dart';
import 'package:taxi_app/data_models/driver_model.dart';
import 'package:taxi_app/data_models/trip_model.dart';
import 'package:taxi_app/services/notification_service.dart';

class DriverHomeCubit extends Cubit<DriverHomeState> {
  final String driverUid;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  GoogleMapController? _mapController;
  StreamSubscription<Position>? _positionStreamSubscription;
  StreamSubscription? _tripRequestSubscription;
  StreamSubscription? _acceptedTripSubscription;
  StreamSubscription? _unreadChatSubscription;

  final NotificationService _notificationService = NotificationService();
  final Dio _dio = Dio();

  BitmapDescriptor? _carIcon;
  BitmapDescriptor? _pickupIcon;
  BitmapDescriptor? _destinationIcon;

  DriverHomeCubit({required this.driverUid}) : super(DriverHomeLoading());

  void setMapController(GoogleMapController controller) {
    _mapController = controller;
  }

  Future<BitmapDescriptor> _bitmapDescriptorFromAsset(
    String assetName,
    int width,
  ) async {
    final data = await rootBundle.load(assetName);
    final codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: width,
    );
    final frame = await codec.getNextFrame();
    final bytes = await frame.image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
  }

  // Camera helper: follow the driver with zoom + optional bearing
  void _flyTo(LatLng target, {double zoom = 16, double bearing = 0}) {
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: target, zoom: zoom, bearing: bearing, tilt: 0),
      ),
    );
  }

  // Load icons + initial state
  Future<void> loadInitialState() async {
    try {
      _carIcon ??= await _bitmapDescriptorFromAsset(KImage.carYellow, 120);
      _pickupIcon ??= await _bitmapDescriptorFromAsset(KImage.manYellow, 120);
      _destinationIcon ??=
          await _bitmapDescriptorFromAsset(KImage.destinationIcon, 100);

      final doc = await _db.collection('drivers').doc(driverUid).get();
      if (!doc.exists) {
        emit(const DriverHomeError(message: "Driver profile not found."));
        return;
      }

      final driver = DriverModel.fromMap(doc.data()!);

      // Try last known; if null, try current
      final lastPosition = await Geolocator.getLastKnownPosition();
      final currentPosition = lastPosition ??
          await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          );

      final latLng =
          LatLng(currentPosition.latitude, currentPosition.longitude);

      if (driver.isOnline) {
        // If already online, kick off tracking
        await goOnline();
      } else {
        emit(DriverOffline(lastKnownPosition: latLng));
        _mapController?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 16));
      }
    } catch (e) {
      emit(DriverHomeError(message: e.toString()));
    }
  }

  // Online: write isOnline, write initial location (with updatedAt), emit Online, start position stream
  Future<void> goOnline() async {
    try {
      emit(DriverHomeLoading());

      await _db.collection('drivers').doc(driverUid).update({
        'isOnline': true,
      });

      // Initial position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final latLng = LatLng(position.latitude, position.longitude);

      await _db.collection('drivers').doc(driverUid).update({
        'currentLocation': GeoPoint(position.latitude, position.longitude),
        'heading': position.heading,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final driverMarker = Marker(
        markerId: const MarkerId('driver'),
        position: latLng,
        icon: _carIcon ?? BitmapDescriptor.defaultMarker,
        rotation: position.heading,
        anchor: const Offset(0.5, 0.5),
        flat: true,
      );

      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 16));
      emit(DriverOnline(currentPosition: latLng, markers: {driverMarker}));

      // Start continuous updates
      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
      );

      await _positionStreamSubscription?.cancel();
      _positionStreamSubscription =
          Geolocator.getPositionStream(locationSettings: locationSettings)
              .listen((pos) async {
        final newLatLng = LatLng(pos.latitude, pos.longitude);

        // Firestore write (always include updatedAt)
        await _db.collection('drivers').doc(driverUid).update({
          'currentLocation': GeoPoint(pos.latitude, pos.longitude),
          'heading': pos.heading,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        final currentState = state;
        if (currentState is DriverOnline) {
          final updatedMarker = Marker(
            markerId: const MarkerId('driver'),
            position: newLatLng,
            icon: _carIcon ?? BitmapDescriptor.defaultMarker,
            rotation: pos.heading,
            anchor: const Offset(0.5, 0.5),
            flat: true,
          );

          // Follow the driver icon with bearing
          _flyTo(newLatLng, zoom: 16, bearing: pos.heading);

          emit(DriverOnline(
            currentPosition: newLatLng,
            markers: {updatedMarker},
            newTripRequest: currentState.newTripRequest,
          ));
        } else if (currentState is DriverEnRouteToPickup) {
          _handleEnRouteLocationUpdate(pos, currentState);
        } else if (currentState is DriverTripInProgress) {
          _handleInProgressLocationUpdate(pos, currentState);
        }
      });

      _listenForTripRequests();
    } catch (e) {
      emit(DriverHomeError(message: e.toString()));
    }
  }

  Future<void> goOffline() async {
    try {
      emit(DriverHomeLoading());

      await _positionStreamSubscription?.cancel();
      _positionStreamSubscription = null;

      await _tripRequestSubscription?.cancel();
      _tripRequestSubscription = null;

      await _acceptedTripSubscription?.cancel();
      _acceptedTripSubscription = null;

      await _unreadChatSubscription?.cancel();
      _unreadChatSubscription = null;

      await _db.collection('drivers').doc(driverUid).update({
        'isOnline': false,
      });

      final lastPosition = await Geolocator.getLastKnownPosition() ??
          await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.low,
          );

      emit(DriverOffline(
        lastKnownPosition: LatLng(
          lastPosition.latitude,
          lastPosition.longitude,
        ),
      ));
    } catch (e) {
      emit(DriverHomeError(message: e.toString()));
    }
  }

  void _listenForTripRequests() {
    _tripRequestSubscription?.cancel();
    _tripRequestSubscription = _db
        .collection('trips')
        .where('status', isEqualTo: 'searching')
        .snapshots()
        .listen((querySnapshot) {
      if (querySnapshot.docs.isEmpty) return;
      final tripDoc = querySnapshot.docs.first;
      final trip = TripModel.fromMap(tripDoc.data(), tripDoc.id);

      final currentState = state;
      if (currentState is DriverOnline) {
        emit(DriverOnline(
          currentPosition: currentState.currentPosition,
          markers: currentState.markers,
          newTripRequest: trip,
        ));
      }
    });
  }

  Future<void> acceptTrip(TripModel trip) async {
    final currentState = state;
    if (currentState is! DriverOnline) return;

    final tripRef = _db.collection('trips').doc(trip.tripId);

    try {
      await _db.runTransaction((transaction) async {
        final snap = await transaction.get(tripRef);
        if (!snap.exists) {
          throw Exception("Trip does not exist anymore.");
        }
        if (snap.data()?['status'] != 'searching') {
          throw Exception("This trip is no longer available.");
        }
        transaction.update(tripRef, {
          'status': 'driver_accepted',
          'driverUid': driverUid,
        });
      });

      await _tripRequestSubscription?.cancel();
      _tripRequestSubscription = null;

      final driverPos = currentState.currentPosition;
      final pickupPos =
          LatLng(trip.pickupLocation.latitude, trip.pickupLocation.longitude);

      final polylinePoints = await _getRouteFromOSRM(driverPos, pickupPos);
      final routeToPickup = Polyline(
        polylineId: const PolylineId('route_to_pickup'),
        color: KColor.primary,
        points: polylinePoints ?? [],
        width: 5,
      );

      final driverMarker = Marker(
        markerId: const MarkerId('driver'),
        position: driverPos,
        icon: _carIcon ?? BitmapDescriptor.defaultMarker,
      );
      final pickupMarker = Marker(
        markerId: const MarkerId('pickup'),
        position: pickupPos,
        icon: _pickupIcon ?? BitmapDescriptor.defaultMarker,
      );

      _mapController?.animateCamera(
        CameraUpdate.newLatLngBounds(
          _boundsFromLatLngList([driverPos, pickupPos]),
          100,
        ),
      );

      _listenToAcceptedTrip(trip.tripId ?? "");
      _listenForUnreadMessages(trip.tripId ?? "", driverUid, trip.customerUid);

      emit(DriverEnRouteToPickup(
        driverPosition: driverPos,
        acceptedTrip: trip,
        markers: {driverMarker, pickupMarker},
        polylines: {routeToPickup},
      ));
    } catch (e) {
      emit(DriverHomeError(message: e.toString()));
      goOnline();
    }
  }

  void _handleEnRouteLocationUpdate(
    Position position,
    DriverEnRouteToPickup currentState,
  ) async {
    final newLatLng = LatLng(position.latitude, position.longitude);

    await _db.collection('drivers').doc(driverUid).update({
      'currentLocation': GeoPoint(position.latitude, position.longitude),
      'heading': position.heading,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final driverMarker = Marker(
      markerId: const MarkerId('driver'),
      position: newLatLng,
      icon: _carIcon ?? BitmapDescriptor.defaultMarker,
      rotation: position.heading,
      anchor: const Offset(0.5, 0.5),
      flat: true,
    );

    // Follow with bearing while en-route
    _flyTo(newLatLng, zoom: 16, bearing: position.heading);

    emit(DriverEnRouteToPickup(
      driverPosition: newLatLng,
      acceptedTrip: currentState.acceptedTrip,
      markers: {
        driverMarker,
        currentState.markers.firstWhere((m) => m.markerId.value == 'pickup')
      },
      polylines: currentState.polylines,
      unreadMessageCount: currentState.unreadMessageCount,
    ));

    _listenForUnreadMessages(
      currentState.acceptedTrip.tripId ?? "",
      FirebaseAuth.instance.currentUser!.uid,
      currentState.acceptedTrip.customerUid,
    );
  }

  // Follow the driver while trip is in progress
  void _handleInProgressLocationUpdate(
    Position position,
    DriverTripInProgress currentState,
  ) {
    final newLatLng = LatLng(position.latitude, position.longitude);

    _db.collection('drivers').doc(driverUid).update({
      'currentLocation': GeoPoint(position.latitude, position.longitude),
      'heading': position.heading,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final driverMarker = Marker(
      markerId: const MarkerId('driver'),
      position: newLatLng,
      icon: _carIcon ?? BitmapDescriptor.defaultMarker,
      rotation: position.heading,
      anchor: const Offset(0.5, 0.5),
      flat: true,
    );

    final destinationMarker = currentState.markers
        .firstWhere((m) => m.markerId.value == 'destination');

    _flyTo(newLatLng, zoom: 16, bearing: position.heading);

    emit(DriverTripInProgress(
      trip: currentState.trip,
      markers: {driverMarker, destinationMarker},
      polylines: currentState.polylines,
    ));
  }

  void driverArrivedAtPickup() {
    final currentState = state;
    if (currentState is! DriverEnRouteToPickup) return;

    _db.collection('trips').doc(currentState.acceptedTrip.tripId).update({
      'status': 'driver_arrived',
    });

    emit(DriverArrivedAtPickup(
      acceptedTrip: currentState.acceptedTrip,
      markers: currentState.markers,
      unreadMessageCount: currentState.unreadMessageCount,
    ));
  }

  void _listenForUnreadMessages(
    String tripId,
    String currentUserId,
    String otherUserId,
  ) {
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

      final s = state;
      if (s is DriverEnRouteToPickup) {
        emit(s.copyWith(unreadMessageCount: unreadCount));
      } else if (s is DriverArrivedAtPickup) {
        emit(s.copyWith(unreadMessageCount: unreadCount));
      }
    });
  }

  Future<void> startTrip() async {
    final s = state;
    if (s is! DriverArrivedAtPickup) return;

    try {
      emit(DriverHomeLoading());
      final trip = s.acceptedTrip;

      await _db.collection('trips').doc(trip.tripId).update({
        'status': 'in_progress',
      });

      final driverPosition =
          s.markers.firstWhere((m) => m.markerId.value == 'driver').position;
      final destinationPosition = LatLng(
        trip.destinationLocation.latitude,
        trip.destinationLocation.longitude,
      );

      final polylinePoints =
          await _getRouteFromOSRM(driverPosition, destinationPosition);
      final routeToDestination = Polyline(
        polylineId: const PolylineId('route_to_destination'),
        color: KColor.primary,
        points: polylinePoints ?? [],
        width: 5,
      );

      final driverMarker = Marker(
        markerId: const MarkerId('driver'),
        position: driverPosition,
        icon: _carIcon ?? BitmapDescriptor.defaultMarker,
      );
      final destinationMarker = Marker(
        markerId: const MarkerId('destination'),
        position: destinationPosition,
        icon: _destinationIcon ?? BitmapDescriptor.defaultMarker,
      );

      _mapController?.animateCamera(
        CameraUpdate.newLatLngBounds(
          _boundsFromLatLngList([driverPosition, destinationPosition]),
          100,
        ),
      );

      emit(DriverTripInProgress(
        trip: trip.copyWith(status: 'in_progress'),
        markers: {driverMarker, destinationMarker},
        polylines: {routeToDestination},
      ));
    } catch (e) {
      emit(DriverHomeError(message: "Failed to start trip: $e"));
    }
  }

  Future<void> endTrip() async {
    final s = state;
    if (s is! DriverTripInProgress) return;

    try {
      emit(DriverHomeLoading());

      await _db.collection('trips').doc(s.trip.tripId).update({
        'status': 'arrived_at_destination',
      });

      emit(DriverArrivedAtDestination(
        markers: {s.markers.first},
      ));
    } catch (e) {
      emit(DriverHomeError(message: "Failed to end trip: $e"));
    }
  }

  void _listenToAcceptedTrip(String tripId) {
    _acceptedTripSubscription?.cancel();
    _acceptedTripSubscription =
        _db.collection('trips').doc(tripId).snapshots().listen((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) return;
      final trip = TripModel.fromMap(snapshot.data()!, snapshot.id);

      if (trip.status == 'completed') {
        _notificationService.showNotification(
          "Trip Completed!",
          "You received EGP ${trip.estimatedFare.toStringAsFixed(2)} and were rated ${trip.ratingForDriver} stars.",
        );
        goOnline();
      }
    });
  }

  Future<List<LatLng>?> _getRouteFromOSRM(LatLng start, LatLng end) async {
    final url =
        'http://router.project-osrm.org/route/v1/driving/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?overview=full&geometries=polyline';
    try {
      final response = await _dio.get(url);
      if (response.statusCode == 200) {
        final data = response.data;
        final route = data['routes'][0];
        final geometry = route['geometry'] as String;
        return _decodePolyline(geometry);
      }
    } catch (e) {
      // ignore
    }
    return null;
  }

  List<LatLng> _decodePolyline(String encoded) {
    final points = <LatLng>[];
    int index = 0, lat = 0, lng = 0;

    while (index < encoded.length) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final dlat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final dlng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }

  LatLngBounds _boundsFromLatLngList(List<LatLng> list) {
    double? minLat, maxLat, minLng, maxLng;
    for (final p in list) {
      minLat = (minLat == null)
          ? p.latitude
          : (p.latitude < minLat ? p.latitude : minLat);
      maxLat = (maxLat == null)
          ? p.latitude
          : (p.latitude > maxLat ? p.latitude : maxLat);
      minLng = (minLng == null)
          ? p.longitude
          : (p.longitude < minLng ? p.longitude : minLng);
      maxLng = (maxLng == null)
          ? p.longitude
          : (p.longitude > maxLng ? p.longitude : maxLng);
    }
    return LatLngBounds(
      southwest: LatLng(minLat!, minLng!),
      northeast: LatLng(maxLat!, maxLng!),
    );
  }

  @override
  Future<void> close() {
    _acceptedTripSubscription?.cancel();
    _unreadChatSubscription?.cancel();
    _positionStreamSubscription?.cancel();
    _tripRequestSubscription?.cancel();
    return super.close();
  }
}
