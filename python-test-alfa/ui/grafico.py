"""Grafico su Canvas: area settimanale, linea sessione, reset, note (testo intero col mouse)."""
from __future__ import annotations

import tkinter as tk
from datetime import datetime, timedelta

from domain import analisi as A
from domain import combinazioni as C
from domain import riordino as P
from ui import tema as T

GIORNI = ["lun", "mar", "mer", "gio", "ven", "sab", "dom"]


def giorno(d: datetime) -> str:
    return GIORNI[d.weekday()]


class Grafico:
    def __init__(self, padre, padre_int=None):
        # altezze = minime (P4): il grafico grande poi prende lo spazio libero
        self.cv = tk.Canvas(padre, bg=T.CARTA, highlightthickness=0, height=T.px(220))
        self.cv_int = tk.Canvas(padre_int or padre, bg=T.CARTA, highlightthickness=0, height=T.px(90))
        self.note_x: list[tuple[float, float, A.Evento]] = []
        self.cv.bind("<Motion>", self._mouse)
        self.cv.bind("<Leave>", lambda e: self._esci())
        self.cv_int.bind("<Motion>", lambda e: self._hover(e, self.cv_int))
        self.cv_int.bind("<Leave>", lambda e: self._esci())
        self._tip = None  # finestrella senza bordi quando il riquadro non entra nel grafico
        self._tip_lbl = None
        self._job_int = None
        self.cv_int.bind("<Configure>", lambda e: self._int_dopo())
        self._ult_int = None
        self._dati = None  # (letture, da, a) dell'ultimo disegno
        self._geo = {}     # canvas -> (L, R) margini sinistro/destro

    def disegna(self, letture, eventi, da: datetime, a: datetime, ora: datetime):
        cv = self.cv
        cv.delete("all")
        self.note_x = []
        W, H = cv.winfo_width(), cv.winfo_height()
        self._dati = (letture, da, a)
        if W < T.px(80) or H < T.px(80):  # grafico grande chiuso/nascosto: l'intensita' si disegna lo stesso
            self._geo.pop(cv, None)
            self.intensita(letture, da, a)
            return
        L, R, T_, B = T.px(48), T.px(18), T.px(46), T.px(30)
        self._geo[cv] = (L, R)
        span = (a - da).total_seconds() or 1
        X = lambda d: L + (d - da).total_seconds() / span * (W - L - R)
        Y = lambda v: T_ + (1 - v / 100) * (H - T_ - B)
        dentro = lambda d: da <= d <= a

        # legenda
        lx = L
        for testo, col in (("Settimana", T.SETT), ("Sessione 5h", T.SESS), ("Nota", T.NOTA),
                           ("Reset", T.RESET), ("Lavoro", "#1f5e3b")):
            cv.create_oval(lx, 12, lx + 10, 22, fill=col, outline="")
            cv.create_text(lx + 15, 17, text=testo, anchor="w", fill=T.SPENTO, font=T.F_PICCOLO)
            lx += 30 + len(testo) * 7

        # fasce lavoro
        ini = None
        for e in eventi:
            if e.tipo == "inizio":
                ini = e.ora
            elif e.tipo == "fine" and ini:
                self._fascia(X, da, a, ini, e.ora, T_, H - B)
                ini = None
        if ini:
            self._fascia(X, da, a, ini, ora, T_, H - B)

        # griglia
        for v in range(0, 101, 25):
            cv.create_line(L, Y(v), W - R, Y(v), fill=T.GRIGLIA)
            cv.create_text(L - 8, Y(v), text=f"{v}%", anchor="e", fill=T.SPENTO, font=T.F_PICCOLO)
        corto = span <= 26 * 3600
        n = max(2, min(7, (W - L - R) // 110))
        for i in range(n + 1):
            d = da + timedelta(seconds=span * i / n)
            t = d.strftime("%H:%M") if corto else f"{giorno(d)} {d:%d} {d:%H:%M}"
            cv.create_text(X(d), H - B + 15, text=t, fill=T.SPENTO, font=T.F_PICCOLO)

        # reset
        resets = set(A.trova_reset(letture, "sett")) | set(A.trova_reset(letture, "sess"))
        resets |= {e.ora for e in eventi if e.tipo == "reset"}
        for r in resets:
            if dentro(r):
                cv.create_line(X(r), T_, X(r), H - B, fill=T.RESET, dash=(3, 4))

        # serie
        for campo, col, area in (("sett", T.SETT, True), ("sess", T.SESS, False)):
            pts = [p for p in letture if getattr(p, campo) is not None]
            prima = [p for p in pts if p.ora < da][-1:]
            dopo = [p for p in pts if p.ora > a][:1]
            serie = prima + [p for p in pts if dentro(p.ora)] + dopo
            if len(serie) < 1:
                continue
            xy = []
            for p in serie:
                xy += [min(max(X(p.ora), L), W - R), Y(getattr(p, campo))]
            if area and len(serie) > 1:
                cv.create_polygon([xy[0], Y(0)] + xy + [xy[-2], Y(0)], fill=T.SETT_AREA, outline="")
            if len(serie) > 1:
                cv.create_line(*xy, fill=col, width=T.px(2), capstyle="round", joinstyle="round")
            for p in serie:
                if dentro(p.ora) and p.fonte != "auto":
                    x, y = X(p.ora), Y(getattr(p, campo))
                    cv.create_oval(x - 3.5, y - 3.5, x + 3.5, y + 3.5, outline=col, fill=T.CARTA, width=1.5)
            ult = [p for p in serie if dentro(p.ora)][-1:]
            if ult:
                p = ult[0]
                x, y = X(p.ora), Y(getattr(p, campo))
                cv.create_oval(x - 7, y - 7, x + 7, y + 7, fill="", outline=col, width=1)
                cv.create_oval(x - 4, y - 4, x + 4, y + 4, fill=col, outline="")
                cv.create_text(x - 10, y - 12, text=f"{getattr(p, campo):g}%", anchor="e", fill=col,
                               font=T.F_TITOLO)

        # note: linea + numero in cerchio; testo intero col mouse
        num = 0
        for e in eventi:
            if e.tipo != "nota":
                continue
            num += 1
            if not dentro(e.ora):
                continue
            x = X(e.ora)
            livello = sum(1 for nx, _, _ in self.note_x if abs(nx - x) < 20)  # note vicine: scendi
            cy = T_ - 9 + livello * 21
            cv.create_line(x, T_ - 8, x, H - B, fill=T.NOTA, width=1.5, dash=(6, 3))
            cv.create_oval(x - 9, cy - 9, x + 9, cy + 9, fill=T.NOTA, outline=T.CARTA, width=2)
            cv.create_text(x, cy, text=str(num), fill="white", font=(T.F, 8, "bold"))
            self.note_x.append((x, cy, e))
        self.intensita(letture, da, a)
        if W - R - lx > 300:  # finestra stretta: niente scritta sopra la legenda
            cv.create_text(W - R, 17, text="passa il mouse sui numeri viola per leggere la nota",
                           anchor="e", fill=T.RESET, font=(T.F, 8))

    def _int_dopo(self):
        """Ridimensionamento: ridisegna una volta quando il mouse si ferma (niente scatti)."""
        if self._job_int:
            self.cv_int.after_cancel(self._job_int)
        self._job_int = self.cv_int.after(80, self._ridisegna_int)

    def _ridisegna_int(self):
        self._job_int = None
        if self._ult_int:
            self.intensita(*self._ult_int)

    def intensita(self, letture, da: datetime, a: datetime):
        """Grafico piccolo: ritmo pt%/h barra 5h, media mobile 30 min. Stessa linea del tempo."""
        self._ult_int = (letture, da, a)
        cv = self.cv_int
        cv.delete("all")
        W, H = cv.winfo_width(), cv.winfo_height()
        if W < T.px(80) or H < T.px(40):
            self._geo.pop(cv, None)
            return
        L, R, T_, B = T.px(48), T.px(18), T.px(20), T.px(8)
        self._geo[cv] = (L, R)
        span = (a - da).total_seconds() or 1
        X = lambda d: L + (d - da).total_seconds() / span * (W - L - R)
        passo = max(5, int(span / 60 / 240))  # max ~240 punti
        serie = A.serie_intensita(letture, da, a, passo, 30)
        vals = [v for _, v in serie if v is not None]
        top = max(vals + [1.0])
        Y = lambda v: T_ + (1 - v / top) * (H - T_ - B)
        cv.create_text(L, 9, text="Intensità (pt%/h, barra 5h, media 30 min)", anchor="w",
                       fill=T.SPENTO, font=T.F_PICCOLO)
        for v in (0, top):
            cv.create_line(L, Y(v), W - R, Y(v), fill=T.GRIGLIA)
            cv.create_text(L - 8, Y(v), text=f"{v:.0f}", anchor="e", fill=T.SPENTO, font=T.F_PICCOLO)
        seg: list[float] = []
        for d, v in serie + [(a, None)]:
            if v is None:
                if len(seg) >= 4:
                    cv.create_line(*seg, fill=T.SESS, width=T.px(2), capstyle="round", joinstyle="round")
                seg = []
            else:
                seg += [X(d), Y(v)]

    def _fascia(self, X, da, a, ini, fin, y0, y1):
        ini, fin = max(ini, da), min(fin, a)
        if fin > ini:
            self.cv.create_rectangle(X(ini), y0, X(fin), y1, fill=T.LAVORO, outline="")

    def _mouse(self, ev):
        cv = self.cv
        self._pulisci()
        vicine = [((x - ev.x) ** 2 + (y - ev.y) ** 2, x, e) for x, y, e in self.note_x
                  if abs(x - ev.x) < 12 and abs(y - ev.y) < 12]
        if not vicine:  # lungo la linea: prendi la più vicina in orizzontale
            vicine = [(abs(x - ev.x), x, e) for x, _, e in self.note_x if abs(x - ev.x) < 6]
        if not vicine:
            self._hover(ev, cv)
            return
        _, x, e = min(vicine, key=lambda t: t[0])
        testo = f"{giorno(e.ora)} {e.ora:%d/%m %H:%M}\n{e.testo}"
        self._riquadro(cv, testo, x, ev, T.NOTA, larghezza=280)

    def _pulisci(self):
        for c in (self.cv, self.cv_int):
            c.delete("tip")
            c.delete("hov")

    def _esci(self):
        self._pulisci()
        self._chiudi_tip()

    @staticmethod
    def _righe_stato(letture, t) -> list[str]:
        st = C.stato_a(letture, t)
        if st is None:
            return []
        m, s = st
        return [f"Modelli: {m.replace('|', ', ') or '—'}", f"Skill: {s.replace('|', ', ') or '—'}"]

    def _hover(self, ev, cv):
        """Linea verticale su entrambi i grafici + riquadro: ora, % sett, % 5h, pt/h.
        Sopra una lettura vera: numero esatto. Tra due letture: valore interpolato con '~'."""
        self._pulisci()
        if not self._dati or cv not in self._geo:
            self._chiudi_tip()
            return
        letture, da, a = self._dati
        L, R = self._geo[cv]
        W = cv.winfo_width()
        larg = W - L - R
        if larg <= 0 or not (L <= ev.x <= W - R):
            self._chiudi_tip()
            return
        span = (a - da).total_seconds() or 1
        sec_px = span / larg
        t = da + timedelta(seconds=(ev.x - L) * sec_px)
        # aggancio alla lettura vera se il mouse e' a <= 6 px
        for l in letture:
            if abs((l.ora - t).total_seconds()) <= 6 * sec_px and da <= l.ora <= a:
                t = l.ora
                break
        sett, e1 = A.valore_a(letture, "sett", t)
        sess, e2 = A.valore_a(letture, "sess", t)
        inte = A.intensita_a(letture, t)
        riga = lambda nome, v, ok, u: (f"{nome}: " + ("—" if v is None else
                                                      f"{'' if ok else '~'}{v:.1f}{u}"))
        testo = "\n".join([f"{giorno(t)} {t:%d/%m %H:%M}",
                           riga("Sett", sett, e1, "%"),
                           riga("5h", sess, e2, "%"),
                           riga("Intensità", inte, e2, " pt/h")]
                          + self._righe_stato(letture, t))
        for c in (self.cv, self.cv_int):
            if c not in self._geo:
                continue
            cL, cR = self._geo[c]
            cW, cH = c.winfo_width(), c.winfo_height()
            x = cL + (t - da).total_seconds() / span * (cW - cL - cR)
            c.create_line(x, 0, x, cH, fill=T.SPENTO, dash=(2, 3), tags="hov")
        x = L + (t - da).total_seconds() / span * larg
        self._riquadro(cv, testo, x, ev, T.SPENTO)

    def _riquadro(self, cv, testo, x, ev, bordo, larghezza=None):
        """Riquadro sempre tutto visibile (P5): nel canvas se entra (destra/sotto, altrimenti sinistra/sopra),
        se il grafico e' troppo piccolo in una finestrella senza bordi vicino al mouse."""
        opz = {"width": larghezza} if larghezza else {}
        tx = cv.create_text(0, 0, text=testo, anchor="nw", fill=T.TESTO, font=T.F_NORMALE, tags="tip", **opz)
        x0, y0, x1, y1 = cv.bbox(tx)
        w, h = x1 - x0 + 16, y1 - y0 + 12
        px, py, entra = P.posiziona_riquadro(x, ev.y, w, h, cv.winfo_width(), cv.winfo_height())
        if not entra:
            cv.delete(tx)
            self._finestrella(cv, testo, ev, bordo, larghezza)
            return
        self._chiudi_tip()
        cv.coords(tx, px + 8, py + 6)
        r = cv.create_rectangle(px, py, px + w, py + h, fill=T.CARTA2, outline=bordo, tags="tip")
        cv.tag_raise(tx, r)

    def _finestrella(self, cv, testo, ev, bordo, larghezza):
        if self._tip is None or not self._tip.winfo_exists():
            top = tk.Toplevel(cv)
            top.overrideredirect(True)
            top.attributes("-topmost", True)
            lbl = tk.Label(top, bg=T.CARTA2, fg=T.TESTO, font=T.F_NORMALE, justify="left", padx=8, pady=6,
                           highlightthickness=1)
            lbl.pack()
            self._tip, self._tip_lbl = top, lbl
        self._tip_lbl.config(text=testo, wraplength=larghezza or 0, highlightbackground=bordo)
        self._tip.update_idletasks()
        w, h = self._tip.winfo_reqwidth(), self._tip.winfo_reqheight()
        sw, sh = cv.winfo_screenwidth(), cv.winfo_screenheight()
        px, py, _ = P.posiziona_riquadro(ev.x_root, ev.y_root, w, h, sw, sh)
        self._tip.geometry(f"+{int(max(0, px))}+{int(max(0, py))}")
        self._tip.deiconify()

    def _chiudi_tip(self):
        if self._tip is not None and self._tip.winfo_exists():
            self._tip.withdraw()
