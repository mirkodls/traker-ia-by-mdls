// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:traker_ia/domain/modelli.dart';
import 'package:traker_ia/domain/piani_progetti.dart';
import 'package:traker_ia/domain/piano_giorni.dart';
import 'package:traker_ia/domain/preferenze.dart';
import 'package:traker_ia/domain/tempo.dart';
import 'package:traker_ia/domain/vista.dart';
import 'package:traker_ia/ui/app.dart';
import 'package:traker_ia/ui/barra_piano.dart';
import 'package:traker_ia/ui/grafico.dart';
import 'package:traker_ia/ui/grafico_dati.dart';
import 'package:traker_ia/ui/stato_app.dart';

import 'servizi_finti.dart';

DateTime _t(String s) => interpreta(s)!;

/// Ven 13/11/2026 11:00; la settimana parte mar 10/11 20:00.
Future<({StatoApp stato, ServiziFinti f})> _apri(
  WidgetTester tester,
  Size taglia, {
  double dpr = 1,
}) async {
  tester.view.physicalSize = taglia * dpr;
  tester.view.devicePixelRatio = dpr;
  addTearDown(tester.view.reset);
  final ServiziFinti f = ServiziFinti()
    ..risposte.add(const Uso(sett: 25, sess: 9));
  f.lett.addAll(<Lettura>[
    Lettura(ora: _t('2026-11-11 08:00'), sett: 5, sess: 3),
    Lettura(ora: _t('2026-11-12 10:00'), sett: 18, sess: 8),
    Lettura(ora: _t('2026-11-13 10:00'), sett: 23, sess: 8),
  ]);
  f.ev.add(
    Evento(ora: _t('2026-11-12 09:00'), tipo: TipoEvento.nota, testo: 'prova'),
  );
  final StatoApp s = StatoApp(
    f,
    orologio: () => _t('2026-11-13 11:00'),
    giri: false,
  );
  await tester.runAsync(s.avvia);
  await tester.pumpWidget(TrakerApp(stato: s));
  await tester.pump();
  return (stato: s, f: f);
}

/// Disegna [p] su una tela finta (come farebbe Flutter).
void _disegna(CustomPainter p, Size s) {
  final ui.PictureRecorder rec = ui.PictureRecorder();
  p.paint(Canvas(rec), s);
  rec.endRecording().dispose();
}

void main() {
  testWidgets('barra piano: nessun errore di spazio (420x500, 1300x950)', (
    WidgetTester tester,
  ) async {
    for (final Size s in const <Size>[Size(420, 500), Size(1300, 950)]) {
      await _apri(tester, s);
      expect(find.byType(BarraPiano), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('giorno-1')), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('giorno-7')), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('primi-7')), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('linea-ideale')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('modo solo grafico 420x500: niente errori di spazio', (
    WidgetTester tester,
  ) async {
    final ({StatoApp stato, ServiziFinti f}) a = await _apri(
      tester,
      const Size(420, 500),
    );
    await tester.runAsync(() => a.stato.scegliModo(ModoVista.grafico));
    await tester.pump();
    expect(find.byType(BarraPiano), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('piano spento (v2_lavoro=0): niente barra, niente piano', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1300, 950);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final ServiziFinti f = ServiziFinti()
      ..risposte.add(const Uso(sett: 25, sess: 9));
    f.imp[Chiavi.v2Lavoro] = '0';
    f.lett.add(Lettura(ora: _t('2026-11-13 10:00'), sett: 23, sess: 8));
    final StatoApp s = StatoApp(
      f,
      orologio: () => _t('2026-11-13 11:00'),
      giri: false,
    );
    await tester.runAsync(s.avvia);
    await tester.pumpWidget(TrakerApp(stato: s));
    await tester.pump();
    expect(find.byType(BarraPiano), findsNothing);
    expect(s.grafico!.piano, isNull);
    // asse come prima: fino ad adesso
    expect(s.grafico!.a, _t('2026-11-13 11:00'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('giorni: tocco giorno e scorciatoia, salvati e nel grafico', (
    WidgetTester tester,
  ) async {
    final ({StatoApp stato, ServiziFinti f}) a = await _apri(
      tester,
      const Size(1300, 950),
    );
    final Finder mar = find.byKey(const ValueKey<String>('giorno-2'));
    await tester.ensureVisible(mar);
    await tester.runAsync(() async {
      await tester.tap(mar);
      await Future<void>.delayed(const Duration(milliseconds: 20));
    });
    await tester.pump();
    expect(a.f.imp[Chiavi.v2PianoGiorni], '${tuttiIGiorni & ~(1 << 1)}');
    expect(a.stato.grafico!.piano!.fette[0].lavoro, isFalse); // martedì spento

    final Finder primi3 = find.byKey(const ValueKey<String>('primi-3'));
    await tester.ensureVisible(primi3);
    await tester.runAsync(() async {
      await tester.tap(primi3);
      await Future<void>.delayed(const Duration(milliseconds: 20));
    });
    await tester.pump();
    expect(a.f.imp[Chiavi.v2PianoGiorni], '${mascheraPrimiGiorni(3)}');
    // ideale si ferma a fine 3° giorno: ven 13/11 20:00
    expect(a.stato.grafico!.piano!.ideale.last.ora, _t('2026-11-13 20:00'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('interruttori linee: salvati, la barra li mostra', (
    WidgetTester tester,
  ) async {
    final ({StatoApp stato, ServiziFinti f}) a = await _apri(
      tester,
      const Size(1300, 950),
    );
    final Finder ide = find.byKey(const ValueKey<String>('linea-ideale'));
    await tester.ensureVisible(ide);
    await tester.runAsync(() async {
      await tester.tap(ide);
      await Future<void>.delayed(const Duration(milliseconds: 20));
    });
    await tester.pump();
    expect(a.f.imp[Chiavi.v2LineaIdeale], '0');
    expect(a.stato.preferenze.lineaIdeale, isFalse);
    expect(a.stato.preferenze.lineaAdattiva, isTrue);
    final Finder ada = find.byKey(const ValueKey<String>('linea-adattiva'));
    await tester.runAsync(() async {
      await tester.tap(ada);
      await Future<void>.delayed(const Duration(milliseconds: 20));
    });
    await tester.pump();
    expect(a.f.imp[Chiavi.v2LineaAdattiva], '0');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'asse: "Settimana" = tutta la settimana; altri periodi invariati',
    (WidgetTester tester) async {
      final ({StatoApp stato, ServiziFinti f}) a = await _apri(
        tester,
        const Size(1300, 950),
      );
      expect(a.stato.grafico!.da, _t('2026-11-10 20:00'));
      expect(a.stato.grafico!.a, _t('2026-11-17 20:00'));
      await tester.runAsync(() => a.stato.cambiaPeriodo(1)); // 6 ore
      expect(a.stato.grafico!.a, _t('2026-11-13 11:00'));
      expect(a.stato.grafico!.piano, isNotNull);
    },
  );

  testWidgets('cache: serie ricalcolate solo se cambiano dati o impostazioni', (
    WidgetTester tester,
  ) async {
    final ({StatoApp stato, ServiziFinti f}) a = await _apri(
      tester,
      const Size(1300, 950),
    );
    final StatoApp s = a.stato;
    expect(s.calcoliPiano, 1);
    final DatiGrafico d0 = s.grafico!;
    // ricalcoli senza cambio dati/piano: stessa serie (oggetto identico)
    await tester.runAsync(() => s.cambiaSoloLavoro(acceso: true));
    await tester.runAsync(() => s.cambiaPeriodo(5));
    expect(s.calcoliPiano, 1);
    expect(identical(s.grafico!.piano, d0.piano), isTrue);
    // giorni cambiati -> 1 ricalcolo
    await tester.runAsync(() => s.cambiaGiornoPiano(4));
    expect(s.calcoliPiano, 2);
    // interruttori = solo disegno: nessun ricalcolo
    await tester.runAsync(() => s.cambiaLineaIdeale(acceso: false));
    await tester.runAsync(() => s.cambiaLineaAdattiva(acceso: false));
    expect(s.calcoliPiano, 2);
    // nuova lettura -> 1 ricalcolo
    await tester.runAsync(
      () => s.aggiungiManuale(_t('2026-11-13 10:30'), 30, 10),
    );
    expect(s.calcoliPiano, 3);
  });

  testWidgets('paint non ricalcola e non cambia le serie', (
    WidgetTester tester,
  ) async {
    final ({StatoApp stato, ServiziFinti f}) a = await _apri(
      tester,
      const Size(1300, 950),
    );
    final StatoApp s = a.stato;
    final DatiGrafico d = s.grafico!;
    final int calcoli = s.calcoliPiano;
    final int nIdeale = d.piano!.ideale.length;
    final PittorePrincipale p = PittorePrincipale(
      d,
      mostraIdeale: true,
      mostraAdattiva: true,
    );
    for (int i = 0; i < 5; i++) {
      _disegna(p, const Size(900, 400));
    }
    expect(s.calcoliPiano, calcoli);
    expect(d.piano!.ideale.length, nIdeale);
  });

  test('shouldRepaint mirato: solo se cambiano dati, linee o scala', () {
    final DatiGrafico d = calcolaDatiGrafico(
      <Lettura>[],
      <Evento>[],
      _t('2026-11-10 20:00'),
      _t('2026-11-17 20:00'),
      _t('2026-11-13 11:00'),
    );
    final PittorePrincipale base = PittorePrincipale(d);
    expect(PittorePrincipale(d).shouldRepaint(base), isFalse);
    expect(
      PittorePrincipale(d, mostraIdeale: true).shouldRepaint(base),
      isTrue,
    );
    expect(
      PittorePrincipale(d, mostraAdattiva: true).shouldRepaint(base),
      isTrue,
    );
    expect(PittorePrincipale(d, dpr: 2).shouldRepaint(base), isTrue);
    final DatiGrafico d2 = calcolaDatiGrafico(
      <Lettura>[],
      <Evento>[],
      _t('2026-11-10 20:00'),
      _t('2026-11-17 20:00'),
      _t('2026-11-13 11:00'),
    );
    expect(PittorePrincipale(d2).shouldRepaint(base), isTrue);
    final PittoreIntensita i = PittoreIntensita(d);
    expect(PittoreIntensita(d).shouldRepaint(i), isFalse);
    expect(PittoreIntensita(d, dpr: 2).shouldRepaint(i), isTrue);
  });

  testWidgets('disegno con ogni combinazione di scala, linee e misure', (
    WidgetTester tester,
  ) async {
    final ({StatoApp stato, ServiziFinti f}) a = await _apri(
      tester,
      const Size(1300, 950),
    );
    final DatiGrafico d = a.stato.grafico!;
    for (final double dpr in <double>[1, 1.25, 2, 3]) {
      for (final bool i in <bool>[true, false]) {
        for (final bool ad in <bool>[true, false]) {
          for (final Size s in const <Size>[
            Size(1200, 500),
            Size(420, 300),
            Size(120, 90),
            Size(30, 20),
          ]) {
            _disegna(
              PittorePrincipale(
                d,
                mostraIdeale: i,
                mostraAdattiva: ad,
                dpr: dpr,
              ),
              s,
            );
            _disegna(PittoreIntensita(d, dpr: dpr), s);
          }
        }
      }
    }
    // anche su "Tutto" (molte settimane) e su periodo corto
    for (final int scatto in <int>[0, 3, 6, 7]) {
      await tester.runAsync(() => a.stato.cambiaPeriodo(scatto));
      _disegna(
        PittorePrincipale(
          a.stato.grafico!,
          mostraIdeale: true,
          mostraAdattiva: true,
          dpr: 2,
        ),
        const Size(900, 400),
      );
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('schermo ad alta densità (x2): nessun errore', (
    WidgetTester tester,
  ) async {
    await _apri(tester, const Size(900, 700), dpr: 2);
    expect(find.byType(Grafico), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  test('intensità: punti fitti, 1 ogni 5 min fino a ~1500', () {
    final DateTime da = _t('2026-11-10 20:00');
    expect(passoIntensita(da, da.add(const Duration(hours: 6))), 5);
    expect(passoIntensita(da, da.add(const Duration(days: 7))), 6);
    final int p = passoIntensita(da, da.add(const Duration(days: 30)));
    expect(
      (30 * 24 * 60 / p).ceil(),
      lessThanOrEqualTo(maxPuntiIntensita + 100),
    );
  });
}
