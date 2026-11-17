// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
//
// Strato data (V2, B17): chiamata HTTPS al fornitore IA (dart:io, zero
// pacchetti) con la chiave API presa SOLO dalla Cassaforte. Mai stampare
// chiave, intestazioni o corpo della risposta d'errore. File resoconto .md.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:traker_ia/data/cassaforte.dart';
import 'package:traker_ia/data/rete.dart';
import 'package:traker_ia/domain/resoconto_ia.dart';

/// Tempo massimo della chiamata (resoconto lungo = l'IA scrive a lungo).
const Duration attesaIA = Duration(seconds: 60);

/// Cliente del resoconto IA.
class ClienteIA {
  /// Crea il cliente. [base] = indirizzo al posto di quello vero (solo
  /// prove con server finto).
  ClienteIA({required this._cassaforte, this.attesa = attesaIA, this.base});

  final Cassaforte _cassaforte;

  /// Tempo massimo della chiamata.
  final Duration attesa;

  /// Indirizzo base al posto di quello vero (solo prove).
  final Uri? base;

  /// Ultimi 4 caratteri della chiave salvata per [f] (null = nessuna).
  Future<String?> fineChiaveSalvata(FornitoreIA f) async {
    final String? k = await _cassaforte.leggi(f.chiaveCassaforte);
    if (k == null || k.trim().isEmpty) {
      return null;
    }
    return fineChiave(k);
  }

  /// Salva la chiave di [f] in cassaforte ('' = cancella). Chiave non
  /// valida -> ErroreIA col motivo (mai la chiave).
  Future<void> salvaChiave(FornitoreIA f, String chiave) async {
    final String k = chiave.trim();
    if (k.isEmpty) {
      await _cassaforte.cancella(f.chiaveCassaforte);
      return;
    }
    final String? probl = problemaChiave(k);
    if (probl != null) {
      throw ErroreIA(probl);
    }
    await _cassaforte.scrivi(f.chiaveCassaforte, k);
  }

  /// Manda [testo] al fornitore di [c]; ritorna la risposta (già senza la
  /// chiave). Errore -> ErroreIA in italiano.
  Future<String> chiedi(
    ConfigIA c,
    String testo, {
    int maxToken = maxTokenResoconto,
  }) async {
    final String chiave =
        (await _cassaforte.leggi(c.fornitore.chiaveCassaforte)) ?? '';
    final RichiestaIA r = costruisciRichiesta(
      c,
      testo,
      chiave,
      maxToken: maxToken,
      base: base,
    );
    final Object? json = await _posta(r);
    return senzaChiave(leggiRisposta(c.fornitore, json), chiave);
  }

  /// Chiamata minima per vedere se chiave e modello vanno.
  Future<String> prova(ConfigIA c) =>
      chiedi(c, testoProva, maxToken: maxTokenProva);

  Future<Object?> _posta(RichiestaIA r) async {
    final HttpClient h = HttpClient()
      ..connectionTimeout = attesa
      ..userAgent = agenteApp;
    try {
      final HttpClientRequest req = await h.postUrl(r.url).timeout(attesa);
      r.intestazioni.forEach(req.headers.set);
      req.add(utf8.encode(r.corpo));
      final HttpClientResponse risp = await req.close().timeout(attesa);
      final List<int> byte = <int>[];
      await for (final List<int> pezzo in risp.timeout(attesa)) {
        byte.addAll(pezzo);
        if (byte.length > maxByteRisposta) {
          throw const ErroreIA('risposta troppo grande');
        }
      }
      if (risp.statusCode < 200 || risp.statusCode > 299) {
        throw ErroreIA(messaggioErroreIA(risp.statusCode));
      }
      return jsonDecode(utf8.decode(byte));
    } on TimeoutException {
      throw ErroreIA('rete: tempo scaduto (${attesa.inSeconds} s)');
    } on SocketException {
      throw const ErroreIA('rete assente o fornitore non raggiungibile');
    } on HandshakeException {
      throw const ErroreIA('rete: connessione sicura fallita');
    } on HttpException {
      throw const ErroreIA('rete: risposta interrotta');
    } on FormatException {
      throw const ErroreIA('risposta non valida dal fornitore');
    } finally {
      h.close(force: true);
    }
  }
}

/// File resoconto (.md) nella [cartella]; [inizio] = solo quella settimana.
/// Più nuovi prima. Cartella mancante = elenco vuoto.
Future<List<FileResoconto>> elencaResoconti(
  String cartella, {
  DateTime? inizio,
}) async {
  final Directory d = Directory(cartella);
  if (cartella.trim().isEmpty || !d.existsSync()) {
    return <FileResoconto>[];
  }
  final List<FileResoconto> out = <FileResoconto>[];
  await for (final FileSystemEntity e in d.list()) {
    if (e is! File) {
      continue;
    }
    final String nome = e.uri.pathSegments.last;
    if (eResoconto(nome, inizio: inizio)) {
      out.add((percorso: e.path, nome: nome));
    }
  }
  out.sort((FileResoconto a, FileResoconto b) => b.nome.compareTo(a.nome));
  return out;
}
