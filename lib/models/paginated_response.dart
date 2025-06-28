import 'package:flutter/foundation.dart';

class PaginationLink {
  final String? url;
  final String label;
  final bool active;

  const PaginationLink({this.url, required this.label, required this.active});

  factory PaginationLink.fromJson(Map<String, dynamic> json) {
    return PaginationLink(
      url: json['url']?.toString(),
      label: json['label']?.toString() ?? '',
      active: json['active'] is bool ? json['active'] : false,
    );
  }

  Map<String, dynamic> toJson() {
    return {'url': url, 'label': label, 'active': active};
  }
}

class PaginatedResponse<T> {
  final int currentPage;
  final List<T> data;
  final String? firstPageUrl;
  final int? from;
  final int lastPage;
  final String? lastPageUrl;
  final List<PaginationLink> links;
  final String? nextPageUrl;
  final String path;
  final int perPage;
  final String? prevPageUrl;
  final int? to;
  final int total;

  const PaginatedResponse({
    required this.currentPage,
    required this.data,
    this.firstPageUrl,
    this.from,
    required this.lastPage,
    this.lastPageUrl,
    required this.links,
    this.nextPageUrl,
    required this.path,
    required this.perPage,
    this.prevPageUrl,
    this.to,
    required this.total,
  });

  // Getter for BLoC compatibility
  int get totalCount => total;

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    try {
      // Parse data array
      final List<dynamic> dataList = json['data'] ?? [];
      final List<T> parsedData = [];

      for (int i = 0; i < dataList.length; i++) {
        try {
          final item = fromJsonT(dataList[i]);
          parsedData.add(item);
        } catch (e) {
          debugPrint("Error parsing item $i: $e");
          // Continue with other items instead of failing completely
        }
      }

      // Parse links array
      final List<dynamic> linksList = json['links'] ?? [];
      final List<PaginationLink> parsedLinks =
          linksList.map((link) => PaginationLink.fromJson(link)).toList();

      return PaginatedResponse<T>(
        currentPage:
            json['current_page'] is int
                ? json['current_page']
                : int.tryParse(json['current_page']?.toString() ?? '') ?? 1,
        data: parsedData,
        firstPageUrl: json['first_page_url']?.toString(),
        from:
            json['from'] is int
                ? json['from']
                : int.tryParse(json['from']?.toString() ?? ''),
        lastPage:
            json['last_page'] is int
                ? json['last_page']
                : int.tryParse(json['last_page']?.toString() ?? '') ?? 1,
        lastPageUrl: json['last_page_url']?.toString(),
        links: parsedLinks,
        nextPageUrl: json['next_page_url']?.toString(),
        path: json['path']?.toString() ?? '',
        perPage:
            json['per_page'] is int
                ? json['per_page']
                : int.tryParse(json['per_page']?.toString() ?? '') ?? 20,
        prevPageUrl: json['prev_page_url']?.toString(),
        to:
            json['to'] is int
                ? json['to']
                : int.tryParse(json['to']?.toString() ?? ''),
        total:
            json['total'] is int
                ? json['total']
                : int.tryParse(json['total']?.toString() ?? '') ?? 0,
      );
    } catch (e) {
      debugPrint("Error parsing paginated response: $e");
      rethrow;
    }
  }

  Map<String, dynamic> toJson(Map<String, dynamic> Function(T) toJsonT) {
    return {
      'current_page': currentPage,
      'data': data.map((item) => toJsonT(item)).toList(),
      'first_page_url': firstPageUrl,
      'from': from,
      'last_page': lastPage,
      'last_page_url': lastPageUrl,
      'links': links.map((link) => link.toJson()).toList(),
      'next_page_url': nextPageUrl,
      'path': path,
      'per_page': perPage,
      'prev_page_url': prevPageUrl,
      'to': to,
      'total': total,
    };
  }

  // Convenience getters
  bool get hasNextPage => nextPageUrl != null;
  bool get hasPrevPage => prevPageUrl != null;
  bool get isFirstPage => currentPage == 1;
  bool get isLastPage => currentPage == lastPage;

  // Calculate page range info
  String get pageInfo => 'Page $currentPage of $lastPage';
  String get itemsInfo {
    if (from != null && to != null) {
      return 'Showing $from-$to of $total items';
    }
    return 'Total: $total items';
  }

  // Create a copy with new data (useful for pagination)
  PaginatedResponse<T> copyWith({
    int? currentPage,
    List<T>? data,
    String? firstPageUrl,
    int? from,
    int? lastPage,
    String? lastPageUrl,
    List<PaginationLink>? links,
    String? nextPageUrl,
    String? path,
    int? perPage,
    String? prevPageUrl,
    int? to,
    int? total,
  }) {
    return PaginatedResponse<T>(
      currentPage: currentPage ?? this.currentPage,
      data: data ?? this.data,
      firstPageUrl: firstPageUrl ?? this.firstPageUrl,
      from: from ?? this.from,
      lastPage: lastPage ?? this.lastPage,
      lastPageUrl: lastPageUrl ?? this.lastPageUrl,
      links: links ?? this.links,
      nextPageUrl: nextPageUrl ?? this.nextPageUrl,
      path: path ?? this.path,
      perPage: perPage ?? this.perPage,
      prevPageUrl: prevPageUrl ?? this.prevPageUrl,
      to: to ?? this.to,
      total: total ?? this.total,
    );
  }
}
