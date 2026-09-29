import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _obscurePassword = true;

  static const Color primaryGreen = Color(0xFF087F5B);
  static const Color darkGreen = Color(0xFF063B2E);
  static const Color gold = Color(0xFFD9B44A);

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // =========================================================
  // LOGIN
  // Username ATAU Email + Password
  // =========================================================

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
    });

    try {
      final supabase = Supabase.instance.client;

      final loginValue = _loginController.text.trim();
      final password = _passwordController.text;

      String? email;

      // =====================================================
      // LOGIN DENGAN EMAIL
      // =====================================================

      if (loginValue.contains('@')) {
        email = loginValue;
      }

      // =====================================================
      // LOGIN DENGAN USERNAME
      // =====================================================

      else {
        final profile = await supabase
            .from('profiles')
            .select('id, username')
            .ilike(
              'username',
              loginValue,
            )
            .maybeSingle();

        if (profile == null) {
          if (!mounted) return;

          _showMessage(
            'Username tidak ditemukan.',
            isError: true,
          );

          return;
        }

        final userId = profile['id']?.toString();

        if (userId == null || userId.isEmpty) {
          if (!mounted) return;

          _showMessage(
            'Data akun tidak valid.',
            isError: true,
          );

          return;
        }

        // Ambil email berdasarkan user ID
        final result = await supabase.rpc(
          'get_email_by_user_id',
          params: {
            'target_user_id': userId,
          },
        );

        email = result?.toString();

        if (email == null || email.isEmpty) {
          if (!mounted) return;

          _showMessage(
            'Email akun tidak ditemukan.',
            isError: true,
          );

          return;
        }
      }

      // =====================================================
      // SUPABASE LOGIN
      // =====================================================

      final response =
          await supabase.auth.signInWithPassword(
        email: email!,
        password: password,
      );

      if (!mounted) return;

      if (response.user == null) {
        _showMessage(
          'Login gagal. Silakan coba lagi.',
          isError: true,
        );

        return;
      }

      // =====================================================
      // CEK ROLE
      // =====================================================

      await _goToDashboard(
        response.user!.id,
      );
    } on AuthException catch (e) {
      if (!mounted) return;

      String message = e.message;

      if (e.message
          .toLowerCase()
          .contains('invalid login credentials')) {
        message =
            'Username/email atau password salah.';
      }

      _showMessage(
        message,
        isError: true,
      );
    } catch (e) {
      debugPrint(
        'Login error: $e',
      );

      if (!mounted) return;

      _showMessage(
        'Terjadi kesalahan saat login.',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // =========================================================
  // MASUK KE DASHBOARD BERDASARKAN ROLE
  // =========================================================

  Future<void> _goToDashboard(
    String userId,
  ) async {
    try {
      final supabase = Supabase.instance.client;

      final profile = await supabase
          .from('profiles')
          .select('role')
          .eq('id', userId)
          .maybeSingle();

      if (!mounted) return;

      if (profile == null) {
        _showMessage(
          'Profil akun belum tersedia. Silakan hubungi admin.',
          isError: true,
        );

        await supabase.auth.signOut();

        return;
      }

      final role = profile['role']
          ?.toString()
          .toLowerCase();

      if (role == 'admin') {
        Navigator.pushReplacementNamed(
          context,
          '/admin',
        );
      } else {
        Navigator.pushReplacementNamed(
          context,
          '/user',
        );
      }
    } catch (e) {
      debugPrint(
        'Profile error: $e',
      );

      if (!mounted) return;

      _showMessage(
        'Profil pengguna tidak dapat dibaca.',
        isError: true,
      );
    }
  }

  // =========================================================
  // SNACKBAR
  // =========================================================

  void _showMessage(
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: isError
            ? Colors.red.shade700
            : primaryGreen,
        behavior:
            SnackBarBehavior.floating,
        margin:
            const EdgeInsets.all(16),
        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(14),
        ),
      ),
    );
  }

  // =========================================================
  // INPUT STYLE
  // =========================================================

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: Colors.grey.shade500,
        fontSize: 14,
      ),
      prefixIcon: Icon(
        icon,
        color: primaryGreen,
        size: 21,
      ),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor:
          const Color(0xFFF5F8F6),
      contentPadding:
          const EdgeInsets.symmetric(
        horizontal: 17,
        vertical: 15,
      ),
      border:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(14),
        borderSide:
            BorderSide.none,
      ),
      enabledBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(14),
        borderSide:
            BorderSide(
          color:
              Colors.grey.shade200,
        ),
      ),
      focusedBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(14),
        borderSide:
            const BorderSide(
          color: primaryGreen,
          width: 1.4,
        ),
      ),
      errorBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(14),
        borderSide:
            const BorderSide(
          color: Colors.red,
        ),
      ),
      focusedErrorBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(14),
        borderSide:
            const BorderSide(
          color: Colors.red,
          width: 1.4,
        ),
      ),
    );
  }

  // =========================================================
  // LOGO ABNAZ
  // =========================================================

  Widget _buildLogo({
    double size = 90,
  }) {
    return Container(
      width: size,
      height: size,
      decoration:
          BoxDecoration(
        borderRadius:
            BorderRadius.circular(
          size * 0.28,
        ),
        gradient:
            const LinearGradient(
          begin:
              Alignment.topLeft,
          end:
              Alignment.bottomRight,
          colors: [
            Color(0xFF6E9C7C),
            Color(0xFF527760),
            Color(0xFF3D5F4C),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color:
                primaryGreen.withValues(
              alpha: 0.18,
            ),
            blurRadius: 22,
            offset:
                const Offset(0, 10),
          ),
        ],
        border:
            Border.all(
          color:
              Colors.white.withValues(
            alpha: 0.16,
          ),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: size * 0.17,
            right: size * 0.17,
            child: Container(
              width:
                  size * 0.30,
              height:
                  size * 0.30,
              decoration:
                  BoxDecoration(
                shape:
                    BoxShape.circle,
                color:
                    Colors.white.withValues(
                  alpha: 0.05,
                ),
              ),
            ),
          ),
          Center(
            child: CustomPaint(
              size: Size(
                size * 0.68,
                size * 0.68,
              ),
              painter:
                  _AbnazLogoPainter(),
            ),
          ),
          Positioned(
            top: size * 0.22,
            right: size * 0.20,
            child: Transform.rotate(
              angle: -0.35,
              child: Container(
                width:
                    size * 0.20,
                height:
                    size * 0.085,
                decoration:
                    BoxDecoration(
                  color: gold,
                  borderRadius:
                      BorderRadius.circular(
                    20,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF7FAF8),
      body: LayoutBuilder(
        builder:
            (context, constraints) {
          final width =
              constraints.maxWidth;

          final isDesktop =
              width >= 850;

          if (isDesktop) {
            return _buildDesktop();
          }

          return _buildMobile();
        },
      ),
    );
  }

  // =========================================================
  // DESKTOP
  // =========================================================

  Widget _buildDesktop() {
    return Row(
      children: [
        // =====================================================
        // BAGIAN KIRI
        // =====================================================

        Expanded(
          flex: 45,
          child: Container(
            height: double.infinity,
            decoration:
                const BoxDecoration(
              gradient:
                  LinearGradient(
                begin:
                    Alignment.topLeft,
                end:
                    Alignment.bottomRight,
                colors: [
                  Color(0xFF3D6550),
                  Color(0xFF4D755D),
                  Color(0xFF557C65),
                ],
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: -100,
                  left: -100,
                  child:
                      _decorCircle(
                    300,
                    0.06,
                  ),
                ),
                Positioned(
                  bottom: -100,
                  right: -100,
                  child:
                      _decorCircle(
                    300,
                    0.07,
                  ),
                ),
                Center(
                  child: Padding(
                    padding:
                        const EdgeInsets.all(
                      35,
                    ),
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        _buildLogo(
                          size: 135,
                        ),

                        const SizedBox(
                          height: 22,
                        ),

                        const Text(
                          'ABNAZ',
                          style:
                              TextStyle(
                            fontSize: 43,
                            fontWeight:
                                FontWeight.w500,
                            letterSpacing:
                                8,
                            color:
                                Colors.white,
                          ),
                        ),

                        const SizedBox(
                          height: 13,
                        ),

                        Container(
                          width: 72,
                          height: 4,
                          decoration:
                              BoxDecoration(
                            color: gold,
                            borderRadius:
                                BorderRadius.circular(
                              20,
                            ),
                          ),
                        ),

                        const SizedBox(
                          height: 17,
                        ),

                        const Text(
                          'Kelola dengan Amanah',
                          textAlign:
                              TextAlign.center,
                          style:
                              TextStyle(
                            fontSize: 17,
                            fontWeight:
                                FontWeight.w400,
                            letterSpacing:
                                1,
                            color:
                                Color(
                              0xFFF0F5F1,
                            ),
                          ),
                        ),

                        const SizedBox(
                          height: 35,
                        ),

                        const Text(
                          'Kelola keuangan dengan\nlebih aman, tertata, dan terkendali.',
                          textAlign:
                              TextAlign.center,
                          style:
                              TextStyle(
                            fontSize: 14,
                            height: 1.6,
                            color:
                                Color(
                              0xD9FFFFFF,
                            ),
                          ),
                        ),

                        const SizedBox(
                          height: 42,
                        ),

                        const Text(
                          'AMANAH • TERTATA • TERKENDALI',
                          style:
                              TextStyle(
                            fontSize: 9,
                            fontWeight:
                                FontWeight.w600,
                            letterSpacing:
                                1.7,
                            color:
                                Color(
                              0xBDE9F6F1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // =====================================================
        // BAGIAN KANAN
        // =====================================================

        Expanded(
          flex: 55,
          child: Center(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 40,
              ),
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(
                  maxWidth: 510,
                ),
                child:
                    _buildLoginCard(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // =========================================================
  // MOBILE
  // =========================================================

  Widget _buildMobile() {
    return SafeArea(
      child: SingleChildScrollView(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 22,
          vertical: 25,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(
              maxWidth: 500,
            ),
            child: Column(
              children: [
                _buildLogo(
                  size: 82,
                ),

                const SizedBox(
                  height: 14,
                ),

                const Text(
                  'ABNAZ',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight:
                        FontWeight.w600,
                    letterSpacing: 5,
                    color: darkGreen,
                  ),
                ),

                const SizedBox(
                  height: 5,
                ),

                const Text(
                  'Kelola dengan Amanah',
                  style: TextStyle(
                    fontSize: 13,
                    color:
                        primaryGreen,
                    fontWeight:
                        FontWeight.w500,
                  ),
                ),

                const SizedBox(
                  height: 25,
                ),

                _buildLoginCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================
  // LOGIN CARD
  // =========================================================

  Widget _buildLoginCard() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(28),
      decoration:
          BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(26),
        border: Border.all(
          color:
              Colors.grey.shade100,
        ),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withValues(
              alpha: 0.055,
            ),
            blurRadius: 35,
            offset:
                const Offset(0, 15),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              'Selamat Datang Kembali',
              style: TextStyle(
                fontSize: 24,
                fontWeight:
                    FontWeight.w800,
                color:
                    Color(0xFF17201C),
              ),
            ),

            const SizedBox(
              height: 6,
            ),

            Text(
              'Masuk ke ABNAZ dan kelola keuangan Anda dengan amanah.',
              style: TextStyle(
                fontSize: 13,
                height: 1.45,
                color:
                    Colors.grey.shade600,
              ),
            ),

            const SizedBox(
              height: 22,
            ),

            const Text(
              'Username atau Email',
              style: TextStyle(
                fontSize: 13,
                fontWeight:
                    FontWeight.w700,
                color:
                    Color(0xFF26352F),
              ),
            ),

            const SizedBox(
              height: 7,
            ),

            TextFormField(
              controller:
                  _loginController,
              keyboardType:
                  TextInputType.text,
              textInputAction:
                  TextInputAction.next,
              decoration:
                  _inputDecoration(
                hint:
                    'Username atau email',
                icon:
                    Icons.person_outline,
              ),
              validator: (value) {
                if (value == null ||
                    value.trim().isEmpty) {
                  return 'Username atau email wajib diisi';
                }

                return null;
              },
            ),

            const SizedBox(
              height: 15,
            ),

            const Text(
              'Password',
              style: TextStyle(
                fontSize: 13,
                fontWeight:
                    FontWeight.w700,
                color:
                    Color(0xFF26352F),
              ),
            ),

            const SizedBox(
              height: 7,
            ),

            TextFormField(
              controller:
                  _passwordController,
              obscureText:
                  _obscurePassword,
              textInputAction:
                  TextInputAction.done,
              onFieldSubmitted: (_) {
                if (!_isLoading) {
                  _login();
                }
              },
              decoration:
                  _inputDecoration(
                hint:
                    'Masukkan password',
                icon:
                    Icons.lock_outline,
                suffixIcon:
                    IconButton(
                  onPressed: () {
                    setState(() {
                      _obscurePassword =
                          !_obscurePassword;
                    });
                  },
                  icon: Icon(
                    _obscurePassword
                        ? Icons
                            .visibility_outlined
                        : Icons
                            .visibility_off_outlined,
                    color:
                        Colors.grey.shade500,
                  ),
                ),
              ),
              validator: (value) {
                if (value == null ||
                    value.isEmpty) {
                  return 'Password wajib diisi';
                }

                if (value.length < 6) {
                  return 'Password minimal 6 karakter';
                }

                return null;
              },
            ),

            const SizedBox(
              height: 7,
            ),

            Align(
              alignment:
                  Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  _showMessage(
                    'Fitur lupa password akan kita buat nanti.',
                  );
                },
                style:
                    TextButton.styleFrom(
                  padding:
                      EdgeInsets.zero,
                  minimumSize:
                      Size.zero,
                  tapTargetSize:
                      MaterialTapTargetSize
                          .shrinkWrap,
                ),
                child: const Text(
                  'Lupa password?',
                  style:
                      TextStyle(
                    color:
                        primaryGreen,
                    fontWeight:
                        FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ),

            const SizedBox(
              height: 10,
            ),

            // =================================================
            // BUTTON MASUK
            // =================================================

            SizedBox(
              width:
                  double.infinity,
              height: 50,
              child:
                  ElevatedButton(
                onPressed:
                    _isLoading
                        ? null
                        : _login,
                style:
                    ElevatedButton.styleFrom(
                  backgroundColor:
                      primaryGreen,
                  foregroundColor:
                      Colors.white,
                  disabledBackgroundColor:
                      primaryGreen
                          .withValues(
                    alpha: 0.5,
                  ),
                  elevation: 0,
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                      14,
                    ),
                  ),
                ),
                child:
                    _isLoading
                        ? const SizedBox(
                            width: 21,
                            height: 21,
                            child:
                                CircularProgressIndicator(
                              strokeWidth:
                                  2.4,
                              color:
                                  Colors.white,
                            ),
                          )
                        : const Text(
                            'Masuk',
                            style:
                                TextStyle(
                              fontSize:
                                  15,
                              fontWeight:
                                  FontWeight.w700,
                            ),
                          ),
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            // =================================================
            // REGISTER
            // =================================================

            Center(
              child: Wrap(
                alignment:
                    WrapAlignment.center,
                children: [
                  Text(
                    'Belum punya akun? ',
                    style:
                        TextStyle(
                      color:
                          Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/register',
                      );
                    },
                    child: const Text(
                      'Daftar sekarang',
                      style:
                          TextStyle(
                        color:
                            primaryGreen,
                        fontSize: 13,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // DECORATION CIRCLE
  // =========================================================

  Widget _decorCircle(
    double size,
    double opacity,
  ) {
    return Container(
      width: size,
      height: size,
      decoration:
          BoxDecoration(
        shape: BoxShape.circle,
        color:
            Colors.white.withValues(
          alpha: opacity,
        ),
      ),
    );
  }
}

// =============================================================
// LOGO ABNAZ
// =============================================================

class _AbnazLogoPainter
    extends CustomPainter {
  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final paint = Paint()
      ..style =
          PaintingStyle.stroke
      ..strokeWidth =
          size.width * 0.12
      ..strokeCap =
          StrokeCap.round
      ..strokeJoin =
          StrokeJoin.round;

    paint.shader =
        const LinearGradient(
      begin:
          Alignment.topLeft,
      end:
          Alignment.bottomRight,
      colors: [
        Colors.white,
        Color(0xFFF1FAF3),
        Color(0xFFBDE5C8),
      ],
    ).createShader(
      Rect.fromLTWH(
        0,
        0,
        size.width,
        size.height,
      ),
    );

    final path =
        Path();

    path.moveTo(
      size.width * 0.10,
      size.height * 0.84,
    );

    path.lineTo(
      size.width * 0.45,
      size.height * 0.14,
    );

    path.quadraticBezierTo(
      size.width * 0.50,
      size.height * 0.04,
      size.width * 0.56,
      size.height * 0.14,
    );

    path.lineTo(
      size.width * 0.90,
      size.height * 0.84,
    );

    canvas.drawPath(
      path,
      paint,
    );

    final middlePaint =
        Paint()
          ..color =
              Colors.white
          ..strokeWidth =
              size.width * 0.085
          ..strokeCap =
              StrokeCap.round;

    canvas.drawLine(
      Offset(
        size.width * 0.30,
        size.height * 0.58,
      ),
      Offset(
        size.width * 0.70,
        size.height * 0.58,
      ),
      middlePaint,
    );

    final growthPaint =
        Paint()
          ..color =
              const Color(
            0xFFB9E5C5,
          )
          ..strokeWidth =
              size.width * 0.065
          ..strokeCap =
              StrokeCap.round;

    canvas.drawLine(
      Offset(
        size.width * 0.38,
        size.height * 0.61,
      ),
      Offset(
        size.width * 0.38,
        size.height * 0.77,
      ),
      growthPaint,
    );

    canvas.drawLine(
      Offset(
        size.width * 0.50,
        size.height * 0.52,
      ),
      Offset(
        size.width * 0.50,
        size.height * 0.77,
      ),
      growthPaint,
    );

    canvas.drawLine(
      Offset(
        size.width * 0.62,
        size.height * 0.40,
      ),
      Offset(
        size.width * 0.62,
        size.height * 0.77,
      ),
      growthPaint,
    );
  }

  @override
  bool shouldRepaint(
    covariant CustomPainter oldDelegate,
  ) {
    return false;
  }
}