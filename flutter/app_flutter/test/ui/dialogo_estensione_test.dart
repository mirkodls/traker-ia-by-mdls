// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:traker_ia/domain/traduzioni/testi_it.dart';
import 'package:traker_ia/ui/dialoghi.dart';

import 'servizi_finti.dart';

void main() {
  testWidgets('estensione: scegli browser → cartella, pagina, passi', (
    WidgetTester tester,
  ) async {
    final List<String> appunti = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (MethodCall c) async {
        if (c.method == 'Clipboard.setData') {
          appunti.add('${(c.arguments as Map<Object?, Object?>)['text']}');
        }
        return null;
      },
    );
    final ServiziFinti f = ServiziFinti();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: DialogoEstensione(servizi: f)),
      ),
    );
    expect(find.text(Testi.firefoxInArrivo), findsOneWidget);

    await tester.tap(find.text('Edge'));
    await tester.pumpAndSettle();
    expect(f.collegamenti, <String>['prepara', 'estensione:edge', 'cartella']);
    expect(appunti, <String>[r'C:\Doc\TraKer IA by mdls\estensioni\chromium']);
    expect(
      find.textContaining('Si è aperta la pagina estensioni di Edge'),
      findsOneWidget,
    );
    expect(find.textContaining('Carica decompressa'), findsOneWidget);

    await tester.tap(find.text('Brave'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining(
        'scrivi nella barra degli indirizzi: brave://extensions',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Firefox'));
    await tester.pumpAndSettle();
    expect(f.collegamenti.where((String c) => c.contains('firefox')), isEmpty);
  });
}
