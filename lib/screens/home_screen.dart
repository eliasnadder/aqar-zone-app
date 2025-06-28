import 'package:flutter/material.dart';
import '../models/property_model.dart';
import '../services/properties_service.dart';
import '../widgets/AI/global_ai_chat_drawer.dart';
import '../widgets/enhanced_property_card.dart';
import '../widgets/enhanced_loading_state.dart';
import '../widgets/enhanced_empty_state.dart';
import '../widgets/animated_fab.dart';
import 'property_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onThemeToggle;

  const HomeScreen({Key? key, this.onThemeToggle}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Property> _properties = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProperties();
  }

  Future<void> _loadProperties() async {
    try {
      final properties = await PropertiesService.getPropertiesStatic();
      setState(() {
        _properties = properties;
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load properties: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _navigateToDetail(Property property) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder:
            (context, animation, secondaryAnimation) =>
                PropertyDetailScreen(property: property),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;

          var tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  void _showAIChat() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.9,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder:
                (context, scrollController) => Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: GlobalAIChatDrawer(properties: _properties),
                ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Aqar Zone',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        actions: [
          if (widget.onThemeToggle != null)
            IconButton(
              icon: Icon(
                theme.brightness == Brightness.light
                    ? Icons.dark_mode_rounded
                    : Icons.light_mode_rounded,
              ),
              onPressed: widget.onThemeToggle,
              tooltip: 'Toggle theme',
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primaryContainer.withValues(alpha: 0.1),
              theme.colorScheme.surface,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child:
              _isLoading
                  ? const EnhancedLoadingState(
                    message: 'Loading properties...',
                    showShimmer: true,
                  )
                  : _properties.isEmpty
                  ? const EnhancedEmptyState(
                    title: 'No Properties Found',
                    subtitle: 'Check back later for new listings!',
                    icon: Icons.home_work_outlined,
                    suggestions: [
                      'Properties will appear here',
                      'Try refreshing the page',
                      'Contact us for more info',
                    ],
                  )
                  : RefreshIndicator(
                    onRefresh: _loadProperties,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                      itemCount: _properties.length,
                      itemBuilder: (context, index) {
                        final property = _properties[index];
                        return EnhancedPropertyCard(
                          property: property,
                          index: index,
                          onTap: () => _navigateToDetail(property),
                        );
                      },
                    ),
                  ),
        ),
      ),
      floatingActionButton: AnimatedFAB(
        onPressed: _showAIChat,
        icon: Icons.smart_toy_rounded,
        tooltip: 'Ask AI about properties',
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
    );
  }
}
