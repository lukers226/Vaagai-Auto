import 'package:get_it/get_it.dart';
import 'data/services/api_service.dart';
import 'data/repositories/auth_repository.dart';
import 'presentation/bloc/auth/auth_bloc.dart';
import 'presentation/bloc/driver/driver_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  
  sl.registerLazySingleton(() => ApiService()); // Service

  
  sl.registerLazySingleton(() => AuthRepository(apiService: sl())); // Repository

  
  sl.registerFactory(() => AuthBloc(authRepository: sl())); //Bloc codes
  sl.registerFactory(() => DriverBloc(authRepository: sl()));
}
