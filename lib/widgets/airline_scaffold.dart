import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/airline_models.dart';

class AirlineScaffold extends StatelessWidget {
  final String title;
  final EntityKind selected;
  final Widget body;
  final List<Widget> actions;
  const AirlineScaffold({
    super.key,
    required this.title,
    required this.selected,
    required this.body,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title), actions: actions),
    drawer: Drawer(
      child: SafeArea(
        child: Column(
          children: [
            const ListTile(
              leading: Icon(Icons.flight_takeoff),
              title: Text(
                'Авиакомпания',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text('Система управления'),
            ),
            const Divider(),
            ...EntityKind.values.map(
              (kind) => ListTile(
                selected: kind == selected,
                leading: Icon(switch (kind) {
                  EntityKind.flights => Icons.flight,
                  EntityKind.aircraft => Icons.airplanemode_active,
                  EntityKind.pilots => Icons.badge,
                  EntityKind.services => Icons.room_service,
                  EntityKind.passengers => Icons.people,
                }),
                title: Text(kind.title),
                onTap: () {
                  Navigator.pop(context);
                  context.go('/${kind.name}');
                },
              ),
            ),
          ],
        ),
      ),
    ),
    body: body,
  );
}
