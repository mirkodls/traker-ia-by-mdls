// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:traker_ia/domain/catena.dart';
import 'package:traker_ia/domain/modelli.dart';
import 'package:traker_ia/domain/preferenze.dart';
import 'package:traker_ia/domain/sfondo.dart';
import 'package:traker_ia/domain/tempo.dart';
import 'package:traker_ia/domain/traduzioni/testi_it.dart';
import 'package:traker_ia/ui/app.dart';
import 'package:traker_ia/ui/stato_app.dart';

import 'aiuti_impostazioni.dart';
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
    expect(f.sfondo.last, (30, false));
  });

  test('login nella pagina: cookie salvato, sfondo acceso, legge', () async {
    f.risposte.add(const Uso(sett: 30, sess: 5));
    final StatoApp s = nuovo();
    await s.avvia();
    await s.salvaLoginWeb('sk-ant-1');
    expect(f.cookie, 'sk-ant-1');
    expect(s.cookie, isTrue);
    expect(f.sfondo.last, (30, true));
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

  test('primo avvio telefono: pagina permessi una volta sola', () async {
    final StatoApp s = nuovo();
    await s.avvia();
    expect(s.permessiDaMostrare, isTrue);
    expect(f.imp[Chiavi.permessiChiesti], '1');
    s.permessiVisti();
    final StatoApp s2 = nuovo();
    await s2.avvia();
    expect(s2.permessiDaMostrare, isFalse);
  });

  test('interruttore Sottofondo: spento = lavoro tolto, salvato', () async {
    f
      ..cookie = 'sk'
      ..imp[Chiavi.permessiChiesti] = '1'
      ..batteria = true;
    final StatoApp s = nuovo();
    await s.avvia();
    expect(f.sfondo.last, (30, true));
    await s.cambiaSfondo(acceso: false);
    expect(f.sfondo.last, (30, false));
    expect(f.imp[Chiavi.sfondoAcceso], '0');
    expect(s.permessiDaMostrare, isFalse);
    await s.cambiaMinutiSfondo(60);
    expect(f.sfondo.last, (60, false));
    await s.cambiaSfondo(acceso: true);
    expect(f.sfondo.last, (60, true));
  });

  test('Sottofondo acceso con batteria limitata: apre i permessi', () async {
    f
      ..cookie = 'sk'
      ..imp[Chiavi.permessiChiesti] = '1'
      ..imp[Chiavi.sfondoAcceso] = '0'
      ..batteria = false;
    final StatoApp s = nuovo();
    await s.avvia();
    expect(s.permessiDaMostrare, isFalse);
    await s.cambiaSfondo(acceso: true);
    expect(s.permessiDaMostrare, isTrue);
  });

  testWidgets('telefono: riga Sottofondo con stima, tocco spegne', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    f
      ..cookie = 'sk'
      ..imp[Chiavi.permessiChiesti] = '1'
      ..batteria = true;
    final StatoApp s = nuovo();
    await tester.runAsync(s.avvia);
    await tester.pumpWidget(TrakerApp(stato: s));
    await tester.pump();
    expect(
      find.text(Testi.rigaSottofondo(acceso: true, login: true, minuti: 30)),
      findsOneWidget,
    );
    await tester.tap(find.byType(Switch));
    await tester.pump();
    await tester.pump();
    expect(f.sfondo.last, (30, false));
    expect(tester.takeException(), isNull);
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
    // Telefono: tutto in una schermata, rotella ⚙ → menu → Impostazioni.
    expect(find.text(Testi.letturaManuale), findsNothing);
    expect(find.text(Testi.aiutoZoom), findsOneWidget);
    expect(find.byType(InteractiveViewer), findsOneWidget);
    await tester.tap(find.byTooltip(Testi.impostazioni));
    await tester.pumpAndSettle();
    await tester.tap(find.text(Testi.impostazioni));
    await tester.pumpAndSettle();
    // Generale: batteria; Accesso: login; Grafico sì; IA no (solo PC).
    expect(find.text(Testi.batteria(false)), findsOneWidget);
    expect(find.text(Testi.sceltaMinutiSfondo(30)), findsOneWidget);
    expect(find.text(Testi.schedaGrafico), findsOneWidget);
    expect(find.text(Testi.titoloIA), findsNothing);
    await tester.ensureVisible(find.text(Testi.titoloPermessi));
    await tester.tap(find.text(Testi.titoloPermessi));
    await tester.pumpAndSettle();
    await tester.tap(find.text(Testi.consenti));
    await tester.pump();
    expect(f.permessi, <String>[Permesso.batteria]);
    await tester.tap(find.text(Testi.fatto));
    await tester.pumpAndSettle();
    await apriScheda(tester, Testi.schedaAccesso);
    expect(find.text(Testi.accedi('Claude')), findsOneWidget);
    expect(find.text(Testi.campoCartella), findsNothing);
    expect(find.text(Testi.installaEstensione), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('telefono: tasti fermi, ordine da ⚙ > Modifica modelli', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    f
      ..cookie = 'sk'
      ..imp[Chiavi.v2ModelliSkill] = '1';
    final StatoApp s = nuovo();
    await tester.runAsync(s.avvia);
    await tester.pumpWidget(TrakerApp(stato: s));
    await tester.pump();
    expect(find.byType(Draggable<(Gruppo, String)>), findsNothing);
    final List<String> prima = s.preferenze.elenco(Gruppo.modelli);
    await tester.tap(find.byTooltip(Testi.impostazioni));
    await tester.pumpAndSettle();
    await tester.tap(
      find.text(Testi.titoloModifica(Testi.gruppoModelli.toLowerCase())),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, prima[1]));
    await tester.pump();
    await tester.ensureVisible(find.text(Testi.su));
    await tester.tap(find.text(Testi.su));
    await tester.pumpAndSettle();
    expect(s.preferenze.elenco(Gruppo.modelli).first, prima[1]);
    expect(tester.takeException(), isNull);
  });

  test('PC: a ogni lettura riprende i dati Python nuovi', () async {
    f
      ..tel = false
      ..imp[Chiavi.cartellaImport] = 'C:/vecchi'
      ..imp[Chiavi.importFatto] = '1'
      ..risposte.addAll(<Object>[const Uso(sett: 1), const Uso(sett: 2)]);
    final StatoApp s = nuovo();
    await s.avvia();
    f.daImportare.add(Lettura(ora: _t('2026-11-14 11:00'), sett: 9));
    await s.leggi();
    expect(f.importate, <String>['C:/vecchi']);
    expect(s.letture.any((Lettura l) => l.sett == 9), isTrue);
    f.daImportare.clear();
    await s.leggi();
    expect(f.importate, hasLength(2));
  });

  test('telefono: niente import Python', () async {
    f
      ..cookie = 'sk'
      ..imp[Chiavi.cartellaImport] = 'C:/vecchi'
      ..imp[Chiavi.importFatto] = '1'
      ..risposte.add(const Uso(sett: 1));
    final StatoApp s = nuovo();
    await s.avvia();
    await s.leggi();
    expect(f.importate, isEmpty);
  });
}
