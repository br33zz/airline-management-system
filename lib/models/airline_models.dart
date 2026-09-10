abstract interface class AirlineModel {
  int get id;
  DateTime? get deletedAt;
  Map<String, dynamic> toJson();
}

int jsonInt(Object? value, [int fallback = 0]) => switch (value) {
  int v => v,
  num v => v.toInt(),
  String v => int.tryParse(v) ?? fallback,
  _ => fallback,
};

double jsonDouble(Object? value, [double fallback = 0]) => switch (value) {
  num v => v.toDouble(),
  String v => double.tryParse(v.replaceAll(',', '.')) ?? fallback,
  _ => fallback,
};

String jsonString(Object? value, [String fallback = '']) =>
    value == null ? fallback : value.toString();

DateTime? jsonDate(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;

List<int> jsonIds(Object? value) => value is List
    ? value.map((e) => jsonInt(e, -1)).where((e) => e >= 0).toList()
    : <int>[];

class Flight implements AirlineModel {
  @override
  final int id;
  final String number, destination, status;
  final DateTime departure;
  final int seats, aircraftId;
  final List<int> pilotIds, serviceIds;
  @override
  final DateTime? deletedAt;

  const Flight({
    required this.id,
    required this.number,
    required this.destination,
    required this.departure,
    required this.status,
    required this.seats,
    required this.aircraftId,
    required this.pilotIds,
    required this.serviceIds,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  Flight copyWith({
    String? number,
    String? destination,
    DateTime? departure,
    String? status,
    int? seats,
    int? aircraftId,
    List<int>? pilotIds,
    List<int>? serviceIds,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) => Flight(
    id: id,
    number: number ?? this.number,
    destination: destination ?? this.destination,
    departure: departure ?? this.departure,
    status: status ?? this.status,
    seats: seats ?? this.seats,
    aircraftId: aircraftId ?? this.aircraftId,
    pilotIds: pilotIds ?? this.pilotIds,
    serviceIds: serviceIds ?? this.serviceIds,
    deletedAt: clearDeletedAt ? null : deletedAt ?? this.deletedAt,
  );

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'number': number,
    'destination': destination,
    'departure': departure.toIso8601String(),
    'status': status,
    'seats': seats,
    'aircraftId': aircraftId,
    'pilotIds': pilotIds,
    'serviceIds': serviceIds,
    'deletedAt': deletedAt?.toIso8601String(),
  };

  factory Flight.fromJson(Map<String, dynamic> json) => Flight(
    id: jsonInt(json['id']),
    number: jsonString(json['number']),
    destination: jsonString(json['destination']),
    departure: jsonDate(json['departure']) ?? DateTime(2026, 1, 1),
    status: jsonString(json['status'], 'По расписанию'),
    seats: jsonInt(json['seats']),
    aircraftId: jsonInt(json['aircraftId']),
    pilotIds: jsonIds(json['pilotIds']),
    serviceIds: jsonIds(json['serviceIds']),
    deletedAt: jsonDate(json['deletedAt']),
  );
}

class Aircraft implements AirlineModel {
  @override
  final int id;
  final String registrationNumber, model, type;
  final int capacity;
  @override
  final DateTime? deletedAt;

  const Aircraft({
    required this.id,
    required this.registrationNumber,
    required this.model,
    required this.type,
    required this.capacity,
    this.deletedAt,
  });

  Aircraft copyWith({
    String? registrationNumber,
    String? model,
    String? type,
    int? capacity,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) => Aircraft(
    id: id,
    registrationNumber: registrationNumber ?? this.registrationNumber,
    model: model ?? this.model,
    type: type ?? this.type,
    capacity: capacity ?? this.capacity,
    deletedAt: clearDeletedAt ? null : deletedAt ?? this.deletedAt,
  );

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'registrationNumber': registrationNumber,
    'model': model,
    'type': type,
    'capacity': capacity,
    'deletedAt': deletedAt?.toIso8601String(),
  };

  factory Aircraft.fromJson(Map<String, dynamic> json) => Aircraft(
    id: jsonInt(json['id']),
    registrationNumber: jsonString(json['registrationNumber']),
    model: jsonString(json['model']),
    type: jsonString(json['type']),
    capacity: jsonInt(json['capacity']),
    deletedAt: jsonDate(json['deletedAt']),
  );
}

class Pilot implements AirlineModel {
  @override
  final int id;
  final String fullName, licenseNumber, qualification;
  final int experienceYears;
  @override
  final DateTime? deletedAt;

  const Pilot({
    required this.id,
    required this.fullName,
    required this.licenseNumber,
    required this.qualification,
    required this.experienceYears,
    this.deletedAt,
  });

  Pilot copyWith({
    String? fullName,
    String? licenseNumber,
    String? qualification,
    int? experienceYears,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) => Pilot(
    id: id,
    fullName: fullName ?? this.fullName,
    licenseNumber: licenseNumber ?? this.licenseNumber,
    qualification: qualification ?? this.qualification,
    experienceYears: experienceYears ?? this.experienceYears,
    deletedAt: clearDeletedAt ? null : deletedAt ?? this.deletedAt,
  );

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'fullName': fullName,
    'licenseNumber': licenseNumber,
    'qualification': qualification,
    'experienceYears': experienceYears,
    'deletedAt': deletedAt?.toIso8601String(),
  };

  factory Pilot.fromJson(Map<String, dynamic> json) => Pilot(
    id: jsonInt(json['id']),
    fullName: jsonString(json['fullName']),
    licenseNumber: jsonString(json['licenseNumber']),
    qualification: jsonString(json['qualification']),
    experienceYears: jsonInt(json['experienceYears']),
    deletedAt: jsonDate(json['deletedAt']),
  );
}

class AirlineService implements AirlineModel {
  @override
  final int id;
  final String name, description;
  final double price;
  @override
  final DateTime? deletedAt;

  const AirlineService({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.deletedAt,
  });

  AirlineService copyWith({
    String? name,
    String? description,
    double? price,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) => AirlineService(
    id: id,
    name: name ?? this.name,
    description: description ?? this.description,
    price: price ?? this.price,
    deletedAt: clearDeletedAt ? null : deletedAt ?? this.deletedAt,
  );

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'price': price,
    'deletedAt': deletedAt?.toIso8601String(),
  };

  factory AirlineService.fromJson(Map<String, dynamic> json) => AirlineService(
    id: jsonInt(json['id']),
    name: jsonString(json['name']),
    description: jsonString(json['description']),
    price: jsonDouble(json['price']),
    deletedAt: jsonDate(json['deletedAt']),
  );
}

class Ticket {
  final String number, seat, fareClass;
  final int flightId;
  final DateTime issuedAt;

  const Ticket({
    required this.number,
    required this.flightId,
    required this.seat,
    required this.fareClass,
    required this.issuedAt,
  });

  Map<String, dynamic> toJson() => {
    'number': number,
    'flightId': flightId,
    'seat': seat,
    'fareClass': fareClass,
    'issuedAt': issuedAt.toIso8601String(),
  };

  factory Ticket.fromJson(Map<String, dynamic> json) => Ticket(
    number: jsonString(json['number']),
    flightId: jsonInt(json['flightId']),
    seat: jsonString(json['seat']),
    fareClass: jsonString(json['fareClass'], 'Эконом'),
    issuedAt: jsonDate(json['issuedAt']) ?? DateTime(2026, 1, 1),
  );
}

class Passenger implements AirlineModel {
  @override
  final int id;
  final String fullName, passport, country, email;
  final Ticket ticket;
  @override
  final DateTime? deletedAt;

  const Passenger({
    required this.id,
    required this.fullName,
    required this.passport,
    required this.country,
    required this.email,
    required this.ticket,
    this.deletedAt,
  });

  Passenger copyWith({
    String? fullName,
    String? passport,
    String? country,
    String? email,
    Ticket? ticket,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) => Passenger(
    id: id,
    fullName: fullName ?? this.fullName,
    passport: passport ?? this.passport,
    country: country ?? this.country,
    email: email ?? this.email,
    ticket: ticket ?? this.ticket,
    deletedAt: clearDeletedAt ? null : deletedAt ?? this.deletedAt,
  );

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'fullName': fullName,
    'passport': passport,
    'country': country,
    'email': email,
    'ticket': ticket.toJson(),
    'deletedAt': deletedAt?.toIso8601String(),
  };

  factory Passenger.fromJson(Map<String, dynamic> json) => Passenger(
    id: jsonInt(json['id']),
    fullName: jsonString(json['fullName']),
    passport: jsonString(json['passport']),
    country: jsonString(json['country']),
    email: jsonString(json['email']),
    ticket: Ticket.fromJson(
      json['ticket'] is Map
          ? Map<String, dynamic>.from(json['ticket'] as Map)
          : const {},
    ),
    deletedAt: jsonDate(json['deletedAt']),
  );
}

enum EntityKind { flights, aircraft, pilots, services, passengers }

extension EntityKindUi on EntityKind {
  String get title => switch (this) {
    EntityKind.flights => 'Рейсы',
    EntityKind.aircraft => 'Самолёты',
    EntityKind.pilots => 'Пилоты',
    EntityKind.services => 'Услуги',
    EntityKind.passengers => 'Пассажиры',
  };

  String get singular => switch (this) {
    EntityKind.flights => 'рейс',
    EntityKind.aircraft => 'самолёт',
    EntityKind.pilots => 'пилота',
    EntityKind.services => 'услугу',
    EntityKind.passengers => 'пассажира',
  };

  static EntityKind? tryParse(String? value) {
    for (final kind in EntityKind.values) {
      if (kind.name == value) return kind;
    }
    return null;
  }
}
