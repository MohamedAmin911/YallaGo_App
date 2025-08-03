import 'package:meta/meta.dart';
import 'package:taxi_app/data_models/driver_model.dart';

@immutable
abstract class DriverState {}

/// The initial state before any driver data has been loaded.
class DriverInitial extends DriverState {}

/// Indicates that a driver-related operation (like creating a profile) is in progress.
class DriverLoading extends DriverState {}

/// State emitted when the driver's profile has been successfully created.
class DriverProfileCreated extends DriverState {}

/// State emitted when the driver's profile data has been successfully loaded.
/// It carries the `DriverModel` object for the UI to display.
class DriverLoaded extends DriverState {
  final DriverModel driver;
  DriverLoaded({required this.driver});
}

/// State emitted when an error occurs while fetching or updating driver data.
class DriverError extends DriverState {
  final String message;
  DriverError({required this.message});
}
