import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'app/routes.dart';
import 'core/theme/theme.dart';
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
    debugPrint("Harap jalankan 'flutterfire configure' untuk menghubungkan aplikasi dengan Firebase console Anda.");
    debugPrint("Error detail: $e");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthBloc(repository: AuthRepository())
        ..add(AuthCheckRequested()),
      child: MaterialApp.router(
        title: 'Jagain',
        theme: AppTheme.lightTheme,
        routerConfig: AppRoutes.router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
