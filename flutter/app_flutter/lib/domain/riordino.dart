// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
//
// Strato domain: riordino tasti trascinati e posizione del riquadro del mouse.

/// Sotto questa distanza (px) è un clic, sopra un trascinamento.
const double sogliaTrascina = 5;

/// Copia di [lista] con l'elemento in [da] portato al posto finale [a].
List<T> sposta<T>(List<T> lista, int da, int a) {
  final List<T> n = List<T>.of(lista);
  if (da < 0 || da >= n.length) {
    return n;
  }
  final int dove = a.clamp(0, n.length - 1);
  n.insert(dove, n.removeAt(da));
  return n;
}

/// Centro di un tasto.
typedef Punto = ({double x, double y});

/// Posto finale del tasto [da] rilasciato. [centri] = centro di ogni tasto,
/// ordine attuale ([da] ha il centro dove è stato rilasciato).
/// Righe diverse se |dy| > [tol].
int indiceRilascio(List<Punto> centri, int da, double tol) {
  final Punto c = centri[da];
  int a = 0;
  for (int i = 0; i < centri.length; i++) {
    if (i == da) {
      continue;
    }
    final Punto p = centri[i];
    if (p.y < c.y - tol || ((p.y - c.y).abs() <= tol && p.x < c.x)) {
      a++;
    }
  }
  return a;
}

/// Riquadro [w] x [h] vicino al mouse ([mx], [my]) in un'area [larg] x [alt].
/// Prima a destra/sotto; se non entra a sinistra/sopra. entra = false se
/// esce comunque (allora serve una finestra a parte).
({double x, double y, bool entra}) posizionaRiquadro(
  double mx,
  double my,
  double w,
  double h,
  double larg,
  double alt, {
  double margine = 6,
  double scarto = 14,
}) {
  double x = mx + scarto;
  if (x + w > larg - margine) {
    x = mx - scarto - w;
  }
  double y = my + scarto;
  if (y + h > alt - margine) {
    y = my - scarto - h;
  }
  final bool entra = x >= margine &&
      y >= margine &&
      x + w <= larg - margine &&
      y + h <= alt - margine;
  return (x: x, y: y, entra: entra);
}
