class PageResult<T> {
  final List<T> items;
  final int page, size, total;
  const PageResult({
    required this.items,
    required this.page,
    required this.size,
    required this.total,
  });
  int get totalPages => total == 0 ? 1 : (total / size).ceil();
  bool get hasPrevious => page > 1;
  bool get hasNext => page < totalPages;
}
