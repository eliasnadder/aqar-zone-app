import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:test_app/widgets/animated_fab.dart';
import '../models/property_model.dart';
import '../models/agent.dart';
import '../widgets/AI/ai_chat_drawer.dart';
import '../widgets/interactive_map_widget.dart';
import '../widgets/agent_contact_widget.dart';
import '../widgets/currency_selector.dart';
import '../providers/currency_provider.dart';

class PropertyDetailScreen extends StatefulWidget {
  final Property property;

  const PropertyDetailScreen({Key? key, required this.property})
    : super(key: key);

  @override
  State<PropertyDetailScreen> createState() => _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends State<PropertyDetailScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  final ScrollController _scrollController = ScrollController();
  bool _isAppBarExpanded = true;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    _scrollController.addListener(_onScroll);

    // Start animations
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final isExpanded = _scrollController.offset < 200;
    if (isExpanded != _isAppBarExpanded) {
      setState(() {
        _isAppBarExpanded = isExpanded;
      });
    }
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
                  child: AIChatDrawer(property: widget.property),
                ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          _buildSliverAppBar(theme),
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: _buildContent(theme),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(theme),
    );
  }

  Widget _buildSliverAppBar(ThemeData theme) {
    return SliverAppBar(
      expandedHeight: 320,
      pinned: true,
      elevation: 0,
      backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.95),
      surfaceTintColor: Colors.transparent,
      foregroundColor: theme.colorScheme.onSurface,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            theme.brightness == Brightness.light
                ? Brightness.dark
                : Brightness.light,
        statusBarBrightness: theme.brightness,
      ),
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Back',
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        title: AnimatedOpacity(
          opacity: _isAppBarExpanded ? 0.0 : 1.0,
          duration: const Duration(milliseconds: 300),
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              widget.property.title,
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        titlePadding: const EdgeInsets.only(left: 72, bottom: 16, right: 120),
        background: Hero(
          tag: 'property-${widget.property.adNumber}',
          child: _buildHeroImage(theme),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 4),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: Icon(
              _isFavorite
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              color: _isFavorite ? Colors.red : Colors.white,
            ),
            onPressed: _toggleFavorite,
            tooltip: _isFavorite ? 'Remove from favorites' : 'Add to favorites',
          ),
        ),
        Container(
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.share_rounded, color: Colors.white),
            onPressed: _shareProperty,
            tooltip: 'Share property',
          ),
        ),
      ],
    );
  }

  Widget _buildHeroImage(ThemeData theme) {
    final images = widget.property.images;
    final hasImages = images != null && images.isNotEmpty;

    return SizedBox.expand(
      child: Stack(
        children: [
          // Main image or placeholder
          if (hasImages)
            Image.network(
              images.first,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _buildImagePlaceholder(theme);
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: Center(
                    child: CircularProgressIndicator(
                      value:
                          loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                    ),
                  ),
                );
              },
            )
          else
            _buildImagePlaceholder(theme),

          // Gradient overlay for better text readability
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // Property type and status badges
          Positioned(
            bottom: 80,
            left: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Property type badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _getAdTypeColor(widget.property.adType),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getAdTypeIcon(widget.property.adType),
                        size: 16,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        widget.property.adType.toUpperCase(),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Property status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(
                      widget.property.status,
                    ).withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        widget.property.status.toUpperCase(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Image count indicator (if multiple images)
          if (hasImages && images.length > 1)
            Positioned(
              top: 80,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.photo_library_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${images.length}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Gallery button overlay
          if (hasImages)
            Positioned(
              bottom: 20,
              right: 16,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.primary.withValues(alpha: 0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(25),
                    onTap: () => _showImageGallery(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.photo_library_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'View Gallery',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder(ThemeData theme) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
            theme.colorScheme.secondaryContainer.withValues(alpha: 0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.home_work_rounded,
              size: 80,
              color: theme.colorScheme.primary.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 16),
            Text(
              'No Image Available',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPropertyHeader(theme),
          const SizedBox(height: 24),
          _buildPropertyStats(theme),
          const SizedBox(height: 20),
          _buildQuickActions(theme),
          const SizedBox(height: 20),
          _buildPropertyDetails(theme),
          const SizedBox(height: 20),
          if (widget.property.features.isNotEmpty) ...[
            _buildPropertyFeatures(theme),
            const SizedBox(height: 20),
          ],
          _buildDescription(theme),
          const SizedBox(height: 20),
          if (widget.property.images?.isNotEmpty == true) ...[
            _buildImageGallery(theme),
            const SizedBox(height: 20),
          ],
          _buildLocationMap(theme),
          const SizedBox(height: 20),
          _buildAgentContact(theme),
          const SizedBox(height: 100), // Space for FAB
        ],
      ),
    );
  }

  Widget _buildPropertyHeader(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.property.title,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              Icons.location_on_rounded,
              size: 18,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                widget.property.location,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Consumer<CurrencyProvider>(
                          builder: (context, currencyProvider, child) {
                            // Convert price to selected currency
                            final convertedPrice = currencyProvider
                                .convertToSelected(
                                  widget.property.price,
                                  widget.property.currency,
                                );

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  currencyProvider.formatAmount(convertedPrice),
                                  style: theme.textTheme.headlineLarge
                                      ?.copyWith(
                                        color: theme.colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                if (currencyProvider.selectedCurrency !=
                                    widget.property.currency)
                                  Text(
                                    'Original: ${widget.property.formattedPrice}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.5),
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                Text(
                                  '${currencyProvider.formatAmountInCurrency(convertedPrice / widget.property.area, currencyProvider.selectedCurrency)}/m²',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Consumer<CurrencyProvider>(
                        builder: (context, currencyProvider, child) {
                          return CurrencySelector(
                            selectedCurrency: currencyProvider.selectedCurrency,
                            onCurrencyChanged: (currency) async {
                              // Only update CurrencyProvider to avoid conflicts
                              await currencyProvider.setSelectedCurrency(
                                currency,
                              );
                            },
                            isCompact: true,
                            showLabel: false,
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.bed_rounded,
                    size: 20,
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    widget.property.bedroomsDisplay,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    Icons.bathtub_rounded,
                    size: 20,
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${widget.property.bathrooms}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPropertyStats(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          // Status indicator
          Expanded(
            child: _buildStatItem(
              icon: Icons.info_outline_rounded,
              label: 'Status',
              value: widget.property.status.toUpperCase(),
              color: _getStatusColor(widget.property.status),
              theme: theme,
            ),
          ),
          const SizedBox(width: 16),
          // Views count
          Expanded(
            child: _buildStatItem(
              icon: Icons.visibility_outlined,
              label: 'Views',
              value: '${widget.property.views ?? 0}',
              color: theme.colorScheme.primary,
              theme: theme,
            ),
          ),
          const SizedBox(width: 16),
          // Property ID
          Expanded(
            child: _buildStatItem(
              icon: Icons.tag_rounded,
              label: 'ID',
              value: widget.property.adNumber,
              color: theme.colorScheme.secondary,
              theme: theme,
              onTap: _copyAdNumber,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required ThemeData theme,
    VoidCallback? onTap,
  }) {
    Widget content = Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(icon, color: color, size: 24),
            if (onTap != null)
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.content_copy_rounded,
                    color: Colors.white,
                    size: 10,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            if (onTap != null) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.touch_app_rounded,
                size: 12,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ],
          ],
        ),
      ],
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
            ),
            child: content,
          ),
        ),
      );
    }

    return content;
  }

  void _copyAdNumber() {
    final adNumber = widget.property.adNumber;
    Clipboard.setData(ClipboardData(text: adNumber));

    // Show animated snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ad number copied',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    adNumber,
                    style: const TextStyle(
                      fontWeight: FontWeight.w400,
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return Colors.green;
      case 'rented':
        return Colors.orange;
      case 'sold':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getAdTypeColor(String adType) {
    switch (adType.toLowerCase()) {
      case 'sale':
        return const Color(0xFF2E7D32); // Dark green for sale
      case 'rent':
        return const Color(0xFF1565C0); // Dark blue for rent
      case 'lease':
        return const Color(0xFF7B1FA2); // Purple for lease
      default:
        return const Color(0xFF424242); // Dark grey for others
    }
  }

  IconData _getAdTypeIcon(String adType) {
    switch (adType.toLowerCase()) {
      case 'sale':
        return Icons.sell_rounded;
      case 'rent':
        return Icons.key_rounded;
      case 'lease':
        return Icons.assignment_rounded;
      default:
        return Icons.home_rounded;
    }
  }

  Widget _buildQuickActions(ThemeData theme) {
    final agent = widget.property.agent ?? Agent.defaultAgent;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildActionButton(
              icon: Icons.phone_rounded,
              label: 'Call',
              color: Colors.green,
              onTap: () => _makePhoneCall(agent.phone),
              theme: theme,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildActionButton(
              icon: Icons.message_rounded,
              label: 'WhatsApp',
              color: const Color(0xFF25D366),
              onTap: () => _openWhatsApp(agent.phone),
              theme: theme,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildActionButton(
              icon: Icons.email_rounded,
              label: 'Email',
              color: Colors.blue,
              onTap: () => _sendEmail(agent.email),
              theme: theme,
            ),
          ),
          if (widget.property.images?.isNotEmpty == true) ...[
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                icon: Icons.photo_library_rounded,
                label: 'Gallery',
                color: theme.colorScheme.primary,
                onTap: () => _showImageGallery(),
                theme: theme,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required ThemeData theme,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPropertyDetails(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Property Details',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailRow(
            'Type',
            '${widget.property.type} for ${widget.property.adType}',
            theme,
          ),
          _buildDetailRow('Location', widget.property.location, theme),
          _buildDetailRow('Size', '${widget.property.area} m²', theme),
          _buildDetailRow('Rooms', widget.property.bedroomsDisplay, theme),
          _buildDetailRow('Bathrooms', '${widget.property.bathrooms}', theme),
          _buildDetailRow('Furnishing', widget.property.furnishing, theme),
          if (widget.property.sellerType != null)
            _buildDetailRow('Seller Type', widget.property.sellerType!, theme),
          if (widget.property.floorNumber != null)
            _buildDetailRow('Floor', '${widget.property.floorNumber}', theme),
          if (widget.property.direction != null)
            _buildDetailRow('Direction', widget.property.direction!, theme),
        ],
      ),
    );
  }

  Widget _buildPropertyFeatures(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Features & Amenities',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                widget.property.features.map((feature) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withValues(
                        alpha: 0.5,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getFeatureIcon(feature),
                          size: 16,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          feature,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  IconData _getFeatureIcon(String feature) {
    final lowerFeature = feature.toLowerCase();
    if (lowerFeature.contains('pool') || lowerFeature.contains('swimming')) {
      return Icons.pool_rounded;
    } else if (lowerFeature.contains('gym') ||
        lowerFeature.contains('fitness')) {
      return Icons.fitness_center_rounded;
    } else if (lowerFeature.contains('parking') ||
        lowerFeature.contains('garage')) {
      return Icons.local_parking_rounded;
    } else if (lowerFeature.contains('garden') ||
        lowerFeature.contains('balcony')) {
      return Icons.grass_rounded;
    } else if (lowerFeature.contains('security') ||
        lowerFeature.contains('guard')) {
      return Icons.security_rounded;
    } else if (lowerFeature.contains('elevator') ||
        lowerFeature.contains('lift')) {
      return Icons.elevator_rounded;
    } else if (lowerFeature.contains('ac') || lowerFeature.contains('air')) {
      return Icons.ac_unit_rounded;
    } else if (lowerFeature.contains('wifi') ||
        lowerFeature.contains('internet')) {
      return Icons.wifi_rounded;
    } else {
      return Icons.check_circle_outline_rounded;
    }
  }

  Widget _buildImageGallery(ThemeData theme) {
    final images = widget.property.images ?? [];
    if (images.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Photo Gallery',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton.icon(
              onPressed: _showImageGallery,
              icon: const Icon(Icons.fullscreen_rounded),
              label: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: images.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.only(
                  right: index < images.length - 1 ? 12 : 0,
                ),
                child: GestureDetector(
                  onTap: () => _showImageGallery(initialIndex: index),
                  child: Container(
                    width: 160,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        images[index],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: theme.colorScheme.surfaceContainerHighest,
                            child: Icon(
                              Icons.image_not_supported_rounded,
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.5,
                              ),
                            ),
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: theme.colorScheme.surfaceContainerHighest,
                            child: Center(
                              child: CircularProgressIndicator(
                                value:
                                    loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress
                                                .cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDescription(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Description',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.property.description,
            style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton(ThemeData theme) {
    return AnimatedFAB(
      onPressed: _showAIChat,
      icon: Icons.smart_toy_rounded,
      tooltip: 'Ask AI about properties',
      backgroundColor: theme.colorScheme.primary,
      foregroundColor: theme.colorScheme.onPrimary,
    );
  }

  Widget _buildLocationMap(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Location & Directions',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        InteractiveMapWidget(
          property: widget.property,
          height: 400,
          padding: const EdgeInsets.all(0),
        ),
      ],
    );
  }

  Widget _buildAgentContact(ThemeData theme) {
    // Always show agent contact with default agent if none provided
    final agent = widget.property.agent ?? Agent.defaultAgent;

    return AgentContactWidget(agent: agent);
  }

  void _toggleFavorite() {
    setState(() {
      _isFavorite = !_isFavorite;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isFavorite ? 'Added to favorites' : 'Removed from favorites',
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _shareProperty() {
    // Get current currency provider for sharing
    final currencyProvider = Provider.of<CurrencyProvider>(
      context,
      listen: false,
    );
    final convertedPrice = currencyProvider.convertToSelected(
      widget.property.price,
      widget.property.currency,
    );
    final formattedPrice = currencyProvider.formatAmount(convertedPrice);

    final propertyText = '''
🏠 ${widget.property.title}

💰 $formattedPrice
📍 ${widget.property.location}
🛏️ ${widget.property.bedroomsDisplay} rooms
🛁 ${widget.property.bathrooms} bathrooms

${widget.property.description}

Shared via Aqar Zone App
''';

    Share.share(
      propertyText,
      subject: 'Check out this property: ${widget.property.title}',
    );
  }

  Widget _buildDetailRow(String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Action methods for quick actions
  void _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not launch phone call to $phoneNumber'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _openWhatsApp(String phoneNumber) async {
    // Remove any non-digit characters and ensure proper format
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    final Uri whatsappUri = Uri.parse('https://wa.me/$cleanNumber');

    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open WhatsApp for $phoneNumber'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _sendEmail(String email) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=Inquiry about ${widget.property.title}',
    );

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not launch email to $email'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showImageGallery({int initialIndex = 0}) {
    final images = widget.property.images ?? [];
    if (images.isEmpty) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => _ImageGalleryScreen(
              images: images,
              initialIndex: initialIndex,
              propertyTitle: widget.property.title,
            ),
      ),
    );
  }
}

// Full-screen image gallery
class _ImageGalleryScreen extends StatefulWidget {
  final List<String> images;
  final int initialIndex;
  final String propertyTitle;

  const _ImageGalleryScreen({
    required this.images,
    required this.initialIndex,
    required this.propertyTitle,
  });

  @override
  State<_ImageGalleryScreen> createState() => _ImageGalleryScreenState();
}

class _ImageGalleryScreenState extends State<_ImageGalleryScreen> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.propertyTitle,
              style: const TextStyle(fontSize: 16),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '${_currentIndex + 1} of ${widget.images.length}',
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            onPressed: () {
              Share.share(
                widget.images[_currentIndex],
                subject: 'Property Image - ${widget.propertyTitle}',
              );
            },
          ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.images.length,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        itemBuilder: (context, index) {
          return InteractiveViewer(
            child: Center(
              child: Image.network(
                widget.images[index],
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[900],
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.image_not_supported_rounded,
                            color: Colors.white54,
                            size: 64,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Failed to load image',
                            style: TextStyle(color: Colors.white54),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value:
                          loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                      color: Colors.white,
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
      bottomNavigationBar:
          widget.images.length > 1
              ? Container(
                color: Colors.black,
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed:
                          _currentIndex > 0
                              ? () {
                                _pageController.previousPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              }
                              : null,
                      icon: const Icon(Icons.arrow_back_ios_rounded),
                      color: Colors.white,
                    ),
                    const SizedBox(width: 20),
                    Text(
                      '${_currentIndex + 1} / ${widget.images.length}',
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    const SizedBox(width: 20),
                    IconButton(
                      onPressed:
                          _currentIndex < widget.images.length - 1
                              ? () {
                                _pageController.nextPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              }
                              : null,
                      icon: const Icon(Icons.arrow_forward_ios_rounded),
                      color: Colors.white,
                    ),
                  ],
                ),
              )
              : null,
    );
  }
}
