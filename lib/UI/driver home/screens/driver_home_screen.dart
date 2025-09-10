import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taxi_app/bloc/auth/auth_cubit.dart';
import 'package:taxi_app/bloc/auth/auth_states.dart';
import 'package:taxi_app/bloc/driver/home/driver_home_cubit.dart';
import 'package:taxi_app/bloc/driver/home/driver_home_states.dart';
import 'package:taxi_app/common/extensions.dart';
import 'package:taxi_app/UI/auth/screens/auth_gate.dart';
import 'package:taxi_app/UI/driver%20home/widgets/home/app_drawer.dart';
import 'package:taxi_app/UI/driver%20home/widgets/home/arrived_at_destination_panel.dart';
import 'package:taxi_app/UI/driver%20home/widgets/home/arrived_panel.dart';
import 'package:taxi_app/UI/driver%20home/widgets/home/en_route_panel.dart';
import 'package:taxi_app/UI/driver%20home/widgets/home/google_map_widget.dart';
import 'package:taxi_app/UI/driver%20home/widgets/home/ride_request_dialog.dart';
import 'package:taxi_app/UI/driver%20home/widgets/home/top_panel.dart';
import 'package:taxi_app/UI/driver%20home/widgets/home/trip_in_progress_panel.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  DriverHomeCubit? _cubit;
  late final User? _user;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
    if (_user != null) {
      _cubit = DriverHomeCubit(driverUid: _user.uid)..loadInitialState();
    }
  }

  @override
  void dispose() {
    _cubit?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return const Scaffold(
        body: Center(child: Text("Error: User not found.")),
      );
    }

    return BlocProvider<DriverHomeCubit>.value(
      value: _cubit!,
      child: MultiBlocListener(
        listeners: [
          BlocListener<AuthCubit, AuthState>(
            listener: (context, state) {
              if (state is AuthLoggedOut) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const AuthGate()),
                  (route) => false,
                );
              }
            },
          ),
          BlocListener<DriverHomeCubit, DriverHomeState>(
            listener: (context, state) {
              if (state is DriverHomeError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(state.message),
                      backgroundColor: KColor.red),
                );
              }
            },
          ),
        ],
        child: Scaffold(
          drawer: const DriverAppDrawer(),
          body: Builder(
            builder: (context) {
              // Show the new trip request dialog only on transition to “new request available”
              return BlocListener<DriverHomeCubit, DriverHomeState>(
                listenWhen: (previous, current) {
                  final wasAvail = previous is DriverOnline &&
                      previous.newTripRequest != null;
                  final isAvail =
                      current is DriverOnline && current.newTripRequest != null;
                  return !wasAvail && isAvail;
                },
                listener: (context, state) {
                  if (state is DriverOnline && state.newTripRequest != null) {
                    showRideRequestDialog(context, state.newTripRequest!);
                  }
                },
                child: BlocBuilder<DriverHomeCubit, DriverHomeState>(
                  builder: (context, state) {
                    final isOnline = state is DriverOnline ||
                        state is DriverEnRouteToPickup ||
                        state is DriverArrivedAtPickup ||
                        state is DriverTripInProgress ||
                        state is DriverArrivedAtDestination;

                    return Stack(
                      children: [
                        buildGoogleMap(context, state),
                        if (!isOnline)
                          Container(color: KColor.primaryText.withOpacity(0.7)),
                        if (state is DriverHomeLoading)
                          Center(
                              child: CircularProgressIndicator(
                                  color: KColor.primary)),
                        if (state is DriverHomeError)
                          Center(child: Text(state.message)),
                        // Show top panel except when en route to pickup (matches your original intent)
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
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
