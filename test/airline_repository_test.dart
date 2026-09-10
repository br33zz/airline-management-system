import 'dart:convert';

import 'package:airline_practice/models/airline_models.dart';
import 'package:airline_practice/repositories/airline_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('модели сериализуются и устойчивы к пустому JSON', () {
    final flight = Flight(
      id: 10,
      number: 'SU 999',
      destination: 'Сочи',
      departure: DateTime(2026, 9, 10, 12),
      status: 'По расписанию',
      seats: 100,
      aircraftId: 1,
      pilotIds: const [1, 2],
      serviceIds: const [1],
    );
    final restored = Flight.fromJson(flight.toJson());
    expect(restored.number, flight.number);
    expect(restored.pilotIds, [1, 2]);

    expect(() => Flight.fromJson(const {}), returnsNormally);
    expect(() => Aircraft.fromJson(const {}), returnsNormally);
    expect(() => Pilot.fromJson(const {}), returnsNormally);
    expect(() => AirlineService.fromJson(const {}), returnsNormally);
    expect(() => Passenger.fromJson(const {}), returnsNormally);
  });

  test('отклоняет повторяющийся номер рейса и email', () async {
    final preferences = await SharedPreferences.getInstance();
    final repository = AirlineRepository(preferences);
    final sourceFlight = repository.flights.first;
    final duplicateFlight = Flight(
      id: 100,
      number: sourceFlight.number,
      destination: 'Тест',
      departure: DateTime(2026, 10, 1),
      status: 'По расписанию',
      seats: 20,
      aircraftId: sourceFlight.aircraftId,
      pilotIds: sourceFlight.pilotIds,
      serviceIds: sourceFlight.serviceIds,
    );
    expect(
      () => repository.save(EntityKind.flights, duplicateFlight),
      throwsA(isA<DuplicateValueException>()),
    );

    final sourcePassenger = repository.passengers.first;
    final duplicatePassenger = Passenger(
      id: 100,
      fullName: 'Тестовый Пассажир',
      passport: '4500 999999',
      country: 'Россия',
      email: sourcePassenger.email.toUpperCase(),
      ticket: Ticket(
        number: 'TKT-99999',
        flightId: repository.flights.first.id,
        seat: '1A',
        fareClass: 'Эконом',
        issuedAt: DateTime(2026, 9, 9),
      ),
    );
    expect(
      () => repository.save(EntityKind.passengers, duplicatePassenger),
      throwsA(isA<DuplicateValueException>()),
    );
  });

  test('не удаляет самолёт со связанными рейсами', () async {
    final repository = AirlineRepository(await SharedPreferences.getInstance());
    expect(
      () => repository.delete(EntityKind.aircraft, 1),
      throwsA(
        isA<LinkedRecordsException>().having(
          (error) => error.count,
          'count',
          greaterThan(0),
        ),
      ),
    );
  });

  test('сохраняет изменения между экземплярами репозитория', () async {
    final preferences = await SharedPreferences.getInstance();
    final first = AirlineRepository(preferences);
    await first.save(
      EntityKind.services,
      const AirlineService(
        id: 99,
        name: 'Тестовая услуга',
        description: 'Проверка постоянного хранения',
        price: 100,
      ),
    );

    final second = AirlineRepository(preferences);
    expect(second.services.any((item) => item.id == 99), isTrue);
  });

  test('несовместимая версия не приводит к падению', () async {
    SharedPreferences.setMockInitialValues({
      AirlineRepository.storageKey: jsonEncode({
        'schemaVersion': 1,
        'flights': [],
      }),
    });
    final repository = AirlineRepository(await SharedPreferences.getInstance());
    expect(repository.flights, isNotEmpty);
    expect(repository.startupMessage, isNotNull);
  });
}
