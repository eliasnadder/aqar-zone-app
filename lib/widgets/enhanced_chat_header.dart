import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class EnhancedChatHeader extends StatefulWidget {
  final TextEditingController apiKeyController;
  final bool isLoadingProperties;
  final String title;
  final String subtitle;

  const EnhancedChatHeader({
    Key? key,
    required this.apiKeyController,
    this.isLoadingProperties = false,
    this.title = 'AI Assistant',
    this.subtitle = 'Ask me anything!',
  }) : super(key: key);

  @override
  State<EnhancedChatHeader> createState() => _EnhancedChatHeaderState();
}

class _EnhancedChatHeaderState extends State<EnhancedChatHeader>
    with TickerProviderStateMixin {
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;
  bool _isApiKeyVisible = false;

  @override
  void initState() {
    super.initState();

    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    if (widget.isLoadingProperties) {
      _shimmerController.repeat();
    }
  }

  @override
  void didUpdateWidget(EnhancedChatHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoadingProperties != oldWidget.isLoadingProperties) {
      if (widget.isLoadingProperties) {
        _shimmerController.repeat();
      } else {
        _shimmerController.stop();
      }
    }
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer,
            theme.colorScheme.primaryContainer.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.primary.withValues(alpha: 0.8),
                      ],
                    ),
                  ),
                  child: SvgPicture.asset(
                    'assets/icons/siri-stroke-rounded.svg',
                    width: 24,
                    height: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                      Text(
                        widget.subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.colorScheme.onPrimaryContainer
                              .withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                  style: IconButton.styleFrom(
                    foregroundColor: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: theme.colorScheme.surface.withValues(alpha: 0.9),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: widget.apiKeyController,
                decoration: InputDecoration(
                  labelText: 'Gemini API Key',
                  hintText: 'Enter your API key',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.transparent,
                  prefixIcon: Icon(
                    Icons.key_rounded,
                    color: theme.colorScheme.primary,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isApiKeyVisible
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    onPressed: () {
                      setState(() {
                        _isApiKeyVisible = !_isApiKeyVisible;
                      });
                    },
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
                obscureText: !_isApiKeyVisible,
                style: TextStyle(color: theme.colorScheme.onSurface),
              ),
            ),
            if (widget.isLoadingProperties) ...[
              const SizedBox(height: 6),
              AnimatedBuilder(
                animation: _shimmerAnimation,
                builder: (context, child) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: theme.colorScheme.surface.withValues(alpha: 0.7),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              theme.colorScheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Loading properties data...',
                          style: TextStyle(
                            color: theme.colorScheme.onSurface,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
