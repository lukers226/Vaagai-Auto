import 'package:get_it/get_it.dart';
import 'data/services/api_service.dart';
import 'data/repositories/auth_repository.dart';
import 'presentation/bloc/auth/auth_bloc.dart';
import 'presentation/bloc/driver/driver_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // Services
  sl.registerLazySingleton(() => ApiService());

  // Repository
  sl.registerLazySingleton(() => AuthRepository(apiService: sl()));

  // BLoCs
  sl.registerFactory(() => AuthBloc(authRepository: sl()));
  sl.registerFactory(() => DriverBloc(authRepository: sl()));
}
