// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
//
// Strato ui: cosa serve alla grafica dal resto dell'app. La ui NON importa
// data: main.dart crea l'oggetto vero che collega archivio, cassaforte,
// lettori e finestra.
import 'package:traker_ia/domain/catena.dart';
import 'package:traker_ia/domain/modelli.dart';

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

  /// Vero se la batteria è "senza limiti" per l'app (null = non so / PC).
  Future<bool?> batteriaLibera();

  /// Apre Info app nelle impostazioni del telefono.
  Future<void> apriInfoApp();

  /// Butta la copia in memoria dei dati (database cambiato da fuori).
  Future<void> dimenticaCache();

  /// Accende/spegne la lettura in sottofondo (solo telefono).
  Future<void> aggiornaSfondo({required int minuti, required bool acceso});
}
