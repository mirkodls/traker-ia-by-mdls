// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
//
// Strato domain: import dei vecchi letture.csv / eventi.csv (separatore ';').
// Riceve il testo: la lettura del file sta in lib/data.
import 'modelli.dart';
import 'tempo.dart';

/// Testo CSV -> righe di campi. Gestisce virgolette e "" dentro i campi.
List<List<String>> leggiCsv(String testo, {String sep = ';'}) {
  final String t = testo.startsWith('﻿') ? testo.substring(1) : testo;
  final List<List<String>> righe = <List<String>>[];
  List<String> riga = <String>[];
  final StringBuffer campo = StringBuffer();
  bool virgolette = false;
  bool qualcosa = false;
  void chiudiCampo() {
    riga.add(campo.toString());
    campo.clear();
  }

  void chiudiRiga() {
    chiudiCampo();
    if (qualcosa || riga.length > 1 || riga.first.isNotEmpty) {
      righe.add(riga);
    }
    riga = <String>[];
    qualcosa = false;
  }

  for (int i = 0; i < t.length; i++) {
    final String c = t[i];
    if (virgolette) {
      if (c == '"') {
        if (i + 1 < t.length && t[i + 1] == '"') {
          campo.write('"');
          i++;
        } else {
          virgolette = false;
        }
      } else {
        campo.write(c);
      }
    } else if (c == '"') {
      virgolette = true;
      qualcosa = true;
    } else if (c == sep) {
      chiudiCampo();
    } else if (c == '\n') {
      chiudiRiga();
    } else if (c != '\r') {
      campo.write(c);
    }
  }
  if (campo.isNotEmpty || riga.isNotEmpty || qualcosa) {
    chiudiRiga();
  }
  return righe;
}

/// Risultato di un import: voci lette e righe scartate.
class RisultatoImport<T> {
  /// Crea il risultato.
  const RisultatoImport(this.voci, this.scartate);

  /// Voci lette, ordinate per ora.
  final List<T> voci;

  /// Righe scartate (rotte).
  final int scartate;
}

Map<String, int> _colonne(List<String> intestazione) => <String, int>{
  for (int i = 0; i < intestazione.length; i++) intestazione[i].trim(): i,
};

String _cella(List<String> r, Map<String, int> col, String nome) {
  final int? i = col[nome];
  return i == null || i >= r.length ? '' : r[i].trim();
}

/// Numero facoltativo: '' o testo rotto -> null (mai scarta la riga).
double? _numeroOpz(String s) {
  try {
    return _numero(s);
  } on FormatException {
    return null;
  }
}

/// Numero: '' -> null; testo non numerico -> eccezione FormatException.
double? _numero(String s) =>
    s.isEmpty ? null : double.parse(s.replaceAll(',', '.'));

/// letture.csv (app Python) -> letture del [gestore].
RisultatoImport<Lettura> importaLetture(
  String testo, {
  String gestore = gestoreAnthropic,
}) {
  final List<List<String>> righe = leggiCsv(testo);
  if (righe.isEmpty) {
    return const RisultatoImport<Lettura>(<Lettura>[], 0);
  }
  final Map<String, int> col = _colonne(righe.first);
  final List<Lettura> out = <Lettura>[];
  int scartate = 0;
  for (final List<String> r in righe.skip(1)) {
    final DateTime? ora = interpreta(_cella(r, col, 'ora'));
    if (ora == null) {
      scartate++;
      continue;
    }
    try {
      final String pc = _cella(r, col, 'al_pc');
      final String fonte = _cella(r, col, 'fonte');
      out.add(
        Lettura(
          ora: ora,
          sett: _numero(_cella(r, col, 'settimanale')),
          sess: _numero(_cella(r, col, 'sessione')),
          // B21: colonna 'fable' facoltativa (CSV vecchi senza = null).
          fable: _numeroOpz(_cella(r, col, 'fable')),
          fonte: fonte.isEmpty ? 'auto' : fonte,
          alPc: pc.isEmpty ? null : pc == '1',
          lavoro: _cella(r, col, 'lavoro') == '1',
          modelli: _cella(r, col, 'modelli'),
          skill: _cella(r, col, 'skill'),
          gestore: gestore,
        ),
      );
    } on FormatException {
      scartate++;
    }
  }
  return RisultatoImport<Lettura>(ordinaLetture(out), scartate);
}

/// eventi.csv (app Python) -> eventi. Tipo sconosciuto = riga scartata.
RisultatoImport<Evento> importaEventi(String testo) {
  final List<List<String>> righe = leggiCsv(testo);
  if (righe.isEmpty) {
    return const RisultatoImport<Evento>(<Evento>[], 0);
  }
  final Map<String, int> col = _colonne(righe.first);
  final List<Evento> out = <Evento>[];
  int scartate = 0;
  for (final List<String> r in righe.skip(1)) {
    final DateTime? ora = interpreta(_cella(r, col, 'ora'));
    final TipoEvento? tipo = TipoEvento.daTesto(_cella(r, col, 'tipo'));
    if (ora == null || tipo == null) {
      scartate++;
      continue;
    }
    out.add(Evento(ora: ora, tipo: tipo, testo: _cella(r, col, 'testo')));
  }
  return RisultatoImport<Evento>(ordinaEventi(out), scartate);
}
