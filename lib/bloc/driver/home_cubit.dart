import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:taxi_app/bloc/driver/home_states.dart';
import 'package:taxi_app/common/images.dart';
import 'package:taxi_app/data_models/driver_model.dart';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';

class DriverHomeCubit extends Cubit<DriverHomeState> {
  final String driverUid;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  StreamSubscription<Position>? _positionStreamSubscription;
  GoogleMapController? _mapController;
  BitmapDescriptor? _carIcon;
  DriverHomeCubit({required this.driverUid}) : super(DriverHomeLoading());

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
      // 1. Update status in Firestore
      await _db.collection('drivers').doc(driverUid).update({'isOnline': true});

      // 2. Start listening for location updates
      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      );

      _positionStreamSubscription =
          Geolocator.getPositionStream(locationSettings: locationSettings)
              .listen((Position position) {
        final newLatLng = LatLng(position.latitude, position.longitude);

        // Update the driver's location in Firestore
        _db.collection('drivers').doc(driverUid).update({
          'currentLocation': GeoPoint(position.latitude, position.longitude),
        });

        final driverMarker = Marker(
          markerId: const MarkerId('driver'),
          position: newLatLng,
          icon: _carIcon!, // Use the pre-loaded custom icon
          rotation: position
              .heading, // Make the car icon rotate with the phone's direction
          anchor: const Offset(0.5, 0.5), // Center the icon on the coordinate
          flat: true, // Make the icon lie flat on the map
        );

        _mapController?.animateCamera(CameraUpdate.newLatLng(newLatLng));
        emit(DriverOnline(currentPosition: newLatLng, markers: {driverMarker}));
      });
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

  @override
  Future<void> close() {
    _positionStreamSubscription?.cancel();
    return super.close();
  }
}
