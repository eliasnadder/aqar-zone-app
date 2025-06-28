import 'package:flutter/material.dart';
import '../../services/AI/gesture_control_service.dart';

class GestureDetectorWrapper extends StatefulWidget {
  final Widget child;
  final GestureControlService? gestureService;
  final bool enableSwipeGestures;
  final bool enableTapGestures;
  final bool enablePinchGestures;

  const GestureDetectorWrapper({
    super.key,
    required this.child,
    this.gestureService,
    this.enableSwipeGestures = true,
    this.enableTapGestures = true,
    this.enablePinchGestures = true,
  });

  @override
  State<GestureDetectorWrapper> createState() => _GestureDetectorWrapperState();
}

class _GestureDetectorWrapperState extends State<GestureDetectorWrapper> {
  Offset? _panStartPosition;
  DateTime? _lastTapTime;
  int _tapCount = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.gestureService?.isGestureEnabled != true) {
      return widget.child;
    }

    return GestureDetector(
      // Tap gestures
      onTap: widget.enableTapGestures ? _handleTap : null,
      onLongPress: widget.enableTapGestures ? _handleLongPress : null,
      
      // Pan gestures for swipe detection
      onPanStart: widget.enableSwipeGestures ? _handlePanStart : null,
      onPanEnd: widget.enableSwipeGestures ? _handlePanEnd : null,
      
      // Scale gestures for pinch
      onScaleStart: widget.enablePinchGestures ? _handleScaleStart : null,
      onScaleUpdate: widget.enablePinchGestures ? _handleScaleUpdate : null,
      onScaleEnd: widget.enablePinchGestures ? _handleScaleEnd : null,
      
      child: widget.child,
    );
  }

  void _handleTap() {
    final now = DateTime.now();
    
    if (_lastTapTime != null && 
        now.difference(_lastTapTime!).inMilliseconds < 500) {
      _tapCount++;
    } else {
      _tapCount = 1;
    }
    
    _lastTapTime = now;
    
    // Handle double tap
    if (_tapCount == 2) {
      widget.gestureService?.handleDoubleTap();
      _tapCount = 0;
    }
  }

  void _handleLongPress() {
    widget.gestureService?.handleLongPress();
  }

  void _handlePanStart(DragStartDetails details) {
    _panStartPosition = details.globalPosition;
  }

  void _handlePanEnd(DragEndDetails details) {
    if (_panStartPosition == null) return;
    
    final velocity = details.velocity.pixelsPerSecond;
    final distance = velocity.distance;
    
    // Only process if velocity is above threshold
    if (distance < 1000) return;
    
    // Determine swipe direction based on velocity
    SwipeDirection? direction;
    
    if (velocity.dx.abs() > velocity.dy.abs()) {
      // Horizontal swipe
      direction = velocity.dx > 0 ? SwipeDirection.right : SwipeDirection.left;
    } else {
      // Vertical swipe
      direction = velocity.dy > 0 ? SwipeDirection.down : SwipeDirection.up;
    }
    
    widget.gestureService?.handleSwipe(direction, distance);
    _panStartPosition = null;
  }

  void _handleScaleStart(ScaleStartDetails details) {
    // Initialize scale gesture
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    // Handle pinch/zoom gesture
    if (details.scale != 1.0) {
      widget.gestureService?.handlePinch(details.scale);
    }
  }

  void _handleScaleEnd(ScaleEndDetails details) {
    // Finalize scale gesture
  }
}

// Enhanced gesture overlay with visual feedback
class GestureOverlay extends StatefulWidget {
  final Widget child;
  final GestureControlService? gestureService;
  final bool showGestureHints;

  const GestureOverlay({
    super.key,
    required this.child,
    this.gestureService,
    this.showGestureHints = false,
  });

  @override
  State<GestureOverlay> createState() => _GestureOverlayState();
}

class _GestureOverlayState extends State<GestureOverlay>
    with TickerProviderStateMixin {
  late AnimationController _hintController;
  late Animation<double> _hintAnimation;
  
  String _currentGestureHint = '';
  bool _showHint = false;

  @override
  void initState() {
    super.initState();
    
    _hintController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _hintAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _hintController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _hintController.dispose();
    super.dispose();
  }

  void _showGestureHint(String hint) {
    setState(() {
      _currentGestureHint = hint;
      _showHint = true;
    });
    
    _hintController.forward();
    
    // Auto-hide after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _hintController.reverse().then((_) {
          if (mounted) {
            setState(() {
              _showHint = false;
            });
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GestureDetectorWrapper(
          gestureService: widget.gestureService,
          child: widget.child,
        ),
        
        if (widget.showGestureHints && _showHint)
          _buildGestureHint(),
      ],
    );
  }

  Widget _buildGestureHint() {
    return AnimatedBuilder(
      animation: _hintAnimation,
      builder: (context, child) {
        return Positioned(
          top: 100,
          left: 16,
          right: 16,
          child: Opacity(
            opacity: _hintAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _currentGestureHint,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      },
    );
  }
}

// Shake detection widget
class ShakeDetector extends StatefulWidget {
  final Widget child;
  final GestureControlService? gestureService;
  final VoidCallback? onShakeDetected;

  const ShakeDetector({
    super.key,
    required this.child,
    this.gestureService,
    this.onShakeDetected,
  });

  @override
  State<ShakeDetector> createState() => _ShakeDetectorState();
}

class _ShakeDetectorState extends State<ShakeDetector> {
  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
  
  // In a real implementation, you would:
  // 1. Use the sensors_plus package to listen to accelerometer data
  // 2. Implement shake detection algorithm
  // 3. Call the gesture service when shake is detected
  
  // For demo purposes, we'll add a button to simulate shake
  Widget _buildShakeSimulator() {
    return Positioned(
      bottom: 100,
      right: 16,
      child: FloatingActionButton(
        mini: true,
        onPressed: () {
          widget.gestureService?.simulateShake();
          widget.onShakeDetected?.call();
        },
        child: const Icon(Icons.vibration),
      ),
    );
  }
}

// Gesture tutorial overlay
class GestureTutorial extends StatefulWidget {
  final VoidCallback? onComplete;

  const GestureTutorial({
    super.key,
    this.onComplete,
  });

  @override
  State<GestureTutorial> createState() => _GestureTutorialState();
}

class _GestureTutorialState extends State<GestureTutorial>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late PageController _pageController;
  
  int _currentPage = 0;
  final List<GestureTutorialStep> _steps = [
    GestureTutorialStep(
      title: 'اسحب لأعلى',
      description: 'اسحب لأعلى لزيادة مستوى الصوت',
      icon: Icons.volume_up,
      gesture: 'swipe_up',
    ),
    GestureTutorialStep(
      title: 'اسحب لأسفل',
      description: 'اسحب لأسفل لتقليل مستوى الصوت',
      icon: Icons.volume_down,
      gesture: 'swipe_down',
    ),
    GestureTutorialStep(
      title: 'اسحب يميناً',
      description: 'اسحب يميناً لزيادة سرعة الكلام',
      icon: Icons.fast_forward,
      gesture: 'swipe_right',
    ),
    GestureTutorialStep(
      title: 'اسحب يساراً',
      description: 'اسحب يساراً لتقليل سرعة الكلام',
      icon: Icons.fast_rewind,
      gesture: 'swipe_left',
    ),
    GestureTutorialStep(
      title: 'نقرة مزدوجة',
      description: 'انقر مرتين لتكرار آخر رد',
      icon: Icons.repeat,
      gesture: 'double_tap',
    ),
    GestureTutorialStep(
      title: 'هز الجهاز',
      description: 'هز الجهاز لمسح المحادثة والبدء من جديد',
      icon: Icons.refresh,
      gesture: 'shake',
    ),
  ];

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _pageController = PageController();
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.8),
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildPageView()),
            _buildControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'تعلم الإيماءات',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            onPressed: widget.onComplete,
            icon: const Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildPageView() {
    return PageView.builder(
      controller: _pageController,
      onPageChanged: (index) {
        setState(() {
          _currentPage = index;
        });
      },
      itemCount: _steps.length,
      itemBuilder: (context, index) {
        return _buildTutorialStep(_steps[index]);
      },
    );
  }

  Widget _buildTutorialStep(GestureTutorialStep step) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            step.icon,
            size: 80,
            color: Colors.white,
          ),
          const SizedBox(height: 32),
          Text(
            step.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            step.description,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: _currentPage > 0 ? _previousPage : null,
            child: const Text(
              'السابق',
              style: TextStyle(color: Colors.white),
            ),
          ),
          Row(
            children: List.generate(_steps.length, (index) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: index == _currentPage 
                      ? Colors.white 
                      : Colors.white.withValues(alpha: 0.3),
                ),
              );
            }),
          ),
          TextButton(
            onPressed: _currentPage < _steps.length - 1 ? _nextPage : widget.onComplete,
            child: Text(
              _currentPage < _steps.length - 1 ? 'التالي' : 'انتهاء',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _previousPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }
}

class GestureTutorialStep {
  final String title;
  final String description;
  final IconData icon;
  final String gesture;

  GestureTutorialStep({
    required this.title,
    required this.description,
    required this.icon,
    required this.gesture,
  });
}
