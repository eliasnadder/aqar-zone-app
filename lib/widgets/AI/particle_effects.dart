import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class ParticleEffects extends StatefulWidget {
  final bool isActive;
  final Color primaryColor;
  final double size;
  final int particleCount;

  const ParticleEffects({
    super.key,
    required this.isActive,
    this.primaryColor = AppTheme.primaryColor,
    this.size = 120,
    this.particleCount = 20,
  });

  @override
  State<ParticleEffects> createState() => _ParticleEffectsState();
}

class _ParticleEffectsState extends State<ParticleEffects>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late List<Particle> _particles;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _initializeParticles();

    _controller.addListener(() {
      if (mounted) {
        setState(() {
          _updateParticles();
        });
      }
    });
  }

  void _initializeParticles() {
    _particles = List.generate(widget.particleCount, (index) {
      return Particle(
        x: widget.size / 2,
        y: widget.size / 2,
        vx: (_random.nextDouble() - 0.5) * 2,
        vy: (_random.nextDouble() - 0.5) * 2,
        life: 1.0,
        maxLife: 1.0 + _random.nextDouble(),
        size: 2 + _random.nextDouble() * 4,
        color: widget.primaryColor,
      );
    });
  }

  void _updateParticles() {
    for (var particle in _particles) {
      particle.update();

      // Reset particle if it's dead
      if (particle.life <= 0) {
        particle.reset(
          widget.size / 2,
          widget.size / 2,
          (_random.nextDouble() - 0.5) * 3,
          (_random.nextDouble() - 0.5) * 3,
        );
      }
    }
  }

  @override
  void didUpdateWidget(ParticleEffects oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: CustomPaint(
        painter: ParticlePainter(
          particles: _particles,
          isActive: widget.isActive,
          animationValue: _controller.value,
        ),
      ),
    );
  }
}

class Particle {
  double x, y;
  double vx, vy;
  double life;
  double maxLife;
  double size;
  Color color;

  Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.life,
    required this.maxLife,
    required this.size,
    required this.color,
  });

  void update() {
    x += vx;
    y += vy;
    life -= 0.02;

    // Add some gravity and friction
    vy += 0.05;
    vx *= 0.99;
    vy *= 0.99;
  }

  void reset(double newX, double newY, double newVx, double newVy) {
    x = newX;
    y = newY;
    vx = newVx;
    vy = newVy;
    life = maxLife;
  }

  double get alpha => (life / maxLife).clamp(0.0, 1.0);
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final bool isActive;
  final double animationValue;

  ParticlePainter({
    required this.particles,
    required this.isActive,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!isActive) return;

    final paint = Paint()..style = PaintingStyle.fill;

    for (var particle in particles) {
      if (particle.life > 0) {
        paint.color = particle.color.withValues(alpha: particle.alpha * 0.8);

        // Add glow effect
        paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

        canvas.drawCircle(
          Offset(particle.x, particle.y),
          particle.size * particle.alpha,
          paint,
        );

        paint.maskFilter = null;
      }
    }
  }

  @override
  bool shouldRepaint(ParticlePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.isActive != isActive;
  }
}

// Breathing animation widget for AI thinking state
class BreathingAnimation extends StatefulWidget {
  final Widget child;
  final bool isActive;
  final Duration duration;

  const BreathingAnimation({
    super.key,
    required this.child,
    required this.isActive,
    this.duration = const Duration(seconds: 2),
  });

  @override
  State<BreathingAnimation> createState() => _BreathingAnimationState();
}

class _BreathingAnimationState extends State<BreathingAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);

    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _opacityAnimation = Tween<double>(
      begin: 0.7,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(BreathingAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
        _controller.reset();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(opacity: _opacityAnimation.value, child: widget.child),
        );
      },
    );
  }
}

// Color-changing gradient background
class DynamicGradientBackground extends StatefulWidget {
  final bool isListening;
  final bool isProcessing;
  final bool isAiSpeaking;
  final Widget child;

  const DynamicGradientBackground({
    super.key,
    required this.isListening,
    required this.isProcessing,
    required this.isAiSpeaking,
    required this.child,
  });

  @override
  State<DynamicGradientBackground> createState() =>
      _DynamicGradientBackgroundState();
}

class _DynamicGradientBackgroundState extends State<DynamicGradientBackground>
    with TickerProviderStateMixin {
  late AnimationController _colorController;
  late Animation<Color?> _topColorAnimation;
  late Animation<Color?> _bottomColorAnimation;

  @override
  void initState() {
    super.initState();
    _colorController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    // Initialize animations with default colors
    _topColorAnimation = ColorTween(
      begin: Colors.black,
      end: Colors.black,
    ).animate(
      CurvedAnimation(parent: _colorController, curve: Curves.easeInOut),
    );

    _bottomColorAnimation = ColorTween(
      begin: Colors.black,
      end: Colors.black,
    ).animate(
      CurvedAnimation(parent: _colorController, curve: Curves.easeInOut),
    );

    _updateColorAnimations();
  }

  void _updateColorAnimations() {
    Color topColor, bottomColor;

    if (widget.isListening) {
      topColor = AppTheme.primaryColor.withValues(alpha: 0.3);
      bottomColor = Colors.black;
    } else if (widget.isProcessing) {
      topColor = AppTheme.secondaryColor.withValues(alpha: 0.3);
      bottomColor = Colors.black;
    } else if (widget.isAiSpeaking) {
      topColor = AppTheme.accentTextColor.withValues(alpha: 0.3);
      bottomColor = Colors.black;
    } else {
      topColor = Colors.black;
      bottomColor = Colors.black;
    }

    _topColorAnimation = ColorTween(
      begin: _topColorAnimation.value,
      end: topColor,
    ).animate(
      CurvedAnimation(parent: _colorController, curve: Curves.easeInOut),
    );

    _bottomColorAnimation = ColorTween(
      begin: _bottomColorAnimation.value,
      end: bottomColor,
    ).animate(
      CurvedAnimation(parent: _colorController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(DynamicGradientBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isListening != oldWidget.isListening ||
        widget.isProcessing != oldWidget.isProcessing ||
        widget.isAiSpeaking != oldWidget.isAiSpeaking) {
      _updateColorAnimations();
      _colorController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _colorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _colorController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                _topColorAnimation.value ?? Colors.black,
                _bottomColorAnimation.value ?? Colors.black,
              ],
            ),
          ),
          child: widget.child,
        );
      },
    );
  }
}
