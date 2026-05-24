import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app/routes.dart';
import 'core/theme/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // =========================================================================
  // CATATAN UNTUK DEVELOPER:
  // Jalankan perintah "flutterfire configure" di root terminal untuk 
  // menghasilkan berkas firebase_options.dart yang berisi konfigurasi Firebase.
  // Setelah selesai, impor DefaultFirebaseOptions dan tambahkan parameter 'options'.
  // =========================================================================
  try {
    await Firebase.initializeApp();
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
    return MaterialApp.router(
      title: 'Jagain',
      theme: AppTheme.lightTheme,
      routerConfig: AppRoutes.router,
      debugShowCheckedModeBanner: false,
    );
  }
}
