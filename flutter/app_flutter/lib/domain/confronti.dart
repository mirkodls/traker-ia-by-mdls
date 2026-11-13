// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
//
// Strato domain: carta CONFRONTI (nota prima/dopo, combinazioni A/B),
// spunta "Conta solo lavoro" e testi di spiegazione.
import 'analisi.dart';
import 'combinazioni.dart';
import 'coppie.dart';
import 'modelli.dart';
import 'tempo.dart';
import 'testi.dart';

/// Effetto della spunta "Conta solo lavoro".
enum FiltroLavoro {
  /// Spunta spenta.
  nessuno,

  /// Contate solo le ore di lavoro.
  lavoro,

  /// Spunta accesa ma un lato senza lavoro: conta tutto.
  tutto,
}

/// Testo del filtro ('' se spunta spenta).
String testoFiltro(FiltroLavoro f) => switch (f) {
  FiltroLavoro.nessuno => '',
  FiltroLavoro.lavoro => Testi.soloLavoro,
  FiltroLavoro.tutto => Testi.nessunLavoro,
};

/// Confronto prima/dopo una nota.
class ConfrontoNota {
  /// Crea il confronto.
  const ConfrontoNota({
    required this.orePrima,
    required this.oreDopo,
    required this.verdetto,
    required this.da,
    required this.nota,
    this.prima,
    this.dopo,
    this.filtro = FiltroLavoro.nessuno,
  });

  /// Ore contate prima.
  final double orePrima;

  /// Ore contate dopo.
  final double oreDopo;

  /// Verdetto ±10%.
  final Verdetto verdetto;

  /// Inizio del "prima" (reset settimanale).
  final DateTime da;

  /// Ora della nota.
  final DateTime nota;

  /// pt%/h prima.
  final double? prima;

  /// pt%/h dopo.
  final double? dopo;

  /// Effetto della spunta "Conta solo lavoro".
  final FiltroLavoro filtro;
}

/// Prima = da reset settimanale alla nota; dopo = dalla nota a oggi.
/// [periodi] = conta solo lavoro; se prima o dopo non ne ha: conta tutto.
ConfrontoNota confrontoNota(
  Iterable<Lettura> letture,
  DateTime marcatore, {
  Campo campo = Campo.sett,
  List<Periodo>? periodi,
}) {
  final DateTime ini = inizioSettimana(marcatore);
  List<Periodo>? usa;
  FiltroLavoro filtro = FiltroLavoro.nessuno;
  if (periodi != null) {
    final double hp =
        ritmoOre(letture, campo, da: ini, a: marcatore, periodi: periodi).ore;
    final double hd =
        ritmoOre(letture, campo, da: marcatore, periodi: periodi).ore;
    if (hp <= 0 || hd <= 0) {
      filtro = FiltroLavoro.tutto;
    } else {
      usa = periodi;
      filtro = FiltroLavoro.lavoro;
    }
  }
  final RitmoOre p = ritmoOre(letture, campo, da: ini, a: marcatore, periodi: usa);
  final RitmoOre d = ritmoOre(letture, campo, da: marcatore, periodi: usa);
  return ConfrontoNota(
    orePrima: p.ore,
    oreDopo: d.ore,
    verdetto: verdetto(p.ritmo, d.ritmo),
    da: ini,
    nota: marcatore,
    prima: p.ritmo,
    dopo: d.ritmo,
    filtro: filtro,
  );
}

/// '(2,0 h prima / 3,5 h dopo)'.
String testoOreNota(ConfrontoNota c) =>
    '(${testoOre(c.orePrima)} prima / ${testoOre(c.oreDopo)} dopo)';

/// '(B solo 0,1 h)' / '(manca un dato)'. Vuoto se entrambe >= 1 h.
String motivoDebole(double? oreA, double? oreB) {
  if (oreA == null || oreB == null) {
    return '(manca un dato)';
  }
  final List<String> corti = <String>[
    if (oreA < oreMinime) 'A solo ${testoOre(oreA)}',
    if (oreB < oreMinime) 'B solo ${testoOre(oreB)}',
  ];
  return corti.isEmpty ? '' : '(${corti.join(', ')})';
}

/// Confronto tra due combinazioni.
class ConfrontoCombo {
  /// Crea il confronto.
  const ConfrontoCombo({
    required this.verdetto,
    required this.motivo,
    this.a,
    this.b,
    this.filtro = FiltroLavoro.nessuno,
  });

  /// Verdetto (B rispetto ad A).
  final Verdetto verdetto;

  /// Motivo del dato debole (vuoto se non debole).
  final String motivo;

  /// pt%/h di A.
  final double? a;

  /// pt%/h di B.
  final double? b;

  /// Effetto della spunta "Conta solo lavoro".
  final FiltroLavoro filtro;
}

/// [tab] = tutte le ore; [tabLavoro] = solo lavoro (spunta accesa).
/// Se A o B non ha ore di lavoro: usa [tab] (conta tutto).
ConfrontoCombo confrontoCombinazioni(
  Map<Combo, RitmoCombo> tab,
  Combo ka,
  Combo kb, {
  Campo campo = Campo.sett,
  Map<Combo, RitmoCombo>? tabLavoro,
}) {
  Map<Combo, RitmoCombo> usa = tab;
  FiltroLavoro filtro = FiltroLavoro.nessuno;
  if (tabLavoro != null) {
    final double ha = tabLavoro[ka]?.ore ?? 0;
    final double hb = tabLavoro[kb]?.ore ?? 0;
    if (ha <= 0 || hb <= 0) {
      filtro = FiltroLavoro.tutto;
    } else {
      usa = tabLavoro;
      filtro = FiltroLavoro.lavoro;
    }
  }
  final RitmoCombo? ra = usa[ka];
  final RitmoCombo? rb = usa[kb];
  final Verdetto v = confronta(ra, rb, campo: campo);
  return ConfrontoCombo(
    verdetto: v,
    motivo: v == Verdetto.datoDebole ? motivoDebole(ra?.ore, rb?.ore) : '',
    a: ra?.valore(campo),
    b: rb?.valore(campo),
    filtro: filtro,
  );
}

/// Primo e ultimo istante degli intervalli della combinazione [k].
Periodo? periodoCombo(
  Iterable<Lettura> letture,
  Combo k, {
  Campo campo = Campo.sett,
}) {
  DateTime? ini;
  DateTime? fin;
  for (final Coppia c in coppie(letture, campo)) {
    if (comboDi(c.arrivo) != k) {
      continue;
    }
    ini = ini == null ? c.partenza.ora : piuPresto(ini, c.partenza.ora);
    fin = fin == null ? c.arrivo.ora : piuTardi(fin, c.arrivo.ora);
  }
  return ini == null || fin == null ? null : (inizio: ini, fine: fin);
}

/// 'Classifica modelli (dal più vorace): Opus 0,87 (2,0 h)  ·  ...'.
String testoClassifica(List<VoceClassifica> cl) {
  if (cl.isEmpty) {
    return Testi.classificaVuota;
  }
  final String voci = cl
      .map((VoceClassifica v) => '${v.modello} ${numero(v.ritmo)} (${testoOre(v.ore)})')
      .join('  ·  ');
  return 'Classifica modelli (dal più vorace): $voci';
}

/// Riga al PC / automatico.
String testoPresenza(double? pc, double? auto) =>
    'Al PC ${numero(pc)}  ·  automatico ${numero(auto)}  pt%/h sett '
    '(questa settimana)';

/// Spiegazione del numero "prima".
String spiegaPrima(ConfrontoNota c) =>
    'PRIMA della nota: ritmo medio da ${quandoData(c.da)} (reset settimana) '
    'a ${quandoData(c.nota)}.\n'
    'Ore di letture usate: ${testoOre(c.orePrima)} ${testoFiltro(c.filtro)}.'
    '\n\n${Testi.pth}';

/// Spiegazione del numero "dopo".
String spiegaDopo(ConfrontoNota c, DateTime fine) =>
    'DOPO la nota: ritmo medio da ${quandoData(c.nota)} a ${quandoData(fine)}.\n'
    'Ore di letture usate: ${testoOre(c.oreDopo)} ${testoFiltro(c.filtro)}.'
    '\n\n${Testi.pth}';

/// Spiegazione di una combinazione (A o B).
String spiegaCombo(String nome, Combo k, Periodo? periodo, double? ore) {
  final List<String> righe = <String>[
    '$nome = ${etichetta(k)}',
    if (ore != null) 'Ore di letture usate: ${testoOre(ore)}.',
    if (periodo != null)
      'Da ${quandoData(periodo.inizio)} a ${quandoData(periodo.fine)} '
          '(solo gli intervalli con questa combinazione).',
    if (k == comboVuota) ...<String>['', Testi.spiegaNonSegnato],
  ];
  return '${righe.join('\n')}\n\n${Testi.pth}\n${Testi.sett}';
}

/// Spiegazione del verdetto.
String spiegaVerdetto(Verdetto v) => Testi.spiegaVerdetto[v.etichetta] ?? '';
