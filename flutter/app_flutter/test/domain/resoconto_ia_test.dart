// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:traker_ia/domain/preferenze.dart';
import 'package:traker_ia/domain/resoconto_ia.dart';

const String _k = 'test-chiave-finta-1234';

Map<String, Object?> _corpo(RichiestaIA r) =>
    jsonDecode(r.corpo) as Map<String, Object?>;

void main() {
  group('ConfigIA', () {
    test('predefiniti, daMappa/aMappa andata e ritorno', () {
      final ConfigIA c = ConfigIA();
      expect(c.fornitore, FornitoreIA.anthropic);
      expect(c.modello, 'claude-sonnet-5-5');
      expect(c.urlBase, 'https://api.anthropic.com');
      final ConfigIA d = c.copia(
        fornitore: FornitoreIA.compatibile,
        modello: 'mistral-small',
        url: ' https://openrouter.ai/api/v1 ',
      );
      expect(d.modello, 'mistral-small');
      expect(d.urlBase, 'https://openrouter.ai/api/v1');
      final ConfigIA e = ConfigIA.daMappa(d.aMappa());
      expect(e, d);
      expect(e.hashCode, d.hashCode);
      // Il modello di un altro fornitore resta il suo.
      expect(e.copia(fornitore: FornitoreIA.openai).modello, 'gpt-5.4-mini');
    });

    test('valori rotti -> predefiniti; modello uguale al predefinito non '
        'salvato', () {
      final ConfigIA c = ConfigIA.daMappa(<String, String?>{
        chiaveIAFornitore: 'boh',
        FornitoreIA.anthropic.chiaveModello: '   ',
      });
      expect(c.fornitore, FornitoreIA.anthropic);
      expect(c.modello, FornitoreIA.anthropic.modelloPredefinito);
      expect(c.copia(modello: 'claude-sonnet-5-5').modelli, isEmpty);
      expect(FornitoreIA.daId('gemini'), FornitoreIA.gemini);
    });

    test('impostazioni: chiavi v2_ia_* in Chiavi.tutte, nessuna parola '
        'segreta, mai la chiave API', () {
      for (final String k in chiaviIA) {
        expect(Chiavi.tutte, contains(k));
        expect(
          RegExp('cookie|token|segret|password|api_key|ia_api').hasMatch(k),
          isFalse,
          reason: k,
        );
      }
      final Preferenze p = Preferenze(ia: ConfigIA().copia(modello: 'x-1'));
      expect(Preferenze.daMappa(p.aMappa()).ia, p.ia);
      for (final FornitoreIA f in FornitoreIA.values) {
        expect(f.chiaveCassaforte, startsWith('ia_api_'));
        expect(chiaviIA, isNot(contains(f.chiaveCassaforte)));
      }
    });
  });

  group('richiesta per fornitore', () {
    test('Anthropic: /v1/messages, x-api-key, versione, max_tokens', () {
      final RichiestaIA r = costruisciRichiesta(ConfigIA(), 'ciao', _k);
      expect(r.url.toString(), 'https://api.anthropic.com/v1/messages');
      expect(r.intestazioni['x-api-key'], _k);
      expect(r.intestazioni['anthropic-version'], versioneAnthropic);
      final Map<String, Object?> b = _corpo(r);
      expect(b['model'], 'claude-sonnet-5-5');
      expect(b['max_tokens'], maxTokenResoconto);
      expect(jsonEncode(b['messages']), contains('ciao'));
    });

    test('OpenAI: /chat/completions, Bearer, niente max_tokens', () {
      final RichiestaIA r = costruisciRichiesta(
        ConfigIA(fornitore: FornitoreIA.openai),
        'ciao',
        _k,
      );
      expect(r.url.toString(), 'https://api.openai.com/v1/chat/completions');
      expect(r.intestazioni['authorization'], 'Bearer $_k');
      expect(_corpo(r).containsKey('max_tokens'), isFalse);
      expect(_corpo(r)['model'], 'gpt-5.4-mini');
    });

    test('Gemini: modello nel percorso, chiave in header (mai nell\'URL)', () {
      final RichiestaIA r = costruisciRichiesta(
        ConfigIA(fornitore: FornitoreIA.gemini),
        'ciao',
        _k,
        maxToken: 16,
      );
      expect(
        r.url.toString(),
        'https://generativelanguage.googleapis.com/v1beta/models/'
        'gemini-flash-latest:generateContent',
      );
      expect(r.url.toString(), isNot(contains(_k)));
      expect(r.intestazioni['x-goog-api-key'], _k);
      expect(jsonEncode(_corpo(r)), contains('"maxOutputTokens":16'));
    });

    test('Compatibile: URL a mano, /chat/completions una volta sola, '
        'chiave facoltativa, http solo per questo PC', () {
      final ConfigIA c = ConfigIA(
        fornitore: FornitoreIA.compatibile,
        modelli: <FornitoreIA, String>{FornitoreIA.compatibile: 'llama3'},
        url: 'http://localhost:11434/v1/',
      );
      final RichiestaIA r = costruisciRichiesta(c, 'ciao', '');
      expect(r.url.toString(), 'http://localhost:11434/v1/chat/completions');
      expect(r.intestazioni.containsKey('authorization'), isFalse);
      final RichiestaIA r2 = costruisciRichiesta(
        c.copia(url: 'https://x.it/v1/chat/completions'),
        'ciao',
        _k,
      );
      expect(r2.url.toString(), 'https://x.it/v1/chat/completions');
      expect(
        () => costruisciRichiesta(c.copia(url: 'http://x.it/v1'), 'c', _k),
        throwsA(isA<ErroreIA>()),
      );
      expect(
        () => costruisciRichiesta(c.copia(url: ''), 'c', _k),
        throwsA(isA<ErroreIA>()),
      );
      expect(
        () => costruisciRichiesta(
          ConfigIA(fornitore: FornitoreIA.compatibile, url: 'https://x.it'),
          'c',
          _k,
        ),
        throwsA(
          isA<ErroreIA>().having(
            (ErroreIA e) => e.messaggio,
            'm',
            contains('modello'),
          ),
        ),
      );
    });

    test('chiave mancante = errore; toString della richiesta senza chiave', () {
      expect(
        () => costruisciRichiesta(ConfigIA(), 'c', '  '),
        throwsA(isA<ErroreIA>()),
      );
      final RichiestaIA r = costruisciRichiesta(ConfigIA(), 'c', _k);
      expect('$r', isNot(contains(_k)));
      expect('$r', contains('api.anthropic.com'));
    });
  });

  group('risposta', () {
    test('testo per i 4 fornitori (salta pensieri e blocchi non testo)', () {
      expect(
        leggiRisposta(FornitoreIA.anthropic, <String, Object?>{
          'content': <Object?>[
            <String, Object?>{'type': 'thinking', 'thinking': 'no'},
            <String, Object?>{'type': 'text', 'text': 'Ciao '},
            <String, Object?>{'type': 'text', 'text': 'Mirko'},
          ],
        }),
        'Ciao Mirko',
      );
      expect(
        leggiRisposta(FornitoreIA.gemini, <String, Object?>{
          'candidates': <Object?>[
            <String, Object?>{
              'content': <String, Object?>{
                'parts': <Object?>[
                  <String, Object?>{'text': 'pensiero', 'thought': true},
                  <String, Object?>{'text': 'Risposta'},
                ],
              },
            },
          ],
        }),
        'Risposta',
      );
      for (final FornitoreIA f in <FornitoreIA>[
        FornitoreIA.openai,
        FornitoreIA.compatibile,
      ]) {
        expect(
          leggiRisposta(f, <String, Object?>{
            'choices': <Object?>[
              <String, Object?>{
                'message': <String, Object?>{'content': ' OK '},
              },
            ],
          }),
          'OK',
        );
      }
    });

    test('vuota o forma strana = ErroreIA "risposta vuota"', () {
      for (final FornitoreIA f in FornitoreIA.values) {
        for (final Object? j in <Object?>[
          null,
          'testo',
          <Object?>[],
          <String, Object?>{'content': <Object?>[]},
          <String, Object?>{'choices': <Object?>[]},
        ]) {
          expect(
            () => leggiRisposta(f, j),
            throwsA(
              isA<ErroreIA>().having(
                (ErroreIA e) => e.messaggio,
                'm',
                contains('vuota'),
              ),
            ),
          );
        }
      }
    });

    test('messaggi errore in italiano per codice', () {
      expect(messaggioErroreIA(401), contains('chiave API sbagliata'));
      expect(messaggioErroreIA(403), contains('chiave API sbagliata'));
      expect(messaggioErroreIA(402), contains('credito'));
      expect(messaggioErroreIA(429), contains('limite'));
      expect(messaggioErroreIA(404), contains('modello'));
      expect(messaggioErroreIA(503), contains('riprova'));
      expect(messaggioErroreIA(418), contains('418'));
    });
  });

  group('chiave e file', () {
    test('problemaChiave / fineChiave / senzaChiave', () {
      expect(problemaChiave(_k), isNull);
      expect(problemaChiave(''), isNotNull);
      expect(problemaChiave('corta'), isNotNull);
      expect(problemaChiave('con spazio dentro'), isNotNull);
      expect(problemaChiave('àccentata-12345'), isNotNull);
      expect(fineChiave(_k), '1234');
      expect(fineChiave('abc'), '');
      expect(senzaChiave('eco $_k fine', _k), isNot(contains(_k)));
      expect(senzaChiave('testo', ''), 'testo');
    });

    test('nome file resoconto e riconoscimento per settimana', () {
      final DateTime i = DateTime(2026, 11, 10, 20);
      final String n = nomeFileResoconto(i, nome: 'Progetto X');
      expect(n, 'traker-ia_2026-11-10_progetto-x_resoconto.md');
      expect(nomeFileResoconto(i), 'traker-ia_2026-11-10_resoconto.md');
      expect(eResoconto(n), isTrue);
      expect(eResoconto(n, inizio: i), isTrue);
      expect(eResoconto(n, inizio: DateTime(2026, 11, 17)), isFalse);
      expect(eResoconto('traker-ia_2026-11-10_progetto-x.md'), isFalse);
      expect(eResoconto('altro_resoconto.md'), isFalse);
    });

    test('testo del file: intestazione, risposta, mai la chiave', () {
      final String t = testoFileResoconto(
        risposta: 'Settimana tranquilla. $_k',
        config: ConfigIA(),
        creato: DateTime(2026, 11, 17, 9, 5),
        chiave: _k,
      );
      expect(t, startsWith('# Resoconto IA'));
      expect(t, contains('2026-11-17 09:05'));
      expect(t, contains('Anthropic (Claude)'));
      expect(t, contains('Settimana tranquilla.'));
      expect(t, isNot(contains(_k)));
    });
  });
}
