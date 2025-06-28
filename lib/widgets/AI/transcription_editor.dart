import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';

class TranscriptionEditor extends StatefulWidget {
  final String initialText;
  final Function(String)? onTextChanged;
  final Function(String)? onTextConfirmed;
  final bool isEditable;
  final bool showConfidenceIndicator;
  final double confidence;

  const TranscriptionEditor({
    super.key,
    required this.initialText,
    this.onTextChanged,
    this.onTextConfirmed,
    this.isEditable = true,
    this.showConfidenceIndicator = true,
    this.confidence = 1.0,
  });

  @override
  State<TranscriptionEditor> createState() => _TranscriptionEditorState();
}

class _TranscriptionEditorState extends State<TranscriptionEditor>
    with TickerProviderStateMixin {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;

  bool _isEditing = false;
  bool _hasChanges = false;
  String _originalText = '';
  Timer? _autoSaveTimer;

  @override
  void initState() {
    super.initState();
    
    _controller = TextEditingController(text: widget.initialText);
    _focusNode = FocusNode();
    _originalText = widget.initialText;
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
    
    _fadeController.forward();
  }

  @override
  void didUpdateWidget(TranscriptionEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.initialText != oldWidget.initialText && !_isEditing) {
      _controller.text = widget.initialText;
      _originalText = widget.initialText;
      _hasChanges = false;
    }
    
    if (widget.confidence != oldWidget.confidence && widget.confidence < 0.7) {
      _pulseController.repeat(reverse: true);
    } else {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  void _onTextChanged() {
    final currentText = _controller.text;
    _hasChanges = currentText != _originalText;
    
    widget.onTextChanged?.call(currentText);
    
    // Auto-save after 2 seconds of no changes
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(seconds: 2), () {
      if (_hasChanges) {
        _confirmChanges();
      }
    });
    
    setState(() {});
  }

  void _onFocusChanged() {
    setState(() {
      _isEditing = _focusNode.hasFocus;
    });
    
    if (!_isEditing && _hasChanges) {
      _confirmChanges();
    }
  }

  void _confirmChanges() {
    _originalText = _controller.text;
    _hasChanges = false;
    widget.onTextConfirmed?.call(_controller.text);
    
    // Provide haptic feedback
    HapticFeedback.lightImpact();
    
    setState(() {});
  }

  void _revertChanges() {
    _controller.text = _originalText;
    _hasChanges = false;
    _focusNode.unfocus();
    
    setState(() {});
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isEditing 
                    ? AppTheme.primaryColor 
                    : AppTheme.primaryColor.withValues(alpha: 0.3),
                width: _isEditing ? 2 : 1,
              ),
              boxShadow: _isEditing ? [
                BoxShadow(
                  color: AppTheme.primaryColor.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ] : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                _buildTextEditor(),
                if (_hasChanges) _buildActionButtons(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.edit,
            size: 16,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(width: 8),
          const Text(
            'تحرير النص المنطوق',
            style: TextStyle(
              color: AppTheme.primaryColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          if (widget.showConfidenceIndicator)
            _buildConfidenceIndicator(),
        ],
      ),
    );
  }

  Widget _buildConfidenceIndicator() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.confidence < 0.7 ? _pulseAnimation.value : 1.0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getConfidenceColor().withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _getConfidenceColor(),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getConfidenceIcon(),
                  size: 12,
                  color: _getConfidenceColor(),
                ),
                const SizedBox(width: 4),
                Text(
                  '${(widget.confidence * 100).round()}%',
                  style: TextStyle(
                    color: _getConfidenceColor(),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getConfidenceColor() {
    if (widget.confidence >= 0.8) {
      return AppTheme.successColor;
    } else if (widget.confidence >= 0.6) {
      return AppTheme.warningColor;
    } else {
      return AppTheme.errorColor;
    }
  }

  IconData _getConfidenceIcon() {
    if (widget.confidence >= 0.8) {
      return Icons.check_circle;
    } else if (widget.confidence >= 0.6) {
      return Icons.warning;
    } else {
      return Icons.error;
    }
  }

  Widget _buildTextEditor() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        enabled: widget.isEditable,
        maxLines: null,
        style: const TextStyle(
          color: AppTheme.primaryTextColor,
          fontSize: 16,
          height: 1.4,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: widget.isEditable 
              ? 'اضغط للتحرير...'
              : 'النص المنطوق',
          hintStyle: TextStyle(
            color: AppTheme.secondaryTextColor.withValues(alpha: 0.6),
            fontSize: 16,
          ),
        ),
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.right,
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.05),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton.icon(
            onPressed: _revertChanges,
            icon: const Icon(
              Icons.undo,
              size: 16,
              color: AppTheme.errorColor,
            ),
            label: const Text(
              'تراجع',
              style: TextStyle(
                color: AppTheme.errorColor,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: _confirmChanges,
            icon: const Icon(
              Icons.check,
              size: 16,
              color: Colors.white,
            ),
            label: const Text(
              'تأكيد',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.successColor,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }
}

// Word-by-word editor for precise corrections
class WordByWordEditor extends StatefulWidget {
  final String text;
  final List<double> wordConfidences;
  final Function(String)? onTextChanged;

  const WordByWordEditor({
    super.key,
    required this.text,
    this.wordConfidences = const [],
    this.onTextChanged,
  });

  @override
  State<WordByWordEditor> createState() => _WordByWordEditorState();
}

class _WordByWordEditorState extends State<WordByWordEditor> {
  List<String> _words = [];
  List<TextEditingController> _controllers = [];
  List<bool> _isEditing = [];

  @override
  void initState() {
    super.initState();
    _initializeWords();
  }

  @override
  void didUpdateWidget(WordByWordEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.text != oldWidget.text) {
      _initializeWords();
    }
  }

  void _initializeWords() {
    _words = widget.text.split(' ').where((word) => word.isNotEmpty).toList();
    
    // Dispose old controllers
    for (final controller in _controllers) {
      controller.dispose();
    }
    
    _controllers = _words.map((word) => TextEditingController(text: word)).toList();
    _isEditing = List.filled(_words.length, false);
    
    // Add listeners
    for (int i = 0; i < _controllers.length; i++) {
      _controllers[i].addListener(() => _onWordChanged(i));
    }
  }

  void _onWordChanged(int index) {
    _words[index] = _controllers[index].text;
    final newText = _words.join(' ');
    widget.onTextChanged?.call(newText);
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: List.generate(_words.length, (index) {
          return _buildWordChip(index);
        }),
      ),
    );
  }

  Widget _buildWordChip(int index) {
    final confidence = index < widget.wordConfidences.length 
        ? widget.wordConfidences[index] 
        : 1.0;
    
    return GestureDetector(
      onTap: () => _startEditingWord(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _getWordColor(confidence),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isEditing[index] 
                ? AppTheme.primaryColor 
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: _isEditing[index] 
            ? _buildWordEditor(index)
            : Text(
                _words[index],
                style: TextStyle(
                  color: confidence < 0.6 ? Colors.white : AppTheme.primaryTextColor,
                  fontSize: 14,
                ),
              ),
      ),
    );
  }

  Widget _buildWordEditor(int index) {
    return SizedBox(
      width: 60,
      child: TextField(
        controller: _controllers[index],
        style: const TextStyle(
          color: AppTheme.primaryTextColor,
          fontSize: 14,
        ),
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        onSubmitted: (_) => _stopEditingWord(index),
        autofocus: true,
      ),
    );
  }

  Color _getWordColor(double confidence) {
    if (confidence >= 0.8) {
      return AppTheme.successColor.withValues(alpha: 0.2);
    } else if (confidence >= 0.6) {
      return AppTheme.warningColor.withValues(alpha: 0.2);
    } else {
      return AppTheme.errorColor.withValues(alpha: 0.8);
    }
  }

  void _startEditingWord(int index) {
    setState(() {
      _isEditing[index] = true;
    });
  }

  void _stopEditingWord(int index) {
    setState(() {
      _isEditing[index] = false;
    });
  }
}
