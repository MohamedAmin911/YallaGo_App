import 'package:meta/meta.dart';
import 'package:taxi_app/data_models/driver_model.dart';

@immutable
abstract class DriverState {}

class DriverInitial extends DriverState {}

class DriverLoading extends DriverState {}

class DriverProfileCreated extends DriverState {}

class DriverLoaded extends DriverState {
  final DriverModel driver;
  DriverLoaded({required this.driver});
}

class DriverError extends DriverState {
  final String message;
  DriverError({required this.message});
}
