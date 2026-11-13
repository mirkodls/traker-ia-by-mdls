"""P8: "Conta solo lavoro" (periodi Inizio->Fine lavoro) + orario reset arrotondato. Logica pura."""
from __future__ import annotations

from datetime import datetime, timedelta
from typing import Optional

from domain import analisi as A

Periodo = tuple[datetime, datetime]
NESSUN_LAVORO = "(nessun periodo lavoro: conta tutto)"


def periodi_lavoro(eventi: list[A.Evento], fino: datetime) -> list[Periodo]:
    """Eventi inizio/fine -> [(inizio, fine)]. Periodo ancora aperto = fino a `fino` (adesso).
    'inizio' doppio ignorato; 'fine' senza inizio ignorato. Ordine del file a parità di ora."""
    out: list[Periodo] = []
    aperto: Optional[datetime] = None
    for e in sorted((e for e in eventi if e.tipo in ("inizio", "fine")), key=lambda e: e.ora):
        if e.tipo == "inizio" and aperto is None:
            aperto = e.ora
        elif e.tipo == "fine" and aperto is not None:
            if e.ora > aperto:
                out.append((aperto, e.ora))
            aperto = None
    if aperto is not None and fino > aperto:
        out.append((aperto, fino))
    return out


def sovrapposizione(ini: datetime, fin: datetime, periodi: Optional[list[Periodo]]) -> float:
    """Ore di [ini, fin] dentro i periodi. periodi=None -> tutto l'intervallo."""
    if fin <= ini:
        return 0.0
    if periodi is None:
        return (fin - ini).total_seconds() / 3600
    tot = 0.0
    for a, b in periodi:
        x, y = max(ini, a), min(fin, b)
        if y > x:
            tot += (y - x).total_seconds() / 3600
    return tot


def quote(letture: list[A.Lettura], campo: str = "sett", da=None, a=None,
          periodi: Optional[list[Periodo]] = None):
    """Per ogni coppia valida (reset esclusi): (lettura_arrivo, punti, ore) dentro [da, a] e dentro i periodi.
    Coppie a cavallo tagliate in proporzione."""
    for x, y, d, ore in A._coppie(letture, campo):
        ini = max(x.ora, da) if da is not None else x.ora
        fin = min(y.ora, a) if a is not None else y.ora
        q = sovrapposizione(ini, fin, periodi)
        if q > 0:
            yield y, d * q / ore, q


def ritmo_ore(letture: list[A.Lettura], campo: str = "sett", da=None, a=None,
              periodi: Optional[list[Periodo]] = None) -> tuple[Optional[float], float]:
    """(pt%/h, ore contate). Senza periodi = stesso risultato di analisi.ritmo."""
    tot_d = tot_h = 0.0
    for _y, d, q in quote(letture, campo, da, a, periodi):
        tot_d += d
        tot_h += q
    return (tot_d / tot_h if tot_h > 0 else None), tot_h


def arrotonda_reset(d: Optional[datetime], tol_min: int = 2) -> Optional[datetime]:
    """Orario reset da mostrare: se entro ±tol_min dall'ora intera (:00) -> ora intera. 19:59 -> 20:00.
    Solo visualizzazione/previsione: i dati salvati non cambiano."""
    if d is None:
        return None
    base = d.replace(minute=0, second=0, microsecond=0)
    for h in (base, base + timedelta(hours=1)):
        if abs((d - h).total_seconds()) <= tol_min * 60:
            return h
    return d
