"""Modelli/skill attivi: ritmo per combinazione, confronto, classifica modelli (logica pura)."""
from __future__ import annotations

from datetime import datetime

from domain import lavoro as LV
from domain.analisi import Lettura, _coppie, verdetto

Combo = tuple[str, str]  # (modelli, skill) normalizzati "A|B"


def norm(s: str) -> str:
    """'Sonnet| Opus|Opus' -> 'Opus|Sonnet' (ordinati, senza doppioni/vuoti)."""
    return "|".join(sorted({x.strip() for x in (s or "").split("|") if x.strip()}))


def unisci(nomi) -> str:
    return norm("|".join(nomi))


def combo(l: Lettura) -> Combo:
    return norm(l.modelli), norm(l.skill)


def etichetta(c: Combo) -> str:
    m, s = c
    if not m and not s:
        return "(non segnato)"
    mm = m.replace("|", " + ") if m else "nessun modello"
    return f"{mm}  ·  {s.replace('|', ' + ')}" if s else mm


def _acc(tab, chiave, campo, d, ore):
    r = tab.setdefault(chiave, {"d_sett": 0.0, "h_sett": 0.0, "d_sess": 0.0, "h_sess": 0.0})
    r["d_" + campo] += d
    r["h_" + campo] += ore


def _chiudi(tab) -> dict:
    out = {}
    for k, r in tab.items():
        f = lambda c, r=r: r["d_" + c] / r["h_" + c] if r["h_" + c] > 0 else None
        out[k] = {"ore": max(r["h_sett"], r["h_sess"]), "sett": f("sett"), "sess": f("sess")}
    return out


def ritmo_per_combinazione(letture: list[Lettura], periodi=None) -> dict[Combo, dict]:
    """{(modelli, skill): {ore, sett pt/h, sess pt/h}}.
    Ogni intervallo tra 2 letture va alla combinazione segnata nella lettura di arrivo
    (come al_pc). Reset (cali) esclusi. periodi (P8) = conta solo dentro i periodi lavoro."""
    tab: dict = {}
    for campo in ("sett", "sess"):
        for b, d, ore in LV.quote(letture, campo, periodi=periodi):
            _acc(tab, combo(b), campo, d, ore)
    return _chiudi(tab)


def confronta(c1: dict | None, c2: dict | None, campo: str = "sett",
              soglia: float = 0.10, ore_min: float = 1.0) -> str:
    """c1 = prima/riferimento, c2 = altra. SCESO/SALITO/COSTANTE (±10%), DATO DEBOLE se ore < 1."""
    if not c1 or not c2 or c1["ore"] < ore_min or c2["ore"] < ore_min:
        return "DATO DEBOLE"
    v = verdetto(c1.get(campo), c2.get(campo), soglia)
    return "DATO DEBOLE" if v == "dati insufficienti" else v.upper()


def classifica_modelli(letture: list[Lettura], campo: str = "sett") -> list[tuple[str, float, float]]:
    """[(modello, ore, pt/h)] dal più vorace. Più modelli attivi insieme: l'intervallo conta per ognuno."""
    tab: dict = {}
    for _, b, d, ore in _coppie(letture, campo):
        for m in filter(None, norm(b.modelli).split("|")):
            r = tab.setdefault(m, [0.0, 0.0])
            r[0] += d
            r[1] += ore
    out = [(m, h, d / h) for m, (d, h) in tab.items() if h > 0]
    return sorted(out, key=lambda x: -x[2])


def stato_a(letture: list[Lettura], t: datetime) -> Combo | None:
    """Combinazione valida all'ora t = quella della prima lettura >= t (stessa regola del ritmo)."""
    ls = sorted(letture, key=lambda x: x.ora)
    for l in ls:
        if l.ora >= t:
            return combo(l)
    return combo(ls[-1]) if ls else None
