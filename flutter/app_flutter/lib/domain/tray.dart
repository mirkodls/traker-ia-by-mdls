// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
//
// Strato domain: testo dell'icona vicino all'orologio (tray), mostrato
// passando il mouse: % sessione e settimana, intensità ultima ora e se è
// in salita o discesa rispetto al resto della sessione.
import 'analisi.dart';
import 'coppie.dart';
import 'info_app.dart';
import 'modelli.dart';
import 'traduzioni/testi_it.dart';

/// Durata di una sessione Anthropic.
const Duration durataSessione = Duration(hours: 5);

/// Finestra dell'intensità "ultima ora".
const Duration ultimaOra = Duration(hours: 1);

/// Ore minime di letture prima dell'ultima ora per dire salita/discesa.
const double oreMinimePrima = 0.5;

/// Windows taglia il testo del tray a 127 caratteri.
const int maxTestoTray = 127;

/// Inizio della sessione 5 ore in corso.
/// 1) [resetSess] noto e nel futuro -> reset - 5 h;
/// 2) sennò l'ultimo calo della barra sessione nelle ultime 5 h;
/// 3) sennò adesso - 5 h.
DateTime inizioSessione(
  Iterable<Lettura> letture,
  DateTime ora, {
  DateTime? resetSess,
}) {
  final DateTime minimo = ora.subtract(durataSessione);
  if (resetSess != null && resetSess.isAfter(ora)) {
    final DateTime i = resetSess.subtract(durataSessione);
    return i.isBefore(minimo) ? minimo : i;
  }
  final List<DateTime> cali = trovaReset(
    letture.where((Lettura l) => !l.ora.isAfter(ora)),
    Campo.sess,
  );
  if (cali.isNotEmpty && cali.last.isAfter(minimo)) {
    return cali.last;
  }
  return minimo;
}

/// Intensità ultima ora e confronto col resto della sessione.
typedef TendenzaOra = ({double? ultima, double? prima, Verdetto verdetto});

/// Intensità (pt%/h barra 5 ore) nell'ultima ora e nella parte di sessione
/// prima dell'ultima ora. Prima con meno di [oreMinimePrima] ore di letture
/// -> dato debole (niente freccia).
TendenzaOra tendenzaUltimaOra(
  Iterable<Lettura> letture,
  DateTime ora, {
  DateTime? resetSess,
}) {
  final DateTime ini = inizioSessione(letture, ora, resetSess: resetSess);
  final DateTime unaOraFa = ora.subtract(ultimaOra);
  final DateTime daUltima = unaOraFa.isBefore(ini) ? ini : unaOraFa;
  final double? ultima = ritmo(letture, Campo.sess, da: daUltima, a: ora);
  if (!unaOraFa.isAfter(ini)) {
    return (ultima: ultima, prima: null, verdetto: Verdetto.datoDebole);
  }
  final RitmoOre p = ritmoOre(letture, Campo.sess, da: ini, a: unaOraFa);
  final double? prima = p.ore >= oreMinimePrima ? p.ritmo : null;
  return (ultima: ultima, prima: prima, verdetto: verdetto(prima, ultima));
}

/// Ultimo valore non vuoto di [campo].
double? ultimoValore(Iterable<Lettura> letture, Campo campo) {
  double? v;
  for (final Lettura l in ordinaLetture(letture)) {
    v = l.valore(campo) ?? v;
  }
  return v;
}

/// Testo del tray (massimo [maxTestoTray] caratteri, righe con '\n').
String testoTray(
  Iterable<Lettura> letture,
  DateTime ora, {
  DateTime? resetSess,
}) {
  final List<Lettura> ls = letture
      .where((Lettura l) => !l.ora.isAfter(ora))
      .toList();
  final List<String> righe = <String>[nomeApp];
  if (ls.isEmpty) {
    righe.add(Testi.trayNessunaLettura);
  } else {
    righe.add(
      Testi.trayPercentuali(
        percento(ultimoValore(ls, Campo.sess)),
        percento(ultimoValore(ls, Campo.sett)),
      ),
    );
    final TendenzaOra t = tendenzaUltimaOra(ls, ora, resetSess: resetSess);
    righe.add(
      t.ultima == null
          ? Testi.trayOraVuota
          : Testi.trayUltimaOra(
              numero(t.ultima, dec: 1),
              Testi.trayTendenza[t.verdetto] ?? '',
              t.prima == null ? '' : numero(t.prima, dec: 1),
            ),
    );
  }
  final String s = righe.join('\n');
  return s.length <= maxTestoTray ? s : s.substring(0, maxTestoTray);
}
