"""Riordino tasti (P5) e posizione riquadri hover. Funzioni pure: niente tkinter."""
from __future__ import annotations

SOGLIA_TRASCINA = 5  # px: sotto questa distanza e' un clic, sopra e' un trascinamento


def sposta(lista: list, da: int, a: int) -> list:
    """Copia di lista con l'elemento in posizione `da` portato in posizione `a` (a = posto finale)."""
    n = list(lista)
    if not 0 <= da < len(n):
        return n
    a = max(0, min(a, len(n) - 1))
    n.insert(a, n.pop(da))
    return n


def indice_rilascio(centri: list[tuple[float, float]], da: int, tol: float) -> int:
    """Posto finale del tasto `da` trascinato. centri = (x, y) del centro di ogni tasto, ordine attuale
    (il tasto `da` ha il centro dove e' stato rilasciato). Tasti a capo: righe diverse se |dy| > tol."""
    cx, cy = centri[da]
    a = 0
    for i, (x, y) in enumerate(centri):
        if i == da:
            continue
        if y < cy - tol or (abs(y - cy) <= tol and x < cx):
            a += 1
    return a


def posiziona_riquadro(mx: float, my: float, w: float, h: float, larg: float, alt: float,
                       margine: float = 6, scarto: float = 14) -> tuple[float, float, bool]:
    """Riquadro w x h vicino al mouse (mx, my) in un'area larg x alt.
    Prima a destra/sotto; se non entra: a sinistra/sopra. Ritorna (x, y, entra):
    entra=False se anche cosi' esce dall'area (allora serve una finestra a parte)."""
    x = mx + scarto
    if x + w > larg - margine:
        x = mx - scarto - w
    y = my + scarto
    if y + h > alt - margine:
        y = my - scarto - h
    entra = x >= margine and y >= margine and x + w <= larg - margine and y + h <= alt - margine
    return x, y, entra
