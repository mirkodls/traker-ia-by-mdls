// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
import 'package:flutter_test/flutter_test.dart';
import 'package:traker_ia/domain/modelli.dart';
import 'package:traker_ia/domain/periodo.dart';
import 'package:traker_ia/domain/preferenze.dart';
import 'package:traker_ia/domain/traduzioni/testi_it.dart';

import 'aiuti.dart';

void main() {
  test(
    'V2 flag: base modelli/skill spenti, lavoro acceso; andata e ritorno',
    () {
      final Preferenze p = Preferenze.daMappa(<String, String?>{});
      expect(p.modelliSkill, isFalse);
      expect(p.lavoroV2, isTrue);
      expect(p.aMappa()[Chiavi.v2ModelliSkill], '0');
      expect(p.aMappa()[Chiavi.v2Lavoro], '1');
      final Preferenze q = Preferenze.daMappa(
        p.copia(modelliSkill: true, lavoroV2: false).aMappa(),
      );
      expect(q.modelliSkill, isTrue);
      expect(q.lavoroV2, isFalse);
      expect(
        Chiavi.tutte,
        containsAll(<String>[Chiavi.v2ModelliSkill, Chiavi.v2Lavoro]),
      );
    },
  );

  test('V2 flag spento: nessun modello/skill raccolto nelle letture', () {
    final Preferenze p = Preferenze(
      skill: <String>['caveman'],
      modelliAttivi: <String>['Opus'],
      skillAttive: <String>['caveman'],
    );
    expect(p.attiviTesto(Gruppo.modelli), 'Opus');
    expect(p.daRaccogliere(Gruppo.modelli), '');
    expect(p.daRaccogliere(Gruppo.skill), '');
    final Preferenze on = p.copia(modelliSkill: true);
    expect(on.daRaccogliere(Gruppo.modelli), 'Opus');
    expect(on.daRaccogliere(Gruppo.skill), 'caveman');
  });

  test('mappa vuota o rotta -> predefiniti', () {
    final Preferenze p = Preferenze.daMappa(<String, String?>{
      Chiavi.minuti: 'x',
      Chiavi.modelli: '{rotto',
      Chiavi.periodo: '99',
    });
    expect(p.minuti, minutiPredefiniti);
    expect(p.metodo, 'auto');
    expect(p.modelli, modelliIniziali);
    expect(p.skill, isEmpty);
    expect(p.periodo, scattoPredefinito);
    expect(p.soloLavoro, isFalse);
  });

  test('andata e ritorno mappa', () {
    final Preferenze p = Preferenze(
      minuti: 6,
      metodo: 'cookie',
      skill: <String>['caveman'],
      modelliAttivi: <String>['Opus'],
      skillAttive: <String>['caveman'],
      periodo: 1,
      soloLavoro: true,
    );
    final Preferenze q = Preferenze.daMappa(p.aMappa());
    expect(q.minuti, 6);
    expect(q.metodo, 'cookie');
    expect(q.skill, <String>['caveman']);
    expect(q.modelliAttivi, <String>['Opus']);
    expect(q.periodo, 1);
    expect(q.soloLavoro, isTrue);
  });

  test('tocca, attiviTesto solo nomi in elenco e normalizzati', () {
    Preferenze p = Preferenze();
    p = p.tocca(Gruppo.modelli, 'Sonnet').tocca(Gruppo.modelli, 'Opus');
    expect(p.attiviTesto(Gruppo.modelli), 'Opus|Sonnet');
    p = p.tocca(Gruppo.modelli, 'Opus');
    expect(p.attiviTesto(Gruppo.modelli), 'Sonnet');
    p = Preferenze(modelliAttivi: <String>['Vecchio', 'Opus']);
    expect(p.attiviTesto(Gruppo.modelli), 'Opus');
  });

  test('nomi: valido, doppio, aggiungi, rinomina, togli, riordina', () {
    Preferenze p = Preferenze(skill: <String>['caveman']);
    expect(p.erroreNome(Gruppo.skill, ''), isNotNull);
    expect(p.erroreNome(Gruppo.skill, 'a|b'), isNotNull);
    expect(p.erroreNome(Gruppo.skill, 'x' * 21), isNotNull);
    expect(p.erroreNome(Gruppo.skill, 'CAVEMAN'), 'doppio');
    expect(p.erroreNome(Gruppo.skill, 'Caveman', vecchio: 'caveman'), isNull);
    p = p.aggiungi(Gruppo.skill, ' risparmio ').tocca(Gruppo.skill, 'caveman');
    expect(p.skill, <String>['caveman', 'risparmio']);
    expect(p.aggiungi(Gruppo.skill, 'caveman').skill.length, 2);
    p = p.rinomina(Gruppo.skill, 'caveman', 'cave');
    expect(p.skill, <String>['cave', 'risparmio']);
    expect(p.skillAttive, <String>['cave']);
    p = p.riordina(Gruppo.skill, <String>['risparmio', 'cave']);
    expect(p.skill.first, 'risparmio');
    p = p.togli(Gruppo.skill, 'cave');
    expect(p.skill, <String>['risparmio']);
    expect(p.skillAttive, isEmpty);
  });

  test('lavoro aperto', () {
    expect(lavoroAperto(<Evento>[]), isFalse);
    final List<Evento> ev = <Evento>[
      Evento(ora: t('2026-11-13 10:00'), tipo: TipoEvento.inizio),
      Evento(ora: t('2026-11-13 11:00'), tipo: TipoEvento.nota, testo: 'x'),
    ];
    expect(lavoroAperto(ev), isTrue);
    ev.add(Evento(ora: t('2026-11-13 12:00'), tipo: TipoEvento.fine));
    expect(lavoroAperto(ev), isFalse);
  });

  test('percentuale scritta a mano', () {
    expect(percentoUtente(''), isNull);
    expect(percentoUtente(' 21,5% '), 21.5);
    expect(percentoUtente('7'), 7);
    expect(() => percentoUtente('abc'), throwsFormatException);
    expect(() => percentoUtente('101'), throwsFormatException);
  });

  test('testi: percento ed etichette scatti', () {
    expect(percento(21), '21%');
    expect(percento(21.54), '21,5%');
    expect(percento(null), '-');
    expect(Testi.scatti.length, oreScatti.length);
  });
}
