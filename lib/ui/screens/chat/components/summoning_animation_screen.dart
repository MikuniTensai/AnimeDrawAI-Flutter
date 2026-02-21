import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class SummoningAnimationScreen extends StatefulWidget {
  final String characterId;
  final String characterImageUrl;
  final int sinCount;
  final String rarity;
  final VoidCallback onAnimationComplete;

  const SummoningAnimationScreen({
    super.key,
    required this.characterId,
    required this.characterImageUrl,
    required this.sinCount,
    required this.rarity,
    required this.onAnimationComplete,
  });

  @override
  State<SummoningAnimationScreen> createState() =>
      _SummoningAnimationScreenState();
}

class _SummoningAnimationScreenState extends State<SummoningAnimationScreen>
    with TickerProviderStateMixin {
  int _animationPhase = 0;
  late RarityColors _colors;

  late AnimationController _rotationController;
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _badgeController;

  @override
  void initState() {
    super.initState();
    _colors = _getRarityColors(widget.sinCount);

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _badgeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _startAnimation();
  }

  void _startAnimation() async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    setState(() => _animationPhase = 1);
    _fadeController.forward();

    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() => _animationPhase = 2);

    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() => _animationPhase = 3);

    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() => _animationPhase = 4);
    _scaleController.forward();

    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    setState(() => _animationPhase = 5);
    _badgeController.forward();

    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    widget.onAnimationComplete();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    _badgeController.dispose();
    super.dispose();
  }

  RarityColors _getRarityColors(int sinCount) {
    if (sinCount == 1) {
      return RarityColors(
        primary: const Color(0xFFCD7F32),
        secondary: const Color(0xFF8B4513),
        particle: const Color(0xFFDEB887),
      );
    } else if (sinCount == 2) {
      return RarityColors(
        primary: const Color(0xFF9370DB),
        secondary: const Color(0xFF8A2BE2),
        particle: const Color(0xFFDDA0DD),
      );
    } else if (sinCount == 3) {
      return RarityColors(
        primary: const Color(0xFFC0C0C0),
        secondary: const Color(0xFFE8E8E8),
        particle: const Color(0xFFFFFFFF),
      );
    } else {
      return RarityColors(
        primary: const Color(0xFFFFD700),
        secondary: const Color(0xFFFFA500),
        particle: const Color(0xFFFFE4B5),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Particles
          if (_animationPhase >= 2)
            AnimatedBuilder(
              animation: _rotationController,
              builder: (context, child) {
                return CustomPaint(
                  painter: ParticlePainter(
                    colors: _colors,
                    rotation: _rotationController.value * 2 * math.pi,
                    isActive: _animationPhase >= 2 && _animationPhase < 6,
                  ),
                  size: Size.infinite,
                );
              },
            ),

          // Color Reveal
          if (_animationPhase >= 3)
            FadeTransition(
              opacity: _fadeController,
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      _colors.primary.withValues(alpha: 0.3),
                      _colors.secondary.withValues(alpha: 0.2),
                      Colors.transparent,
                    ],
                    radius: 0.8,
                  ),
                ),
              ),
            ),

          // Image Reveal
          if (_animationPhase >= 4)
            ScaleTransition(
              scale: CurvedAnimation(
                parent: _scaleController,
                curve: Curves.fastOutSlowIn,
              ),
              child: FadeTransition(
                opacity: _fadeController,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 280,
                      height: 280,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: _colors.primary.withValues(alpha: 0.4),
                            blurRadius: 40,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: widget.characterImageUrl.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: widget.characterImageUrl,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: Colors.grey[900],
                                  child: const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                                errorWidget: (context, url, error) =>
                                    const Icon(Icons.error),
                              )
                            : Container(
                                color: Colors.grey[900],
                                child: const Icon(Icons.broken_image),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Rarity Badge
          if (_animationPhase >= 5)
            Positioned(
              bottom: 100,
              child: FadeTransition(
                opacity: _badgeController,
                child: Column(
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(
                        math.min(widget.sinCount, 7),
                        (index) => Text(
                          "★",
                          style: TextStyle(
                            color: _colors.primary,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(color: Colors.black45, blurRadius: 4),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.rarity.toUpperCase(),
                      style: TextStyle(
                        color: _colors.primary,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    Text(
                      "${widget.sinCount} Deadly Sins",
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class RarityColors {
  final Color primary;
  final Color secondary;
  final Color particle;

  RarityColors({
    required this.primary,
    required this.secondary,
    required this.particle,
  });
}

class ParticlePainter extends CustomPainter {
  final RarityColors colors;
  final double rotation;
  final bool isActive;
  final List<Particle> particles;

  ParticlePainter({
    required this.colors,
    required this.rotation,
    required this.isActive,
  }) : particles = List.generate(30, (index) {
         final random = math.Random(index);
         return Particle(
           angle: random.nextDouble() * 2 * math.pi,
           distance: random.nextDouble() * 150 + 50,
           size: random.nextDouble() * 4 + 2,
           speed: random.nextDouble() * 0.5 + 0.5,
         );
       });

  @override
  void paint(Canvas canvas, Size size) {
    if (!isActive) return;

    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()..style = PaintingStyle.fill;

    for (final particle in particles) {
      final animatedAngle = particle.angle + (rotation * particle.speed);
      final x = center.dx + math.cos(animatedAngle) * particle.distance;
      final y = center.dy + math.sin(animatedAngle) * particle.distance;

      paint.color = colors.particle.withValues(alpha: 0.8);
      canvas.drawCircle(Offset(x, y), particle.size, paint);

      if (particle.size > 4) {
        _drawStar(
          canvas,
          Offset(x, y),
          particle.size * 1.5,
          colors.primary.withValues(alpha: 0.6),
        );
      }
    }
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Color color) {
    final path = Path();
    const points = 5;
    final outerRadius = radius;
    final innerRadius = radius * 0.4;

    for (int i = 0; i < points * 2; i++) {
      final angle = (i * 36 - 90) * math.pi / 180;
      final r = i.isEven ? outerRadius : innerRadius;
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant ParticlePainter oldDelegate) => true;
}

class Particle {
  final double angle;
  final double distance;
  final double size;
  final double speed;

  Particle({
    required this.angle,
    required this.distance,
    required this.size,
    required this.speed,
  });
}
