class Validators {
  static String? requiredText(
    String? value, {
    String message = 'Обязательное поле',
  }) => value == null || value.trim().isEmpty ? message : null;

  static String? length(String? value, {int min = 2, int max = 100}) {
    final required = requiredText(value);
    if (required != null) return required;
    final count = value!.trim().length;
    return count < min || count > max
        ? 'Допустимо от $min до $max символов'
        : null;
  }

  static String? integer(String? value, {int min = 0, int max = 9999}) {
    final number = int.tryParse(value ?? '');
    if (number == null) return 'Введите целое число';
    return number < min || number > max
        ? 'Допустимо значение от $min до $max'
        : null;
  }

  static String? decimal(
    String? value, {
    double min = 0,
    double max = 1000000,
  }) {
    final number = double.tryParse((value ?? '').replaceAll(',', '.'));
    if (number == null) return 'Введите число';
    return number < min || number > max
        ? 'Допустимо значение от $min до $max'
        : null;
  }

  static String? email(String? value) {
    final required = requiredText(value);
    if (required != null) return required;
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value!.trim())
        ? null
        : 'Введите корректный адрес почты';
  }

  static String? flightNumber(String? value) {
    final text = (value ?? '').trim().toUpperCase();
    if (text.isEmpty) return 'Укажите номер рейса';
    return RegExp(r'^[A-ZА-ЯЁ]{2}\s?\d{1,4}$').hasMatch(text)
        ? null
        : 'Формат: SU 123';
  }

  static String? registration(String? value) =>
      RegExp(
        r'^[A-ZА-ЯЁ]{2}-\d{5}$',
      ).hasMatch((value ?? '').trim().toUpperCase())
      ? null
      : 'Формат: RA-12345';

  static String? passport(String? value) =>
      RegExp(r'^\d{4}\s\d{6}$').hasMatch((value ?? '').trim())
      ? null
      : 'Формат: 1234 567890';

  static String? ticketNumber(String? value) =>
      RegExp(r'^TKT-\d{5,8}$').hasMatch((value ?? '').trim().toUpperCase())
      ? null
      : 'Формат: TKT-12345';

  static String? seat(String? value) =>
      RegExp(
        r'^(?:[1-9]|[1-5]\d)[A-F]$',
      ).hasMatch((value ?? '').trim().toUpperCase())
      ? null
      : 'Формат места: 12A';

  static String? dateTime(String? value) =>
      DateTime.tryParse(value ?? '') == null
      ? 'Формат: ГГГГ-ММ-ДД ЧЧ:ММ'
      : null;

  static String? date(String? value) =>
      DateTime.tryParse(value ?? '') == null ? 'Формат: ГГГГ-ММ-ДД' : null;
}
