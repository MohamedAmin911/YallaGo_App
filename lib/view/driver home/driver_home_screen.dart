import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:taxi_app/bloc/auth/auth_cubit.dart';
import 'package:taxi_app/bloc/auth/auth_states.dart';
import 'package:taxi_app/bloc/driver/home/driver_home_cubit.dart';
import 'package:taxi_app/bloc/driver/home/driver_home_states.dart';
import 'package:taxi_app/common/extensions.dart';
import 'package:taxi_app/common/images.dart';
import 'package:taxi_app/common/text_style.dart';
import 'package:taxi_app/common_widgets/rounded_button.dart';
import 'package:taxi_app/data_models/trip_model.dart';
import 'package:taxi_app/view/auth/auth_gate.dart';
import 'package:taxi_app/view/widgets/chat_bottom_sheet.dart';

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
            drawer: _buildAppDrawer(),
            body: Builder(
              builder: (context) {
                return BlocListener<DriverHomeCubit, DriverHomeState>(
                    listenWhen: (previous, current) {
                  // Check the state before the update. Was there already a trip request?
                  final wasTripAvailable = previous is DriverOnline &&
                      previous.newTripRequest != null;

                  // Check the state after the update. Is there a trip request now?
                  final isTripAvailable =
                      current is DriverOnline && current.newTripRequest != null;

                  // Only trigger the listener if a trip was NOT available before, but IS available now.
                  // This makes it fire only once when the new request first appears.
                  return !wasTripAvailable && isTripAvailable;
                }, listener: (context, state) {
                  if (state is DriverOnline && state.newTripRequest != null) {
                    _showRideRequestDialog(context, state.newTripRequest!);
                  }
                }, child: BlocBuilder<DriverHomeCubit, DriverHomeState>(
                  builder: (context, state) {
                    bool isOnline = state is DriverOnline ||
                        state is DriverEnRouteToPickup ||
                        state is DriverArrivedAtPickup;
                    return Stack(
                      children: [
                        // --- Google Map ---
                        _buildGoogleMap(context, state),
                        !isOnline
                            ? Container(
                                color: KColor.primaryText.withOpacity(0.7))
                            : Container(),

                        // --- Loading and Error UI ---
                        if (state is DriverHomeLoading)
                          Center(
                              child: CircularProgressIndicator(
                            color: KColor.primary,
                          )),
                        if (state is DriverHomeError)
                          Center(child: Text(state.message)),

                        // --- Top UI (Online/Offline Toggle) ---
                        _buildTopPanel(context, state),

                        // Only show the top panel if a trip is NOT in progress
                        if (state is! DriverEnRouteToPickup)
                          _buildTopPanel(context, state),

                        // Show the "en route" panel when a trip is accepted
                        if (state is DriverEnRouteToPickup)
                          _buildEnRouteToPickupPanel(context, state),
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

  Widget _buildEnRouteToPickupPanel(
      BuildContext context, DriverEnRouteToPickup state) {
    final trip = state.acceptedTrip;

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Card(
        elevation: 5,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.r)),
        margin: const EdgeInsets.all(20),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Customer Info Row ---
              Row(
                children: [
                  // Customer Profile Picture
                  CircleAvatar(
                    radius: 24.r,
                    backgroundImage: (trip.customerImageUrl != null &&
                            trip.customerImageUrl!.isNotEmpty)
                        ? NetworkImage(trip.customerImageUrl!)
                        : null,
                    child: (trip.customerImageUrl == null ||
                            trip.customerImageUrl!.isEmpty)
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  SizedBox(width: 12.w),
                  // Customer Name
                  Expanded(
                    child: Text(
                      trip.customerName ?? "Customer",
                      style: appStyle(
                        size: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: KColor.primaryText,
                      ),
                    ),
                  ),
                  SizedBox(
<<<<<<< HEAD
                    width: 85.w,
                    child: Badge(
                      isLabelVisible: state.unreadMessageCount >
                          0, // Show badge if count > 0
                      label: Text(state.unreadMessageCount.toString()),
                      child: RoundButton(
                        title: "CHAT",
                        onPressed: () {
                          showModalBottomSheet(
                            elevation: 5,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30.r)),
                            context: context,
                            isScrollControlled: true,
                            builder: (sheetContext) {
                              return BlocProvider.value(
                                value: BlocProvider.of<AuthCubit>(context),
                                child: ChatBottomSheet(
                                    tripId: state.acceptedTrip.tripId ?? ""),
                              );
                            },
                          );
                        },
                        color: KColor.primary,
                      ),
=======
                    width: 80.w,
                    child: RoundButton(
                      title: "CHAT",
                      onPressed: () {
                        /// TODO: Navigate to Chat Screen
                      },
                      color: KColor.primary,
>>>>>>> origin/main
                    ),
                  ),
                ],
              ),

              const Divider(height: 24),

              IntrinsicHeight(
                child: Row(
                  children: [
                    Column(
                      children: [
                        Icon(Icons.circle, color: KColor.primary, size: 30.sp),
                        Expanded(
                            child:
                                Container(width: 1.w, color: KColor.primary)),
                        Icon(Icons.location_on,
                            color: KColor.primary, size: 40.sp),
                      ],
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("PICKUP",
                              style: appStyle(
                                  size: 12.sp,
                                  color: KColor.placeholder,
                                  fontWeight: FontWeight.bold)),
                          Text(trip.pickupAddress,
                              style: appStyle(
<<<<<<< HEAD
                                  size: 16.sp,
                                  color: KColor.primaryText,
                                  fontWeight: FontWeight.bold),
                              maxLines: 2,
=======
                                  size: 15.sp,
                                  color: KColor.primaryText,
                                  fontWeight: FontWeight.bold),
                              maxLines: 3,
>>>>>>> origin/main
                              overflow: TextOverflow.ellipsis),
                          SizedBox(height: 12.h),
                          Text("DESTINATION",
                              style: appStyle(
                                  size: 12.sp,
                                  color: KColor.placeholder,
                                  fontWeight: FontWeight.bold)),
                          Text(trip.destinationAddress,
                              style: appStyle(
<<<<<<< HEAD
                                  size: 16.sp,
                                  color: KColor.primaryText,
                                  fontWeight: FontWeight.bold),
                              maxLines: 2,
=======
                                  size: 15.sp,
                                  color: KColor.primaryText,
                                  fontWeight: FontWeight.bold),
                              maxLines: 3,
>>>>>>> origin/main
                              overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

<<<<<<< HEAD
              // --- Action Buttons ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: RoundButton(
                      title: "ARRIVED",
                      onPressed: () {
                        context.read<DriverHomeCubit>().driverArrivedAtPickup();
                      },
                      color: Colors.green,
                    ),
                  ),
                ],
=======
              RoundButton(
                title: "ARRIVED",
                onPressed: () {
                  context.read<DriverHomeCubit>().driverArrivedAtPickup();
                },
                color: Colors.green,
>>>>>>> origin/main
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoogleMap(BuildContext context, DriverHomeState state) {
    LatLng initialPosition = const LatLng(30.0444, 31.2357); // Default to Cairo
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
      // initialPosition = state.driverPosition;
      markers = state.markers;
      // polylines = state.polylines;
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

  Widget _buildTopPanel(BuildContext context, DriverHomeState state) {
    bool isOnline = state is DriverOnline ||
        state is DriverEnRouteToPickup ||
        state is DriverArrivedAtPickup;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            //drawer button
            Container(
              padding: EdgeInsets.all(1.w),
              decoration: BoxDecoration(
                color: KColor.bg,
                shape: BoxShape.circle,
                boxShadow: const [
                  BoxShadow(
                      color: Colors.black26, blurRadius: 5, spreadRadius: 1)
                ],
              ),
              child: IconButton(
                icon: Icon(
                  Icons.menu,
                  weight: 3,
                  size: 30.sp,
                  color: KColor.primaryText,
                ),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
            const Spacer(),
            //online/offline button
            Material(
              elevation: 5,
              color: isOnline ? KColor.red : KColor.primary,
              borderRadius: BorderRadius.circular(40.r),
              child: Container(
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  color: KColor.bg,
                  borderRadius: BorderRadius.circular(40.r),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 130.w,
                      child: RoundButton(
                        title: isOnline ? "GO OFFLINE" : "GO ONLINE",
                        onPressed: () {
                          if (isOnline) {
                            context.read<DriverHomeCubit>().goOffline();
                          } else {
                            context.read<DriverHomeCubit>().goOnline();
                          }
                        },
                        color: isOnline ? KColor.red : KColor.primary,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10.w),
                      child: Icon(
                        isOnline
                            ? Icons.gps_off_rounded
                            : Icons.gps_fixed_rounded,
                        color: isOnline ? KColor.red : KColor.primary,
                      ),
                    )
                  ],
                ),
              ),
            ),
          ],
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
          children: <Widget>[
            DrawerHeader(
              padding: EdgeInsets.all(40.w),
              curve: Curves.bounceIn,
              decoration: BoxDecoration(
                  color: KColor.primary,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(22.r),
                  )),
              child: Image.asset(KImage.logo4),
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
        // filled: true,
        // fillColor: Colors.grey[200],
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

  Widget _newRideFields(String text, String fieldName, Color color) {
    return Container(
      // padding: EdgeInsets.symmetric(horizontal: 5.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30.r),
        border: Border.all(color: color, width: 2.w),
      ),
      child: Row(
        children: [
          Container(
              width: 70.w,
              height: 50.h,
              padding: EdgeInsets.symmetric(vertical: 10.h),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(30.r),
              ),
              child: Center(
                child: Text(
                  fieldName,
                  style: appStyle(
                      size: 18.sp,
                      color: KColor.bg,
                      fontWeight: FontWeight.bold),
                ),
              )),
          Expanded(child: _buildLocationField(text: text, onTap: () {}))
        ],
      ),
    );
  }

  void _showRideRequestDialog(BuildContext context, TripModel trip) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.r)),
          title: Text(
            "New Ride Request",
            style: appStyle(
                size: 20.sp,
                color: KColor.primary,
                fontWeight: FontWeight.bold),
          ),
          content: IntrinsicHeight(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _newRideFields(trip.pickupAddress, "From", KColor.primary),
                SizedBox(height: 8.h),
                _newRideFields(trip.destinationAddress, "To", KColor.primary),
                const SizedBox(height: 8),
                _newRideFields("${trip.estimatedFare.toStringAsFixed(2)} EGP",
                    "Fare", Colors.green),
              ],
            ),
          ),
          actions: [
            Column(
              children: [
                RoundButton(
                  title: "ACCEPT",
                  onPressed: () {
                    context.read<DriverHomeCubit>().acceptTrip(trip);
                    Navigator.of(dialogContext).pop();
                  },
                  color: KColor.primary,
                ),
                SizedBox(height: 10.h),
                RoundButton(
                  title: "DECLINE",
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  color: KColor.red,
                ),
              ],
            )
          ],
        );
      },
    );
  }
}
