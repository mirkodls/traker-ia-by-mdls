// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
//
// Servizi finti in memoria per i test della ui.
import 'dart:async';

import 'package:traker_ia/domain/archivio_settimane.dart';
import 'package:traker_ia/domain/catena.dart';
import 'package:traker_ia/domain/modelli.dart';
import 'package:traker_ia/domain/piani_progetti.dart';
import 'package:traker_ia/domain/progetti.dart';
import 'package:traker_ia/domain/resoconto_ia.dart';
import 'package:traker_ia/domain/sfondo.dart';
import 'package:traker_ia/domain/sync_dati.dart';
import 'package:traker_ia/ui/servizi.dart';

/// Servizi finti: tutto in memoria.
class ServiziFinti implements Servizi {
  /// Letture salvate.
  final List<Lettura> lett = <Lettura>[];

  /// Eventi salvati.
  final List<Evento> ev = <Evento>[];

  /// Impostazioni salvate.
  final Map<String, String> imp = <String, String>{};

  /// Risposte di leggi(): Uso o ErroreLettura, in ordine (l'ultima si ripete).
  final List<Object> risposte = <Object>[];

  /// Metodi chiesti a leggi().
  final List<String> metodi = <String>[];

  /// Letture da dare all'import.
  List<Lettura> daImportare = <Lettura>[];

  /// Cartelle chieste all'import.
  final List<String> importate = <String>[];

  /// Cookie salvato.
  String cookie = '';

  /// Chiamate primo piano.
  final List<bool> primoPianoChiamate = <bool>[];

  // ignore: close_sinks
  final StreamController<void> _est = StreamController<void>.broadcast();

  @override
  Future<List<Lettura>> letture() async => ordinaLetture(lett);

  @override
  Future<List<Evento>> eventi() async => ordinaEventi(ev);

  @override
  Future<void> aggiungiLettura(Lettura l) async => lett.add(l);

  @override
  Future<void> aggiungiEvento(Evento e) async => ev.add(e);

  @override
  Future<Map<String, String?>> impostazioni(List<String> chiavi) async =>
      <String, String?>{for (final String k in chiavi) k: imp[k]};

  @override
  Future<void> salvaImpostazioni(Map<String, String> valori) async =>
      imp.addAll(valori);

  @override
  Future<RisultatoCatena> leggi(String metodo) async {
    metodi.add(metodo);
    final Object r = risposte.length > 1
        ? risposte.removeAt(0)
        : risposte.first;
    if (r is ErroreLettura) {
      throw r;
    }
    return RisultatoCatena(r as Uso, 'estensione');
  }

  @override
  Stream<void> get arriviEstensione => _est.stream;

  @override
  bool get claudeCodeTrovato => false;

  @override
  Future<bool> cookieSalvato() async => cookie.isNotEmpty;

  @override
  Future<void> salvaCookie(String c) async => cookie = c.trim();

  @override
  String get cartellaImportPredefinita => 'vecchi';

  /// Export per IA: file "salvati" (nome -> testo) e cartelle usate.
  final Map<String, String> fileSalvati = <String, String>{};

  /// Se non null, il salvataggio fallisce con questo motivo.
  String? erroreSalva;

  @override
  String get cartellaEsportaPredefinita =>
      tel ? cartellaEsportaTelefono : 'esporta';

  @override
  Future<String> salvaTestoInCartella({
    required String cartella,
    required String nome,
    required String testo,
  }) async {
    if (erroreSalva != null) {
      throw Exception(erroreSalva);
    }
    final String p = '$cartella/$nome';
    fileSalvati[p] = testo;
    return p;
  }

  @override
  Future<EsitoImportUi> importaVecchi(String cartella) async {
    importate.add(cartella);
    lett.addAll(daImportare);
    return (
      file: daImportare.isEmpty ? 0 : 1,
      letture: daImportare.length,
      eventi: 0,
      scartate: 0,
    );
  }

  @override
  bool get primoPianoDisponibile => true;

  @override
  Future<void> primoPiano({required bool acceso}) async =>
      primoPianoChiamate.add(acceso);

  /// Avvio con Windows disponibile.
  bool avvioDisponibile = true;

  /// Stato avvio con Windows.
  bool avvio = false;

  /// Chiamate a impostaAvvioWindows.
  final List<bool> avvioChiamate = <bool>[];

  /// Testi mandati al tray.
  final List<String> tray = <String>[];

  @override
  bool get avvioWindowsDisponibile => avvioDisponibile;

  @override
  Future<bool> avvioWindows() async => avvio;

  @override
  Future<void> impostaAvvioWindows({required bool acceso}) async {
    avvioChiamate.add(acceso);
    avvio = acceso;
  }

  @override
  Future<void> aggiornaTray(String testo) async => tray.add(testo);

  /// Browser "installati" per apriPaginaEstensioni.
  final Set<String> browserTrovati = <String>{'edge'};

  /// Chiamate ai collegamenti (`estensione:<id>`, `claude_code`).
  final List<String> collegamenti = <String>[];

  @override
  bool get collegamentiDisponibili => !tel;

  @override
  Future<String> preparaEstensione() async {
    collegamenti.add('prepara');
    return r'C:\Doc\TraKer IA by mdls\estensioni\chromium';
  }

  @override
  Future<void> mostraCartella(String percorso) async =>
      collegamenti.add('cartella');

  @override
  Future<bool> apriPaginaEstensioni(String idBrowser) async {
    collegamenti.add('estensione:$idBrowser');
    return browserTrovati.contains(idBrowser);
  }

  @override
  Future<bool> accediClaudeCode() async {
    collegamenti.add('claude_code');
    return true;
  }

  /// Finge il telefono.
  bool tel = false;

  /// Cookie della pagina di login finta.
  String cookieDellaPagina = '';

  /// Batteria finta (null = non so).
  bool? batteria;

  /// Chiamate a sfondo: (minuti, acceso).
  final List<(int, bool)> sfondo = <(int, bool)>[];

  /// Volte che la cache è stata buttata.
  int cacheButtate = 0;

  /// Pagine permessi aperte.
  final List<String> permessi = <String>[];

  @override
  bool get telefono => tel;

  @override
  Future<String> cookieWeb(String sito) async => cookieDellaPagina;

  @override
  Future<void> preparaWeb(int id) async {}

  @override
  Future<bool?> batteriaLibera() async => batteria;

  @override
  Future<void> apriPermesso(String voce) async => permessi.add(voce);

  /// B21: testi mandati al menu Condividi.
  final List<String> condivisi = <String>[];

  @override
  Future<bool> condividiTesto(String testo, {required String titolo}) async {
    condivisi.add(testo);
    return telefono;
  }

  @override
  Future<void> dimenticaCache() async => cacheButtate++;

  @override
  Future<void> aggiornaSfondo({
    required int minuti,
    required bool acceso,
  }) async => sfondo.add((minuti, acceso));

  /// Progetti salvati.
  final List<Progetto> prog = <Progetto>[];

  /// Settimane archiviate.
  final List<SettimanaProgetto> sett = <SettimanaProgetto>[];

  /// Quante volte si è chiesto di archiviare.
  int archiviazioni = 0;

  /// Quante volte si sono lette le settimane.
  int letturaSettimane = 0;

  @override
  Future<List<Progetto>> progetti() async => List<Progetto>.of(prog);

  @override
  Future<Progetto> aggiungiProgetto(Progetto p) async {
    final String n = normalizzaNome(p.nome);
    if (n.isEmpty || prog.any((Progetto x) => normalizzaNome(x.nome) == n)) {
      throw ArgumentError.value(p.nome, 'nome');
    }
    final Progetto nuovo = Progetto(
      id: prog.length + 1,
      nome: p.nome.trim(),
      colore: p.colore,
      note: p.note,
    );
    prog.add(nuovo);
    return nuovo;
  }

  @override
  Future<void> modificaProgetto(Progetto p) async {
    final int i = prog.indexWhere((Progetto x) => x.id == p.id);
    final String n = normalizzaNome(p.nome);
    if (i < 0 ||
        n.isEmpty ||
        prog.any((Progetto x) => x.id != p.id && normalizzaNome(x.nome) == n)) {
      throw ArgumentError.value(p.nome, 'nome');
    }
    prog[i] = Progetto(
      id: p.id,
      nome: p.nome.trim(),
      colore: p.colore,
      note: p.note,
    );
  }

  @override
  Future<List<SettimanaProgetto>> settimane() async {
    letturaSettimane++;
    return List<SettimanaProgetto>.of(sett);
  }

  @override
  Future<void> salvaTokenManuali(int idRiga, int? token) async {
    final int i = sett.indexWhere((SettimanaProgetto r) => r.id == idRiga);
    if (i < 0) {
      return;
    }
    final SettimanaProgetto r = sett[i];
    sett[i] = SettimanaProgetto(
      id: r.id,
      progettoId: r.progettoId,
      inizio: r.inizio,
      fine: r.fine,
      istantanea: r.istantanea,
      log: r.log,
      tokenManuali: token,
    );
  }

  @override
  Future<int> archiviaSettimaneChiuse({
    required List<Lettura> letture,
    required List<Evento> eventi,
    required DateTime adesso,
    Piano? piano,
  }) async {
    archiviazioni++;
    final Set<DateTime> gia = <DateTime>{
      for (final SettimanaProgetto r in sett) r.inizio,
    };
    int n = 0;
    for (final ({DateTime inizio, DateTime fine}) w in settimaneDaArchiviare(
      letture,
      adesso,
      gia: gia,
    )) {
      for (final SettimanaProgetto r in archiviaSettimana(
        letture: letture,
        eventi: eventi,
        progetti: prog,
        inizio: w.inizio,
        fine: w.fine,
        piano: piano,
      )) {
        sett.add(
          SettimanaProgetto(
            id: sett.length + 1,
            progettoId: r.progettoId,
            inizio: r.inizio,
            fine: r.fine,
            istantanea: r.istantanea,
            log: r.log,
          ),
        );
        n++;
      }
    }
    return n;
  }

  /// B17: cassaforte finta delle chiavi API.
  final Map<FornitoreIA, String> chiaviIA = <FornitoreIA, String>{};

  /// B17: risposte di chiediIA/provaIA: String o ErroreIA (l'ultima si
  /// ripete). Vuota = 'Resoconto finto'.
  final List<Object> risposteIA = <Object>[];

  /// B17: testi mandati all'IA (con la config).
  final List<(ConfigIA, String)> chiamateIA = <(ConfigIA, String)>[];

  /// B17: attesa finta della risposta IA (per vedere "attendo").
  Completer<void>? attesaIA;

  Future<String> _rispostaIA(ConfigIA c, String testo) async {
    chiamateIA.add((c, testo));
    if (attesaIA != null) {
      await attesaIA!.future;
    }
    if (risposteIA.isEmpty) {
      return 'Resoconto finto';
    }
    final Object r = risposteIA.length > 1
        ? risposteIA.removeAt(0)
        : risposteIA.first;
    if (r is ErroreIA) {
      throw r;
    }
    return '$r';
  }

  @override
  Future<String?> fineChiaveIA(FornitoreIA f) async {
    final String? k = chiaviIA[f];
    return k == null ? null : fineChiave(k);
  }

  @override
  Future<void> salvaChiaveIA(FornitoreIA f, String chiave) async {
    final String k = chiave.trim();
    if (k.isEmpty) {
      chiaviIA.remove(f);
      return;
    }
    final String? p = problemaChiave(k);
    if (p != null) {
      throw ErroreIA(p);
    }
    chiaviIA[f] = k;
  }

  @override
  Future<String> chiediIA(ConfigIA c, String testo) => _rispostaIA(c, testo);

  @override
  Future<String> provaIA(ConfigIA c) => _rispostaIA(c, testoProva);

  @override
  Future<List<FileResoconto>> resocontiSalvati(
    String cartella, {
    DateTime? inizio,
  }) async {
    final List<FileResoconto> out = <FileResoconto>[
      for (final String p in fileSalvati.keys)
        if (p.startsWith('$cartella/') &&
            eResoconto(p.substring(cartella.length + 1), inizio: inizio))
          (percorso: p, nome: p.substring(cartella.length + 1)),
    ]..sort((FileResoconto a, FileResoconto b) => b.nome.compareTo(a.nome));
    return out;
  }

  @override
  Future<String> leggiTestoFile(String percorso) async =>
      fileSalvati[percorso] ?? (throw Exception('file mancante'));

  @override
  Future<void> apriFile(String percorso) async =>
      collegamenti.add('apri:$percorso');

  // ------------------------------------------------------------ B22 sync
  /// Codice che il finto PC mostra.
  String codiceFinto = '123456';

  /// Esito finto del sync.
  EsitoSync esitoSync = const EsitoSync(ok: true, messaggio: 'ok');

  /// Dispositivi abbinati finti.
  final List<String> abbinatiFinti = <String>[];

  /// Quante volte sincronizza.
  int sync = 0;

  /// Arrivi sync finti.
  // ignore: close_sinks, vive quanto il test
  final StreamController<int> arriviSyncFinti =
      StreamController<int>.broadcast();

  @override
  Future<bool> apriAbbinamento({
    required void Function(String codice) codice,
    required void Function(String nome) fatto,
  }) async {
    codice(codiceFinto);
    return true;
  }

  @override
  void chiudiAbbinamento() {}

  @override
  Future<List<String>> abbinati() async => List<String>.of(abbinatiFinti);

  @override
  Future<void> dimenticaAbbinati() async => abbinatiFinti.clear();

  @override
  Future<EsitoSync> abbinaAlPc(Future<String?> Function() chiediCodice) async {
    final String? c = await chiediCodice();
    if (c == codiceFinto) {
      abbinatiFinti.add('PC');
      return const EsitoSync(ok: true, messaggio: 'Abbinato a PC.');
    }
    return const EsitoSync(ok: false, messaggio: 'no');
  }

  @override
  Future<EsitoSync> sincronizza({bool tutto = false}) async {
    sync++;
    return esitoSync;
  }

  @override
  Stream<int> get arriviSync => arriviSyncFinti.stream;
}
