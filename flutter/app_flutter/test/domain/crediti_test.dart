// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
//
// B19: crediti di utilizzo letti dal blocco 'spend' di /usage (solo valore
// attuale per la carta CREDITI, niente storico).
import 'package:flutter_test/flutter_test.dart';
import 'package:traker_ia/domain/analisi.dart';
import 'package:traker_ia/domain/modelli.dart';

void main() {
  test('forma vera claude.ai (20/11): 0,00 \$ usati, spenti', () {
    final Uso u = leggiRisposta(<String, Object?>{
      'seven_day': <String, Object?>{'utilization': 71},
      'spend': <String, Object?>{
        'used': <String, Object?>{
          'amount_minor': 0,
          'currency': 'USD',
          'exponent': 2,
        },
        'limit': null,
        'percent': 0,
        'enabled': false,
      },
    });
    final Crediti c = u.crediti!;
    expect(c.usati, 0);
    expect(c.valuta, 'USD');
    expect(c.attivi, isFalse);
    expect(c.limite, isNull);
    expect(testoCrediti(c), (valore: r'0,00 $', sotto: 'usati  ·  spenti'));
  });

  test('attivi con limite: importi in unità minori convertiti', () {
    final Crediti c = leggiCrediti(<String, Object?>{
      'spend': <String, Object?>{
        'used': <String, Object?>{
          'amount_minor': 1234,
          'currency': 'EUR',
          'exponent': 2,
        },
        'limit': <String, Object?>{
          'amount_minor': 5000,
          'currency': 'EUR',
          'exponent': 2,
        },
        'enabled': true,
      },
    })!;
    expect(c.usati, closeTo(12.34, 1e-9));
    expect(c.limite, closeTo(50, 1e-9));
    expect(testoCrediti(c), (
      valore: '12,34 €',
      sotto: 'usati di 50,00 €  ·  attivi',
    ));
  });

  test('spend assente o rotto -> null, carta in attesa', () {
    expect(leggiCrediti(null), isNull);
    expect(leggiCrediti(<String, Object?>{'spend': null}), isNull);
    expect(
      leggiCrediti(<String, Object?>{
        'spend': <String, Object?>{'used': 'x'},
      }),
      isNull,
    );
    expect(leggiRisposta(<String, Object?>{}).crediti, isNull);
    expect(testoCrediti(null), (valore: '—', sotto: 'in attesa di lettura'));
  });

  test('simbolo valuta e formato soldi', () {
    expect(simboloValuta('usd'), r'$');
    expect(simboloValuta('CHF'), 'CHF');
    expect(soldi(3.5, 'GBP'), '3,50 £');
  });
}
