import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class WaveformVisualizer extends StatefulWidget {
  final bool isListening;
  final bool isProcessing;
  final double audioLevel;
  final List<double> audioLevels;
  final Color primaryColor;
  final double width;
  final double height;

  const WaveformVisualizer({
    super.key,
    required this.isListening,
    this.isProcessing = false,
    this.audioLevel = 0.0,
    this.audioLevels = const [],
    this.primaryColor = AppTheme.primaryColor,
    this.width = 300,
    this.height = 80,
  });

  @override
  State<WaveformVisualizer> createState() => _WaveformVisualizerState();
}

class _WaveformVisualizerState extends State<WaveformVisualizer>
    with TickerProviderStateMixin {
  late AnimationController _waveController;
  late AnimationController _pulseController;
  late Animation<double> _waveAnimation;
  late Animation<double> _pulseAnimation;
  
  List<double> _waveformData = [];
  Timer? _dataUpdateTimer;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeWaveformData();
    _startDataUpdates();
  }

  void _setupAnimations() {
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _waveAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _waveController, curve: Curves.easeInOut),
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  void _initializeWaveformData() {
    _waveformData = List.generate(50, (index) => 0.1);
  }

  void _startDataUpdates() {
    _dataUpdateTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (mounted) {
        _updateWaveformData();
      }
    });
  }

  void _updateWaveformData() {
    if (!widget.isListening && !widget.isProcessing) {
      // Gradually reduce to baseline when not active
      for (int i = 0; i < _waveformData.length; i++) {
        _waveformData[i] = _waveformData[i] * 0.9;
        if (_waveformData[i] < 0.1) _waveformData[i] = 0.1;
      }
    } else {
      // Simulate real-time audio data
      _waveformData.removeAt(0);
      double newLevel;
      
      if (widget.isProcessing) {
        // Breathing pattern for processing
        newLevel = 0.3 + 0.2 * sin(DateTime.now().millisecondsSinceEpoch / 200);
      } else if (widget.audioLevels.isNotEmpty) {
        // Use real audio levels if available
        newLevel = widget.audioLevels.last.clamp(0.0, 1.0);
      } else {
        // Simulate audio activity
        newLevel = widget.audioLevel > 0 
            ? widget.audioLevel + (_random.nextDouble() - 0.5) * 0.3
            : 0.2 + _random.nextDouble() * 0.6;
      }
      
      _waveformData.add(newLevel.clamp(0.1, 1.0));
    }
    
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void didUpdateWidget(WaveformVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isListening != oldWidget.isListening) {
      if (widget.isListening) {
        _waveController.repeat(reverse: true);
        _pulseController.repeat(reverse: true);
      } else {
        _waveController.stop();
        _pulseController.stop();
      }
    }
  }

  @override
  void dispose() {
    _dataUpdateTimer?.cancel();
    _waveController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_waveAnimation, _pulseAnimation]),
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [
                widget.primaryColor.withValues(alpha: 0.1),
                widget.primaryColor.withValues(alpha: 0.05),
              ],
            ),
          ),
          child: CustomPaint(
            painter: WaveformPainter(
              waveformData: _waveformData,
              primaryColor: widget.primaryColor,
              isListening: widget.isListening,
              isProcessing: widget.isProcessing,
              animationValue: _waveAnimation.value,
              pulseValue: _pulseAnimation.value,
            ),
            size: Size(widget.width, widget.height),
          ),
        );
      },
    );
  }
}

class WaveformPainter extends CustomPainter {
  final List<double> waveformData;
  final Color primaryColor;
  final bool isListening;
  final bool isProcessing;
  final double animationValue;
  final double pulseValue;

  WaveformPainter({
    required this.waveformData,
    required this.primaryColor,
    required this.isListening,
    required this.isProcessing,
    required this.animationValue,
    required this.pulseValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round;

    final barWidth = size.width / waveformData.length;
    final centerY = size.height / 2;

    for (int i = 0; i < waveformData.length; i++) {
      final barHeight = waveformData[i] * size.height * 0.8;
      final x = i * barWidth;
      
      // Create gradient effect based on position and activity
      final progress = i / waveformData.length;
      final alpha = isListening 
          ? (0.3 + 0.7 * waveformData[i] * pulseValue).clamp(0.0, 1.0)
          : (0.2 + 0.3 * waveformData[i]).clamp(0.0, 1.0);
      
      Color barColor;
      if (isProcessing) {
        // Breathing effect for processing
        barColor = Color.lerp(
          primaryColor.withValues(alpha: alpha * 0.5),
          AppTheme.secondaryColor.withValues(alpha: alpha),
          sin(progress * pi + animationValue * 2 * pi) * 0.5 + 0.5,
        )!;
      } else {
        // Normal waveform colors
        barColor = Color.lerp(
          primaryColor.withValues(alpha: alpha),
          AppTheme.accentTextColor.withValues(alpha: alpha),
          progress,
        )!;
      }
      
      paint.color = barColor;
      
      // Draw the bar
      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(x + barWidth / 2, centerY),
          width: barWidth * 0.8,
          height: barHeight,
        ),
        Radius.circular(barWidth * 0.2),
      );
      
      canvas.drawRRect(rect, paint);
      
      // Add glow effect for active listening
      if (isListening && waveformData[i] > 0.5) {
        paint.color = primaryColor.withValues(alpha: 0.3 * pulseValue);
        paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
        canvas.drawRRect(rect, paint);
        paint.maskFilter = null;
      }
    }
  }

  @override
  bool shouldRepaint(WaveformPainter oldDelegate) {
    return oldDelegate.waveformData != waveformData ||
           oldDelegate.isListening != isListening ||
           oldDelegate.isProcessing != isProcessing ||
           oldDelegate.animationValue != animationValue ||
           oldDelegate.pulseValue != pulseValue;
  }
}

// Audio level detector widget
class AudioLevelIndicator extends StatefulWidget {
  final double level;
  final bool isActive;
  final Color color;

  const AudioLevelIndicator({
    super.key,
    required this.level,
    this.isActive = false,
    this.color = AppTheme.primaryColor,
  });

  @override
  State<AudioLevelIndicator> createState() => _AudioLevelIndicatorState();
}

class _AudioLevelIndicatorState extends State<AudioLevelIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void didUpdateWidget(AudioLevelIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _controller.forward();
      } else {
        _controller.reverse();
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
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: 60,
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: Colors.grey.withValues(alpha: 0.3),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: (widget.level * _animation.value).clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                gradient: LinearGradient(
                  colors: [
                    widget.color,
                    widget.color.withValues(alpha: 0.7),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
