import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Ahmad Finance'),
        backgroundColor: const Color(0xFF0B8F55),
        foregroundColor: Colors.white,
      ),

      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.admin_panel_settings,
              size: 90,
              color: Color(0xFF0B8F55),
            ),

            const SizedBox(height: 20),

            const Text(
              'Dashboard Admin',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              'Selamat datang, Admin Ahmad Finance',
            ),

            const SizedBox(height: 30),

            ElevatedButton.icon(
              onPressed: () async {
                await Supabase.instance.client.auth.signOut();

                if (!context.mounted) return;

                Navigator.pushReplacementNamed(
                  context,
                  '/',
                );
              },
              icon: const Icon(Icons.logout),
              label: const Text('LOGOUT'),
            ),
          ],
        ),
      ),
    );
  }
}