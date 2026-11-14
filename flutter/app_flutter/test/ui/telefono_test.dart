// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:traker_ia/domain/catena.dart';
import 'package:traker_ia/domain/modelli.dart';
import 'package:traker_ia/domain/preferenze.dart';
import 'package:traker_ia/domain/tempo.dart';
import 'package:traker_ia/domain/traduzioni/testi_it.dart';
import 'package:traker_ia/ui/app.dart';
import 'package:traker_ia/ui/stato_app.dart';

import 'servizi_finti.dart';

DateTime _t(String s) => interpreta(s)!;

void main() {
  late ServiziFinti f;
  StatoApp nuovo() =>
      StatoApp(f, orologio: () => _t('2026-11-14 12:00'), giri: false);

  setUp(() {
    f = ServiziFinti()..tel = true;
  });

  test('senza login: niente lettura, chiede il login, sfondo spento', () async {
    final StatoApp s = nuovo();
    await s.avvia();
    await s.leggi();
    expect(f.metodi, isEmpty);
    expect(s.stato, Testi.serveLogin);
    expect(s.statoErrore, isTrue);
    expect(f.sfondo.last, (10, false));
  });

  test('login nella pagina: cookie salvato, sfondo acceso, legge', () async {
    f.risposte.add(const Uso(sett: 30, sess: 5));
    final StatoApp s = nuovo();
    await s.avvia();
    await s.salvaLoginWeb('sk-ant-1');
    expect(f.cookie, 'sk-ant-1');
    expect(s.cookie, isTrue);
    expect(f.sfondo.last, (10, true));
    expect(f.lett.single.sett, 30);
  });

  test(
    '401: avviso "rifai login" subito, una volta; lettura ok lo toglie',
    () async {
      f
        ..cookie = 'vecchio'
        ..risposte.addAll(<Object>[
          const ErroreLettura('401', loginScaduto: true),
          const ErroreLettura('401', loginScaduto: true),
          const Uso(sett: 31),
        ]);
      final StatoApp s = nuovo();
      await s.avvia();
      await s.leggi();
      expect(s.avvisoDaMostrare, Testi.rifaiLogin);
      expect(s.loginScaduto, isTrue);
      expect(f.imp[Chiavi.loginScaduto], '1');
      s.avvisoVisto();
      await s.leggi();
      expect(s.avvisoDaMostrare, isNull);
      await s.leggi();
      expect(s.loginScaduto, isFalse);
      expect(f.imp[Chiavi.loginScaduto], '0');
    },
  );

  test('sottofondo ha trovato login scaduto: avviso all\'avvio', () async {
    f
      ..cookie = 'vecchio'
      ..imp[Chiavi.loginScaduto] = '1';
    final StatoApp s = nuovo();
    await s.avvia();
    expect(s.avvisoDaMostrare, Testi.rifaiLogin);
  });

  test('ritorno nell\'app: rilegge dati e batteria', () async {
    f.cookie = 'sk';
    final StatoApp s = nuovo();
    await s.avvia();
    expect(s.batteriaLibera, isNull);
    f
      ..lett.add(Lettura(ora: _t('2026-11-14 11:50'), sett: 33))
      ..batteria = true;
    await s.riprendi();
    expect(f.cacheButtate, 1);
    expect(s.letture, hasLength(1));
    expect(s.batteriaLibera, isTrue);
  });

  test('PC: niente sfondo, niente batteria', () async {
    f.tel = false;
    await nuovo().avvia();
    expect(f.sfondo, isEmpty);
  });

  testWidgets('telefono 360x780: impostazioni con login e batteria', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    f
      ..batteria = false
      ..risposte.add(const Uso(sett: 25, sess: 9));
    final StatoApp s = nuovo();
    await tester.runAsync(s.avvia);
    await tester.pumpWidget(TrakerApp(stato: s));
    await tester.pump();
    await tester.ensureVisible(find.text(Testi.impostazioni));
    await tester.tap(find.text(Testi.impostazioni));
    await tester.pumpAndSettle();
    expect(find.text(Testi.accedi('Claude')), findsOneWidget);
    expect(find.text(Testi.batteria(false)), findsOneWidget);
    expect(find.text(Testi.apriInfoApp), findsOneWidget);
    expect(find.text(Testi.campoCartella), findsNothing);
    expect(find.text(Testi.installaEstensione), findsNothing);
    await tester.ensureVisible(find.text(Testi.apriInfoApp));
    await tester.tap(find.text(Testi.apriInfoApp));
    await tester.pump();
    expect(f.infoApp, 1);
    expect(tester.takeException(), isNull);
  });
}
