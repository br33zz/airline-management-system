import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/airline_models.dart';
import '../repositories/airline_repository.dart';
import '../widgets/airline_scaffold.dart';

class EntityDetailScreen extends StatelessWidget {
  final EntityKind kind;
  final int id;
  const EntityDetailScreen({super.key, required this.kind, required this.id});

  String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}.${value.month.toString().padLeft(2, '0')}.${value.year}';
  String _dateTime(DateTime value) =>
      '${_date(value)} ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

  List<(String, String)> _fields(
    AirlineModel item,
    AirlineRepository repository,
  ) => switch (item) {
    Flight value => [
      ('Номер рейса', value.number),
      ('Направление', value.destination),
      ('Вылет', _dateTime(value.departure)),
      ('Статус', value.status),
      ('Продано мест', '${value.seats}'),
      ('Самолёт', repository.aircraftName(value.aircraftId)),
      ('Пилоты', repository.pilotNames(value.pilotIds)),
      ('Услуги', repository.serviceNames(value.serviceIds)),
    ],
    Aircraft value => [
      ('Регистрация', value.registrationNumber),
      ('Модель', value.model),
      ('Тип', value.type),
      ('Вместимость', '${value.capacity}'),
      (
        'Связано активных рейсов',
        '${repository.flights.where((flight) => flight.aircraftId == value.id && flight.deletedAt == null).length}',
      ),
    ],
    Pilot value => [
      ('ФИО', value.fullName),
      ('Лицензия', value.licenseNumber),
      ('Квалификация', value.qualification),
      ('Стаж', '${value.experienceYears} лет'),
      (
        'Связано рейсов',
        '${repository.flights.where((flight) => flight.pilotIds.contains(value.id)).length}',
      ),
    ],
    AirlineService value => [
      ('Название', value.name),
      ('Описание', value.description),
      ('Стоимость', '${value.price.toStringAsFixed(2)} ₽'),
      (
        'Связано рейсов',
        '${repository.flights.where((flight) => flight.serviceIds.contains(value.id)).length}',
      ),
    ],
    Passenger value => [
      ('ФИО', value.fullName),
      ('Паспорт', value.passport),
      ('Страна', value.country),
      ('Почта', value.email),
      ('Номер билета', value.ticket.number),
      ('Рейс', repository.flightName(value.ticket.flightId)),
      ('Место', value.ticket.seat),
      ('Класс', value.ticket.fareClass),
      ('Дата оформления', _date(value.ticket.issuedAt)),
    ],
    _ => [('ID', '${item.id}')],
  };

  @override
  Widget build(BuildContext context) {
    final repository = context.watch<AirlineRepository>();
    final item = repository.byId(kind, id);
    return AirlineScaffold(
      title: 'Карточка • ${kind.title}',
      selected: kind,
      actions: [
        if (item != null && item.deletedAt == null)
          IconButton(
            tooltip: 'Редактировать',
            onPressed: () => context.go('/${kind.name}/$id/edit'),
            icon: const Icon(Icons.edit),
          ),
      ],
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 780),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: item == null
                ? const Center(child: Text('Запись не найдена'))
                : Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Icon(
                                item.deletedAt == null
                                    ? Icons.verified_outlined
                                    : Icons.delete_outline,
                                color: item.deletedAt == null
                                    ? Colors.green
                                    : Colors.orange,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                kind.title,
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineSmall,
                              ),
                            ],
                          ),
                          const Divider(height: 30),
                          ..._fields(item, repository).map(
                            (field) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: 190,
                                    child: Text(
                                      field.$1,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Expanded(child: Text(field.$2)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton(
                                onPressed: () => context.go('/${kind.name}'),
                                child: const Text('К списку'),
                              ),
                              if (item.deletedAt == null) ...[
                                const SizedBox(width: 12),
                                FilledButton.icon(
                                  onPressed: () =>
                                      context.go('/${kind.name}/$id/edit'),
                                  icon: const Icon(Icons.edit),
                                  label: const Text('Редактировать'),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
