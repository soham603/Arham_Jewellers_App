class PaginationMeta {
  final int total;
  final bool paginated;

  PaginationMeta({
    required this.total,
    required this.paginated,
  });

  factory PaginationMeta.fromJson(Map<String, dynamic> json) {
    return PaginationMeta(
      total: json['total'] ?? 0,
      paginated: json['paginated'] ?? false,
    );
  }
}