import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taxi_app/bloc/auth/auth_cubit.dart';
import 'package:taxi_app/bloc/auth/auth_states.dart';
import 'package:taxi_app/bloc/driver/home/driver_home_cubit.dart';
import 'package:taxi_app/bloc/driver/home/driver_home_states.dart';
import 'package:taxi_app/common/extensions.dart';
import 'package:taxi_app/view/auth/auth_gate.dart';
import 'package:taxi_app/view/widgets/driver/home/app_drawer.dart';
import 'package:taxi_app/view/widgets/driver/home/arrived_at_destination_panel.dart';
import 'package:taxi_app/view/widgets/driver/home/arrived_panel.dart';
import 'package:taxi_app/view/widgets/driver/home/en_route_panel.dart';
import 'package:taxi_app/view/widgets/driver/home/google_map_widget.dart';
import 'package:taxi_app/view/widgets/driver/home/ride_request_dialog.dart';
import 'package:taxi_app/view/widgets/driver/home/top_panel.dart';
import 'package:taxi_app/view/widgets/driver/home/trip_in_progress_panel.dart';

class DriverHomeScreen extends StatelessWidget {
  const DriverHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
          body: Center(child: Text("Error: User not found.")));
    }

    return BlocProvider(
      create: (context) =>
          DriverHomeCubit(driverUid: user.uid)..loadInitialState(),
      child: BlocListener<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthLoggedOut) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const AuthGate()),
              (route) => false,
            );
          }
        },
        child: BlocListener<DriverHomeCubit, DriverHomeState>(
          listener: (context, state) {
            if (state is DriverHomeError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: KColor.red,
                ),
              );
            }
          },
          child: Scaffold(
            drawer: const DriverAppDrawer(),
            body: Builder(
              builder: (context) {
                return BlocListener<DriverHomeCubit, DriverHomeState>(
                    listenWhen: (previous, current) {
                  final wasTripAvailable = previous is DriverOnline &&
                      previous.newTripRequest != null;

                  final isTripAvailable =
                      current is DriverOnline && current.newTripRequest != null;

                  return !wasTripAvailable && isTripAvailable;
                }, listener: (context, state) {
                  if (state is DriverOnline && state.newTripRequest != null) {
                    showRideRequestDialog(context, state.newTripRequest!);
                  }
                }, child: BlocBuilder<DriverHomeCubit, DriverHomeState>(
                  builder: (context, state) {
                    bool isOnline = state is DriverOnline ||
                        state is DriverEnRouteToPickup ||
                        state is DriverArrivedAtPickup ||
                        state is DriverTripInProgress ||
                        state is DriverArrivedAtDestination;
                    return Stack(
                      children: [
                        buildGoogleMap(context, state),
                        !isOnline
                            ? Container(
                                color: KColor.primaryText.withOpacity(0.7))
                            : Container(),
                        if (state is DriverHomeLoading)
                          Center(
                              child: CircularProgressIndicator(
                            color: KColor.primary,
                          )),
                        if (state is DriverHomeError)
                          Center(child: Text(state.message)),
                        buildTopPanel(context, state),
                        if (state is! DriverEnRouteToPickup)
                          buildTopPanel(context, state),
                        if (state is DriverEnRouteToPickup)
                          buildEnRouteToPickupPanel(context, state),
                        if (state is DriverArrivedAtPickup)
                          buildArrivedPanel(context, state),
                        if (state is DriverTripInProgress)
                          buildTripInProgressPanel(context, state),
                        if (state is DriverArrivedAtDestination)
                          buildArrivedAtDestinationPanel(context, state),
                      ],
                    );
                  },
                ));
              },
            ),
          ),
        ),
      ),
    );
  }
}
