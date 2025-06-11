class Pagination {
  final int limit;
  final int page;
  final int total;
  final int totalPages;

  Pagination({
    required this.limit,
    required this.page,
    required this.total,
    required this.totalPages,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      limit: json['limit'] ?? 10,
      page: json['page'] ?? 1,
      total: json['total'] ?? 0,
      totalPages: json['total_pages'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'limit': limit,
      'page': page,
      'total': total,
      'total_pages': totalPages,
    };
  }
}
