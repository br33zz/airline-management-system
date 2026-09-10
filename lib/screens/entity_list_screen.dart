import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/airline_models.dart';
import '../models/list_query.dart';
import '../models/page_result.dart';
import '../repositories/airline_repository.dart';
import '../widgets/airline_scaffold.dart';
import '../widgets/entity_table.dart';

class EntityListScreen extends StatefulWidget {
  final EntityKind kind;
  final Uri uri;
  const EntityListScreen({super.key, required this.kind, required this.uri});

  @override
  State<EntityListScreen> createState() => _EntityListScreenState();
}

class _EntityListScreenState extends State<EntityListScreen> {
  late final TextEditingController search;
  late ListQuery query;
  PageResult<AirlineModel>? result;
  Object? error;
  bool loading = true;
  Timer? debounce;

  @override
  void initState() {
    super.initState();
    query = _queryFromUri(widget.uri);
    search = TextEditingController(text: query.search);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _load();
      final repository = context.read<AirlineRepository>();
      if (repository.startupMessage != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(repository.startupMessage!)));
        repository.startupMessage = null;
      }
    });
  }

  @override
  void didUpdateWidget(covariant EntityListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.kind != widget.kind || oldWidget.uri != widget.uri) {
      query = _queryFromUri(widget.uri);
      search.text = query.search;
      _load();
    }
  }

  ListQuery _queryFromUri(Uri uri) {
    final values = uri.queryParameters;
    final sort = (values['sort'] ?? 'name,asc').split(',');
    return ListQuery(
      search: values['search'] ?? '',
      filter: values['filter'] ?? '',
      sortField: sort.first,
      sortAscending: sort.length < 2 || sort[1] != 'desc',
      includeDeleted: values['deleted'] == 'true',
      page: int.tryParse(values['page'] ?? '') ?? 1,
      size: int.tryParse(values['size'] ?? '') ?? 5,
    );
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final value = await context.read<AirlineRepository>().find(
        widget.kind,
        query,
      );
      if (mounted) {
        setState(() {
          result = value;
          loading = false;
        });
      }
    } catch (exception) {
      if (mounted) {
        setState(() {
          error = exception;
          loading = false;
        });
      }
    }
  }

  void _apply(ListQuery next) {
    query = next;
    context.go(
      Uri(
        path: '/${widget.kind.name}',
        queryParameters: {
          if (query.search.isNotEmpty) 'search': query.search,
          if (query.filter.isNotEmpty) 'filter': query.filter,
          'sort': '${query.sortField},${query.sortAscending ? 'asc' : 'desc'}',
          'page': '${query.page}',
          'size': '${query.size}',
          if (query.includeDeleted) 'deleted': 'true',
        },
      ).toString(),
    );
    _load();
  }

  List<String> _filters(AirlineRepository repository) => switch (widget.kind) {
    EntityKind.flights => ['По расписанию', 'Посадка', 'Задержан'],
    EntityKind.aircraft =>
      repository.aircraft.map((e) => e.type).toSet().toList(),
    EntityKind.pilots =>
      repository.pilots.map((e) => e.qualification).toSet().toList(),
    EntityKind.services => ['Платно', 'Бесплатно'],
    EntityKind.passengers =>
      repository.passengers.map((e) => e.country).toSet().toList(),
  };

  List<TableColumnSpec<AirlineModel>> _columns(
    AirlineRepository repository,
  ) => switch (widget.kind) {
    EntityKind.flights => [
      TableColumnSpec('Рейс', 'name', (item) => (item as Flight).number),
      TableColumnSpec(
        'Направление',
        'destination',
        (item) => (item as Flight).destination,
      ),
      TableColumnSpec(
        'Вылет',
        'departure',
        (item) => _dateTime((item as Flight).departure),
      ),
      TableColumnSpec(
        'Самолёт',
        'aircraft',
        (item) => repository.aircraftName((item as Flight).aircraftId),
      ),
      TableColumnSpec('Мест', 'seats', (item) => '${(item as Flight).seats}'),
    ],
    EntityKind.aircraft => [
      TableColumnSpec(
        'Регистрация',
        'name',
        (item) => (item as Aircraft).registrationNumber,
      ),
      TableColumnSpec('Модель', 'model', (item) => (item as Aircraft).model),
      TableColumnSpec('Тип', 'type', (item) => (item as Aircraft).type),
      TableColumnSpec(
        'Вместимость',
        'capacity',
        (item) => '${(item as Aircraft).capacity}',
      ),
    ],
    EntityKind.pilots => [
      TableColumnSpec('ФИО', 'name', (item) => (item as Pilot).fullName),
      TableColumnSpec(
        'Лицензия',
        'license',
        (item) => (item as Pilot).licenseNumber,
      ),
      TableColumnSpec(
        'Квалификация',
        'qualification',
        (item) => (item as Pilot).qualification,
      ),
      TableColumnSpec(
        'Стаж',
        'experience',
        (item) => '${(item as Pilot).experienceYears} лет',
      ),
    ],
    EntityKind.services => [
      TableColumnSpec(
        'Название',
        'name',
        (item) => (item as AirlineService).name,
      ),
      TableColumnSpec(
        'Описание',
        'description',
        (item) => (item as AirlineService).description,
      ),
      TableColumnSpec(
        'Стоимость',
        'price',
        (item) => '${(item as AirlineService).price.toStringAsFixed(0)} ₽',
      ),
    ],
    EntityKind.passengers => [
      TableColumnSpec('ФИО', 'name', (item) => (item as Passenger).fullName),
      TableColumnSpec(
        'Паспорт',
        'passport',
        (item) => (item as Passenger).passport,
      ),
      TableColumnSpec(
        'Страна',
        'country',
        (item) => (item as Passenger).country,
      ),
      TableColumnSpec('Почта', 'email', (item) => (item as Passenger).email),
      TableColumnSpec(
        'Билет',
        'ticket',
        (item) => (item as Passenger).ticket.number,
      ),
    ],
  };

  String _dateTime(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}.${value.month.toString().padLeft(2, '0')}.${value.year} '
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

  Future<void> _delete(AirlineModel item) async {
    final hard = item.deletedAt != null;
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(hard ? 'Удалить навсегда?' : 'Удалить запись?'),
            content: Text(
              hard
                  ? 'После физического удаления восстановление невозможно.'
                  : 'Запись будет скрыта, но её можно восстановить.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Отмена'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Удалить'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !mounted) return;
    try {
      await context.read<AirlineRepository>().delete(
        widget.kind,
        item.id,
        hard: hard,
      );
      await _load();
    } on LinkedRecordsException catch (exception) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Удаление невозможно: связанных рейсов — ${exception.count}',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final repository = context.watch<AirlineRepository>();
    final pageResult = result;
    return AirlineScaffold(
      title: 'Авиакомпания • ${widget.kind.title}',
      selected: widget.kind,
      actions: [
        IconButton(
          tooltip: 'Добавить',
          onPressed: () => context.go('/${widget.kind.name}/new'),
          icon: const Icon(Icons.add),
        ),
      ],
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1250),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SizedBox(
                      width: 300,
                      child: TextField(
                        controller: search,
                        onChanged: (value) {
                          debounce?.cancel();
                          debounce = Timer(
                            const Duration(milliseconds: 350),
                            () =>
                                _apply(query.copyWith(search: value, page: 1)),
                          );
                        },
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.search),
                          labelText: 'Поиск',
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 220,
                      child: DropdownButtonFormField<String>(
                        initialValue: query.filter,
                        decoration: const InputDecoration(labelText: 'Фильтр'),
                        items: ['', ..._filters(repository)]
                            .map(
                              (value) => DropdownMenuItem(
                                value: value,
                                child: Text(value.isEmpty ? 'Все' : value),
                              ),
                            )
                            .toList(),
                        onChanged: (value) => _apply(
                          query.copyWith(filter: value ?? '', page: 1),
                        ),
                      ),
                    ),
                    FilterChip(
                      label: const Text('Показать удалённые'),
                      selected: query.includeDeleted,
                      onSelected: (value) => _apply(
                        query.copyWith(includeDeleted: value, page: 1),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: loading
                      ? const Center(child: CircularProgressIndicator())
                      : error != null
                      ? Center(
                          child: FilledButton.icon(
                            onPressed: _load,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Повторить загрузку'),
                          ),
                        )
                      : pageResult == null || pageResult.items.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.search_off, size: 64),
                              Text('Ничего не найдено'),
                            ],
                          ),
                        )
                      : EntityTable<AirlineModel>(
                          items: pageResult.items,
                          columns: _columns(repository),
                          idOf: (item) => item.id,
                          isDeleted: (item) => item.deletedAt != null,
                          sortField: query.sortField,
                          sortAscending: query.sortAscending,
                          onSort: (field) => _apply(
                            query.copyWith(
                              sortField: field,
                              sortAscending: query.sortField == field
                                  ? !query.sortAscending
                                  : true,
                              page: 1,
                            ),
                          ),
                          onOpen: (item) =>
                              context.go('/${widget.kind.name}/${item.id}'),
                          onEdit: (item) => context.go(
                            '/${widget.kind.name}/${item.id}/edit',
                          ),
                          onDelete: _delete,
                          onRestore: (item) async {
                            await repository.restore(widget.kind, item.id);
                            await _load();
                          },
                        ),
                ),
                if (pageResult != null)
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      IconButton(
                        tooltip: 'Предыдущая',
                        onPressed: pageResult.hasPrevious
                            ? () => _apply(
                                query.copyWith(page: pageResult.page - 1),
                              )
                            : null,
                        icon: const Icon(Icons.chevron_left),
                      ),
                      Text(
                        'Страница ${pageResult.page} из ${pageResult.totalPages} · Всего: ${pageResult.total}',
                      ),
                      IconButton(
                        tooltip: 'Следующая',
                        onPressed: pageResult.hasNext
                            ? () => _apply(
                                query.copyWith(page: pageResult.page + 1),
                              )
                            : null,
                        icon: const Icon(Icons.chevron_right),
                      ),
                      const SizedBox(width: 12),
                      DropdownButton<int>(
                        value: query.size,
                        items: [5, 10, 25]
                            .map(
                              (value) => DropdownMenuItem(
                                value: value,
                                child: Text('$value'),
                              ),
                            )
                            .toList(),
                        onChanged: (value) =>
                            _apply(query.copyWith(size: value, page: 1)),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    debounce?.cancel();
    search.dispose();
    super.dispose();
  }
}
