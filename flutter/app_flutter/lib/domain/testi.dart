// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
//
// Strato domain: numeri in formato italiano e testi fissi della logica.
// Tutti i testi qui: nel Blocco 3 passano nel file traduzioni.

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

/// Testi fissi (italiano).
abstract final class Testi {
  /// Combinazione senza modelli né skill.
  static const String nonSegnato = '(non segnato)';

  /// Nessun modello acceso.
  static const String nessunModello = 'nessun modello';

  /// Spunta "Conta solo lavoro" ma nessun periodo.
  static const String nessunLavoro = '(nessun periodo lavoro: conta tutto)';

  /// Filtro attivo.
  static const String soloLavoro = '(solo lavoro)';

  /// Riquadro dati senza letture settimanali.
  static const String nessunDato = 'Nessun dato settimanale: aspetta una lettura.';

  /// Poco consumo nel periodo.
  static const String datoDebole = 'Dato debole: aspetta.';

  /// Classifica vuota.
  static const String classificaVuota = 'Classifica modelli: ancora nessun dato.';

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
      'Ore di letture vere dietro ai due ritmi. Poche ore = numero poco affidabile.';

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
      'Passa il mouse su ogni numero per la spiegazione.';

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
}
