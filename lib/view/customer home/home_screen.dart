import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:taxi_app/bloc/auth/auth_cubit.dart';
import 'package:taxi_app/bloc/auth/auth_states.dart';
import 'package:taxi_app/bloc/customer/home/home_cubit.dart';
import 'package:taxi_app/bloc/customer/home/home_states.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:taxi_app/common/extensions.dart';
import 'package:taxi_app/common/images.dart';
import 'package:taxi_app/common/text_style.dart';
import 'package:taxi_app/common_widgets/rounded_button.dart';
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
        child: Scaffold(
          drawer: _buildAppDrawer(),
          body: Builder(
            builder: (context) {
              return BlocBuilder<HomeCubit, HomeState>(
                builder: (context, state) {
                  return Stack(
                    children: [
                      _buildGoogleMap(context, state),
                      if (state is HomeLoading)
                        Center(
                            child: CircularProgressIndicator(
                          color: KColor.primary,
                        )),
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
    if (state is HomeMapReady) {
      return _buildSearchPanel(context, state);
    }
    if (state is HomeRouteReady) {
      return _buildConfirmationPanel(context, state);
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
                onPressed: () {},
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
            // ListTile(
            //   leading: Icon(
            //     Icons.logout,
            //     color: KColor.secondaryText,
            //     size: 25.sp,
            //   ),
            //   title: Text(
            //     'Sign Out',
            //     style: appStyle(
            //         size: 15.sp,
            //         color: KColor.secondaryText,
            //         fontWeight: FontWeight.bold),
            //   ),
            //   onTap: () => context.read<AuthCubit>().signOut(),
            // ),
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
