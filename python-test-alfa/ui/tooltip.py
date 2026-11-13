"""Tooltip riutilizzabile (P6): popup con spiegazione dopo ~400 ms di mouse fermo sul widget.
Stessa finestrella senza bordi del grafico (P5): sempre dentro lo schermo (domain.riordino)."""
from __future__ import annotations

import contextlib
import tkinter as tk
from typing import Callable, Union

from domain import riordino as P
from ui import tema as T

RITARDO_MS = 400
LARGHEZZA = 340


class Tooltip:
    def __init__(self, widget: tk.Widget, testo: Union[str, Callable[[], str]], ritardo: int = RITARDO_MS):
        self.w, self.testo, self.ritardo = widget, testo, ritardo
        self._job = None
        self._top: tk.Toplevel | None = None
        widget.bind("<Enter>", self._entra, add="+")
        widget.bind("<Leave>", self._esci, add="+")
        widget.bind("<ButtonPress>", self._esci, add="+")
        widget.bind("<Destroy>", self._esci, add="+")

    def _entra(self, e):
        self._annulla()
        self._job = self.w.after(self.ritardo, self._mostra, e.x_root, e.y_root)

    def _esci(self, _e=None):
        self._annulla()
        if self._top is not None and self._top.winfo_exists():
            self._top.destroy()
        self._top = None

    def _annulla(self):
        if self._job is not None:
            with contextlib.suppress(tk.TclError):
                self.w.after_cancel(self._job)
            self._job = None

    def _mostra(self, x, y):
        self._job = None
        t = self.testo() if callable(self.testo) else self.testo
        if not t or not self.w.winfo_exists():
            return
        top = tk.Toplevel(self.w)
        top.overrideredirect(True)
        top.attributes("-topmost", True)
        tk.Label(top, text=t, bg=T.CARTA2, fg=T.TESTO, font=T.F_PICCOLO, justify="left", anchor="w",
                 padx=10, pady=8, wraplength=LARGHEZZA, highlightthickness=1,
                 highlightbackground=T.SPENTO).pack()
        top.update_idletasks()
        w, h = top.winfo_reqwidth(), top.winfo_reqheight()
        px, py, _ = P.posiziona_riquadro(x, y, w, h, self.w.winfo_screenwidth(), self.w.winfo_screenheight())
        top.geometry(f"+{int(max(0, px))}+{int(max(0, py))}")
        self._top = top


def metti(widget: tk.Widget, testo: Union[str, Callable[[], str]]) -> Tooltip:
    """Aggancia un tooltip a un widget. testo puo' essere una funzione (valutata al momento di mostrarlo)."""
    return Tooltip(widget, testo)
