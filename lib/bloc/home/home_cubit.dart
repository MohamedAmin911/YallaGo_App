import 'dart:async';
import 'dart:ui' as ui;
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:taxi_app/bloc/home/home_states.dart';
import 'package:taxi_app/common/extensions.dart';
import 'package:taxi_app/common/images.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit() : super(HomeInitial());

  GoogleMapController? _mapController;
  StreamSubscription<Position>? _positionStreamSubscription;
  final Dio _dio = Dio();
  Position? _currentUserPosition;

  BitmapDescriptor? _pickupIcon;
  BitmapDescriptor? _destinationIcon;

  void setMapController(GoogleMapController controller) {
    _mapController = controller;
  }

  Future<void> loadCurrentUserLocation() async {
    try {
      emit(HomeLoading());

      _pickupIcon ??= await _bitmapDescriptorFromAsset(KImage.homeIcon, 90);
      _destinationIcon ??=
          await _bitmapDescriptorFromAsset(KImage.destinationIcon, 100);

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
            markers: {updatedMarker},
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
                  .firstWhere((m) => m.markerId.value == 'destination')
            },
            polylines: {newRoutePolyline},
            distance: "$distanceKm km",
            duration: "$durationMinutes min",
            estimatedPrice: "EGP ${price.toStringAsFixed(2)}",
          ));
        }
      });
    } catch (e) {
      emit(HomeError(message: "Failed to get location: ${e.toString()}"));
    }
  }

  Future<void> planRoute(LatLng destination, String destinationAddress) async {
    final startState = state;
    if ((startState is! HomeMapReady && startState is! HomeRouteReady) ||
        _currentUserPosition == null) {
      return;
    }

    try {
      emit(HomeLoading());

      final pickupLatLng = LatLng(
          _currentUserPosition!.latitude, _currentUserPosition!.longitude);

      String pickupAddress = "";
      if (startState is HomeMapReady) {
        pickupAddress = startState.currentAddress;
      } else if (startState is HomeRouteReady) {
        pickupAddress = startState.pickupAddress;
      }

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

      final routePolyline = Polyline(
        polylineId: const PolylineId('route'),
        color: KColor.primary,
        points: polylinePoints,
        width: 5,
      );

      final pickupMarker = Marker(
          markerId: const MarkerId('pickup'),
          position: pickupLatLng,
          icon: _pickupIcon!);
      final destMarker = Marker(
          markerId: const MarkerId('destination'),
          position: destination,
          icon: _destinationIcon!);

      _mapController?.animateCamera(
        CameraUpdate.newLatLngBounds(
          _boundsFromLatLngList([pickupLatLng, destination]),
          150.0,
        ),
      );

      emit(HomeRouteReady(
        pickupPosition: pickupLatLng,
        pickupAddress: pickupAddress,
        destinationAddress: destinationAddress,
        markers: {pickupMarker, destMarker},
        polylines: {routePolyline},
        distance: "$distanceKm km",
        duration: "$durationMinutes min",
        estimatedPrice: "EGP ${price.toStringAsFixed(2)}",
      ));
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

  @override
  Future<void> close() {
    _positionStreamSubscription?.cancel();
    return super.close();
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
}
