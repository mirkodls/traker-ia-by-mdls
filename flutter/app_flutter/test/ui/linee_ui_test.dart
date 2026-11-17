// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:traker_ia/domain/modelli.dart';
import 'package:traker_ia/domain/preferenze.dart';
import 'package:traker_ia/domain/stile_linee.dart';
import 'package:traker_ia/domain/tempo.dart';
import 'package:traker_ia/domain/traduzioni/testi_it.dart';
import 'package:traker_ia/ui/app.dart';
import 'package:traker_ia/ui/grafico.dart';
import 'package:traker_ia/ui/grafico_dati.dart';
import 'package:traker_ia/ui/stato_app.dart';
import 'package:traker_ia/ui/tema.dart';

import 'servizi_finti.dart';

DateTime _t(String s) => interpreta(s)!;

/// Ven 13/11/2026 11:00, settimana dal 10/11 20:00, piano 7 giorni: la
/// settimana sta sopra la soglia del giorno (rosso).
Future<({StatoApp stato, ServiziFinti f})> _apri(
  WidgetTester tester,
  Size taglia, {
  bool lavoro = true,
}) async {
  tester.view.physicalSize = taglia;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final ServiziFinti f = ServiziFinti()
    ..risposte.add(const Uso(sett: 52, sess: 9));
  if (!lavoro) {
    f.imp[Chiavi.v2Lavoro] = '0';
  }
  f.lett.addAll(<Lettura>[
    Lettura(ora: _t('2026-11-10 21:00'), sett: 2, sess: 1),
    Lettura(ora: _t('2026-11-11 08:00'), sett: 40, sess: 3),
    Lettura(ora: _t('2026-11-12 10:00'), sett: 45, sess: 8),
    Lettura(ora: _t('2026-11-13 10:00'), sett: 51, sess: 8),
  ]);
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

Future<void> _apriImpostazioni(WidgetTester tester) async {
  await tester.tap(find.text(Testi.impostazioni));
  await tester.pumpAndSettle();
}

Future<void> _spostaCursore(
  WidgetTester tester,
  String chiave,
  double dx,
) async {
  final Finder f = find.byKey(Key(chiave));
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.drag(f, Offset(dx, 0));
  await tester.pumpAndSettle();
}

/// Disegna il pittore in un'immagine e conta i pixel quasi uguali a [c].
Future<int> _pixel(
  WidgetTester tester,
  CustomPainter p,
  Size s,
  Color c,
) async {
  final GlobalKey k = GlobalKey();
  await tester.pumpWidget(
    Align(
      alignment: Alignment.topLeft,
      child: RepaintBoundary(
        key: k,
        child: SizedBox.fromSize(
          size: s,
          child: CustomPaint(painter: p),
        ),
      ),
    ),
  );
  final RenderRepaintBoundary b =
      k.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final ByteData? d = await tester.runAsync<ByteData?>(() async {
    final ui.Image im = await b.toImage();
    final ByteData? bd = await im.toByteData();
    im.dispose();
    return bd;
  });
  final Uint8List px = d!.buffer.asUint8List();
  int n = 0;
  final int r = (c.r * 255).round();
  final int g = (c.g * 255).round();
  final int bl = (c.b * 255).round();
  for (int i = 0; i + 3 < px.length; i += 4) {
    if ((px[i] - r).abs() < 14 &&
        (px[i + 1] - g).abs() < 14 &&
        (px[i + 2] - bl).abs() < 14) {
      n++;
    }
  }
  return n;
}

void main() {
  testWidgets('impostazioni 420x500: sezione linee senza errori di spazio', (
    WidgetTester tester,
  ) async {
    await _apri(tester, const Size(420, 500));
    await _apriImpostazioni(tester);
    expect(find.text(Testi.titoloLinee), findsOneWidget);
    for (final LineaGrafico l in LineaGrafico.values) {
      final Finder tr = find.byKey(Key('linea-${l.nome}-trasparenza'));
      final Finder sp = find.byKey(Key('linea-${l.nome}-spessore'));
      await tester.ensureVisible(tr);
      await tester.pumpAndSettle();
      expect(tr, findsOneWidget, reason: l.nome);
      expect(sp, findsOneWidget, reason: l.nome);
    }
    await tester.ensureVisible(find.byKey(const Key('rosso-soglia')));
    await tester.ensureVisible(find.byKey(const Key('ripristina-linee')));
    await tester.pumpAndSettle();
    expect(find.text(Testi.ripristinaLinee), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('impostazioni a 1300x950 e a 360x640: nessun errore', (
    WidgetTester tester,
  ) async {
    for (final Size s in const <Size>[Size(1300, 950), Size(360, 640)]) {
      await _apri(tester, s);
      await _apriImpostazioni(tester);
      await tester.ensureVisible(find.byKey(const Key('ripristina-linee')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.text(Testi.annulla));
      await tester.pumpAndSettle();
    }
  });

  testWidgets('cursori: solo ridisegno, nessun ricalcolo; salva al rilascio', (
    WidgetTester tester,
  ) async {
    final ({StatoApp stato, ServiziFinti f}) a = await _apri(
      tester,
      const Size(1300, 950),
    );
    final StatoApp s = a.stato;
    final DatiGrafico dati = s.grafico!;
    final int cp = s.calcoliPiano;
    final int ci = s.calcoliIntensita;
    await _apriImpostazioni(tester);
    final StileLinea prima = s.preferenze.stileLinee.di(LineaGrafico.ideale);
    await _spostaCursore(tester, 'linea-ideale-trasparenza', 60);
    await _spostaCursore(tester, 'linea-ideale-spessore', 40);
    final StileLinea dopo = s.preferenze.stileLinee.di(LineaGrafico.ideale);
    expect(dopo.alfa, lessThan(prima.alfa)); // piu trasparente
    expect(dopo.spessore, isNot(prima.spessore));
    // nessun ricalcolo: stessi dati, stesse cache
    expect(identical(s.grafico, dati), isTrue);
    expect(s.calcoliPiano, cp);
    expect(s.calcoliIntensita, ci);
    // salvato (al rilascio) nelle impostazioni
    expect(a.f.imp['v2_linea_ideale_alfa'], '${dopo.alfa}');
    expect(a.f.imp['v2_linea_ideale_spessore'], '${dopo.spessore}');
    // le altre linee non cambiano
    expect(
      s.preferenze.stileLinee.di(LineaGrafico.sessione),
      LineaGrafico.sessione.predefinito,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Ripristina: linee e rosso tornano come all inizio', (
    WidgetTester tester,
  ) async {
    final ({StatoApp stato, ServiziFinti f}) a = await _apri(
      tester,
      const Size(1300, 950),
    );
    final StatoApp s = a.stato;
    await s.cambiaStileLinee(
      s.preferenze.stileLinee.con(
        LineaGrafico.settimana,
        alfa: 30,
        spessore: 5,
      ),
    );
    await s.cambiaSogliaRosso(70);
    await s.cambiaRossoAcceso(acceso: false);
    await _apriImpostazioni(tester);
    await tester.ensureVisible(find.byKey(const Key('ripristina-linee')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('ripristina-linee')));
    await tester.pumpAndSettle();
    expect(s.preferenze.stileLinee.predefinito, isTrue);
    expect(s.preferenze.rossoAcceso, isTrue);
    expect(s.preferenze.sogliaRosso, 95);
    expect(a.f.imp['v2_soglia_rosso'], '95');
    expect(a.f.imp['v2_rosso_acceso'], '1');
    expect(a.f.imp['v2_linea_settimana_alfa'], '100');
  });

  testWidgets('rosso: soglia e interruttore dalle impostazioni', (
    WidgetTester tester,
  ) async {
    final ({StatoApp stato, ServiziFinti f}) a = await _apri(
      tester,
      const Size(1300, 950),
    );
    final StatoApp s = a.stato;
    expect(s.grafico!.piano!.rosso, isNotEmpty);
    final int base = s.grafico!.piano!.rosso.length;
    await _apriImpostazioni(tester);
    await _spostaCursore(tester, 'rosso-soglia', -60);
    expect(s.preferenze.sogliaRosso, lessThan(95));
    expect(a.f.imp['v2_soglia_rosso'], '${s.preferenze.sogliaRosso}');
    await tester.ensureVisible(find.byKey(const Key('rosso-acceso')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('rosso-acceso')));
    await tester.pumpAndSettle();
    expect(s.preferenze.rossoAcceso, isFalse);
    expect(s.grafico!.piano!.rosso, isEmpty);
    expect(s.grafico!.piano!.soglie, isEmpty);
    expect(base, greaterThan(0));
  });

  testWidgets('rosso: solo con lavoro V2 acceso', (WidgetTester tester) async {
    final ({StatoApp stato, ServiziFinti f}) a = await _apri(
      tester,
      const Size(1300, 950),
      lavoro: false,
    );
    expect(a.stato.grafico!.piano, isNull);
  });

  testWidgets('rosso: soglia piu bassa = piu rosso', (
    WidgetTester tester,
  ) async {
    final ({StatoApp stato, ServiziFinti f}) a = await _apri(
      tester,
      const Size(1300, 950),
    );
    final StatoApp s = a.stato;
    int totale() => s.grafico!.piano!.rosso.fold<int>(
      0,
      (int t, ({DateTime inizio, DateTime fine}) r) =>
          t + r.fine.difference(r.inizio).inMinutes,
    );
    await s.cambiaSogliaRosso(100);
    final int t100 = totale();
    await s.cambiaSogliaRosso(50);
    expect(totale(), greaterThanOrEqualTo(t100));
  });

  test('shouldRepaint: cambia stile = ridisegno; stesso stile = no', () {
    final DatiGrafico d = calcolaDatiGrafico(
      <Lettura>[],
      <Evento>[],
      _t('2026-11-10 20:00'),
      _t('2026-11-17 20:00'),
      _t('2026-11-13 11:00'),
    );
    final PittorePrincipale base = PittorePrincipale(d);
    expect(
      PittorePrincipale(
        d,
        stile: StileLinee.daMappa(<String, String?>{}),
      ).shouldRepaint(base),
      isFalse,
    );
    final StileLinee x = const StileLinee().con(
      LineaGrafico.settimana,
      alfa: 50,
    );
    expect(PittorePrincipale(d, stile: x).shouldRepaint(base), isTrue);
    expect(
      PittorePrincipale(
        d,
        stile: const StileLinee().con(LineaGrafico.settimana, alfa: 50),
      ).shouldRepaint(PittorePrincipale(d, stile: x)),
      isFalse,
    );
    final PittoreIntensita i = PittoreIntensita(d);
    expect(
      PittoreIntensita(
        d,
        stile: StileLinee.daMappa(<String, String?>{}),
      ).shouldRepaint(i),
      isFalse,
    );
    expect(PittoreIntensita(d, stile: x).shouldRepaint(i), isTrue);
  });

  testWidgets('disegno: rosso presente/assente, trasparenza, ogni scala', (
    WidgetTester tester,
  ) async {
    final ({StatoApp stato, ServiziFinti f}) a = await _apri(
      tester,
      const Size(1300, 950),
    );
    final DatiGrafico d = a.stato.grafico!;
    const Size s = Size(1000, 400);
    final int rossi = await _pixel(
      tester,
      PittorePrincipale(d, mostraIdeale: true, mostraAdattiva: true),
      s,
      Colori.settRossa,
    );
    expect(rossi, greaterThan(50)); // la linea rossa si vede
    // linea Settimana invisibile (trasparenza 100%): niente rosso
    final int invisibili = await _pixel(
      tester,
      PittorePrincipale(
        d,
        stile: const StileLinee().con(LineaGrafico.settimana, alfa: 0),
      ),
      s,
      Colori.settRossa,
    );
    expect(invisibili, lessThan(rossi ~/ 20 + 1));
    // piu spessa = piu pixel rossi
    final int spessa = await _pixel(
      tester,
      PittorePrincipale(
        d,
        stile: const StileLinee().con(LineaGrafico.settimana, spessore: 6),
      ),
      s,
      Colori.settRossa,
    );
    expect(spessa, greaterThan(rossi));
    // rosso spento: dati senza tratti rossi
    await a.stato.cambiaRossoAcceso(acceso: false);
    final int spento = await _pixel(
      tester,
      PittorePrincipale(a.stato.grafico!),
      s,
      Colori.settRossa,
    );
    expect(spento, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('disegno: tutte le combinazioni senza errori e senza ricalcoli', (
    WidgetTester tester,
  ) async {
    final ({StatoApp stato, ServiziFinti f}) a = await _apri(
      tester,
      const Size(1300, 950),
    );
    final StatoApp s = a.stato;
    final DatiGrafico d = s.grafico!;
    final int cp = s.calcoliPiano;
    final int ci = s.calcoliIntensita;
    StileLinee st = const StileLinee();
    for (final LineaGrafico l in LineaGrafico.values) {
      st = st.con(l, alfa: 35, spessore: 5.5);
    }
    for (final double dpr in <double>[1, 1.25, 2, 3]) {
      for (final StileLinee stile in <StileLinee>[const StileLinee(), st]) {
        for (final Size z in const <Size>[
          Size(1200, 500),
          Size(420, 300),
          Size(120, 90),
          Size(30, 20),
        ]) {
          final ui.PictureRecorder r1 = ui.PictureRecorder();
          PittorePrincipale(
            d,
            mostraIdeale: true,
            mostraAdattiva: true,
            dpr: dpr,
            stile: stile,
          ).paint(Canvas(r1), z);
          r1.endRecording().dispose();
          final ui.PictureRecorder r2 = ui.PictureRecorder();
          PittoreIntensita(d, dpr: dpr, stile: stile).paint(Canvas(r2), z);
          r2.endRecording().dispose();
        }
      }
    }
    expect(s.calcoliPiano, cp);
    expect(s.calcoliIntensita, ci);
  });
}
