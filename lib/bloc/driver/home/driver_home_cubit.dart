import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:taxi_app/bloc/driver/home/driver_home_states.dart';
import 'package:taxi_app/common/extensions.dart';
import 'package:taxi_app/common/images.dart';
import 'package:taxi_app/data_models/driver_model.dart';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:taxi_app/data_models/trip_model.dart';

class DriverHomeCubit extends Cubit<DriverHomeState> {
  final String driverUid;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  StreamSubscription<Position>? _positionStreamSubscription;
  GoogleMapController? _mapController;
  BitmapDescriptor? _carIcon;
  BitmapDescriptor? _pickupIcon;
  DriverHomeCubit({required this.driverUid}) : super(DriverHomeLoading());
  StreamSubscription? _tripRequestSubscription;
  final Dio _dio = Dio();
  void setMapController(GoogleMapController controller) {
    _mapController = controller;
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

  /// Fetches the driver's initial state (online/offline) and last known location.
  Future<void> loadInitialState() async {
    try {
      _carIcon ??= await _bitmapDescriptorFromAsset(KImage.carYellow, 120);
      _pickupIcon ??= await _bitmapDescriptorFromAsset(KImage.manYellow, 120);
      final doc = await _db.collection('drivers').doc(driverUid).get();
      if (!doc.exists) {
        emit(const DriverHomeError(message: "Driver profile not found."));
        return;
      }

      final driver = DriverModel.fromMap(doc.data()!);
      final lastPosition = await Geolocator.getLastKnownPosition() ??
          await Geolocator.getCurrentPosition();
      final latLng = LatLng(lastPosition.latitude, lastPosition.longitude);

      if (driver.isOnline) {
        goOnline(); // If they were already online, start tracking immediately
      } else {
        emit(DriverOffline(lastKnownPosition: latLng));
        _mapController?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 16));
      }
    } catch (e) {
      emit(DriverHomeError(message: e.toString()));
    }
  }

  /// Puts the driver in the online state.
  Future<void> goOnline() async {
    try {
      emit(DriverHomeLoading());
      await _db.collection('drivers').doc(driverUid).update({'isOnline': true});

      // 1. Get the current position immediately to provide an initial state.
      Position position = await Geolocator.getCurrentPosition();
      final newLatLng = LatLng(position.latitude, position.longitude);
      await _db.collection('drivers').doc(driverUid).update({
        'currentLocation': GeoPoint(position.latitude, position.longitude),
      });

      final driverMarker = Marker(
        markerId: const MarkerId('driver'),
        position: newLatLng,
        icon: _carIcon!,
        rotation: position.heading,
        anchor: const Offset(0.5, 0.5),
        flat: true,
      );

      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(newLatLng, 16));
      // 2. Emit the DriverOnline state immediately so the UI is not stuck loading.
      emit(DriverOnline(currentPosition: newLatLng, markers: {driverMarker}));

      // 3. Now, start listening for future location updates.
      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      );

      _positionStreamSubscription =
          Geolocator.getPositionStream(locationSettings: locationSettings)
              .listen((Position position) {
        final newLatLng = LatLng(position.latitude, position.longitude);
        _db.collection('drivers').doc(driverUid).update({
          'currentLocation': GeoPoint(position.latitude, position.longitude),
        });

        final currentState = state;
        if (currentState is DriverOnline) {
          final driverMarker = Marker(
              markerId: const MarkerId('driver'),
              position: newLatLng,
              icon: _carIcon!,
              rotation: position.heading,
              anchor: const Offset(0.5, 0.5),
              flat: true);
          _mapController
              ?.animateCamera(CameraUpdate.newLatLngZoom(newLatLng, 16));
          emit(DriverOnline(
              currentPosition: newLatLng,
              markers: {driverMarker},
              newTripRequest: currentState.newTripRequest));
        } else if (currentState is DriverEnRouteToPickup) {
          _handleEnRouteLocationUpdate(position, currentState);
        }
      });

      _listenForTripRequests();
    } catch (e) {
      emit(DriverHomeError(message: e.toString()));
    }
  }

  /// Puts the driver in the offline state.
  Future<void> goOffline() async {
    try {
      emit(DriverHomeLoading());
      // 1. Stop listening to location updates to save battery
      await _positionStreamSubscription?.cancel();
      _positionStreamSubscription = null;

      await _tripRequestSubscription?.cancel();
      _tripRequestSubscription = null;
      // 2. Update status in Firestore
      await _db
          .collection('drivers')
          .doc(driverUid)
          .update({'isOnline': false});

      final lastPosition = await Geolocator.getLastKnownPosition() ??
          await Geolocator.getCurrentPosition();
      emit(DriverOffline(
          lastKnownPosition:
              LatLng(lastPosition.latitude, lastPosition.longitude)));
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
      if (querySnapshot.docs.isNotEmpty) {
        final tripDoc = querySnapshot.docs.first;
        final trip = TripModel.fromMap(tripDoc.data(), tripDoc.id);

        final currentState = state;
        // Only update if the driver is currently online
        if (currentState is DriverOnline) {
          // Emit a new DriverOnline state, copying the old data
          // and adding the new trip request.
          emit(DriverOnline(
            currentPosition: currentState.currentPosition,
            markers: currentState.markers,
            newTripRequest: trip,
          ));
        }
      }
    });
  }

  /// Accepts a trip, calculates the route to the customer, and updates the state.
  Future<void> acceptTrip(TripModel trip) async {
    final currentState = state;
    // Ensure the driver is actually online before accepting a trip.
    if (currentState is! DriverOnline) return;

    try {
      emit(DriverHomeLoading());

      // Step 1: Update the trip document in Firestore to "claim" it.
      // This changes the status and assigns the driver's ID to the trip.
      await _db.collection('trips').doc(trip.tripId).update({
        'status': 'driver_accepted',
        'driverUid': driverUid,
      });

      // Step 2: Stop listening for other new trip requests.
      await _tripRequestSubscription?.cancel();
      _tripRequestSubscription = null;

      // Step 3: Get the driver's current position and the customer's pickup position.
      final driverPosition = currentState.currentPosition;
      final pickupPosition =
          LatLng(trip.pickupLocation.latitude, trip.pickupLocation.longitude);

      // Step 4: Calculate the route from the driver to the customer.
      final polylinePoints =
          await _getRouteFromOSRM(driverPosition, pickupPosition);
      final routeToPickup = Polyline(
        polylineId: const PolylineId('route_to_pickup'),
        color: KColor.primary,
        points: polylinePoints ?? [],
        width: 5,
      );

      // Step 5: Create new markers for the driver and the customer's pickup spot.
      final driverMarker = Marker(
          markerId: const MarkerId('driver'),
          position: driverPosition,
          icon: _carIcon!);
      final pickupMarker = Marker(
          markerId: const MarkerId('pickup'),
          position: pickupPosition,
          icon: _pickupIcon!);

      // Step 6: Animate the map camera to show the full route.
      _mapController?.animateCamera(
        CameraUpdate.newLatLngBounds(
            _boundsFromLatLngList([driverPosition, pickupPosition]), 100.0),
      );

      // Step 7: Emit the new state to update the UI to the "en route" view.
      emit(DriverEnRouteToPickup(
        driverPosition: driverPosition,
        acceptedTrip: trip,
        markers: {driverMarker, pickupMarker},
        polylines: {routeToPickup},
      ));
    } catch (e) {
      emit(DriverHomeError(message: "Failed to accept trip: $e"));
    }
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

  void _handleEnRouteLocationUpdate(
      Position position, DriverEnRouteToPickup currentState) {
    final newLatLng = LatLng(position.latitude, position.longitude);

    // The automatic distance check is now removed.
    // This function's only job is to update the driver's marker position.
    final driverMarker = Marker(
        markerId: const MarkerId('driver'),
        position: newLatLng,
        icon: _carIcon!,
        rotation: position.heading,
        anchor: const Offset(0.5, 0.5),
        flat: true);

    _mapController?.animateCamera(CameraUpdate.newLatLng(newLatLng));

    emit(DriverEnRouteToPickup(
      driverPosition: newLatLng,
      acceptedTrip: currentState.acceptedTrip,
      markers: {
        driverMarker,
        currentState.markers.firstWhere((m) => m.markerId.value == 'pickup')
      },
      polylines: currentState.polylines,
    ));
  }

  void driverArrivedAtPickup() {
    final currentState = state;
    if (currentState is! DriverEnRouteToPickup) return;

    // Stop listening for location updates as they are no longer needed for this stage.
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;

    // Update the trip status in Firestore
    _db.collection('trips').doc(currentState.acceptedTrip.tripId).update({
      'status': 'driver_arrived',
    });

    // Emit the new state to update the UI
    emit(DriverArrivedAtPickup(
      acceptedTrip: currentState.acceptedTrip,
      markers: currentState.markers,
    ));
  }

  @override
  Future<void> close() {
    _positionStreamSubscription?.cancel();
    _tripRequestSubscription?.cancel();
    return super.close();
  }
}
