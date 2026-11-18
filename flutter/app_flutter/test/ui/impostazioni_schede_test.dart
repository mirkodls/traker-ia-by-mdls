// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
//
// B18: Impostazioni a schede, colori delle linee, anteprima del grafico.
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:traker_ia/domain/modelli.dart';
import 'package:traker_ia/domain/stile_linee.dart';
import 'package:traker_ia/domain/tempo.dart';
import 'package:traker_ia/domain/traduzioni/testi_it.dart';
import 'package:traker_ia/ui/app.dart';
import 'package:traker_ia/ui/grafico_dati.dart';
import 'package:traker_ia/ui/stato_app.dart';

import 'aiuti_impostazioni.dart';
import 'servizi_finti.dart';

DateTime _t(String s) => interpreta(s)!;

/// Ven 13/11/2026 11:00, settimana dal 10/11 20:00, piano 7 giorni.
Future<({StatoApp stato, ServiziFinti f})> _apri(
  WidgetTester tester,
  Size taglia, {
  bool telefono = false,
}) async {
  tester.view.physicalSize = taglia;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final ServiziFinti f = ServiziFinti()
    ..tel = telefono
    ..risposte.add(const Uso(sett: 52, sess: 9));
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

Future<void> _apriImpostazioni(
  WidgetTester tester, {
  bool telefono = false,
}) async {
  if (telefono) {
    await tester.tap(find.byTooltip(Testi.impostazioni));
    await tester.pumpAndSettle();
  }
  await tester.tap(find.text(Testi.impostazioni));
  await tester.pumpAndSettle();
}

/// Pixel dell'anteprima quasi uguali a [c].
Future<int> _pixelAnteprima(WidgetTester tester, Color c) async {
  final RenderRepaintBoundary b = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const Key('anteprima-grafico')),
  );
  final ByteData? d = await tester.runAsync<ByteData?>(() async {
    final ui.Image im = await b.toImage();
    final ByteData? bd = await im.toByteData();
    im.dispose();
    return bd;
  });
  final Uint8List px = d!.buffer.asUint8List();
  final int r = (c.r * 255).round();
  final int g = (c.g * 255).round();
  final int bl = (c.b * 255).round();
  int n = 0;
  for (int i = 0; i + 3 < px.length; i += 4) {
    if ((px[i] - r).abs() < 14 &&
        (px[i + 1] - g).abs() < 14 &&
        (px[i + 2] - bl).abs() < 14) {
      n++;
    }
  }
  return n;
}

Finder _pallino(LineaGrafico l, int i) =>
    find.byKey(Key('linea-${l.nome}-colore-$i'));

bool _scelto(WidgetTester tester, LineaGrafico l, int i) {
  final GestureDetector g = tester.widget<GestureDetector>(_pallino(l, i));
  final BoxDecoration d = (g.child! as Container).decoration! as BoxDecoration;
  return (d.border! as Border).top.color == Colors.white;
}

void main() {
  testWidgets(
    'ogni scheda senza errori di spazio: 420x500, 1300x950, 360x640',
    (WidgetTester tester) async {
      for (final Size z in const <Size>[
        Size(420, 500),
        Size(1300, 950),
        Size(360, 640),
      ]) {
        await _apri(tester, z);
        await _apriImpostazioni(tester);
        expect(find.byKey(const Key('schede-impostazioni')), findsOneWidget);
        for (final String scheda in <String>[
          Testi.schedaGenerale,
          Testi.schedaAccesso,
          Testi.schedaGrafico,
          Testi.titoloIA,
        ]) {
          await apriScheda(tester, scheda);
          expect(tester.takeException(), isNull, reason: '$scheda $z');
        }
        await apriScheda(tester, Testi.schedaGrafico);
        expect(find.byKey(const Key('anteprima-grafico')), findsOneWidget);
        // ogni riga raggiungibile (si scorre la lista, l'anteprima resta)
        for (final LineaGrafico l in LineaGrafico.values) {
          await tester.ensureVisible(
            find.byKey(Key('linea-${l.nome}-spessore')),
          );
          await tester.pumpAndSettle();
          expect(_pallino(l, 9), findsOneWidget, reason: l.nome);
        }
        expect(find.byKey(const Key('anteprima-grafico')), findsOneWidget);
        expect(tester.takeException(), isNull, reason: '$z');
        await tester.tap(find.text(Testi.annulla));
        await tester.pumpAndSettle();
      }
    },
  );

  testWidgets('telefono 360x640: 3 schede (niente IA), schermo intero', (
    WidgetTester tester,
  ) async {
    await _apri(tester, const Size(360, 640), telefono: true);
    await _apriImpostazioni(tester, telefono: true);
    expect(find.text(Testi.schedaGenerale), findsOneWidget);
    expect(find.text(Testi.schedaAccesso), findsOneWidget);
    expect(find.text(Testi.schedaGrafico), findsOneWidget);
    expect(find.text(Testi.titoloIA), findsNothing);
    for (final String scheda in <String>[
      Testi.schedaGenerale,
      Testi.schedaAccesso,
      Testi.schedaGrafico,
    ]) {
      await apriScheda(tester, scheda);
      expect(tester.takeException(), isNull, reason: scheda);
    }
    expect(find.byKey(const Key('anteprima-grafico')), findsOneWidget);
    // schermo intero: il dialogo occupa tutta la finestra
    expect(
      tester.getSize(find.byKey(const Key('schede-impostazioni'))).width,
      360,
    );
  });

  testWidgets('colore: anteprima cambia subito, nessun ricalcolo, salvato', (
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
    await apriScheda(tester, Testi.schedaGrafico);
    const Color viola = Color(0xFFA78BFA);
    expect(await _pixelAnteprima(tester, viola), 0);
    expect(_scelto(tester, LineaGrafico.settimana, 0), isTrue); // base
    expect(_scelto(tester, LineaGrafico.settimana, 5), isFalse);
    await tester.ensureVisible(_pallino(LineaGrafico.settimana, 5));
    await tester.tap(_pallino(LineaGrafico.settimana, 5));
    await tester.pumpAndSettle();
    // il colore scelto si vede subito nell'anteprima (linea, legenda, punto)
    expect(await _pixelAnteprima(tester, viola), greaterThan(50));
    expect(_scelto(tester, LineaGrafico.settimana, 5), isTrue);
    expect(_scelto(tester, LineaGrafico.settimana, 0), isFalse);
    expect(
      s.preferenze.stileLinee.di(LineaGrafico.settimana).colore,
      0xFFA78BFA,
    );
    // solo ridisegno: stessi dati, stesse cache
    expect(identical(s.grafico, dati), isTrue);
    expect(s.calcoliPiano, cp);
    expect(s.calcoliIntensita, ci);
    // salvato da solo
    expect(a.f.imp['v2_linea_settimana_colore'], 'FFA78BFA');
    // le altre linee: colore base
    expect(s.preferenze.stileLinee.di(LineaGrafico.sessione).colore, isNull);
    // tornare al colore base = niente colore salvato
    await tester.tap(_pallino(LineaGrafico.settimana, 0));
    await tester.pumpAndSettle();
    expect(s.preferenze.stileLinee.predefinito, isTrue);
    expect(a.f.imp['v2_linea_settimana_colore'], '');
    expect(await _pixelAnteprima(tester, viola), 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('anteprima: segue la linea toccata e si cambia a mano', (
    WidgetTester tester,
  ) async {
    await _apri(tester, const Size(1300, 950));
    await _apriImpostazioni(tester);
    await apriScheda(tester, Testi.schedaGrafico);
    bool principale() => tester
        .widget<ChoiceChip>(find.byKey(const Key('anteprima-principale')))
        .selected;
    expect(principale(), isTrue);
    await tester.ensureVisible(_pallino(LineaGrafico.int5h, 3));
    await tester.tap(_pallino(LineaGrafico.int5h, 3));
    await tester.pumpAndSettle();
    expect(principale(), isFalse); // linea d'intensità -> grafico intensità
    await tester.tap(find.byKey(const Key('anteprima-principale')));
    await tester.pumpAndSettle();
    expect(principale(), isTrue);
    await tester.ensureVisible(_pallino(LineaGrafico.ideale, 4));
    await tester.tap(_pallino(LineaGrafico.ideale, 4));
    await tester.pumpAndSettle();
    expect(principale(), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('salvataggio: Grafico da solo, Generale solo con Salva; '
      'cambiare scheda non perde nulla', (WidgetTester tester) async {
    final ({StatoApp stato, ServiziFinti f}) a = await _apri(
      tester,
      const Size(1300, 950),
    );
    final int minutiPrima = a.stato.preferenze.minuti;
    await _apriImpostazioni(tester);
    await tester.enterText(
      find.widgetWithText(TextField, Testi.campoMinuti),
      '7',
    );
    await apriScheda(tester, Testi.schedaGrafico);
    await tester.ensureVisible(_pallino(LineaGrafico.sessione, 7));
    await tester.tap(_pallino(LineaGrafico.sessione, 7));
    await tester.pumpAndSettle();
    await apriScheda(tester, Testi.schedaGenerale);
    // il testo scritto è ancora lì
    expect(
      tester
          .widget<TextField>(find.widgetWithText(TextField, Testi.campoMinuti))
          .controller!
          .text,
      '7',
    );
    // Annulla: minuti NON salvati, colore (scheda Grafico) già salvato
    await tester.tap(find.text(Testi.annulla));
    await tester.pumpAndSettle();
    expect(a.stato.preferenze.minuti, minutiPrima);
    expect(a.f.imp['v2_linea_sessione_colore'], 'FF22D3EE');
    // Salva e prova: minuti salvati
    await _apriImpostazioni(tester);
    await tester.enterText(
      find.widgetWithText(TextField, Testi.campoMinuti),
      '7',
    );
    await tester.tap(find.text(Testi.salvaEProva));
    await tester.pumpAndSettle();
    expect(a.stato.preferenze.minuti, 7);
    expect(
      a.stato.preferenze.stileLinee.di(LineaGrafico.sessione).colore,
      0xFF22D3EE,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('minuti sbagliati: errore visibile sulla scheda Generale', (
    WidgetTester tester,
  ) async {
    await _apri(tester, const Size(1300, 950));
    await _apriImpostazioni(tester);
    await tester.enterText(
      find.widgetWithText(TextField, Testi.campoMinuti),
      '0',
    );
    await apriScheda(tester, Testi.schedaGrafico);
    await tester.tap(find.text(Testi.salvaEProva));
    await tester.pumpAndSettle();
    expect(find.text(Testi.erroreMinuti), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Ripristina: anche i colori tornano come all inizio', (
    WidgetTester tester,
  ) async {
    final ({StatoApp stato, ServiziFinti f}) a = await _apri(
      tester,
      const Size(1300, 950),
    );
    await _apriImpostazioni(tester);
    await apriScheda(tester, Testi.schedaGrafico);
    await tester.ensureVisible(_pallino(LineaGrafico.adattiva, 6));
    await tester.tap(_pallino(LineaGrafico.adattiva, 6));
    await tester.pumpAndSettle();
    expect(a.f.imp['v2_linea_adattiva_colore'], 'FFF472B6');
    await tester.ensureVisible(find.byKey(const Key('ripristina-linee')));
    await tester.tap(find.byKey(const Key('ripristina-linee')));
    await tester.pumpAndSettle();
    expect(a.stato.preferenze.stileLinee.predefinito, isTrue);
    expect(a.f.imp['v2_linea_adattiva_colore'], '');
    expect(_scelto(tester, LineaGrafico.adattiva, 3), isTrue); // giallo base
  });
}
