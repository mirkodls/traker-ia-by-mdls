// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:traker_ia/domain/modelli.dart';
import 'package:traker_ia/domain/preferenze.dart';
import 'package:traker_ia/domain/tempo.dart';
import 'package:traker_ia/domain/traduzioni/testi_it.dart';
import 'package:traker_ia/ui/app.dart';
import 'package:traker_ia/ui/grafico.dart';
import 'package:traker_ia/ui/sezioni.dart';
import 'package:traker_ia/ui/stato_app.dart';

import 'servizi_finti.dart';

DateTime _t(String s) => interpreta(s)!;

Future<StatoApp> _apri(
  WidgetTester tester,
  Size taglia, {
  bool modelliSkill = false,
}) async {
  tester.view.physicalSize = taglia;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final ServiziFinti f = ServiziFinti()
    ..risposte.add(const Uso(sett: 25, sess: 9));
  if (modelliSkill) {
    f.imp[Chiavi.v2ModelliSkill] = '1';
  }
  f.lett.addAll(<Lettura>[
    Lettura(ora: _t('2026-11-13 08:00'), sett: 20, sess: 3, modelli: 'Opus'),
    Lettura(ora: _t('2026-11-13 10:00'), sett: 23, sess: 8, modelli: 'Opus'),
  ]);
  f.ev.add(
    Evento(ora: _t('2026-11-13 09:00'), tipo: TipoEvento.nota, testo: 'prova'),
  );
  final StatoApp s = StatoApp(
    f,
    orologio: () => _t('2026-11-13 11:00'),
    giri: false,
  );
  await tester.runAsync(s.avvia);
  await tester.pumpWidget(TrakerApp(stato: s));
  await tester.pump();
  return s;
}

void main() {
  testWidgets('V2 base: niente modelli/skill, note restano', (
    WidgetTester tester,
  ) async {
    await _apri(tester, const Size(1300, 950));
    expect(find.byType(BarraTasti), findsNothing);
    expect(find.text(Testi.gruppoModelli), findsNothing);
    expect(find.text(Testi.combinazioni), findsNothing);
    expect(find.byType(RigaNota), findsOneWidget);
    expect(find.text(Testi.aggiungiNota), findsOneWidget);
    expect(find.text(Testi.nota), findsOneWidget);
    expect(find.textContaining('SKILL / MODELLI'), findsNothing);
    expect(find.textContaining('NOTA'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('V2 flag acceso: tasti e combinazioni tornano', (
    WidgetTester tester,
  ) async {
    await _apri(tester, const Size(1300, 950), modelliSkill: true);
    expect(find.byType(BarraTasti), findsOneWidget);
    expect(find.text(Testi.combinazioni), findsOneWidget);
    expect(find.byType(RigaNota), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('riquadro mouse: righe modelli/skill solo con flag', () {
    final List<Lettura> l = <Lettura>[
      Lettura(ora: _t('2026-11-13 08:00'), sett: 20, modelli: 'Opus'),
      Lettura(ora: _t('2026-11-13 10:00'), sett: 23, modelli: 'Opus'),
    ];
    final DateTime t = _t('2026-11-13 09:00');
    expect(testoMouse(l, t), isNot(contains(Testi.rqModelli)));
    expect(testoMouse(l, t, modelliSkill: true), contains(Testi.rqModelli));
  });

  testWidgets('finestra larga: carte, grafico, sezioni', (
    WidgetTester tester,
  ) async {
    await _apri(tester, const Size(1300, 950));
    expect(find.text(Testi.cartaSett), findsOneWidget);
    expect(find.text(Testi.cartaSess), findsOneWidget);
    expect(find.text('23%'), findsOneWidget);
    expect(find.textContaining('CONFRONTI'), findsWidgets);
    expect(find.text(Testi.leggiOra), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('finestra stretta e piccola: niente errori di spazio', (
    WidgetTester tester,
  ) async {
    await _apri(tester, const Size(420, 500));
    final Object? e = tester.takeException();
    if (e is FlutterError) {
      debugPrint(e.toStringDeep());
    }
    expect(e, isNull);
    expect(find.text(Testi.cartaSett), findsOneWidget);
  });

  testWidgets('mouse sul grafico: riquadro con valori', (
    WidgetTester tester,
  ) async {
    await _apri(tester, const Size(1300, 950));
    final Finder g = find.byType(CustomPaint).at(0);
    expect(g, findsOneWidget);
    final TestGesture m = await tester.createGesture(
      kind: PointerDeviceKind.mouse,
    );
    await m.addPointer(location: Offset.zero);
    addTearDown(m.removePointer);
    final Rect r = tester.getRect(
      find
          .byWidgetPredicate(
            (Widget w) => w.runtimeType.toString() == 'Grafico',
          )
          .first,
    );
    await m.moveTo(Offset(r.left + r.width * 0.6, r.top + r.height * 0.7));
    await tester.pump();
    expect(find.textContaining('Sett:'), findsOneWidget);
    await m.moveTo(Offset.zero);
    await tester.pump();
  });

  testWidgets('leggi ora, nota, inizio lavoro', (WidgetTester tester) async {
    final StatoApp s = await _apri(tester, const Size(1300, 950));
    await tester.runAsync(() async {
      await tester.tap(find.text(Testi.leggiOra));
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pump();
    expect(s.letture.length, 3);
    await tester.ensureVisible(find.text(Testi.aggiungiNota));
    await tester.pump();
    await tester.enterText(find.byType(TextField).first, 'nuova nota');
    await tester.runAsync(() async {
      await tester.tap(find.text(Testi.aggiungiNota));
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pump();
    expect(s.note.length, 2);
    await tester.runAsync(() async {
      await tester.tap(find.text(Testi.inizioLavoro));
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pump();
    expect(find.text(Testi.fineLavoro), findsOneWidget);
  });

  testWidgets('impostazioni e lettura manuale si aprono', (
    WidgetTester tester,
  ) async {
    await _apri(tester, const Size(1300, 950));
    await tester.tap(find.text(Testi.impostazioni));
    await tester.pumpAndSettle();
    expect(find.text(Testi.campoCookie), findsOneWidget);
    await tester.tap(find.text(Testi.annulla));
    await tester.pumpAndSettle();
    await tester.tap(find.text(Testi.letturaManuale));
    await tester.pumpAndSettle();
    expect(find.text(Testi.campoSett), findsOneWidget);
  });
}
