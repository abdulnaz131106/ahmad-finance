import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_config.dart';
import 'screens/splash_screen.dart';
import 'screens/user_dashboard.dart';
import 'screens/admin_dashboard.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.publishableKey,
  );

  runApp(const AhmadFinanceApp());
}

class AhmadFinanceApp extends StatelessWidget {
  const AhmadFinanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ahmad Finance',

      routes: {
        '/user': (context) => const UserDashboard(),
        '/admin': (context) => const AdminDashboard(),
      },

      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0B8F55),
        ),
      ),

      home: const SplashScreen(),
    );
  }
}