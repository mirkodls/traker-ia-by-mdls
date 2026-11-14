// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:traker_ia/domain/traduzioni/testi_it.dart';
import 'package:traker_ia/ui/dialoghi.dart';

import 'servizi_finti.dart';

void main() {
  testWidgets('estensione: cartella pronta da sola, 2 tasti, 5 passi', (
    WidgetTester tester,
  ) async {
    final ServiziFinti f = ServiziFinti();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: DialogoEstensione(servizi: f)),
      ),
    );
    await tester.pumpAndSettle();
    expect(f.collegamenti, <String>['prepara']);
    expect(find.text('Firefox'), findsNothing);
    expect(
      find.text('1. ${Testi.passoPagina('brave://extensions')}'),
      findsOneWidget,
    );
    expect(find.text('4. ${Testi.passoTrascina}'), findsOneWidget);

    // Brave non trovato → avviso
    await tester.tap(find.text(Testi.apriPagina));
    await tester.pumpAndSettle();
    expect(f.collegamenti.last, 'estensione:brave');
    expect(
      find.text(Testi.browserNonTrovato('brave://extensions')),
      findsOneWidget,
    );

    // Edge trovato → niente avviso
    await tester.tap(find.text('Edge'));
    await tester.pumpAndSettle();
    expect(
      find.text('1. ${Testi.passoPagina('edge://extensions')}'),
      findsOneWidget,
    );
    await tester.tap(find.text(Testi.apriPagina));
    await tester.pumpAndSettle();
    expect(f.collegamenti.last, 'estensione:edge');
    expect(find.textContaining('Browser non trovato'), findsNothing);

    await tester.tap(find.text(Testi.apriCartella));
    await tester.pumpAndSettle();
    expect(f.collegamenti, <String>[
      'prepara',
      'estensione:brave',
      'estensione:edge',
      'cartella',
    ]);
  });
}
