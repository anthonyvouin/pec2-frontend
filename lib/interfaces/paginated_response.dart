import 'package:firstflutterapp/interfaces/pagination.dart';

class PaginatedResponse<T> {
  final Pagination pagination;
  final List<T> data;

  PaginatedResponse({
    required this.pagination,
    required this.data,
  });

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    return PaginatedResponse<T>(
      pagination: Pagination.fromJson(json['pagination']),
      data: (json['posts'] as List<dynamic>).map((item) => fromJsonT(item)).toList(),
    );
  }

  Map<String, dynamic> toJson(Map<String, dynamic> Function(T) toJsonT) {
    return {
      'pagination': pagination.toJson(),
      'posts': data.map((item) => toJsonT(item)).toList(),
    };
  }
}
