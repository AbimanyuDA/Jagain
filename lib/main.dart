import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'app/routes.dart';
import 'core/theme/theme.dart';
import 'core/theme/theme_cubit.dart';
import 'firebase_options.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint("Pemberitahuan: Inisialisasi Firebase gagal.");
    debugPrint(
      "Harap jalankan 'flutterfire configure' untuk menghubungkan aplikasi dengan Firebase console Anda.",
    );
    debugPrint("Error detail: $e");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ThemeCubit()),
        BlocProvider(
          create: (_) => AuthBloc(repository: AuthRepository())
            ..add(AuthCheckRequested()),
        ),
      ],
      child: const _AppView(),
    );
  }
}

class _AppView extends StatefulWidget {
  const _AppView();

  @override
  State<_AppView> createState() => _AppViewState();
}

class _AppViewState extends State<_AppView> {
  GoRouter? _router;

  @override
  Widget build(BuildContext context) {
    _router ??= AppRoutes.createRouter(context);
    return MaterialApp.router(
      title: 'Jagain',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      routerConfig: _router!,
      debugShowCheckedModeBanner: false,
    );
  }
}
