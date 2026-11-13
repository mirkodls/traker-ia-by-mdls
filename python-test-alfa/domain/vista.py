"""Vista finestra (P4): quali sezioni si vedono, aperte/chiuse, modo solo-X, a capo delle barre.
Funzioni pure: niente tkinter. Lo stato vive in impostazioni.json alla chiave "vista"."""
from __future__ import annotations

import copy

# ordine dall'alto
SEZIONI = ("carte", "grafico", "intensita", "barra", "dati", "confronti")
MODI = ("tutto", "grafico", "intensita")  # tutto | solo grafico grande | solo intensita
ESPANDIBILI = ("grafico", "intensita")    # chi prende lo spazio libero, in quest'ordine


def base() -> dict:
    return {"visibili": dict.fromkeys(SEZIONI, True), "aperte": dict.fromkeys(SEZIONI, True),
            "modo": "tutto", "primo_piano": False}


def normalizza(raw) -> dict:
    """Da impostazioni.json (anche vuoto/rotto) a vista completa e valida."""
    v = base()
    if not isinstance(raw, dict):
        return v
    for k in ("visibili", "aperte"):
        d = raw.get(k)
        if isinstance(d, dict):
            for s in SEZIONI:
                if isinstance(d.get(s), bool):
                    v[k][s] = d[s]
    if raw.get("modo") in MODI:
        v["modo"] = raw["modo"]
    if isinstance(raw.get("primo_piano"), bool):
        v["primo_piano"] = raw["primo_piano"]
    return v


def mostra(v: dict) -> list[tuple[str, bool]]:
    """Sezioni da disegnare, in ordine: [(nome, aperta)]."""
    if v["modo"] != "tutto":
        return [(v["modo"], True)]
    return [(s, v["aperte"][s]) for s in SEZIONI if v["visibili"][s]]


def con_titoli(v: dict) -> bool:
    """Nei modi solo-X niente titoli: solo il grafico."""
    return v["modo"] == "tutto"


def chi_espande(v: dict) -> str | None:
    aperte = {s for s, a in mostra(v) if a}
    return next((s for s in ESPANDIBILI if s in aperte), None)


def spuntata(v: dict, s: str) -> bool:
    """Spunta nel menu Vista = sezione che si vede ora."""
    return any(n == s for n, _ in mostra(v))


def cambia_visibile(v: dict, s: str) -> dict:
    n = copy.deepcopy(v)
    if n["modo"] != "tutto":  # da solo-X: si riparte da quello che si vede
        n["visibili"] = {x: x == n["modo"] for x in SEZIONI}
        n["aperte"][n["modo"]] = True
        n["modo"] = "tutto"
    n["visibili"][s] = not n["visibili"][s]
    if n["visibili"][s]:
        n["aperte"][s] = True
    return n


def cambia_aperta(v: dict, s: str) -> dict:
    n = copy.deepcopy(v)
    n["aperte"][s] = not n["aperte"][s]
    return n


def scegli_modo(v: dict, modo: str) -> dict:
    n = copy.deepcopy(v)
    if modo == "tutto":
        n["visibili"] = dict.fromkeys(SEZIONI, True)
        n["aperte"] = dict.fromkeys(SEZIONI, True)
    n["modo"] = modo if modo in MODI else "tutto"
    return n


def cambia_primo_piano(v: dict) -> dict:
    n = copy.deepcopy(v)
    n["primo_piano"] = not n["primo_piano"]
    return n


def disponi(gruppi: list[list[int]], larg: int, spazio: int = 4) -> list[tuple[int, int, int, int]]:
    """Barre che vanno a capo. gruppi = liste di larghezze (px).
    Ritorna [(gruppo, indice, x, riga)]. Dentro un gruppo si va a capo se non c'e' posto.
    Gruppi dopo il primo: a destra sulla stessa riga se c'e' posto, altrimenti riga nuova."""
    out: list[tuple[int, int, int, int]] = []
    riga, x = 0, 0
    for g, ws in enumerate(gruppi):
        if not ws:
            continue
        tot = sum(ws) + spazio * (len(ws) - 1)
        if g > 0 and x > 0:
            if x + spazio * 3 + tot <= larg:
                x0 = larg - tot
                for i, w in enumerate(ws):
                    out.append((g, i, x0, riga))
                    x0 += w + spazio
                x = larg
                continue
            riga, x = riga + 1, 0
        for i, w in enumerate(ws):
            if x > 0 and x + w > larg:
                riga, x = riga + 1, 0
            out.append((g, i, x, riga))
            x += w + spazio
    return out
