import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../services/properties_service.dart';
import '../../models/property_model.dart';
import 'properties_event.dart';
import 'properties_state.dart';

class PropertiesBloc extends Bloc<PropertiesEvent, PropertiesState> {
  final PropertiesService _propertiesService;
  static const String _favoritesKey = 'favorite_properties';
  static const String _cachedPropertiesKey = 'cached_properties';
  static const String _cacheTimeKey = 'cache_time';
  static const Duration _cacheExpiry = Duration(hours: 1);

  List<String> _favoritePropertyIds = [];
  Timer? _debounceTimer;

  PropertiesBloc({required PropertiesService propertiesService})
    : _propertiesService = propertiesService,
      super(const PropertiesInitial()) {
    on<LoadProperties>(_onLoadProperties);
    on<RefreshProperties>(_onRefreshProperties);
    on<SearchProperties>(_onSearchProperties);
    on<FilterProperties>(_onFilterProperties);
    on<ClearFilters>(_onClearFilters);
    on<LoadMoreProperties>(_onLoadMoreProperties);
    on<ToggleFavoriteProperty>(_onToggleFavoriteProperty);
    on<LoadFavoriteProperties>(_onLoadFavoriteProperties);
    on<SearchByAdNumber>(_onSearchByAdNumber);
    on<UpdatePropertyViews>(_onUpdatePropertyViews);
    on<LoadPropertyDetails>(_onLoadPropertyDetails);
    on<ClearPropertyDetails>(_onClearPropertyDetails);
    on<LoadSimilarProperties>(_onLoadSimilarProperties);
    on<UpdatePropertyFilters>(_onUpdatePropertyFilters);
    on<SortProperties>(_onSortProperties);
    on<CacheProperties>(_onCacheProperties);
    on<LoadCachedProperties>(_onLoadCachedProperties);

    _loadFavoriteIds();
  }

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    return super.close();
  }

  Future<void> _loadFavoriteIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoriteIds = prefs.getStringList(_favoritesKey) ?? [];
      _favoritePropertyIds = favoriteIds;
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _saveFavoriteIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_favoritesKey, _favoritePropertyIds);
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _onLoadProperties(
    LoadProperties event,
    Emitter<PropertiesState> emit,
  ) async {
    try {
      if (event.page == 1) {
        emit(const PropertiesLoading());
      } else {
        if (state is PropertiesLoaded) {
          final currentState = state as PropertiesLoaded;
          emit(
            PropertiesLoadingMore(
              currentProperties: currentState.properties,
              hasReachedMax: currentState.hasReachedMax,
              currentPage: currentState.currentPage,
              searchQuery: event.searchQuery,
              filters: event.filters,
            ),
          );
        }
      }

      final response = await _propertiesService.getProperties(
        page: event.page,
        limit: event.limit,
        searchQuery: event.searchQuery,
        filters: event.filters,
      );

      final properties = response.data;
      final hasReachedMax = properties.length < event.limit;

      List<Property> allProperties = [];
      if (event.page > 1 && state is PropertiesLoaded) {
        final currentState = state as PropertiesLoaded;
        allProperties = [...currentState.properties, ...properties];
      } else {
        allProperties = properties;
      }

      emit(
        PropertiesLoaded(
          properties: allProperties,
          hasReachedMax: hasReachedMax,
          currentPage: event.page,
          totalCount: response.totalCount,
          searchQuery: event.searchQuery,
          filters: event.filters,
          favoritePropertyIds: _favoritePropertyIds,
        ),
      );

      // Cache properties if it's the first page
      if (event.page == 1) {
        add(const CacheProperties());
      }
    } catch (e) {
      // Try to load cached properties on error
      final cachedProperties = await _loadCachedProperties();
      emit(
        PropertiesError(
          message: e.toString(),
          cachedProperties: cachedProperties,
        ),
      );
    }
  }

  Future<void> _onRefreshProperties(
    RefreshProperties event,
    Emitter<PropertiesState> emit,
  ) async {
    try {
      List<Property> currentProperties = [];
      if (state is PropertiesLoaded) {
        currentProperties = (state as PropertiesLoaded).properties;
        emit(PropertiesRefreshing(currentProperties: currentProperties));
      }

      final response = await _propertiesService.getProperties(
        page: 1,
        limit: 20,
        searchQuery: event.searchQuery,
        filters: event.filters,
      );

      final properties = response.data;
      final hasReachedMax = properties.length < 20;

      emit(
        PropertiesLoaded(
          properties: properties,
          hasReachedMax: hasReachedMax,
          currentPage: 1,
          totalCount: response.totalCount,
          searchQuery: event.searchQuery,
          filters: event.filters,
          favoritePropertyIds: _favoritePropertyIds,
        ),
      );

      // Cache refreshed properties
      add(const CacheProperties());
    } catch (e) {
      emit(PropertiesError(message: e.toString()));
    }
  }

  Future<void> _onSearchProperties(
    SearchProperties event,
    Emitter<PropertiesState> emit,
  ) async {
    // Debounce search requests
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      add(
        LoadProperties(
          page: 1,
          searchQuery: event.query,
          filters: event.filters,
        ),
      );
    });

    emit(PropertiesSearching(query: event.query));
  }

  Future<void> _onFilterProperties(
    FilterProperties event,
    Emitter<PropertiesState> emit,
  ) async {
    emit(PropertiesFiltering(filters: event.filters));

    add(
      LoadProperties(
        page: 1,
        filters: event.filters,
        searchQuery:
            state is PropertiesLoaded
                ? (state as PropertiesLoaded).searchQuery
                : null,
      ),
    );
  }

  Future<void> _onClearFilters(
    ClearFilters event,
    Emitter<PropertiesState> emit,
  ) async {
    add(const LoadProperties(page: 1));
  }

  Future<void> _onLoadMoreProperties(
    LoadMoreProperties event,
    Emitter<PropertiesState> emit,
  ) async {
    if (state is PropertiesLoaded) {
      final currentState = state as PropertiesLoaded;
      if (!currentState.hasReachedMax) {
        add(
          LoadProperties(
            page: currentState.currentPage + 1,
            searchQuery: currentState.searchQuery,
            filters: currentState.filters,
          ),
        );
      }
    }
  }

  Future<void> _onToggleFavoriteProperty(
    ToggleFavoriteProperty event,
    Emitter<PropertiesState> emit,
  ) async {
    final isFavorite = _favoritePropertyIds.contains(event.propertyId);

    if (isFavorite) {
      _favoritePropertyIds.remove(event.propertyId);
    } else {
      _favoritePropertyIds.add(event.propertyId);
    }

    await _saveFavoriteIds();

    emit(
      PropertyFavoriteToggled(
        propertyId: event.propertyId,
        isFavorite: !isFavorite,
      ),
    );

    // Update the current state with new favorite IDs
    if (state is PropertiesLoaded) {
      final currentState = state as PropertiesLoaded;
      emit(currentState.copyWith(favoritePropertyIds: _favoritePropertyIds));
    }
  }

  Future<void> _onLoadFavoriteProperties(
    LoadFavoriteProperties event,
    Emitter<PropertiesState> emit,
  ) async {
    try {
      emit(const PropertiesLoading());

      final favoriteProperties = <Property>[];

      for (final propertyId in _favoritePropertyIds) {
        try {
          final property = await _propertiesService.getPropertyById(propertyId);
          if (property != null) {
            favoriteProperties.add(property);
          }
        } catch (e) {
          // Skip properties that can't be loaded
        }
      }

      emit(
        FavoritePropertiesLoaded(
          favoriteProperties: favoriteProperties,
          favoritePropertyIds: _favoritePropertyIds,
        ),
      );
    } catch (e) {
      emit(PropertiesError(message: e.toString()));
    }
  }

  Future<void> _onSearchByAdNumber(
    SearchByAdNumber event,
    Emitter<PropertiesState> emit,
  ) async {
    try {
      emit(PropertiesSearching(query: event.adNumber));

      final property = await _propertiesService.getPropertyByAdNumber(
        event.adNumber,
      );

      if (property != null) {
        emit(
          PropertiesLoaded(
            properties: [property],
            hasReachedMax: true,
            currentPage: 1,
            totalCount: 1,
            searchQuery: event.adNumber,
            favoritePropertyIds: _favoritePropertyIds,
          ),
        );
      } else {
        emit(const PropertiesError(message: 'Property not found'));
      }
    } catch (e) {
      emit(PropertiesError(message: e.toString()));
    }
  }

  Future<void> _onUpdatePropertyViews(
    UpdatePropertyViews event,
    Emitter<PropertiesState> emit,
  ) async {
    try {
      final newViewCount = await _propertiesService.incrementPropertyViews(
        event.propertyId,
      );

      emit(
        PropertyViewsUpdated(
          propertyId: event.propertyId,
          newViewCount: newViewCount,
        ),
      );
    } catch (e) {
      // Handle error silently for view updates
    }
  }

  Future<void> _onLoadPropertyDetails(
    LoadPropertyDetails event,
    Emitter<PropertiesState> emit,
  ) async {
    try {
      if (event.propertyId.isEmpty) {
        emit(
          PropertyDetailsError(
            message: 'Invalid property ID',
            propertyId: event.propertyId,
          ),
        );
        return;
      }

      emit(const PropertyDetailsLoading());

      final property = await _propertiesService.getPropertyById(
        event.propertyId,
      );

      if (property != null) {
        emit(PropertyDetailsLoaded(property: property));

        // Load similar properties
        add(LoadSimilarProperties(propertyId: event.propertyId));
      } else {
        emit(
          PropertyDetailsError(
            message: 'Property not found',
            propertyId: event.propertyId,
          ),
        );
      }
    } catch (e) {
      emit(
        PropertyDetailsError(
          message: 'Failed to load property: ${e.toString()}',
          propertyId: event.propertyId,
        ),
      );
    }
  }

  Future<void> _onClearPropertyDetails(
    ClearPropertyDetails event,
    Emitter<PropertiesState> emit,
  ) async {
    if (state is PropertiesLoaded) {
      // Return to properties list
      return;
    }
    emit(const PropertiesInitial());
  }

  Future<void> _onLoadSimilarProperties(
    LoadSimilarProperties event,
    Emitter<PropertiesState> emit,
  ) async {
    try {
      if (state is PropertyDetailsLoaded) {
        final currentState = state as PropertyDetailsLoaded;
        final similarProperties = await _propertiesService.getSimilarProperties(
          event.propertyId,
          limit: event.limit,
        );

        emit(currentState.copyWith(similarProperties: similarProperties));
      }
    } catch (e) {
      // Handle error silently for similar properties
    }
  }

  Future<void> _onUpdatePropertyFilters(
    UpdatePropertyFilters event,
    Emitter<PropertiesState> emit,
  ) async {
    final filters = <String, dynamic>{};

    if (event.propertyType != null) filters['type'] = event.propertyType;
    if (event.adType != null) filters['ad_type'] = event.adType;
    if (event.minPrice != null) filters['min_price'] = event.minPrice;
    if (event.maxPrice != null) filters['max_price'] = event.maxPrice;
    if (event.location != null) filters['location'] = event.location;
    if (event.minRooms != null) filters['min_rooms'] = event.minRooms;
    if (event.maxRooms != null) filters['max_rooms'] = event.maxRooms;
    if (event.minBathrooms != null) {
      filters['min_bathrooms'] = event.minBathrooms;
    }
    if (event.maxBathrooms != null) {
      filters['max_bathrooms'] = event.maxBathrooms;
    }
    if (event.minArea != null) filters['min_area'] = event.minArea;
    if (event.maxArea != null) filters['max_area'] = event.maxArea;
    if (event.furnishing != null) filters['furnishing'] = event.furnishing;
    if (event.sellerType != null) filters['seller_type'] = event.sellerType;

    add(FilterProperties(filters: filters));
  }

  Future<void> _onSortProperties(
    SortProperties event,
    Emitter<PropertiesState> emit,
  ) async {
    if (state is PropertiesLoaded) {
      final currentState = state as PropertiesLoaded;
      emit(PropertiesSorting(sortBy: event.sortBy, ascending: event.ascending));

      final sortedProperties = _sortProperties(
        currentState.properties,
        event.sortBy,
        event.ascending,
      );

      emit(
        currentState.copyWith(
          properties: sortedProperties,
          sortBy: event.sortBy,
          sortAscending: event.ascending,
        ),
      );
    }
  }

  List<Property> _sortProperties(
    List<Property> properties,
    String sortBy,
    bool ascending,
  ) {
    final sortedList = List<Property>.from(properties);

    sortedList.sort((a, b) {
      int comparison = 0;

      switch (sortBy) {
        case 'price':
          comparison = a.price.compareTo(b.price);
          break;
        case 'area':
          comparison = a.area.compareTo(b.area);
          break;
        case 'created_at':
          comparison = a.createdAt.compareTo(b.createdAt);
          break;
        case 'views':
          comparison = (a.views ?? 0).compareTo(b.views ?? 0);
          break;
        default:
          comparison = a.title.compareTo(b.title);
      }

      return ascending ? comparison : -comparison;
    });

    return sortedList;
  }

  Future<void> _onCacheProperties(
    CacheProperties event,
    Emitter<PropertiesState> emit,
  ) async {
    try {
      if (state is PropertiesLoaded) {
        final currentState = state as PropertiesLoaded;
        await _cacheProperties(currentState.properties);

        emit(
          PropertiesCached(
            cachedProperties: currentState.properties,
            cacheTime: DateTime.now(),
          ),
        );
      }
    } catch (e) {
      // Handle caching error silently
    }
  }

  Future<void> _onLoadCachedProperties(
    LoadCachedProperties event,
    Emitter<PropertiesState> emit,
  ) async {
    try {
      final cachedProperties = await _loadCachedProperties();
      if (cachedProperties.isNotEmpty) {
        emit(
          PropertiesLoaded(
            properties: cachedProperties,
            hasReachedMax: true,
            currentPage: 1,
            totalCount: cachedProperties.length,
            favoritePropertyIds: _favoritePropertyIds,
          ),
        );
      }
    } catch (e) {
      emit(PropertiesError(message: e.toString()));
    }
  }

  Future<void> _cacheProperties(List<Property> properties) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final propertiesJson = properties.map((p) => p.toJson()).toList();
      await prefs.setString(_cachedPropertiesKey, json.encode(propertiesJson));
      await prefs.setInt(_cacheTimeKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      // Handle caching error silently
    }
  }

  Future<List<Property>> _loadCachedProperties() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_cachedPropertiesKey);
      final cacheTime = prefs.getInt(_cacheTimeKey);

      if (cachedData != null && cacheTime != null) {
        final cacheDateTime = DateTime.fromMillisecondsSinceEpoch(cacheTime);
        final isExpired =
            DateTime.now().difference(cacheDateTime) > _cacheExpiry;

        if (!isExpired) {
          final List<dynamic> propertiesJson = json.decode(cachedData);
          return propertiesJson.map((json) => Property.fromJson(json)).toList();
        }
      }
    } catch (e) {
      // Handle error silently
    }

    return [];
  }
}
