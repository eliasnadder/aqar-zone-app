import 'package:flutter/material.dart';

class EnhancedEmptyState extends StatefulWidget {
  final String title;
  final String subtitle;
  final String subtitle2;
  final IconData icon;
  final List<String> suggestions;
  final Function(String)? onSuggestionTap;
  final String? apiKey;
  final bool isLoading;

  const EnhancedEmptyState({
    Key? key,
    this.title = 'Start a conversation',
    this.subtitle = 'Ask me anything you\'d like to know!',
    this.subtitle2 = 'Property title',
    this.icon = Icons.chat_bubble_outline_rounded,
    this.suggestions = const [],
    this.onSuggestionTap,
    this.apiKey,
    this.isLoading = false,
  }) : super(key: key);

  @override
  State<EnhancedEmptyState> createState() => _EnhancedEmptyStateState();
}

class _EnhancedEmptyStateState extends State<EnhancedEmptyState>
    with TickerProviderStateMixin {
  late AnimationController _floatController;
  late AnimationController _fadeController;
  late Animation<double> _floatAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _floatController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _floatAnimation = Tween<double>(begin: 0.0, end: 10.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    _floatController.repeat(reverse: true);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _floatController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Center(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isNarrowScreen = constraints.maxWidth < 400;
            final isVeryNarrowScreen = constraints.maxWidth < 300;

            return Padding(
              padding: EdgeInsets.all(isVeryNarrowScreen ? 16.0 : 32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _floatAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _floatAnimation.value),
                        child: Container(
                          padding: EdgeInsets.all(isVeryNarrowScreen ? 16 : 24),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                theme.colorScheme.primary.withValues(
                                  alpha: 0.1,
                                ),
                                theme.colorScheme.primary.withValues(
                                  alpha: 0.05,
                                ),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: theme.colorScheme.primary.withValues(
                                  alpha: 0.1,
                                ),
                                blurRadius: isVeryNarrowScreen ? 15 : 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Icon(
                            widget.icon,
                            size:
                                isVeryNarrowScreen
                                    ? 48
                                    : (isNarrowScreen ? 56 : 64),
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.7,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: isVeryNarrowScreen ? 16 : 24),
                  Text(
                    widget.title,
                    style: TextStyle(
                      fontSize:
                          isVeryNarrowScreen ? 20 : (isNarrowScreen ? 22 : 24),
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      // Calculate available width for text
                      final availableWidth = constraints.maxWidth;
                      final isNarrowScreen = availableWidth < 300;

                      // Check if both subtitles can fit on one line
                      final textPainter1 = TextPainter(
                        text: TextSpan(
                          text: widget.subtitle,
                          style: TextStyle(
                            fontSize: isNarrowScreen ? 14 : 16,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.7,
                            ),
                          ),
                        ),
                        textDirection: TextDirection.ltr,
                      )..layout();

                      final textPainter2 = TextPainter(
                        text: TextSpan(
                          text: widget.subtitle2,
                          style: TextStyle(
                            fontSize: isNarrowScreen ? 14 : 16,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        textDirection: TextDirection.ltr,
                      )..layout();

                      final totalTextWidth =
                          textPainter1.width +
                          textPainter2.width +
                          8; // 8px spacing
                      final shouldWrap =
                          totalTextWidth >
                          availableWidth * 0.9; // 90% of available width

                      if (shouldWrap) {
                        // Stack vertically when text is too long
                        return Column(
                          children: [
                            Text(
                              widget.subtitle,
                              style: TextStyle(
                                fontSize: isNarrowScreen ? 14 : 16,
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.7,
                                ),
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (widget.subtitle2.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                widget.subtitle2,
                                style: TextStyle(
                                  fontSize: isNarrowScreen ? 14 : 16,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        );
                      } else {
                        // Keep side by side when there's enough space
                        return Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              widget.subtitle,
                              style: TextStyle(
                                fontSize: isNarrowScreen ? 14 : 16,
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.7,
                                ),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            if (widget.subtitle2.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Text(
                                widget.subtitle2,
                                style: TextStyle(
                                  fontSize: isNarrowScreen ? 14 : 16,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ],
                        );
                      }
                    },
                  ),
                  if (widget.suggestions.isNotEmpty) ...[
                    SizedBox(height: isVeryNarrowScreen ? 24 : 32),
                    Text(
                      'Try asking:',
                      style: TextStyle(
                        fontSize: isVeryNarrowScreen ? 12 : 14,
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.8,
                        ),
                      ),
                    ),
                    SizedBox(height: isVeryNarrowScreen ? 12 : 16),
                    ...widget.suggestions.asMap().entries.map((entry) {
                      final index = entry.key;
                      final suggestion = entry.value;

                      return TweenAnimationBuilder<double>(
                        duration: Duration(milliseconds: 800 + (index * 200)),
                        tween: Tween(begin: 0.0, end: 1.0),
                        builder: (context, value, child) {
                          return Transform.translate(
                            offset: Offset(0, 20 * (1 - value)),
                            child: Opacity(
                              opacity: value,
                              child: GestureDetector(
                                onTap: () {
                                  if (widget.onSuggestionTap != null) {
                                    widget.onSuggestionTap!(suggestion);
                                  }
                                },
                                child: Container(
                                  margin: EdgeInsets.only(
                                    bottom: isVeryNarrowScreen ? 6 : 8,
                                  ),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isVeryNarrowScreen ? 12 : 16,
                                    vertical: isVeryNarrowScreen ? 8 : 12,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    color: theme
                                        .colorScheme
                                        .surfaceContainerHighest
                                        .withValues(alpha: 0.5),
                                    border: Border.all(
                                      color: theme.colorScheme.outline
                                          .withValues(alpha: 0.2),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.lightbulb_outline_rounded,
                                        size: isVeryNarrowScreen ? 14 : 16,
                                        color: theme.colorScheme.primary,
                                      ),
                                      SizedBox(
                                        width: isVeryNarrowScreen ? 6 : 8,
                                      ),
                                      Flexible(
                                        child: Text(
                                          suggestion,
                                          style: TextStyle(
                                            fontSize:
                                                isVeryNarrowScreen ? 12 : 14,
                                            color: theme.colorScheme.onSurface
                                                .withValues(alpha: 0.8),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    }),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
