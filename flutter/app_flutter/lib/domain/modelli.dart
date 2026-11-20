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
    this.fable,
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

  /// % Fable (0-100) come mostrata da claude.ai, null se mancante
  /// (letture vecchie o riga Fable assente).
  final double? fable;

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

/// Uso letto da un gestore: due barre con % e ora di reset, più la %
/// Fable se c'è.
class Uso {
  /// Crea un uso.
  const Uso({
    this.sess,
    this.sett,
    this.fable,
    this.resetSess,
    this.resetSett,
    this.crediti,
  });

  /// % sessione 5 ore.
  final double? sess;

  /// % settimanale.
  final double? sett;

  /// % Fable (null = riga Fable assente).
  final double? fable;

  /// Prossimo reset della sessione (ora locale).
  final DateTime? resetSess;

  /// Prossimo reset settimanale (ora locale).
  final DateTime? resetSett;

  /// Crediti di utilizzo (null = non presenti nella risposta).
  final Crediti? crediti;

  /// Vero se manca tutto (nessuna percentuale).
  bool get vuoto => sess == null && sett == null;
}

/// Crediti di utilizzo di claude.ai (solo valore attuale, non storico).
class Crediti {
  /// Crea i crediti.
  const Crediti({
    required this.usati,
    required this.valuta,
    required this.attivi,
    this.limite,
  });

  /// Importo usato (es. 0.0).
  final double usati;

  /// Codice valuta (es. 'USD').
  final String valuta;

  /// Crediti attivati dall'utente.
  final bool attivi;

  /// Limite di spesa (null = nessun limite).
  final double? limite;
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
