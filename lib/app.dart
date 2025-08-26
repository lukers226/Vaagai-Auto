import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/theme/app_theme.dart';
import 'presentation/bloc/auth/auth_bloc.dart';
import 'presentation/bloc/driver/driver_bloc.dart';
import 'presentation/pages/splash_page.dart';
import 'injection_container.dart' as di;

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (_) => di.sl<AuthBloc>(),
        ),
        BlocProvider<DriverBloc>(
          create: (_) => di.sl<DriverBloc>(),
        ),
      ],
      child: MaterialApp(
        title: 'Auto Meter App',
        theme: AppTheme.lightTheme,
        home: SplashPage(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
