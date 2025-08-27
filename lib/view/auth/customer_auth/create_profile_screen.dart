import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:taxi_app/bloc/auth/auth_cubit.dart';
import 'package:taxi_app/bloc/auth/auth_states.dart';
import 'package:taxi_app/bloc/customer/customer_cubit.dart';
import 'package:taxi_app/bloc/customer/customer_states.dart';
import 'package:taxi_app/common/extensions.dart';
import 'package:taxi_app/common/text_style.dart';
import 'package:taxi_app/common_widgets/rounded_button.dart';
import 'package:taxi_app/view/auth/customer_auth/add_payment_method_screen.dart';
import 'package:taxi_app/view/widgets/create_profile_screen_widgets/customer_input_fields.dart';
import 'package:taxi_app/view/widgets/auth_widgets/terms_And_conditions.dart';

class CreateProfileScreen extends StatefulWidget {
  const CreateProfileScreen({super.key});

  @override
  State<CreateProfileScreen> createState() => _CreateProfileScreenState();
}

class _CreateProfileScreenState extends State<CreateProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _auth = FirebaseAuth.instance;
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _homeAddressController = TextEditingController();
  final _password = TextEditingController();
  final _email = TextEditingController();
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  String? _fetchedHomeAddress;
  bool _isFetchingAddress = false;

  Future<void> _pickImage() async {
    final pickedFile =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _fetchAddress() async {
    setState(() => _isFetchingAddress = true);
    try {
      final address = await context.read<CustomerCubit>().getCurrentAddress();
      setState(() => _fetchedHomeAddress = address);
      print("Fetched Address: $_fetchedHomeAddress");
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: KColor.red),
      );
    } finally {
      setState(() => _isFetchingAddress = false);
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

    if (_fetchedHomeAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Please get your home address."),
          backgroundColor: KColor.red,
        ),
      );
      return;
    }

    final authState = context.read<AuthCubit>().state;
    if (authState is AuthLoggedIn) {
      final user = authState.user;
      context.read<CustomerCubit>().createCustomerProfile(
            uid: user.uid,
            phoneNumber: user.phoneNumber ?? "N/A",
            fullName:
                "${_firstNameController.text.trim()} ${_lastNameController.text.trim()}",
            email: _email.text.trim(),
            imageFile: _imageFile,
            homeAddress:
                _fetchedHomeAddress ?? _homeAddressController.text.trim(),
            password: _password.text.trim(),
          );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error: User not logged in.")),
      );
    }
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
      body: BlocConsumer<CustomerCubit, CustomerState>(
          listener: (context, state) {
        if (state is CustomerProfileCreated) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Profile Created Successfully!")),
          );

          context.pushRlacement(AddPaymentMethod(
            redirectToPaymentMethods: false,
            email: _email.text,
            phone: _auth.currentUser!.phoneNumber ?? "",
          ));
        } else if (state is CustomerError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: KColor.red),
          );
        }
      }, builder: (context, state) {
        final isLoading = state is CustomerLoading;
        return SingleChildScrollView(
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
                      homeAddressController: _homeAddressController,
                      email: _email),
                  SizedBox(height: 10.h),
                  if (_fetchedHomeAddress != null)
                    Center(
                      child: Container(
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: KColor.lightGray.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          "Home Address: $_fetchedHomeAddress",
                          style: appStyle(
                              size: 14.sp,
                              color: KColor.primaryText,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                  SizedBox(height: 10.h),
                  _isFetchingAddress
                      ? Center(
                          child: CircularProgressIndicator(
                          color: KColor.primary,
                        ))
                      : Center(
                          child: SizedBox(
                            width: double.infinity,
                            height: 60.h,
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.my_location),
                              label: const Text("Get Current Location"),
                              onPressed: _fetchAddress,
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  side: BorderSide(width: 2.w),
                                  borderRadius: BorderRadius.circular(20.r),
                                ),
                                foregroundColor: KColor.primary,
                                side: BorderSide(color: KColor.primary),
                              ),
                            ),
                          ),
                        ),
                  SizedBox(height: 20.h),
                  // Terms and conditions
                  const TermsAndConditions(),
                  SizedBox(height: 17.h),
                  //register button
                  isLoading
                      ? Center(
                          child: CircularProgressIndicator(
                          color: KColor.primary,
                        ))
                      : RoundButton(
                          color: KColor.primary,
                          title: "NEXT",
                          onPressed: _submitProfile,
                        ),
                  SizedBox(height: 10.h),
                ],
              ),
            ),
          ),
        );
      }),
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
