import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/chat_message_model.dart';
import '../../core/theme/app_theme.dart';

class VoiceAnimationWidget extends StatefulWidget {
  final VoiceStatus voiceStatus;
  final double size;
  final VoidCallback? onTap;

  const VoiceAnimationWidget({
    super.key,
    required this.voiceStatus,
    this.size = 80.0,
    this.onTap,
  });

  @override
  State<VoiceAnimationWidget> createState() => _VoiceAnimationWidgetState();
}

class _VoiceAnimationWidgetState extends State<VoiceAnimationWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late AnimationController _rotationController;

  late Animation<double> _pulseAnimation;
  late Animation<double> _waveAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _waveController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _rotationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _waveAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _waveController, curve: Curves.easeInOut),
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.linear),
    );

    _updateAnimations();
  }

  @override
  void didUpdateWidget(VoiceAnimationWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.voiceStatus.state != widget.voiceStatus.state) {
      _updateAnimations();
    }
  }

  void _updateAnimations() {
    switch (widget.voiceStatus.state) {
      case VoiceState.listening:
        _pulseController.repeat(reverse: true);
        _waveController.repeat(reverse: true);
        _rotationController.stop();
        break;
      case VoiceState.processing:
        _pulseController.stop();
        _waveController.stop();
        _rotationController.repeat();
        break;
      case VoiceState.speaking:
        _pulseController.repeat(reverse: true);
        _waveController.repeat(reverse: true);
        _rotationController.stop();
        break;
      case VoiceState.error:
        _pulseController.stop();
        _waveController.stop();
        _rotationController.stop();
        break;
      case VoiceState.idle:
      default:
        _pulseController.stop();
        _waveController.stop();
        _rotationController.stop();
        break;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: widget.voiceStatus.statusColor.withValues(alpha: 0.3),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            _buildRippleEffect(),
            _buildMainButton(),
            if (widget.voiceStatus.state == VoiceState.processing)
              _buildProcessingIndicator(),
            if (widget.voiceStatus.isListening || widget.voiceStatus.isSpeaking)
              _buildVoiceWaves(),
          ],
        ),
      ),
    );
  }

  Widget _buildRippleEffect() {
    if (!widget.voiceStatus.isActive) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Container(
          width: widget.size * _pulseAnimation.value,
          height: widget.size * _pulseAnimation.value,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: widget.voiceStatus.statusColor.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
        );
      },
    );
  }

  Widget _buildMainButton() {
    return AnimatedContainer(
      duration: AppConstants.fastAnimation,
      width: widget.size * 0.7,
      height: widget.size * 0.7,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: widget.voiceStatus.statusColor,
        gradient: RadialGradient(
          colors: [
            widget.voiceStatus.statusColor,
            widget.voiceStatus.statusColor.withValues(alpha: 0.8),
          ],
        ),
      ),
      child: Icon(
        widget.voiceStatus.statusIcon,
        color: Colors.white,
        size: widget.size * 0.3,
      ),
    );
  }

  Widget _buildProcessingIndicator() {
    return AnimatedBuilder(
      animation: _rotationAnimation,
      builder: (context, child) {
        return Transform.rotate(
          angle: _rotationAnimation.value,
          child: Container(
            width: widget.size * 0.9,
            height: widget.size * 0.9,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: widget.voiceStatus.statusColor,
                width: 3,
              ),
            ),
            child: CustomPaint(
              painter: ProcessingPainter(
                color: widget.voiceStatus.statusColor,
                progress: _rotationAnimation.value,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildVoiceWaves() {
    return AnimatedBuilder(
      animation: _waveAnimation,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: VoiceWavesPainter(
            animation: _waveAnimation.value,
            color: widget.voiceStatus.statusColor,
            isListening: widget.voiceStatus.isListening,
          ),
        );
      },
    );
  }
}

class VoiceWavesPainter extends CustomPainter {
  final double animation;
  final Color color;
  final bool isListening;

  VoiceWavesPainter({
    required this.animation,
    required this.color,
    required this.isListening,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color.withValues(alpha: 0.6)
          ..strokeWidth = AppConstants.voiceWaveWidth
          ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.4;

    for (int i = 0; i < AppConstants.voiceWaveCount; i++) {
      final angle =
          (i * 2 * math.pi / AppConstants.voiceWaveCount) +
          (animation * 2 * math.pi);

      final waveHeight =
          isListening
              ? AppConstants.voiceWaveMinHeight +
                  (AppConstants.voiceWaveMaxHeight -
                          AppConstants.voiceWaveMinHeight) *
                      (0.5 + 0.5 * math.sin(animation * 4 * math.pi + i))
              : AppConstants.voiceWaveMinHeight +
                  (AppConstants.voiceWaveMaxHeight -
                          AppConstants.voiceWaveMinHeight) *
                      (0.3 + 0.7 * math.sin(animation * 3 * math.pi + i * 0.5));

      final startPoint = Offset(
        center.dx + math.cos(angle) * radius,
        center.dy + math.sin(angle) * radius,
      );

      final endPoint = Offset(
        center.dx + math.cos(angle) * (radius + waveHeight),
        center.dy + math.sin(angle) * (radius + waveHeight),
      );

      canvas.drawLine(startPoint, endPoint, paint);
    }
  }

  @override
  bool shouldRepaint(VoiceWavesPainter oldDelegate) {
    return oldDelegate.animation != animation ||
        oldDelegate.color != color ||
        oldDelegate.isListening != isListening;
  }
}

class ProcessingPainter extends CustomPainter {
  final Color color;
  final double progress;

  ProcessingPainter({required this.color, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;

    // Draw arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * 0.7,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(ProcessingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class VoiceStatusIndicator extends StatelessWidget {
  final VoiceStatus voiceStatus;
  final EdgeInsets padding;

  const VoiceStatusIndicator({
    super.key,
    required this.voiceStatus,
    this.padding = const EdgeInsets.all(AppConstants.mediumSpacing),
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppConstants.fastAnimation,
      padding: padding,
      decoration: BoxDecoration(
        color: voiceStatus.statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppConstants.mediumRadius),
        border: Border.all(
          color: voiceStatus.statusColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            voiceStatus.statusIcon,
            color: voiceStatus.statusColor,
            size: 16,
          ),
          const SizedBox(width: AppConstants.smallSpacing),
          Flexible(
            child: Text(
              voiceStatus.message,
              style: TextStyle(
                color: voiceStatus.statusColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}
