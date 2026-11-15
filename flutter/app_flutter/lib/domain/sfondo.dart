// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
//
// Strato domain: regole delle letture automatiche (anche a app chiusa sul
// telefono) e metodi di lettura per piattaforma.
import 'catena.dart';
import 'modelli.dart';
import 'preferenze.dart';
import 'tempo.dart';

/// Android non fa lavori in sottofondo più spesso di 15 minuti.
const int minutiMinimiSfondo = 15;

/// Minuti tra due letture in sottofondo (mai sotto 15).
int minutiSfondo(int minuti) =>
    minuti < minutiMinimiSfondo ? minutiMinimiSfondo : minuti;

/// Tutti i metodi, in ordine di menu.
const List<String> tuttiMetodi = <String>[
  metodoAuto,
  'estensione',
  'claude_code',
  'cookie',
  metodoManuale,
];

/// Metodi usabili qui: sul telefono niente estensione e Claude Code.
List<String> metodiDisponibili({required bool telefono}) => telefono
    ? <String>[metodoAuto, 'cookie', metodoManuale]
    : List<String>.of(tuttiMetodi);

/// [metodo] se usabile qui, altrimenti automatico.
String metodoValido(String metodo, {required bool telefono}) =>
    metodiDisponibili(telefono: telefono).contains(metodo)
    ? metodo
    : metodoAuto;

/// Lettura automatica da salvare: % lette + lavoro/modelli/skill di adesso.
Lettura letturaAutomatica(
  Uso uso,
  DateTime ora,
  Preferenze pref,
  Iterable<Evento> eventi, {
  String gestore = gestoreAnthropic,
}) => Lettura(
  ora: alMinuto(ora),
  sett: uso.sett,
  sess: uso.sess,
  lavoro: lavoroAperto(eventi),
  modelli: pref.attiviTesto(Gruppo.modelli),
  skill: pref.attiviTesto(Gruppo.skill),
  gestore: gestore,
);

/// Vero se, tornando nell'app, serve leggere subito: nessuna lettura
/// automatica o l'ultima è più vecchia di [minuti].
bool serveLetturaAlRitorno(
  Iterable<Lettura> letture,
  DateTime ora,
  int minuti,
) {
  DateTime? ultima;
  for (final Lettura l in letture) {
    if (l.fonte != 'manuale' && (ultima == null || l.ora.isAfter(ultima))) {
      ultima = l.ora;
    }
  }
  return ultima == null || ora.difference(ultima) >= Duration(minutes: minuti);
}

/// Lettura a app chiusa da accendere: login fatto, non "solo manuale" e
/// interruttore Sottofondo acceso.
bool sfondoDaAccendere(Preferenze pref, {required bool login}) =>
    login && pref.metodo != metodoManuale && pref.sfondoAcceso;

/// Pagine dei permessi del telefono (solo batteria: l'app non usa
/// notifiche né allarmi).
abstract final class Permesso {
  /// Popup di Android "senza limiti di batteria".
  static const String batteria = 'batteria';

  /// Pagina batteria di questa app (Senza limitazioni).
  static const String paginaBatteria = 'paginaBatteria';

  /// Samsung: Batteria > App mai in sospensione.
  static const String samsung = 'samsung';

  /// Info app (se le altre pagine mancano su questo telefono).
  static const String infoApp = 'infoApp';
}

/// Vero se aprire la pagina permessi: primo avvio sul telefono, oppure
/// Sottofondo appena acceso con batteria limitata.
bool chiediPermessi({
  required bool primaVolta,
  required bool sfondoAcceso,
  required bool? batteriaLibera,
}) => primaVolta || (sfondoAcceso && batteriaLibera == false);
