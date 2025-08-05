import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:taxi_app/bloc/auth/auth_cubit.dart';
import 'package:taxi_app/bloc/driver/home_cubit.dart';
import 'package:taxi_app/bloc/driver/home_states.dart';
import 'package:taxi_app/common/extensions.dart';
import 'package:taxi_app/common/images.dart';
import 'package:taxi_app/common/text_style.dart';
import 'package:taxi_app/common_widgets/rounded_button.dart';

class DriverHomeScreen extends StatelessWidget {
  const DriverHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // This is a safeguard in case something goes wrong.
      return const Scaffold(
          body: Center(child: Text("Error: User not found.")));
    }
    // Use a BlocBuilder to reactively listen to the AuthCubit's state.
    return BlocProvider(
      create: (context) =>
          DriverHomeCubit(driverUid: user.uid)..loadInitialState(),
      child: Scaffold(
        drawer: _buildAppDrawer(),
        body: Builder(
          builder: (context) {
            return BlocBuilder<DriverHomeCubit, DriverHomeState>(
              builder: (context, state) {
                bool isOnline = state is DriverOnline;
                return Stack(
                  children: [
                    // --- Google Map ---
                    _buildGoogleMap(context, state),
                    !isOnline
                        ? Container(color: KColor.primaryText.withOpacity(0.7))
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
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildGoogleMap(BuildContext context, DriverHomeState state) {
    LatLng initialPosition = const LatLng(30.0444, 31.2357); // Default to Cairo
    Set<Marker> markers = {};

    if (state is DriverOffline) {
      initialPosition = state.lastKnownPosition;
    } else if (state is DriverOnline) {
      initialPosition = state.currentPosition;
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
      myLocationButtonEnabled: false,
    );
  }

  Widget _buildTopPanel(BuildContext context, DriverHomeState state) {
    bool isOnline = state is DriverOnline;

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
}
