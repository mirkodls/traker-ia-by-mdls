// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
//
// Strato data: sync Wi-Fi PC <-> telefono (B22). Zero pacchetti di rete:
// dart:io (TCP + UDP broadcast). Il PC ascolta (porta 45791, ricerca UDP
// 45790) solo se ha telefoni abbinati o l'abbinamento è aperto; il telefono
// chiama. Cifratura: domain/sync_cifra.dart. Unione: domain/sync_dati.dart.
// Messaggi: 4 byte lunghezza + contenuto. Prima del saluto JSON in chiaro
// (solo id, nomi, numeri pubblici); dopo, tutto cifrato e firmato.
// Segreti (chiavi di coppia) SOLO in cassaforte; mai nei log o nei messaggi.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:traker_ia/data/archivio.dart';
import 'package:traker_ia/data/archivio_progetti.dart';
import 'package:traker_ia/data/cassaforte.dart';
import 'package:traker_ia/domain/modelli.dart';
import 'package:traker_ia/domain/sync_cifra.dart';
import 'package:traker_ia/domain/sync_dati.dart';
import 'package:traker_ia/domain/tempo.dart';
import 'package:traker_ia/domain/traduzioni/testi_it.dart';

/// Messaggio più grande accettato (64 MB).
const int _maxMessaggio = 64 * 1024 * 1024;

/// Dispositivo abbinato (la chiave è segreta: solo cassaforte).
class Coppia {
  /// Crea la coppia.
  const Coppia(this.id, this.nome, this.chiave);

  /// Id dell'altro dispositivo.
  final String id;

  /// Nome dell'altro dispositivo.
  final String nome;

  /// Chiave di coppia (32 byte).
  final Uint8List chiave;
}

/// Coppie salvate nella [c] (rotte = nessuna).
Future<List<Coppia>> leggiCoppie(Cassaforte c) async {
  try {
    final Object? j = jsonDecode(await c.leggi(chiaveCoppieSync) ?? '[]');
    return <Coppia>[
      if (j is List)
        for (final Object? o in j)
          if (o is Map && o['id'] is String && o['k'] is String)
            Coppia(
              o['id'] as String,
              o['nome'] is String ? o['nome'] as String : '',
              daEsa(o['k'] as String),
            ),
    ];
  } on Object {
    return const <Coppia>[];
  }
}

/// Salva [nuova] nella [c]; [sola] = toglie le altre (telefono: un PC).
Future<void> salvaCoppia(
  Cassaforte c,
  Coppia nuova, {
  bool sola = false,
}) async {
  final List<Coppia> tutte = <Coppia>[
    if (!sola)
      for (final Coppia x in await leggiCoppie(c))
        if (x.id != nuova.id) x,
    nuova,
  ];
  await c.scrivi(
    chiaveCoppieSync,
    jsonEncode(<Object?>[
      for (final Coppia x in tutte)
        <String, String>{'id': x.id, 'nome': x.nome, 'k': esa(x.chiave)},
    ]),
  );
}

/// Id di questo dispositivo (creato la prima volta).
Future<String> idDispositivo(Archivio a) async {
  final String? v = await a.impostazione(ChiaviSync.id);
  if (v != null && v.length == 16) {
    return v;
  }
  final String nuovo = esa(byteCasuali(8));
  await a.salvaImpostazione(ChiaviSync.id, nuovo);
  return nuovo;
}

/// Prepara e applica i pacchi sul database.
class DatiSync {
  /// Crea il ponte.
  const DatiSync(this.archivio, this.progetti);

  /// Letture/eventi/impostazioni.
  final Archivio archivio;

  /// Progetti/settimane.
  final ArchivioProgetti progetti;

  /// Il mio pacco dal momento [da] (null = tutto).
  Future<PaccoSync> prepara(DateTime? da) async {
    final Map<String, int> ore = await archivio.oreImpostazioni(chiaviSync);
    final Map<String, ValoreSync> imp = <String, ValoreSync>{};
    for (final String k in chiaviSync) {
      final String? v = await archivio.impostazione(k);
      if (v != null) {
        imp[k] = (valore: v, ora: ore[k] ?? 0);
      }
    }
    return PaccoSync(
      da: da,
      letture: PaccoSync.dal(
        await archivio.letture(),
        (Lettura l) => l.ora,
        da,
      ),
      eventi: PaccoSync.dal(await archivio.eventi(), (Evento e) => e.ora, da),
      progetti: await progetti.progetti(),
      settimane: await progetti.settimaneSync(da),
      impostazioni: imp,
    );
  }

  /// Aggiunge il pacco [p] arrivato. Ritorna le righe nuove.
  Future<int> applica(PaccoSync p) async {
    int n = await archivio.aggiungiLettureSoloNuove(p.letture);
    n += await archivio.aggiungiEventiSoloNuovi(p.eventi);
    n += await progetti.aggiungiSync(p.progetti, p.settimane);
    final Map<String, String?> mie = <String, String?>{
      for (final String k in p.impostazioni.keys)
        k: await archivio.impostazione(k),
    };
    final Map<String, ValoreSync> da = impostazioniDaApplicare(
      mie,
      await archivio.oreImpostazioni(p.impostazioni.keys),
      p.impostazioni,
    );
    for (final MapEntry<String, ValoreSync> e in da.entries) {
      await archivio.salvaImpostazioneSync(e.key, e.value.valore, e.value.ora);
    }
    return n;
  }
}

/// Una connessione: messaggi con lunghezza, in chiaro o cifrati.
class _Connessione {
  _Connessione(this._s) {
    _sub = _s.listen(
      (Uint8List d) {
        _buf.add(d);
        if (_buf.length > _maxMessaggio + 4) {
          _rotta = true;
        }
        _sveglia();
      },
      onError: (Object _) {
        _rotta = true;
        _sveglia();
      },
      onDone: () {
        _fine = true;
        _sveglia();
      },
      cancelOnError: true,
    );
  }

  final Socket _s;
  late final StreamSubscription<Uint8List> _sub;
  final BytesBuilder _buf = BytesBuilder(copy: false);
  Completer<void>? _attesa;
  bool _fine = false;
  bool _rotta = false;
  int _serve = 4;
  int? _lung;
  Canale? canale;

  void _sveglia() {
    final Completer<void>? c = _attesa;
    _attesa = null;
    if (c != null && !c.isCompleted) {
      c.complete();
    }
  }

  Future<Uint8List> _grezzo(Duration t) async {
    final DateTime limite = DateTime.now().add(t);
    while (true) {
      if (_rotta) {
        throw const ErroreSync('connessione rotta');
      }
      if (_buf.length >= _serve) {
        final Uint8List b = _buf.takeBytes();
        if (_lung == null) {
          final int l = ByteData.sublistView(b, 0, 4).getUint32(0);
          if (l > _maxMessaggio) {
            throw const ErroreSync('messaggio troppo grande');
          }
          _lung = l;
          _serve = 4 + l;
        }
        if (b.length >= _serve) {
          final Uint8List m = Uint8List.fromList(b.sublist(4, _serve));
          if (b.length > _serve) {
            _buf.add(b.sublist(_serve));
          }
          _lung = null;
          _serve = 4;
          return m;
        }
        _buf.add(b);
      }
      if (_fine) {
        throw const ErroreSync('connessione chiusa');
      }
      final Duration resto = limite.difference(DateTime.now());
      if (resto <= Duration.zero) {
        throw const ErroreSync('tempo scaduto');
      }
      _attesa = Completer<void>();
      await _attesa!.future.timeout(resto, onTimeout: () {});
    }
  }

  void _manda(Uint8List m) {
    final Uint8List h = Uint8List(4);
    ByteData.sublistView(h).setUint32(0, m.length);
    _s
      ..add(h)
      ..add(m);
  }

  /// Manda [j]: in chiaro prima del saluto, poi cifrato (+gzip).
  Future<void> manda(Map<String, Object?> j) async {
    final List<int> testo = utf8.encode(jsonEncode(j));
    final Canale? c = canale;
    _manda(
      c == null
          ? Uint8List.fromList(testo)
          : c.cifra(Uint8List.fromList(gzip.encode(testo))),
    );
    await _s.flush();
  }

  /// Prossimo messaggio JSON (tipo [tipo] obbligato; 'no' -> ErroreSync).
  Future<Map<String, Object?>> leggi(
    String tipo, {
    Duration t = const Duration(seconds: 20),
  }) async {
    final Uint8List m = await _grezzo(t);
    final Canale? c = canale;
    final List<int> testo = c == null ? m : gzip.decode(c.decifra(m));
    final Object? j = jsonDecode(utf8.decode(testo));
    if (j is! Map<String, Object?>) {
      throw const ErroreSync('messaggio non valido');
    }
    if (j['t'] == 'no') {
      throw ErroreSync('no:${j['motivo']}');
    }
    if (j['t'] != tipo) {
      throw ErroreSync('atteso $tipo');
    }
    return j;
  }

  Future<void> chiudi() async {
    await _sub.cancel();
    try {
      await _s.close();
    } on Object {
      // già chiusa
    }
    _s.destroy();
  }
}

String _testo(Map<String, Object?> j, String k) {
  final Object? v = j[k];
  if (v is! String) {
    throw ErroreSync('manca $k');
  }
  return v;
}

/// PC: ascolta i telefoni.
class ServerSync {
  /// Crea il server.
  ServerSync({
    required this.dati,
    required this.cassaforte,
    required this.nome,
    this.porta = portaSync,
    this.portaUdp = portaRicerca,
  });

  /// Database.
  final DatiSync dati;

  /// Cassaforte (coppie).
  final Cassaforte cassaforte;

  /// Nome del PC mostrato sul telefono.
  final String nome;

  /// Porte (nei test: 0 = libera qualsiasi).
  final int porta;

  /// Porta della ricerca UDP.
  final int portaUdp;

  ServerSocket? _tcp;
  RawDatagramSocket? _udp;
  bool _occupato = false;
  DateTime? _abbinaFino;
  void Function(String codice)? _mostraCodice;
  void Function(String nome)? _abbinato;
  final StreamController<int> _sincronizzati =
      StreamController<int>.broadcast();

  /// Porta TCP vera (dopo [avvia]).
  int get portaVera => _tcp?.port ?? porta;

  /// Porta UDP vera (dopo [avvia]).
  int get portaUdpVera => _udp?.port ?? portaUdp;

  /// Un telefono ha fatto il sync: righe nuove arrivate qui.
  Stream<int> get sincronizzati => _sincronizzati.stream;

  /// Ascolta (se non già). Falso se la porta è occupata.
  Future<bool> avvia() async {
    if (_tcp != null) {
      return true;
    }
    try {
      final ServerSocket s = await ServerSocket.bind(
        InternetAddress.anyIPv4,
        porta,
      );
      _tcp = s;
      s.listen((Socket c) => unawaited(_cliente(c)));
    } on SocketException {
      return false;
    }
    try {
      final RawDatagramSocket u = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        portaUdp,
      );
      _udp = u;
      final String id = await idDispositivo(dati.archivio);
      u.listen((RawSocketEvent e) {
        if (e != RawSocketEvent.read) {
          return;
        }
        final Datagram? d = u.receive();
        if (d == null || d.data.length > 64) {
          return;
        }
        if (String.fromCharCodes(d.data) == domandaRicerca) {
          u.send(
            utf8.encode('$rispostaRicerca $portaVera $id'),
            d.address,
            d.port,
          );
        }
      });
    } on SocketException {
      // Ricerca spenta: il telefono può ancora usare l'ultimo indirizzo.
    }
    return true;
  }

  /// Smette di ascoltare.
  Future<void> ferma() async {
    await _tcp?.close();
    _tcp = null;
    _udp?.close();
    _udp = null;
  }

  /// Apre l'abbinamento per 3 minuti: [mostraCodice] quando c'è il codice,
  /// [abbinato] a coppia salvata.
  Future<bool> apriAbbinamento({
    required void Function(String codice) mostraCodice,
    required void Function(String nome) abbinato,
  }) async {
    _abbinaFino = DateTime.now().add(
      const Duration(minutes: minutiAbbinamento),
    );
    _mostraCodice = mostraCodice;
    _abbinato = abbinato;
    return avvia();
  }

  /// Chiude l'abbinamento.
  void chiudiAbbinamento() {
    _abbinaFino = null;
    _mostraCodice = null;
    _abbinato = null;
  }

  bool get _abbinaAperto =>
      _abbinaFino != null && DateTime.now().isBefore(_abbinaFino!);

  Future<void> _cliente(Socket s) async {
    if (_occupato) {
      s.destroy();
      return;
    }
    _occupato = true;
    final _Connessione c = _Connessione(s);
    try {
      final Uint8List primo = await c._grezzo(const Duration(seconds: 10));
      final Object? j = jsonDecode(utf8.decode(primo));
      if (j is! Map<String, Object?>) {
        throw const ErroreSync('messaggio non valido');
      }
      if (j['t'] == 'abbina1') {
        await _abbina(c, j);
      } else if (j['t'] == 'ciao') {
        await _sync(c, j);
      }
    } on Object {
      // Errore o telefono sparito: niente dati scritti a metà (ogni
      // aggiunta è in batch/transazione); si riprova al prossimo giro.
    } finally {
      _occupato = false;
      await c.chiudi();
    }
  }

  Future<void> _abbina(_Connessione c, Map<String, Object?> j) async {
    if (!_abbinaAperto) {
      await c.manda(<String, Object?>{'t': 'no', 'motivo': 'chiuso'});
      return;
    }
    final String idTel = _testo(j, 'id');
    final String nomeTel = _testo(j, 'nome');
    final ChiaviDH dh = ChiaviDH.nuove();
    await c.manda(<String, Object?>{
      't': 'impegno',
      'id': await idDispositivo(dati.archivio),
      'nome': nome,
      'h': impegno(dh.pubblica),
    });
    final Map<String, Object?> a = await c.leggi('abbina2');
    final BigInt pubTel = BigInt.parse(_testo(a, 'a'), radix: 16);
    final Uint8List k = chiaveCoppia(dh.segreto(pubTel), pubTel, dh.pubblica);
    await c.manda(<String, Object?>{
      't': 'svela',
      'b': dh.pubblica.toRadixString(16),
    });
    _mostraCodice?.call(codiceAbbinamento(k));
    final Map<String, Object?> conf = await c.leggi(
      'abbina3',
      t: const Duration(minutes: minutiAbbinamento),
    );
    if (!stessiByte(
      daEsa(_testo(conf, 'm')),
      firmaEtichetta(k, 'conferma-tel'),
    )) {
      throw const ErroreSync('conferma sbagliata');
    }
    await salvaCoppia(cassaforte, Coppia(idTel, nomeTel, k));
    await c.manda(<String, Object?>{
      't': 'abbina_ok',
      'm': esa(firmaEtichetta(k, 'conferma-pc')),
    });
    final void Function(String)? fatto = _abbinato;
    chiudiAbbinamento();
    fatto?.call(nomeTel);
  }

  Future<void> _sync(_Connessione c, Map<String, Object?> j) async {
    final String idTel = _testo(j, 'id');
    final Uint8List n1 = daEsa(_testo(j, 'n1'));
    Coppia? cp;
    for (final Coppia x in await leggiCoppie(cassaforte)) {
      if (x.id == idTel) {
        cp = x;
      }
    }
    if (cp == null || n1.length != 16) {
      await c.manda(<String, Object?>{'t': 'no', 'motivo': 'sconosciuto'});
      return;
    }
    final Uint8List n2 = byteCasuali(16);
    await c.manda(<String, Object?>{
      't': 'ciao_pc',
      'n2': esa(n2),
      'm': esa(firmaEtichetta(cp.chiave, 'pc', <int>[...n1, ...n2])),
    });
    c.canale = Canale.sessione(cp.chiave, n1, n2, telefono: false);
    final Map<String, Object?> arr = await c.leggi(
      'dati',
      t: const Duration(seconds: 60),
    );
    final PaccoSync suo = PaccoSync.daJson(_mappa(arr['p']));
    final PaccoSync mio = await dati.prepara(suo.da);
    await c.manda(<String, Object?>{'t': 'dati', 'p': mio.aJson()});
    final int n = await dati.applica(suo);
    _sincronizzati.add(n);
  }
}

Map<String, Object?> _mappa(Object? o) =>
    o is Map<String, Object?> ? o : const <String, Object?>{};

/// Vero se l'indirizzo [a] è di una rete di casa (192.168/10/172.16-31).
bool indirizzoDiCasa(InternetAddress a) {
  if (a.type != InternetAddressType.IPv4) {
    return false;
  }
  final List<int> b = a.rawAddress;
  return b[0] == 10 ||
      (b[0] == 192 && b[1] == 168) ||
      (b[0] == 172 && b[1] >= 16 && b[1] <= 31);
}

/// Telefono: vero se è sul Wi-Fi (interfaccia wlan con indirizzo di casa).
Future<bool> suWifi() async {
  try {
    for (final NetworkInterface i in await NetworkInterface.list(
      type: InternetAddressType.IPv4,
    )) {
      if (i.name.toLowerCase().startsWith('wlan') &&
          i.addresses.any(indirizzoDiCasa)) {
        return true;
      }
    }
  } on Object {
    return false;
  }
  return false;
}

/// Telefono: chiama il PC.
class ClientSync {
  /// Crea il client.
  ClientSync({
    required this.dati,
    required this.cassaforte,
    this.nome = 'Telefono',
    this.porta = portaSync,
    this.portaUdp = portaRicerca,
    this.controllaWifi = suWifi,
    this.indirizzoRicerca,
  });

  /// Database.
  final DatiSync dati;

  /// Cassaforte (coppia col PC).
  final Cassaforte cassaforte;

  /// Nome mostrato sul PC.
  final String nome;

  /// Porta TCP del PC (se la ricerca non la dice).
  final int porta;

  /// Porta della ricerca UDP.
  final int portaUdp;

  /// Controllo Wi-Fi (nei test: sempre vero).
  final Future<bool> Function() controllaWifi;

  /// Dove mandare la domanda (null = broadcast 255.255.255.255).
  final InternetAddress? indirizzoRicerca;

  /// Cerca il PC in rete (1,5 s). [pcId] = solo quel PC.
  Future<({InternetAddress ip, int porta})?> cerca({String? pcId}) async {
    RawDatagramSocket? u;
    try {
      u = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      u.broadcastEnabled = true;
      final Completer<({InternetAddress ip, int porta})?> trovato =
          Completer<({InternetAddress ip, int porta})?>();
      u.listen((RawSocketEvent e) {
        if (e != RawSocketEvent.read) {
          return;
        }
        final Datagram? d = u?.receive();
        if (d == null || d.data.length > 128 || trovato.isCompleted) {
          return;
        }
        final List<String> p = String.fromCharCodes(d.data).split(' ');
        final int? pt = p.length == 3 ? int.tryParse(p[1]) : null;
        if (p.length == 3 &&
            p[0] == rispostaRicerca &&
            pt != null &&
            (pcId == null || p[2] == pcId)) {
          trovato.complete((ip: d.address, porta: pt));
        }
      });
      final InternetAddress dove =
          indirizzoRicerca ?? InternetAddress('255.255.255.255');
      for (int i = 0; i < 3 && !trovato.isCompleted; i++) {
        u.send(utf8.encode(domandaRicerca), dove, portaUdp);
        await Future.any(<Future<Object?>>[
          trovato.future,
          Future<void>.delayed(const Duration(milliseconds: 500)),
        ]);
      }
      return trovato.isCompleted ? await trovato.future : null;
    } on SocketException {
      return null;
    } finally {
      u?.close();
    }
  }

  Future<_Connessione?> _collega(String? pcId, {bool cerca = true}) async {
    final String? ip = await dati.archivio.impostazione(ChiaviSync.ipPc);
    final InternetAddress? vecchio = ip == null
        ? null
        : InternetAddress.tryParse(ip);
    if (vecchio != null && pcId != null) {
      try {
        return _Connessione(
          await Socket.connect(
            vecchio,
            porta,
            timeout: const Duration(seconds: 2),
          ),
        );
      } on Object {
        // cambiato indirizzo: si cerca
      }
    }
    if (!cerca) {
      return null;
    }
    final ({InternetAddress ip, int porta})? t = await this.cerca(pcId: pcId);
    if (t == null) {
      return null;
    }
    try {
      final _Connessione c = _Connessione(
        await Socket.connect(
          t.ip,
          t.porta,
          timeout: const Duration(seconds: 3),
        ),
      );
      await dati.archivio.salvaImpostazione(ChiaviSync.ipPc, t.ip.address);
      return c;
    } on Object {
      return null;
    }
  }

  /// Abbina al PC: [chiediCodice] chiede all'utente il codice mostrato sul
  /// PC (null = annullato).
  Future<EsitoSync> abbina(Future<String?> Function() chiediCodice) async {
    if (!await controllaWifi()) {
      return const EsitoSync(ok: false, messaggio: Testi.syncNoWifi);
    }
    final _Connessione? c = await _collega(null);
    if (c == null) {
      return const EsitoSync(ok: false, messaggio: Testi.syncPcNonTrovato);
    }
    try {
      await c.manda(<String, Object?>{
        't': 'abbina1',
        'v': versioneSync,
        'id': await idDispositivo(dati.archivio),
        'nome': nome,
      });
      final Map<String, Object?> imp = await c.leggi('impegno');
      final String idPc = _testo(imp, 'id');
      final String nomePc = _testo(imp, 'nome');
      final String h = _testo(imp, 'h');
      final ChiaviDH dh = ChiaviDH.nuove();
      await c.manda(<String, Object?>{
        't': 'abbina2',
        'a': dh.pubblica.toRadixString(16),
      });
      final Map<String, Object?> sv = await c.leggi('svela');
      final BigInt pubPc = BigInt.parse(_testo(sv, 'b'), radix: 16);
      if (impegno(pubPc) != h) {
        return const EsitoSync(ok: false, messaggio: Testi.syncErrore);
      }
      final Uint8List k = chiaveCoppia(dh.segreto(pubPc), dh.pubblica, pubPc);
      final String? scritto = await chiediCodice();
      if (scritto == null) {
        return const EsitoSync(ok: false, messaggio: Testi.syncAnnullato);
      }
      if (scritto.replaceAll(RegExp(r'\s'), '') != codiceAbbinamento(k)) {
        return const EsitoSync(ok: false, messaggio: Testi.syncCodiceSbagliato);
      }
      await c.manda(<String, Object?>{
        't': 'abbina3',
        'm': esa(firmaEtichetta(k, 'conferma-tel')),
      });
      final Map<String, Object?> ok = await c.leggi('abbina_ok');
      if (!stessiByte(
        daEsa(_testo(ok, 'm')),
        firmaEtichetta(k, 'conferma-pc'),
      )) {
        return const EsitoSync(ok: false, messaggio: Testi.syncErrore);
      }
      await salvaCoppia(cassaforte, Coppia(idPc, nomePc, k), sola: true);
      return EsitoSync(
        ok: true,
        messaggio: Testi.syncAbbinato(nomePc),
        nomeAltro: nomePc,
      );
    } on ErroreSync catch (e) {
      return EsitoSync(
        ok: false,
        messaggio: e.motivo == 'no:chiuso'
            ? Testi.syncApriAbbinaSulPc
            : Testi.syncErrore,
      );
    } on Object {
      return const EsitoSync(ok: false, messaggio: Testi.syncErrore);
    } finally {
      await c.chiudi();
    }
  }

  /// Sync col PC abbinato. [tutto] = tutte le righe (non solo ultimi giorni).
  /// [cerca] falso = solo l'ultimo indirizzo del PC (sottofondo).
  Future<EsitoSync> sincronizza({bool tutto = false, bool cerca = true}) async {
    final List<Coppia> cs = await leggiCoppie(cassaforte);
    if (cs.isEmpty) {
      return const EsitoSync(ok: false, messaggio: Testi.syncNonAbbinato);
    }
    final Coppia cp = cs.last;
    if (!await controllaWifi()) {
      return const EsitoSync(ok: false, messaggio: Testi.syncNoWifi);
    }
    final _Connessione? c = await _collega(cp.id, cerca: cerca);
    if (c == null) {
      return const EsitoSync(ok: false, messaggio: Testi.syncPcNonTrovato);
    }
    try {
      final Uint8List n1 = byteCasuali(16);
      await c.manda(<String, Object?>{
        't': 'ciao',
        'v': versioneSync,
        'id': await idDispositivo(dati.archivio),
        'n1': esa(n1),
      });
      final Map<String, Object?> r = await c.leggi('ciao_pc');
      final Uint8List n2 = daEsa(_testo(r, 'n2'));
      if (n2.length != 16 ||
          !stessiByte(
            daEsa(_testo(r, 'm')),
            firmaEtichetta(cp.chiave, 'pc', <int>[...n1, ...n2]),
          )) {
        return const EsitoSync(ok: false, messaggio: Testi.syncErrore);
      }
      c.canale = Canale.sessione(cp.chiave, n1, n2, telefono: true);
      final DateTime adesso = DateTime.now();
      final DateTime? da = daQuando(
        interpreta(await dati.archivio.impostazione(ChiaviSync.ultimo) ?? ''),
        tutto: tutto,
      );
      await c.manda(<String, Object?>{
        't': 'dati',
        'p': (await dati.prepara(da)).aJson(),
      });
      final Map<String, Object?> arr = await c.leggi(
        'dati',
        t: const Duration(seconds: 60),
      );
      final int n = await dati.applica(PaccoSync.daJson(_mappa(arr['p'])));
      await dati.archivio.salvaImpostazione(
        ChiaviSync.ultimo,
        formatta(adesso),
      );
      return EsitoSync(
        ok: true,
        messaggio: Testi.syncFatto(cp.nome, n),
        ricevute: n,
        nomeAltro: cp.nome,
      );
    } on ErroreSync catch (e) {
      return EsitoSync(
        ok: false,
        messaggio: e.motivo == 'no:sconosciuto'
            ? Testi.syncRiabbina
            : Testi.syncErrore,
      );
    } on Object {
      return const EsitoSync(ok: false, messaggio: Testi.syncErrore);
    } finally {
      await c.chiudi();
    }
  }
}
