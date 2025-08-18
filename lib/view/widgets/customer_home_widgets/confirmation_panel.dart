import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:taxi_app/bloc/customer/customer_cubit.dart';
import 'package:taxi_app/bloc/customer/customer_states.dart';
import 'package:taxi_app/bloc/customer/home/customer_home_states.dart';
import 'package:taxi_app/bloc/trip/trip_cubit.dart';
import 'package:taxi_app/common/extensions.dart';
import 'package:taxi_app/common/images.dart';
import 'package:taxi_app/common/text_style.dart';
import 'package:taxi_app/common_widgets/rounded_button.dart';
import 'package:taxi_app/view/widgets/driver/home/location_field.dart';

Widget buildConfirmationPanel(BuildContext context, HomeRouteReady state,
    Function(BuildContext, LatLng) navigateToSearch) {
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
                        Icon(Icons.circle, color: KColor.primary, size: 20.sp),
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
                        buildLocationField(
                            text: state.pickupAddress, onTap: () {}),
                        SizedBox(height: 12.h),
                        buildLocationField(
                          text: state.destinationAddress,
                          onTap: () =>
                              navigateToSearch(context, state.pickupPosition),
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
                final customerState = context.read<CustomerCubit>().state;

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

Widget _buildTripDetail({required IconData icon, required String value}) {
  return Column(
    children: [
      Icon(icon, color: KColor.primary, size: 25.sp),
      SizedBox(height: 4.h),
      Text(value,
          style: appStyle(
              size: 14.sp, color: KColor.primary, fontWeight: FontWeight.bold)),
    ],
  );
}
