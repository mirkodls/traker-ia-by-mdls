"""P2: previsione 100%, budget giornaliero, frasi fisse. Logica pura, niente IA."""
from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime, timedelta
from typing import Optional

from domain import analisi as A

GIORNI = ["lun", "mar", "mer", "gio", "ven", "sab", "dom"]
DEBOLE_PT = 1.0  # consumo nel periodo <= 1 punto = dato debole


@dataclass
class Previsione:
    att: Optional[float]              # % settimanale attuale
    ritmo: Optional[float]            # pt/h su ultime N ore (tempo reale, pause incluse)
    consumo: float                    # punti consumati nel periodo
    ora_100: Optional[datetime]       # stima 100%; None se ritmo 0/ignoto
    prima_del_reset: bool
    debole: bool


def _ultima(letture: list[A.Lettura], campo: str) -> Optional[A.Lettura]:
    ls = [l for l in letture if getattr(l, campo) is not None]
    return max(ls, key=lambda l: l.ora) if ls else None


def previsione(letture: list[A.Lettura], reset_sett: datetime, ore: float = 6.0) -> Previsione:
    """Ora stimata 100% settimanale al ritmo delle ultime `ore` ore (fino all'ultima lettura)."""
    ult = _ultima(letture, "sett")
    if ult is None:
        return Previsione(None, None, 0.0, None, False, True)
    da = ult.ora - timedelta(hours=ore)
    r = A.ritmo(letture, "sett", da, ult.ora)
    coperte = _ore_coperte(letture, da, ult.ora)
    consumo = (r or 0.0) * coperte
    debole = r is None or consumo <= DEBOLE_PT
    ora_100 = None
    prima = False
    if r and r > 0:
        ora_100 = ult.ora + timedelta(hours=(100 - ult.sett) / r)
        prima = ora_100 < reset_sett
    return Previsione(ult.sett, r, consumo, ora_100, prima, debole)


def _ore_coperte(letture: list[A.Lettura], da: datetime, a: datetime) -> float:
    tot = 0.0
    for x, y, _, _ in A._coppie(letture, "sett"):
        ini, fin = max(x.ora, da), min(y.ora, a)
        if fin > ini:
            tot += (fin - ini).total_seconds() / 3600
    return tot


def budget_giorno(att: Optional[float], adesso: datetime, reset_sett: datetime) -> Optional[float]:
    """Punti % per giorno fino al reset: (100-att)/giorni_al_reset."""
    if att is None:
        return None
    giorni = (reset_sett - adesso).total_seconds() / 86400
    if giorni <= 0:
        return None
    return max(0.0, 100 - att) / giorni


def ritmo_attivo(letture: list[A.Lettura], ore: float = 6.0) -> Optional[float]:
    """pt/h settimanale solo sulle coppie con consumo (> 0), ultime `ore` ore di tali coppie."""
    coppie = [(b.ora, d, h) for _, b, d, h in A._coppie(letture, "sett") if d > 0]
    tot_d = tot_h = 0.0
    for _, d, h in reversed(coppie):
        if tot_h >= ore:
            break
        tot_d += d
        tot_h += h
    return tot_d / tot_h if tot_h > 0 else None


def ore_full_gas_rimaste(letture: list[A.Lettura], ore: float = 6.0) -> Optional[float]:
    """Ore di uso continuo al ritmo 'attivo' prima di toccare 100%."""
    ult = _ultima(letture, "sett")
    r = ritmo_attivo(letture, ore)
    if ult is None or not r:
        return None
    return max(0.0, 100 - ult.sett) / r


def _quando(d: datetime) -> str:
    return f"{GIORNI[d.weekday()]} {d:%H:%M}"


def _durata(h: float) -> str:
    m = int(round(h * 60))
    return f"{m // 60}h {m % 60:02d}m"


def frasi(letture: list[A.Lettura], reset_sett: datetime, adesso: datetime, ore: float = 6.0) -> list[str]:
    """Frasi fisse coi numeri per il riquadro 'Cosa dicono i dati'."""
    p = previsione(letture, reset_sett, ore)
    if p.att is None:
        return ["Nessun dato settimanale: aspetta una lettura."]
    out = []
    if p.debole:
        out.append("Dato debole: aspetta.")
    elif p.prima_del_reset:
        out.append(f"A questo ritmo finisci {_quando(p.ora_100)}. Reset {_quando(reset_sett)}.")
    else:
        out.append(f"A questo ritmo arrivi al reset senza finire. Reset {_quando(reset_sett)}.")
    b = budget_giorno(p.att, adesso, reset_sett)
    if b is not None:
        out.append(f"Oggi puoi usare ancora {b:.1f} punti.")
    h = ore_full_gas_rimaste(letture, ore)
    if h is not None:
        out.append(f"A pieno regime ti restano circa {_durata(h)} di lavoro.")
    return out
