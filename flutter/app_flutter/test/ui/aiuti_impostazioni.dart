// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// Tocca la scheda [nome] delle Impostazioni (Generale, Accesso, Grafico,
/// IA resoconto).
Future<void> apriScheda(WidgetTester tester, String nome) async {
  await tester.tap(
    find.descendant(
      of: find.byKey(const Key('schede-impostazioni')),
      matching: find.text(nome),
    ),
  );
  await tester.pumpAndSettle();
}
