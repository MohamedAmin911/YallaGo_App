import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:taxi_app/bloc/driver/driver_cubit.dart';
import 'package:taxi_app/bloc/driver/driver_states.dart';
import 'package:taxi_app/common/extensions.dart';
import 'package:taxi_app/common/text_style.dart';
import 'package:taxi_app/common_widgets/rounded_button.dart';
import 'package:taxi_app/UI/auth/screens/driver_auth/driver_payout_screen.dart';
import 'package:taxi_app/UI/driver%20home/screens/driver_home_screen.dart';

class DriverDocumentsScreen extends StatefulWidget {
  // Receives all data from the previous screens
  final String fullName;
  final String email;
  final File? profileImageFile;
  final String carModel;
  final String licensePlate;
  final String carColor;
  final File? carImageFile;

  const DriverDocumentsScreen({
    super.key,
    required this.fullName,
    required this.email,
    this.profileImageFile,
    required this.carModel,
    required this.licensePlate,
    required this.carColor,
    this.carImageFile,
  });

  @override
  State<DriverDocumentsScreen> createState() => _DriverDocumentsScreenState();
}

class _DriverDocumentsScreenState extends State<DriverDocumentsScreen> {
  final ImagePicker _picker = ImagePicker();

  File? _nationalIdFile;
  File? _driversLicenseFile;
  File? _carLicenseFile;
  File? _criminalRecordFile;

  Future<void> _pickImage(Function(File) onImagePicked) async {
    final pickedFile =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      setState(() {
        onImagePicked(File(pickedFile.path));
      });
    }
  }

  void _submitDocuments() {
    if (_nationalIdFile == null ||
        _driversLicenseFile == null ||
        _carLicenseFile == null ||
        _criminalRecordFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please upload all required documents.")),
      );
      return;
    }

    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => DriverPayoutScreen(
        // Pass all the data forward
        fullName: widget.fullName,
        email: widget.email,
        profileImageFile: widget.profileImageFile,
        carModel: widget.carModel,
        licensePlate: widget.licensePlate,
        carColor: widget.carColor,
        carImageFile: widget.carImageFile,
        nationalIdFile: _nationalIdFile!,
        driversLicenseFile: _driversLicenseFile!,
        carLicenseFile: _carLicenseFile!,
        criminalRecordFile: _criminalRecordFile!,
      ),
    ));
  }

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
      body: BlocConsumer<DriverCubit, DriverState>(
        listener: (context, state) {
          if (state is DriverProfileCreated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content:
                      Text("Sign up complete! Your account is under review.")),
            );
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const DriverHomeScreen()),
              (route) => false,
            );
          } else if (state is DriverError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is DriverLoading;
          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 22.h),
                //title
                Text(
                  "Documents",
                  style: appStyle(
                    size: 25.sp,
                    color: KColor.primaryText,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 30.h),
                SizedBox(height: 8.h),
                const Text(
                  "Please upload clear photos of the following documents.",
                  style: TextStyle(color: Colors.grey),
                ),
                SizedBox(height: 30.h),
                _buildDocumentUploader(
                  title: "National ID (البطاقة الشخصية)",
                  file: _nationalIdFile,
                  onTap: () => _pickImage((file) => _nationalIdFile = file),
                ),
                _buildDocumentUploader(
                  title: "Driver's License (رخصة القيادة)",
                  file: _driversLicenseFile,
                  onTap: () => _pickImage((file) => _driversLicenseFile = file),
                ),
                _buildDocumentUploader(
                  title: "Car License (رخصة السيارة)",
                  file: _carLicenseFile,
                  onTap: () => _pickImage((file) => _carLicenseFile = file),
                ),
                _buildDocumentUploader(
                  title: "Criminal Record Check (فيش وتشبيه)",
                  file: _criminalRecordFile,
                  onTap: () => _pickImage((file) => _criminalRecordFile = file),
                ),
                SizedBox(height: 40.h),
                isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          color: KColor.primary,
                        ),
                      )
                    : RoundButton(
                        title: "CONTUNUE",
                        color: KColor.primary,
                        onPressed: isLoading ? () {} : _submitDocuments,
                      ),
                SizedBox(height: 20.h),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDocumentUploader({
    required String title,
    required File? file,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
          SizedBox(height: 8.h),
          GestureDetector(
            onTap: onTap,
            child: Container(
              height: 150.h,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: Colors.grey.shade400),
                image: file != null
                    ? DecorationImage(image: FileImage(file), fit: BoxFit.cover)
                    : null,
              ),
              child: file == null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo_outlined,
                              size: 40.r, color: Colors.grey[600]),
                          SizedBox(height: 8.h),
                          const Text("Tap to upload"),
                        ],
                      ),
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
