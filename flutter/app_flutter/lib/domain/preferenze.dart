// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
//
// Strato domain: preferenze dell'utente (salvate come testo nelle
// impostazioni), elenchi modelli/skill modificabili, stato lavoro.
import 'dart:convert';

import 'catena.dart';
import 'combinazioni.dart';
import 'intensita.dart';
import 'modelli.dart';
import 'periodo.dart';
import 'piani_progetti.dart';
import 'resoconto_ia.dart';
import 'stile_linee.dart';

/// Chiavi delle impostazioni (mai segreti: quelli vanno in cassaforte).
abstract final class Chiavi {
  /// Minuti tra due letture.
  static const String minuti = 'minuti';

  /// Metodo di lettura.
  static const String metodo = 'metodo';

  /// Elenco modelli (JSON).
  static const String modelli = 'modelli';

  /// Elenco skill (JSON).
  static const String skill = 'skill';

  /// Modelli accesi (JSON).
  static const String modelliAttivi = 'modelli_attivi';

  /// Skill accese (JSON).
  static const String skillAttive = 'skill_attive';

  /// Scatto del cursore periodo.
  static const String periodo = 'periodo';

  /// Spunta "Conta solo lavoro".
  static const String soloLavoro = 'solo_lavoro';

  /// Stato della vista (JSON).
  static const String vista = 'vista';

  /// Import vecchi dati già tentato ('1').
  static const String importFatto = 'import_python_fatto';

  /// Cartella dei vecchi dati Python.
  static const String cartellaImport = 'cartella_import';

  /// Avvio con Windows già deciso una volta ('1'): da lì decide l'utente.
  static const String avvioDeciso = 'avvio_windows_deciso';

  /// '1' = una lettura in sottofondo ha trovato il login scaduto.
  static const String loginScaduto = 'login_scaduto';

  /// V2: '1' = modelli/skill accesi (tasti, raccolta, confronti).
  /// Spento di base: le colonne e i dati vecchi restano intatti.
  static const String v2ModelliSkill = 'v2_modelli_skill';

  /// V2: '1' = funzioni lavoro V2 accese (piani, linee). Acceso di base.
  static const String v2Lavoro = 'v2_lavoro';

  /// V2: giorni di lavoro del piano (maschera 1-127, bit0 = lunedì).
  static const String v2PianoGiorni = 'v2_piano_giorni';

  /// V2: '1' = linea ideale del piano visibile nel grafico.
  static const String v2LineaIdeale = 'v2_linea_ideale';

  /// V2: '1' = linea adattiva del piano visibile nel grafico.
  static const String v2LineaAdattiva = 'v2_linea_adattiva';

  /// V2: finestra (minuti: 30/60/120) dell'intensità postuma settimanale.
  static const String v2FinestraPostuma = 'v2_finestra_postuma';

  /// V2: '1' = la linea Settimana diventa rossa vicino alla soglia del
  /// giorno. Acceso di base.
  static const String v2RossoAcceso = 'v2_rosso_acceso';

  /// V2: % della soglia del giorno oltre cui la linea Settimana è rossa
  /// (50-100, base 95).
  static const String v2SogliaRosso = 'v2_soglia_rosso';
  /// Telefono: letture a app chiusa accese ('1') o spente ('0').
  static const String sfondoAcceso = 'sfondo_acceso';

  /// Telefono: minuti tra due letture a app chiusa (15/30/60).
  static const String minutiSfondo = 'minuti_sfondo';

  /// Telefono: pagina permessi già mostrata al primo avvio ('1').
  static const String permessiChiesti = 'permessi_chiesti';

  /// Tutte le chiavi lette all'avvio.
  static final List<String> tutte = <String>[
    for (final LineaGrafico l in LineaGrafico.values) ...<String>[
      l.chiaveAlfa,
      l.chiaveSpessore,
      l.chiaveColore,
    ],
    v2RossoAcceso,
    v2SogliaRosso,
    ...chiaviIA,
    loginScaduto,
    v2ModelliSkill,
    v2Lavoro,
    v2PianoGiorni,
    v2LineaIdeale,
    v2LineaAdattiva,
    v2FinestraPostuma,
    minuti,
    metodo,
    modelli,
    skill,
    modelliAttivi,
    skillAttive,
    periodo,
    soloLavoro,
    vista,
    importFatto,
    cartellaImport,
    avvioDeciso,
    sfondoAcceso,
    minutiSfondo,
    permessiChiesti,
  ];
}

/// Gruppo di tasti.
enum Gruppo {
  /// Modelli (a destra).
  modelli,

  /// Skill (a sinistra).
  skill,
}

/// Modelli all'inizio.
const List<String> modelliIniziali = <String>[
  'Opus',
  'Sonnet',
  'Fable',
  'Haiku',
];

/// Minuti predefiniti tra due letture.
const int minutiPredefiniti = 10;

/// Telefono: scelte di minuti per le letture a app chiusa (meno spesso =
/// meno batteria). Android non va sotto 15.
const List<int> sceltaMinutiSfondo = <int>[15, 30, 60];

/// Telefono: minuti predefiniti a app chiusa (obiettivo ~1% batteria/24h).
const int minutiSfondoPredefiniti = 30;

/// [m] se è una scelta valida, altrimenti il predefinito.
int normalizzaMinutiSfondo(int? m) =>
    sceltaMinutiSfondo.contains(m) ? m! : minutiSfondoPredefiniti;

/// Lunghezza massima di un nome tasto.
const int maxNome = 20;

List<String> _lista(String? json, List<String> pred) {
  if (json == null) {
    return pred;
  }
  try {
    final Object? v = jsonDecode(json);
    if (v is List<Object?>) {
      return List<String>.unmodifiable(<String>[
        for (final Object? x in v)
          if (x is String && x.trim().isNotEmpty) x.trim(),
      ]);
    }
  } on FormatException {
    // testo rotto: valore predefinito
  }
  return pred;
}

/// Maschera giorni valida: ristretta ai 7 bit; 0 (nessun giorno) -> tutti.
int _maschera(int m) {
  final int v = m & tuttiIGiorni;
  return v == 0 ? tuttiIGiorni : v;
}

/// Preferenze (immutabili).
class Preferenze {
  /// Crea le preferenze.
  Preferenze({
    this.minuti = minutiPredefiniti,
    this.metodo = metodoAuto,
    List<String> modelli = modelliIniziali,
    List<String> skill = const <String>[],
    List<String> modelliAttivi = const <String>[],
    List<String> skillAttive = const <String>[],
    this.periodo = scattoPredefinito,
    this.soloLavoro = false,
    this.modelliSkill = false,
    this.lavoroV2 = true,
    int giorniPiano = tuttiIGiorni,
    this.lineaIdeale = true,
    this.lineaAdattiva = true,
    int finestraPostuma = finestraPostumaPredefinita,
    this.stileLinee = const StileLinee(),
    this.rossoAcceso = true,
    int sogliaRosso = sogliaRossoPredefinita,
    ConfigIA? ia,
    this.sfondoAcceso = true,
    this.minutiSfondo = minutiSfondoPredefiniti,
  }) : ia = ia ?? ConfigIA(),
       sogliaRosso = sogliaRossoValida(sogliaRosso),
       finestraPostuma = finestraPostumaValida(finestraPostuma),
       giorniPiano = _maschera(giorniPiano),
       modelli = List<String>.unmodifiable(modelli),
       skill = List<String>.unmodifiable(skill),
       modelliAttivi = List<String>.unmodifiable(modelliAttivi),
       skillAttive = List<String>.unmodifiable(skillAttive);

  /// Da impostazioni salvate (chiave -> testo). Valori rotti -> predefiniti.
  factory Preferenze.daMappa(Map<String, String?> m) {
    final int? min = int.tryParse(m[Chiavi.minuti] ?? '');
    final String met = (m[Chiavi.metodo] ?? '').trim();
    return Preferenze(
      minuti: min != null && min >= 1 && min <= 120 ? min : minutiPredefiniti,
      metodo: met.isEmpty ? metodoAuto : met,
      modelli: _lista(m[Chiavi.modelli], modelliIniziali),
      skill: _lista(m[Chiavi.skill], const <String>[]),
      modelliAttivi: _lista(m[Chiavi.modelliAttivi], const <String>[]),
      skillAttive: _lista(m[Chiavi.skillAttive], const <String>[]),
      periodo: normalizzaScatto(int.tryParse(m[Chiavi.periodo] ?? '')),
      soloLavoro: m[Chiavi.soloLavoro] == '1',
      modelliSkill: m[Chiavi.v2ModelliSkill] == '1',
      lavoroV2: m[Chiavi.v2Lavoro] != '0',
      giorniPiano: int.tryParse(m[Chiavi.v2PianoGiorni] ?? '') ?? tuttiIGiorni,
      lineaIdeale: m[Chiavi.v2LineaIdeale] != '0',
      lineaAdattiva: m[Chiavi.v2LineaAdattiva] != '0',
      finestraPostuma: finestraPostumaValida(
        int.tryParse(m[Chiavi.v2FinestraPostuma] ?? ''),
      ),
      stileLinee: StileLinee.daMappa(m),
      rossoAcceso: m[Chiavi.v2RossoAcceso] != '0',
      ia: ConfigIA.daMappa(m),
      sogliaRosso: sogliaRossoValida(
        int.tryParse((m[Chiavi.v2SogliaRosso] ?? '').trim()),
      ),
      sfondoAcceso: m[Chiavi.sfondoAcceso] != '0',
      minutiSfondo: normalizzaMinutiSfondo(
        int.tryParse(m[Chiavi.minutiSfondo] ?? ''),
      ),
    );
  }

  /// Minuti tra due letture (1-120).
  final int minuti;

  /// Metodo di lettura (auto, estensione, claude_code, cookie, manuale).
  final String metodo;

  /// Elenco modelli, in ordine.
  final List<String> modelli;

  /// Elenco skill, in ordine.
  final List<String> skill;

  /// Modelli accesi.
  final List<String> modelliAttivi;

  /// Skill accese.
  final List<String> skillAttive;

  /// Scatto del cursore periodo.
  final int periodo;

  /// Spunta "Conta solo lavoro".
  final bool soloLavoro;

  /// V2: modelli/skill accesi (tasti, raccolta, confronti). Base: spento.
  final bool modelliSkill;

  /// V2: funzioni lavoro V2 accese. Base: acceso.
  final bool lavoroV2;

  /// V2: giorni di lavoro del piano (maschera, mai 0: almeno 1 giorno).
  final int giorniPiano;

  /// V2: linea ideale visibile. Base: acceso.
  final bool lineaIdeale;

  /// V2: linea adattiva visibile. Base: acceso.
  final bool lineaAdattiva;

  /// V2: finestra (minuti) dell'intensità postuma settimanale (30/60/120).
  final int finestraPostuma;

  /// V2: trasparenza e spessore di ogni linea dei grafici.
  final StileLinee stileLinee;

  /// V2: linea Settimana rossa vicino alla soglia del giorno. Base: acceso.
  final bool rossoAcceso;

  /// V2: % della soglia del giorno da cui la linea Settimana è rossa
  /// (50-100). Base 95.
  final int sogliaRosso;

  /// V2: fornitore, modello e URL del resoconto IA (MAI la chiave API:
  /// quella sta in cassaforte).
  final ConfigIA ia;
  /// Telefono: letture a app chiusa accese (interruttore).
  final bool sfondoAcceso;

  /// Telefono: minuti tra due letture a app chiusa (15/30/60).
  final int minutiSfondo;

  /// Preferenze -> impostazioni da salvare.
  Map<String, String> aMappa() => <String, String>{
    ...ia.aMappa(),
    ...stileLinee.aMappa(),
    Chiavi.v2RossoAcceso: rossoAcceso ? '1' : '0',
    Chiavi.v2SogliaRosso: '$sogliaRosso',
    Chiavi.minuti: '$minuti',
    Chiavi.metodo: metodo,
    Chiavi.modelli: jsonEncode(modelli),
    Chiavi.skill: jsonEncode(skill),
    Chiavi.modelliAttivi: jsonEncode(modelliAttivi),
    Chiavi.skillAttive: jsonEncode(skillAttive),
    Chiavi.periodo: '$periodo',
    Chiavi.soloLavoro: soloLavoro ? '1' : '0',
    Chiavi.v2ModelliSkill: modelliSkill ? '1' : '0',
    Chiavi.v2Lavoro: lavoroV2 ? '1' : '0',
    Chiavi.v2PianoGiorni: '$giorniPiano',
    Chiavi.v2LineaIdeale: lineaIdeale ? '1' : '0',
    Chiavi.v2LineaAdattiva: lineaAdattiva ? '1' : '0',
    Chiavi.v2FinestraPostuma: '$finestraPostuma',
    Chiavi.sfondoAcceso: sfondoAcceso ? '1' : '0',
    Chiavi.minutiSfondo: '$minutiSfondo',
  };

  /// Copia con alcuni valori cambiati.
  Preferenze copia({
    int? minuti,
    String? metodo,
    List<String>? modelli,
    List<String>? skill,
    List<String>? modelliAttivi,
    List<String>? skillAttive,
    int? periodo,
    bool? soloLavoro,
    bool? modelliSkill,
    bool? lavoroV2,
    int? giorniPiano,
    bool? lineaIdeale,
    bool? lineaAdattiva,
    int? finestraPostuma,
    StileLinee? stileLinee,
    bool? rossoAcceso,
    int? sogliaRosso,
    ConfigIA? ia,
    bool? sfondoAcceso,
    int? minutiSfondo,
  }) => Preferenze(
    minuti: minuti ?? this.minuti,
    metodo: metodo ?? this.metodo,
    modelli: modelli ?? this.modelli,
    skill: skill ?? this.skill,
    modelliAttivi: modelliAttivi ?? this.modelliAttivi,
    skillAttive: skillAttive ?? this.skillAttive,
    periodo: periodo ?? this.periodo,
    soloLavoro: soloLavoro ?? this.soloLavoro,
    modelliSkill: modelliSkill ?? this.modelliSkill,
    lavoroV2: lavoroV2 ?? this.lavoroV2,
    giorniPiano: giorniPiano ?? this.giorniPiano,
    lineaIdeale: lineaIdeale ?? this.lineaIdeale,
    lineaAdattiva: lineaAdattiva ?? this.lineaAdattiva,
    finestraPostuma: finestraPostuma ?? this.finestraPostuma,
    stileLinee: stileLinee ?? this.stileLinee,
    rossoAcceso: rossoAcceso ?? this.rossoAcceso,
    sogliaRosso: sogliaRosso ?? this.sogliaRosso,
    ia: ia ?? this.ia,
    sfondoAcceso: sfondoAcceso ?? this.sfondoAcceso,
    minutiSfondo: normalizzaMinutiSfondo(minutiSfondo ?? this.minutiSfondo),
  );

  /// Accende/spegne il giorno [g] (1 = lunedì ... 7 = domenica) del piano.
  /// L'ultimo giorno acceso non si spegne (serve almeno 1 giorno).
  Preferenze toccaGiorno(int g) {
    if (g < DateTime.monday || g > DateTime.sunday) {
      return this;
    }
    final int m = giorniPiano ^ (1 << (g - 1));
    return m == 0 ? this : copia(giorniPiano: m);
  }

  /// Elenco del gruppo [g].
  List<String> elenco(Gruppo g) => g == Gruppo.modelli ? modelli : skill;

  /// Accesi del gruppo [g].
  List<String> accesi(Gruppo g) =>
      g == Gruppo.modelli ? modelliAttivi : skillAttive;

  Preferenze _conGruppo(Gruppo g, List<String> elenco, List<String> accesi) =>
      g == Gruppo.modelli
      ? copia(modelli: elenco, modelliAttivi: accesi)
      : copia(skill: elenco, skillAttive: accesi);

  /// Accesi del gruppo [g] ancora in elenco, normalizzati 'A|B'.
  String attiviTesto(Gruppo g) {
    final Set<String> el = elenco(g).toSet();
    return unisci(accesi(g).where(el.contains));
  }

  /// Testo da salvare nella lettura per il gruppo [g]: vuoto se
  /// modelli/skill sono spenti (V2), altrimenti [attiviTesto].
  String daRaccogliere(Gruppo g) => modelliSkill ? attiviTesto(g) : '';

  /// Accende/spegne il tasto [nome].
  Preferenze tocca(Gruppo g, String nome) {
    final List<String> acc = List<String>.of(accesi(g));
    if (!acc.remove(nome)) {
      acc.add(nome);
    }
    return _conGruppo(g, elenco(g), acc);
  }

  /// Nuovo ordine del gruppo (stessi nomi).
  Preferenze riordina(Gruppo g, List<String> ordine) =>
      _conGruppo(g, ordine, accesi(g));

  /// Errore del nome (null = valido). [vecchio] = nome che si rinomina.
  String? erroreNome(Gruppo g, String nome, {String? vecchio}) {
    final String n = nome.trim();
    if (n.isEmpty ||
        n.length > maxNome ||
        n.contains('|') ||
        n.contains(';') ||
        n.contains('\n')) {
      return 'non valido';
    }
    final bool doppio = elenco(g)
        .any((String x) => x.toLowerCase() == n.toLowerCase() && x != vecchio);
    return doppio ? 'doppio' : null;
  }

  /// Aggiunge un nome (se valido).
  Preferenze aggiungi(Gruppo g, String nome) => erroreNome(g, nome) != null
      ? this
      : _conGruppo(g, <String>[...elenco(g), nome.trim()], accesi(g));

  /// Rinomina [vecchio] in [nuovo] (anche tra gli accesi). Vale da ora.
  Preferenze rinomina(Gruppo g, String vecchio, String nuovo) {
    final String n = nuovo.trim();
    if (!elenco(g).contains(vecchio) ||
        n == vecchio ||
        erroreNome(g, n, vecchio: vecchio) != null) {
      return this;
    }
    String sost(String x) => x == vecchio ? n : x;
    return _conGruppo(
      g,
      elenco(g).map(sost).toList(),
      accesi(g).map(sost).toList(),
    );
  }

  /// Toglie un nome (anche dagli accesi).
  Preferenze togli(Gruppo g, String nome) => _conGruppo(
    g,
    elenco(g).where((String x) => x != nome).toList(),
    accesi(g).where((String x) => x != nome).toList(),
  );
}

/// Vero se l'ultimo inizio/fine lavoro è un "inizio" (lavoro in corso).
bool lavoroAperto(Iterable<Evento> eventi) {
  Evento? ult;
  for (final Evento e in ordinaEventi(eventi)) {
    if (e.tipo == TipoEvento.inizio || e.tipo == TipoEvento.fine) {
      ult = e;
    }
  }
  return ult?.tipo == TipoEvento.inizio;
}

/// Percentuale scritta a mano: '21,5' / '21.5%' -> 21.5; vuoto -> null.
/// Testo sbagliato o fuori 0-100 -> FormatException.
double? percentoUtente(String s) {
  final String t = s.replaceAll('%', '').replaceAll(',', '.').trim();
  if (t.isEmpty) {
    return null;
  }
  final double v = double.parse(t);
  if (v.isNaN || v < 0 || v > 100) {
    throw const FormatException('fuori 0-100');
  }
  return v;
}
