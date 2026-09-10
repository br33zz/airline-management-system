import 'package:flutter/material.dart';

class TableColumnSpec<T> {
  final String label, sortField;
  final String Function(T) value;
  const TableColumnSpec(this.label, this.sortField, this.value);
}

class EntityTable<T> extends StatelessWidget {
  final List<T> items;
  final List<TableColumnSpec<T>> columns;
  final int Function(T) idOf;
  final bool Function(T) isDeleted;
  final String sortField;
  final bool sortAscending;
  final ValueChanged<String> onSort;
  final void Function(T) onOpen, onEdit, onDelete, onRestore;

  const EntityTable({
    super.key,
    required this.items,
    required this.columns,
    required this.idOf,
    required this.isDeleted,
    required this.sortField,
    required this.sortAscending,
    required this.onSort,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
    required this.onRestore,
  });

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (_, box) {
      if (box.maxWidth < 760) {
        return ListView.separated(
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, index) {
            final item = items[index];
            return Card(
              child: ListTile(
                onTap: () => onOpen(item),
                leading: CircleAvatar(child: Text('${idOf(item)}')),
                title: Text(columns.first.value(item)),
                subtitle: Text(
                  columns
                      .skip(1)
                      .map((column) => '${column.label}: ${column.value(item)}')
                      .join('\n'),
                ),
                trailing: Wrap(
                  children: [
                    if (!isDeleted(item))
                      IconButton(
                        tooltip: 'Редактировать',
                        onPressed: () => onEdit(item),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                    IconButton(
                      tooltip: isDeleted(item) ? 'Восстановить' : 'Удалить',
                      onPressed: () =>
                          isDeleted(item) ? onRestore(item) : onDelete(item),
                      icon: Icon(
                        isDeleted(item) ? Icons.restore : Icons.delete_outline,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }
      final sortIndex = columns.indexWhere(
        (column) => column.sortField == sortField,
      );
      return SingleChildScrollView(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            sortAscending: sortAscending,
            sortColumnIndex: sortIndex < 0 ? null : sortIndex,
            columns: [
              ...columns.map(
                (column) => DataColumn(
                  label: Text(column.label),
                  onSort: (_, __) => onSort(column.sortField),
                ),
              ),
              const DataColumn(label: Text('Действия')),
            ],
            rows: items
                .map(
                  (item) => DataRow(
                    color: isDeleted(item)
                        ? WidgetStatePropertyAll(
                            Colors.red.withValues(alpha: 0.06),
                          )
                        : null,
                    cells: [
                      ...columns.map(
                        (column) => DataCell(
                          Text(column.value(item)),
                          onTap: () => onOpen(item),
                        ),
                      ),
                      DataCell(
                        Wrap(
                          children: [
                            IconButton(
                              tooltip: 'Открыть',
                              onPressed: () => onOpen(item),
                              icon: const Icon(Icons.visibility_outlined),
                            ),
                            if (!isDeleted(item))
                              IconButton(
                                tooltip: 'Редактировать',
                                onPressed: () => onEdit(item),
                                icon: const Icon(Icons.edit_outlined),
                              ),
                            IconButton(
                              tooltip: isDeleted(item)
                                  ? 'Восстановить'
                                  : 'Удалить',
                              onPressed: () => isDeleted(item)
                                  ? onRestore(item)
                                  : onDelete(item),
                              icon: Icon(
                                isDeleted(item)
                                    ? Icons.restore
                                    : Icons.delete_outline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
                .toList(),
          ),
        ),
      );
    },
  );
}
