// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
//
// B17: sezione Impostazioni "IA resoconto" e tasto "Resoconto IA" del
// dialogo Esporta (servizi finti, nessuna rete). Chiave finta "test-...".
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:traker_ia/domain/archivio_settimane.dart';
import 'package:traker_ia/domain/modelli.dart';
import 'package:traker_ia/domain/resoconto_ia.dart';
import 'package:traker_ia/domain/traduzioni/testi_it.dart';
import 'package:traker_ia/ui/app.dart';
import 'package:traker_ia/ui/stato_app.dart';

import 'progetti_helper.dart';
import 'servizi_finti.dart';

const String _k = 'test-xxx-chiave-ui-5555';

Future<({StatoApp stato, ServiziFinti f})> _apri(
  WidgetTester tester,
  Size taglia,
) async {
  tester.view.physicalSize = taglia;
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
  return (stato: s, f: f);
}

Future<void> _tocca(WidgetTester tester, Finder fi) async {
  await tester.ensureVisible(fi);
  await tester.pumpAndSettle();
  await tester.runAsync(() async {
    await tester.tap(fi);
    await Future<void>.delayed(const Duration(milliseconds: 30));
  });
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 30)),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Finder _k2(String k) => find.byKey(ValueKey<String>(k));

Future<void> _apriImpostazioni(WidgetTester tester) async {
  await _tocca(tester, find.text(Testi.impostazioni));
}

/// Nessun segreto in impostazioni, file salvati, testi mandati.
void _nessunSegreto(ServiziFinti f) {
  for (final String v in f.imp.values) {
    expect(v, isNot(contains(_k)));
  }
  for (final String v in f.fileSalvati.values) {
    expect(v, isNot(contains(_k)));
  }
  for (final (ConfigIA, String) c in f.chiamateIA) {
    expect(c.$2, isNot(contains(_k)));
  }
}

Future<void> _apriEsporta(WidgetTester tester, ServiziFinti f) async {
  await _tocca(tester, _k2('tasto-progetti'));
  final int id = f.sett
      .firstWhere((SettimanaProgetto s) => s.progettoId == 1)
      .id!;
  await _tocca(tester, _k2('riga-$id'));
  await _tocca(tester, _k2('scheda-esporta'));
}

void main() {
  for (final Size taglia in const <Size>[Size(420, 500), Size(1300, 950)]) {
    testWidgets('impostazioni IA ${taglia.width.toInt()}: salva chiave '
        '(solo ••••), prova con conferma, cancella, nessun overflow', (
      WidgetTester tester,
    ) async {
      final ({StatoApp stato, ServiziFinti f}) a = await _apri(tester, taglia);
      await _apriImpostazioni(tester);
      expect(find.text(Testi.titoloIA), findsOneWidget);
      expect(find.text(Testi.chiaveIASalvata(null)), findsOneWidget);
      // Chiave sbagliata rifiutata.
      await tester.enterText(_k2('ia-chiave'), 'corta');
      await _tocca(tester, _k2('ia-salva-chiave'));
      expect(find.textContaining('troppo corta'), findsOneWidget);
      expect(a.f.chiaviIA, isEmpty);
      // Chiave buona: in cassaforte, campo svuotato, si vede solo la fine.
      await tester.enterText(_k2('ia-chiave'), _k);
      await _tocca(tester, _k2('ia-salva-chiave'));
      expect(a.f.chiaviIA[FornitoreIA.anthropic], _k);
      expect(find.text(Testi.chiaveIASalvata('5555')), findsOneWidget);
      expect(find.text(_k), findsNothing);
      expect(
        tester.widget<TextField>(_k2('ia-chiave')).controller!.text,
        isEmpty,
      );
      // Prova: conferma con costo; Annulla = nessuna chiamata.
      await _tocca(tester, _k2('ia-prova'));
      expect(_k2('ia-conferma'), findsOneWidget);
      expect(find.text(Testi.avvisoCostoIA), findsWidgets);
      await _tocca(tester, _k2('ia-annulla'));
      expect(a.f.chiamateIA, isEmpty);
      await _tocca(tester, _k2('ia-prova'));
      await _tocca(tester, _k2('ia-invia'));
      expect(a.f.chiamateIA.single.$2, testoProva);
      expect(find.text(Testi.provaIAOk), findsOneWidget);
      // Errore mostrato in italiano.
      a.f.risposteIA.add(const ErroreIA('chiave API sbagliata (401)'));
      await _tocca(tester, _k2('ia-prova'));
      await _tocca(tester, _k2('ia-invia'));
      expect(find.textContaining('chiave API sbagliata (401)'), findsOneWidget);
      // Cancella.
      await _tocca(tester, _k2('ia-cancella-chiave'));
      expect(a.f.chiaviIA, isEmpty);
      expect(find.text(Testi.chiaveIASalvata(null)), findsOneWidget);
      _nessunSegreto(a.f);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('impostazioni IA: compatibile mostra URL; fornitore, modello '
      'e URL salvati da soli (impostazioni v2_ia_*)', (
    WidgetTester tester,
  ) async {
    final ({StatoApp stato, ServiziFinti f}) a = await _apri(
      tester,
      const Size(1300, 950),
    );
    await _apriImpostazioni(tester);
    expect(_k2('ia-url'), findsNothing);
    await _tocca(tester, _k2('ia-fornitore'));
    await _tocca(tester, find.text(FornitoreIA.compatibile.nome).last);
    expect(_k2('ia-url'), findsOneWidget);
    expect(a.f.imp[chiaveIAFornitore], 'compatibile');
    await tester.enterText(_k2('ia-url'), 'https://openrouter.ai/api/v1');
    await tester.enterText(_k2('ia-modello'), 'mistral-small');
    // Prova senza chiave va (compatibile): salva anche modello/URL.
    await _tocca(tester, _k2('ia-prova'));
    await _tocca(tester, _k2('ia-invia'));
    final ConfigIA c = a.f.chiamateIA.single.$1;
    expect(c.urlBase, 'https://openrouter.ai/api/v1');
    expect(c.modello, 'mistral-small');
    expect(a.f.imp[chiaveIAUrl], 'https://openrouter.ai/api/v1');
    expect(a.f.imp[FornitoreIA.compatibile.chiaveModello], 'mistral-small');
    expect(a.stato.preferenze.ia.fornitore, FornitoreIA.compatibile);
    expect(tester.takeException(), isNull);
  });

  testWidgets('esporta: Resoconto IA chiede chiave, conferma costo, salva '
      '_resoconto.md, lo mostra, apri file/cartella, elenco salvati', (
    WidgetTester tester,
  ) async {
    final ({StatoApp stato, ServiziFinti f}) a = await _apri(
      tester,
      const Size(420, 500),
    );
    await _apriEsporta(tester, a.f);
    expect(find.text(Testi.nessunResoconto), findsOneWidget);
    // Senza chiave: messaggio, nessuna chiamata.
    await _tocca(tester, _k2('esporta-resoconto'));
    expect(find.text(Testi.mancaChiaveIA), findsOneWidget);
    expect(a.f.chiamateIA, isEmpty);
    a.f.chiaviIA[FornitoreIA.anthropic] = _k;
    // Annulla la conferma: nessuna chiamata.
    await _tocca(tester, _k2('esporta-resoconto'));
    expect(find.text(Testi.avvisoCostoIA), findsOneWidget);
    await _tocca(tester, _k2('ia-annulla'));
    expect(a.f.chiamateIA, isEmpty);
    // Invia: testo export mandato, file salvato e mostrato.
    a.f.risposteIA.add('Settimana regolare, picco giovedì.');
    await _tocca(tester, _k2('esporta-resoconto'));
    await _tocca(tester, _k2('ia-invia'));
    expect(a.f.chiamateIA.single.$2, startsWith('RICHIESTA: '));
    final String percorso = a.f.fileSalvati.keys.single;
    expect(percorso, startsWith('esporta/traker-ia_2026-'));
    expect(percorso, endsWith('_alfa_resoconto.md'));
    expect(a.f.fileSalvati[percorso], startsWith('# Resoconto IA'));
    expect(
      a.f.fileSalvati[percorso],
      contains('Settimana regolare, picco giovedì.'),
    );
    expect(_k2('resoconto-dialogo'), findsOneWidget);
    expect(find.textContaining('picco giovedì'), findsOneWidget);
    await _tocca(tester, _k2('resoconto-apri-file'));
    expect(a.f.collegamenti, contains('apri:$percorso'));
    await _tocca(tester, _k2('resoconto-apri-cartella'));
    expect(a.f.collegamenti, contains('cartella'));
    await _tocca(tester, _k2('resoconto-chiudi'));
    expect(_k2('resoconto-dialogo'), findsNothing);
    // Elenco dei salvati: si riapre dal file.
    final String nome = percorso.substring('esporta/'.length);
    expect(_k2('resoconto-salvato-$nome'), findsOneWidget);
    await _tocca(tester, _k2('resoconto-salvato-$nome'));
    expect(_k2('resoconto-dialogo'), findsOneWidget);
    await _tocca(tester, _k2('resoconto-chiudi'));
    // Errore: mostrato, nessun file nuovo.
    a.f.risposteIA
      ..clear()
      ..add(const ErroreIA('rete assente o fornitore non raggiungibile'));
    await _tocca(tester, _k2('esporta-resoconto'));
    await _tocca(tester, _k2('ia-invia'));
    expect(find.textContaining('rete assente'), findsOneWidget);
    expect(a.f.fileSalvati.length, 1);
    _nessunSegreto(a.f);
    expect(tester.takeException(), isNull);
  });
}
