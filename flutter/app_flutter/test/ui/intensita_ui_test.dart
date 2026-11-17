// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:traker_ia/domain/analisi.dart';
import 'package:traker_ia/domain/coppie.dart';
import 'package:traker_ia/domain/intensita.dart';
import 'package:traker_ia/domain/modelli.dart';
import 'package:traker_ia/domain/preferenze.dart';
import 'package:traker_ia/domain/serie_intensita.dart';
import 'package:traker_ia/domain/tempo.dart';
import 'package:traker_ia/domain/traduzioni/testi_it.dart';
import 'package:traker_ia/domain/vista.dart';
import 'package:traker_ia/ui/app.dart';
import 'package:traker_ia/ui/barra_intensita.dart';
import 'package:traker_ia/ui/grafico.dart';
import 'package:traker_ia/ui/grafico_dati.dart';
import 'package:traker_ia/ui/stato_app.dart';

import 'servizi_finti.dart';

DateTime _t(String s) => interpreta(s)!;

/// Ven 13/11/2026 11:00. 07:00-09:00 barra 5h (6 pt/h); 09:10-11:00 solo
/// settimanale (2 pt/h): il grafico ha tutte e due le fonti.
Future<({StatoApp stato, ServiziFinti f})> _apri(
  WidgetTester tester,
  Size taglia, {
  double dpr = 1,
  bool v2 = true,
}) async {
  tester.view.physicalSize = taglia * dpr;
  tester.view.devicePixelRatio = dpr;
  addTearDown(tester.view.reset);
  final ServiziFinti f = ServiziFinti()
    ..risposte.add(const Uso(sett: 28, sess: 13));
  if (!v2) {
    f.imp[Chiavi.v2Lavoro] = '0';
  }
  final DateTime base = _t('2026-11-13 07:00');
  for (int i = 0; i <= 24; i++) {
    f.lett.add(
      Lettura(
        ora: base.add(Duration(minutes: 10 * i)),
        sett: 20.0 + i ~/ 3,
        sess: i <= 12 ? 1.0 + i : null,
      ),
    );
  }
  f.ev.add(Evento(ora: _t('2026-11-13 07:30'), tipo: TipoEvento.inizio));
  f.ev.add(Evento(ora: _t('2026-11-13 08:30'), tipo: TipoEvento.fine));
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

void _disegna(CustomPainter p, Size s) {
  final ui.PictureRecorder rec = ui.PictureRecorder();
  p.paint(Canvas(rec), s);
  rec.endRecording().dispose();
}

Future<void> _tocca(WidgetTester tester, Finder fi) async {
  await tester.ensureVisible(fi);
  await tester.runAsync(() async {
    await tester.tap(fi);
    await Future<void>.delayed(const Duration(milliseconds: 20));
  });
  await tester.pump();
}

void main() {
  testWidgets('barra intensità: nessun errore di spazio (420x500, 1300x950)', (
    WidgetTester tester,
  ) async {
    for (final Size s in const <Size>[Size(420, 500), Size(1300, 950)]) {
      await _apri(tester, s);
      expect(find.byType(BarraIntensita), findsOneWidget);
      for (final int n in finestrePostuma) {
        expect(find.byKey(ValueKey<String>('postuma-$n')), findsOneWidget);
      }
      expect(
        find.byKey(const ValueKey<String>('solo-lavoro-int')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('medie-intensita')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('modo solo intensità 420x500: niente errori di spazio', (
    WidgetTester tester,
  ) async {
    final ({StatoApp stato, ServiziFinti f}) a = await _apri(
      tester,
      const Size(420, 500),
    );
    await tester.runAsync(() => a.stato.scegliModo(ModoVista.intensita));
    await tester.pump();
    expect(find.byType(BarraIntensita), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('v2_lavoro=0: intensità vecchia, nessuna barra', (
    WidgetTester tester,
  ) async {
    final ({StatoApp stato, ServiziFinti f}) a = await _apri(
      tester,
      const Size(1300, 950),
      v2: false,
    );
    expect(find.byType(BarraIntensita), findsNothing);
    expect(a.stato.grafico!.intensitaV2, isNull);
    expect(a.stato.calcoliIntensita, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('dati: serie V2 con tutte e due le fonti, medie in barra', (
    WidgetTester tester,
  ) async {
    final ({StatoApp stato, ServiziFinti f}) a = await _apri(
      tester,
      const Size(1300, 950),
    );
    final IntensitaV2 v = a.stato.grafico!.intensitaV2!;
    expect(v.stat.n5h, greaterThan(0));
    expect(v.stat.n7gg, greaterThan(0));
    final Text medie = tester.widget<Text>(
      find.byKey(const ValueKey<String>('medie-intensita')),
    );
    expect(medie.data, contains('~'));
    expect(medie.data, contains('±'));
    expect(medie.data, contains('pt sess/h'));
    expect(medie.data, contains('pt sett/h'));
    expect(medie.data, isNot(contains('solo Lavoro')));
  });

  testWidgets('scelta N: salvata, ricalcolo 1 sola volta, valore ammesso', (
    WidgetTester tester,
  ) async {
    final ({StatoApp stato, ServiziFinti f}) a = await _apri(
      tester,
      const Size(1300, 950),
    );
    expect(a.stato.preferenze.finestraPostuma, 60);
    final int c0 = a.stato.calcoliIntensita;
    await _tocca(tester, find.byKey(const ValueKey<String>('postuma-120')));
    expect(a.f.imp[Chiavi.v2FinestraPostuma], '120');
    expect(a.stato.grafico!.intensitaV2!.finestraPostumaMin, 120);
    expect(a.stato.calcoliIntensita, c0 + 1);
    await _tocca(tester, find.byKey(const ValueKey<String>('postuma-30')));
    expect(a.f.imp[Chiavi.v2FinestraPostuma], '30');
    // valore non ammesso -> 60
    await tester.runAsync(() => a.stato.cambiaFinestraPostuma(45));
    expect(a.stato.preferenze.finestraPostuma, 60);
    expect(tester.takeException(), isNull);
  });

  testWidgets('solo Lavoro: casella salvata, medie con "(solo Lavoro)"', (
    WidgetTester tester,
  ) async {
    final ({StatoApp stato, ServiziFinti f}) a = await _apri(
      tester,
      const Size(1300, 950),
    );
    await _tocca(tester, find.byKey(const ValueKey<String>('solo-lavoro-int')));
    expect(a.f.imp[Chiavi.soloLavoro], '1');
    expect(a.stato.grafico!.intensitaV2!.soloLavoro, isTrue);
    final Text medie = tester.widget<Text>(
      find.byKey(const ValueKey<String>('medie-intensita')),
    );
    expect(medie.data, contains(Testi.soloLavoroSuffisso));
  });

  testWidgets('ricalcolo senza dati nuovi: serie intensità non rifatta', (
    WidgetTester tester,
  ) async {
    final ({StatoApp stato, ServiziFinti f}) a = await _apri(
      tester,
      const Size(1300, 950),
    );
    final int c0 = a.stato.calcoliIntensita;
    expect(c0, 1);
    await tester.runAsync(() => a.stato.cambiaGiornoPiano(3));
    await tester.runAsync(() => a.stato.cambiaLineaIdeale(acceso: false));
    expect(a.stato.calcoliIntensita, c0);
  });

  testWidgets('tasto Lavoro: spiegazione breve e nota-comando', (
    WidgetTester tester,
  ) async {
    final ({StatoApp stato, ServiziFinti f}) a = await _apri(
      tester,
      const Size(1300, 950),
    );
    expect(
      find.byWidgetPredicate(
        (Widget w) => w is Tooltip && w.message == Testi.spiegaLavoro,
      ),
      findsOneWidget,
    );
    expect(a.stato.lavoro, isFalse);
    final int ev0 = a.f.ev.length;
    await tester.runAsync(() => a.stato.aggiungiNota('Lavoro'));
    expect(a.stato.lavoro, isTrue);
    expect(a.f.ev.length, ev0 + 1);
    expect(a.f.ev.last.tipo, TipoEvento.inizio);
    // già in Lavoro: ripetere non fa niente
    await tester.runAsync(() => a.stato.aggiungiNota('lavoro'));
    expect(a.f.ev.length, ev0 + 1);
    await tester.runAsync(() => a.stato.aggiungiNota('Fine lavoro.'));
    expect(a.stato.lavoro, isFalse);
    expect(a.f.ev.last.tipo, TipoEvento.fine);
    // fine senza lavoro aperto: niente
    await tester.runAsync(() => a.stato.aggiungiNota('fine lavoro'));
    expect(a.f.ev.length, ev0 + 2);
    // nota normale: resta nota, non cambia Lavoro
    await tester.runAsync(() => a.stato.aggiungiNota('lavoro su excel'));
    expect(a.f.ev.last.tipo, TipoEvento.nota);
    expect(a.stato.lavoro, isFalse);
    // le note-comando non entrano tra le note
    expect(a.f.ev.where((Evento e) => e.tipo == TipoEvento.nota).length, 1);
  });

  testWidgets('disegno intensità V2: dpr 1/2, 4 misure, con e senza banda', (
    WidgetTester tester,
  ) async {
    final ({StatoApp stato, ServiziFinti f}) a = await _apri(
      tester,
      const Size(1300, 950),
    );
    final DatiGrafico d = a.stato.grafico!;
    expect(d.fasce, isNotEmpty);
    for (final double dpr in const <double>[1, 1.25, 2]) {
      for (final Size s in const <Size>[
        Size(1200, 150),
        Size(420, 100),
        Size(200, 90),
        Size(60, 40),
      ]) {
        _disegna(PittoreIntensita(d, dpr: dpr), s);
      }
    }
    // serie vuota e solo buchi: nessuna eccezione
    final DatiGrafico vuoto = DatiGrafico(
      da: d.da,
      a: d.a,
      sett: d.sett,
      sess: d.sess,
      reset: d.reset,
      fasce: const <Periodo>[],
      note: d.note,
      intensita: const <PuntoSerie>[],
      maxIntensita: 1,
      intensitaV2: IntensitaV2.vuota(),
    );
    _disegna(PittoreIntensita(vuoto), const Size(800, 120));
    expect(tester.takeException(), isNull);
  });

  testWidgets('shouldRepaint mirato: stessi dati = niente ridisegno', (
    WidgetTester tester,
  ) async {
    final ({StatoApp stato, ServiziFinti f}) a = await _apri(
      tester,
      const Size(1300, 950),
    );
    final DatiGrafico d = a.stato.grafico!;
    final PittoreIntensita p = PittoreIntensita(d);
    expect(p.shouldRepaint(PittoreIntensita(d)), isFalse);
    expect(p.shouldRepaint(PittoreIntensita(d, dpr: 2)), isTrue);
  });

  testWidgets('riquadro mouse V2: stima con ~ e ±, unità della fonte', (
    WidgetTester tester,
  ) async {
    final ({StatoApp stato, ServiziFinti f}) a = await _apri(
      tester,
      const Size(1300, 950),
    );
    final IntensitaV2 v = a.stato.grafico!.intensitaV2!;
    final String t5 = testoMouse(
      a.stato.letture,
      _t('2026-11-13 08:00'),
      v2: v,
    );
    expect(t5, contains('${Testi.rqIntensita}: ~'));
    expect(t5, contains('±'));
    expect(t5, contains('pt sess/h'));
    final String t7 = testoMouse(
      a.stato.letture,
      _t('2026-11-13 10:30'),
      v2: v,
    );
    expect(t7, contains('pt sett/h'));
    // fuori dai dati: trattino, mai un valore inventato
    final String fuori = testoMouse(
      a.stato.letture,
      _t('2026-11-18 10:30'),
      v2: v,
    );
    expect(fuori, contains('${Testi.rqIntensita}: ${Testi.trattino}'));
  });

  test('testoMedie: nessuna media, solo 5h, errore decimale', () {
    expect(
      testoMedie(const StatIntensita(), soloLavoro: false),
      Testi.nessunaMedia,
    );
    final String s = testoMedie(
      const StatIntensita(media5h: 12.4, errore5h: 2.2, n5h: 3),
      soloLavoro: true,
    );
    expect(s, contains('~12 ±2 pt sess/h'));
    expect(s, isNot(contains('sett')));
    expect(s, endsWith(Testi.soloLavoroSuffisso));
    final String d = testoMedie(
      const StatIntensita(media7gg: 1.26, errore7gg: 0.5, n7gg: 3),
      soloLavoro: false,
    );
    expect(d, contains('~1,3 ±0,5 pt sett/h'));
  });

  test('preferenze: finestra postuma salvata, rotta -> 60', () {
    expect(Preferenze().finestraPostuma, 60);
    expect(
      Preferenze.daMappa(<String, String?>{Chiavi.v2FinestraPostuma: '120'})
          .finestraPostuma,
      120,
    );
    expect(
      Preferenze.daMappa(<String, String?>{Chiavi.v2FinestraPostuma: 'x'})
          .finestraPostuma,
      60,
    );
    expect(
      Preferenze.daMappa(<String, String?>{Chiavi.v2FinestraPostuma: '45'})
          .finestraPostuma,
      60,
    );
    expect(
      Preferenze()
          .copia(finestraPostuma: 30)
          .aMappa()[Chiavi.v2FinestraPostuma],
      '30',
    );
    expect(Chiavi.tutte, contains(Chiavi.v2FinestraPostuma));
  });
}
