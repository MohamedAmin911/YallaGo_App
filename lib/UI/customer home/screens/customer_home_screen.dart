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
import 'package:taxi_app/UI/auth/screens/auth_gate.dart';
import 'package:taxi_app/UI/customer%20home/screens/destination_search_screen.dart';
import 'package:taxi_app/UI/customer%20home/widgets/customer_home_widgets/app_drawer.dart';
import 'package:taxi_app/UI/customer%20home/widgets/customer_home_widgets/confirmation_panel.dart';
import 'package:taxi_app/UI/customer%20home/widgets/customer_home_widgets/driver_arrived_panel.dart';
import 'package:taxi_app/UI/customer%20home/widgets/customer_home_widgets/driver_en_route_panel.dart';
import 'package:taxi_app/UI/customer%20home/widgets/customer_home_widgets/google_map_widget.dart';
import 'package:taxi_app/UI/customer%20home/widgets/customer_home_widgets/search_panel.dart';
import 'package:taxi_app/UI/customer%20home/widgets/customer_home_widgets/searching_panel.dart';
import 'package:taxi_app/UI/customer%20home/widgets/customer_home_widgets/top_ui.dart';
import 'package:taxi_app/UI/customer%20home/widgets/customer_home_widgets/trip_completed_panel.dart';
import 'package:taxi_app/UI/customer%20home/widgets/customer_home_widgets/trip_in_progress_panel.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final HomeCubit _homeCubit; // keep a single instance
  double _rating = 5.0;

  void _updateRating(double newRating) => setState(() => _rating = newRating);

  @override
  void initState() {
    super.initState();
    _homeCubit = HomeCubit()..loadCurrentUserLocation();
  }

  @override
  void dispose() {
    _homeCubit.close();
    super.dispose();
  }

  Future<void> _navigateToSearch(BuildContext context, LatLng position) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DestinationSearchScreen(
          currentUserPosition: position,
        ),
      ),
    );

    if (!mounted) return; // avoid using context after dispose

    if (result != null && result is Map) {
      final destination = result['location'] as LatLng;
      final address = result['address'] as String;
      context.read<HomeCubit>().planRoute(destination, address);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<HomeCubit>.value(
      value: _homeCubit,
      child: MultiBlocListener(
        listeners: [
          BlocListener<AuthCubit, AuthState>(
            listener: (context, state) {
              if (state is AuthLoggedOut) {
                context.pushRlacement(const AuthGate());
// Navigator.of(context).pushAndRemoveUntil(
// MaterialPageRoute(builder: () => ),
// (route) => false,
// );
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
