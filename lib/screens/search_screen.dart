import 'package:flutter/material.dart';
import '../models/property_model.dart';
import '../services/properties_service.dart';
import '../widgets/enhanced_property_card.dart';
import 'property_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  // PropertiesService has static methods, no need for instance

  List<Property> _searchResults = [];
  List<Property> _recentSearches = [];
  List<String> _searchHistory = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  String _selectedPropertyType = 'All';
  String _selectedPriceRange = 'All';
  String _selectedLocation = 'All';
  String _sortBy = 'Newest';
  bool _showFilters = false;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final List<String> _propertyTypes = [
    'All',
    'Apartment',
    'Villa',
    'Office',
    'Shop',
    'House',
    'Studio',
    'Penthouse',
  ];
  final List<String> _priceRanges = [
    'All',
    'Under 100k',
    '100k-500k',
    '500k-1M',
    '1M-2M',
    'Above 2M',
  ];
  final List<String> _locations = [
    'All',
    'Downtown',
    'Suburbs',
    'Waterfront',
    'City Center',
    'Residential',
    'Commercial',
  ];
  final List<String> _sortOptions = [
    'Newest',
    'Price: Low to High',
    'Price: High to Low',
    'Most Popular',
    'Size: Large to Small',
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _fadeController.forward();
    _loadRecentSearches();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadRecentSearches() async {
    try {
      final response = await PropertiesService.getPropertiesPaginated();
      final properties = response.data;
      if (mounted) {
        setState(() {
          _recentSearches = properties.take(5).toList();
        });
      }
    } catch (e) {
      // Handle error silently for recent searches
    }
  }

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    // Add to search history
    if (query.isNotEmpty && !_searchHistory.contains(query)) {
      _searchHistory.insert(0, query);
      if (_searchHistory.length > 10) {
        _searchHistory.removeLast();
      }
    }

    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    try {
      final response = await PropertiesService.getPropertiesPaginated();
      final properties = response.data;

      // Filter properties based on search criteria
      final filteredProperties =
          properties.where((property) {
            final matchesQuery =
                property.title.toLowerCase().contains(query.toLowerCase()) ||
                property.location.toLowerCase().contains(query.toLowerCase()) ||
                property.description.toLowerCase().contains(
                  query.toLowerCase(),
                ) ||
                (property.adNumber.toLowerCase().contains(
                  query.toLowerCase(),
                )) ||
                property.id.toString().contains(query);

            final matchesType =
                _selectedPropertyType == 'All' ||
                property.type.toLowerCase().contains(
                  _selectedPropertyType.toLowerCase(),
                );

            final matchesPrice =
                _selectedPriceRange == 'All' ||
                _matchesPriceRange(property.price);

            final matchesLocation =
                _selectedLocation == 'All' ||
                property.location.toLowerCase().contains(
                  _selectedLocation.toLowerCase(),
                );

            return matchesQuery &&
                matchesType &&
                matchesPrice &&
                matchesLocation;
          }).toList();

      // Apply sorting
      final sortedProperties = _applySorting(filteredProperties);

      if (mounted) {
        setState(() {
          _searchResults = sortedProperties;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Search failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<Property> _applySorting(List<Property> properties) {
    switch (_sortBy) {
      case 'Price: Low to High':
        properties.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'Price: High to Low':
        properties.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'Size: Large to Small':
        properties.sort((a, b) => (b.area).compareTo(a.area));
        break;
      case 'Most Popular':
        properties.sort((a, b) => (b.views ?? 0).compareTo(a.views ?? 0));
        break;
      case 'Newest':
      default:
        properties.sort(
          (a, b) => b.id.compareTo(a.id),
        ); // Sort by ID as proxy for newest
        break;
    }
    return properties;
  }

  bool _matchesPriceRange(double price) {
    switch (_selectedPriceRange) {
      case 'Under 100k':
        return price < 100000;
      case '100k-500k':
        return price >= 100000 && price <= 500000;
      case '500k-1M':
        return price >= 500000 && price <= 1000000;
      case '1M-2M':
        return price >= 1000000 && price <= 2000000;
      case 'Above 2M':
        return price > 2000000;
      default:
        return true;
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchResults.clear();
      _hasSearched = false;
    });
  }

  void _clearFilters() {
    setState(() {
      _selectedPropertyType = 'All';
      _selectedPriceRange = 'All';
      _selectedLocation = 'All';
      _sortBy = 'Newest';
    });
    // Re-run search if there's an active search
    if (_hasSearched) {
      _performSearch();
    }
  }

  void _showSearchHistory() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Search History',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _searchHistory.clear();
                        });
                        Navigator.pop(context);
                      },
                      child: const Text('Clear All'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_searchHistory.isEmpty)
                  const Center(child: Text('No search history yet'))
                else
                  ...List.generate(_searchHistory.length, (index) {
                    final query = _searchHistory[index];
                    return ListTile(
                      leading: const Icon(Icons.history_rounded),
                      title: Text(query),
                      trailing: IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          setState(() {
                            _searchHistory.removeAt(index);
                          });
                          Navigator.pop(context);
                        },
                      ),
                      onTap: () {
                        _searchController.text = query;
                        Navigator.pop(context);
                        _performSearch();
                      },
                    );
                  }),
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Search Properties',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            _buildSearchHeader(theme),
            _buildFilters(theme),
            Expanded(child: _buildSearchContent(theme)),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Search Bar
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.5,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by location, type, ad number, or keywords...',
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: theme.colorScheme.primary,
                ),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_searchHistory.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.history_rounded),
                        onPressed: _showSearchHistory,
                        tooltip: 'Search History',
                      ),
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: _clearSearch,
                        tooltip: 'Clear Search',
                      ),
                  ],
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              onSubmitted: (_) => _performSearch(),
              onChanged: (value) {
                setState(() {}); // Rebuild to show/hide clear button
              },
            ),
          ),

          const SizedBox(height: 16),

          // Search Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _performSearch,
              icon:
                  _isLoading
                      ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Icon(Icons.search_rounded),
              label: Text(_isLoading ? 'Searching...' : 'Search Properties'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(ThemeData theme) {
    return Column(
      children: [
        // Filter toggle button
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filters',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _showFilters = !_showFilters;
                  });
                },
                icon: Icon(
                  _showFilters
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                ),
                label: Text(_showFilters ? 'Hide Filters' : 'Show Filters'),
              ),
            ],
          ),
        ),

        // Expandable filters
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: _showFilters ? null : 0,
          child:
              _showFilters
                  ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        const SizedBox(height: 16),
                        // First row of filters
                        Row(
                          children: [
                            Expanded(
                              child: _buildFilterDropdown(
                                'Type',
                                _selectedPropertyType,
                                _propertyTypes,
                                (value) => setState(
                                  () => _selectedPropertyType = value!,
                                ),
                                theme,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildFilterDropdown(
                                'Price Range',
                                _selectedPriceRange,
                                _priceRanges,
                                (value) => setState(
                                  () => _selectedPriceRange = value!,
                                ),
                                theme,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Second row of filters
                        Row(
                          children: [
                            Expanded(
                              child: _buildFilterDropdown(
                                'Location',
                                _selectedLocation,
                                _locations,
                                (value) =>
                                    setState(() => _selectedLocation = value!),
                                theme,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildFilterDropdown(
                                'Sort By',
                                _sortBy,
                                _sortOptions,
                                (value) => setState(() => _sortBy = value!),
                                theme,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Clear filters button
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _clearFilters,
                            icon: const Icon(Icons.clear_all_rounded),
                            label: const Text('Clear All Filters'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                  : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildFilterDropdown(
    String label,
    String value,
    List<String> items,
    ValueChanged<String?> onChanged,
    ThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          items:
              items.map((item) {
                return DropdownMenuItem(
                  value: item,
                  child: Text(item, style: theme.textTheme.bodyMedium),
                );
              }).toList(),
          onChanged: onChanged,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchContent(ThemeData theme) {
    if (!_hasSearched) {
      return _buildRecentSearches(theme);
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchResults.isEmpty) {
      return _buildNoResults(theme);
    }

    return _buildSearchResults(theme);
  }

  Widget _buildRecentSearches(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search suggestions
          if (_searchHistory.isNotEmpty) ...[
            Text(
              'Recent Searches',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  _searchHistory.take(5).map((query) {
                    return ActionChip(
                      label: Text(query),
                      onPressed: () {
                        _searchController.text = query;
                        _performSearch();
                      },
                      backgroundColor: theme.colorScheme.primaryContainer
                      // ignore: deprecated_member_use
                      .withOpacity(0.3),
                      side: BorderSide(
                        // ignore: deprecated_member_use
                        color: theme.colorScheme.primary.withOpacity(0.3),
                      ),
                    );
                  }).toList(),
            ),
            const SizedBox(height: 24),
          ],

          Text(
            'Recent Properties',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (_recentSearches.isEmpty)
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.search_rounded,
                    size: 64,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Start searching for properties',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            )
          else
            ...List.generate(_recentSearches.length, (index) {
              final property = _recentSearches[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: EnhancedPropertyCard(
                  property: property,
                  index: index,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) =>
                                PropertyDetailScreen(property: property),
                      ),
                    );
                  },
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildSearchResults(ThemeData theme) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_searchResults.length} Properties Found',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton.icon(
                onPressed: _clearSearch,
                icon: const Icon(Icons.clear_rounded),
                label: const Text('Clear'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _searchResults.length,
            itemBuilder: (context, index) {
              final property = _searchResults[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: EnhancedPropertyCard(
                  property: property,
                  index: index,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) =>
                                PropertyDetailScreen(property: property),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNoResults(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 80,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 24),
            Text(
              'No Properties Found',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Try adjusting your search criteria or filters',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _clearSearch,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Clear Search'),
            ),
          ],
        ),
      ),
    );
  }
}
