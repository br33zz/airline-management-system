import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/airline_models.dart';
import '../models/list_query.dart';
import '../models/page_result.dart';

class DuplicateValueException implements Exception {
  final String field, message;
  const DuplicateValueException(this.field, this.message);
  @override
  String toString() => message;
}

class LinkedRecordsException implements Exception {
  final int count;
  const LinkedRecordsException(this.count);
  @override
  String toString() => 'Самолёт используется активными рейсами: $count';
}

class AirlineRepository extends ChangeNotifier {
  static const storageKey = 'airline_v2';
  static const schemaVersion = 2;
  final SharedPreferences prefs;
  List<Flight> flights = [];
  List<Aircraft> aircraft = [];
  List<Pilot> pilots = [];
  List<AirlineService> services = [];
  List<Passenger> passengers = [];
  String? startupMessage;

  AirlineRepository(this.prefs) {
    _restore();
  }

  void _restore() {
    final raw = prefs.getString(storageKey);
    if (raw == null) {
      _seed();
      _persist();
      return;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) throw const FormatException('Ожидался объект');
      final json = Map<String, dynamic>.from(decoded);
      if (jsonInt(json['schemaVersion']) != schemaVersion) {
        throw const FormatException('Версия данных не поддерживается');
      }
      flights = _list(json['flights'], Flight.fromJson);
      aircraft = _list(json['aircraft'], Aircraft.fromJson);
      pilots = _list(json['pilots'], Pilot.fromJson);
      services = _list(json['services'], AirlineService.fromJson);
      passengers = _list(json['passengers'], Passenger.fromJson);
      if (aircraft.isEmpty || pilots.isEmpty || services.isEmpty) {
        throw const FormatException('Справочники отсутствуют');
      }
    } catch (_) {
      _seed();
      startupMessage =
          'Формат локальных данных изменился. Загружен демонстрационный набор.';
      _persist();
    }
  }

  List<T> _list<T>(Object? value, T Function(Map<String, dynamic>) fromJson) =>
      value is List
      ? value
            .whereType<Map>()
            .map((item) => fromJson(Map<String, dynamic>.from(item)))
            .toList()
      : <T>[];

  void _seed() {
    aircraft = [
      const Aircraft(
        id: 1,
        registrationNumber: 'RA-73101',
        model: 'Airbus A320-200',
        type: 'A320',
        capacity: 180,
      ),
      const Aircraft(
        id: 2,
        registrationNumber: 'RA-73312',
        model: 'Boeing 737-800',
        type: 'B737',
        capacity: 189,
      ),
      const Aircraft(
        id: 3,
        registrationNumber: 'RA-89120',
        model: 'Sukhoi Superjet 100',
        type: 'SSJ100',
        capacity: 98,
      ),
      const Aircraft(
        id: 4,
        registrationNumber: 'RA-73405',
        model: 'Airbus A321neo',
        type: 'A320',
        capacity: 220,
      ),
      const Aircraft(
        id: 5,
        registrationNumber: 'RA-73630',
        model: 'Boeing 737 MAX 8',
        type: 'B737',
        capacity: 178,
      ),
      const Aircraft(
        id: 6,
        registrationNumber: 'RA-89147',
        model: 'Sukhoi Superjet New',
        type: 'SSJ100',
        capacity: 103,
      ),
    ];
    pilots = List.generate(12, (index) {
      const names = [
        'Иванов Алексей',
        'Петров Михаил',
        'Соколов Андрей',
        'Орлов Максим',
        'Волков Сергей',
        'Морозов Павел',
      ];
      const types = ['A320', 'B737', 'SSJ100'];
      return Pilot(
        id: index + 1,
        fullName: '${names[index % names.length]} ${index ~/ 6 + 1}',
        licenseNumber: 'PL-${4100 + index}',
        qualification: types[index % types.length],
        experienceYears: 4 + index,
      );
    });
    services = [
      AirlineService(
        id: 1,
        name: 'Питание',
        description: 'Горячее питание на борту',
        price: 1200,
      ),
      AirlineService(
        id: 2,
        name: 'Багаж 23 кг',
        description: 'Одно место зарегистрированного багажа',
        price: 2500,
      ),
      AirlineService(
        id: 3,
        name: 'Выбор места',
        description: 'Предварительный выбор места',
        price: 650,
      ),
      AirlineService(
        id: 4,
        name: 'Бизнес-зал',
        description: 'Доступ в зал ожидания',
        price: 3200,
      ),
      AirlineService(
        id: 5,
        name: 'Приоритетная посадка',
        description: 'Посадка вне общей очереди',
        price: 900,
      ),
      AirlineService(
        id: 6,
        name: 'Спортивный багаж',
        description: 'Перевозка спортивного инвентаря',
        price: 2800,
      ),
      AirlineService(
        id: 7,
        name: 'Домашнее животное',
        description: 'Перевозка животного в салоне',
        price: 4000,
      ),
      AirlineService(
        id: 8,
        name: 'Страхование',
        description: 'Страхование поездки',
        price: 750,
      ),
    ];
    final base = DateTime(2026, 9, 10, 6, 30);
    const destinations = [
      'Сочи',
      'Казань',
      'Санкт-Петербург',
      'Екатеринбург',
      'Минск',
      'Астана',
    ];
    const statuses = ['По расписанию', 'Посадка', 'Задержан'];
    flights = List.generate(18, (index) {
      final aircraftItem = aircraft[index % aircraft.length];
      final qualified = pilots
          .where((pilot) => pilot.qualification == aircraftItem.type)
          .toList();
      return Flight(
        id: index + 1,
        number: 'SU ${310 + index}',
        destination: destinations[index % destinations.length],
        departure: base.add(Duration(hours: index * 3)),
        status: statuses[index % statuses.length],
        seats: 70 + index * 3,
        aircraftId: aircraftItem.id,
        pilotIds: [qualified[index % qualified.length].id],
        serviceIds: [1, 2, 3 + index % 5],
      );
    });
    const names = [
      'Анна Петрова',
      'Иван Сидоров',
      'Мария Кузнецова',
      'Алексей Смирнов',
      'Ольга Волкова',
    ];
    const countries = ['Россия', 'Беларусь', 'Казахстан'];
    passengers = List.generate(15, (index) {
      final flight = flights[index % flights.length];
      return Passenger(
        id: index + 1,
        fullName: '${names[index % names.length]} ${index ~/ names.length + 1}',
        passport: '${4500 + index} ${120000 + index}',
        country: countries[index % countries.length],
        email: 'passenger${index + 1}@example.ru',
        ticket: Ticket(
          number: 'TKT-${10001 + index}',
          flightId: flight.id,
          seat: '${index % 28 + 1}${String.fromCharCode(65 + index % 6)}',
          fareClass: index % 5 == 0 ? 'Бизнес' : 'Эконом',
          issuedAt: DateTime(2026, 9, 1).add(Duration(days: index)),
        ),
      );
    });
  }

  Future<void> _persist() async {
    await prefs.setString(
      storageKey,
      jsonEncode({
        'schemaVersion': schemaVersion,
        'flights': flights.map((item) => item.toJson()).toList(),
        'aircraft': aircraft.map((item) => item.toJson()).toList(),
        'pilots': pilots.map((item) => item.toJson()).toList(),
        'services': services.map((item) => item.toJson()).toList(),
        'passengers': passengers.map((item) => item.toJson()).toList(),
      }),
    );
  }

  List<AirlineModel> all(EntityKind kind) => switch (kind) {
    EntityKind.flights => flights,
    EntityKind.aircraft => aircraft,
    EntityKind.pilots => pilots,
    EntityKind.services => services,
    EntityKind.passengers => passengers,
  };

  AirlineModel? byId(EntityKind kind, int id) {
    for (final item in all(kind)) {
      if (item.id == id) return item;
    }
    return null;
  }

  int nextId(EntityKind kind) =>
      all(kind).fold(0, (max, item) => item.id > max ? item.id : max) + 1;
  Aircraft? aircraftById(int id) =>
      aircraft.where((item) => item.id == id).firstOrNull;
  Flight? flightById(int id) =>
      flights.where((item) => item.id == id).firstOrNull;
  String aircraftName(int id) {
    final item = aircraftById(id);
    return item == null
        ? 'Не указан'
        : '${item.registrationNumber} · ${item.model}';
  }

  String pilotNames(List<int> ids) => pilots
      .where((item) => ids.contains(item.id))
      .map((item) => item.fullName)
      .join(', ');
  String serviceNames(List<int> ids) => services
      .where((item) => ids.contains(item.id))
      .map((item) => item.name)
      .join(', ');
  String flightName(int id) {
    final item = flightById(id);
    return item == null
        ? 'Рейс не найден'
        : '${item.number} · ${item.destination}';
  }

  List<Pilot> compatiblePilots(int? aircraftId) {
    final type = aircraftById(aircraftId ?? -1)?.type;
    return pilots
        .where((item) => item.deletedAt == null && item.qualification == type)
        .toList();
  }

  Future<PageResult<AirlineModel>> find(
    EntityKind kind,
    ListQuery query,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    final needle = query.search.trim().toLowerCase();
    var rows = all(kind).where((item) {
      if (!query.includeDeleted && item.deletedAt != null) {
        return false;
      }
      if (needle.isNotEmpty && !_searchText(item).contains(needle)) {
        return false;
      }
      if (query.filter.isNotEmpty && _filterValue(item) != query.filter) {
        return false;
      }
      return true;
    }).toList();
    rows.sort((a, b) {
      final result = _sortValue(
        a,
        query.sortField,
      ).compareTo(_sortValue(b, query.sortField));
      return query.sortAscending ? result : -result;
    });
    final total = rows.length;
    final pages = total == 0 ? 1 : (total / query.size).ceil();
    final page = query.page.clamp(1, pages);
    final from = (page - 1) * query.size;
    final to = (from + query.size).clamp(0, total);
    return PageResult(
      items: from >= total ? <AirlineModel>[] : rows.sublist(from, to),
      page: page,
      size: query.size,
      total: total,
    );
  }

  String _searchText(AirlineModel item) => switch (item) {
    Flight value =>
      '${value.number} ${value.destination} ${value.status}'.toLowerCase(),
    Aircraft value =>
      '${value.registrationNumber} ${value.model} ${value.type}'.toLowerCase(),
    Pilot value =>
      '${value.fullName} ${value.licenseNumber} ${value.qualification}'
          .toLowerCase(),
    AirlineService value => '${value.name} ${value.description}'.toLowerCase(),
    Passenger value =>
      '${value.fullName} ${value.passport} ${value.email} ${value.ticket.number}'
          .toLowerCase(),
    _ => '${item.id}',
  };

  String _filterValue(AirlineModel item) => switch (item) {
    Flight value => value.status,
    Aircraft value => value.type,
    Pilot value => value.qualification,
    AirlineService value => value.price == 0 ? 'Бесплатно' : 'Платно',
    Passenger value => value.country,
    _ => '',
  };

  Comparable<Object> _sortValue(AirlineModel item, String field) {
    if (field == 'id') return item.id;
    return switch (item) {
      Flight value => switch (field) {
        'destination' => value.destination.toLowerCase(),
        'departure' => value.departure,
        'seats' => value.seats,
        _ => value.number.toLowerCase(),
      },
      Aircraft value => switch (field) {
        'capacity' => value.capacity,
        'type' => value.type.toLowerCase(),
        _ => value.registrationNumber.toLowerCase(),
      },
      Pilot value => switch (field) {
        'experience' => value.experienceYears,
        'qualification' => value.qualification.toLowerCase(),
        _ => value.fullName.toLowerCase(),
      },
      AirlineService value =>
        field == 'price' ? value.price : value.name.toLowerCase(),
      Passenger value => switch (field) {
        'country' => value.country.toLowerCase(),
        'email' => value.email.toLowerCase(),
        _ => value.fullName.toLowerCase(),
      },
      _ => item.id,
    };
  }

  Future<void> save(EntityKind kind, AirlineModel item) async {
    if (item is Flight) {
      final normalized = item.number.replaceAll(' ', '').toLowerCase();
      if (flights.any(
        (value) =>
            value.id != item.id &&
            value.number.replaceAll(' ', '').toLowerCase() == normalized,
      )) {
        throw const DuplicateValueException(
          'number',
          'Рейс с таким номером уже существует',
        );
      }
      _upsert(flights, item);
    } else if (item is Aircraft) {
      _upsert(aircraft, item);
    } else if (item is Pilot) {
      _upsert(pilots, item);
    } else if (item is AirlineService) {
      _upsert(services, item);
    } else if (item is Passenger) {
      if (passengers.any(
        (value) =>
            value.id != item.id &&
            value.email.toLowerCase() == item.email.toLowerCase(),
      )) {
        throw const DuplicateValueException(
          'email',
          'Пассажир с такой почтой уже существует',
        );
      }
      _upsert(passengers, item);
    }
    await _persist();
    notifyListeners();
  }

  void _upsert<T extends AirlineModel>(List<T> rows, T item) {
    final index = rows.indexWhere((value) => value.id == item.id);
    if (index < 0) {
      rows.add(item);
    } else {
      rows[index] = item;
    }
  }

  Future<void> delete(EntityKind kind, int id, {bool hard = false}) async {
    if (kind == EntityKind.aircraft) {
      final count = flights
          .where((item) => item.aircraftId == id && item.deletedAt == null)
          .length;
      if (count > 0) throw LinkedRecordsException(count);
    }
    if (hard) {
      all(kind).removeWhere((item) => item.id == id);
      if (kind == EntityKind.pilots) {
        flights = flights
            .map(
              (flight) => flight.copyWith(
                pilotIds: flight.pilotIds
                    .where((value) => value != id)
                    .toList(),
              ),
            )
            .toList();
      }
      if (kind == EntityKind.services) {
        flights = flights
            .map(
              (flight) => flight.copyWith(
                serviceIds: flight.serviceIds
                    .where((value) => value != id)
                    .toList(),
              ),
            )
            .toList();
      }
    } else {
      final index = all(kind).indexWhere((item) => item.id == id);
      if (index >= 0) {
        _replaceDeleted(kind, index, DateTime.now());
      }
    }
    await _persist();
    notifyListeners();
  }

  Future<void> restore(EntityKind kind, int id) async {
    final index = all(kind).indexWhere((item) => item.id == id);
    if (index >= 0) _replaceDeleted(kind, index, null);
    await _persist();
    notifyListeners();
  }

  void _replaceDeleted(EntityKind kind, int index, DateTime? value) {
    switch (kind) {
      case EntityKind.flights:
        flights[index] = flights[index].copyWith(
          deletedAt: value,
          clearDeletedAt: value == null,
        );
      case EntityKind.aircraft:
        aircraft[index] = aircraft[index].copyWith(
          deletedAt: value,
          clearDeletedAt: value == null,
        );
      case EntityKind.pilots:
        pilots[index] = pilots[index].copyWith(
          deletedAt: value,
          clearDeletedAt: value == null,
        );
      case EntityKind.services:
        services[index] = services[index].copyWith(
          deletedAt: value,
          clearDeletedAt: value == null,
        );
      case EntityKind.passengers:
        passengers[index] = passengers[index].copyWith(
          deletedAt: value,
          clearDeletedAt: value == null,
        );
    }
  }
}
