// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
//
// Strato domain: vista della finestra (sezioni visibili/aperte, modo solo-X,
// primo piano) e disposizione delle barre di tasti che vanno a capo.

/// Sezioni, in ordine dall'alto.
enum Sezione {
  /// Carte numeri.
  carte,

  /// Grafico principale.
  grafico,

  /// Grafico intensità.
  intensita,

  /// Barra tasti.
  barra,

  /// Riquadro "Cosa dicono i dati".
  dati,

  /// Carta confronti.
  confronti,
}

/// Modo della finestra.
enum ModoVista {
  /// Tutte le sezioni scelte.
  tutto,

  /// Solo il grafico, grande.
  grafico,

  /// Solo l'intensità, grande.
  intensita,
}

/// Sezioni che prendono lo spazio libero, in quest'ordine.
const List<Sezione> espandibili = <Sezione>[Sezione.grafico, Sezione.intensita];

Map<Sezione, bool> _tutte(bool v) => Map<Sezione, bool>.unmodifiable(
  <Sezione, bool>{for (final Sezione s in Sezione.values) s: v},
);

/// Stato della vista (immutabile). Salvato in impostazioni alla chiave "vista".
class StatoVista {
  /// Crea uno stato.
  StatoVista({
    required Map<Sezione, bool> visibili,
    required Map<Sezione, bool> aperte,
    this.modo = ModoVista.tutto,
    this.primoPiano = false,
  }) : visibili = Map<Sezione, bool>.unmodifiable(visibili),
       aperte = Map<Sezione, bool>.unmodifiable(aperte);

  /// Tutto visibile e aperto.
  factory StatoVista.base() =>
      StatoVista(visibili: _tutte(true), aperte: _tutte(true));

  /// Da JSON (anche vuoto o rotto) a stato completo e valido.
  factory StatoVista.daJson(Object? raw) {
    final StatoVista b = StatoVista.base();
    if (raw is! Map<Object?, Object?>) {
      return b;
    }
    Map<Sezione, bool> leggi(String chiave, Map<Sezione, bool> pred) {
      final Object? d = raw[chiave];
      return <Sezione, bool>{
        for (final Sezione s in Sezione.values)
          s: d is Map<Object?, Object?> && d[s.name] is bool
              ? d[s.name] as bool
              : pred[s]!,
      };
    }

    ModoVista modo = ModoVista.tutto;
    for (final ModoVista m in ModoVista.values) {
      if (raw['modo'] == m.name) {
        modo = m;
      }
    }
    final Object? pp = raw['primo_piano'];
    return StatoVista(
      visibili: leggi('visibili', b.visibili),
      aperte: leggi('aperte', b.aperte),
      modo: modo,
      primoPiano: pp is bool && pp,
    );
  }

  /// Sezioni scelte nel menu Vista.
  final Map<Sezione, bool> visibili;

  /// Sezioni aperte (non chiuse col titolo).
  final Map<Sezione, bool> aperte;

  /// Modo attuale.
  final ModoVista modo;

  /// Sempre in primo piano (solo Windows).
  final bool primoPiano;

  /// Stato -> JSON.
  Map<String, Object> aJson() => <String, Object>{
    'visibili': <String, bool>{
      for (final Sezione s in Sezione.values) s.name: visibili[s]!,
    },
    'aperte': <String, bool>{
      for (final Sezione s in Sezione.values) s.name: aperte[s]!,
    },
    'modo': modo.name,
    'primo_piano': primoPiano,
  };

  Sezione get _sezioneModo => Sezione.values.byName(modo.name);

  /// Sezioni da disegnare, in ordine: (sezione, aperta).
  List<(Sezione, bool)> mostra() {
    if (modo != ModoVista.tutto) {
      return <(Sezione, bool)>[(_sezioneModo, true)];
    }
    return <(Sezione, bool)>[
      for (final Sezione s in Sezione.values)
        if (visibili[s]!) (s, aperte[s]!),
    ];
  }

  /// Nei modi solo-X niente titoli.
  bool get conTitoli => modo == ModoVista.tutto;

  /// Sezione che prende lo spazio libero (null = nessuna).
  Sezione? chiEspande() {
    final Set<Sezione> ap = <Sezione>{
      for (final (Sezione, bool) x in mostra())
        if (x.$2) x.$1,
    };
    for (final Sezione s in espandibili) {
      if (ap.contains(s)) {
        return s;
      }
    }
    return null;
  }

  /// Spunta nel menu Vista = sezione che si vede ora.
  bool spuntata(Sezione s) =>
      mostra().any(((Sezione, bool) x) => x.$1 == s);

  /// Accende/spegne una sezione nel menu Vista.
  StatoVista cambiaVisibile(Sezione s) {
    final Map<Sezione, bool> vis = Map<Sezione, bool>.of(visibili);
    final Map<Sezione, bool> ap = Map<Sezione, bool>.of(aperte);
    if (modo != ModoVista.tutto) {
      // Da solo-X: si riparte da quello che si vede.
      for (final Sezione x in Sezione.values) {
        vis[x] = x == _sezioneModo;
      }
      ap[_sezioneModo] = true;
    }
    vis[s] = !vis[s]!;
    if (vis[s]!) {
      ap[s] = true;
    }
    return StatoVista(visibili: vis, aperte: ap, primoPiano: primoPiano);
  }

  /// Apre/chiude una sezione (clic sul titolo).
  StatoVista cambiaAperta(Sezione s) {
    final Map<Sezione, bool> ap = Map<Sezione, bool>.of(aperte);
    ap[s] = !ap[s]!;
    return StatoVista(
      visibili: visibili,
      aperte: ap,
      modo: modo,
      primoPiano: primoPiano,
    );
  }

  /// Sceglie il modo. "tutto" rimette tutto visibile e aperto.
  StatoVista scegliModo(ModoVista m) {
    if (m == ModoVista.tutto) {
      return StatoVista(
        visibili: _tutte(true),
        aperte: _tutte(true),
        primoPiano: primoPiano,
      );
    }
    return StatoVista(
      visibili: visibili,
      aperte: aperte,
      modo: m,
      primoPiano: primoPiano,
    );
  }

  /// Accende/spegne "Sempre in primo piano".
  StatoVista cambiaPrimoPiano() => StatoVista(
    visibili: visibili,
    aperte: aperte,
    modo: modo,
    primoPiano: !primoPiano,
  );
}

/// Posto di un tasto: gruppo, indice nel gruppo, x in px, riga.
typedef PostoTasto = ({int gruppo, int indice, int x, int riga});

/// Barre che vanno a capo. [gruppi] = liste di larghezze (px).
/// Dentro un gruppo si va a capo se non c'è posto. Gruppi dopo il primo:
/// a destra sulla stessa riga se c'è posto, altrimenti riga nuova.
List<PostoTasto> disponi(List<List<int>> gruppi, int larg, {int spazio = 4}) {
  final List<PostoTasto> out = <PostoTasto>[];
  int riga = 0;
  int x = 0;
  for (int g = 0; g < gruppi.length; g++) {
    final List<int> ws = gruppi[g];
    if (ws.isEmpty) {
      continue;
    }
    final int tot = ws.fold(0, (int s, int w) => s + w) + spazio * (ws.length - 1);
    if (g > 0 && x > 0) {
      if (x + spazio * 3 + tot <= larg) {
        int x0 = larg - tot;
        for (int i = 0; i < ws.length; i++) {
          out.add((gruppo: g, indice: i, x: x0, riga: riga));
          x0 += ws[i] + spazio;
        }
        x = larg;
        continue;
      }
      riga++;
      x = 0;
    }
    for (int i = 0; i < ws.length; i++) {
      if (x > 0 && x + ws[i] > larg) {
        riga++;
        x = 0;
      }
      out.add((gruppo: g, indice: i, x: x, riga: riga));
      x += ws[i] + spazio;
    }
  }
  return out;
}
