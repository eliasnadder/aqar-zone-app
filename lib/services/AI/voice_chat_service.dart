import 'package:flutter/material.dart';
import '../../screens/AI/voice_chat_screen.dart';

/// Service to handle voice chat integration
/// This service provides a bridge between the chat UI and voice functionality
class VoiceChatService {
  static VoiceChatService? _instance;
  static VoiceChatService get instance => _instance ??= VoiceChatService._();

  VoiceChatService._();

  // Callback for voice mode toggle
  VoidCallback? _voiceModeToggleCallback;

  // Current voice mode state
  bool _isVoiceModeActive = false;

  /// Register the voice mode toggle callback
  /// This should be called from your voice chat screen or service
  void registerVoiceModeToggle(VoidCallback callback) {
    _voiceModeToggleCallback = callback;
  }

  /// Unregister the voice mode toggle callback
  void unregisterVoiceModeToggle() {
    _voiceModeToggleCallback = null;
  }

  /// Toggle voice mode
  /// This method will be called when the graphic_eq button is pressed
  void toggleVoiceMode() {
    if (_voiceModeToggleCallback != null) {
      _voiceModeToggleCallback!();
      _isVoiceModeActive = !_isVoiceModeActive;
    } else {
      // Fallback: Show a message that voice mode is not available
      debugPrint('Voice mode toggle requested but no callback registered');
    }
  }

  /// Get current voice mode state
  bool get isVoiceModeActive => _isVoiceModeActive;

  /// Set voice mode state (called from voice chat implementation)
  void setVoiceModeState(bool isActive) {
    _isVoiceModeActive = isActive;
  }

  /// Navigate to voice chat screen
  /// This navigates to the actual VoiceChatScreen implementation
  static void navigateToVoiceChat(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const VoiceChatScreen()),
    );
  }

  /// Start voice recording
  /// This method can be connected to your voice recording functionality
  static Future<void> startVoiceRecording() async {
    // TODO: Implement voice recording start
    debugPrint('Voice recording started');
  }

  /// Stop voice recording
  /// This method can be connected to your voice recording functionality
  static Future<String?> stopVoiceRecording() async {
    // TODO: Implement voice recording stop and return transcribed text
    debugPrint('Voice recording stopped');
    return null; // Return transcribed text
  }

  /// Process voice input
  /// This method can be used to process voice input and convert it to text
  static Future<String?> processVoiceInput() async {
    // TODO: Implement voice processing
    debugPrint('Processing voice input');
    return null; // Return processed text
  }
}

/// Voice Chat Integration Widget
/// This widget can be used to easily integrate voice chat functionality
class VoiceChatIntegration extends StatefulWidget {
  final Widget child;
  final VoidCallback? onVoiceModeToggle;

  const VoiceChatIntegration({
    Key? key,
    required this.child,
    this.onVoiceModeToggle,
  }) : super(key: key);

  @override
  State<VoiceChatIntegration> createState() => _VoiceChatIntegrationState();
}

class _VoiceChatIntegrationState extends State<VoiceChatIntegration> {
  @override
  void initState() {
    super.initState();
    // Register the voice mode toggle callback if provided
    if (widget.onVoiceModeToggle != null) {
      VoiceChatService.instance.registerVoiceModeToggle(
        widget.onVoiceModeToggle!,
      );
    }
  }

  @override
  void dispose() {
    // Unregister the callback when widget is disposed
    VoiceChatService.instance.unregisterVoiceModeToggle();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// Voice Mode Button Widget
/// A reusable button widget for voice mode toggle
class VoiceModeButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final bool isActive;
  final double size;
  final Color? activeColor;
  final Color? inactiveColor;

  const VoiceModeButton({
    Key? key,
    this.onPressed,
    this.isActive = false,
    this.size = 24.0,
    this.activeColor,
    this.inactiveColor,
  }) : super(key: key);

  @override
  State<VoiceModeButton> createState() => _VoiceModeButtonState();
}

class _VoiceModeButtonState extends State<VoiceModeButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTap() {
    _animationController.forward().then((_) {
      _animationController.reverse();
    });

    if (widget.onPressed != null) {
      widget.onPressed!();
    } else {
      VoiceChatService.instance.toggleVoiceMode();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color =
        widget.isActive
            ? (widget.activeColor ?? theme.colorScheme.primary)
            : (widget.inactiveColor ??
                // ignore: deprecated_member_use
                theme.colorScheme.onSurface.withOpacity(0.6));

    return ScaleTransition(
      scale: _scaleAnimation,
      child: IconButton(
        onPressed: _handleTap,
        icon: Icon(Icons.graphic_eq_rounded, size: widget.size, color: color),
        tooltip: widget.isActive ? 'Stop Voice Mode' : 'Start Voice Mode',
      ),
    );
  }
}
