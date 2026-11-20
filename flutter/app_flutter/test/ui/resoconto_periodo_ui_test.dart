// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
//
// B20: dialogo resoconto con scelta periodo (Giorno / Settimana /
// Progetto), tasto Resoconto IA sul progetto, fine a mano; nessun overflow
// a 420x500, 1300x950, 360x640.
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:traker_ia/domain/export_ia.dart';
import 'package:traker_ia/domain/modelli.dart';
import 'package:traker_ia/domain/traduzioni/testi_it.dart';
import 'package:traker_ia/ui/app.dart';
import 'package:traker_ia/ui/stato_app.dart';

import 'progetti_helper.dart';
import 'servizi_finti.dart';

Future<ServiziFinti> _apri(WidgetTester tester, Size taglia) async {
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
  return f;
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

Finder _k(String k) => find.byKey(ValueKey<String>(k));

/// Salva .md e torna il testo salvato con quel nome.
Future<String> _salva(WidgetTester tester, ServiziFinti f, String nome) async {
  f.fileSalvati.clear();
  await _tocca(tester, _k('esporta-salva'));
  expect(f.fileSalvati.keys.single, endsWith(nome));
  return f.fileSalvati.values.single;
}

void main() {
  for (final Size taglia in const <Size>[
    Size(420, 500),
    Size(1300, 950),
    Size(360, 640),
  ]) {
    final String n = '${taglia.width.toInt()}x${taglia.height.toInt()}';

    testWidgets('$n: giorno -> settimana, solo dati del periodo', (
      WidgetTester tester,
    ) async {
      final ServiziFinti f = await _apri(tester, taglia);
      await _tocca(tester, _k('tasto-progetti'));
      await _tocca(tester, _k('resoconto-ia'));
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(_k('periodo-tipo'), findsOneWidget);
      expect(tester.takeException(), isNull);
      // Giorno di oggi (17/11).
      String t = await _salva(tester, f, 'traker-ia_2026-11-17_giorno.md');
      expect(t, contains('PERIODO: tipo=giorno da=2026-11-17 00:00'));
      expect(t, contains('(in corso, fino ad adesso)'));
      expect(t, isNot(contains('  2026-11-16 n=')));
      expect(parolaVietataEsportazione.hasMatch(t), isFalse);
      // Giorno prima.
      await _tocca(tester, _k('periodo-prima'));
      t = await _salva(tester, f, 'traker-ia_2026-11-16_giorno.md');
      expect(t, contains('da=2026-11-16 00:00 a=2026-11-17 00:00'));
      expect(t, isNot(contains('  2026-11-17 n=')));
      // Settimana in corso.
      await _tocca(tester, find.text(Testi.periodoSettimana));
      t = await _salva(tester, f, 'traker-ia_2026-11-10_settimana.md');
      expect(t, contains('PERIODO: tipo=settimana da=2026-11-10 20:00'));
      // Settimana prima: istantanea archiviata.
      await _tocca(tester, _k('periodo-prima'));
      t = await _salva(tester, f, 'traker-ia_2026-11-03_settimana.md');
      expect(t, contains('a=2026-11-10 20:00 '));
      expect(tester.takeException(), isNull);
    });

    testWidgets('$n: tasto Resoconto IA del progetto + fine a mano', (
      WidgetTester tester,
    ) async {
      final ServiziFinti f = await _apri(tester, taglia);
      await _tocca(tester, _k('tasto-progetti'));
      await _tocca(tester, _k('resoconto-progetto-1'));
      expect(_k('periodo-progetto'), findsOneWidget);
      expect(_k('periodo-scelta'), findsOneWidget);
      expect(tester.takeException(), isNull);
      // Ultimo periodo di Alfa: 10/11 22:00 -> 12/11 02:00.
      String t = await _salva(
        tester,
        f,
        'traker-ia_2026-11-10_progetto-alfa.md',
      );
      expect(t, contains('PROGETTO: "Alfa"'));
      expect(t, contains('da=2026-11-10 22:00 a=2026-11-12 02:00'));
      expect(t, contains('fine=da nota fine'));
      // Fine spostata a mano di 1 ora.
      await _tocca(tester, _k('fine-meno-ora'));
      expect(find.textContaining('(scelta a mano)'), findsOneWidget);
      t = await _salva(tester, f, 'traker-ia_2026-11-10_progetto-alfa.md');
      expect(t, contains('a=2026-11-12 01:00'));
      expect(t, contains('scelta a mano'));
      // Torna automatica.
      await _tocca(tester, _k('fine-automatica'));
      expect(find.textContaining('(scelta a mano)'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
