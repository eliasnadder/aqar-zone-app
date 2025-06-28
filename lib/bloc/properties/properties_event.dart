import 'package:equatable/equatable.dart';

abstract class PropertiesEvent extends Equatable {
  const PropertiesEvent();

  @override
  List<Object?> get props => [];
}

class LoadProperties extends PropertiesEvent {
  final int page;
  final int limit;
  final String? searchQuery;
  final Map<String, dynamic>? filters;

  const LoadProperties({
    this.page = 1,
    this.limit = 20,
    this.searchQuery,
    this.filters,
  });

  @override
  List<Object?> get props => [page, limit, searchQuery, filters];
}

class RefreshProperties extends PropertiesEvent {
  final String? searchQuery;
  final Map<String, dynamic>? filters;

  const RefreshProperties({
    this.searchQuery,
    this.filters,
  });

  @override
  List<Object?> get props => [searchQuery, filters];
}

class SearchProperties extends PropertiesEvent {
  final String query;
  final Map<String, dynamic>? filters;

  const SearchProperties({
    required this.query,
    this.filters,
  });

  @override
  List<Object?> get props => [query, filters];
}

class FilterProperties extends PropertiesEvent {
  final Map<String, dynamic> filters;

  const FilterProperties({required this.filters});

  @override
  List<Object?> get props => [filters];
}

class ClearFilters extends PropertiesEvent {
  const ClearFilters();
}

class LoadMoreProperties extends PropertiesEvent {
  const LoadMoreProperties();
}

class ToggleFavoriteProperty extends PropertiesEvent {
  final String propertyId;

  const ToggleFavoriteProperty({required this.propertyId});

  @override
  List<Object?> get props => [propertyId];
}

class LoadFavoriteProperties extends PropertiesEvent {
  const LoadFavoriteProperties();
}

class SearchByAdNumber extends PropertiesEvent {
  final String adNumber;

  const SearchByAdNumber({required this.adNumber});

  @override
  List<Object?> get props => [adNumber];
}

class UpdatePropertyViews extends PropertiesEvent {
  final String propertyId;

  const UpdatePropertyViews({required this.propertyId});

  @override
  List<Object?> get props => [propertyId];
}

class LoadPropertyDetails extends PropertiesEvent {
  final String propertyId;

  const LoadPropertyDetails({required this.propertyId});

  @override
  List<Object?> get props => [propertyId];
}

class ClearPropertyDetails extends PropertiesEvent {
  const ClearPropertyDetails();
}

class LoadSimilarProperties extends PropertiesEvent {
  final String propertyId;
  final int limit;

  const LoadSimilarProperties({
    required this.propertyId,
    this.limit = 5,
  });

  @override
  List<Object?> get props => [propertyId, limit];
}

class UpdatePropertyFilters extends PropertiesEvent {
  final String? propertyType;
  final String? adType;
  final double? minPrice;
  final double? maxPrice;
  final String? location;
  final int? minRooms;
  final int? maxRooms;
  final int? minBathrooms;
  final int? maxBathrooms;
  final double? minArea;
  final double? maxArea;
  final String? furnishing;
  final String? sellerType;

  const UpdatePropertyFilters({
    this.propertyType,
    this.adType,
    this.minPrice,
    this.maxPrice,
    this.location,
    this.minRooms,
    this.maxRooms,
    this.minBathrooms,
    this.maxBathrooms,
    this.minArea,
    this.maxArea,
    this.furnishing,
    this.sellerType,
  });

  @override
  List<Object?> get props => [
    propertyType,
    adType,
    minPrice,
    maxPrice,
    location,
    minRooms,
    maxRooms,
    minBathrooms,
    maxBathrooms,
    minArea,
    maxArea,
    furnishing,
    sellerType,
  ];
}

class SortProperties extends PropertiesEvent {
  final String sortBy;
  final bool ascending;

  const SortProperties({
    required this.sortBy,
    this.ascending = true,
  });

  @override
  List<Object?> get props => [sortBy, ascending];
}

class CacheProperties extends PropertiesEvent {
  const CacheProperties();
}

class LoadCachedProperties extends PropertiesEvent {
  const LoadCachedProperties();
}
