// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
//
// B21: telefono con tutte le funzioni V2 del PC (tranne Resoconto IA via
// API). Tre misure di telefono, nessun overflow.
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:traker_ia/domain/analisi.dart';
import 'package:traker_ia/domain/modelli.dart';
import 'package:traker_ia/domain/preferenze.dart';
import 'package:traker_ia/domain/sfondo.dart';
import 'package:traker_ia/domain/traduzioni/testi_it.dart';
import 'package:traker_ia/ui/app.dart';
import 'package:traker_ia/ui/barra_intensita.dart';
import 'package:traker_ia/ui/barra_piano.dart';
import 'package:traker_ia/ui/grafico.dart';
import 'package:traker_ia/ui/pagina_progetti.dart';
import 'package:traker_ia/ui/stato_app.dart';

import 'aiuti_impostazioni.dart';
import 'progetti_helper.dart';
import 'servizi_finti.dart';

/// Misure: piccolo, Samsung S23, grande.
const List<Size> _misure = <Size>[
  Size(360, 640),
  Size(393, 852),
  Size(412, 915),
];

const Crediti _crediti = Crediti(
  usati: 12.5,
  valuta: 'USD',
  attivi: true,
  limite: 50,
);

Future<({StatoApp stato, ServiziFinti f})> _apri(
  WidgetTester tester,
  Size taglia, {
  bool progetti = true,
}) async {
  tester.view.physicalSize = taglia;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final ServiziFinti f = ServiziFinti()
    ..tel = true
    ..cookie = 'sk'
    ..batteria = true
    ..imp[Chiavi.permessiChiesti] = '1'
    ..risposte.add(const Uso(sett: 30, sess: 10, fable: 40, crediti: _crediti));
  riempi(f);
  if (!progetti) {
    f.prog.clear();
  }
  final StatoApp s = StatoApp(f, orologio: () => adessoFinto, giri: false);
  await tester.runAsync(() async {
    await s.avvia();
    await s.leggi();
    await Future<void>.delayed(const Duration(milliseconds: 80));
  });
  await tester.pumpWidget(TrakerApp(stato: s));
  await tester.pump();
  return (stato: s, f: f);
}

Future<void> _tocca(WidgetTester tester, Finder fi) async {
  await tester.ensureVisible(fi);
  await tester.runAsync(() async {
    await tester.tap(fi);
    await Future<void>.delayed(const Duration(milliseconds: 30));
  });
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 800));
  await tester.pump();
}

Finder _k(String k) => find.byKey(ValueKey<String>(k));

void main() {
  for (final Size m in _misure) {
    final String nome = '${m.width.toInt()}x${m.height.toInt()}';

    testWidgets('telefono $nome: schermata unica con crediti, piano, '
        'progetti, tasti sezioni, nessun overflow', (
      WidgetTester tester,
    ) async {
      final ({StatoApp stato, ServiziFinti f}) a = await _apri(tester, m);
      // Crediti letti dalla risposta (valore + riga sotto).
      expect(_k('mini-crediti'), findsOneWidget);
      expect(find.text(soldi(12.5, 'USD')), findsOneWidget);
      expect(a.stato.quotaCrediti, closeTo(0.25, 1e-9));
      // Grafico con linee del piano, progetto attivo in una riga.
      expect(_k('tasto-piano'), findsOneWidget);
      expect(_k('progetti-una-riga'), findsOneWidget);
      expect(_k('progetto-attivo-1'), findsOneWidget);
      for (final String s in <String>[
        'dati',
        'intensita',
        'confronti',
        'progetti',
      ]) {
        expect(_k('sezione-$s'), findsOneWidget);
      }
      // Niente scorrimento: la schermata non è dentro uno Scrollable
      // verticale (solo la riga progetti scorre di lato).
      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('telefono $nome: Piano (giorni, linee) nel foglio', (
      WidgetTester tester,
    ) async {
      final ({StatoApp stato, ServiziFinti f}) a = await _apri(tester, m);
      await _tocca(tester, _k('tasto-piano'));
      expect(_k('foglio-piano'), findsOneWidget);
      expect(find.byType(BarraPiano), findsOneWidget);
      final int prima = a.stato.preferenze.giorniPiano;
      await _tocca(tester, _k('giorno-7'));
      expect(a.stato.preferenze.giorniPiano, isNot(prima));
      await _tocca(tester, _k('linea-ideale'));
      expect(a.stato.preferenze.lineaIdeale, isFalse);
      expect(tester.takeException(), isNull);
    });

    testWidgets('telefono $nome: Intensità con barra 5h/7gg e Lavoro', (
      WidgetTester tester,
    ) async {
      await _apri(tester, m);
      await _tocca(tester, _k('sezione-intensita'));
      expect(find.byType(BarraIntensita), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('telefono $nome: Progetti > Esporta per IA = condividi e '
        'salva, niente IA via API', (WidgetTester tester) async {
      final ({StatoApp stato, ServiziFinti f}) a = await _apri(tester, m);
      await _tocca(tester, _k('sezione-progetti'));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump(const Duration(milliseconds: 800));
      expect(find.byType(PaginaProgetti), findsOneWidget);
      expect(tester.takeException(), isNull);
      expect(
        find.descendant(
          of: _k('resoconto-ia'),
          matching: find.text(Testi.titoloEsportaIA),
        ),
        findsOneWidget,
      );
      await _tocca(tester, _k('resoconto-ia'));
      expect(_k('esporta-condividi'), findsOneWidget);
      expect(_k('esporta-cartella'), findsNothing);
      expect(_k('esporta-resoconto'), findsNothing);
      expect(
        find.text(Testi.salvaSuTelefono(cartellaEsportaTelefono)),
        findsOneWidget,
      );
      await _tocca(tester, _k('esporta-condividi'));
      expect(a.f.condivisi, hasLength(1));
      expect(a.f.condivisi.single, isNotEmpty);
      await _tocca(tester, _k('esporta-salva'));
      expect(a.f.fileSalvati.keys.single, startsWith(cartellaEsportaTelefono));
      // Mai segreti nel testo condiviso.
      expect(a.f.condivisi.single.contains('sk'), isFalse);
      expect(tester.takeException(), isNull);
    });

    testWidgets('telefono $nome: Impostazioni 3 schede (Sottofondo in '
        'Generale), niente IA', (WidgetTester tester) async {
      final ({StatoApp stato, ServiziFinti f}) a = await _apri(tester, m);
      await tester.tap(find.byTooltip(Testi.impostazioni));
      await tester.pumpAndSettle();
      await tester.tap(find.text(Testi.impostazioni));
      await tester.pumpAndSettle();
      expect(find.text(Testi.schedaGrafico), findsOneWidget);
      expect(find.text(Testi.titoloIA), findsNothing);
      expect(_k('imp-sottofondo'), findsOneWidget);
      await tester.ensureVisible(_k('imp-sottofondo'));
      await tester.runAsync(() async {
        await tester.tap(_k('imp-sottofondo'));
        await Future<void>.delayed(const Duration(milliseconds: 30));
      });
      await tester.pump();
      expect(a.stato.preferenze.sfondoAcceso, isFalse);
      expect(a.f.sfondo.last.$2, isFalse);
      expect(tester.takeException(), isNull);
      await apriScheda(tester, Testi.schedaAccesso);
      expect(find.text(Testi.accedi('Claude')), findsOneWidget);
      expect(tester.takeException(), isNull);
      await apriScheda(tester, Testi.schedaGrafico);
      expect(_k('anteprima-grafico'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('telefono senza progetti: niente riga progetti, tasto '
      'Progetti resta', (WidgetTester tester) async {
    await _apri(tester, _misure.first, progetti: false);
    expect(_k('progetti-una-riga'), findsNothing);
    expect(_k('sezione-progetti'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('PC: dialogo esporta con cartella e Resoconto IA, niente '
      'Condividi', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1300, 950);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final ServiziFinti f = ServiziFinti()
      ..risposte.add(const Uso(sett: 30, sess: 10));
    riempi(f);
    final StatoApp s = StatoApp(f, orologio: () => adessoFinto, giri: false);
    await tester.runAsync(() async {
      await s.avvia();
      await Future<void>.delayed(const Duration(milliseconds: 80));
    });
    await tester.pumpWidget(TrakerApp(stato: s));
    await tester.pump();
    await _tocca(tester, _k('tasto-progetti'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump(const Duration(milliseconds: 800));
    await _tocca(tester, _k('resoconto-ia'));
    expect(_k('esporta-cartella'), findsOneWidget);
    expect(_k('esporta-resoconto'), findsOneWidget);
    expect(_k('esporta-condividi'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  test('riquadro del grafico: riga Fable solo dove letta (B19 aperto)', () {
    final List<Lettura> ls = <Lettura>[
      Lettura(ora: DateTime(2026, 11, 20, 10), sett: 10, sess: 5, fable: 40),
      Lettura(ora: DateTime(2026, 11, 20, 11), sett: 12, sess: 7),
    ];
    expect(
      testoMouse(ls, DateTime(2026, 11, 20, 10)),
      contains(Testi.legFable),
    );
    expect(
      testoMouse(ls, DateTime(2026, 11, 20, 11)).contains(Testi.legFable),
      isFalse,
    );
  });
}
