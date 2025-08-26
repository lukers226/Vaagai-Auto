import '../../../data/models/driver_model.dart';

abstract class DriverState {}

class DriverInitial extends DriverState {}

class DriverLoading extends DriverState {}

class DriverAddSuccess extends DriverState {}

class DriversLoaded extends DriverState {
  final List<DriverModel> drivers;
  DriversLoaded({required this.drivers});
}

class DriverFailure extends DriverState {
  final String message;
  DriverFailure({required this.message});
}
