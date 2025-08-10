import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:taxi_app/bloc/auth/auth_cubit.dart';
import 'package:taxi_app/bloc/auth/auth_states.dart';
import 'package:taxi_app/bloc/customer/customer_cubit.dart';
import 'package:taxi_app/bloc/customer/customer_states.dart';
import 'package:taxi_app/bloc/customer/home/customer_home_cubit.dart';
import 'package:taxi_app/bloc/customer/home/customer_home_states.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:taxi_app/bloc/trip/trip_cubit.dart';
import 'package:taxi_app/bloc/trip/trip_states.dart';
import 'package:taxi_app/common/extensions.dart';
import 'package:taxi_app/common/images.dart';
import 'package:taxi_app/common/text_style.dart';
import 'package:taxi_app/common_widgets/rounded_button.dart';
import 'package:taxi_app/data_models/driver_model.dart';
import 'package:taxi_app/view/auth/auth_gate.dart';
import 'package:taxi_app/view/customer%20home/destination_search_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _navigateToSearch(BuildContext context, LatLng position) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DestinationSearchScreen(currentUserPosition: position),
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
    // --- THE FIX IS HERE ---
    // The MultiBlocProvider is removed. We now use BlocProvider just to create
    // the HomeCubit for this screen session.
    return BlocProvider(
      create: (context) => HomeCubit()..loadCurrentUserLocation(),
      child: BlocListener<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthLoggedOut) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const AuthGate()),
              (route) => false,
            );
          }
        },
        child: BlocListener<TripCubit, TripState>(
          listener: (context, tripState) {
            if (tripState is TripCreated) {
              context.read<HomeCubit>().listenToTripUpdates(tripState.tripId);
            }
          },
          child: Scaffold(
            drawer: _buildAppDrawer(),
            body: Builder(
              builder: (context) {
                return BlocBuilder<HomeCubit, HomeState>(
                  builder: (context, state) {
                    return Stack(
                      children: [
                        _buildGoogleMap(context, state),
                        if (state is HomeLoading ||
                            state is HomeSearchingForDriver)
                          const Center(child: CircularProgressIndicator()),
                        if (state is HomeError)
                          Center(child: Text(state.message)),
                        _buildTopUI(context),
                        _buildBottomPanel(context, state),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchingPanel() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Card(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.r)),
        margin: const EdgeInsets.all(20),
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text("Searching for nearby drivers...",
                  style: appStyle(
                      color: KColor.primaryText,
                      fontWeight: FontWeight.bold,
                      size: 18.sp)),
              const SizedBox(height: 16),
              RoundButton(
                  title: "Cancel Ride", onPressed: () {}, color: KColor.red)
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDriverEnRoutePanel(
      BuildContext context, HomeDriverEnRoute state) {
    final driver = state.driver;
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Card(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.r)),
        margin: const EdgeInsets.all(20),
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(30.r),
                    child: driver.profileImageUrl != null
                        ? Image.network(
                            driver.profileImageUrl!,
                            width: 100.w,
                            height: 100.h,
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(driver.fullName,
                          style: appStyle(
                              color: KColor.primary,
                              fontWeight: FontWeight.bold,
                              size: 25.sp)),
                      SizedBox(height: 10.h),
                      Row(
                        children: [
                          Icon(
                            Icons.drive_eta_rounded,
                            size: 25.sp,
                            color: KColor.primaryText,
                          ),
                          SizedBox(width: 3.w),
                          SizedBox(
                            width: 90.w,
                            child: Text(driver.carModel,
                                style: appStyle(
                                    color: KColor.primaryText,
                                    fontWeight: FontWeight.bold,
                                    size: 14.sp)),
                          ),
                          Icon(
                            Icons.circle,
                            size: 20.sp,
                            color: Color(int.parse(
                                "0xff${driver.carColor.replaceFirst(RegExp(r'#'), "")}")),
                          ),
                        ],
                      ),
                      SizedBox(height: 5.h),
                      Row(
                        children: [
                          Image.asset(
                            KImage.licensePlate,
                            width: 25.w,
                          ),
                          // Icon(
                          //   Icons.assignment_ind,
                          //   size: 20.sp,
                          //   color: KColor.primaryText,
                          // ),
                          Text(" ${driver.licensePlate}",
                              style: appStyle(
                                  color: KColor.primaryText,
                                  fontWeight: FontWeight.bold,
                                  size: 14.sp)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 10.h),
              RoundButton(
                  title: "CHAT", onPressed: () {}, color: KColor.primary),
              const Divider(height: 24),
              Text("Your driver is on the way!",
                  style: appStyle(
                      color: KColor.primaryText,
                      fontWeight: FontWeight.bold,
                      size: 15.sp)),
              SizedBox(height: 5.h),
              Text("Arriving in ${state.arrivalEta} minutes",
                  style: appStyle(
                      color: KColor.placeholder,
                      fontWeight: FontWeight.w600,
                      size: 14.sp)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDriverArrivedPanel(
      BuildContext context, DriverModel driver, String tripId) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Card(
        elevation: 3,
        margin: const EdgeInsets.all(20),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.r)),
        color: KColor.bg,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 40),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Your driver has arrived!",
                            style: appStyle(
                                color: KColor.primaryText,
                                fontWeight: FontWeight.bold,
                                size: 18.sp)),
                        Text(
                          "Meet ${driver.fullName} outside.",
                          style: appStyle(
                              color: KColor.placeholder,
                              fontWeight: FontWeight.w500,
                              size: 14.sp),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10.h),
              RoundButton(
                  title: "CHAT", onPressed: () {}, color: KColor.primary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoogleMap(BuildContext context, HomeState state) {
    Set<Marker> markers = {};
    Set<Polyline> polylines = {};

    if (state is HomeMapReady) {
      markers = state.markers;
    } else if (state is HomeRouteReady) {
      markers = state.markers;
      polylines = state.polylines;
    } else if (state is HomeDriverEnRoute) {
      // It now correctly handles the DriverEnRoute state
      markers = state.markers;
      polylines = state.polylines;
    } else if (state is HomeDriverArrived) {
      // It now correctly handles the DriverArrived state
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
      myLocationEnabled: false,
      myLocationButtonEnabled: false,
    );
  }

  Widget _buildBottomPanel(BuildContext context, HomeState state) {
    if (state is HomeSearchingForDriver) {
      return _buildSearchingPanel();
    }
    if (state is HomeDriverEnRoute) {
      return _buildDriverEnRoutePanel(context, state);
    }
    if (state is HomeDriverArrived) {
      return _buildDriverArrivedPanel(
          context, state.driver, state.trip.tripId ?? "");
    }
    if (state is HomeRouteReady) {
      return _buildConfirmationPanel(context, state);
    }
    if (state is HomeMapReady) {
      return _buildSearchPanel(context, state);
    }
    return const SizedBox.shrink();
  }

  Widget _buildSearchPanel(BuildContext context, HomeMapReady state) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Card(
        elevation: 8,
        color: KColor.bg,
        margin: EdgeInsets.all(15.w),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22.r),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: IntrinsicHeight(
            child: Row(
              children: [
                Padding(
                  padding: EdgeInsets.only(top: 15.h, bottom: 8.h),
                  child: Column(
                    children: [
                      Icon(Icons.circle, color: KColor.primary, size: 20.sp),
                      Expanded(
                          child: Container(
                        width: 2.w,
                        decoration: BoxDecoration(
                          color: KColor.primary,
                          borderRadius: BorderRadius.circular(22.r),
                        ),
                      )),
                      SizedBox(height: 1.h),
                      Image.asset(
                        KImage.destinationIcon,
                        width: 20.w,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    children: [
                      _buildLocationField(
                        text: state.currentAddress,
                        onTap: () {},
                      ),
                      SizedBox(height: 12.h),
                      _buildLocationField(
                        text: "Where to?",
                        isHint: true,
                        onTap: () =>
                            _navigateToSearch(context, state.currentPosition),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConfirmationPanel(BuildContext context, HomeRouteReady state) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Card(
        margin: EdgeInsets.all(15.w),
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22.r),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: KColor.primary,
                  borderRadius: BorderRadius.circular(22.r),
                ),
              ),
              SizedBox(height: 16.h),
              IntrinsicHeight(
                child: Row(
                  children: [
                    Padding(
                      padding: EdgeInsets.only(top: 15.h, bottom: 8.h),
                      child: Column(
                        children: [
                          Icon(Icons.circle,
                              color: KColor.primary, size: 20.sp),
                          Expanded(
                              child:
                                  Container(width: 1.w, color: KColor.primary)),
                          SizedBox(height: 1.h),
                          Image.asset(
                            KImage.destinationIcon,
                            width: 20.w,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: Column(
                        children: [
                          _buildLocationField(
                              text: state.pickupAddress, onTap: () {}),
                          SizedBox(height: 12.h),
                          _buildLocationField(
                            text: state.destinationAddress,
                            onTap: () => _navigateToSearch(
                                context, state.pickupPosition),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16.h),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildTripDetail(
                      icon: Icons.directions_car, value: state.estimatedPrice),
                  _buildTripDetail(
                      icon: Icons.social_distance, value: state.distance),
                  _buildTripDetail(
                      icon: Icons.timer_outlined, value: state.duration),
                ],
              ),
              const Divider(height: 24),
              RoundButton(
                title: "Confirm Ride",
                onPressed: () {
                  final user = FirebaseAuth.instance.currentUser;
                  final customerState =
                      context.read<CustomerCubit>().state; // Get customer state

                  if (user != null && customerState is CustomerLoaded) {
                    final customer = customerState.customer;
                    final price = double.tryParse(
                            state.estimatedPrice.replaceAll("EGP ", "")) ??
                        0.0;

                    context.read<TripCubit>().createTripRequest(
                          customerUid: user.uid,
                          customerName: customer.fullName ?? "Customer",
                          customerImageUrl: customer.profileImageUrl,
                          pickupPosition: state.pickupPosition,
                          pickupAddress: state.pickupAddress,
                          destinationPosition: state.markers
                              .firstWhere(
                                  (m) => m.markerId.value == 'destination')
                              .position,
                          destinationAddress: state.destinationAddress,
                          estimatedFare: price,
                        );
                  }
                },
                color: KColor.primary,
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationField({
    required String text,
    bool isHint = false,
    required VoidCallback onTap,
  }) {
    final controller = TextEditingController(text: text);

    return TextField(
      maxLines: 1,
      textAlign: TextAlign.left,
      controller: controller,
      readOnly: true,
      onTap: onTap,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.grey[200],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22.r),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        hintText: isHint ? text : null,
        hintStyle: appStyle(
          size: 16.sp,
          color: KColor.placeholder,
          fontWeight: FontWeight.w500,
        ),
      ),
      style: appStyle(
        size: 16.sp,
        color: isHint ? KColor.placeholder : KColor.primaryText,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildTopUI(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          decoration: BoxDecoration(
            color: KColor.bg,
            shape: BoxShape.circle,
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 5, spreadRadius: 1)
            ],
          ),
          child: IconButton(
            icon: Icon(
              Icons.menu,
              color: KColor.primary,
            ),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
    );
  }

  Widget _buildAppDrawer() {
    return Builder(builder: (context) {
      return Drawer(
        backgroundColor: KColor.bg,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
          bottomRight: Radius.circular(22.r),
          topRight: Radius.circular(22.r),
        )),
        child: Column(
          // padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              padding: EdgeInsets.all(40.w),
              curve: Curves.bounceIn,
              decoration: BoxDecoration(
                  color: KColor.primary,
                  borderRadius: BorderRadius.only(
                    // bottomRight: Radius.circular(22.r),
                    topRight: Radius.circular(22.r),
                  )),
              child: Image.asset(KImage.logo4),

              // Text('Taxi App',
              //     style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
            ListTile(
              leading: Icon(
                Icons.person,
                color: KColor.placeholder,
                size: 25.sp,
              ),
              title: Text(
                'Profile',
                style: appStyle(
                    size: 15.sp,
                    color: KColor.placeholder,
                    fontWeight: FontWeight.bold),
              ),
              onTap: () {},
            ),
            ListTile(
              leading: Icon(
                Icons.payment,
                color: KColor.placeholder,
                size: 25.sp,
              ),
              title: Text(
                'Payment',
                style: appStyle(
                    size: 15.sp,
                    color: KColor.placeholder,
                    fontWeight: FontWeight.bold),
              ),
              onTap: () {},
            ),
            ListTile(
              leading: Icon(
                Icons.history,
                color: KColor.placeholder,
                size: 25.sp,
              ),
              title: Text(
                'Ride History',
                style: appStyle(
                    size: 15.sp,
                    color: KColor.placeholder,
                    fontWeight: FontWeight.bold),
              ),
              onTap: () {},
            ),
            const Spacer(),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 10.h),
              child: RoundButton(
                  title: "SIGN OUT",
                  onPressed: () {
                    context.read<AuthCubit>().signOut();
                  },
                  color: KColor.placeholder),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildTripDetail({required IconData icon, required String value}) {
    return Column(
      children: [
        Icon(icon, color: KColor.primary, size: 25.sp),
        SizedBox(height: 4.h),
        Text(value,
            style: appStyle(
                size: 14.sp,
                color: KColor.primary,
                fontWeight: FontWeight.bold)),
      ],
    );
  }
}
