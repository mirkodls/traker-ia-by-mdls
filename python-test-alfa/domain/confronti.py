"""Carta CONFRONTI (P6): numeri, ore contate e testi di spiegazione. Logica pura, niente tkinter."""
from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime
from typing import Optional

from domain import analisi as A
from domain import combinazioni as C
from domain import lavoro as LV

GIORNI = ["lun", "mar", "mer", "gio", "ven", "sab", "dom"]
DEBOLE = "DATO DEBOLE"
ORE_MIN = 1.0  # sotto = dato debole (stessa soglia di combinazioni.confronta)


def num(x: Optional[float], dec: int = 2) -> str:
    """0.94 -> '0,94'; None -> '-'."""
    return "-" if x is None else f"{x:.{dec}f}".replace(".", ",")


def ore(h: Optional[float]) -> str:
    """0.1 -> '0,1 h'."""
    return "-" if h is None else f"{h:.1f}".replace(".", ",") + " h"


def quando(d: datetime) -> str:
    return f"{GIORNI[d.weekday()]} {d:%d/%m %H:%M}"


def ore_contate(letture: list[A.Lettura], campo: str = "sett", da=None, a=None) -> float:
    """Ore di letture usate dal ritmo nel periodo [da, a] (stessa regola di analisi.ritmo)."""
    tot = 0.0
    for x, y, _d, _o in A._coppie(letture, campo):
        ini = max(x.ora, da) if da is not None else x.ora
        fin = min(y.ora, a) if a is not None else y.ora
        if fin > ini:
            tot += (fin - ini).total_seconds() / 3600
    return tot


# ---------- riga 1: nota ----------
@dataclass
class ConfrontoNota:
    prima: Optional[float]
    dopo: Optional[float]
    ore_prima: float
    ore_dopo: float
    verdetto: str  # SCESO | SALITO | COSTANTE | DATO DEBOLE
    da: datetime   # inizio del "prima" (reset settimanale)
    nota: datetime
    filtro: str = ""  # P8: "" | "lavoro" (conta solo lavoro) | "tutto" (spunta accesa ma nessun periodo)


def _scegli_periodi(ore_con_filtro: list[float], periodi) -> tuple[Optional[list], str]:
    """P8: spunta spenta -> (None, ''); un lato senza ore di lavoro -> conta tutto (None, 'tutto')."""
    if periodi is None:
        return None, ""
    if any(h <= 0 for h in ore_con_filtro):
        return None, "tutto"
    return periodi, "lavoro"


def confronto_nota(letture: list[A.Lettura], marcatore: datetime, campo: str = "sett",
                   periodi: Optional[list] = None) -> ConfrontoNota:
    """Prima = da reset settimanale alla nota; dopo = dalla nota a oggi. Verdetto ±10%.
    periodi (P8) = conta solo dentro i periodi lavoro; se prima o dopo non ne ha: conta tutto."""
    ini = A.inizio_settimana(marcatore)
    if periodi is not None:
        hp = LV.ritmo_ore(letture, campo, ini, marcatore, periodi)[1]
        hd = LV.ritmo_ore(letture, campo, marcatore, None, periodi)[1]
        periodi, filtro = _scegli_periodi([hp, hd], periodi)
    else:
        filtro = ""
    prima, op = LV.ritmo_ore(letture, campo, ini, marcatore, periodi)
    dopo, od = LV.ritmo_ore(letture, campo, marcatore, None, periodi)
    v = A.verdetto(prima, dopo)
    return ConfrontoNota(prima, dopo, op, od,
                         DEBOLE if v == "dati insufficienti" else v.upper(), ini, marcatore, filtro)


def testo_filtro(filtro: str) -> str:
    return {"lavoro": "(solo lavoro)", "tutto": LV.NESSUN_LAVORO}.get(filtro, "")


def testo_ore_nota(c: ConfrontoNota) -> str:
    return f"({ore(c.ore_prima)} prima / {ore(c.ore_dopo)} dopo)"


# ---------- riga 2: combinazioni ----------
def motivo_debole(ore_a: Optional[float], ore_b: Optional[float]) -> str:
    """'(B solo 0,1 h)' / '(A solo 0,5 h, B solo 0,1 h)' / '(manca un dato)'. Vuoto se entrambe >= 1 h."""
    if ore_a is None or ore_b is None:
        return "(manca un dato)"
    corti = [f"{n} solo {ore(h)}" for n, h in (("A", ore_a), ("B", ore_b)) if h < ORE_MIN]
    return f"({', '.join(corti)})" if corti else ""


@dataclass
class ConfrontoCombo:
    a: Optional[float]
    b: Optional[float]
    verdetto: str
    motivo: str  # non vuoto solo con DATO DEBOLE
    filtro: str = ""  # P8, come ConfrontoNota.filtro


def confronto_combinazioni(tab: dict, ka, kb, campo: str = "sett", tab_lavoro: Optional[dict] = None) -> ConfrontoCombo:
    """tab = tutte le ore. tab_lavoro (P8, spunta accesa) = solo ore di lavoro;
    se A o B non ha ore di lavoro: usa tab (conta tutto)."""
    filtro = ""
    if tab_lavoro is not None:
        hl = [(tab_lavoro.get(k) or {}).get("ore", 0.0) for k in (ka, kb)]
        usa, filtro = _scegli_periodi(hl, True)
        if usa:
            tab = tab_lavoro
    ra, rb = tab.get(ka), tab.get(kb)
    v = C.confronta(ra, rb, campo)
    return ConfrontoCombo(ra.get(campo) if ra else None, rb.get(campo) if rb else None, v,
                          motivo_debole(ra["ore"] if ra else None, rb["ore"] if rb else None)
                          if v == DEBOLE else "", filtro)


def periodo_combo(letture: list[A.Lettura], k, campo: str = "sett") -> Optional[tuple[datetime, datetime]]:
    """Primo e ultimo istante degli intervalli assegnati alla combinazione k (None se nessuno)."""
    iv = [(a.ora, b.ora) for a, b, _d, _o in A._coppie(letture, campo) if C.combo(b) == k]
    return (min(i[0] for i in iv), max(i[1] for i in iv)) if iv else None


def testo_classifica(cl: list[tuple[str, float, float]]) -> str:
    """cl = classifica_modelli(): 'Classifica modelli: Opus 0,87 · Sonnet 0,40' (dal più vorace)."""
    if not cl:
        return "Classifica modelli: ancora nessun dato."
    return "Classifica modelli (dal più vorace): " + "  ·  ".join(f"{m} {num(p)} ({ore(h)})" for m, h, p in cl)


def testo_presenza(pc: Optional[float], auto: Optional[float]) -> str:
    return f"Al PC {num(pc)}  ·  automatico {num(auto)}  pt%/h sett (questa settimana)"


# ---------- spiegazioni (tooltip) ----------
PTH = ("pt%/h = punti percentuali della barra consumati in media ogni ora.\n"
       "Esempio: 0,50 vuol dire che la barra sale di mezzo punto ogni ora.\n"
       "Più è basso, più Claude dura.")
SETT = "'sett' = barra della SETTIMANA (si azzera il martedì alle 20:00)."
FRECCIA = "Il ritmo è calcolato solo sulle letture vere. I cali della barra (reset) non contano."
SPIEGA_VERDETTO = {
    "SCESO": "SCESO: il secondo ritmo è almeno il 10% più basso del primo. Consumi meno.",
    "SALITO": "SALITO: il secondo ritmo è almeno il 10% più alto del primo. Consumi di più.",
    "COSTANTE": "COSTANTE: la differenza è sotto il 10%. Nessun cambiamento chiaro.",
    DEBOLE: ("DATO DEBOLE: meno di 1 ora di letture in uno dei due periodi, o dato mancante.\n"
             "Il numero c'è ma non ci si può fidare: aspetta altre letture."),
}
NON_SEGNATO = ("(non segnato) = letture fatte prima dei tasti modelli/skill.\n"
               "Non si sa quale modello era acceso, quindi sono tenute a parte.")
AL_PC = ("Al PC = intervalli in cui hai usato mouse o tastiera.\n"
         "Automatico = PC fermo (lavora solo Claude o niente).\n"
         "Il tempo di inattività si cambia in Impostazioni.")
COME_LEGGERE = (
    "COME LEGGERE I CONFRONTI\n\n"
    "Nota: confronta il ritmo PRIMA e DOPO la nota scelta. 'Prima' parte dall'ultimo reset "
    "della settimana, 'dopo' arriva a oggi.\n\n"
    "Combinazioni: confronta due modi di lavorare (modelli + skill accesi) tra loro. "
    "Ogni intervallo tra due letture va alla combinazione segnata nella lettura di arrivo.\n\n"
    "Il ritmo è in pt%/h: punti della barra consumati ogni ora. Più basso = meglio.\n\n"
    "Il verdetto usa ±10%. Con meno di 1 ora di dati: DATO DEBOLE.\n\n"
    "Passa il mouse su ogni numero per la spiegazione."
)


def spiega_prima(c: ConfrontoNota) -> str:
    return (f"PRIMA della nota: ritmo medio da {quando(c.da)} (reset settimana) a {quando(c.nota)}.\n"
            f"Ore di letture usate: {ore(c.ore_prima)} {testo_filtro(c.filtro)}.\n\n{PTH}")


def spiega_dopo(c: ConfrontoNota, fine: datetime) -> str:
    return (f"DOPO la nota: ritmo medio da {quando(c.nota)} a {quando(fine)}.\n"
            f"Ore di letture usate: {ore(c.ore_dopo)} {testo_filtro(c.filtro)}.\n\n{PTH}")


SOLO_LAVORO = ("Conta solo lavoro: i ritmi usano SOLO il tempo tra 'Inizio lavoro' e 'Fine lavoro'\n"
               "(periodo ancora aperto = fino ad adesso). Le letture a cavallo vengono tagliate in proporzione.\n"
               "Se prima o dopo (o A o B) non ha ore di lavoro, conta tutto e lo scrive.\n"
               "Vale per la riga Nota e per la riga Combinazioni. Verdetto sempre ±10%.")


def spiega_ore_nota() -> str:
    return "Ore di letture vere dietro ai due ritmi. Poche ore = numero poco affidabile."


def spiega_combo(nome: str, k, periodo, h: Optional[float]) -> str:
    righe = [f"{nome} = {C.etichetta(k)}"]
    if h is not None:
        righe.append(f"Ore di letture usate: {ore(h)}.")
    if periodo:
        righe.append(f"Da {quando(periodo[0])} a {quando(periodo[1])} "
                     "(solo gli intervalli con questa combinazione).")
    if k == ("", ""):
        righe += ["", NON_SEGNATO]
    return "\n".join(righe) + f"\n\n{PTH}\n{SETT}"


def spiega_verdetto(v: str) -> str:
    return SPIEGA_VERDETTO.get(v, "")
