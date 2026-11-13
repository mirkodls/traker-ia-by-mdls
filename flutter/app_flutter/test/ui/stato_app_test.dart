// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
import 'package:flutter_test/flutter_test.dart';
import 'package:traker_ia/domain/catena.dart';
import 'package:traker_ia/domain/modelli.dart';
import 'package:traker_ia/domain/preferenze.dart';
import 'package:traker_ia/domain/tempo.dart';
import 'package:traker_ia/domain/vista.dart';
import 'package:traker_ia/ui/stato_app.dart';

import 'servizi_finti.dart';

DateTime _t(String s) => interpreta(s)!;

void main() {
  late ServiziFinti f;
  late DateTime ora;
  StatoApp nuovo() => StatoApp(f, orologio: () => ora, giri: false);

  setUp(() {
    f = ServiziFinti();
    ora = _t('2026-11-13 12:00');
  });

  test('primo avvio: importa da solo una volta, poi mai più', () async {
    f.daImportare = <Lettura>[Lettura(ora: _t('2026-11-12 10:00'), sett: 30)];
    final StatoApp s = nuovo();
    await s.avvia();
    expect(f.importate, <String>['vecchi']);
    expect(s.letture.length, 1);
    expect(f.imp[Chiavi.importFatto], '1');
    expect(s.cartaSett.valore, 30);
    f.lett.clear();
    final StatoApp s2 = nuovo();
    await s2.avvia();
    expect(f.importate.length, 1);
  });

  test('archivio già pieno: niente import automatico', () async {
    f.lett.add(Lettura(ora: _t('2026-11-12 10:00'), sett: 30));
    await nuovo().avvia();
    expect(f.importate, isEmpty);
  });

  test('lettura ok: salva con modelli/skill accesi e lavoro', () async {
    f.risposte.add(const Uso(sett: 40, sess: 12));
    final StatoApp s = nuovo();
    await s.avvia();
    await s.tocca(Gruppo.modelli, 'Opus');
    await s.aggiungiTasto(Gruppo.skill, 'caveman');
    await s.tocca(Gruppo.skill, 'caveman');
    await s.cambiaLavoro();
    await s.leggi();
    final Lettura l = f.lett.single;
    expect(l.sett, 40);
    expect(l.sess, 12);
    expect(l.modelli, 'Opus');
    expect(l.skill, 'caveman');
    expect(l.lavoro, isTrue);
    expect(s.statoErrore, isFalse);
    expect(s.cartaSess.valore, 12);
    expect(f.imp[Chiavi.modelliAttivi], '["Opus"]');
  });

  test('2 letture fallite di fila: avviso una volta sola', () async {
    f.risposte.add(const ErroreLettura('rete giù'));
    final StatoApp s = nuovo();
    await s.avvia();
    await s.leggi();
    expect(s.statoErrore, isTrue);
    expect(s.avvisoDaMostrare, isNull);
    await s.leggi();
    expect(s.avvisoDaMostrare, 'rete giù');
    s.avvisoVisto();
    await s.leggi();
    expect(s.avvisoDaMostrare, isNull);
  });

  test('metodo manuale: niente lettura automatica', () async {
    f.imp[Chiavi.metodo] = metodoManuale;
    final StatoApp s = nuovo();
    await s.avvia();
    await s.leggi();
    expect(f.metodi, isEmpty);
  });

  test('manuale, nota e confronto prima/dopo', () async {
    final StatoApp s = nuovo();
    await s.avvia();
    await s.aggiungiManuale(_t('2026-11-13 08:00'), 10, null);
    await s.aggiungiManuale(_t('2026-11-13 10:00'), 12, null);
    await s.aggiungiNota('  ');
    expect(s.note, isEmpty);
    await s.aggiungiNota('caveman acceso');
    ora = _t('2026-11-13 14:00');
    await s.aggiungiManuale(_t('2026-11-13 14:00'), 13, null);
    expect(f.lett.first.fonte, 'manuale');
    expect(s.note.single.testo, 'caveman acceso');
    expect(s.confrontoNota, isNotNull);
    expect(s.confrontoNota!.prima, closeTo(0.625, 1e-9));
    expect(s.confrontoNota!.dopo, closeTo(0.25, 1e-9));
    expect(s.frasi, isNotEmpty);
    expect(s.grafico!.note.single.numero, 1);
  });

  test('vista: salvata e primo piano chiesto alla finestra', () async {
    final StatoApp s = nuovo();
    await s.avvia();
    await s.cambiaPrimoPiano();
    expect(f.primoPianoChiamate, <bool>[true]);
    await s.scegliModo(ModoVista.grafico);
    expect(f.imp[Chiavi.vista], contains('"modo":"grafico"'));
    final StatoApp s2 = nuovo();
    await s2.avvia();
    expect(s2.vista.modo, ModoVista.grafico);
    expect(f.primoPianoChiamate, <bool>[true, true]);
  });

  test('impostazioni: cookie, minuti, metodo', () async {
    f.risposte.add(const Uso(sett: 1));
    final StatoApp s = nuovo();
    await s.avvia();
    await s.salvaImpostazioni(
      minuti: 6,
      metodo: 'cookie',
      cartella: ' c:/dati ',
      cookie: 'abc',
    );
    expect(s.cookie, isTrue);
    expect(s.preferenze.minuti, 6);
    expect(f.metodi.last, 'cookie');
    expect(f.imp[Chiavi.cartellaImport], 'c:/dati');
    expect(f.imp.values.join(), isNot(contains('abc')));
    await s.salvaImpostazioni(
      minuti: 6,
      metodo: 'cookie',
      cartella: '',
      cookie: '',
    );
    expect(s.cookie, isFalse);
  });

  test('combinazioni: A e B, classifica', () async {
    final StatoApp s = nuovo();
    await s.avvia();
    f.lett.addAll(<Lettura>[
      Lettura(ora: _t('2026-11-13 06:00'), sett: 10, modelli: 'Opus'),
      Lettura(ora: _t('2026-11-13 08:00'), sett: 14, modelli: 'Opus'),
      Lettura(ora: _t('2026-11-13 10:00'), sett: 15, modelli: 'Sonnet'),
    ]);
    await s.aggiungiManuale(_t('2026-11-13 11:00'), 15.5, null);
    expect(s.combinazioni.length, greaterThanOrEqualTo(2));
    expect(s.confrontoCombo, isNotNull);
    expect(s.classifica, contains('Opus'));
  });
}
