"""Catena di riserva per le letture del traker (Edge è a parte, in ricevitore.py).
Ordine in "auto": Claude Code -> cookie. Il primo che risponde vince; se cadono tutti: errore unico."""
from __future__ import annotations

from data import fonte, sistema
from domain import analisi as A


def metodi_attivi(imp: dict) -> list[str]:
    m = imp.get("metodo", "auto")
    if m == "manuale":
        return []
    if m != "auto":
        return [m]
    out = []
    if fonte.token_claude_code():
        out.append("claude_code")
    if imp.get("cookie"):
        out.append("cookie")
    return out


def leggi_uno(m: str, imp: dict, salva) -> A.Uso:
    if m == "claude_code":
        tok = fonte.token_claude_code()
        if not tok:
            raise fonte.ErroreFonte("Claude Code non trovato")
        body = fonte.leggi_claude_code(tok)
    elif m == "cookie":
        ck = sistema.decifra(imp.get("cookie", ""))
        if not ck:
            raise fonte.ErroreFonte("cookie mancante")
        org = imp.get("org_id") or fonte.trova_org(ck)
        if org != imp.get("org_id"):
            imp["org_id"] = org
            salva()
        body = fonte.leggi_cookie(ck, org)
    else:
        raise fonte.ErroreFonte(f"metodo sconosciuto: {m}")
    uso = A.leggi_risposta(body)
    if uso.sett is None and uso.sess is None:
        raise fonte.ErroreFonte("risposta senza percentuali")
    return uso


NOMI = {"claude_code": "Claude Code", "cookie": "cookie", "edge": "Edge"}


def leggi_catena(imp: dict, salva, metodi: list[str], leggi=leggi_uno):
    """-> (Uso, metodo). Prova i metodi in ordine; se falliscono tutti alza ErroreFonte."""
    errori = []
    for m in metodi:
        try:
            return leggi(m, imp, salva), m
        except fonte.ErroreFonte as e:
            errori.append(f"{NOMI.get(m, m)}: {e}")
        except Exception as e:  # noqa: BLE001 - un metodo rotto non ferma la catena
            errori.append(f"{NOMI.get(m, m)}: errore {e}")
    raise fonte.ErroreFonte(" | ".join(errori) or "nessun metodo disponibile")
