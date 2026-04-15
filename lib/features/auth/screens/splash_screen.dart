import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;

// ─── Splash Screen ────────────────────────────────────────────────────────────
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  // ── Controllers ──────────────────────────────────────────────────────────────
  late AnimationController _logoCtrl;
  late AnimationController _ringCtrl;
  late AnimationController _textCtrl;
  late AnimationController _barCtrl;
  late AnimationController _particleCtrl;
  late AnimationController _pulseCtrl;

  // ── Animations ───────────────────────────────────────────────────────────────
  late Animation<double> _logoScale;
  late Animation<double> _logoFade;
  late Animation<double> _ring1;
  late Animation<double> _ring2;
  late Animation<double> _textFade;
  late Animation<double> _textY;
  late Animation<double> _barWidth;
  late Animation<double> _shimmer;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF05051A),
    ));

    _logoCtrl     = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _ringCtrl     = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))..repeat();
    _textCtrl     = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _barCtrl      = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000));
    _particleCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();
    _pulseCtrl    = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat(reverse: true);

    // Logo
    _logoScale = CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut).drive(Tween(begin: 0.0, end: 1.0));
    _logoFade  = CurvedAnimation(parent: _logoCtrl, curve: const Interval(0.0, 0.4)).drive(Tween(begin: 0.0, end: 1.0));

    // Rings
    _ring1 = CurvedAnimation(parent: _ringCtrl, curve: Curves.easeInOut).drive(Tween(begin: 0.0, end: 1.0));
    _ring2 = CurvedAnimation(parent: _ringCtrl, curve: const Interval(0.3, 1.0, curve: Curves.easeInOut)).drive(Tween(begin: 0.0, end: 1.0));

    // Text
    _textFade = CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut).drive(Tween(begin: 0.0, end: 1.0));
    _textY    = CurvedAnimation(parent: _textCtrl, curve: Curves.easeOutCubic).drive(Tween(begin: 24.0, end: 0.0));

    // Progress bar
    _barWidth = CurvedAnimation(parent: _barCtrl, curve: Curves.easeInOut).drive(Tween(begin: 0.0, end: 1.0));

    // Shimmer on logo
    _shimmer = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat()
      ..drive(Tween(begin: -1.0, end: 2.0));

    // Pulse glow
    _pulse = CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut).drive(Tween(begin: 0.7, end: 1.0));

    // Sequence
    _logoCtrl.forward().then((_) {
      _textCtrl.forward().then((_) {
        _barCtrl.forward();
      });
    });
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _ringCtrl.dispose();
    _textCtrl.dispose();
    _barCtrl.dispose();
    _particleCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: const Color(0xFF05051A),
      body: Stack(
        children: [
          // ── Background: Deep Ambient Blobs ───────────────────────────────
          Positioned(top: -80, left: -60,
            child: _GlowBlob(width: 320, height: 320, color: const Color(0xFF0284C7).withOpacity(0.18), blur: 90)),
          Positioned(bottom: -100, right: -80,
            child: _GlowBlob(width: 360, height: 360, color: const Color(0xFF0891B2).withOpacity(0.14), blur: 110)),
          Positioned(top: size.height * 0.4, left: size.width * 0.6,
            child: _GlowBlob(width: 200, height: 200, color: const Color(0xFF0EA5E9).withOpacity(0.10), blur: 80)),

          // ── Grid mesh ────────────────────────────────────────────────────
          CustomPaint(size: size, painter: _GridPainter()),

          // ── Floating Particles ───────────────────────────────────────────
          AnimatedBuilder(
            animation: _particleCtrl,
            builder: (_, __) => CustomPaint(
              size: size,
              painter: _ParticlePainter(_particleCtrl.value),
            ),
          ),

          // ── Main Content (centered) ───────────────────────────────────────
          SizedBox.expand(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Spacer(flex: 3),

                // ── Logo Block ─────────────────────────────────────────────
                AnimatedBuilder(
                  animation: Listenable.merge([_logoCtrl, _ringCtrl, _pulseCtrl]),
                  builder: (_, __) => Opacity(
                    opacity: _logoFade.value,
                    child: Transform.scale(
                      scale: _logoScale.value,
                      child: SizedBox(
                        width: 180, height: 180,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Outer pulsing glow aura
                            Container(
                              width: 180 * _pulse.value,
                              height: 180 * _pulse.value,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    const Color(0xFF0284C7).withOpacity(0.22 * _pulse.value),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                            // Ring 1 — sweeping
                            _AnimatedRing(progress: _ring1.value, radius: 82, strokeWidth: 1.2, color: const Color(0xFF6366F1).withOpacity(0.4)),
                            // Ring 2 — offset sweep
                            _AnimatedRing(progress: _ring2.value, radius: 70, strokeWidth: 0.8, color: const Color(0xFF818CF8).withOpacity(0.25), reverse: true),
                            // Inner glowing circle
                            Container(
                              width: 116, height: 116,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                                  colors: [Color(0xFF6366F1), Color(0xFF0284C7), Color(0xFF0891B2)],
                                ),
                                boxShadow: [
                                  BoxShadow(color: const Color(0xFF0284C7).withOpacity(0.7 * _pulse.value), blurRadius: 40, spreadRadius: 4),
                                  BoxShadow(color: const Color(0xFF0284C7).withOpacity(0.3), blurRadius: 70, spreadRadius: 10),
                                ],
                              ),
                              child: ClipOval(
                                child: Stack(
                                  children: [
                                    Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text('MFL',
                                            style: GoogleFonts.inter(
                                              fontSize: 26, fontWeight: FontWeight.w900,
                                              color: Colors.white, letterSpacing: 2,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.12),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text('ELmana',
                                              style: GoogleFonts.inter(
                                                fontSize: 9, fontWeight: FontWeight.w600,
                                                color: Colors.white70, letterSpacing: 1.5,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Shimmer sweep
                                    AnimatedBuilder(
                                      animation: _shimmer,
                                      builder: (_, __) => Positioned.fill(
                                        child: Transform.translate(
                                          offset: Offset(_shimmer.value * 150, 0),
                                          child: Container(
                                            width: 50,
                                            decoration: const BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [Colors.transparent, Color(0x33FFFFFF), Colors.transparent],
                                              ),
                                            ),
                                          ),
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
                  ),
                ),

                const SizedBox(height: 44),

                // ── Brand Text ─────────────────────────────────────────────
                AnimatedBuilder(
                  animation: _textCtrl,
                  builder: (_, __) => Opacity(
                    opacity: _textFade.value,
                    child: Transform.translate(
                      offset: Offset(0, _textY.value),
                      child: Column(
                        children: [
                          // Main title
                          ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [Color(0xFFE0E7FF), Colors.white, Color(0xFFC7D2FE)],
                            ).createShader(bounds),
                            child: Text(
                              'MFL RAJKOT',
                              style: GoogleFonts.inter(
                                fontSize: 32, fontWeight: FontWeight.w900,
                                color: Colors.white, letterSpacing: 4,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          // Subtitle line
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _Diamond(),
                              const SizedBox(width: 10),
                              Text(
                                'Modern Future Language Excellence',
                                style: GoogleFonts.inter(
                                  fontSize: 11, color: const Color(0xFF6B7280),
                                  letterSpacing: 1.5, fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 10),
                              _Diamond(),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const Spacer(flex: 3),

                // ── Progress Bar ───────────────────────────────────────────
                AnimatedBuilder(
                  animation: _barCtrl,
                  builder: (_, __) => Opacity(
                    opacity: _barCtrl.value.clamp(0.0, 1.0),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 60),
                      child: Column(
                        children: [
                          // Track
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Stack(
                              children: [
                                Container(height: 3, color: Colors.white.withOpacity(0.06)),
                                LayoutBuilder(
                                  builder: (context, constraints) => Container(
                                    height: 3,
                                    width: constraints.maxWidth * _barWidth.value,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF6366F1), Color(0xFF818CF8), Color(0xFFA5B4FC)],
                                      ),
                                      boxShadow: [BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.8), blurRadius: 8)],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'INITIALIZING',
                            style: GoogleFonts.inter(
                              fontSize: 9, color: const Color(0xFF374151),
                              letterSpacing: 3, fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 48),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Animated Glowing Ring ────────────────────────────────────────────────────
class _AnimatedRing extends StatelessWidget {
  final double progress;
  final double radius;
  final double strokeWidth;
  final Color color;
  final bool reverse;
  const _AnimatedRing({required this.progress, required this.radius, required this.strokeWidth, required this.color, this.reverse = false});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(radius * 2, radius * 2),
      painter: _RingPainter(progress: progress, color: color, strokeWidth: strokeWidth, reverse: reverse),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;
  final bool reverse;
  const _RingPainter({required this.progress, required this.color, required this.strokeWidth, this.reverse = false});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final angle = progress * math.pi * 2;
    final startAngle = reverse ? -angle : angle - math.pi / 4;
    const sweepAngle = math.pi * 1.4;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle, sweepAngle, false, paint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress || old.color != color;
}

// ─── Glow Blob ────────────────────────────────────────────────────────────────
class _GlowBlob extends StatelessWidget {
  final double width, height;
  final Color color;
  final double blur;
  const _GlowBlob({required this.width, required this.height, required this.color, required this.blur});

  @override
  Widget build(BuildContext context) => Container(
    width: width, height: height,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: color,
    ),
    child: BackdropFilter(
      filter: const ColorFilter.linearToSrgbGamma(),
      child: const SizedBox.shrink(),
    ),
  );
}

// ─── Diamond dot ──────────────────────────────────────────────────────────────
class _Diamond extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: math.pi / 4,
      child: Container(
        width: 5, height: 5,
        decoration: BoxDecoration(
          color: const Color(0xFF0284C7).withOpacity(0.6),
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    );
  }
}

// ─── Subtle Grid Painter ──────────────────────────────────────────────────────
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.018)
      ..strokeWidth = 0.8;
    const spacing = 56.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

// ─── Particle Painter ─────────────────────────────────────────────────────────
class _ParticlePainter extends CustomPainter {
  final double progress;
  static final List<_Particle> _particles = List.generate(22, (i) {
    final rng = math.Random(i * 31 + 7);
    return _Particle(
      x: rng.nextDouble(),
      y: rng.nextDouble(),
      size: 1.0 + rng.nextDouble() * 1.8,
      speed: 0.03 + rng.nextDouble() * 0.06,
      phase: rng.nextDouble(),
      opacity: 0.15 + rng.nextDouble() * 0.25,
    );
  });

  const _ParticlePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in _particles) {
      final t = (progress * p.speed + p.phase) % 1.0;
      final y = (p.y - t * 0.5) % 1.0;
      final opacity = math.sin(t * math.pi) * p.opacity;
      final paint = Paint()
        ..color = const Color(0xFF818CF8).withOpacity(opacity.clamp(0, 1))
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(p.x * size.width, y * size.height), p.size, paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.progress != progress;
}

class _Particle {
  final double x, y, size, speed, phase, opacity;
  const _Particle({required this.x, required this.y, required this.size, required this.speed, required this.phase, required this.opacity});
}
