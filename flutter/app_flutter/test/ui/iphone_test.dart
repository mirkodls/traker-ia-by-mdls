// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
//
// B23 iPhone: stessa schermata del telefono Android, ma sottofondo deciso
// da iPhone (niente scelta minuti) e una sola voce permessi.
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:traker_ia/domain/modelli.dart';
import 'package:traker_ia/domain/preferenze.dart';
import 'package:traker_ia/domain/sfondo.dart';
import 'package:traker_ia/domain/traduzioni/testi_it.dart';
import 'package:traker_ia/ui/app.dart';
import 'package:traker_ia/ui/stato_app.dart';

import 'servizi_finti.dart';

Future<({StatoApp stato, ServiziFinti f})> _apri(
  WidgetTester tester, {
  bool? batteria = true,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final ServiziFinti f = ServiziFinti()
    ..ios = true
    ..cookie = 'sk'
    ..batteria = batteria
    ..imp[Chiavi.permessiChiesti] = '1'
    ..risposte.add(const Uso(sett: 30, sess: 10));
  final StatoApp s = StatoApp(f, giri: false);
  await tester.runAsync(() async {
    await s.avvia();
    await s.leggi();
    await Future<void>.delayed(const Duration(milliseconds: 80));
  });
  await tester.pumpWidget(TrakerApp(stato: s));
  await tester.pump();
  return (stato: s, f: f);
}

void main() {
  test('iPhone = telefono (login nell\'app, sottofondo, sync client)', () {
    final ServiziFinti f = ServiziFinti()..ios = true;
    expect(f.telefono, isTrue);
    expect(f.iphone, isTrue);
    expect((ServiziFinti()..tel = true).iphone, isFalse);
  });

  test('testi batteria iPhone diversi da Android', () {
    expect(Testi.batteria(true, iphone: true), contains('background'));
    expect(Testi.batteria(false, iphone: true), contains('spento'));
    expect(Testi.batteria(null, iphone: true), contains('sconosciuto'));
    expect(Testi.batteria(true), startsWith('Batteria'));
  });

  testWidgets('iPhone: Impostazioni senza scelta minuti, spiegazione '
      'iPhone, niente overflow', (WidgetTester tester) async {
    await _apri(tester);
    await tester.tap(find.byTooltip(Testi.impostazioni));
    await tester.pumpAndSettle();
    await tester.tap(find.text(Testi.impostazioni));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('imp-sottofondo')),
      findsOneWidget,
    );
    expect(find.text(Testi.spiegaSfondoIphone), findsOneWidget);
    expect(find.text(Testi.campoMinutiSfondo), findsNothing);
    expect(find.text(Testi.spiegaSfondo), findsNothing);
    expect(find.text(Testi.batteria(true, iphone: true)), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('iPhone: Permessi = una voce, Apri = Impostazioni app', (
    WidgetTester tester,
  ) async {
    final ({StatoApp stato, ServiziFinti f}) a = await _apri(
      tester,
      batteria: false,
    );
    await tester.tap(find.byTooltip(Testi.impostazioni));
    await tester.pumpAndSettle();
    await tester.tap(find.text(Testi.menuPermessi));
    await tester.pumpAndSettle();
    expect(find.text(Testi.permessoIphone), findsOneWidget);
    expect(find.text(Testi.permessoSamsung), findsNothing);
    expect(find.text(Testi.permessoBatteria), findsNothing);
    expect(find.text(Testi.batteria(false, iphone: true)), findsOneWidget);
    await tester.runAsync(() async {
      await tester.tap(find.text(Testi.apri));
      await Future<void>.delayed(const Duration(milliseconds: 30));
    });
    await tester.pump();
    expect(a.f.permessi, <String>[Permesso.infoApp]);
    expect(tester.takeException(), isNull);
  });
}
