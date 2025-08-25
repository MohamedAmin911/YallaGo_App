// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:taxi_app/bloc/auth/auth_cubit.dart';
import 'package:taxi_app/bloc/auth/auth_states.dart';
import 'package:taxi_app/bloc/customer/home/customer_home_cubit.dart';
import 'package:taxi_app/bloc/customer/home/customer_home_states.dart';
import 'package:taxi_app/bloc/trip/trip_cubit.dart';
import 'package:taxi_app/bloc/trip/trip_states.dart';
import 'package:taxi_app/common/extensions.dart';
import 'package:taxi_app/view/auth/auth_gate.dart';
import 'package:taxi_app/view/customer%20home/destination_search_screen.dart';
import 'package:taxi_app/view/widgets/customer/home/customer_home_widgets/app_drawer.dart';
import 'package:taxi_app/view/widgets/customer/home/customer_home_widgets/confirmation_panel.dart';
import 'package:taxi_app/view/widgets/customer/home/customer_home_widgets/driver_arrived_panel.dart';
import 'package:taxi_app/view/widgets/customer/home/customer_home_widgets/driver_en_route_panel.dart';
import 'package:taxi_app/view/widgets/customer/home/customer_home_widgets/google_map_widget.dart';
import 'package:taxi_app/view/widgets/customer/home/customer_home_widgets/search_panel.dart';
import 'package:taxi_app/view/widgets/customer/home/customer_home_widgets/searching_panel.dart';
import 'package:taxi_app/view/widgets/customer/home/customer_home_widgets/top_ui.dart';
import 'package:taxi_app/view/widgets/customer/home/customer_home_widgets/trip_completed_panel.dart';
import 'package:taxi_app/view/widgets/customer/home/customer_home_widgets/trip_in_progress_panel.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double _rating = 5.0;

  void _updateRating(double newRating) => setState(() => _rating = newRating);

  Future<void> _navigateToSearch(BuildContext context, LatLng position) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DestinationSearchScreen(
          currentUserPosition: position,
        ),
      ),
    );

    if (result != null && result is Map) {
      final destination = result['location'] as LatLng;
      final address = result['address'] as String;
      context.read<HomeCubit>().planRoute(destination, address);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => HomeCubit()..loadCurrentUserLocation(),
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
          BlocListener<TripCubit, TripState>(
            listener: (context, tripState) {
              if (tripState is TripCreated) {
                context.read<HomeCubit>().listenToTripUpdates(tripState.tripId);
              }
            },
          ),
// Show errors via ScaffoldMessenger, not as a widget in the tree
          BlocListener<HomeCubit, HomeState>(
            listener: (context, state) {
              if (state is HomeError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.message)),
                );
              }
            },
          ),
        ],
        child: Scaffold(
          drawer: const CustomerAppDrawer(),
          body: BlocBuilder<HomeCubit, HomeState>(
            builder: (context, state) {
              return Stack(
                children: [
                  buildGoogleMap(context, state),
                  if (state is HomeLoading)
                    Center(
                        child:
                            CircularProgressIndicator(color: KColor.primary)),
                  buildTopUI(context),
                  _buildBottomPanel(context, state),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBottomPanel(BuildContext context, HomeState state) {
    if (state is HomeSearchingForDriver) {
      return buildSearchingPanel(context, state);
    }
    if (state is HomeDriverEnRoute) {
      return buildDriverEnRoutePanel(context, state);
    }
    if (state is HomeDriverArrived) {
      return buildDriverArrivedPanel(
        context,
        state.driver,
        state.trip.tripId ?? "",
        state,
      );
    }
    if (state is HomeTripInProgress) {
      return buildTripInProgressPanel(context, state);
    }
    if (state is HomeTripCompleted) {
      return buildTripCompletedPanel(context, state, _rating, _updateRating);
    }
    if (state is HomeRouteReady) {
      return buildConfirmationPanel(context, state, _navigateToSearch);
    }
    if (state is HomeMapReady) {
      return buildSearchPanel(context, state, _navigateToSearch);
    }
    return const SizedBox.shrink();
  }
}
