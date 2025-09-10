import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:taxi_app/bloc/customer/home/customer_home_cubit.dart';

import 'package:taxi_app/bloc/customer/home/customer_home_states.dart';
import 'package:taxi_app/common/extensions.dart';

Widget buildGoogleMap(BuildContext context, HomeState state) {
  Set<Marker> markers = {};
  Set<Polyline> polylines = {};
  Set<Circle> circles = {};

  if (state is HomeMapReady) {
    markers = state.markers;
  } else if (state is HomeRouteReady) {
    markers = state.markers;
    polylines = state.polylines;
  } else if (state is HomeSearchingForDriver) {
    // --- ADD THIS CASE ---
    markers = state.markers;
    // Create the circle to represent the search radius
    circles = {
      Circle(
        circleId: const CircleId('search_radius'),
        center: state.currentPosition,
        radius: 500, // 5km radius
        fillColor: KColor.primary.withOpacity(0.2),
        strokeColor: KColor.primary,
        strokeWidth: 2,
      )
    };
  } else if (state is HomeDriverEnRoute) {
    markers = state.markers;
    polylines = state.polylines;
  } else if (state is HomeDriverArrived) {
    markers = state.markers;
  } else if (state is HomeTripInProgress) {
    markers = state.markers;
    polylines = state.polylines;
  } else if (state is HomeTripCompleted) {
    markers = state.markers;
  }

  return GoogleMap(
    buildingsEnabled: false,
    compassEnabled: false,
    zoomControlsEnabled: false,
    initialCameraPosition:
        const CameraPosition(target: LatLng(30.0444, 31.2357), zoom: 12),
    onMapCreated: (controller) =>
        context.read<HomeCubit>().setMapController(controller),
    markers: markers,
    polylines: polylines,
    circles: circles,
    myLocationEnabled: false,
    myLocationButtonEnabled: false,
  );
}
