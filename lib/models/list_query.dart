class ListQuery {
  final String search, filter, sortField;
  final bool sortAscending, includeDeleted;
  final int page, size;
  const ListQuery({
    this.search = '',
    this.filter = '',
    this.sortField = 'id',
    this.sortAscending = true,
    this.includeDeleted = false,
    this.page = 1,
    this.size = 10,
  });
  ListQuery copyWith({
    String? search,
    String? filter,
    String? sortField,
    bool? sortAscending,
    bool? includeDeleted,
    int? page,
    int? size,
  }) => ListQuery(
    search: search ?? this.search,
    filter: filter ?? this.filter,
    sortField: sortField ?? this.sortField,
    sortAscending: sortAscending ?? this.sortAscending,
    includeDeleted: includeDeleted ?? this.includeDeleted,
    page: page ?? 1,
    size: size ?? this.size,
  );
}
