abstract class DriverEvent {}

class AddDriverRequested extends DriverEvent {
  final String name;
  final String phoneNumber;
  
  AddDriverRequested({required this.name, required this.phoneNumber});
}

class LoadDriversRequested extends DriverEvent {}
