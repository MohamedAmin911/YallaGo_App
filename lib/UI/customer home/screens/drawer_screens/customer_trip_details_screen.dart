import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:taxi_app/bloc/customer/customer_trip_details/cubit.dart';
import 'package:taxi_app/bloc/customer/customer_trip_details/states.dart';
import 'package:taxi_app/common/extensions.dart';
import 'package:taxi_app/common/text_style.dart';
import 'package:taxi_app/data_models/driver_model.dart';
import 'package:taxi_app/data_models/trip_model.dart';
import 'package:intl/intl.dart';

class TripDetailsScreen extends StatelessWidget {
  final TripModel trip;
  const TripDetailsScreen({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          TripDetailsCubit()..fetchDriverDetails(trip.driverUid!),
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
        body: ListView(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
          children: [
            SizedBox(height: 22.h),
            //title
            Text(
              "Trip Details",
              style: appStyle(
                size: 25.sp,
                color: KColor.primaryText,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 30.h),
            // --- Driver Header ---
            BlocBuilder<TripDetailsCubit, TripDetailsState>(
              builder: (context, state) {
                if (state is TripDetailsLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is TripDetailsLoaded) {
                  return _buildDriverHeader(state.driver);
                }
                if (state is TripDetailsError) {
                  return Text(state.message);
                }
                return const SizedBox.shrink();
              },
            ),
            SizedBox(height: 24.h),

            // --- Trip Info Card ---
            _buildInfoCard(
              children: [
                _buildDetailRow(
                  icon: Icons.calendar_today,
                  title: "Date",
                  value: DateFormat('MMM d, yyyy - hh:mm a')
                      .format(trip.requestedAt.toDate()),
                ),
                const Divider(),
                _buildDetailRow(
                  icon: Icons.location_on,
                  title: "From",
                  value: trip.pickupAddress,
                ),
                const Divider(),
                _buildDetailRow(
                  icon: Icons.flag,
                  title: "To",
                  value: trip.destinationAddress,
                ),
              ],
            ),
            SizedBox(height: 20.h),

            // --- Payment & Rating Card ---
            _buildInfoCard(
              children: [
                _buildDetailRow(
                  icon: Icons.attach_money,
                  title: "Final Fare",
                  value: "EGP ${trip.estimatedFare.toStringAsFixed(2)}",
                  valueColor: Colors.green,
                ),
                const Divider(),
                _buildRatingSection(trip),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDriverHeader(DriverModel driver) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 40.r,
          backgroundImage: (driver.profileImageUrl != null &&
                  driver.profileImageUrl!.isNotEmpty)
              ? NetworkImage(driver.profileImageUrl!)
              : null,
          child: (driver.profileImageUrl == null ||
                  driver.profileImageUrl!.isEmpty)
              ? Icon(Icons.person, size: 40.r)
              : null,
        ),
        SizedBox(width: 16.w),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Your driver was",
              style: appStyle(
                  size: 14.sp,
                  color: KColor.secondaryText,
                  fontWeight: FontWeight.bold),
            ),
            Text(
              driver.fullName,
              style: appStyle(
                  size: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: KColor.primaryText),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoCard({required List<Widget> children}) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildRatingSection(TripModel trip) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.star_rate_rounded,
                color: Colors.amber,
                size: 20.sp,
              ),
              SizedBox(width: 16.w),
              Text(
                "Your Rating",
                style: appStyle(
                    size: 12.sp,
                    color: KColor.secondaryText,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          trip.ratingForDriver != null
              ? RatingBarIndicator(
                  rating: trip.ratingForDriver ?? 0,
                  itemBuilder: (context, index) => const Icon(
                    Icons.star_rate_rounded,
                    color: Colors.amber,
                  ),
                  itemCount: 5,
                  itemSize: 40.sp,
                  unratedColor: KColor.placeholder.withOpacity(0.5),
                  direction: Axis.horizontal,
                )
              : Text(
                  "You did not rate this trip.",
                  style: appStyle(
                      size: 16.sp,
                      color: KColor.secondaryText,
                      fontWeight: FontWeight.bold),
                ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String title,
    required String value,
    Color? valueColor,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: KColor.primary, size: 20.sp),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: appStyle(
                      size: 12.sp,
                      color: KColor.secondaryText,
                      fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 2.h),
                Text(
                  value,
                  style: appStyle(
                    size: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: valueColor ?? KColor.primaryText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
