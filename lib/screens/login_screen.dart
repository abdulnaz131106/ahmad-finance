import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;

  final supabase = Supabase.instance.client;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> login() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    // ==========================================
    // CEK INPUT
    // ==========================================

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email dan password wajib diisi'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // ==========================================
      // 1. LOGIN SUPABASE AUTH
      // ==========================================

      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (!mounted) return;

      if (response.user == null) {
        throw Exception('Login gagal');
      }

      final userId = response.user!.id;

      // ==========================================
      // 2. AMBIL ROLE DARI TABEL PROFILES
      // ==========================================

      final profiles = await supabase
          .from('profiles')
          .select('role')
          .eq('id', userId);

      // ==========================================
      // 3. CEK APAKAH PROFILE ADA
      // ==========================================

      if (profiles.isEmpty) {
        throw Exception(
          'Profil pengguna belum tersedia di tabel profiles.',
        );
      }

      // ==========================================
      // 4. AMBIL ROLE
      // ==========================================

      final role = profiles[0]['role'];

      // ==========================================
      // 5. CEK ROLE
      // ==========================================

      if (!mounted) return;

      if (role == 'admin') {
        // ========================================
        // ADMIN
        // ========================================

        Navigator.pushReplacementNamed(
          context,
          '/admin',
        );
      } else if (role == 'user') {
        // ========================================
        // USER
        // ========================================

        Navigator.pushReplacementNamed(
          context,
          '/user',
        );
      } else {
        // ========================================
        // ROLE TIDAK DIKENAL
        // ========================================

        throw Exception(
          'Role pengguna tidak valid: $role',
        );
      }
    } on AuthException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.red,
        ),
      );
    } on PostgrestException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal mengambil data profil: ${e.message}',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login Ahmad Finance'),
      ),

      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            // ==========================================
            // JUDUL
            // ==========================================

            const Text(
              'Ahmad Finance',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              'Silakan login untuk melanjutkan',
            ),

            const SizedBox(height: 30),

            // ==========================================
            // EMAIL
            // ==========================================

            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),

            const SizedBox(height: 16),

            // ==========================================
            // PASSWORD
            // ==========================================

            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),

            const SizedBox(height: 24),

            // ==========================================
            // BUTTON LOGIN
            // ==========================================

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: isLoading ? null : login,
                child: isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'LOGIN',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 16),

            // ==========================================
            // REGISTER
            // ==========================================

            TextButton(
              onPressed: isLoading
                  ? null
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RegisterScreen(),
                        ),
                      );
                    },
              child: const Text(
                'Belum punya akun? Daftar',
              ),
            ),
          ],
        ),
      ),
    );
  }
}