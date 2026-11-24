// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:traker_ia/domain/sync_cifra.dart';

void main() {
  test(
    'primo gruppo 14: 2048 bit, inizio/fine RFC 3526, primo sicuro (Fermat)',
    () {
      expect(primoDH.bitLength, 2048);
      final String h = primoDH.toRadixString(16).toUpperCase();
      expect(h.startsWith('FFFFFFFFFFFFFFFFC90FDAA22168C234'), isTrue);
      expect(h.endsWith('FFFFFFFFFFFFFFFF'), isTrue);
      final BigInt q = (primoDH - BigInt.one) >> 1;
      expect(BigInt.from(3).modPow(primoDH - BigInt.one, primoDH), BigInt.one);
      expect(BigInt.from(3).modPow(q - BigInt.one, q), BigInt.one);
    },
  );

  test('DH: stesso segreto, stessa chiave, stesso codice a 6 cifre', () {
    final ChiaviDH t = ChiaviDH.nuove(Random(1));
    final ChiaviDH p = ChiaviDH.nuove(Random(2));
    final Uint8List kt = chiaveCoppia(
      t.segreto(p.pubblica),
      t.pubblica,
      p.pubblica,
    );
    final Uint8List kp = chiaveCoppia(
      p.segreto(t.pubblica),
      t.pubblica,
      p.pubblica,
    );
    expect(kt, kp);
    expect(kt.length, 32);
    expect(codiceAbbinamento(kt), codiceAbbinamento(kp));
    expect(RegExp(r'^\d{6}$').hasMatch(codiceAbbinamento(kt)), isTrue);
    // Chi sta in mezzo con un'altra chiave ottiene un altro codice.
    final ChiaviDH m = ChiaviDH.nuove(Random(3));
    final Uint8List km = chiaveCoppia(
      t.segreto(m.pubblica),
      t.pubblica,
      m.pubblica,
    );
    expect(km, isNot(kt));
  });

  test('pubbliche fuori gruppo rifiutate', () {
    final ChiaviDH t = ChiaviDH.nuove(Random(4));
    for (final BigInt y in <BigInt>[
      BigInt.zero,
      BigInt.one,
      primoDH - BigInt.one,
      primoDH,
    ]) {
      expect(pubblicaValida(y), isFalse);
      expect(() => t.segreto(y), throwsA(isA<ErroreSync>()));
    }
    expect(pubblicaValida(t.pubblica), isTrue);
  });

  test('impegno: cambia se cambia la chiave', () {
    final ChiaviDH a = ChiaviDH.nuove(Random(5));
    final ChiaviDH b = ChiaviDH.nuove(Random(6));
    expect(impegno(a.pubblica), impegno(a.pubblica));
    expect(impegno(a.pubblica), isNot(impegno(b.pubblica)));
    expect(impegno(a.pubblica).length, 64);
  });

  test('esadecimale andata e ritorno; rotto -> errore', () {
    final Uint8List b = Uint8List.fromList(<int>[0, 1, 127, 255]);
    expect(daEsa(esa(b)), b);
    expect(() => daEsa('abc'), throwsA(isA<ErroreSync>()));
    expect(() => daEsa('zz'), throwsA(isA<ErroreSync>()));
  });

  group('canale', () {
    final Uint8List k = Uint8List.fromList(
      List<int>.generate(32, (int i) => i),
    );
    final List<int> n1 = List<int>.filled(16, 1);
    final List<int> n2 = List<int>.filled(16, 2);
    Canale tel() => Canale.sessione(k, n1, n2, telefono: true);
    Canale pc() => Canale.sessione(k, n1, n2, telefono: false);

    test('andata e ritorno nei due sensi, anche 100 KB e vuoto', () {
      final Canale t = tel();
      final Canale p = pc();
      final Uint8List grande = Uint8List.fromList(
        List<int>.generate(100000, (int i) => i % 251),
      );
      expect(p.decifra(t.cifra(grande)), grande);
      expect(t.decifra(p.cifra(Uint8List(0))), Uint8List(0));
      final Uint8List c = t.cifra(Uint8List.fromList(<int>[1, 2, 3]));
      expect(c.sublist(8, 11), isNot(<int>[1, 2, 3]));
      expect(p.decifra(c), <int>[1, 2, 3]);
    });

    test('un byte cambiato -> firma sbagliata', () {
      final Uint8List c = tel().cifra(Uint8List.fromList(<int>[9, 9, 9]));
      c[9] ^= 1;
      expect(() => pc().decifra(c), throwsA(isA<ErroreSync>()));
    });

    test('ripetuto o fuori ordine -> rifiutato', () {
      final Canale t = tel();
      final Canale p = pc();
      final Uint8List a = t.cifra(Uint8List.fromList(<int>[1]));
      final Uint8List b = t.cifra(Uint8List.fromList(<int>[2]));
      expect(() => p.decifra(b), throwsA(isA<ErroreSync>()));
      expect(p.decifra(a), <int>[1]);
      expect(() => p.decifra(a), throwsA(isA<ErroreSync>()));
      expect(p.decifra(b), <int>[2]);
    });

    test(
      'il telefono non accetta i suoi messaggi; altri numeri = altre chiavi',
      () {
        final Canale t = tel();
        expect(
          () => tel().decifra(t.cifra(Uint8List.fromList(<int>[1]))),
          throwsA(isA<ErroreSync>()),
        );
        final Canale altro = Canale.sessione(
          k,
          n1,
          List<int>.filled(16, 3),
          telefono: false,
        );
        expect(
          () => altro.decifra(tel().cifra(Uint8List.fromList(<int>[1]))),
          throwsA(isA<ErroreSync>()),
        );
      },
    );
  });
}
