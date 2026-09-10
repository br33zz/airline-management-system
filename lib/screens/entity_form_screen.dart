import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/airline_models.dart';
import '../repositories/airline_repository.dart';
import '../utils/validators.dart';
import '../widgets/airline_scaffold.dart';
import '../widgets/configured_fields.dart';

class EntityFormScreen extends StatefulWidget {
  final EntityKind kind;
  final int? id;
  const EntityFormScreen({super.key, required this.kind, this.id});

  bool get isEditing => id != null;

  @override
  State<EntityFormScreen> createState() => _EntityFormScreenState();
}

class _EntityFormScreenState extends State<EntityFormScreen> {
  final formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> controllers = {};
  bool dirty = false, saving = false, loaded = false;
  int? aircraftId, ticketFlightId;
  List<int> pilotIds = [], serviceIds = [];
  String status = 'По расписанию';
  String fareClass = 'Эконом';
  String? duplicateNumberError, duplicateEmailError;

  TextEditingController control(String key) =>
      controllers.putIfAbsent(key, TextEditingController.new);
  String text(String key) => control(key).text.trim();
  int number(String key) => int.tryParse(text(key)) ?? 0;
  double decimal(String key) =>
      double.tryParse(text(key).replaceAll(',', '.')) ?? 0;
  DateTime? parsedDate(String key) =>
      DateTime.tryParse(text(key).replaceFirst(' ', 'T'));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (loaded) return;
    loaded = true;
    _loadExisting(context.read<AirlineRepository>());
  }

  void _loadExisting(AirlineRepository repository) {
    if (!widget.isEditing) {
      control('departure').text = '2026-09-15 12:00';
      control('issuedAt').text = '2026-09-09';
      return;
    }
    final item = repository.byId(widget.kind, widget.id!);
    switch (item) {
      case Flight value:
        control('number').text = value.number;
        control('destination').text = value.destination;
        control('departure').text = _dateTimeInput(value.departure);
        control('seats').text = '${value.seats}';
        aircraftId = value.aircraftId;
        pilotIds = [...value.pilotIds];
        serviceIds = [...value.serviceIds];
        status = value.status;
      case Aircraft value:
        control('registration').text = value.registrationNumber;
        control('model').text = value.model;
        control('type').text = value.type;
        control('capacity').text = '${value.capacity}';
      case Pilot value:
        control('fullName').text = value.fullName;
        control('license').text = value.licenseNumber;
        control('qualification').text = value.qualification;
        control('experience').text = '${value.experienceYears}';
      case AirlineService value:
        control('name').text = value.name;
        control('description').text = value.description;
        control('price').text = value.price.toStringAsFixed(0);
      case Passenger value:
        control('fullName').text = value.fullName;
        control('passport').text = value.passport;
        control('country').text = value.country;
        control('email').text = value.email;
        control('ticketNumber').text = value.ticket.number;
        control('seat').text = value.ticket.seat;
        control('issuedAt').text = _dateInput(value.ticket.issuedAt);
        ticketFlightId = value.ticket.flightId;
        fareClass = value.ticket.fareClass;
      case null:
        break;
    }
  }

  String _dateInput(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
  String _dateTimeInput(DateTime value) =>
      '${_dateInput(value)} ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

  void markDirty([String _ = '']) {
    if (!dirty) setState(() => dirty = true);
  }

  Future<bool> confirmLeave() async {
    if (!dirty) return true;
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Есть несохранённые изменения'),
            content: const Text('Закрыть форму и потерять введённые данные?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Остаться'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Выйти'),
              ),
            ],
          ),
        ) ??
        false;
  }

  List<FieldSpec> _simpleFields() => switch (widget.kind) {
    EntityKind.aircraft => [
      FieldSpec(
        keyName: 'registration',
        label: 'Регистрационный номер',
        controller: control('registration'),
        validator: Validators.registration,
      ),
      FieldSpec(
        keyName: 'model',
        label: 'Модель',
        controller: control('model'),
        validator: (value) => Validators.length(value, min: 2, max: 60),
      ),
      FieldSpec(
        keyName: 'type',
        label: 'Тип самолёта',
        controller: control('type'),
        validator: (value) => Validators.length(value, min: 2, max: 20),
      ),
      FieldSpec(
        keyName: 'capacity',
        label: 'Вместимость',
        controller: control('capacity'),
        keyboardType: TextInputType.number,
        validator: (value) => Validators.integer(value, min: 1, max: 600),
      ),
    ],
    EntityKind.pilots => [
      FieldSpec(
        keyName: 'fullName',
        label: 'ФИО пилота',
        controller: control('fullName'),
        validator: (value) => Validators.length(value, min: 5, max: 100),
      ),
      FieldSpec(
        keyName: 'license',
        label: 'Номер лицензии',
        controller: control('license'),
        validator: (value) => Validators.length(value, min: 4, max: 30),
      ),
      FieldSpec(
        keyName: 'qualification',
        label: 'Квалификация по типу самолёта',
        controller: control('qualification'),
        validator: (value) => Validators.length(value, min: 2, max: 20),
      ),
      FieldSpec(
        keyName: 'experience',
        label: 'Стаж, лет',
        controller: control('experience'),
        keyboardType: TextInputType.number,
        validator: (value) => Validators.integer(value, min: 0, max: 60),
      ),
    ],
    EntityKind.services => [
      FieldSpec(
        keyName: 'name',
        label: 'Название услуги',
        controller: control('name'),
        validator: (value) => Validators.length(value, min: 2, max: 80),
      ),
      FieldSpec(
        keyName: 'description',
        label: 'Описание',
        controller: control('description'),
        maxLines: 3,
        validator: (value) => Validators.length(value, min: 5, max: 250),
      ),
      FieldSpec(
        keyName: 'price',
        label: 'Стоимость, ₽',
        controller: control('price'),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        validator: (value) => Validators.decimal(value, min: 0, max: 1000000),
      ),
    ],
    EntityKind.passengers => [
      FieldSpec(
        keyName: 'fullName',
        label: 'ФИО пассажира',
        controller: control('fullName'),
        validator: (value) => Validators.length(value, min: 5, max: 100),
      ),
      FieldSpec(
        keyName: 'passport',
        label: 'Паспорт',
        controller: control('passport'),
        validator: Validators.passport,
      ),
      FieldSpec(
        keyName: 'country',
        label: 'Страна',
        controller: control('country'),
        validator: (value) => Validators.length(value, min: 2, max: 60),
      ),
      FieldSpec(
        keyName: 'email',
        label: 'Электронная почта',
        controller: control('email'),
        keyboardType: TextInputType.emailAddress,
        validator: (value) => duplicateEmailError ?? Validators.email(value),
      ),
    ],
    EntityKind.flights => const [],
  };

  Widget _flightFields(AirlineRepository repository) {
    final compatible = repository.compatiblePilots(aircraftId);
    final activeServices = repository.services
        .where((item) => item.deletedAt == null)
        .toList();
    final selectedAircraft = repository.aircraftById(aircraftId ?? -1);
    return Column(
      children: [
        ConfiguredFields(
          fields: [
            FieldSpec(
              keyName: 'number',
              label: 'Номер рейса',
              controller: control('number'),
              validator: (value) =>
                  duplicateNumberError ?? Validators.flightNumber(value),
            ),
            FieldSpec(
              keyName: 'destination',
              label: 'Направление',
              controller: control('destination'),
              validator: (value) => Validators.length(value, min: 2, max: 80),
            ),
            FieldSpec(
              keyName: 'departure',
              label: 'Дата и время вылета (ГГГГ-ММ-ДД ЧЧ:ММ)',
              controller: control('departure'),
              validator: (value) =>
                  Validators.dateTime((value ?? '').replaceFirst(' ', 'T')),
            ),
            FieldSpec(
              keyName: 'seats',
              label: 'Продано мест',
              controller: control('seats'),
              keyboardType: TextInputType.number,
              validator: (value) {
                final base = Validators.integer(value, min: 1, max: 600);
                if (base != null) return base;
                if (selectedAircraft != null &&
                    (int.tryParse(value ?? '') ?? 0) >
                        selectedAircraft.capacity) {
                  return 'Больше вместимости самолёта (${selectedAircraft.capacity})';
                }
                return null;
              },
            ),
          ],
          onChanged: markDirty,
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: DropdownButtonFormField<int>(
            initialValue: aircraftId,
            decoration: const InputDecoration(labelText: 'Самолёт'),
            items: repository.aircraft
                .where((item) => item.deletedAt == null)
                .map(
                  (item) => DropdownMenuItem(
                    value: item.id,
                    child: Text('${item.registrationNumber} · ${item.model}'),
                  ),
                )
                .toList(),
            validator: (value) => value == null ? 'Выберите самолёт' : null,
            onChanged: (value) {
              final allowed = repository
                  .compatiblePilots(value)
                  .map((item) => item.id)
                  .toSet();
              setState(() {
                aircraftId = value;
                pilotIds.removeWhere((id) => !allowed.contains(id));
                dirty = true;
              });
              formKey.currentState?.validate();
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: DropdownButtonFormField<String>(
            initialValue: status,
            decoration: const InputDecoration(labelText: 'Статус'),
            items: const ['По расписанию', 'Посадка', 'Задержан']
                .map(
                  (value) => DropdownMenuItem(value: value, child: Text(value)),
                )
                .toList(),
            onChanged: (value) => setState(() {
              status = value ?? status;
              dirty = true;
            }),
          ),
        ),
        FormField<List<int>>(
          initialValue: pilotIds,
          validator: (_) => pilotIds.isEmpty
              ? 'Выберите хотя бы одного пилота'
              : null,
          builder: (field) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: aircraftId == null
                    ? 'Пилоты — сначала выберите самолёт'
                    : 'Пилоты с квалификацией ${selectedAircraft?.type ?? ''}',
                errorText: field.errorText,
              ),
              child: compatible.isEmpty
                  ? const Text('Нет доступных пилотов')
                  : Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: compatible.map((pilot) {
                        final selected = pilotIds.contains(pilot.id);
                        return FilterChip(
                          label: Text(pilot.fullName),
                          selected: selected,
                          onSelected: (_) {
                            final next = [...pilotIds];
                            selected
                                ? next.remove(pilot.id)
                                : next.add(pilot.id);
                            field.didChange(next);
                            setState(() {
                              pilotIds = next;
                              dirty = true;
                            });
                          },
                        );
                      }).toList(),
                    ),
            ),
          ),
        ),
        FormField<List<int>>(
          initialValue: serviceIds,
          validator: (_) => serviceIds.isEmpty
              ? 'Выберите хотя бы одну услугу'
              : null,
          builder: (field) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Услуги',
                errorText: field.errorText,
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: activeServices.map((service) {
                  final selected = serviceIds.contains(service.id);
                  return FilterChip(
                    label: Text(service.name),
                    selected: selected,
                    onSelected: (_) {
                      final next = [...serviceIds];
                      selected ? next.remove(service.id) : next.add(service.id);
                      field.didChange(next);
                      setState(() {
                        serviceIds = next;
                        dirty = true;
                      });
                    },
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _passengerFields(AirlineRepository repository) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      ConfiguredFields(fields: _simpleFields(), onChanged: markDirty),
      const Divider(height: 30),
      Text('Билет пассажира', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 14),
      ConfiguredFields(
        fields: [
          FieldSpec(
            keyName: 'ticketNumber',
            label: 'Номер билета',
            controller: control('ticketNumber'),
            validator: Validators.ticketNumber,
          ),
          FieldSpec(
            keyName: 'seat',
            label: 'Место',
            controller: control('seat'),
            validator: Validators.seat,
          ),
          FieldSpec(
            keyName: 'issuedAt',
            label: 'Дата оформления (ГГГГ-ММ-ДД)',
            controller: control('issuedAt'),
            validator: Validators.date,
          ),
        ],
        onChanged: markDirty,
      ),
      Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: DropdownButtonFormField<int>(
          initialValue: ticketFlightId,
          decoration: const InputDecoration(labelText: 'Рейс по билету'),
          items: repository.flights
              .where((item) => item.deletedAt == null)
              .map(
                (item) => DropdownMenuItem(
                  value: item.id,
                  child: Text('${item.number} · ${item.destination}'),
                ),
              )
              .toList(),
          validator: (value) => value == null ? 'Выберите рейс' : null,
          onChanged: (value) => setState(() {
            ticketFlightId = value;
            dirty = true;
          }),
        ),
      ),
      DropdownButtonFormField<String>(
        initialValue: fareClass,
        decoration: const InputDecoration(labelText: 'Класс обслуживания'),
        items: const ['Эконом', 'Комфорт', 'Бизнес']
            .map((value) => DropdownMenuItem(value: value, child: Text(value)))
            .toList(),
        onChanged: (value) => setState(() {
          fareClass = value ?? fareClass;
          dirty = true;
        }),
      ),
      const SizedBox(height: 14),
    ],
  );

  Future<void> _save() async {
    duplicateNumberError = null;
    duplicateEmailError = null;
    if (!(formKey.currentState?.validate() ?? false)) return;
    final repository = context.read<AirlineRepository>();
    final id = widget.id ?? repository.nextId(widget.kind);
    final old = widget.id == null
        ? null
        : repository.byId(widget.kind, widget.id!);
    final item = switch (widget.kind) {
      EntityKind.flights => Flight(
        id: id,
        number: text('number').toUpperCase(),
        destination: text('destination'),
        departure: parsedDate('departure')!,
        status: status,
        seats: number('seats'),
        aircraftId: aircraftId!,
        pilotIds: [...pilotIds],
        serviceIds: [...serviceIds],
        deletedAt: old?.deletedAt,
      ),
      EntityKind.aircraft => Aircraft(
        id: id,
        registrationNumber: text('registration').toUpperCase(),
        model: text('model'),
        type: text('type').toUpperCase(),
        capacity: number('capacity'),
        deletedAt: old?.deletedAt,
      ),
      EntityKind.pilots => Pilot(
        id: id,
        fullName: text('fullName'),
        licenseNumber: text('license').toUpperCase(),
        qualification: text('qualification').toUpperCase(),
        experienceYears: number('experience'),
        deletedAt: old?.deletedAt,
      ),
      EntityKind.services => AirlineService(
        id: id,
        name: text('name'),
        description: text('description'),
        price: decimal('price'),
        deletedAt: old?.deletedAt,
      ),
      EntityKind.passengers => Passenger(
        id: id,
        fullName: text('fullName'),
        passport: text('passport'),
        country: text('country'),
        email: text('email').toLowerCase(),
        ticket: Ticket(
          number: text('ticketNumber').toUpperCase(),
          flightId: ticketFlightId!,
          seat: text('seat').toUpperCase(),
          fareClass: fareClass,
          issuedAt: parsedDate('issuedAt')!,
        ),
        deletedAt: old?.deletedAt,
      ),
    };
    setState(() => saving = true);
    try {
      await repository.save(widget.kind, item);
      dirty = false;
      if (mounted) context.go('/${widget.kind.name}/$id');
    } on DuplicateValueException catch (exception) {
      if (exception.field == 'number') {
        duplicateNumberError = exception.message;
      } else {
        duplicateEmailError = exception.message;
      }
      if (mounted) {
        setState(() => saving = false);
        formKey.currentState?.validate();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final repository = context.watch<AirlineRepository>();
    return PopScope(
      canPop: !dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop && await confirmLeave() && context.mounted) {
          dirty = false;
          context.pop();
        }
      },
      child: AirlineScaffold(
        title: widget.isEditing
            ? 'Редактировать ${widget.kind.singular}'
            : 'Добавить ${widget.kind.singular}',
        selected: widget.kind,
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 780),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          widget.isEditing
                              ? 'Изменение записи'
                              : 'Новая запись',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 20),
                        if (widget.kind == EntityKind.flights)
                          _flightFields(repository)
                        else if (widget.kind == EntityKind.passengers)
                          _passengerFields(repository)
                        else
                          ConfiguredFields(
                            fields: _simpleFields(),
                            onChanged: markDirty,
                          ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () async {
                                if (await confirmLeave() && context.mounted) {
                                  dirty = false;
                                  context.go('/${widget.kind.name}');
                                }
                              },
                              child: const Text('Отмена'),
                            ),
                            const SizedBox(width: 12),
                            FilledButton.icon(
                              onPressed: saving ? null : _save,
                              icon: saving
                                  ? const SizedBox.square(
                                      dimension: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.save),
                              label: Text(
                                widget.isEditing ? 'Сохранить' : 'Создать',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    for (final controller in controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
}
