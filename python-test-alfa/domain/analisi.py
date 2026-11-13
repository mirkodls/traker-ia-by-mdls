"""Logica pura: lettura risposta API, ritmo di consumo, confronto prima/dopo."""
from __future__ import annotations

import re
from dataclasses import dataclass
from datetime import datetime, timedelta, timezone
from typing import Optional

FMT = "%Y-%m-%d %H:%M"


@dataclass
class Lettura:
    ora: datetime
    sett: Optional[float]          # % settimanale
    sess: Optional[float]          # % sessione 5h
    fonte: str = "auto"            # auto | manuale | iniziale
    al_pc: Optional[bool] = None   # input tastiera/mouse nell'intervallo
    lavoro: bool = False           # tasto "Inizio lavoro" attivo
    modelli: str = ""              # modelli attivi alla lettura, nomi separati da "|"
    skill: str = ""                # skill attive alla lettura, nomi separati da "|"


@dataclass
class Evento:
    ora: datetime
    tipo: str                      # nota | inizio | fine | reset
    testo: str = ""


@dataclass
class Uso:
    sess: Optional[float]
    sett: Optional[float]
    reset_sess: Optional[datetime]
    reset_sett: Optional[datetime]


def _data_utc_a_locale(s) -> Optional[datetime]:
    if not s or not isinstance(s, str):
        return None
    s = s.strip().replace("Z", "+00:00")
    s = re.sub(r"(\.\d{6})\d+", r"\1", s)
    try:
        d = datetime.fromisoformat(s)
    except ValueError:
        return None
    if d.tzinfo is None:
        d = d.replace(tzinfo=timezone.utc)
    return d.astimezone().replace(tzinfo=None, second=0, microsecond=0)


def leggi_risposta(body: dict) -> Uso:
    """Risposta /usage -> Uso. Valori in percento (0-100)."""
    def blocco(chiave):
        v = body.get(chiave) if isinstance(body, dict) else None
        if not isinstance(v, dict):
            return None, None
        u = v.get("utilization")
        u = float(u) if isinstance(u, (int, float)) else None
        return u, _data_utc_a_locale(v.get("resets_at"))

    sess, rs = blocco("five_hour")
    sett, rw = blocco("seven_day")
    # alcune versioni danno frazioni 0-1: se entrambi <=1 e non interi, scala
    vals = [x for x in (sess, sett) if x is not None]
    if vals and all(x <= 1.0 for x in vals) and any(0 < x < 1 for x in vals):
        sess = sess * 100 if sess is not None else None
        sett = sett * 100 if sett is not None else None
    return Uso(sess, sett, rs, rw)


def inizio_settimana(ora: datetime, giorno: int = 1, h: int = 20, m: int = 0) -> datetime:
    """Ultimo reset settimanale (default martedi 20:00) <= ora."""
    base = ora.replace(hour=h, minute=m, second=0, microsecond=0)
    base -= timedelta(days=(ora.weekday() - giorno) % 7)
    if base > ora:
        base -= timedelta(days=7)
    return base


def filtra(letture: list[Lettura], da: datetime, a: datetime) -> list[Lettura]:
    return [l for l in letture if da <= l.ora <= a]


def trova_reset(letture: list[Lettura], campo: str) -> list[datetime]:
    """Momenti in cui il valore scende (= reset)."""
    out, prec = [], None
    for l in sorted(letture, key=lambda x: x.ora):
        v = getattr(l, campo)
        if v is None:
            continue
        if prec is not None and v < prec - 0.5:
            out.append(l.ora)
        prec = v
    return out


def _coppie(letture: list[Lettura], campo: str):
    """Coppie consecutive valide (stessa finestra, nessun reset in mezzo)."""
    ls = [l for l in sorted(letture, key=lambda x: x.ora) if getattr(l, campo) is not None]
    for a, b in zip(ls, ls[1:]):
        d = getattr(b, campo) - getattr(a, campo)
        ore = (b.ora - a.ora).total_seconds() / 3600
        if d < -0.5 or ore <= 0:
            continue
        yield a, b, max(d, 0.0), ore


def ritmo(letture: list[Lettura], campo: str = "sett", da=None, a=None) -> Optional[float]:
    """Punti % all'ora nel periodo [da, a]; coppie a cavallo divise in proporzione."""
    tot_d = tot_h = 0.0
    for x, y, d, ore in _coppie(letture, campo):
        ini, fin = x.ora, y.ora
        if da is not None:
            ini = max(ini, da)
        if a is not None:
            fin = min(fin, a)
        if fin <= ini:
            continue
        quota = (fin - ini).total_seconds() / 3600
        tot_d += d * quota / ore
        tot_h += quota
    return tot_d / tot_h if tot_h > 0 else None


def serie_intensita(letture: list[Lettura], da: datetime, a: datetime,
                    passo_min: int = 5, finestra_min: int = 30) -> list[tuple[datetime, Optional[float]]]:
    """Ritmo pt%/h della barra 5h (sess), media mobile su finestra_min, reset esclusi.
    Punti ogni passo_min in [da, a]; None dove la finestra non ha dati validi."""
    out: list[tuple[datetime, Optional[float]]] = []
    t = da
    while t <= a:
        out.append((t, ritmo(letture, "sess", t - timedelta(minutes=finestra_min), t)))
        t += timedelta(minutes=passo_min)
    return out


def valore_a(letture: list[Lettura], campo: str, t: datetime,
             tol_s: float = 0.0) -> tuple[Optional[float], bool]:
    """Valore di campo all'ora t -> (valore, esatto).
    esatto=True se una lettura vera cade a t (±tol_s). Tra 2 letture: interpolazione lineare.
    None se fuori dai dati o a cavallo di un reset (calo)."""
    ls = [l for l in sorted(letture, key=lambda x: x.ora) if getattr(l, campo) is not None]
    for l in ls:
        if abs((l.ora - t).total_seconds()) <= tol_s:
            return getattr(l, campo), True
    for a, b in zip(ls, ls[1:]):
        if a.ora < t < b.ora:
            va, vb = getattr(a, campo), getattr(b, campo)
            if vb < va - 0.5:
                return None, False
            f = (t - a.ora).total_seconds() / (b.ora - a.ora).total_seconds()
            return va + (vb - va) * f, False
    return None, False


def intensita_a(letture: list[Lettura], t: datetime, finestra_min: int = 30) -> Optional[float]:
    """Intensità (pt%/h barra 5h, media mobile) all'ora t. Stesso calcolo di serie_intensita."""
    return ritmo(letture, "sess", t - timedelta(minutes=finestra_min), t)


def ritmo_per_presenza(letture: list[Lettura], campo: str = "sett"):
    """(pt/h quando al PC, pt/h in automatico). Solo coppie con al_pc noto."""
    acc = {True: [0.0, 0.0], False: [0.0, 0.0]}
    for _, b, d, ore in _coppie(letture, campo):
        if b.al_pc is None:
            continue
        acc[b.al_pc][0] += d
        acc[b.al_pc][1] += ore
    f = lambda k: acc[k][0] / acc[k][1] if acc[k][1] > 0 else None
    return f(True), f(False)


def verdetto(prima: Optional[float], dopo: Optional[float], soglia: float = 0.10) -> str:
    if prima is None or dopo is None:
        return "dati insufficienti"
    if prima == 0:
        return "salito" if dopo > 0 else "costante"
    r = (dopo - prima) / prima
    if r <= -soglia:
        return "sceso"
    if r >= soglia:
        return "salito"
    return "costante"


def confronto(letture: list[Lettura], marcatore: datetime, campo: str = "sett"):
    """Ritmo prima/dopo il marcatore, nella stessa settimana del marcatore."""
    ini = inizio_settimana(marcatore)
    prima = ritmo(letture, campo, ini, marcatore)
    dopo = ritmo(letture, campo, marcatore, None)
    return prima, dopo, verdetto(prima, dopo)


def fmt(d: datetime) -> str:
    return d.strftime(FMT)


def parse(s: str) -> datetime:
    return datetime.strptime(s.strip(), FMT)
