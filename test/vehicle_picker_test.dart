import 'package:event_app/models/vehicle.dart';
import 'package:event_app/theme/app_theme.dart';
import 'package:event_app/widgets/home/vehicle_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.dark,
    home: Scaffold(body: child),
  );
}

const List<Vehicle> _vehicles = [
  Vehicle(id: 'vehicle-001', name: 'Beli kombi'),
  Vehicle(id: 'vehicle-002', name: 'Sivi Caddy'),
];

void main() {
  testWidgets('prikazuje izabrano vozilo', (WidgetTester tester) async {
    await tester.pumpWidget(
      _wrap(
        VehiclePicker(
          vehicles: _vehicles,
          selectedVehicleId: 'vehicle-002',
          onSelected: (_) {},
          onAdd: (_) {},
        ),
      ),
    );

    expect(find.text('Vozilo'), findsOneWidget);
    expect(find.text('Sivi Caddy'), findsOneWidget);
  });

  testWidgets('kad vozilo nije izabrano prikazuje objašnjenje',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      _wrap(
        VehiclePicker(
          vehicles: _vehicles,
          selectedVehicleId: null,
          onSelected: (_) {},
          onAdd: (_) {},
        ),
      ),
    );

    expect(find.text('Vozilo nije izabrano'), findsOneWidget);
  });

  testWidgets('nepoznat id vozila se ponaša kao da izbora nema',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      _wrap(
        VehiclePicker(
          vehicles: _vehicles,
          selectedVehicleId: 'vehicle-obrisano',
          onSelected: (_) {},
          onAdd: (_) {},
        ),
      ),
    );

    expect(find.text('Vozilo nije izabrano'), findsOneWidget);
  });

  testWidgets('bez dozvole se lista ne otvara', (WidgetTester tester) async {
    await tester.pumpWidget(
      _wrap(
        VehiclePicker(
          vehicles: _vehicles,
          selectedVehicleId: 'vehicle-001',
          onSelected: (_) {},
          onAdd: (_) {},
          canEdit: false,
        ),
      ),
    );

    await tester.tap(find.text('Beli kombi'));
    await tester.pumpAndSettle();

    expect(find.text('Izaberi vozilo'), findsNothing);
  });

  testWidgets('izbor iz liste javlja ekranu koje je vozilo izabrano',
      (WidgetTester tester) async {
    String? chosen;
    await tester.pumpWidget(
      _wrap(
        VehiclePicker(
          vehicles: _vehicles,
          selectedVehicleId: 'vehicle-001',
          onSelected: (id) => chosen = id,
          onAdd: (_) {},
        ),
      ),
    );

    await tester.tap(find.text('Beli kombi'));
    await tester.pumpAndSettle();
    expect(find.text('Izaberi vozilo'), findsOneWidget);

    await tester.tap(find.text('Sivi Caddy'));
    await tester.pumpAndSettle();

    expect(chosen, 'vehicle-002');
    expect(find.text('Izaberi vozilo'), findsNothing);
  });

  testWidgets('dodavanje novog vozila javlja ekranu naziv',
      (WidgetTester tester) async {
    String? added;
    await tester.pumpWidget(
      _wrap(
        VehiclePicker(
          vehicles: _vehicles,
          selectedVehicleId: null,
          onSelected: (_) {},
          onAdd: (name) => added = name,
        ),
      ),
    );

    await tester.tap(find.text('Vozilo nije izabrano'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Dodaj vozilo'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '  Crni Transporter  ');
    await tester.tap(find.text('Sačuvaj'));
    await tester.pumpAndSettle();

    // Višak razmaka se skida.
    expect(added, 'Crni Transporter');
  });

  testWidgets('prazan naziv vozila se ne prihvata',
      (WidgetTester tester) async {
    var addCalls = 0;
    await tester.pumpWidget(
      _wrap(
        VehiclePicker(
          vehicles: _vehicles,
          selectedVehicleId: null,
          onSelected: (_) {},
          onAdd: (_) => addCalls++,
        ),
      ),
    );

    await tester.tap(find.text('Vozilo nije izabrano'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dodaj vozilo'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '   ');
    await tester.tap(find.text('Sačuvaj'));
    await tester.pumpAndSettle();

    expect(addCalls, 0);
    expect(find.text('Izaberi vozilo'), findsOneWidget);
  });

  testWidgets('prazan spisak vozila ima svoje objašnjenje',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      _wrap(
        VehiclePicker(
          vehicles: const [],
          selectedVehicleId: null,
          onSelected: (_) {},
          onAdd: (_) {},
        ),
      ),
    );

    await tester.tap(find.text('Vozilo nije izabrano'));
    await tester.pumpAndSettle();

    expect(find.text('Nijedno vozilo još nije uneto.'), findsOneWidget);
    expect(find.text('Dodaj vozilo'), findsOneWidget);
  });
}
