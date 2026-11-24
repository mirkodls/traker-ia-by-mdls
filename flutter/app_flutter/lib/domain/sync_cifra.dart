// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
//
// Strato domain: cifratura del sync Wi-Fi (B22). Puro Dart + pacchetto crypto
// (SHA-256/HMAC, BSD-3).
// - Abbinamento: Diffie-Hellman gruppo 14 (RFC 3526, 2048 bit) con impegno
//   (il PC manda prima l'hash della sua chiave) + codice di 6 cifre da
//   confrontare: chi sta in mezzo non può indovinarlo (1 su un milione).
// - Sessione: chiave di coppia (32 byte, solo cassaforte) + 2 numeri a caso
//   -> 4 chiavi; ogni messaggio = flusso HMAC-SHA256 (contatore) XOR testo,
//   poi HMAC su numero+testo cifrato (cifra-poi-firma). Numero di messaggio
//   obbligato: niente ripetizioni o scambi di ordine.
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// Errore del sync (messaggio per IA/log: mai segreti dentro).
class ErroreSync implements Exception {
  /// Crea l'errore.
  const ErroreSync(this.motivo);

  /// Motivo breve.
  final String motivo;

  @override
  String toString() => 'ErroreSync: $motivo';
}

/// Primo del gruppo 14 (RFC 3526, 2048 bit, primo sicuro). Generatore 2.
final BigInt primoDH = BigInt.parse(
  <String>[
    'FFFFFFFFFFFFFFFFC90FDAA22168C234C4C6628B80DC1CD129024E088A67CC74',
    '020BBEA63B139B22514A08798E3404DDEF9519B3CD3A431B302B0A6DF25F1437',
    '4FE1356D6D51C245E485B576625E7EC6F44C42E9A637ED6B0BFF5CB6F406B7ED',
    'EE386BFB5A899FA5AE9F24117C4B1FE649286651ECE45B3DC2007CB8A163BF05',
    '98DA48361C55D39A69163FA8FD24CF5F83655D23DCA3AD961C62F356208552BB',
    '9ED529077096966D670C354E4ABC9804F1746C08CA18217C32905E462E36CE3B',
    'E39E772C180E86039B2783A2EC07A28FB5C55DF06F4C52C9DE2BCBF695581718',
    '3995497CEA956AE515D2261898FA051015728E5A8AACAA68FFFFFFFFFFFFFFFF',
  ].join(),
  radix: 16,
);

final BigInt _due = BigInt.two;

/// Lunghezza in byte dei numeri del gruppo.
const int byteDH = 256;

/// Byte casuali sicuri.
Uint8List byteCasuali(int n, [Random? r]) {
  final Random g = r ?? Random.secure();
  return Uint8List.fromList(<int>[for (int i = 0; i < n; i++) g.nextInt(256)]);
}

/// Testo esadecimale dei [b].
String esa(List<int> b) {
  final StringBuffer s = StringBuffer();
  for (final int x in b) {
    s.write(x.toRadixString(16).padLeft(2, '0'));
  }
  return s.toString();
}

/// Byte dal testo esadecimale [s] (rotto -> ErroreSync).
Uint8List daEsa(String s) {
  if (s.length.isOdd || !RegExp(r'^[0-9a-fA-F]*$').hasMatch(s)) {
    throw const ErroreSync('esadecimale rotto');
  }
  return Uint8List.fromList(<int>[
    for (int i = 0; i < s.length; i += 2)
      int.parse(s.substring(i, i + 2), radix: 16),
  ]);
}

/// [n] in [lung] byte (big-endian).
Uint8List numeroInByte(BigInt n, [int lung = byteDH]) {
  final Uint8List b = Uint8List(lung);
  BigInt x = n;
  final BigInt ff = BigInt.from(0xff);
  for (int i = lung - 1; i >= 0; i--) {
    b[i] = (x & ff).toInt();
    x = x >> 8;
  }
  if (x != BigInt.zero) {
    throw const ErroreSync('numero troppo grande');
  }
  return b;
}

/// Numero dai byte [b] (big-endian).
BigInt byteInNumero(List<int> b) {
  BigInt x = BigInt.zero;
  for (final int v in b) {
    x = (x << 8) | BigInt.from(v);
  }
  return x;
}

/// Coppia di chiavi Diffie-Hellman (la privata non esce mai dal processo).
class ChiaviDH {
  ChiaviDH._(this._privata, this.pubblica);

  /// Chiavi nuove (esponente casuale di 256 bit).
  factory ChiaviDH.nuove([Random? r]) {
    final BigInt a = byteInNumero(byteCasuali(32, r)) | BigInt.one;
    return ChiaviDH._(a, _due.modPow(a, primoDH));
  }

  final BigInt _privata;

  /// Chiave pubblica (g^a mod p).
  final BigInt pubblica;

  /// Segreto comune con la pubblica [altra] dell'altro (256 byte).
  /// Pubblica fuori gruppo -> ErroreSync.
  Uint8List segreto(BigInt altra) {
    if (!pubblicaValida(altra)) {
      throw const ErroreSync('chiave pubblica non valida');
    }
    return numeroInByte(altra.modPow(_privata, primoDH));
  }
}

/// Vero se [y] è una chiave pubblica accettabile (2 <= y <= p-2).
bool pubblicaValida(BigInt y) => y >= _due && y <= primoDH - _due;

/// Impegno: hash della pubblica [y], mandato PRIMA di vederla.
String impegno(BigInt y) => esa(sha256.convert(numeroInByte(y)).bytes);

/// Chiave di coppia (32 byte) dal [segreto] e dalle 2 pubbliche.
Uint8List chiaveCoppia(Uint8List segreto, BigInt pubTel, BigInt pubPc) =>
    Uint8List.fromList(
      sha256.convert(<int>[
        ...utf8.encode('traker-ia abbina v1'),
        ...segreto,
        ...numeroInByte(pubTel),
        ...numeroInByte(pubPc),
      ]).bytes,
    );

/// HMAC-SHA256 di [dati] con [chiave].
Uint8List firma(List<int> chiave, List<int> dati) =>
    Uint8List.fromList(Hmac(sha256, chiave).convert(dati).bytes);

/// Firma di un'[etichetta] + [extra] (conferme, saluti).
Uint8List firmaEtichetta(
  List<int> chiave,
  String etichetta, [
  List<int> extra = const <int>[],
]) => firma(chiave, <int>[...utf8.encode(etichetta), 0, ...extra]);

/// Codice di 6 cifre da confrontare tra PC e telefono.
String codiceAbbinamento(Uint8List chiave) {
  final Uint8List h = firmaEtichetta(chiave, 'codice');
  final int n = ((h[0] << 24) | (h[1] << 16) | (h[2] << 8) | h[3]) & 0x7fffffff;
  return (n % 1000000).toString().padLeft(6, '0');
}

/// Confronto a tempo costante.
bool stessiByte(List<int> x, List<int> y) {
  if (x.length != y.length) {
    return false;
  }
  int d = 0;
  for (int i = 0; i < x.length; i++) {
    d |= x[i] ^ y[i];
  }
  return d == 0;
}

Uint8List _int(int v, int lung) {
  final Uint8List b = Uint8List(lung);
  int x = v;
  for (int i = lung - 1; i >= 0; i--) {
    b[i] = x & 0xff;
    x = x >> 8;
  }
  return b;
}

const int _byteNumero = 8;
const int _byteFirma = 32;

/// Canale cifrato di una sessione (un oggetto per lato).
class Canale {
  Canale._(this._encTx, this._macTx, this._encRx, this._macRx);

  /// Chiavi della sessione dalla [chiave] di coppia e dai numeri [n1]
  /// (telefono) e [n2] (PC). [telefono] = questo lato è il telefono.
  factory Canale.sessione(
    Uint8List chiave,
    List<int> n1,
    List<int> n2, {
    required bool telefono,
  }) {
    Uint8List k(String e) => firmaEtichetta(chiave, e, <int>[...n1, ...n2]);
    final Uint8List encT = k('enc tel->pc');
    final Uint8List macT = k('mac tel->pc');
    final Uint8List encP = k('enc pc->tel');
    final Uint8List macP = k('mac pc->tel');
    return telefono
        ? Canale._(encT, macT, encP, macP)
        : Canale._(encP, macP, encT, macT);
  }

  final Uint8List _encTx;
  final Uint8List _macTx;
  final Uint8List _encRx;
  final Uint8List _macRx;
  int _inviati = 0;
  int _ricevuti = 0;

  static Uint8List _flusso(Uint8List enc, Uint8List numero, Uint8List dati) {
    final Hmac h = Hmac(sha256, enc);
    final Uint8List out = Uint8List(dati.length);
    int blocco = 0;
    for (int i = 0; i < dati.length; i += 32) {
      final List<int> ks = h.convert(<int>[
        ...numero,
        ..._int(blocco, 4),
      ]).bytes;
      blocco++;
      final int fine = min(i + 32, dati.length);
      for (int j = i; j < fine; j++) {
        out[j] = dati[j] ^ ks[j - i];
      }
    }
    return out;
  }

  /// Cifra [chiaro]: numero(8) + cifrato + firma(32).
  Uint8List cifra(Uint8List chiaro) {
    final Uint8List numero = _int(_inviati++, _byteNumero);
    final Uint8List c = _flusso(_encTx, numero, chiaro);
    final Uint8List f = firma(_macTx, <int>[...numero, ...c]);
    return Uint8List.fromList(<int>[...numero, ...c, ...f]);
  }

  /// Decifra un [pacchetto]: firma sbagliata o numero fuori ordine ->
  /// ErroreSync (niente dati usati).
  Uint8List decifra(Uint8List pacchetto) {
    if (pacchetto.length < _byteNumero + _byteFirma) {
      throw const ErroreSync('pacchetto corto');
    }
    final Uint8List numero = Uint8List.sublistView(pacchetto, 0, _byteNumero);
    final int fineC = pacchetto.length - _byteFirma;
    final Uint8List c = Uint8List.sublistView(pacchetto, _byteNumero, fineC);
    final Uint8List f = Uint8List.sublistView(pacchetto, fineC);
    if (!stessiByte(firma(_macRx, <int>[...numero, ...c]), f)) {
      throw const ErroreSync('firma sbagliata');
    }
    if (!stessiByte(numero, _int(_ricevuti, _byteNumero))) {
      throw const ErroreSync('messaggio fuori ordine');
    }
    _ricevuti++;
    return _flusso(_encRx, numero, c);
  }
}
