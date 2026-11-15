// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
import 'package:flutter_test/flutter_test.dart';
import 'package:traker_ia/domain/catena.dart';
import 'package:traker_ia/domain/fornitori.dart';
import 'package:traker_ia/domain/modelli.dart';
import 'package:traker_ia/domain/preferenze.dart';
import 'package:traker_ia/domain/sfondo.dart';

import 'aiuti.dart';

class _Ko implements LettoreUso {
  _Ko(this.id, {required this.scaduto});

  @override
  final String id;

  final bool scaduto;

  @override
  String get nome => id;

  @override
  String get gestore => gestoreAnthropic;

  @override
  Future<Uso> leggi() async => throw ErroreLettura('no', loginScaduto: scaduto);
}

void main() {
  group('fornitori', () {
    test('cookie di sessione trovato tra gli altri', () {
      expect(
        fornitoreClaude.cookieSessione('a=1; sessionKey=sk-ant-xyz; b=2'),
        'sk-ant-xyz',
      );
      expect(fornitoreClaude.cookieSessione('sessionKey=abc'), 'abc');
    });

    test('login non finito: niente cookie di sessione', () {
      expect(fornitoreClaude.cookieSessione(''), isNull);
      expect(fornitoreClaude.cookieSessione('a=1; b=2'), isNull);
      expect(fornitoreClaude.cookieSessione('sessionKey='), isNull);
      expect(fornitoreClaude.cookieSessione('xsessionKey=1'), isNull);
    });

    test('solo Claude per ora, agente senza "wv"', () {
      expect(fornitoriWeb.map((FornitoreWeb f) => f.id), <String>['claude']);
      expect(fornitoreClaude.gestore, gestoreAnthropic);
      expect(agenteWebTelefono.contains('wv'), isFalse);
    });
  });

  group('sfondo', () {
    test('mai sotto 15 minuti', () {
      expect(minutiSfondo(1), 15);
      expect(minutiSfondo(15), 15);
      expect(minutiSfondo(30), 30);
    });

    test('telefono: niente estensione e Claude Code', () {
      expect(metodiDisponibili(telefono: true), <String>[
        'auto',
        'cookie',
        'manuale',
      ]);
      expect(metodiDisponibili(telefono: false), tuttiMetodi);
      expect(metodoValido('estensione', telefono: true), 'auto');
      expect(metodoValido('cookie', telefono: true), 'cookie');
      expect(metodoValido('claude_code', telefono: false), 'claude_code');
    });

    test('lettura automatica prende lavoro, modelli e skill di adesso', () {
      final Preferenze p = Preferenze()
          .tocca(Gruppo.modelli, 'Opus')
          .aggiungi(Gruppo.skill, 'caveman')
          .tocca(Gruppo.skill, 'caveman');
      final Lettura x = letturaAutomatica(
        const Uso(sett: 40, sess: 12),
        DateTime(2026, 11, 14, 9, 30, 45),
        p,
        <Evento>[Evento(ora: t('2026-11-14 08:00'), tipo: TipoEvento.inizio)],
      );
      expect(x.ora, t('2026-11-14 09:30'));
      expect(x.sett, 40);
      expect(x.sess, 12);
      expect(x.lavoro, isTrue);
      expect(x.modelli, 'Opus');
      expect(x.skill, 'caveman');
      expect(x.fonte, 'auto');
    });

    test('al ritorno: legge se vecchia o mancante, ignora le manuali', () {
      final DateTime ora = t('2026-11-14 10:00');
      expect(serveLetturaAlRitorno(<Lettura>[], ora, 10), isTrue);
      expect(
        serveLetturaAlRitorno(<Lettura>[l('2026-11-14 09:55', 1, 1)], ora, 10),
        isFalse,
      );
      expect(
        serveLetturaAlRitorno(<Lettura>[l('2026-11-14 09:50', 1, 1)], ora, 10),
        isTrue,
      );
      final Lettura manuale = Lettura(
        ora: t('2026-11-14 09:59'),
        sett: 1,
        fonte: 'manuale',
      );
      expect(serveLetturaAlRitorno(<Lettura>[manuale], ora, 10), isTrue);
    });
  });

  test('catena: login scaduto passa avanti', () async {
    await expectLater(
      leggiCatena(<LettoreUso>[
        _Ko('a', scaduto: false),
        _Ko('b', scaduto: true),
      ]),
      throwsA(
        isA<ErroreLettura>().having(
          (ErroreLettura e) => e.loginScaduto,
          'scaduto',
          isTrue,
        ),
      ),
    );
    await expectLater(
      leggiCatena(<LettoreUso>[_Ko('a', scaduto: false)]),
      throwsA(
        isA<ErroreLettura>().having(
          (ErroreLettura e) => e.loginScaduto,
          'scaduto',
          isFalse,
        ),
      ),
    );
  });

  group('sottofondo e permessi', () {
    test('minuti a app chiusa: solo 15/30/60, altrimenti 30', () {
      expect(normalizzaMinutiSfondo(15), 15);
      expect(normalizzaMinutiSfondo(60), 60);
      expect(normalizzaMinutiSfondo(10), minutiSfondoPredefiniti);
      expect(normalizzaMinutiSfondo(null), 30);
      final Preferenze p = Preferenze.daMappa(<String, String?>{
        Chiavi.minutiSfondo: '45',
      });
      expect(p.minutiSfondo, 30);
      expect(p.sfondoAcceso, isTrue);
      final Preferenze q = Preferenze.daMappa(
        p.copia(sfondoAcceso: false, minutiSfondo: 60).aMappa(),
      );
      expect(q.sfondoAcceso, isFalse);
      expect(q.minutiSfondo, 60);
    });

    test('sottofondo acceso solo con login, non manuale, interruttore', () {
      final Preferenze p = Preferenze();
      expect(sfondoDaAccendere(p, login: true), isTrue);
      expect(sfondoDaAccendere(p, login: false), isFalse);
      expect(
        sfondoDaAccendere(p.copia(metodo: metodoManuale), login: true),
        isFalse,
      );
      expect(
        sfondoDaAccendere(p.copia(sfondoAcceso: false), login: true),
        isFalse,
      );
    });

    test('pagina permessi: primo avvio o acceso con batteria limitata', () {
      expect(
        chiediPermessi(
          primaVolta: true,
          sfondoAcceso: false,
          batteriaLibera: true,
        ),
        isTrue,
      );
      expect(
        chiediPermessi(
          primaVolta: false,
          sfondoAcceso: true,
          batteriaLibera: false,
        ),
        isTrue,
      );
      expect(
        chiediPermessi(
          primaVolta: false,
          sfondoAcceso: true,
          batteriaLibera: null,
        ),
        isFalse,
      );
      expect(
        chiediPermessi(
          primaVolta: false,
          sfondoAcceso: false,
          batteriaLibera: false,
        ),
        isFalse,
      );
    });
  });
}
