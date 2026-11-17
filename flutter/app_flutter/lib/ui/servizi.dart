// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
//
// Strato ui: cosa serve alla grafica dal resto dell'app. La ui NON importa
// data: main.dart crea l'oggetto vero che collega archivio, cassaforte,
// lettori e finestra.
import 'package:traker_ia/domain/archivio_settimane.dart';
import 'package:traker_ia/domain/catena.dart';
import 'package:traker_ia/domain/modelli.dart';
import 'package:traker_ia/domain/piani_progetti.dart';
import 'package:traker_ia/domain/resoconto_ia.dart';

/// Esito di un import dei vecchi dati.
typedef EsitoImportUi = ({int file, int letture, int eventi, int scartate});

/// Servizi usati dalla grafica.
abstract interface class Servizi {
  /// Tutte le letture, ordinate.
  Future<List<Lettura>> letture();

  /// Tutti gli eventi, ordinati.
  Future<List<Evento>> eventi();

  /// Salva una lettura.
  Future<void> aggiungiLettura(Lettura l);

  /// Salva un evento.
  Future<void> aggiungiEvento(Evento e);

  /// Impostazioni salvate per le [chiavi] (null = mancante).
  Future<Map<String, String?>> impostazioni(List<String> chiavi);

  /// Salva impostazioni (mai segreti).
  Future<void> salvaImpostazioni(Map<String, String> valori);

  /// Una lettura col [metodo] (auto, estensione, claude_code, cookie).
  /// Errore -> ErroreLettura.
  Future<RisultatoCatena> leggi(String metodo);

  /// Arrivo di un messaggio dall'estensione del browser.
  Stream<void> get arriviEstensione;

  /// Vero se Claude Code è installato su questo dispositivo.
  bool get claudeCodeTrovato;

  /// Vero se c'è un cookie salvato in cassaforte.
  Future<bool> cookieSalvato();

  /// Salva il cookie in cassaforte (vuoto = cancella).
  Future<void> salvaCookie(String cookie);

  /// Cartella proposta per i vecchi dati Python.
  String get cartellaImportPredefinita;

  /// Importa letture.csv / eventi.csv dalla [cartella] (senza doppioni).
  Future<EsitoImportUi> importaVecchi(String cartella);

  /// Vero se "Sempre in primo piano" funziona qui (solo Windows).
  bool get primoPianoDisponibile;

  /// Accende/spegne "Sempre in primo piano".
  Future<void> primoPiano({required bool acceso});

  /// Vero se "Avvio con Windows" si può usare qui (solo exe Windows).
  bool get avvioWindowsDisponibile;

  /// Vero se l'app parte con Windows.
  Future<bool> avvioWindows();

  /// Accende/spegne l'avvio con Windows (acceso = riscrive anche il
  /// percorso dell'exe attuale).
  Future<void> impostaAvvioWindows({required bool acceso});

  /// Aggiorna l'icona vicino all'orologio: testo col mouse sopra ed
  /// etichette del menu.
  Future<void> aggiornaTray(String testo);

  /// Vero se si possono usare i collegamenti guidati (solo Windows).
  bool get collegamentiDisponibili;

  /// Scrive l'estensione nella cartella dati dell'app; restituisce il
  /// percorso della cartella.
  Future<String> preparaEstensione();

  /// Apre Esplora risorse con la cartella [percorso] selezionata.
  Future<void> mostraCartella(String percorso);

  /// Apre la pagina estensioni del browser [idBrowser]. Falso = non trovato.
  Future<bool> apriPaginaEstensioni(String idBrowser);

  /// Apre la finestra cmd con l'accesso guidato a Claude Code.
  Future<bool> accediClaudeCode();

  /// Vero sul telefono: login claude.ai dentro l'app e lettura in
  /// sottofondo; niente estensione, Claude Code, cartella vecchi dati.
  bool get telefono;

  /// Cookie della pagina di login per [sito] ('' = nessuno).
  Future<String> cookieWeb(String sito);

  /// Sistema la pagina di login con id [id] (popup, cookie terze parti).
  Future<void> preparaWeb(int id);

  /// Vero se la batteria è "senza limiti" per l'app (null = non so / PC).
  Future<bool?> batteriaLibera();

  /// Apre Info app nelle impostazioni del telefono.
  Future<void> apriInfoApp();

  /// Butta la copia in memoria dei dati (database cambiato da fuori).
  Future<void> dimenticaCache();

  /// Accende/spegne la lettura in sottofondo (solo telefono).
  Future<void> aggiornaSfondo({required int minuti, required bool acceso});

  /// V2: tutti i progetti, per id.
  Future<List<Progetto>> progetti();

  /// V2: aggiunge un progetto (nome vuoto o doppio = ArgumentError).
  Future<Progetto> aggiungiProgetto(Progetto p);

  /// V2: cambia nome/colore/note di un progetto (id obbligatorio).
  Future<void> modificaProgetto(Progetto p);

  /// V2: settimane archiviate (con istantanea intera), per inizio.
  Future<List<SettimanaProgetto>> settimane();

  /// V2: token scritti a mano per la riga [idRiga] (null = cancella).
  Future<void> salvaTokenManuali(int idRiga, int? token);

  /// V2: archivia le settimane chiuse non ancora archiviate (idempotente).
  /// Ritorna le righe aggiunte.
  Future<int> archiviaSettimaneChiuse({
    required List<Lettura> letture,
    required List<Evento> eventi,
    required DateTime adesso,
    Piano? piano,
  });

  /// V2: cartella proposta per salvare i file .md dell'export per IA.
  String get cartellaEsportaPredefinita;

  /// V2: salva [testo] come [nome] nella [cartella] (la crea se manca).
  /// Ritorna il percorso del file. Errore -> eccezione col motivo.
  Future<String> salvaTestoInCartella({
    required String cartella,
    required String nome,
    required String testo,
  });

  /// V2 B17: ultimi 4 caratteri della chiave API salvata in cassaforte per
  /// [f] (null = nessuna). La ui NON riceve mai la chiave intera.
  Future<String?> fineChiaveIA(FornitoreIA f);

  /// V2 B17: salva in cassaforte la chiave API di [f] ('' = cancella).
  /// Chiave non valida -> ErroreIA col motivo.
  Future<void> salvaChiaveIA(FornitoreIA f, String chiave);

  /// V2 B17: manda [testo] all'IA di [c]; ritorna la risposta.
  /// Errore -> ErroreIA in italiano.
  Future<String> chiediIA(ConfigIA c, String testo);

  /// V2 B17: chiamata minima di prova. Errore -> ErroreIA.
  Future<String> provaIA(ConfigIA c);

  /// V2 B17: file resoconto .md nella [cartella] (solo la settimana che
  /// inizia il giorno di [inizio], se dato). Più nuovi prima.
  Future<List<FileResoconto>> resocontiSalvati(
    String cartella, {
    DateTime? inizio,
  });

  /// V2 B17: testo di un file (resoconto salvato).
  Future<String> leggiTestoFile(String percorso);

  /// V2 B17: apre il file con il programma di Windows (Esplora risorse).
  Future<void> apriFile(String percorso);
}
