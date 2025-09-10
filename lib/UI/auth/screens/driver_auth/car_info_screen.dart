import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:taxi_app/common/extensions.dart';
import 'package:taxi_app/common/text_style.dart';
import 'package:taxi_app/common_widgets/rounded_button.dart';
import 'package:taxi_app/common_widgets/txt_field_1.dart';
import 'package:taxi_app/UI/auth/screens/driver_auth/driver_documents_screen.dart';

class CarInfoScreen extends StatefulWidget {
  // This screen receives the data from the previous profile creation screen
  final String fullName;
  final String email;
  final File? profileImageFile;

  const CarInfoScreen({
    super.key,
    required this.fullName,
    required this.email,
    this.profileImageFile,
  });

  @override
  State<CarInfoScreen> createState() => _CarInfoScreenState();
}

class _CarInfoScreenState extends State<CarInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _carModelController = TextEditingController();
  final _licensePlateController = TextEditingController();

  File? _carImageFile;
  final ImagePicker _picker = ImagePicker();

  Color _selectedCarColor = Colors.black; // Default color

  void _showColorPickerDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pick a color'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: _selectedCarColor,
            onColorChanged: (color) {
              setState(() => _selectedCarColor = color);
            },
            pickerAreaHeightPercent: 0.8,
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('DONE'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _pickCarImage() async {
    final pickedFile =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      setState(() {
        _carImageFile = File(pickedFile.path);
      });
    }
  }

  void _submitCarInfo() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    if (_carImageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please upload a photo of your car.")),
      );
      return;
    }

    // --- THE EDIT IS HERE ---
    // This screen no longer calls the cubit.
    // It navigates to the next screen, passing ALL the data collected so far.
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => DriverDocumentsScreen(
        // Pass data from the previous screen
        fullName: widget.fullName,
        email: widget.email,
        profileImageFile: widget.profileImageFile,
        // Pass data from this screen
        carModel: _carModelController.text.trim(),
        licensePlate: _licensePlateController.text.trim(),
        carColor: '#${_selectedCarColor.value.toRadixString(16).substring(2)}',
        carImageFile: _carImageFile,
      ),
    ));
  }

  @override
  void dispose() {
    _carModelController.dispose();
    _licensePlateController.dispose();
    super.dispose();
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
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 22.h),
              //title
              Text(
                "Add your car info",
                style: appStyle(
                  size: 25.sp,
                  color: KColor.primaryText,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 30.h),

              // Car Image Picker
              GestureDetector(
                onTap: _pickCarImage,
                child: Container(
                  height: 150.h,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12.r),
                    image: _carImageFile != null
                        ? DecorationImage(
                            image: FileImage(_carImageFile!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _carImageFile == null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.camera_alt,
                                  size: 40.r, color: Colors.grey[600]),
                              SizedBox(height: 8.h),
                              const Text("Upload a photo of your car"),
                            ],
                          ),
                        )
                      : null,
                ),
              ),
              SizedBox(height: 24.h),

              // Form Fields
              CustomTxtField1(
                controller: _carModelController,
                hintText: "Car Model (e.g., Toyota Corolla 2022)",
                keyboardType: TextInputType.text,
                isObscure: false,
                obscureText: false,
                errorText: "Please enter your car model",
              ),
              SizedBox(height: 16.h),
              CustomTxtField1(
                controller: _licensePlateController,
                hintText: "License Plate (e.g., ١٢٣ أ ب ج)",
                keyboardType: TextInputType.text,
                isObscure: false,
                obscureText: false,
                errorText: "Please enter your license plate",
              ),
              SizedBox(height: 16.h),

              // Color Picker Widget
              InkWell(
                onTap: _showColorPickerDialog,
                child: Container(
                  height: 58.h,
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Car Color"),
                      Container(
                        width: 30.w,
                        height: 30.h,
                        decoration: BoxDecoration(
                          color: _selectedCarColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 40.h),

              // Continue Button
              RoundButton(
                title: "CONTINUE",
                onPressed: _submitCarInfo,
                color: KColor.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
