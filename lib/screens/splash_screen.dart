import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;

  late Animation<double> _logoScale;
  late Animation<double> _logoFade;
  late Animation<Offset> _textSlide;
  late Animation<double> _textFade;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _logoScale = CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeOutBack,
    );

    _logoFade = CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeIn,
    );

    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _textController,
        curve: Curves.easeOutCubic,
      ),
    );

    _textFade = CurvedAnimation(
      parent: _textController,
      curve: Curves.easeIn,
    );

    _startSplash();
  }

  Future<void> _startSplash() async {
    _logoController.forward();

    await Future.delayed(
      const Duration(milliseconds: 350),
    );

    if (!mounted) return;

    _textController.forward();

    await Future.delayed(
      const Duration(milliseconds: 2200),
    );

    if (!mounted) return;

    await _checkLogin();
  }

  Future<void> _checkLogin() async {
    try {
      final supabase = Supabase.instance.client;

      final session = supabase.auth.currentSession;

      // Belum login
      if (session == null) {
        if (!mounted) return;

        Navigator.pushReplacementNamed(
          context,
          '/login',
        );

        return;
      }

      // Sudah login → cek role
      final profile = await supabase
          .from('profiles')
          .select('role')
          .eq('id', session.user.id)
          .maybeSingle();

      if (!mounted) return;

      // Session ada tetapi profile tidak ada
      if (profile == null) {
        await supabase.auth.signOut();

        if (!mounted) return;

        Navigator.pushReplacementNamed(
          context,
          '/login',
        );

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
        'Splash login check error: $e',
      );

      if (!mounted) return;

      Navigator.pushReplacementNamed(
        context,
        '/login',
      );
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF3D6550),
              Color(0xFF4D755D),
              Color(0xFF557C65),
            ],
            stops: [
              0.0,
              0.55,
              1.0,
            ],
          ),
        ),
        child: Stack(
          children: [
            // Dekorasi lingkaran kanan atas
            Positioned(
              top: -100,
              right: -80,
              child: _backgroundCircle(
                size: 260,
                opacity: 0.08,
              ),
            ),

            // Dekorasi kiri bawah
            Positioned(
              bottom: -120,
              left: -100,
              child: _backgroundCircle(
                size: 300,
                opacity: 0.06,
              ),
            ),

            // Dekorasi kiri tengah
            Positioned(
              top: MediaQuery.of(context).size.height * 0.18,
              left: -80,
              child: _backgroundCircle(
                size: 160,
                opacity: 0.04,
              ),
            ),

            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // =========================
                  // LOGO
                  // =========================
                  FadeTransition(
                    opacity: _logoFade,
                    child: ScaleTransition(
                      scale: _logoScale,
                      child: _buildLogo(),
                    ),
                  ),

                  const SizedBox(height: 52),

                  // =========================
                  // BRAND
                  // =========================
                  FadeTransition(
                    opacity: _textFade,
                    child: SlideTransition(
                      position: _textSlide,
                      child: Column(
                        children: [
                          const Text(
                            'ABNAZ',
                            style: TextStyle(
                              fontSize: 44,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 8,
                              color: Colors.white,
                            ),
                          ),

                          const SizedBox(height: 25),

                          // Garis gold
                          Container(
                            width: 82,
                            height: 4,
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFFD9B44A,
                              ),
                              borderRadius:
                                  BorderRadius.circular(20),
                            ),
                          ),

                          const SizedBox(height: 26),

                          const Text(
                            'Kelola dengan Amanah',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w400,
                              letterSpacing: 1.1,
                              color: Color(0xFFF1F5F2),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // =========================
            // FOOTER
            // =========================
            Positioned(
              bottom: 14,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _textFade,
                child: const Column(
                  children: [
                    Text(
                      'AMANAH • TERTATA • TERKENDALI',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.8,
                        color: Color(0xBDE9F6F1),
                      ),
                    ),

                    SizedBox(height: 12),

                    Text(
                      'Financial Management',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 0.8,
                        color: Color(0x99FFFFFF),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // LOGO ABNAZ
  // =========================================================

  Widget _buildLogo() {
    return Container(
      width: 155,
      height: 155,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(40),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF6E9C7C),
            Color(0xFF527760),
            Color(0xFF3D5F4C),
          ],
        ),
        border: Border.all(
          color: Colors.white.withValues(
            alpha: 0.18,
          ),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.15,
            ),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Lingkaran dekorasi kanan atas
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(
                  alpha: 0.05,
                ),
              ),
            ),
          ),

          // Logo utama
          Center(
            child: CustomPaint(
              size: const Size(
                105,
                105,
              ),
              painter: _AbnazLogoPainter(),
            ),
          ),

          // Aksen gold
          Positioned(
            top: 32,
            right: 30,
            child: Transform.rotate(
              angle: -0.35,
              child: Container(
                width: 31,
                height: 13,
                decoration: BoxDecoration(
                  color: const Color(
                    0xFFD9B44A,
                  ),
                  borderRadius:
                      BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _backgroundCircle({
    required double size,
    required double opacity,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(
          alpha: opacity,
        ),
      ),
    );
  }
}

// =============================================================
// PAINTER LOGO ABNAZ
// Konsep: A + N abstrak / ribbon / pertumbuhan
// =============================================================

class _AbnazLogoPainter extends CustomPainter {
  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Gradient putih → hijau muda
    paint.shader = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFFFFFFFF),
        Color(0xFFF4FBF6),
        Color(0xFFD6F0DC),
      ],
    ).createShader(
      Rect.fromLTWH(
        0,
        0,
        size.width,
        size.height,
      ),
    );

    // =========================================================
    // BAGIAN A
    // =========================================================

    final pathA = Path();

    pathA.moveTo(
      size.width * 0.12,
      size.height * 0.80,
    );

    pathA.lineTo(
      size.width * 0.42,
      size.height * 0.18,
    );

    pathA.quadraticBezierTo(
      size.width * 0.50,
      size.height * 0.02,
      size.width * 0.58,
      size.height * 0.18,
    );

    pathA.lineTo(
      size.width * 0.88,
      size.height * 0.80,
    );

    canvas.drawPath(
      pathA,
      paint,
    );

    // =========================================================
    // GARIS TENGAH A
    // =========================================================

    final middlePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

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

    // =========================================================
    // ELEMEN N / GROWTH
    // =========================================================

    final growthPaint = Paint()
      ..color = const Color(
        0xFFB8E7C5,
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    // Batang pertama
    canvas.drawLine(
      Offset(
        size.width * 0.38,
        size.height * 0.60,
      ),
      Offset(
        size.width * 0.38,
        size.height * 0.76,
      ),
      growthPaint,
    );

    // Batang kedua
    canvas.drawLine(
      Offset(
        size.width * 0.50,
        size.height * 0.51,
      ),
      Offset(
        size.width * 0.50,
        size.height * 0.76,
      ),
      growthPaint,
    );

    // Batang ketiga
    canvas.drawLine(
      Offset(
        size.width * 0.62,
        size.height * 0.39,
      ),
      Offset(
        size.width * 0.62,
        size.height * 0.76,
      ),
      growthPaint,
    );

    // =========================================================
    // GARIS DIAGONAL PERTUMBUHAN
    // =========================================================

    final growthLinePaint = Paint()
      ..color = const Color(
        0xFF9BDCB0,
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    final growthPath = Path();

    growthPath.moveTo(
      size.width * 0.35,
      size.height * 0.75,
    );

    growthPath.lineTo(
      size.width * 0.48,
      size.height * 0.61,
    );

    growthPath.lineTo(
      size.width * 0.59,
      size.height * 0.65,
    );

    growthPath.lineTo(
      size.width * 0.69,
      size.height * 0.47,
    );

    canvas.drawPath(
      growthPath,
      growthLinePaint,
    );
  }

  @override
  bool shouldRepaint(
    covariant CustomPainter oldDelegate,
  ) {
    return false;
  }
}