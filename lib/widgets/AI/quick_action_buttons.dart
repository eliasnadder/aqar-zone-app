import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class QuickActionButtons extends StatefulWidget {
  final Function(String)? onActionSelected;
  final bool isVisible;
  final List<QuickAction>? customActions;

  const QuickActionButtons({
    super.key,
    this.onActionSelected,
    this.isVisible = true,
    this.customActions,
  });

  @override
  State<QuickActionButtons> createState() => _QuickActionButtonsState();
}

class _QuickActionButtonsState extends State<QuickActionButtons>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  List<QuickAction> _actions = [];

  @override
  void initState() {
    super.initState();
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _setupActions();
    
    if (widget.isVisible) {
      _showButtons();
    }
  }

  void _setupActions() {
    _actions = widget.customActions ?? [
      QuickAction(
        id: 'properties_under_500k',
        title: 'عقارات أقل من 500 ألف',
        icon: Icons.home,
        color: AppTheme.primaryColor,
        query: 'أريد عقارات بسعر أقل من 500 ألف ريال',
      ),
      QuickAction(
        id: 'apartments_riyadh',
        title: 'شقق في الرياض',
        icon: Icons.apartment,
        color: AppTheme.secondaryColor,
        query: 'أبحث عن شقق في الرياض',
      ),
      QuickAction(
        id: 'villas_with_garden',
        title: 'فلل بحديقة',
        icon: Icons.villa,
        color: AppTheme.accentTextColor,
        query: 'أريد فيلا بحديقة',
      ),
      QuickAction(
        id: 'call_agent',
        title: 'اتصل بالوكيل',
        icon: Icons.phone,
        color: AppTheme.successColor,
        query: 'أريد التواصل مع الوكيل',
      ),
      QuickAction(
        id: 'schedule_visit',
        title: 'حجز معاينة',
        icon: Icons.calendar_today,
        color: AppTheme.warningColor,
        query: 'أريد حجز موعد لمعاينة العقار',
      ),
      QuickAction(
        id: 'save_favorites',
        title: 'حفظ في المفضلة',
        icon: Icons.favorite,
        color: AppTheme.errorColor,
        query: 'احفظ هذا العقار في المفضلة',
      ),
    ];
  }

  @override
  void didUpdateWidget(QuickActionButtons oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible != oldWidget.isVisible) {
      if (widget.isVisible) {
        _showButtons();
      } else {
        _hideButtons();
      }
    }
    
    if (widget.customActions != oldWidget.customActions) {
      _setupActions();
    }
  }

  void _showButtons() {
    _fadeController.forward();
    _slideController.forward();
  }

  void _hideButtons() {
    _fadeController.reverse();
    _slideController.reverse();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_slideAnimation, _fadeAnimation]),
      builder: (context, child) {
        return SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: const Text(
                      'إجراءات سريعة',
                      style: TextStyle(
                        color: AppTheme.primaryTextColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildActionGrid(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _actions.length,
      itemBuilder: (context, index) {
        final action = _actions[index];
        return _buildActionButton(action, index);
      },
    );
  }

  Widget _buildActionButton(QuickAction action, int index) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 200 + (index * 50)),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: GestureDetector(
            onTap: () => _handleActionTap(action),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    action.color,
                    action.color.withValues(alpha: 0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: action.color.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _handleActionTap(action),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            action.icon,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            action.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleActionTap(QuickAction action) {
    // Add haptic feedback
    // HapticFeedback.lightImpact();
    
    // Animate button press
    _animateButtonPress(action);
    
    // Call the callback
    widget.onActionSelected?.call(action.query);
  }

  void _animateButtonPress(QuickAction action) {
    // Simple scale animation for feedback
    // This could be enhanced with more sophisticated animations
  }
}

// Context-aware quick actions
class ContextualQuickActions extends StatelessWidget {
  final String? currentContext;
  final Function(String)? onActionSelected;
  final bool isVisible;

  const ContextualQuickActions({
    super.key,
    this.currentContext,
    this.onActionSelected,
    this.isVisible = true,
  });

  @override
  Widget build(BuildContext context) {
    final actions = _getContextualActions();
    
    return QuickActionButtons(
      customActions: actions,
      onActionSelected: onActionSelected,
      isVisible: isVisible,
    );
  }

  List<QuickAction> _getContextualActions() {
    if (currentContext == null) {
      return _getDefaultActions();
    }

    final lowerContext = currentContext!.toLowerCase();
    final actions = <QuickAction>[];

    // Property type specific actions
    if (lowerContext.contains('شقة')) {
      actions.addAll([
        QuickAction(
          id: 'more_apartments',
          title: 'المزيد من الشقق',
          icon: Icons.apartment,
          color: AppTheme.primaryColor,
          query: 'أريد المزيد من الشقق',
        ),
        QuickAction(
          id: 'apartment_features',
          title: 'مواصفات الشقة',
          icon: Icons.info,
          color: AppTheme.secondaryColor,
          query: 'ما هي مواصفات هذه الشقة؟',
        ),
      ]);
    }

    if (lowerContext.contains('فيلا')) {
      actions.addAll([
        QuickAction(
          id: 'villa_with_pool',
          title: 'فيلا بمسبح',
          icon: Icons.pool,
          color: AppTheme.accentTextColor,
          query: 'أريد فيلا بمسبح',
        ),
        QuickAction(
          id: 'villa_garden',
          title: 'فيلا بحديقة',
          icon: Icons.grass,
          color: AppTheme.successColor,
          query: 'أريد فيلا بحديقة كبيرة',
        ),
      ]);
    }

    // Price-related actions
    if (lowerContext.contains('سعر') || lowerContext.contains('ريال')) {
      actions.addAll([
        QuickAction(
          id: 'price_range',
          title: 'نطاق سعري محدد',
          icon: Icons.attach_money,
          color: AppTheme.warningColor,
          query: 'أريد عقارات في نطاق سعري محدد',
        ),
        QuickAction(
          id: 'financing_options',
          title: 'خيارات التمويل',
          icon: Icons.account_balance,
          color: AppTheme.primaryColor,
          query: 'ما هي خيارات التمويل المتاحة؟',
        ),
      ]);
    }

    // Location-related actions
    if (lowerContext.contains('منطقة') || lowerContext.contains('موقع')) {
      actions.addAll([
        QuickAction(
          id: 'nearby_services',
          title: 'الخدمات القريبة',
          icon: Icons.location_on,
          color: AppTheme.errorColor,
          query: 'ما هي الخدمات القريبة من هذا الموقع؟',
        ),
        QuickAction(
          id: 'transportation',
          title: 'المواصلات',
          icon: Icons.directions_bus,
          color: AppTheme.secondaryColor,
          query: 'كيف المواصلات في هذه المنطقة؟',
        ),
      ]);
    }

    // Add common actions
    actions.addAll([
      QuickAction(
        id: 'call_agent',
        title: 'اتصل بالوكيل',
        icon: Icons.phone,
        color: AppTheme.successColor,
        query: 'أريد التواصل مع الوكيل',
      ),
      QuickAction(
        id: 'save_property',
        title: 'احفظ العقار',
        icon: Icons.favorite,
        color: AppTheme.errorColor,
        query: 'احفظ هذا العقار في المفضلة',
      ),
    ]);

    return actions.take(6).toList();
  }

  List<QuickAction> _getDefaultActions() {
    return [
      QuickAction(
        id: 'search_apartments',
        title: 'ابحث عن شقق',
        icon: Icons.apartment,
        color: AppTheme.primaryColor,
        query: 'أبحث عن شقق',
      ),
      QuickAction(
        id: 'search_villas',
        title: 'ابحث عن فلل',
        icon: Icons.villa,
        color: AppTheme.secondaryColor,
        query: 'أبحث عن فلل',
      ),
      QuickAction(
        id: 'price_inquiry',
        title: 'استفسار عن الأسعار',
        icon: Icons.attach_money,
        color: AppTheme.warningColor,
        query: 'ما هي أسعار العقارات؟',
      ),
      QuickAction(
        id: 'call_agent',
        title: 'اتصل بالوكيل',
        icon: Icons.phone,
        color: AppTheme.successColor,
        query: 'أريد التواصل مع الوكيل',
      ),
    ];
  }
}

class QuickAction {
  final String id;
  final String title;
  final IconData icon;
  final Color color;
  final String query;

  QuickAction({
    required this.id,
    required this.title,
    required this.icon,
    required this.color,
    required this.query,
  });
}
