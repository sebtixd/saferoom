import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/theme/app_theme.dart';
import 'injection_container.dart';
import 'presentation/blocs/auth/auth_bloc.dart';
import 'presentation/blocs/game/game_bloc.dart';
import 'presentation/screens/splash/splash_screen.dart';

class SafeRoomApp extends StatelessWidget {
  const SafeRoomApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SafeRoom',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: Builder(
        builder: (context) {
          // DI is initialized by SplashScreen after first frame. Until then,
          // show the splash without BLoCs to keep startup fast.
          if (!sl.isRegistered<AuthBloc>() || !sl.isRegistered<GameBloc>()) {
            return const SplashScreen();
          }
          return MultiBlocProvider(
            providers: [
              BlocProvider(create: (_) => sl<AuthBloc>()),
              BlocProvider(create: (_) => sl<GameBloc>()),
            ],
            child: const SplashScreen(),
          );
        },
      ),
    );
  }
}
