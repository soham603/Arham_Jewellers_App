class PaginatedResult<T> {
  final List<T> items;
  final int total;
  final int totalPages;
  final int currentPage;

  PaginatedResult({
    required this.items,
    required this.total,
    required this.totalPages,
    required this.currentPage,
  });
}
