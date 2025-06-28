import 'package:equatable/equatable.dart';
import '../../models/property_model.dart';

abstract class PropertiesState extends Equatable {
  const PropertiesState();

  @override
  List<Object?> get props => [];
}

class PropertiesInitial extends PropertiesState {
  const PropertiesInitial();
}

class PropertiesLoading extends PropertiesState {
  const PropertiesLoading();
}

class PropertiesLoadingMore extends PropertiesState {
  final List<Property> currentProperties;
  final bool hasReachedMax;
  final int currentPage;
  final String? searchQuery;
  final Map<String, dynamic>? filters;

  const PropertiesLoadingMore({
    required this.currentProperties,
    required this.hasReachedMax,
    required this.currentPage,
    this.searchQuery,
    this.filters,
  });

  @override
  List<Object?> get props => [
    currentProperties,
    hasReachedMax,
    currentPage,
    searchQuery,
    filters,
  ];
}

class PropertiesLoaded extends PropertiesState {
  final List<Property> properties;
  final bool hasReachedMax;
  final int currentPage;
  final int totalCount;
  final String? searchQuery;
  final Map<String, dynamic>? filters;
  final String? sortBy;
  final bool sortAscending;
  final List<String> favoritePropertyIds;

  const PropertiesLoaded({
    required this.properties,
    required this.hasReachedMax,
    required this.currentPage,
    required this.totalCount,
    this.searchQuery,
    this.filters,
    this.sortBy,
    this.sortAscending = true,
    this.favoritePropertyIds = const [],
  });

  PropertiesLoaded copyWith({
    List<Property>? properties,
    bool? hasReachedMax,
    int? currentPage,
    int? totalCount,
    String? searchQuery,
    Map<String, dynamic>? filters,
    String? sortBy,
    bool? sortAscending,
    List<String>? favoritePropertyIds,
  }) {
    return PropertiesLoaded(
      properties: properties ?? this.properties,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      currentPage: currentPage ?? this.currentPage,
      totalCount: totalCount ?? this.totalCount,
      searchQuery: searchQuery ?? this.searchQuery,
      filters: filters ?? this.filters,
      sortBy: sortBy ?? this.sortBy,
      sortAscending: sortAscending ?? this.sortAscending,
      favoritePropertyIds: favoritePropertyIds ?? this.favoritePropertyIds,
    );
  }

  @override
  List<Object?> get props => [
    properties,
    hasReachedMax,
    currentPage,
    totalCount,
    searchQuery,
    filters,
    sortBy,
    sortAscending,
    favoritePropertyIds,
  ];
}

class PropertiesError extends PropertiesState {
  final String message;
  final String? errorCode;
  final List<Property>? cachedProperties;

  const PropertiesError({
    required this.message,
    this.errorCode,
    this.cachedProperties,
  });

  @override
  List<Object?> get props => [message, errorCode, cachedProperties];
}

class PropertyDetailsLoading extends PropertiesState {
  const PropertyDetailsLoading();
}

class PropertyDetailsLoaded extends PropertiesState {
  final Property property;
  final List<Property> similarProperties;

  const PropertyDetailsLoaded({
    required this.property,
    this.similarProperties = const [],
  });

  PropertyDetailsLoaded copyWith({
    Property? property,
    List<Property>? similarProperties,
  }) {
    return PropertyDetailsLoaded(
      property: property ?? this.property,
      similarProperties: similarProperties ?? this.similarProperties,
    );
  }

  @override
  List<Object?> get props => [property, similarProperties];
}

class PropertyDetailsError extends PropertiesState {
  final String message;
  final String propertyId;

  const PropertyDetailsError({required this.message, required this.propertyId});

  @override
  List<Object?> get props => [message, propertyId];
}

class FavoritePropertiesLoaded extends PropertiesState {
  final List<Property> favoriteProperties;
  final List<String> favoritePropertyIds;

  const FavoritePropertiesLoaded({
    required this.favoriteProperties,
    required this.favoritePropertyIds,
  });

  @override
  List<Object?> get props => [favoriteProperties, favoritePropertyIds];
}

class PropertyFavoriteToggled extends PropertiesState {
  final String propertyId;
  final bool isFavorite;

  const PropertyFavoriteToggled({
    required this.propertyId,
    required this.isFavorite,
  });

  @override
  List<Object?> get props => [propertyId, isFavorite];
}

class PropertiesSearching extends PropertiesState {
  final String query;

  const PropertiesSearching({required this.query});

  @override
  List<Object?> get props => [query];
}

class PropertiesFiltering extends PropertiesState {
  final Map<String, dynamic> filters;

  const PropertiesFiltering({required this.filters});

  @override
  List<Object?> get props => [filters];
}

class PropertiesSorting extends PropertiesState {
  final String sortBy;
  final bool ascending;

  const PropertiesSorting({required this.sortBy, required this.ascending});

  @override
  List<Object?> get props => [sortBy, ascending];
}

class PropertiesCached extends PropertiesState {
  final List<Property> cachedProperties;
  final DateTime cacheTime;

  const PropertiesCached({
    required this.cachedProperties,
    required this.cacheTime,
  });

  @override
  List<Object?> get props => [cachedProperties, cacheTime];
}

class PropertyViewsUpdated extends PropertiesState {
  final String propertyId;
  final int newViewCount;

  const PropertyViewsUpdated({
    required this.propertyId,
    required this.newViewCount,
  });

  @override
  List<Object?> get props => [propertyId, newViewCount];
}

class PropertiesRefreshing extends PropertiesState {
  final List<Property> currentProperties;

  const PropertiesRefreshing({required this.currentProperties});

  @override
  List<Object?> get props => [currentProperties];
}
