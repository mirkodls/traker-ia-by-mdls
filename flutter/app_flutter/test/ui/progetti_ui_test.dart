// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:traker_ia/domain/archivio_settimane.dart';
import 'package:traker_ia/domain/export_ia.dart';
import 'package:traker_ia/domain/modelli.dart';
import 'package:traker_ia/domain/piani_progetti.dart';
import 'package:traker_ia/domain/traduzioni/testi_it.dart';
import 'package:traker_ia/ui/app.dart';
import 'package:traker_ia/ui/barre_settimane.dart';
import 'package:traker_ia/ui/pagina_progetti.dart';
import 'package:traker_ia/ui/stato_app.dart';

import 'progetti_helper.dart';
import 'servizi_finti.dart';

Future<({StatoApp stato, ServiziFinti f})> _apri(
  WidgetTester tester,
  Size taglia, {
  bool progetti = true,
}) async {
  tester.view.physicalSize = taglia;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final ServiziFinti f = ServiziFinti()
    ..risposte.add(const Uso(sett: 30, sess: 10));
  riempi(f);
  if (!progetti) {
    f.prog.clear();
  }
  final StatoApp s = StatoApp(f, orologio: () => adessoFinto, giri: false);
  await tester.runAsync(() async {
    await s.avvia();
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

Future<void> _apriPagina(WidgetTester tester) async {
  await _tocca(tester, find.byKey(const ValueKey<String>('tasto-progetti')));
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 50)),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 800));
}

void main() {
  for (final Size taglia in const <Size>[Size(420, 500), Size(1300, 950)]) {
    testWidgets('barra progetto attivo ${taglia.width.toInt()}: tasti, '
        'toggle, nessun overflow', (WidgetTester tester) async {
      final ({StatoApp stato, ServiziFinti f}) a = await _apri(tester, taglia);
      expect(find.byType(BarraProgetti), findsOneWidget);
      final Finder alfa = find.byKey(
        const ValueKey<String>('progetto-attivo-1'),
      );
      final Finder beta = find.byKey(
        const ValueKey<String>('progetto-attivo-2'),
      );
      expect(alfa, findsOneWidget);
      expect(beta, findsOneWidget);
      await _tocca(tester, alfa);
      expect(a.f.ev.last.testo, 'Alfa inizio');
      await _tocca(tester, beta);
      expect(a.stato.progettiAttivi, <int>{1, 2});
      await _tocca(tester, alfa);
      expect(a.f.ev.last.testo, 'Alfa fine');
      expect(a.stato.progettiAttivi, <int>{2});
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('senza progetti: nessuna barra attivo, tasto Progetti c\'è', (
    WidgetTester tester,
  ) async {
    await _apri(tester, const Size(1300, 950), progetti: false);
    expect(find.byType(BarraProgetti), findsNothing);
    expect(
      find.byKey(const ValueKey<String>('tasto-progetti')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('v2_lavoro=0: né tasto Progetti né barra', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1300, 950);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final ServiziFinti f = ServiziFinti()
      ..risposte.add(const Uso(sett: 30, sess: 10));
    riempi(f);
    f.imp['v2_lavoro'] = '0';
    final StatoApp s = StatoApp(f, orologio: () => adessoFinto, giri: false);
    await tester.runAsync(s.avvia);
    await tester.pumpWidget(TrakerApp(stato: s));
    await tester.pump();
    expect(find.byKey(const ValueKey<String>('tasto-progetti')), findsNothing);
    expect(find.byType(BarraProgetti), findsNothing);
  });

  for (final Size taglia in const <Size>[Size(420, 500), Size(1300, 950)]) {
    testWidgets('pagina progetti ${taglia.width.toInt()}: riquadri e righe, '
        'nessun overflow', (WidgetTester tester) async {
      final ({StatoApp stato, ServiziFinti f}) a = await _apri(tester, taglia);
      await _apriPagina(tester);
      expect(find.byType(PaginaProgetti), findsOneWidget);
      expect(find.text(Testi.titoloElencoProgetti), findsOneWidget);
      expect(find.text('Alfa'), findsWidgets);
      expect(find.text('Beta'), findsWidgets);
      expect(
        find.byKey(const ValueKey<String>('carta-in-corso')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('carta-confronto')),
        findsOneWidget,
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey<String>('carta-settimane')),
      );
      await tester.pump();
      expect(find.byType(BarreSettimane), findsOneWidget);
      final int ids = a.f.sett.length;
      expect(ids, greaterThan(0));
      expect(
        find.byKey(ValueKey<String>('riga-${a.f.sett.first.id}')),
        findsWidgets,
      );
      expect(tester.takeException(), isNull);
      // Indietro: la pagina si chiude e butta le istantanee.
      await _tocca(
        tester,
        find.byKey(const ValueKey<String>('pagina-indietro')),
      );
      expect(find.byType(PaginaProgetti), findsNothing);
      expect(a.stato.settimane, isNull);
    });
  }

  testWidgets('filtro del confronto: scelta progetto cambia le barre', (
    WidgetTester tester,
  ) async {
    await _apri(tester, const Size(1300, 950));
    await _apriPagina(tester);
    final Finder tutti = find.byKey(const ValueKey<String>('filtro-tutti'));
    await tester.ensureVisible(tutti);
    await tester.pump();
    final Finder f1 = find.byKey(const ValueKey<String>('filtro-1'));
    expect(f1, findsOneWidget);
    await tester.tap(f1);
    await tester.pump();
    expect(find.byType(BarreSettimane), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final Size taglia in const <Size>[Size(420, 500), Size(1300, 950)]) {
    testWidgets('scheda settimana ${taglia.width.toInt()}: grafici salvati, '
        'costo, log, token', (WidgetTester tester) async {
      final ({StatoApp stato, ServiziFinti f}) a = await _apri(tester, taglia);
      await _apriPagina(tester);
      final int idRiga = a.f.sett
          .firstWhere((SettimanaProgetto s) => s.progettoId == 1)
          .id!;
      final Finder riga = find.byKey(ValueKey<String>('riga-$idRiga'));
      await tester.ensureVisible(riga);
      await tester.pump();
      await tester.tap(riga);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));
      expect(
        find.byKey(const ValueKey<String>('scheda-grafico')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('scheda-intensita')),
        findsOneWidget,
      );
      expect(find.text(Testi.titoloCosto), findsOneWidget);
      expect(find.textContaining('Settimana:'), findsOneWidget);
      expect(find.textContaining('Ore attive:'), findsOneWidget);
      // Alfa è sempre attivo anche insieme a Beta: stima con intervallo.
      expect(find.textContaining(Testi.stima), findsWidgets);
      await tester.ensureVisible(
        find.byKey(const ValueKey<String>('scheda-log')),
      );
      await tester.pump();
      expect(find.byKey(const ValueKey<String>('scheda-log')), findsOneWidget);
      // Token a mano.
      final Finder campo = find.byKey(const ValueKey<String>('campo-token'));
      await tester.ensureVisible(campo);
      await tester.pump();
      await tester.enterText(campo, '-3');
      await tester.tap(find.byKey(const ValueKey<String>('salva-token')));
      await tester.pump();
      expect(find.text(Testi.tokenNonValidi), findsOneWidget);
      await tester.enterText(campo, '4200');
      await tester.runAsync(() async {
        await tester.tap(find.byKey(const ValueKey<String>('salva-token')));
        await Future<void>.delayed(const Duration(milliseconds: 30));
      });
      await tester.pump();
      expect(
        a.f.sett
            .firstWhere((SettimanaProgetto s) => s.id == idRiga)
            .tokenManuali,
        4200,
      );
      expect(find.text(Testi.rigaToken(4200)), findsOneWidget);
      expect(tester.takeException(), isNull);
      // Indietro all'elenco.
      final Finder ind = find.byKey(const ValueKey<String>('scheda-indietro'));
      await tester.ensureVisible(ind);
      await tester.pump();
      await tester.tap(ind);
      await tester.pump();
      expect(
        find.byKey(const ValueKey<String>('scheda-grafico')),
        findsNothing,
      );
      expect(find.text(Testi.titoloElencoProgetti), findsOneWidget);
    });
  }

  testWidgets('dialogo: nuovo progetto, colore, doppio rifiutato', (
    WidgetTester tester,
  ) async {
    final ({StatoApp stato, ServiziFinti f}) a = await _apri(
      tester,
      const Size(420, 500),
    );
    await _apriPagina(tester);
    await _tocca(tester, find.byKey(const ValueKey<String>('nuovo-progetto')));
    expect(find.text(Testi.titoloNuovoProgetto), findsWidgets);
    // Nome doppio -> errore, il dialogo resta.
    await tester.enterText(
      find.byKey(const ValueKey<String>('campo-nome-progetto')),
      'alfa',
    );
    await _tocca(tester, find.byKey(const ValueKey<String>('salva-progetto')));
    expect(find.text(Testi.nomeProgettoNonValido), findsOneWidget);
    // Nome nuovo + colore scelto.
    await tester.enterText(
      find.byKey(const ValueKey<String>('campo-nome-progetto')),
      'Gamma',
    );
    await tester.tap(find.byKey(const ValueKey<String>('colore-4')));
    await tester.pump();
    await _tocca(tester, find.byKey(const ValueKey<String>('salva-progetto')));
    expect(a.f.prog.length, 3);
    expect(a.f.prog.last.nome, 'Gamma');
    expect(a.f.prog.last.colore, 0xFFA78BFA);
    expect(tester.takeException(), isNull);
  });

  testWidgets('dialogo modifica: avviso se rinomini, colore e note salvati', (
    WidgetTester tester,
  ) async {
    final ({StatoApp stato, ServiziFinti f}) a = await _apri(
      tester,
      const Size(420, 500),
    );
    await _apriPagina(tester);
    await _tocca(tester, find.byKey(const ValueKey<String>('modifica-2')));
    expect(find.byKey(const ValueKey<String>('avviso-rinomina')), findsNothing);
    await tester.enterText(
      find.byKey(const ValueKey<String>('campo-nome-progetto')),
      'Beta nuovo',
    );
    await tester.pump();
    expect(
      find.byKey(const ValueKey<String>('avviso-rinomina')),
      findsOneWidget,
    );
    await tester.enterText(
      find.byKey(const ValueKey<String>('campo-note-progetto')),
      'una nota',
    );
    await tester.tap(find.byKey(const ValueKey<String>('colore-1')));
    await tester.pump();
    await _tocca(tester, find.byKey(const ValueKey<String>('salva-progetto')));
    final Progetto b = a.f.prog.firstWhere((Progetto p) => p.id == 2);
    expect(b.nome, 'Beta nuovo');
    expect(b.note, 'una nota');
    expect(b.colore, 0xFF34D399);
    expect(tester.takeException(), isNull);
  });

  testWidgets('settimana in corso: mostra stima dei progetti attivi', (
    WidgetTester tester,
  ) async {
    final ({StatoApp stato, ServiziFinti f}) a = await _apri(
      tester,
      const Size(1300, 950),
    );
    await tester.runAsync(
      () => a.stato.cambiaProgettoAttivo(a.stato.progetti[0]),
    );
    await _apriPagina(tester);
    final Finder carta = find.byKey(const ValueKey<String>('carta-in-corso'));
    expect(carta, findsOneWidget);
    expect(
      find.descendant(of: carta, matching: find.textContaining('pt')),
      findsWidgets,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('esporta per IA: scheda copia e salva .md, errore mostrato', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(420, 500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    String? negliAppunti;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (MethodCall c) async {
        if (c.method == 'Clipboard.setData') {
          negliAppunti =
              (c.arguments as Map<Object?, Object?>)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    final ({StatoApp stato, ServiziFinti f}) a = await _apri(
      tester,
      const Size(420, 500),
    );
    await _apriPagina(tester);
    final int idRiga = a.f.sett
        .firstWhere((SettimanaProgetto s) => s.progettoId == 1)
        .id!;
    final Finder riga = find.byKey(ValueKey<String>('riga-$idRiga'));
    await tester.ensureVisible(riga);
    await tester.pump();
    await tester.tap(riga);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    await _tocca(tester, find.byKey(const ValueKey<String>('scheda-esporta')));
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('esporta-anteprima')),
      findsOneWidget,
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey<String>('esporta-copia')),
    );
    await tester.pump();
    await tester.runAsync(() async {
      await tester.tap(find.byKey(const ValueKey<String>('esporta-copia')));
      await Future<void>.delayed(const Duration(milliseconds: 30));
    });
    await tester.pump();
    expect(find.text(Testi.copiatoEsporta), findsOneWidget);
    expect(negliAppunti, startsWith('RICHIESTA: '));
    expect(negliAppunti, contains('## PROGETTO "Alfa"'));
    expect(parolaVietataEsportazione.hasMatch(negliAppunti!), isFalse);
    await tester.ensureVisible(
      find.byKey(const ValueKey<String>('esporta-salva')),
    );
    await tester.pump();
    await tester.runAsync(() async {
      await tester.tap(find.byKey(const ValueKey<String>('esporta-salva')));
      await Future<void>.delayed(const Duration(milliseconds: 30));
    });
    await tester.pump();
    expect(a.f.fileSalvati.keys.single, startsWith('esporta/traker-ia_2026-'));
    expect(a.f.fileSalvati.keys.single, endsWith('_alfa.md'));
    expect(a.f.fileSalvati.values.single, negliAppunti);
    // Errore di salvataggio mostrato, nessuna eccezione.
    a.f.erroreSalva = 'disco pieno';
    await tester.ensureVisible(
      find.byKey(const ValueKey<String>('esporta-salva')),
    );
    await tester.pump();
    await tester.runAsync(() async {
      await tester.tap(find.byKey(const ValueKey<String>('esporta-salva')));
      await Future<void>.delayed(const Duration(milliseconds: 30));
    });
    await tester.pump();
    expect(find.textContaining('disco pieno'), findsOneWidget);
    // Cartella vuota rifiutata.
    await tester.enterText(
      find.byKey(const ValueKey<String>('esporta-cartella')),
      '  ',
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey<String>('esporta-salva')),
    );
    await tester.pumpAndSettle(); // B17: dialogo più alto, scorre
    await tester.tap(find.byKey(const ValueKey<String>('esporta-salva')));
    await tester.pump();
    expect(find.text(Testi.cartellaEsportaVuota), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'esporta per IA: tasto della settimana esporta tutti i progetti',
    (WidgetTester tester) async {
      final ({StatoApp stato, ServiziFinti f}) a = await _apri(
        tester,
        const Size(420, 500),
      );
      await _apriPagina(tester);
      final Finder tasto = find.byKey(
        ValueKey<String>(
          'esporta-sett-${a.f.sett.first.inizio.toIso8601String()}',
        ),
      );
      await _tocca(tester, tasto);
      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.ensureVisible(
        find.byKey(const ValueKey<String>('esporta-salva')),
      );
      await tester.pump();
      await tester.runAsync(() async {
        await tester.tap(find.byKey(const ValueKey<String>('esporta-salva')));
        await Future<void>.delayed(const Duration(milliseconds: 30));
      });
      await tester.pump();
      final String testo = a.f.fileSalvati.values.single;
      final int n = a.f.sett
          .where((SettimanaProgetto s) => s.inizio == a.f.sett.first.inizio)
          .length;
      expect('## PROGETTO'.allMatches(testo).length, n);
      expect(tester.takeException(), isNull);
    },
  );
}
