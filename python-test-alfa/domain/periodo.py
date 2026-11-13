"""Cursore periodo del grafico: scatto -> intervallo (pura, niente tkinter)."""
from __future__ import annotations

from datetime import datetime, timedelta

# (etichetta, ore) ; ore None = caso speciale (Settimana, Tutto)
SCATTI = [("2 ore", 2), ("6 ore", 6), ("12 ore", 12), ("24 ore", 24), ("3 giorni", 72),
          ("Settimana", None), ("7 giorni", 168), ("Tutto", None)]
SETTIMANA = 5
TUTTO = 7
PREDEFINITO = SETTIMANA


def normalizza(i) -> int:
    """Indice valido 0..7; dato strano (non int, bool, fuori range) -> predefinito."""
    if isinstance(i, bool) or not isinstance(i, int) or not 0 <= i < len(SCATTI):
        return PREDEFINITO
    return i


def etichetta(i) -> str:
    return SCATTI[normalizza(i)][0]


def intervallo(i, ora: datetime, inizio_sett: datetime,
               primo_dato: datetime | None) -> tuple[datetime, datetime]:
    """(da, a) per lo scatto i. Settimana = da ultimo reset; Tutto = dal primo dato.
    Settimana/Tutto: almeno 1 ora di larghezza."""
    i = normalizza(i)
    ore = SCATTI[i][1]
    if ore is not None:
        return ora - timedelta(hours=ore), ora
    ini = inizio_sett if i == SETTIMANA else (primo_dato or ora - timedelta(days=1))
    return ini, max(ora, ini + timedelta(hours=1))
