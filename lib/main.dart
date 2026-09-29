import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_config.dart';

import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';

import 'screens/user_dashboard.dart';
import 'screens/admin_dashboard.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting(
    'id_ID',
    null,
  );

  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.publishableKey,
  );

  runApp(
    const AbnazApp(),
  );
}

class AbnazApp extends StatelessWidget {
  const AbnazApp({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      title: 'ABNAZ',

      theme: ThemeData(
        useMaterial3: true,

        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(
            0xFF087F5B,
          ),
        ),

        scaffoldBackgroundColor:
            const Color(0xFFF8FAF7),

        fontFamily: 'Arial',
      ),

      // =====================================================
      // ROUTES
      // =====================================================

      routes: {
        // Splash
        '/splash': (context) =>
            const SplashScreen(),

        // Login
        '/login': (context) =>
            const LoginScreen(),

        // Register
        '/register': (context) =>
            const RegisterScreen(),

        // User
        '/user': (context) =>
            const UserDashboard(),

        // Admin
        '/admin': (context) =>
            const AdminDashboard(),
      },

      // =====================================================
      // HALAMAN AWAL
      // =====================================================

      home: const SplashScreen(),
    );
  }
}