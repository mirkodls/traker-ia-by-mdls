"""Contenitori per il ridimensionamento (P4): area con scorrimento e barra che va a capo."""
from __future__ import annotations

import tkinter as tk
from tkinter import ttk

from domain import vista as V


class Scorrevole(tk.Frame):
    """Contenuto alto quanto la finestra; se non entra (finestra piccola) compare la barra a destra.
    Cosi' niente viene tagliato: si scorre."""

    def __init__(self, padre, bg):
        super().__init__(padre, bg=bg)
        self.cv = tk.Canvas(self, bg=bg, highlightthickness=0, bd=0)
        self.sb = ttk.Scrollbar(self, orient="vertical", command=self.cv.yview)
        self.cv.configure(yscrollcommand=self.sb.set)
        self.cv.pack(side="left", fill="both", expand=True)
        self.dentro = tk.Frame(self.cv, bg=bg)
        self._win = self.cv.create_window(0, 0, window=self.dentro, anchor="nw")
        self._in_coda = False
        self.cv.bind("<Configure>", lambda e: self.aggiorna())
        self.winfo_toplevel().bind("<Configure>", lambda e: self.aggiorna(), add="+")
        for ev in ("<MouseWheel>", "<Button-4>", "<Button-5>"):
            self.winfo_toplevel().bind_all(ev, self._rotella, add="+")

    def aggiorna(self):
        if not self._in_coda:
            self._in_coda = True
            self.after_idle(self._adatta)

    def _adatta(self):
        self._in_coda = False
        cw, ch = self.cv.winfo_width(), self.cv.winfo_height()
        if cw <= 1 or ch <= 1:
            return
        req = self.dentro.winfo_reqheight()
        h = max(ch, req)
        self.cv.itemconfigure(self._win, width=cw, height=h)
        self.cv.configure(scrollregion=(0, 0, cw, h))
        serve = req > ch + 1
        if serve and not self.sb.winfo_ismapped():
            self.sb.pack(side="right", fill="y", before=self.cv)
        elif not serve and self.sb.winfo_ismapped():
            self.sb.pack_forget()
            self.cv.yview_moveto(0)

    def _rotella(self, ev):
        if not self.sb.winfo_ismapped() or not isinstance(ev.widget, tk.Misc):
            return
        if isinstance(ev.widget, tk.Listbox) or ev.widget.winfo_toplevel() is not self.winfo_toplevel():
            return
        passi = -1 if (getattr(ev, "num", 0) == 4 or ev.delta > 0) else 1
        self.cv.yview_scroll(passi * 3, "units")


class Flusso(tk.Frame):
    """Barra che va a capo se stretta. gruppi() = liste di widget figli (vedi domain.vista.disponi):
    il 2o gruppo sta a destra sulla stessa riga se c'e' posto, altrimenti sotto."""

    def __init__(self, padre, bg, spazio=4, larg_fissa: int | None = None):
        super().__init__(padre, bg=bg, height=1)
        self.spazio, self.larg_fissa = spazio, larg_fissa
        self._gruppi: list[list[tk.Widget]] | None = None
        self._in_coda = False
        self.bind("<Configure>", lambda e: self.aggiorna())

    def gruppi(self, g: list[list[tk.Widget]] | None):
        """None = tutti i figli in un gruppo solo."""
        self._gruppi = g
        self.aggiorna()

    def aggiorna(self):
        if not self._in_coda:
            self._in_coda = True
            self.after_idle(self._disponi)

    def _disponi(self):
        self._in_coda = False
        if not self.winfo_exists():
            return
        g = self._gruppi
        if g is None:
            g = [list(self.winfo_children())]
        g = [[w for w in grp if w.winfo_exists()] for grp in g]
        larg = self.larg_fissa or self.winfo_width()
        if larg <= 1:
            larg = sum(w.winfo_reqwidth() + self.spazio for grp in g for w in grp)
        pos = V.disponi([[w.winfo_reqwidth() for w in grp] for grp in g], larg, self.spazio)
        alte: dict[int, int] = {}
        for gi, i, _, r in pos:
            alte[r] = max(alte.get(r, 0), g[gi][i].winfo_reqheight())
        y_riga, y = {}, 0
        for r in sorted(alte):
            y_riga[r] = y
            y += alte[r] + self.spazio
        for gi, i, x, r in pos:
            w = g[gi][i]
            w.place(x=x, y=y_riga[r] + (alte[r] - w.winfo_reqheight()) // 2)
        h = max(1, y - self.spazio)
        if self.larg_fissa:
            self.configure(width=self.larg_fissa)
        if int(self.cget("height")) != h:
            self.configure(height=h)
