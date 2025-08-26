import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/auth_repository.dart';
import 'driver_event.dart';
import 'driver_state.dart';

class DriverBloc extends Bloc<DriverEvent, DriverState> {
  final AuthRepository authRepository;

  DriverBloc({required this.authRepository}) : super(DriverInitial()) {
    on<AddDriverRequested>(_onAddDriverRequested);
    on<LoadDriversRequested>(_onLoadDriversRequested);
  }

  void _onAddDriverRequested(AddDriverRequested event, Emitter<DriverState> emit) async {
    emit(DriverLoading());
    try {
      final success = await authRepository.addDriver(event.name, event.phoneNumber);
      if (success) {
        emit(DriverAddSuccess());
        // Auto-load drivers after successful addition
        add(LoadDriversRequested());
      } else {
        emit(DriverFailure(message: "Failed to add driver"));
      }
    } catch (e) {
      emit(DriverFailure(message: e.toString().replaceAll('Exception: ', '')));
    }
  }

  void _onLoadDriversRequested(LoadDriversRequested event, Emitter<DriverState> emit) async {
    emit(DriverLoading());
    try {
      final drivers = await authRepository.getDrivers();
      emit(DriversLoaded(drivers: drivers));
    } catch (e) {
      emit(DriverFailure(message: e.toString().replaceAll('Exception: ', '')));
    }
  }
}
