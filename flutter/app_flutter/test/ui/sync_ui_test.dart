// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
//
// B22: sezione Sync in Impostazioni > Generale (PC e telefono).
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:traker_ia/domain/modelli.dart';
import 'package:traker_ia/domain/preferenze.dart';
import 'package:traker_ia/domain/sync_dati.dart';
import 'package:traker_ia/domain/tempo.dart';
import 'package:traker_ia/domain/traduzioni/testi_it.dart';
import 'package:traker_ia/ui/app.dart';
import 'package:traker_ia/ui/stato_app.dart';

import 'servizi_finti.dart';

DateTime _t(String s) => interpreta(s)!;

Future<({StatoApp stato, ServiziFinti f})> _apri(
  WidgetTester tester,
  Size taglia, {
  bool telefono = false,
  List<String> abbinati = const <String>[],
}) async {
  tester.view.physicalSize = taglia;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final ServiziFinti f = ServiziFinti()
    ..tel = telefono
    ..cookie = telefono ? 'sk' : ''
    ..batteria = true
    ..imp[Chiavi.permessiChiesti] = '1'
    ..risposte.add(const Uso(sett: 52, sess: 9));
  f.abbinatiFinti.addAll(abbinati);
  f.lett.add(Lettura(ora: _t('2026-11-13 10:00'), sett: 51, sess: 8));
  final StatoApp s = StatoApp(
    f,
    orologio: () => _t('2026-11-13 11:00'),
    giri: false,
  );
  await tester.runAsync(s.avvia);
  await tester.pumpWidget(TrakerApp(stato: s));
  await tester.pump();
  if (telefono) {
    await tester.tap(find.byTooltip(Testi.impostazioni));
    await tester.pumpAndSettle();
  }
  await tester.tap(find.text(Testi.impostazioni));
  await tester.pumpAndSettle();
  await tester.scrollUntilVisible(
    find.byKey(const Key('sync-abbina')),
    200,
    scrollable: find.byType(Scrollable).last,
  );
  await tester.pumpAndSettle();
  return (stato: s, f: f);
}

void main() {
  testWidgets('PC: Abbina telefono mostra il codice grande, 420x500 ok', (
    WidgetTester tester,
  ) async {
    await _apri(tester, const Size(420, 500));
    expect(find.text(Testi.nessunTelefono), findsOneWidget);
    await tester.tap(find.byKey(const Key('sync-abbina')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('sync-codice-pc')), findsOneWidget);
    expect(find.text('123456'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byKey(const Key('sync-chiudi')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('sync-codice-pc')), findsNothing);
  });

  testWidgets('PC: abbinati elencati + Dimentica', (WidgetTester tester) async {
    final ({StatoApp stato, ServiziFinti f}) a = await _apri(
      tester,
      const Size(1300, 950),
      abbinati: <String>['Telefono'],
    );
    expect(
      find.text(Testi.telefoniAbbinati(<String>['Telefono'])),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('sync-dimentica')));
    await tester.pumpAndSettle();
    expect(a.f.abbinatiFinti, isEmpty);
    expect(find.text(Testi.nessunTelefono), findsOneWidget);
  });

  testWidgets(
    'telefono: abbina col codice del PC, poi Sincronizza ora (360x640)',
    (WidgetTester tester) async {
      final ({StatoApp stato, ServiziFinti f}) a = await _apri(
        tester,
        const Size(360, 640),
        telefono: true,
      );
      expect(find.text(Testi.tastoAbbinaPc), findsOneWidget);
      expect(find.byKey(const Key('sync-ora')), findsNothing);
      await tester.tap(find.byKey(const Key('sync-abbina')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('sync-codice')), '123456');
      await tester.tap(find.byKey(const Key('sync-conferma')));
      await tester.pumpAndSettle();
      expect(find.text('Abbinato a PC.'), findsOneWidget);
      expect(find.text(Testi.pcAbbinato('PC')), findsOneWidget);
      a.f.esitoSync = EsitoSync(ok: true, messaggio: Testi.syncFatto('PC', 4));
      await tester.tap(find.byKey(const Key('sync-ora')));
      await tester.pumpAndSettle();
      expect(a.f.sync, 1);
      expect(find.text(Testi.syncFatto('PC', 4)), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('telefono: errore sync in rosso, nessun overflow 360x640', (
    WidgetTester tester,
  ) async {
    final ({StatoApp stato, ServiziFinti f}) a = await _apri(
      tester,
      const Size(360, 640),
      telefono: true,
      abbinati: <String>['PC'],
    );
    a.f.esitoSync = const EsitoSync(
      ok: false,
      messaggio: Testi.syncPcNonTrovato,
    );
    await tester.tap(find.byKey(const Key('sync-tutto')));
    await tester.pumpAndSettle();
    final Text t = tester.widget<Text>(find.byKey(const Key('sync-messaggio')));
    expect(t.data, Testi.syncPcNonTrovato);
    expect(t.style?.color, isNotNull);
    expect(tester.takeException(), isNull);
  });

  for (final (String prima, int dopo) c in <(String, int)>[
    ('30', 60),
    ('15', 15),
    ('', 60),
  ]) {
    test(
      'B22 telefono: sottofondo "${c.$1}" -> ${c.$2} min una volta sola',
      () async {
        final ServiziFinti f = ServiziFinti()
          ..tel = true
          ..cookie = 'sk'
          ..batteria = true
          ..imp[Chiavi.permessiChiesti] = '1';
        if (c.$1 != '') {
          f.imp[Chiavi.minutiSfondo] = c.$1;
        }
        final StatoApp s = StatoApp(
          f,
          orologio: () => _t('2026-11-13 11:00'),
          giri: false,
        );
        await s.avvia();
        expect(s.preferenze.minutiSfondo, c.$2);
        expect(f.imp['b22_sfondo_60'], '1');
        // Dopo: scelta a mano 30 resta 30.
        f.imp[Chiavi.minutiSfondo] = '30';
        final StatoApp s2 = StatoApp(
          f,
          orologio: () => _t('2026-11-13 11:00'),
          giri: false,
        );
        await s2.avvia();
        expect(s2.preferenze.minutiSfondo, 30);
      },
    );
  }
}
