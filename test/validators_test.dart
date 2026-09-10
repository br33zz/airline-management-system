import 'package:airline_practice/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Validators', () {
    test('проверяет обязательность и длину', () {
      expect(Validators.length(''), isNotNull);
      expect(Validators.length('А'), isNotNull);
      expect(Validators.length('Москва'), isNull);
    });

    test('проверяет форматы предметной области', () {
      expect(Validators.flightNumber('SU 321'), isNull);
      expect(Validators.flightNumber('321'), isNotNull);
      expect(Validators.registration('RA-73101'), isNull);
      expect(Validators.passport('4500 123456'), isNull);
      expect(Validators.ticketNumber('TKT-12345'), isNull);
      expect(Validators.seat('12A'), isNull);
    });

    test('проверяет числа, даты и email', () {
      expect(Validators.integer('180', min: 1, max: 600), isNull);
      expect(Validators.integer('-1', min: 1), isNotNull);
      expect(Validators.decimal('1250,50'), isNull);
      expect(Validators.date('2026-09-09'), isNull);
      expect(Validators.email('passenger@example.ru'), isNull);
      expect(Validators.email('wrong'), isNotNull);
    });
  });
}
