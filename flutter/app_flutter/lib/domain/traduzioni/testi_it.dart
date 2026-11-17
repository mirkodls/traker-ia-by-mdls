// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
//
// File traduzioni (italiano): TUTTI i testi dell'app, della logica e della
// grafica. Dart puro (niente Flutter): lo usano domain e ui.
// Per l'inglese (dopo l'MVP): copia questo file in testi_en.dart.
import '../analisi.dart' show Verdetto;

/// 0.94 -> '0,94'; null -> '-'.
String numero(double? x, {int dec = 2}) =>
    x == null ? '-' : x.toStringAsFixed(dec).replaceAll('.', ',');

/// 0.1 -> '0,1 h'; null -> '-'.
String testoOre(double? h) =>
    h == null ? '-' : '${h.toStringAsFixed(1).replaceAll('.', ',')} h';

/// 1.5 -> '1h 30m'.
String durata(double ore) {
  final int m = (ore * 60).round();
  return '${m ~/ 60}h ${(m % 60).toString().padLeft(2, '0')}m';
}

/// Percentuale corta: 21.0 -> '21%', 21.5 -> '21,5%'; null -> '-'.
String percento(double? v) {
  if (v == null) {
    return '-';
  }
  final double r = (v * 10).roundToDouble() / 10;
  return r == r.roundToDouble()
      ? '${r.toStringAsFixed(0)}%'
      : '${r.toStringAsFixed(1).replaceAll('.', ',')}%';
}

/// Testi fissi (italiano).
abstract final class Testi {
  // ---------------------------------------------------------------- logica

  /// Combinazione senza modelli né skill.
  static const String nonSegnato = '(non segnato)';

  /// Nessun modello acceso.
  static const String nessunModello = 'nessun modello';

  /// Spunta "Conta solo lavoro" ma nessun periodo.
  static const String nessunLavoro = '(nessun periodo lavoro: conta tutto)';

  /// Filtro attivo.
  static const String soloLavoro = '(solo lavoro)';

  /// Riquadro dati senza letture settimanali.
  static const String nessunDato =
      'Nessun dato settimanale: aspetta una lettura.';

  /// Poco consumo nel periodo.
  static const String datoDebole = 'Dato debole: aspetta.';

  /// Classifica vuota.
  static const String classificaVuota =
      'Classifica modelli: ancora nessun dato.';

  /// Spiegazione pt%/h.
  static const String pth =
      'pt%/h = punti percentuali della barra consumati in media ogni ora.\n'
      'Esempio: 0,50 vuol dire che la barra sale di mezzo punto ogni ora.\n'
      'Più è basso, più Claude dura.';

  /// Spiegazione 'sett'.
  static const String sett =
      "'sett' = barra della SETTIMANA (si azzera il martedì alle 20:00).";

  /// Come si calcola il ritmo.
  static const String freccia =
      'Il ritmo è calcolato solo sulle letture vere. '
      'I cali della barra (reset) non contano.';

  /// Spiegazione (non segnato).
  static const String spiegaNonSegnato =
      '(non segnato) = letture fatte prima dei tasti modelli/skill.\n'
      'Non si sa quale modello era acceso, quindi sono tenute a parte.';

  /// Spiegazione al PC / automatico.
  static const String alPc =
      'Al PC = intervalli in cui hai usato mouse o tastiera.\n'
      'Automatico = PC fermo (lavora solo Claude o niente).\n'
      'Il tempo di inattività si cambia in Impostazioni.';

  /// Spiegazione "Conta solo lavoro".
  static const String spiegaSoloLavoro =
      "Conta solo lavoro: i ritmi usano SOLO il tempo tra 'Inizio lavoro' e "
      "'Fine lavoro'\n(periodo ancora aperto = fino ad adesso). Le letture a "
      'cavallo vengono tagliate in proporzione.\n'
      'Se prima o dopo (o A o B) non ha ore di lavoro, conta tutto e lo scrive.\n'
      'Vale per la riga Nota e per la riga Combinazioni. Verdetto sempre ±10%.';

  /// Spiegazione ore della nota.
  static const String spiegaOreNota =
      'Ore di letture vere dietro ai due ritmi. '
      'Poche ore = numero poco affidabile.';

  /// Testo "Come leggere i confronti".
  static const String comeLeggere =
      'COME LEGGERE I CONFRONTI\n\n'
      "Nota: confronta il ritmo PRIMA e DOPO la nota scelta. 'Prima' parte "
      "dall'ultimo reset della settimana, 'dopo' arriva a oggi.\n\n"
      'Combinazioni: confronta due modi di lavorare (modelli + skill accesi) '
      'tra loro. Ogni intervallo tra due letture va alla combinazione segnata '
      'nella lettura di arrivo.\n\n'
      'Il ritmo è in pt%/h: punti della barra consumati ogni ora. '
      'Più basso = meglio.\n\n'
      'Il verdetto usa ±10%. Con meno di 1 ora di dati: DATO DEBOLE.\n\n'
      'Passa il mouse su ogni numero per la spiegazione '
      '(sul telefono: tieni premuto).';

  /// Link breve a "Come leggere".
  static const String comeLeggereBreve = 'ⓘ Come leggere';

  /// Spiegazioni dei verdetti, per etichetta.
  static const Map<String, String> spiegaVerdetto = <String, String>{
    'SCESO':
        'SCESO: il secondo ritmo è almeno il 10% più basso del primo. '
        'Consumi meno.',
    'SALITO':
        'SALITO: il secondo ritmo è almeno il 10% più alto del primo. '
        'Consumi di più.',
    'COSTANTE':
        'COSTANTE: la differenza è sotto il 10%. Nessun cambiamento chiaro.',
    'DATO DEBOLE':
        'DATO DEBOLE: meno di 1 ora di letture in uno dei due periodi, o dato '
        "mancante.\nIl numero c'è ma non ci si può fidare: aspetta altre letture.",
  };

  /// Frase previsione: finisci prima del reset.
  static String finisciPrima(String quando100, String quandoReset) =>
      'A questo ritmo finisci $quando100. Reset $quandoReset.';

  /// Frase previsione: arrivi al reset.
  static String arriviAlReset(String quandoReset) =>
      'A questo ritmo arrivi al reset senza finire. Reset $quandoReset.';

  /// Frase budget del giorno.
  static String budgetOggi(String punti) =>
      'Oggi puoi usare ancora $punti punti.';

  /// Frase ore a pieno regime.
  static String pienoRegime(String durata) =>
      'A pieno regime ti restano circa $durata di lavoro.';

  /// '(2,0 h prima / 3,5 h dopo)'.
  static String oreNota(String prima, String dopo) =>
      '($prima prima / $dopo dopo)';

  /// Motivo debole: manca un dato.
  static const String mancaDato = '(manca un dato)';

  /// Motivo debole: 'A solo 0,1 h'.
  static String soloOre(String lato, String ore) => '$lato solo $ore';

  /// Titolo classifica con voci.
  static String classifica(String voci) =>
      'Classifica modelli (dal più vorace): $voci';

  /// Riga al PC / automatico.
  static String presenza(String pc, String auto) =>
      'Al PC $pc  ·  automatico $auto  pt%/h sett (questa settimana)';

  /// Spiegazione del numero "prima".
  static String spiegaPrima(
    String da,
    String nota,
    String ore,
    String filtro,
  ) =>
      'PRIMA della nota: ritmo medio da $da (reset settimana) a $nota.\n'
      'Ore di letture usate: $ore $filtro.\n\n$pth';

  /// Spiegazione del numero "dopo".
  static String spiegaDopo(
    String nota,
    String fine,
    String ore,
    String filtro,
  ) =>
      'DOPO la nota: ritmo medio da $nota a $fine.\n'
      'Ore di letture usate: $ore $filtro.\n\n$pth';

  /// Riga spiegazione combinazione: 'A = Opus · caveman'.
  static String comboUguale(String nome, String etichetta) =>
      '$nome = $etichetta';

  /// Riga spiegazione combinazione: ore usate.
  static String oreUsate(String ore) => 'Ore di letture usate: $ore.';

  /// Riga spiegazione combinazione: periodo.
  static String periodoCombo(String da, String a) =>
      'Da $da a $a (solo gli intervalli con questa combinazione).';

  /// Etichette degli scatti del cursore periodo.
  static const List<String> scatti = <String>[
    '2 ore',
    '6 ore',
    '12 ore',
    '24 ore',
    '3 giorni',
    'Settimana',
    '7 giorni',
    'Tutto',
  ];

  // ---------------------------------------------------------------- grafica

  /// Titoli delle sezioni (per nome di Sezione).
  static const Map<String, String> titoliSezioni = <String, String>{
    'carte': 'USO ATTUALE',
    'grafico': 'GRAFICO',
    'intensita': 'INTENSITÀ',
    'barra': 'SKILL / MODELLI · NOTA',
    'dati': 'COSA DICONO I DATI',
    'confronti': 'CONFRONTI',
  };

  /// Voci del menu Vista per le sezioni (per nome di Sezione).
  static const Map<String, String> vociSezioni = <String, String>{
    'carte': 'Uso attuale',
    'grafico': 'Grafico',
    'intensita': 'Intensità',
    'barra': 'Skill / modelli · nota',
    'dati': 'Cosa dicono i dati',
    'confronti': 'Confronti',
  };

  /// Titolo della sezione [nome]; senza modelli/skill (V2) la barra è
  /// solo 'NOTA'.
  static String titoloSezione(String nome, {required bool modelliSkill}) =>
      nome == 'barra' && !modelliSkill ? 'NOTA' : titoliSezioni[nome] ?? nome;

  /// Voce del menu Vista per la sezione [nome] (come [titoloSezione]).
  static String voceSezione(String nome, {required bool modelliSkill}) =>
      nome == 'barra' && !modelliSkill ? 'Nota' : vociSezioni[nome] ?? nome;

  /// Carta sessione.
  static const String cartaSess = 'SESSIONE 5 ORE';

  /// Carta settimana.
  static const String cartaSett = 'SETTIMANA';

  /// Reset non ancora noto.
  static const String resetInAttesa = 'reset: in attesa di lettura';

  /// 'reset 18:00  ·  tra 2h 05m'.
  static String resetTra(String quando, String tra) =>
      'reset $quando  ·  tra $tra';

  /// Tasto leggi ora.
  static const String leggiOra = 'Leggi ora';

  /// Tasto lettura manuale.
  static const String letturaManuale = 'Lettura manuale';

  /// Tasto impostazioni.
  static const String impostazioni = 'Impostazioni';

  /// Tasto vista.
  static const String vista = 'Vista ▾';

  /// Tasto Skill (disattivato).
  static const String skillTasto = 'Skill';

  /// Scritta sotto il tasto Skill.
  static const String inArrivo = 'in arrivo';

  /// Menu Vista: modo tutto.
  static const String modoTutto = 'Mostra tutto';

  /// Menu Vista: solo grafico.
  static const String modoGrafico = 'Solo grafico';

  /// Menu Vista: solo intensità.
  static const String modoIntensita = 'Solo intensità';

  /// Menu Vista: primo piano.
  static const String primoPiano = 'Sempre in primo piano';

  /// Etichetta cursore periodo.
  static const String periodo = 'Periodo';

  /// Legenda grafico.
  static const String legSett = 'Settimana';

  /// Legenda grafico.
  static const String legSess = 'Sessione 5h';

  /// Legenda grafico.
  static const String legNota = 'Nota';

  /// Legenda grafico.
  static const String legReset = 'Reset';

  /// Legenda grafico.
  static const String legLavoro = 'Lavoro';

  /// Aiuto sopra il grafico.
  static const String aiutoNote =
      'passa il mouse sui numeri viola per leggere la nota';

  /// Titolo grafico intensità.
  static const String titoloIntensita =
      'Intensità (pt%/h, barra 5h, media 30 min)';

  /// Nessuna lettura nel grafico.
  static const String graficoVuoto = 'Nessuna lettura in questo periodo.';

  /// Riga riquadro mouse.
  static String rigaValore(String nome, String valore) => '$nome: $valore';

  /// Nome riga settimana nel riquadro.
  static const String rqSett = 'Sett';

  /// Nome riga 5 ore nel riquadro.
  static const String rqSess = '5h';

  /// Nome riga intensità nel riquadro.
  static const String rqIntensita = 'Intensità';

  /// Nome riga modelli nel riquadro.
  static const String rqModelli = 'Modelli';

  /// Nome riga skill nel riquadro.
  static const String rqSkill = 'Skill';

  /// Valore mancante.
  static const String trattino = '—';

  /// Titolo gruppo skill.
  static const String gruppoSkill = 'SKILL';

  /// Titolo gruppo modelli.
  static const String gruppoModelli = 'MODELLI';

  /// Tasto modifica tasti.
  static const String modifica = '✎ modifica';

  /// Aiuto tasti.
  static const String aiutoTasti =
      'Clic = accendi/spegni. Trascina per cambiare ordine.';

  /// Campo nota.
  static const String scriviNota = 'Scrivi una nota (es. "attivato caveman")';

  /// Tasto nota.
  static const String aggiungiNota = 'Aggiungi nota';

  /// Tasto inizio lavoro.
  static const String inizioLavoro = '▶  Inizio lavoro';

  /// Tasto fine lavoro.
  static const String fineLavoro = '■  Fine lavoro';

  /// Etichetta riga nota nei confronti.
  static const String nota = 'Nota';

  /// Etichetta riga combinazioni.
  static const String combinazioni = 'Combinazioni';

  /// 'vs'.
  static const String vs = 'vs';

  /// Unità ritmo.
  static const String unitaSett = 'pt%/h sett';

  /// Nessuna nota.
  static const String nessunaNota =
      'Scrivi una nota per confrontare prima/dopo.';

  /// Nessuna combinazione.
  static const String nessunaCombo =
      'Accendi modelli/skill: le prossime letture li segnano.';

  /// Serve seconda combinazione.
  static const String serveSecondaCombo = '(serve una seconda combinazione)';

  /// Spunta.
  static const String contaSoloLavoro = 'Conta solo lavoro';

  /// 'prima 0,94'.
  static String prima(String v) => 'prima $v';

  /// 'dopo 0,80'.
  static String dopo(String v) => 'dopo $v';

  /// 'A 0,94'.
  static String lato(String nome, String v) => '$nome $v';

  /// Spiegazione classifica.
  static const String spiegaClassifica =
      'Ore tra parentesi = letture usate per quel modello.';

  /// Voce del menu nota: '3.  mer 12/11 17:30 - testo'.
  static String voceNota(int n, String quando, String testo) =>
      '$n.  $quando - $testo';

  // ------------------------------------------------------------ stato/letture

  /// Stato mentre legge.
  static const String leggo = 'Leggo...';

  /// Stato lettura riuscita.
  static String ultimaLettura(String ora, String metodo) =>
      'Ultima lettura $ora ($metodo)';

  /// Stato lettura fallita.
  static String letturaFallita(String msg) => 'Lettura fallita: $msg';

  /// Metodo manuale scelto.
  static const String soloManuale =
      'Metodo manuale: inserisci le letture a mano.';

  /// Stato all'avvio.
  static const String avvio = 'Avvio...';

  /// Nomi dei metodi di lettura (per id).
  static const Map<String, String> nomiMetodi = <String, String>{
    'auto': 'automatico (prova tutti)',
    'estensione': 'estensione browser',
    'claude_code': 'Claude Code',
    'cookie': 'cookie claude.ai',
    'manuale': 'solo manuale',
  };

  /// Titolo avviso.
  static const String titoloAvviso = 'Le letture non funzionano';

  /// Testo avviso dopo 2 letture fallite.
  static String testoAvviso(String msg) =>
      'Due letture di fila sono fallite.\n\n$msg\n\n'
      'Controlla di essere loggato su claude.ai nel browser con '
      "l'estensione,\noppure incolla il cookie in Impostazioni.";

  /// Tasto ok.
  static const String ok = 'OK';

  /// Tasto annulla.
  static const String annulla = 'Annulla';

  /// Tasto salva.
  static const String salva = 'Salva';

  /// Tasto chiudi.
  static const String chiudi = 'Chiudi';

  // ------------------------------------------------------------ tray

  /// Tray senza letture.
  static const String trayNessunaLettura = 'Nessuna lettura ancora';

  /// Tray: riga percentuali.
  static String trayPercentuali(String sess, String sett) =>
      'Sessione $sess · Settimana $sett';

  /// Tray: ultima ora senza dati.
  static const String trayOraVuota = 'Ultima ora: nessun dato';

  /// Tray: intensità ultima ora (+ tendenza e intensità di prima).
  static String trayUltimaOra(String pth, String tendenza, String prima) =>
      'Ultima ora $pth pt/h'
      '${tendenza.isEmpty ? '' : ' $tendenza'}'
      '${prima.isEmpty ? '' : ' (prima $prima)'}';

  /// Tray: tendenza rispetto al resto della sessione.
  static const Map<Verdetto, String> trayTendenza = <Verdetto, String>{
    Verdetto.salito: '↑ in salita',
    Verdetto.sceso: '↓ in discesa',
    Verdetto.costante: '= costante',
  };

  /// Menu tray: mostra finestra.
  static const String trayMostra = 'Mostra';

  /// Menu tray: nascondi finestra.
  static const String trayNascondi = 'Nascondi';

  /// Menu tray: esci davvero.
  static const String trayEsci = 'Esci';

  /// Impostazioni: avvio con Windows.
  static const String avvioWindows = 'Avvia con Windows';

  /// Impostazioni: spiegazione tasto X.
  static const String spiegaX = 'X = nascondi. Chiudi: icona orologio > Esci.';

  // ------------------------------------------------------- collegamenti

  /// Impostazioni: titolo sezione collegamenti.
  static const String collegaFonti = 'Collegamenti';

  /// Tasto: installa estensione.
  static const String installaEstensione = 'Estensione browser';

  /// Tasto: accesso a Claude Code.
  static const String accediClaudeCode = 'Accedi a Claude Code';

  /// Esito: finestra cmd aperta.
  static const String claudeCodeAperto = 'Segui i passi nella finestra nera.';

  /// Esito: finestra cmd non partita.
  static const String claudeCodeErrore = 'Finestra non aperta.';

  /// Titolo dialogo estensione.
  static const String titoloEstensione = 'Estensione browser';

  /// Firefox non ancora pronto.
  static const String firefoxInArrivo = 'Firefox: presto.';

  /// Tasto: apri pagina estensioni.
  static const String apriPagina = 'Apri pagina';

  /// Tasto: apri cartella estensione.
  static const String apriCartella = 'Apri cartella';

  /// Passo 1 (con tasto Apri pagina).
  static String passoPagina(String pagina) => 'Apri $pagina';

  /// Passo 2.
  static const String passoSviluppatore =
      'Accendi "Modalità sviluppatore" (in alto a destra)';

  /// Passo 3 (con tasto Apri cartella).
  static const String passoCartella = 'Apri la cartella';

  /// Passo 4.
  static const String passoTrascina = 'Trascina "chromium" nella pagina';

  /// Passo 5.
  static const String passoFatto =
      'Fatto: compare "TraKer IA by mdls". Login su claude.ai.';

  /// Browser non trovato.
  static String browserNonTrovato(String pagina) =>
      'Browser non trovato: aprilo e scrivi $pagina';

  // ------------------------------------------------------------ manuale

  /// Titolo dialogo manuale.
  static const String titoloManuale = 'Lettura manuale';

  /// Campo data.
  static const String campoOra = 'Data e ora (AAAA-MM-GG HH:MM)';

  /// Campo settimanale.
  static const String campoSett = 'Settimanale %';

  /// Campo sessione.
  static const String campoSess = 'Sessione 5h % (anche vuoto)';

  /// Errore manuale.
  static const String erroreManuale =
      'Controlla data/ora e percentuali (0-100, almeno una).';

  // ------------------------------------------------------------ modifica tasti

  /// Titolo dialogo modifica.
  static String titoloModifica(String gruppo) => 'Modifica $gruppo';

  /// Campo nome.
  static const String campoNome = 'Nome';

  /// Tasto aggiungi.
  static const String aggiungi = 'Aggiungi';

  /// Tasto rinomina.
  static const String rinomina = 'Rinomina';

  /// Tasto togli.
  static const String togli = 'Togli';

  /// Sposta su il nome scelto.
  static const String su = '↑ Su';

  /// Sposta giù il nome scelto.
  static const String giu = '↓ Giù';

  /// Nota rinomina.
  static const String notaRinomina =
      'Rinomina vale da ora: le letture vecchie tengono il nome vecchio.';

  /// Errore nome non valido.
  static const String nomeNonValido =
      'Nome vuoto, troppo lungo (max 20) o con | ; dentro.';

  /// Errore nome doppio.
  static const String nomeDoppio = 'Nome già presente.';

  /// Nessun nome scelto.
  static const String scegliNome = 'Scegli prima un nome dalla lista.';

  // ------------------------------------------------------------ impostazioni

  /// Titolo impostazioni.
  static const String titoloImpostazioni = 'Impostazioni';

  /// Campo minuti.
  static const String campoMinuti = 'Leggi ogni (minuti)';

  /// Campo metodo.
  static const String campoMetodo = 'Metodo di lettura';

  /// Claude Code trovato o no.
  static String claudeCode(bool trovato) =>
      'Claude Code su questo dispositivo: ${trovato ? 'trovato' : 'non trovato'}';

  /// Campo cookie.
  static const String campoCookie =
      "Cookie sessionKey di claude.ai (vuoto = lascia com'è)";

  /// Stato cookie salvato.
  static String cookieSalvato(bool si) =>
      si ? 'Cookie: salvato.' : 'Cookie: non salvato.';

  /// Avviso cookie.
  static const String avvisoCookie =
      'Salvato cifrato solo su questo dispositivo. Non darlo a nessuno.';

  /// Tasto cancella cookie.
  static const String cancellaCookie = 'Cancella cookie';

  /// Campo cartella vecchi dati.
  static const String campoCartella =
      'Cartella vecchi dati (letture.csv / eventi.csv)';

  /// Tasto importa.
  static const String importaOra = 'Importa ora';

  /// Tasto salva e prova.
  static const String salvaEProva = 'Salva e prova';

  /// Errore minuti.
  static const String erroreMinuti = 'Minuti: numero intero da 1 a 120.';

  /// Esito import.
  static String esitoImport(int file, int letture, int eventi, int scartate) =>
      file == 0
      ? 'Nessun file trovato nella cartella.'
      : 'Import: $letture letture e $eventi eventi nuovi'
            '${scartate > 0 ? ', $scartate righe rotte saltate' : ''}.';

  // ------------------------------------------------------------ telefono

  /// Login scaduto (401/403): rifare.
  static const String rifaiLogin =
      'Login claude.ai scaduto. Rifai login: ⚙ > Accedi a claude.ai.';

  /// Telefono senza login.
  static const String serveLogin = 'Serve login: ⚙ > Accedi a claude.ai.';

  /// Impostazioni: titolo sezione accesso.
  static const String titoloAccesso = 'Accesso';

  /// Tasto: login nella pagina dell'app.
  static String accedi(String fornitore) => 'Accedi a $fornitore';

  /// Stato login.
  static String statoLogin({required bool fatto, required bool scaduto}) =>
      scaduto
      ? 'Login: scaduto, rifallo.'
      : (fatto ? 'Login: fatto.' : 'Login: non fatto.');

  /// Esito: login riuscito.
  static const String loginFatto = 'Login fatto. Leggo…';

  /// Titolo pagina login.
  static String titoloLogin(String fornitore) => 'Login $fornitore';

  /// Spiegazione pagina login.
  static const String spiegaLogin =
      'Entra con email + codice. Google spesso non va qui. '
      'Fatto il login la pagina si chiude da sola.';

  /// Riga di controllo della pagina login (mai valori dei cookie).
  static String controlloLogin(
    String pagina,
    int cookie, {
    required bool sessione,
  }) => '$pagina · cookie: $cookie · sessione: ${sessione ? 'sì' : 'no'}';

  /// Tasto: ricarica la pagina.
  static const String ricarica = 'Ricarica';

  /// Tasto: torna alla pagina di login.
  static const String ricomincia = 'Ricomincia';

  /// Pagina login non caricata.
  static String loginErrore(String dettaglio) =>
      'Pagina non caricata ($dettaglio). Controlla internet, poi Ricarica.';

  /// Riga batteria.
  static String batteria(bool? libera) => switch (libera) {
    true => 'Batteria: senza limiti. Ok.',
    false => 'Batteria: limitata. Letture a app chiusa bloccate.',
    null => 'Batteria: stato sconosciuto.',
  };

  /// Passi batteria Samsung.
  static const String passiBatteria =
      'Apri Info app > Batteria > Senza limiti. Poi torna qui.';

  /// Tasto Info app.
  static const String apriInfoApp = 'Apri Info app';

  /// Spiegazione letture a app chiusa.
  static const String spiegaSfondo =
      'App chiusa: legge circa ogni 15 min (Android decide il momento).';

  /// Telefono: aiuto sotto il grafico.
  static const String aiutoZoom = 'Due dita: zoom · Tieni premuto: dettagli';

  /// Telefono: titoli corti delle carte.
  static const String cortoSess = '5 ORE';

  /// Telefono: titolo corto settimana.
  static const String cortoSett = 'SETT.';
}
