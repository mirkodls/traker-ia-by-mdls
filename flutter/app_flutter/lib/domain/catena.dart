// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
//
// Strato domain: catena di lettori con riserve e avviso dopo 2 giri falliti.
// I lettori veri (estensione, Claude Code, cookie...) stanno in lib/data.
import 'modelli.dart';

/// Errore di un lettore (messaggio senza segreti).
class ErroreLettura implements Exception {
  /// Crea l'errore.
  const ErroreLettura(this.messaggio, {this.loginScaduto = false});

  /// Messaggio da mostrare.
  final String messaggio;

  /// Vero se il sito ha rifiutato l'accesso (401/403): rifare il login.
  final bool loginScaduto;

  @override
  String toString() => messaggio;
}

/// Un modo di leggere l'uso di un gestore (interfaccia; le versioni vere
/// stanno in lib/data).
abstract interface class LettoreUso {
  /// Id ('estensione', 'claude_code', 'cookie'...).
  String get id;

  /// Nome mostrato.
  String get nome;

  /// Gestore letto (es. 'anthropic').
  String get gestore;

  /// Legge l'uso. Errore -> ErroreLettura.
  Future<Uso> leggi();
}

/// Metodo "auto": tutti i lettori disponibili in ordine.
const String metodoAuto = 'auto';

/// Metodo "manuale": nessuna lettura automatica.
const String metodoManuale = 'manuale';

/// Lettori da provare per il [metodo] scelto, in ordine di [disponibili].
List<LettoreUso> scegliLettori(String metodo, List<LettoreUso> disponibili) {
  if (metodo == metodoManuale) {
    return <LettoreUso>[];
  }
  if (metodo == metodoAuto) {
    return List<LettoreUso>.of(disponibili);
  }
  return disponibili.where((LettoreUso l) => l.id == metodo).toList();
}

/// Risultato della catena: uso letto e id del lettore che ha risposto.
class RisultatoCatena {
  /// Crea il risultato.
  const RisultatoCatena(this.uso, this.lettore);

  /// Uso letto.
  final Uso uso;

  /// Id del lettore che ha risposto.
  final String lettore;
}

/// Prova i [lettori] in ordine: il primo che risponde con almeno una %
/// vince. Se cadono tutti: un solo ErroreLettura con tutti i motivi.
Future<RisultatoCatena> leggiCatena(List<LettoreUso> lettori) async {
  final List<String> errori = <String>[];
  bool scaduto = false;
  for (final LettoreUso l in lettori) {
    try {
      final Uso uso = await l.leggi();
      if (uso.vuoto) {
        errori.add('${l.nome}: risposta senza percentuali');
        continue;
      }
      return RisultatoCatena(uso, l.id);
    } on ErroreLettura catch (e) {
      errori.add('${l.nome}: ${e.messaggio}');
      scaduto = scaduto || e.loginScaduto;
    } on Object catch (e) {
      // Un lettore rotto non ferma la catena.
      errori.add('${l.nome}: errore ${e.runtimeType}');
    }
  }
  throw ErroreLettura(
    errori.isEmpty ? 'nessun metodo disponibile' : errori.join(' | '),
    loginScaduto: scaduto,
  );
}

/// Avviso a schermo dopo [soglia] giri falliti di fila: una volta sola,
/// fino al prossimo giro riuscito.
class AvvisoFallimenti {
  /// Crea il contatore.
  AvvisoFallimenti({this.soglia = 2});

  /// Giri falliti di fila che fanno scattare l'avviso.
  final int soglia;

  int _ko = 0;
  bool _mostrato = false;

  /// Giri falliti di fila.
  int get koDiFila => _ko;

  /// Giro riuscito: azzera.
  void ok() {
    _ko = 0;
    _mostrato = false;
  }

  /// Giro fallito. Vero = mostra l'avviso adesso.
  bool ko() {
    _ko++;
    if (_ko >= soglia && !_mostrato) {
      _mostrato = true;
      return true;
    }
    return false;
  }
}
