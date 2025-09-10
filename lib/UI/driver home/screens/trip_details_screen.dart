import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:taxi_app/common/extensions.dart';
import 'package:taxi_app/common/text_style.dart';
import 'package:taxi_app/data_models/trip_model.dart';
import 'package:intl/intl.dart';

class TripDetailsScreen extends StatelessWidget {
  final TripModel trip;
  const TripDetailsScreen({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          // --- Customer Header ---
          _buildCustomerHeader(trip),
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
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: const Divider(),
              ),
              // --- Payment & Rating Card ---

              _buildDetailRow(
                icon: Icons.attach_money,
                title: "Final Fare",
                value: "EGP ${trip.estimatedFare.toStringAsFixed(2)}",
                valueColor: Colors.green,
              ),
              const Divider(),
              // --- Rating Card ---
              Row(
                children: [
                  Icon(
                    size: 20.sp,
                    Icons.star_rate_rounded,
                    color: Colors.amber,
                  ),
                  SizedBox(width: 10.w),
                  Text(
                    "Rating Received",
                    style: appStyle(
                        size: 12.sp,
                        color: KColor.secondaryText,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              SizedBox(height: 5.h),
              RatingBarIndicator(
                rating: trip.ratingForDriver != null
                    ? trip.ratingForDriver ?? 0
                    : 0,
                itemBuilder: (context, index) => const Icon(
                  Icons.star_rate_rounded,
                  color: Colors.amber,
                ),
                itemCount: 5,
                itemSize: 40.sp,
                unratedColor: KColor.placeholder.withOpacity(0.5),
                direction: Axis.horizontal,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerHeader(TripModel trip) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8.r),
          child:
              trip.customerImageUrl != null && trip.customerImageUrl!.isNotEmpty
                  ? Image.network(
                      trip.customerImageUrl!,
                      width: 100.w,
                      height: 100.h,
                      fit: BoxFit.fitWidth,
                    )
                  : Container(
                      width: 100.w,
                      height: 80.h,
                      color: Colors.grey[200],
                      child: Icon(Icons.directions_car, size: 40.r),
                    ),
        ),
        SizedBox(width: 16.w),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "You drove",
              style: appStyle(
                  size: 14.sp,
                  color: KColor.secondaryText,
                  fontWeight: FontWeight.bold),
            ),
            Text(
              trip.customerName ?? "Customer",
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
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        child: Column(children: children),
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
