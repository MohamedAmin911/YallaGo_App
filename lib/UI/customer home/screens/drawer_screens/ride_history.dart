import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:taxi_app/bloc/customer/customer_ride_history/cubit.dart';
import 'package:taxi_app/bloc/customer/customer_ride_history/states.dart';

import 'package:taxi_app/common/extensions.dart';
import 'package:taxi_app/common/text_style.dart';
import 'package:taxi_app/data_models/trip_model.dart';
import 'package:intl/intl.dart';
import 'package:taxi_app/UI/customer%20home/screens/drawer_screens/customer_trip_details_screen.dart';

class RideHistoryScreen extends StatelessWidget {
  const RideHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text("Error: Not logged in.")));
    }

    return BlocProvider(
      create: (context) => RideHistoryCubit()..fetchHistory(user.uid),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            onPressed: context.pop,
            icon: Icon(
              Icons.arrow_back_ios,
              color: KColor.primaryText,
            ),
          ),
        ),
        backgroundColor: KColor.bg,
        body: BlocBuilder<RideHistoryCubit, RideHistoryState>(
          builder: (context, state) {
            if (state is RideHistoryLoading) {
              return Center(
                  child: CircularProgressIndicator(
                color: KColor.primary,
              ));
            }
            if (state is RideHistoryLoaded) {
              if (state.trips.isEmpty) {
                return const Center(
                    child: Text("You haven't taken any trips yet."));
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 22.h),
                  //title
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Text(
                      "Trip Details",
                      style: appStyle(
                        size: 25.sp,
                        color: KColor.primaryText,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  SizedBox(height: 30.h),
                  Expanded(
                    child: ListView.builder(
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                      itemCount: state.trips.length,
                      itemBuilder: (context, index) {
                        final trip = state.trips[index];
                        return _buildTripCard(context, trip);
                      },
                    ),
                  ),
                ],
              );
            }
            if (state is RideHistoryError) {
              return Center(child: Text(state.message));
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildTripCard(BuildContext context, TripModel trip) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => TripDetailsScreen(trip: trip),
          ));
        },
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Row(
            children: [
              Icon(Icons.local_taxi, color: KColor.primary, size: 30.sp),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trip.destinationAddress,
                      style: appStyle(
                          size: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: KColor.primaryText),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      DateFormat('MMM d, yyyy - hh:mm a')
                          .format(trip.requestedAt.toDate()),
                      style: appStyle(
                          size: 12.sp,
                          color: KColor.secondaryText,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 16.w),
              Text(
                "EGP ${trip.estimatedFare.toStringAsFixed(2)}",
                style: appStyle(
                    size: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.green),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
