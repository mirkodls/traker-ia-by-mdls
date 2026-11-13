"""Salvataggio locale: letture.csv, eventi.csv, impostazioni.json."""
from __future__ import annotations

import csv
import json
import os
import tempfile
from datetime import datetime

from domain.analisi import Evento, Lettura, fmt, parse

CAMPI_L = ["ora", "settimanale", "sessione", "fonte", "al_pc", "lavoro", "modelli", "skill"]
CAMPI_E = ["ora", "tipo", "testo"]

IMPOSTAZIONI_BASE = {
    "minuti": 10,          # ogni quanto leggere
    "metodo": "auto",      # auto | claude_code | cookie | manuale
    "cookie": "",          # sessionKey cifrato (DPAPI)
    "org_id": "",
    "minuti_inattivo": 5,  # senza input per X min = non al PC
    "modelli": ["Opus", "Sonnet", "Fable", "Haiku"],  # nomi tasti a destra
    "skill": ["caveman"],                              # nomi tasti a sinistra
    "modelli_attivi": [],
    "skill_attive": [],
}

DATI_INIZIALI_L: list = []  # niente dati personali nel codice
DATI_INIZIALI_E: list = []


def _num(s):
    return float(s) if s not in ("", None) else None


def _bool(s):
    return None if s in ("", None) else s == "1"


class Archivio:
    def __init__(self, cartella: str):
        self.cartella = cartella
        os.makedirs(cartella, exist_ok=True)
        self.f_l = os.path.join(cartella, "letture.csv")
        self.f_e = os.path.join(cartella, "eventi.csv")
        self.f_i = os.path.join(cartella, "impostazioni.json")
        self._cache: dict[str, tuple] = {}  # file -> (firma, lista): rilegge solo se il file cambia
        if not os.path.exists(self.f_l):
            self._crea(self.f_l, CAMPI_L)
            for o, w, s, f in DATI_INIZIALI_L:
                self.aggiungi_lettura(Lettura(parse(o), w, s, f))
        else:
            self._migra_letture()
        if not os.path.exists(self.f_e):
            self._crea(self.f_e, CAMPI_E)
            for o, t, x in DATI_INIZIALI_E:
                self.aggiungi_evento(Evento(parse(o), t, x))

    @staticmethod
    def _crea(path, campi):
        with open(path, "w", newline="", encoding="utf-8") as f:
            csv.writer(f, delimiter=";").writerow(campi)

    def _migra_letture(self):
        """Intestazione vecchia -> aggiunge colonne mancanti IN FONDO, righe vecchie vuote."""
        with open(self.f_l, newline="", encoding="utf-8") as f:
            righe = list(csv.reader(f, delimiter=";"))
        if not righe or righe[0][:len(CAMPI_L)] == CAMPI_L:
            return
        if righe[0] != CAMPI_L[:len(righe[0])]:
            return  # intestazione sconosciuta: non toccare
        n = len(CAMPI_L)
        fd, tmp = tempfile.mkstemp(dir=self.cartella, suffix=".csv")
        with os.fdopen(fd, "w", newline="", encoding="utf-8") as f:
            w = csv.writer(f, delimiter=";")
            w.writerow(CAMPI_L)
            for r in righe[1:]:
                w.writerow(r + [""] * (n - len(r)))
        os.replace(tmp, self.f_l)

    def aggiungi_lettura(self, l: Lettura):
        b = lambda v: "" if v is None else ("1" if v else "0")
        n = lambda v: "" if v is None else f"{v:g}"
        with open(self.f_l, "a", newline="", encoding="utf-8") as f:
            csv.writer(f, delimiter=";").writerow(
                [fmt(l.ora), n(l.sett), n(l.sess), l.fonte, b(l.al_pc), b(l.lavoro), l.modelli, l.skill])

    def aggiungi_evento(self, e: Evento):
        with open(self.f_e, "a", newline="", encoding="utf-8") as f:
            csv.writer(f, delimiter=";").writerow([fmt(e.ora), e.tipo, e.testo.replace("\n", " ")])

    def _da_cache(self, path, leggi):
        st = os.stat(path)
        firma = (st.st_mtime_ns, st.st_size)
        c = self._cache.get(path)
        if c is None or c[0] != firma:
            c = (firma, leggi())
            self._cache[path] = c
        return list(c[1])

    def letture(self) -> list[Lettura]:
        return self._da_cache(self.f_l, self._leggi_letture)

    def eventi(self) -> list[Evento]:
        return self._da_cache(self.f_e, self._leggi_eventi)

    def _leggi_letture(self) -> list[Lettura]:
        out = []
        with open(self.f_l, newline="", encoding="utf-8") as f:
            for r in csv.DictReader(f, delimiter=";"):
                try:
                    out.append(Lettura(parse(r["ora"]), _num(r["settimanale"]), _num(r["sessione"]),
                                       r.get("fonte") or "auto", _bool(r.get("al_pc")),
                                       r.get("lavoro") == "1",
                                       r.get("modelli") or "", r.get("skill") or ""))
                except (ValueError, KeyError):
                    continue
        return sorted(out, key=lambda x: x.ora)

    def _leggi_eventi(self) -> list[Evento]:
        out = []
        with open(self.f_e, newline="", encoding="utf-8") as f:
            for r in csv.DictReader(f, delimiter=";"):
                try:
                    out.append(Evento(parse(r["ora"]), r["tipo"], r.get("testo") or ""))
                except (ValueError, KeyError):
                    continue
        return sorted(out, key=lambda x: x.ora)

    def impostazioni(self) -> dict:
        d = json.loads(json.dumps(IMPOSTAZIONI_BASE))  # copia profonda (liste)
        try:
            with open(self.f_i, encoding="utf-8") as f:
                d.update(json.load(f))
        except (OSError, ValueError):
            pass
        return d

    def salva_impostazioni(self, d: dict):
        with open(self.f_i, "w", encoding="utf-8") as f:
            json.dump(d, f, indent=2)


def adesso() -> datetime:
    return datetime.now().replace(second=0, microsecond=0)
