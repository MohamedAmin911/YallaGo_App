import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:taxi_app/bloc/customer/customer_cubit.dart';
import 'package:taxi_app/bloc/customer/customer_states.dart';
import 'package:taxi_app/common/extensions.dart';
import 'package:taxi_app/common/text_style.dart';
import 'package:taxi_app/common_widgets/rounded_button.dart';
import 'package:taxi_app/data_models/customer_model.dart';

class CustomerProfileScreen extends StatelessWidget {
  const CustomerProfileScreen({super.key});

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
      body: BlocBuilder<CustomerCubit, CustomerState>(
        builder: (context, state) {
          if (state is! CustomerLoaded) {
            // Show a loading indicator until the customer's data is available
            return const Center(child: CircularProgressIndicator());
          }
          final customer = state.customer;

          return ListView(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            children: [
              SizedBox(height: 22.h),
              //title
              Text(
                "My Profile",
                style: appStyle(
                  size: 25.sp,
                  color: KColor.primaryText,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 30.h),
              // --- Profile Header ---
              _buildProfileHeader(customer),
              const Divider(height: 40),

              // --- Contact Information ---
              _buildSectionTitle("Contact Info"),
              SizedBox(height: 8.h),
              _buildInfoTile(
                icon: Icons.phone_android,
                title: "Phone Number",
                subtitle: customer.phoneNumber,
              ),
              _buildInfoTile(
                icon: Icons.email_outlined,
                title: "Email",
                subtitle: customer.email ?? "Not provided",
              ),
              const Divider(height: 40),

              // --- Saved Places ---
              _buildSectionTitle("Saved Places"),
              SizedBox(height: 8.h),
              _buildInfoTile(
                icon: Icons.home_outlined,
                title: "Home",
                subtitle: customer.homeAddress,
                onTap: () {
                  // TODO: Implement "Add/Edit Home Address" functionality
                },
              ),
              const Divider(height: 40),

              // --- Danger Zone ---
              _buildActionTile(
                title: "Delete Account",
                icon: Icons.delete_outline,
                color: KColor.red,
                onTap: () {
                  // TODO: Implement "Delete Account" functionality
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(CustomerModel customer) {
    return Column(
      children: [
        // --- Profile Picture ---
        Material(
          borderRadius: BorderRadius.circular(30.r),
          elevation: 5,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30.r),
            child: customer.profileImageUrl != null
                ? Image.network(
                    customer.profileImageUrl!,
                    width: 300.w,
                    fit: BoxFit.contain,
                  )
                : null,
          ),
        ),
        SizedBox(height: 20.h),
        Text(
          customer.fullName ?? "Customer",
          style: appStyle(
              size: 22.sp,
              fontWeight: FontWeight.bold,
              color: KColor.primaryText),
        ),
        SizedBox(height: 10.h),
        SizedBox(
          width: 130.w,
          height: 40.h,
          child: RoundButton(
            title: "Edit Profile",
            onPressed: () {
              // TODO: Navigate to an "Edit Profile" screen
            },
            color: KColor.placeholder,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: appStyle(
          size: 18.sp, fontWeight: FontWeight.w600, color: KColor.primaryText),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: KColor.primaryText),
      title: Text(title,
          style: appStyle(
              size: 16.sp,
              color: KColor.primaryText,
              fontWeight: FontWeight.w600)),
      subtitle: Text(
        subtitle,
        style: appStyle(
            size: 14.sp,
            color: KColor.secondaryText,
            fontWeight: FontWeight.w600),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing:
          onTap != null ? const Icon(Icons.arrow_forward_ios, size: 16) : null,
      onTap: onTap,
    );
  }

  Widget _buildActionTile({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: appStyle(size: 16.sp, color: color, fontWeight: FontWeight.w600),
      ),
      onTap: onTap,
    );
  }
}
