// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
//
// Strato ui: stato dell'app (letture, preferenze, vista, giro letture).
// Leggerezza: i calcoli si fanno qui, 1 volta quando cambiano i dati o
// scatta il minuto; la grafica legge solo i risultati.
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:traker_ia/domain/catena.dart';
import 'package:traker_ia/domain/combinazioni.dart';
import 'package:traker_ia/domain/confronti.dart' hide confrontoNota;
import 'package:traker_ia/domain/confronti.dart' as cf show confrontoNota;
import 'package:traker_ia/domain/coppie.dart';
import 'package:traker_ia/domain/lavoro.dart';
import 'package:traker_ia/domain/modelli.dart';
import 'package:traker_ia/domain/periodo.dart';
import 'package:traker_ia/domain/preferenze.dart';
import 'package:traker_ia/domain/previsione.dart' as prev;
import 'package:traker_ia/domain/sfondo.dart';
import 'package:traker_ia/domain/tempo.dart';
import 'package:traker_ia/domain/traduzioni/testi_it.dart';
import 'package:traker_ia/domain/tray.dart';
import 'package:traker_ia/domain/vista.dart';
import 'package:traker_ia/ui/grafico_dati.dart';
import 'package:traker_ia/ui/servizi.dart';

/// Valori di una carta in alto (sessione o settimana).
typedef ValoreCarta = ({double? valore, String sotto});

/// Stato dell'app.
class StatoApp extends ChangeNotifier {
  /// Crea lo stato. [orologio] per i test.
  StatoApp(this.servizi, {DateTime Function()? orologio, this.giri = true})
    : _orologio = orologio ?? DateTime.now;

  /// Servizi (archivio, letture, cassaforte...).
  final Servizi servizi;

  /// Falso nei test: niente timer.
  final bool giri;

  final DateTime Function() _orologio;
  final AvvisoFallimenti _avviso = AvvisoFallimenti();
  Timer? _giro;
  Timer? _minuto;
  Timer? _primaLettura;
  StreamSubscription<void>? _estensione;
  bool _chiuso = false;

  List<Lettura> _letture = <Lettura>[];
  List<Evento> _eventi = <Evento>[];
  Preferenze _pref = Preferenze();
  StatoVista _vista = StatoVista.base();
  Uso? _ultimoUso;
  DateTime? _ultimaEstensione;
  bool _inLettura = false;
  bool _pronto = false;
  bool _cookie = false;
  bool _avvio = false;
  bool? _batteria;
  bool _loginScaduto = false;
  String _trayInviato = '';
  String _cartella = '';
  String _stato = Testi.avvio;
  bool _statoErrore = false;
  String? _avvisoDaMostrare;

  // Scelte della carta confronti (null = automatico).
  DateTime? _notaScelta;
  Combo? _sceltaA;
  Combo? _sceltaB;

  // Risultati calcolati.
  ValoreCarta _cartaSess = (valore: null, sotto: Testi.resetInAttesa);
  ValoreCarta _cartaSett = (valore: null, sotto: Testi.resetInAttesa);
  DatiGrafico? _grafico;
  List<String> _frasi = <String>[];
  List<Evento> _note = <Evento>[];
  ConfrontoNota? _confNota;
  List<Combo> _combo = <Combo>[];
  Map<Combo, RitmoCombo> _tabUsata = <Combo, RitmoCombo>{};
  ConfrontoCombo? _confCombo;
  String _classifica = '';

  /// Ora attuale (al minuto).
  DateTime get adesso => alMinuto(_orologio());

  /// Vero dopo il primo caricamento.
  bool get pronto => _pronto;

  /// Tutte le letture.
  List<Lettura> get letture => _letture;

  /// Preferenze attuali.
  Preferenze get preferenze => _pref;

  /// Vista attuale.
  StatoVista get vista => _vista;

  /// Lavoro in corso.
  bool get lavoro => lavoroAperto(_eventi);

  /// Testo della riga di stato.
  String get stato => _stato;

  /// La riga di stato è un errore.
  bool get statoErrore => _statoErrore;

  /// Lettura in corso.
  bool get inLettura => _inLettura;

  /// C'è un cookie salvato.
  bool get cookie => _cookie;

  /// Telefono: batteria "senza limiti" (null = non so).
  bool? get batteriaLibera => _batteria;

  /// Telefono: il sito ha rifiutato il login, va rifatto.
  bool get loginScaduto => _loginScaduto;

  /// L'app parte con Windows.
  bool get avvioWindows => _avvio;

  /// Cartella dei vecchi dati.
  String get cartellaImport => _cartella;

  /// Carta sessione.
  ValoreCarta get cartaSess => _cartaSess;

  /// Carta settimana.
  ValoreCarta get cartaSett => _cartaSett;

  /// Dati del grafico (null prima del caricamento).
  DatiGrafico? get grafico => _grafico;

  /// Frasi "Cosa dicono i dati".
  List<String> get frasi => _frasi;

  /// Tutte le note, dalla prima.
  List<Evento> get note => _note;

  /// Nota scelta nella carta confronti.
  Evento? get notaScelta {
    for (final Evento e in _note.reversed) {
      if (e.ora == _notaScelta) {
        return e;
      }
    }
    return _note.isEmpty ? null : _note.last;
  }

  /// Confronto prima/dopo la nota (null = nessuna nota).
  ConfrontoNota? get confrontoNota => _confNota;

  /// Combinazioni, dalla più usata.
  List<Combo> get combinazioni => _combo;

  /// Combinazione A scelta.
  Combo? get comboA => _scegli(_sceltaA, 0);

  /// Combinazione B scelta.
  Combo? get comboB => _scegli(_sceltaB, 1);

  /// Tabella ritmi usata per il confronto (tutto o solo lavoro).
  Map<Combo, RitmoCombo> get tabellaCombo => _tabUsata;

  /// Confronto A/B (null se manca B).
  ConfrontoCombo? get confrontoCombo => _confCombo;

  /// Testo classifica modelli.
  String get classifica => _classifica;

  /// Avviso da mostrare (2 letture fallite), null = niente.
  String? get avvisoDaMostrare => _avvisoDaMostrare;

  /// Tutte le letture in [periodo] della combinazione (per le spiegazioni).
  Periodo? periodoDi(Combo k) => periodoCombo(_letture, k);

  Combo? _scegli(Combo? s, int i) {
    if (s != null && _combo.contains(s)) {
      return s;
    }
    return i < _combo.length ? _combo[i] : null;
  }

  // ------------------------------------------------------------------ avvio

  /// Carica dati e preferenze, import automatico al primo avvio, timer.
  Future<void> avvia() async {
    final Map<String, String?> imp = await servizi.impostazioni(Chiavi.tutte);
    _pref = Preferenze.daMappa(imp);
    _vista = StatoVista.daJson(_json(imp[Chiavi.vista]));
    _cartella = (imp[Chiavi.cartellaImport] ?? '').trim();
    if (_cartella.isEmpty) {
      _cartella = servizi.cartellaImportPredefinita;
    }
    _cookie = await servizi.cookieSalvato();
    if (servizi.telefono) {
      _loginScaduto = imp[Chiavi.loginScaduto] == '1';
      if (_loginScaduto) {
        _avvisoDaMostrare = Testi.rifaiLogin;
      }
      _batteria = await servizi.batteriaLibera();
      await _aggiornaSfondo();
    }
    await _avvioPrimaVolta(imp[Chiavi.avvioDeciso]);
    await _scriviEstensione();
    await _ricarica();
    if (_letture.isEmpty && imp[Chiavi.importFatto] != '1') {
      // Primo avvio: prova da solo a importare i vecchi dati Python.
      await servizi.salvaImpostazioni(<String, String>{
        Chiavi.importFatto: '1',
      });
      final EsitoImportUi e = await servizi.importaVecchi(_cartella);
      if (e.file > 0) {
        await _ricarica();
        _scriviStato(
          Testi.esitoImport(e.file, e.letture, e.eventi, e.scartate),
        );
      }
    }
    if (_vista.primoPiano && servizi.primoPianoDisponibile) {
      await servizi.primoPiano(acceso: true);
    }
    _pronto = true;
    _ricalcola();
    if (giri && !_chiuso) {
      _estensione = servizi.arriviEstensione.listen((_) => _daEstensione());
      _primaLettura = Timer(const Duration(milliseconds: 1500), () {
        unawaited(leggi());
      });
      _programma();
      _minuto = Timer.periodic(const Duration(minutes: 1), (_) => _ricalcola());
    }
  }

  /// Telefono: lettura in sottofondo accesa se c'è il login e non è
  /// "solo manuale".
  Future<void> _aggiornaSfondo() async {
    if (!servizi.telefono) {
      return;
    }
    await servizi.aggiornaSfondo(
      minuti: _pref.minuti,
      acceso: _cookie && _pref.metodo != metodoManuale,
    );
  }

  /// Telefono: tornando nell'app rilegge i dati (la lettura in sottofondo
  /// può averne aggiunti), batteria e login; legge se l'ultima è vecchia.
  Future<void> riprendi() async {
    if (!_pronto || _chiuso) {
      return;
    }
    await servizi.dimenticaCache();
    await _ricarica();
    final Map<String, String?> imp = await servizi.impostazioni(<String>[
      Chiavi.loginScaduto,
    ]);
    final bool scaduto = imp[Chiavi.loginScaduto] == '1';
    if (scaduto && !_loginScaduto) {
      _avvisoDaMostrare = Testi.rifaiLogin;
    }
    _loginScaduto = scaduto;
    _batteria = await servizi.batteriaLibera();
    _ricalcola();
    if (giri && serveLetturaAlRitorno(_letture, adesso, _pref.minuti)) {
      await leggi();
    }
  }

  /// Rilegge lo stato della batteria (dopo Info app).
  Future<void> aggiornaBatteria() async {
    _batteria = await servizi.batteriaLibera();
    _avvisa();
  }

  /// Login fatto nella pagina dell'app: salva il cookie di sessione in
  /// cassaforte, accende il sottofondo e legge subito.
  Future<void> salvaLoginWeb(String valore) async {
    await servizi.salvaCookie(valore);
    _cookie = await servizi.cookieSalvato();
    await _togliLoginScaduto();
    await _aggiornaSfondo();
    await leggi();
  }

  Future<void> _togliLoginScaduto() async {
    if (!_loginScaduto) {
      return;
    }
    _loginScaduto = false;
    await servizi.salvaImpostazioni(<String, String>{Chiavi.loginScaduto: '0'});
  }

  /// Avvio con Windows: acceso da solo la prima volta, poi decide l'utente.
  /// Se acceso, riscrive il percorso dell'exe attuale (es. nuova release).
  Future<void> _avvioPrimaVolta(String? deciso) async {
    if (!servizi.avvioWindowsDisponibile) {
      return;
    }
    if (deciso != '1') {
      await servizi.impostaAvvioWindows(acceso: true);
      await servizi.salvaImpostazioni(<String, String>{
        Chiavi.avvioDeciso: '1',
      });
    } else if (await servizi.avvioWindows()) {
      await servizi.impostaAvvioWindows(acceso: true);
    }
    _avvio = await servizi.avvioWindows();
  }

  /// PC: a ogni lettura riprende in silenzio quello che la vecchia app
  /// Python ha scritto (senza doppioni), così le due app restano uguali.
  Future<void> _seguiPython() async {
    if (servizi.telefono || _cartella.isEmpty) {
      return;
    }
    try {
      final EsitoImportUi e = await servizi.importaVecchi(_cartella);
      if (e.letture + e.eventi > 0) {
        await _ricarica();
        _ricalcola();
      }
    } on Exception {
      // Cartella sparita o file in scrittura: si riprova al prossimo giro.
    }
  }

  /// Tiene aggiornata la cartella fissa dell'estensione (Documenti).
  Future<void> _scriviEstensione() async {
    if (!servizi.collegamentiDisponibili) {
      return;
    }
    try {
      await servizi.preparaEstensione();
    } on Object {
      // non blocca l'avvio: il tasto in Impostazioni riprova
    }
  }

  static Object? _json(String? s) {
    if (s == null) {
      return null;
    }
    try {
      return jsonDecode(s);
    } on FormatException {
      return null;
    }
  }

  void _programma() {
    _giro?.cancel();
    _giro = Timer.periodic(Duration(minutes: _pref.minuti), (_) => _faiGiro());
  }

  void _faiGiro() {
    final DateTime? e = _ultimaEstensione;
    // L'estensione manda già le letture: niente doppioni.
    if (e != null &&
        adesso.difference(e) <= Duration(minutes: _pref.minuti + 3)) {
      return;
    }
    unawaited(leggi());
  }

  void _daEstensione() {
    if (_pref.metodo == metodoAuto || _pref.metodo == 'estensione') {
      unawaited(leggi());
    }
  }

  Future<void> _ricarica() async {
    _letture = await servizi.letture();
    _eventi = await servizi.eventi();
  }

  @override
  void dispose() {
    _chiuso = true;
    _giro?.cancel();
    _minuto?.cancel();
    _primaLettura?.cancel();
    unawaited(_estensione?.cancel());
    super.dispose();
  }

  void _scriviStato(String t, {bool errore = false}) {
    _stato = t;
    _statoErrore = errore;
  }

  void _avvisa() {
    if (!_chiuso) {
      notifyListeners();
    }
  }

  // ------------------------------------------------------------------ letture

  /// Lettura adesso col metodo scelto.
  Future<void> leggi() async {
    if (_inLettura || _chiuso) {
      return;
    }
    await _seguiPython();
    if (_pref.metodo == metodoManuale) {
      _scriviStato(Testi.soloManuale);
      _avvisa();
      return;
    }
    if (servizi.telefono && !_cookie) {
      _scriviStato(Testi.serveLogin, errore: true);
      _avvisa();
      return;
    }
    _inLettura = true;
    _scriviStato(Testi.leggo);
    _avvisa();
    try {
      final RisultatoCatena r = await servizi.leggi(_pref.metodo);
      if (_chiuso) {
        return;
      }
      final DateTime ora = adesso;
      _ultimoUso = r.uso;
      if (r.lettore == 'estensione') {
        _ultimaEstensione = ora;
      }
      await servizi.aggiungiLettura(
        letturaAutomatica(r.uso, ora, _pref, _eventi),
      );
      _avviso.ok();
      await _togliLoginScaduto();
      _letture = await servizi.letture();
      _scriviStato(
        Testi.ultimaLettura(
          formatta(ora).substring(11),
          Testi.nomiMetodi[r.lettore] ?? r.lettore,
        ),
      );
    } on ErroreLettura catch (e) {
      if (e.loginScaduto && servizi.telefono) {
        // 401/403 sul telefono: avviso subito, una volta.
        _scriviStato(Testi.rifaiLogin, errore: true);
        if (!_loginScaduto) {
          _loginScaduto = true;
          _avvisoDaMostrare = Testi.rifaiLogin;
          await servizi.salvaImpostazioni(<String, String>{
            Chiavi.loginScaduto: '1',
          });
        }
      } else {
        _scriviStato(Testi.letturaFallita(e.messaggio), errore: true);
        if (_avviso.ko()) {
          _avvisoDaMostrare = e.messaggio;
        }
      }
    } finally {
      _inLettura = false;
    }
    _ricalcola();
  }

  /// L'avviso è stato mostrato.
  void avvisoVisto() {
    _avvisoDaMostrare = null;
  }

  /// Salva una lettura scritta a mano.
  Future<void> aggiungiManuale(DateTime ora, double? sett, double? sess) async {
    await servizi.aggiungiLettura(
      Lettura(
        ora: alMinuto(ora),
        sett: sett,
        sess: sess,
        fonte: 'manuale',
        modelli: _pref.daRaccogliere(Gruppo.modelli),
        skill: _pref.daRaccogliere(Gruppo.skill),
      ),
    );
    _letture = await servizi.letture();
    _ricalcola();
  }

  /// Aggiunge una nota (testo vuoto = niente).
  Future<void> aggiungiNota(String testo) async {
    final String t = testo.trim();
    if (t.isEmpty) {
      return;
    }
    final DateTime ora = adesso;
    await servizi.aggiungiEvento(
      Evento(ora: ora, tipo: TipoEvento.nota, testo: t),
    );
    _eventi = await servizi.eventi();
    _notaScelta = ora;
    _ricalcola();
  }

  /// Inizio / fine lavoro.
  Future<void> cambiaLavoro() async {
    await servizi.aggiungiEvento(
      Evento(ora: adesso, tipo: lavoro ? TipoEvento.fine : TipoEvento.inizio),
    );
    _eventi = await servizi.eventi();
    _ricalcola();
  }

  // ------------------------------------------------------------- preferenze

  Future<void> _salvaPref(Preferenze p) async {
    _pref = p;
    _ricalcola();
    await servizi.salvaImpostazioni(p.aMappa());
  }

  /// Accende/spegne un tasto modello/skill.
  Future<void> tocca(Gruppo g, String nome) => _salvaPref(_pref.tocca(g, nome));

  /// Nuovo ordine dei tasti di un gruppo.
  Future<void> riordina(Gruppo g, List<String> ordine) =>
      _salvaPref(_pref.riordina(g, ordine));

  /// Aggiunge un tasto.
  Future<void> aggiungiTasto(Gruppo g, String nome) =>
      _salvaPref(_pref.aggiungi(g, nome));

  /// Rinomina un tasto.
  Future<void> rinominaTasto(Gruppo g, String vecchio, String nuovo) =>
      _salvaPref(_pref.rinomina(g, vecchio, nuovo));

  /// Toglie un tasto.
  Future<void> togliTasto(Gruppo g, String nome) =>
      _salvaPref(_pref.togli(g, nome));

  /// Scatto del cursore periodo.
  Future<void> cambiaPeriodo(int scatto) =>
      _salvaPref(_pref.copia(periodo: normalizzaScatto(scatto)));

  /// Spunta "Conta solo lavoro".
  Future<void> cambiaSoloLavoro({required bool acceso}) =>
      _salvaPref(_pref.copia(soloLavoro: acceso));

  /// Salva le impostazioni del dialogo. [cookie] null = lascia com'è,
  /// '' = cancella.
  Future<void> salvaImpostazioni({
    required int minuti,
    required String metodo,
    required String cartella,
    String? cookie,
    bool? avvioWindows,
  }) async {
    if (avvioWindows != null &&
        avvioWindows != _avvio &&
        servizi.avvioWindowsDisponibile) {
      await servizi.impostaAvvioWindows(acceso: avvioWindows);
      _avvio = await servizi.avvioWindows();
    }
    if (cookie != null) {
      await servizi.salvaCookie(cookie);
      _cookie = await servizi.cookieSalvato();
      if (_cookie) {
        await _togliLoginScaduto();
      }
    }
    _cartella = cartella.trim();
    await servizi.salvaImpostazioni(<String, String>{
      Chiavi.cartellaImport: _cartella,
    });
    await _salvaPref(_pref.copia(minuti: minuti, metodo: metodo));
    await _aggiornaSfondo();
    if (giri) {
      _programma();
    }
    await leggi();
  }

  /// Importa adesso i vecchi dati dalla [cartella].
  Future<String> importaOra(String cartella) async {
    final EsitoImportUi e = await servizi.importaVecchi(cartella.trim());
    await _ricarica();
    _ricalcola();
    return Testi.esitoImport(e.file, e.letture, e.eventi, e.scartate);
  }

  // ------------------------------------------------------------------ vista

  Future<void> _salvaVista(StatoVista v) async {
    final bool pp = v.primoPiano != _vista.primoPiano;
    _vista = v;
    _avvisa();
    if (pp && servizi.primoPianoDisponibile) {
      await servizi.primoPiano(acceso: v.primoPiano);
    }
    await servizi.salvaImpostazioni(<String, String>{
      Chiavi.vista: jsonEncode(v.aJson()),
    });
  }

  /// Accende/spegne una sezione (menu Vista).
  Future<void> cambiaVisibile(Sezione s) =>
      _salvaVista(_vista.cambiaVisibile(s));

  /// Apre/chiude una sezione (clic sul titolo).
  Future<void> cambiaAperta(Sezione s) => _salvaVista(_vista.cambiaAperta(s));

  /// Sceglie il modo della finestra.
  Future<void> scegliModo(ModoVista m) => _salvaVista(_vista.scegliModo(m));

  /// Sempre in primo piano.
  Future<void> cambiaPrimoPiano() => _salvaVista(_vista.cambiaPrimoPiano());

  // -------------------------------------------------------------- confronti

  /// Sceglie la nota del confronto.
  void scegliNota(Evento e) {
    _notaScelta = e.ora;
    _ricalcola();
  }

  /// Sceglie la combinazione A (0) o B (1).
  void scegliCombo(int lato, Combo k) {
    if (lato == 0) {
      _sceltaA = k;
    } else {
      _sceltaB = k;
    }
    _ricalcola();
  }

  // ------------------------------------------------------------- ricalcolo

  ValoreCarta _carta(Campo campo, DateTime? reset, DateTime ora) {
    double? v;
    for (final Lettura l in _letture.reversed) {
      v = l.valore(campo);
      if (v != null) {
        break;
      }
    }
    final DateTime? r = arrotondaReset(reset);
    if (r == null) {
      return (valore: v, sotto: Testi.resetInAttesa);
    }
    final String q = campo == Campo.sess
        ? formatta(r).substring(11)
        : quando(r);
    final double ore = oreTra(ora, r);
    return (valore: v, sotto: Testi.resetTra(q, durata(ore < 0 ? 0 : ore)));
  }

  void _ricalcola() {
    if (!_pronto || _chiuso) {
      return;
    }
    final DateTime ora = adesso;
    _cartaSess = _carta(Campo.sess, _ultimoUso?.resetSess, ora);
    _cartaSett = _carta(Campo.sett, _ultimoUso?.resetSett, ora);

    final DateTime iniSett = inizioSettimana(ora);
    final ({DateTime da, DateTime a}) iv = intervallo(
      _pref.periodo,
      ora,
      iniSett,
      _letture.isEmpty ? null : _letture.first.ora,
    );
    _grafico = calcolaDatiGrafico(_letture, _eventi, iv.da, iv.a, ora);

    final DateTime resetSett =
        arrotondaReset(_ultimoUso?.resetSett) ?? prossimoReset(ora);
    final List<Lettura> settimana = _letture
        .where((Lettura l) => !l.ora.isBefore(iniSett) && !l.ora.isAfter(ora))
        .toList();
    _frasi = prev.frasi(settimana, resetSett, ora);

    final List<Periodo>? periodi = _pref.soloLavoro
        ? periodiLavoro(_eventi, ora)
        : null;
    _note = _eventi.where((Evento e) => e.tipo == TipoEvento.nota).toList();
    final Evento? n = notaScelta;
    _confNota = n == null
        ? null
        : cf.confrontoNota(_letture, n.ora, periodi: periodi);

    final Map<Combo, RitmoCombo> tab = ritmoPerCombinazione(_letture);
    final Map<Combo, RitmoCombo>? tabLav = periodi == null
        ? null
        : ritmoPerCombinazione(_letture, periodi: periodi);
    _combo = tab.keys.toList()
      ..sort((Combo x, Combo y) => tab[y]!.ore.compareTo(tab[x]!.ore));
    final Combo? a = comboA;
    final Combo? b = comboB;
    _tabUsata = tab;
    _confCombo = null;
    if (a != null && b != null) {
      final ConfrontoCombo c = confrontoCombinazioni(
        tab,
        a,
        b,
        tabLavoro: tabLav,
      );
      _confCombo = c;
      if (c.filtro == FiltroLavoro.lavoro && tabLav != null) {
        _tabUsata = tabLav;
      }
    }
    _classifica = testoClassifica(classificaModelli(_letture));
    _aggiornaTray(ora);
    _avvisa();
  }

  /// Testo dell'icona vicino all'orologio: mandato solo se cambia.
  void _aggiornaTray(DateTime ora) {
    final String t = testoTray(
      _letture,
      ora,
      resetSess: arrotondaReset(_ultimoUso?.resetSess),
    );
    if (t != _trayInviato) {
      _trayInviato = t;
      unawaited(servizi.aggiornaTray(t));
    }
  }
}
