import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:taxi_app/common/extensions.dart';
import 'package:taxi_app/common/text_style.dart';
import 'package:taxi_app/common_widgets/rounded_button.dart';
import 'package:taxi_app/view/auth/driver_auth/car_info_screen.dart';
import 'package:taxi_app/view/widgets/create_profile_screen_widgets/customer_input_fields.dart';
import 'package:taxi_app/view/widgets/auth_widgets/terms_And_conditions.dart';

class DriverCreateProfileScreen extends StatefulWidget {
  const DriverCreateProfileScreen({super.key});

  @override
  State<DriverCreateProfileScreen> createState() =>
      _DriverCreateProfileScreenState();
}

class _DriverCreateProfileScreenState extends State<DriverCreateProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _email = TextEditingController();
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final pickedFile =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  void _submitProfile() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Please upload a profile image."),
          backgroundColor: KColor.red,
        ),
      );
      return;
    }

    // This screen now navigates to the CarInfoScreen, passing the collected data.
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => CarInfoScreen(
        profileImageFile: _imageFile,
        email: _email.text.trim(),
        fullName:
            "${_firstNameController.text.trim()} ${_lastNameController.text.trim()}",
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    // This screen no longer needs a BlocConsumer.
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
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 22.h),
                //title
                Text(
                  "Create profile",
                  style: appStyle(
                    size: 25.sp,
                    color: KColor.primaryText,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 30.h),
                // Profile Image
                uploadImageWidget(),
                SizedBox(height: 24.h),
                // Input Fields
                CustomerInputFields(
                    firstNameController: _firstNameController,
                    lastNameController: _lastNameController,
                    email: _email),
                SizedBox(height: 10.h),

                SizedBox(height: 20.h),
                // Terms and conditions
                const TermsAndConditions(),
                SizedBox(height: 17.h),
                //register button
                // This is now a simple button that navigates.
                RoundButton(
                  color: KColor.primary,
                  title: "NEXT",
                  onPressed: _submitProfile,
                ),
                SizedBox(height: 10.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Column uploadImageWidget() {
    return Column(
      children: [
        Center(
          child: GestureDetector(
            onTap: _pickImage,
            child: CircleAvatar(
              radius: 50.r,
              backgroundColor: KColor.lightGray.withOpacity(0.5),
              backgroundImage:
                  _imageFile != null ? FileImage(_imageFile!) : null,
              child: _imageFile == null
                  ? Icon(Icons.camera_alt,
                      size: 40.r, color: KColor.secondaryText)
                  : null,
            ),
          ),
        ),
        SizedBox(height: 10.h),
        Center(
          child: Text("Upload Photo",
              style: appStyle(
                  size: 14.sp,
                  color: KColor.secondaryText,
                  fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }
}
