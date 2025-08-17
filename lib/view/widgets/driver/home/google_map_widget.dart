import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:taxi_app/bloc/driver/home/driver_home_cubit.dart';

import 'package:taxi_app/bloc/driver/home/driver_home_states.dart';

Widget buildGoogleMap(BuildContext context, DriverHomeState state) {
  LatLng initialPosition = const LatLng(30.0444, 31.2357);
  Set<Marker> markers = {};
  Set<Polyline> polylines = {};

  if (state is DriverOffline) {
    initialPosition = state.lastKnownPosition;
  } else if (state is DriverOnline) {
    initialPosition = state.currentPosition;
    markers = state.markers;
  } else if (state is DriverEnRouteToPickup) {
    initialPosition = state.driverPosition;
    markers = state.markers;
    polylines = state.polylines;
  } else if (state is DriverArrivedAtPickup) {
    markers = state.markers;
  } else if (state is DriverTripInProgress) {
    markers = state.markers;
    polylines = state.polylines;
  } else if (state is DriverArrivedAtDestination) {
    markers = state.markers;
  }

  return GoogleMap(
    buildingsEnabled: false,
    compassEnabled: false,
    zoomControlsEnabled: false,
    myLocationEnabled: false,
    initialCameraPosition: CameraPosition(target: initialPosition, zoom: 16),
    onMapCreated: (controller) =>
        context.read<DriverHomeCubit>().setMapController(controller),
    markers: markers,
    polylines: polylines,
    myLocationButtonEnabled: false,
  );
}
