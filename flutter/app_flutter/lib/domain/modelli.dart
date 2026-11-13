// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
//
// Strato domain: modelli dei dati (lettura, evento, uso letto dal gestore).
import 'tempo.dart';

/// Id del gestore Anthropic (unico gestore nell'MVP).
const String gestoreAnthropic = 'anthropic';

/// Quale barra: settimanale o sessione 5 ore.
enum Campo {
  /// Barra settimanale.
  sett,

  /// Barra sessione 5 ore.
  sess,
}

/// Una lettura delle percentuali d'uso.
class Lettura {
  /// Crea una lettura.
  const Lettura({
    required this.ora,
    this.sett,
    this.sess,
    this.fonte = 'auto',
    this.alPc,
    this.lavoro = false,
    this.modelli = '',
    this.skill = '',
    this.gestore = gestoreAnthropic,
  });

  /// Ora della lettura (al minuto).
  final DateTime ora;

  /// % settimanale (0-100), null se mancante.
  final double? sett;

  /// % sessione 5 ore (0-100), null se mancante.
  final double? sess;

  /// Origine: auto | manuale | iniziale.
  final String fonte;

  /// Input tastiera/mouse nell'intervallo (null = non noto).
  final bool? alPc;

  /// Periodo di lavoro attivo al momento della lettura.
  final bool lavoro;

  /// Modelli accesi, nomi separati da '|'.
  final String modelli;

  /// Skill accese, nomi separati da '|'.
  final String skill;

  /// Gestore IA della lettura (es. 'anthropic').
  final String gestore;

  /// Valore della barra [campo].
  double? valore(Campo campo) => campo == Campo.sett ? sett : sess;
}

/// Tipo di evento salvato.
enum TipoEvento {
  /// Nota/marcatore scritto dall'utente.
  nota,

  /// Inizio lavoro.
  inizio,

  /// Fine lavoro.
  fine,

  /// Reset segnato.
  reset;

  /// Da testo ('nota', 'inizio'...) a tipo; sconosciuto -> null.
  static TipoEvento? daTesto(String s) {
    final String t = s.trim();
    for (final TipoEvento e in TipoEvento.values) {
      if (e.name == t) {
        return e;
      }
    }
    return null;
  }
}

/// Evento nel tempo (nota, inizio/fine lavoro, reset).
class Evento {
  /// Crea un evento.
  const Evento({required this.ora, required this.tipo, this.testo = ''});

  /// Ora dell'evento.
  final DateTime ora;

  /// Tipo di evento.
  final TipoEvento tipo;

  /// Testo libero (note).
  final String testo;
}

/// Uso letto da un gestore: due barre con % e ora di reset.
class Uso {
  /// Crea un uso.
  const Uso({this.sess, this.sett, this.resetSess, this.resetSett});

  /// % sessione 5 ore.
  final double? sess;

  /// % settimanale.
  final double? sett;

  /// Prossimo reset della sessione (ora locale).
  final DateTime? resetSess;

  /// Prossimo reset settimanale (ora locale).
  final DateTime? resetSett;

  /// Vero se manca tutto (nessuna percentuale).
  bool get vuoto => sess == null && sett == null;
}

/// Solo le letture del gestore [gestore], ordinate per ora.
List<Lettura> diGestore(Iterable<Lettura> letture, String gestore) =>
    ordinaPerOra(
      letture.where((Lettura l) => l.gestore == gestore),
      (Lettura l) => l.ora,
    );

/// Letture ordinate per ora (stabile).
List<Lettura> ordinaLetture(Iterable<Lettura> letture) =>
    ordinaPerOra(letture, (Lettura l) => l.ora);

/// Eventi ordinati per ora (stabile).
List<Evento> ordinaEventi(Iterable<Evento> eventi) =>
    ordinaPerOra(eventi, (Evento e) => e.ora);
