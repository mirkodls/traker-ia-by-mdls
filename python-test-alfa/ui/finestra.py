"""Finestra (tkinter): stato attuale, note, lavoro, grafico, analisi."""
from __future__ import annotations

import contextlib
import threading
import tkinter as tk
from datetime import datetime, timedelta
from tkinter import messagebox, ttk

from data import catena, fonte, ricevitore, sistema
from data.archivio import Archivio, adesso
from domain import analisi as A
from domain import combinazioni as C
from domain import confronti as K
from domain import lavoro as LV
from domain import periodo as PE
from domain import previsione as PR
from domain import riordino as RI
from domain import vista as V
from ui import tema as T
from ui import tooltip as TP
from ui.grafico import Grafico, giorno
from ui.layout import Flusso, Scorrevole

COL_VERDETTO = {"sceso": T.OK, "salito": T.ERRORE, "costante": T.SETT}
ATTIVI = {"modelli": "modelli_attivi", "skill": "skill_attive"}
COL_TASTO = {"modelli": T.ACCENTO, "skill": "#7c3aed"}
TITOLI = {"carte": "USO ATTUALE", "grafico": "GRAFICO", "intensita": "INTENSITÀ",
          "barra": "SKILL / MODELLI · NOTA", "dati": "COSA DICONO I DATI", "confronti": "CONFRONTI"}


def durata(td: timedelta) -> str:
    m = max(0, int(td.total_seconds() // 60))
    return f"{m // 60}h {m % 60:02d}m" if m >= 60 else f"{m}m"


class App:
    def __init__(self, root: tk.Tk, cartella_dati: str):
        self.root, self.arch = root, Archivio(cartella_dati)
        self.imp = self.arch.impostazioni()
        self.vista = V.normalizza(self.imp.get("vista"))
        self.al_pc = False
        self.lavoro = self._stato_lavoro()
        self.ultimo_uso: A.Uso | None = None
        self.in_lettura = False
        self.ultima_edge: datetime | None = None
        self.fallite, self.avvisato = 0, False
        self.srv = ricevitore.avvia(lambda d: self.root.after(0, self._da_edge, d),
                                    lambda: self.imp.get("minuti", 10))

        root.title("Traker uso Claude")
        T.scala(root)
        root.geometry(f"{T.px(1040)}x{min(T.px(960), root.winfo_screenheight() - 90)}")
        root.minsize(T.px(420), T.px(300))
        T.applica(root)
        self._costruisci()
        self._applica_vista(salva=False)
        self.ridisegna()
        T.barra_titolo_scura(root)
        root.after(1500, self.leggi)
        root.after(1000, self._controlla_presenza)
        self._programma()

    # ---------- interfaccia ----------
    def _carta(self, padre, **pack):
        f = tk.Frame(padre, bg=T.CARTA, highlightthickness=1, highlightbackground=T.BORDO)
        f.pack(**pack)
        return f

    @staticmethod
    def _avvolgi(lbl, padre, meno=28):
        """Testo che va a capo con la larghezza (niente righe tagliate)."""
        padre.bind("<Configure>", lambda e: lbl.config(wraplength=max(80, e.width - meno)), add="+")

    def _sezione(self, nome) -> tk.Frame:
        f = tk.Frame(self.cont, bg=T.SFONDO)
        tit = tk.Label(f, text="", bg=T.SFONDO, fg=T.SPENTO, font=T.F_SEZIONE, cursor="hand2", anchor="w")
        tit.bind("<Button-1>", lambda e: self._vista(V.cambia_aperta(self.vista, nome)))
        corpo = tk.Frame(f, bg=T.SFONDO)
        self.sez[nome] = {"f": f, "tit": tit, "corpo": corpo}
        return corpo

    def _costruisci(self):
        r = self.root
        self.sez: dict[str, dict] = {}
        self.scorr = Scorrevole(r, T.SFONDO)
        self.scorr.pack(fill="both", expand=True)
        self.cont = tk.Frame(self.scorr.dentro, bg=T.SFONDO)
        self.cont.pack(fill="both", expand=True, padx=14, pady=(8, 4))

        # --- carte % + tasti ---
        corpo = self._sezione("carte")
        self.alto = tk.Frame(corpo, bg=T.SFONDO)
        self.alto.pack(fill="x")
        self.alto.columnconfigure((0, 1), weight=1, uniform="carte")
        self.carte = {}
        for i, (chiave, titolo, col) in enumerate((("sess", "SESSIONE 5 ORE", T.SESS), ("sett", "SETTIMANA", T.SETT))):
            c = tk.Frame(self.alto, bg=T.CARTA, highlightthickness=1, highlightbackground=T.BORDO)
            c.grid(row=0, column=i, sticky="new", padx=(0, 8))
            riga = tk.Frame(c, bg=T.CARTA)
            riga.pack(fill="x", padx=12, pady=(6, 3))
            val = tk.Label(riga, text="-", bg=T.CARTA, fg=col, font=T.F_CARTA)
            val.pack(side="left")
            dx = tk.Frame(riga, bg=T.CARTA)
            dx.pack(side="left", fill="x", expand=True, padx=(10, 0))
            tl = tk.Label(dx, text=titolo, bg=T.CARTA, fg=T.SPENTO, font=T.F_TITOLO, anchor="w", justify="left")
            tl.pack(fill="x")
            self._avvolgi(tl, dx, 4)
            sotto = tk.Label(dx, text="", bg=T.CARTA, fg=T.SPENTO, font=T.F_PICCOLO, justify="left", anchor="w")
            sotto.pack(fill="x")
            self._avvolgi(sotto, dx, 4)
            barra = tk.Canvas(c, height=T.px(4), bg=T.CARTA, highlightthickness=0)
            barra.pack(fill="x", padx=12, pady=(0, 8))
            barra.bind("<Configure>", lambda e, k=chiave: self._barra(k))
            self.carte[chiave] = {"val": val, "barra": barra, "sotto": sotto, "col": col, "pct": None, "f": c}
        self.tasti = Flusso(self.alto, T.SFONDO, spazio=6)
        for testo, cmd in (("Leggi ora", self.leggi), ("Lettura manuale", self.dlg_manuale),
                           ("Impostazioni", self.dlg_impostazioni), ("Vista ▾", self.menu_vista)):
            self.btn_vista = ttk.Button(self.tasti, text=testo, command=cmd)
        self._alto_largo = None
        self.alto.bind("<Configure>", self._disponi_alto)
        st = tk.Frame(corpo, bg=T.SFONDO)
        st.pack(fill="x", pady=(6, 0))
        self.pallino = tk.Canvas(st, width=10, height=10, bg=T.SFONDO, highlightthickness=0)
        self.pallino.pack(side="left", padx=(2, 6))
        self.lbl_stato = tk.Label(st, text="", bg=T.SFONDO, fg=T.SPENTO, font=T.F_PICCOLO, justify="left", anchor="w")
        self.lbl_stato.pack(side="left", fill="x", expand=True)
        self._avvolgi(self.lbl_stato, st, 24)

        # --- grafico grande + intensita (sezioni separate, stessa asse tempo) ---
        gc = self._carta(self._sezione("grafico"), fill="both", expand=True)
        ic = self._carta(self._sezione("intensita"), fill="both", expand=True)
        self.sel = Flusso(gc, T.CARTA, spazio=4)
        self.sel.pack(fill="x", padx=10, pady=(8, 0))
        tk.Label(self.sel, text="Periodo", bg=T.CARTA, fg=T.SPENTO, font=T.F_TITOLO, padx=4)
        self.scatto = tk.IntVar(value=PE.normalizza(self.imp.get("periodo")))
        self._job_per = None
        self.cur_periodo = tk.Scale(
            self.sel, from_=0, to=len(PE.SCATTI) - 1, orient="horizontal", showvalue=False,
            variable=self.scatto, length=240, sliderlength=18, width=14, bd=0, highlightthickness=0,
            bg=T.CARTA, troughcolor=T.CARTA2, activebackground=T.ACCENTO,
            command=lambda v: self._cambia_periodo())
        self.lbl_periodo = tk.Label(self.sel, text=PE.etichetta(self.scatto.get()), bg=T.CARTA,
                                    fg=T.ACCENTO, font=T.F_TITOLO, width=10, anchor="w")
        self.graf = Grafico(gc, ic)
        self.graf.cv.pack(fill="both", expand=True, padx=6, pady=6)
        self.graf.cv_int.pack(fill="both", expand=True, padx=6, pady=6)
        self._job_graf = None
        self.graf.cv.bind("<Configure>", lambda e: self._grafico_dopo(), add="+")

        # --- skill (sinistra) + modelli (destra) + nota/lavoro ---
        corpo = self._sezione("barra")
        pm = self._carta(corpo, fill="x", pady=(0, 6))
        self.ms = Flusso(pm, T.CARTA, spazio=4)
        self.ms.pack(fill="x", padx=10, pady=8)
        self._disegna_tasti()
        bar = self._carta(corpo, fill="x")
        dentro = tk.Frame(bar, bg=T.CARTA)
        dentro.pack(fill="x", padx=10, pady=8)
        tk.Label(dentro, text="✎", bg=T.CARTA, fg=T.NOTA, font=(T.F, 13)).pack(side="left", padx=(2, 6))
        self.btn_lav = tk.Label(dentro, width=13, font=T.F_TITOLO, cursor="hand2", pady=6)
        self.btn_lav.pack(side="right", padx=(8, 0))
        self.btn_lav.bind("<Button-1>", lambda e: self.cambia_lavoro())
        ttk.Button(dentro, text="Aggiungi nota", style="Accento.TButton",
                   command=self.aggiungi_nota).pack(side="right")
        self.ent_nota = ttk.Entry(dentro, width=8)
        self.ent_nota.pack(side="left", fill="x", expand=True, padx=(0, 8))
        self.ent_nota.bind("<Return>", lambda e: self.aggiungi_nota())
        self._aggiorna_btn_lavoro()

        # --- cosa dicono i dati (previsione, budget) ---
        cd = self._carta(self._sezione("dati"), fill="x")
        self.lbl_dati = tk.Label(cd, text="", bg=T.CARTA, fg=T.TESTO, font=T.F_NORMALE, justify="left", anchor="w")
        self.lbl_dati.pack(fill="x", padx=12, pady=10)
        self._avvolgi(self.lbl_dati, cd)

        # --- confronti (P6): carta unica compatta, ogni numero ha il suo tooltip ---
        an = self._carta(self._sezione("confronti"), fill="x")
        th = tk.Frame(an, bg=T.CARTA)
        th.pack(fill="x", padx=12, pady=(8, 0))
        tk.Label(th, text="CONFRONTI", bg=T.CARTA, fg=T.SPENTO, font=T.F_TITOLO).pack(side="left")
        info = tk.Label(th, text="ⓘ", bg=T.CARTA, fg=T.ACCENTO, font=T.F_TITOLO, padx=6, cursor="question_arrow")
        info.pack(side="left")
        TP.metti(info, K.COME_LEGGERE)

        def lab(padre, testo="", spiega=None, fg=T.TESTO, font=T.F_NORMALE):
            lb = tk.Label(padre, text=testo, bg=T.CARTA, fg=fg, font=font)
            if spiega:
                TP.metti(lb, spiega)
            return lb

        self._cn = None          # ConfrontoNota attuale
        self._cc = None          # ConfrontoCombo attuale
        self._sel_keys = [None, None]
        self._letture_c: list = []
        self._tab_c: dict = {}
        self._tab_usata: dict | None = None
        sp = T.F_PICCOLO
        r1 = Flusso(an, T.CARTA, spazio=6)
        r1.pack(fill="x", padx=12, pady=(4, 2))
        lab(r1, "Nota", fg=T.SPENTO, font=T.F_TITOLO)
        self.sel_nota = ttk.Combobox(r1, state="readonly", width=34)
        self.sel_nota.bind("<<ComboboxSelected>>", lambda e: self.analizza())
        self.n_prima = lab(r1, spiega=lambda: K.spiega_prima(self._cn) if self._cn else "")
        lab(r1, "→", fg=T.SPENTO)
        self.n_dopo = lab(r1, spiega=lambda: K.spiega_dopo(self._cn, adesso()) if self._cn else "")
        self.n_unita = lab(r1, spiega=lambda: f"{K.PTH}\n{K.SETT}\n{K.FRECCIA}" if self._cn else "")
        self.verdetto = lab(r1, spiega=lambda: K.spiega_verdetto(self._cn.verdetto) if self._cn else "",
                            font=T.F_TITOLO)
        self.n_ore = lab(r1, spiega=lambda: K.spiega_ore_nota() if self._cn else "", fg=T.SPENTO, font=sp)
        # P8: conta solo lavoro (vale per Nota e Combinazioni), salvata
        self.var_lavoro = tk.BooleanVar(value=bool(self.imp.get("solo_lavoro", False)))
        ck = tk.Checkbutton(r1, text="Conta solo lavoro", variable=self.var_lavoro, command=self._cambia_solo_lavoro,
                            bg=T.CARTA, fg=T.TESTO, selectcolor=T.CARTA2, activebackground=T.CARTA,
                            activeforeground=T.TESTO, font=sp, bd=0, highlightthickness=0, cursor="hand2")
        TP.metti(ck, K.SOLO_LAVORO)

        r2 = Flusso(an, T.CARTA, spazio=6)
        r2.pack(fill="x", padx=12, pady=(2, 2))
        lab(r2, "Combinazioni", fg=T.SPENTO, font=T.F_TITOLO)
        self.sel_c = []
        for i, nome in enumerate("AB"):
            if i:
                lab(r2, "vs", fg=T.SPENTO, font=sp)
            lab(r2, nome, fg=T.SPENTO, font=T.F_TITOLO)
            cb = ttk.Combobox(r2, state="readonly", width=24)
            cb.bind("<<ComboboxSelected>>", lambda e: self.analizza())
            self.sel_c.append(cb)
        self.c_a = lab(r2, spiega=lambda: self._spiega_combo(0))
        lab(r2, "·", fg=T.SPENTO)
        self.c_b = lab(r2, spiega=lambda: self._spiega_combo(1))
        self.c_unita = lab(r2, spiega=lambda: f"{K.PTH}\n{K.SETT}\n{K.FRECCIA}")
        self.verd_c = lab(r2, spiega=lambda: K.spiega_verdetto(self._cc.verdetto) if self._cc else "",
                          font=T.F_TITOLO)
        self.c_motivo = lab(r2, spiega=lambda: K.spiega_verdetto(K.DEBOLE), fg=T.SPENTO, font=sp)

        self.lbl_class = tk.Label(an, text="", bg=T.CARTA, fg=T.SPENTO, font=sp, justify="left", anchor="w")
        self.lbl_class.pack(fill="x", padx=12, pady=(4, 0))
        TP.metti(self.lbl_class, lambda: f"{K.PTH}\n{K.SETT}\nOre tra parentesi = letture usate per quel modello.")
        self.lbl_pres = tk.Label(an, text="", bg=T.CARTA, fg=T.SPENTO, font=sp, justify="left", anchor="w")
        self.lbl_pres.pack(fill="x", padx=12, pady=(0, 8))
        TP.metti(self.lbl_pres, lambda: f"{K.AL_PC}\n\n{K.PTH}")
        self._avvolgi(self.lbl_class, an, 24)
        self._avvolgi(self.lbl_pres, an, 24)
        self._combo_keys: list = []

        # tasto Vista sempre raggiungibile (anche con carte nascoste) + clic destro ovunque
        self.vista_flott = tk.Label(r, text="Vista ▾", bg=T.CARTA2, fg=T.TESTO, font=T.F_PICCOLO,
                                    padx=8, pady=3, cursor="hand2")
        self.vista_flott.bind("<Button-1>", lambda e: self.menu_vista(e))
        r.bind("<Button-3>", lambda e: self.menu_vista(e))

    def _disponi_alto(self, e):
        """Finestra larga: tasti in colonna a destra delle carte. Stretta: tasti sotto, a capo."""
        largo = e.width >= T.px(640)
        if largo == self._alto_largo:
            return
        self._alto_largo = largo
        self.tasti.grid_forget()
        if largo:
            w = [b.winfo_reqwidth() for b in self.tasti.winfo_children()]
            self.tasti.larg_fissa = max(w[0] + w[1], w[2] + w[3]) + self.tasti.spazio  # 2 x 2: carte basse
            self.tasti.grid(row=0, column=2, sticky="n")
            self.carte["sett"]["f"].grid_configure(padx=(0, 10))
        else:
            self.tasti.larg_fissa = None
            self.tasti.grid(row=1, column=0, columnspan=2, sticky="ew", pady=(6, 0))
            self.carte["sett"]["f"].grid_configure(padx=0)
        self.tasti.aggiorna()

    # ---------- vista (sezioni, solo-X, primo piano) ----------
    def _vista(self, nuova: dict):
        self.vista = nuova
        self._applica_vista()

    def _applica_vista(self, salva=True):
        v = self.vista
        for d in self.sez.values():
            d["f"].pack_forget()
        esp, titoli = V.chi_espande(v), V.con_titoli(v)
        mostrate = V.mostra(v)
        for nome, aperta in mostrate:
            d = self.sez[nome]
            d["tit"].pack_forget()
            d["corpo"].pack_forget()
            if titoli:
                d["tit"].config(text=("▾  " if aperta else "▸  ") + TITOLI[nome])
                d["tit"].pack(fill="x", pady=(0, 2))
            if aperta:
                d["corpo"].pack(fill="both" if nome == esp else "x", expand=nome == esp)
            d["f"].pack(fill="both" if nome == esp else "x", expand=nome == esp, pady=(0, 8))
        with contextlib.suppress(tk.TclError):
            self.root.attributes("-topmost", v["primo_piano"])
        if ("carte", True) in mostrate:
            self.vista_flott.place_forget()
        else:
            self.vista_flott.place(relx=1.0, x=-22, y=4, anchor="ne")
            self.vista_flott.lift()
        if salva:
            self.imp["vista"] = v
            self.arch.salva_impostazioni(self.imp)
        self.scorr.aggiorna()

    def menu_vista(self, ev=None):
        m = tk.Menu(self.root, tearoff=0, bg=T.CARTA2, fg=T.TESTO, activebackground=T.ACCENTO,
                    activeforeground="white", selectcolor=T.TESTO)
        self._var_menu = []
        for s in V.SEZIONI:
            var = tk.BooleanVar(value=V.spuntata(self.vista, s))
            self._var_menu.append(var)
            m.add_checkbutton(label=TITOLI[s].capitalize(), variable=var,
                              command=lambda s=s: self._vista(V.cambia_visibile(self.vista, s)))
        m.add_separator()
        for testo, modo in (("Solo grafico grande", "grafico"), ("Solo intensità", "intensita"), ("Tutto", "tutto")):
            m.add_command(label=testo, command=lambda modo=modo: self._vista(V.scegli_modo(self.vista, modo)))
        m.add_separator()
        pp = tk.BooleanVar(value=self.vista["primo_piano"])
        self._var_menu.append(pp)
        m.add_checkbutton(label="Sempre in primo piano", variable=pp,
                          command=lambda: self._vista(V.cambia_primo_piano(self.vista)))
        if ev is not None:
            x, y = ev.x_root, ev.y_root
        else:
            b = self.btn_vista
            x, y = b.winfo_rootx(), b.winfo_rooty() + b.winfo_height()
        try:
            m.tk_popup(x, y)
        finally:
            m.grab_release()

    def _cambia_periodo(self):
        """Cursore mosso: etichetta subito, grafico e salvataggio quando si ferma."""
        i = PE.normalizza(self.scatto.get())
        self.lbl_periodo.config(text=PE.etichetta(i))
        self._grafico_dopo()
        if self._job_per:
            self.root.after_cancel(self._job_per)
        self._job_per = self.root.after(400, self._salva_periodo)

    def _salva_periodo(self):
        self._job_per = None
        i = PE.normalizza(self.scatto.get())
        if self.imp.get("periodo") != i:
            self.imp["periodo"] = i
            self.arch.salva_impostazioni(self.imp)

    def _barra(self, k):
        c = self.carte[k]
        cv = c["barra"]
        cv.delete("all")
        w = cv.winfo_width()
        h = T.px(4)
        cv.create_rectangle(0, 0, w, h, fill=T.CARTA2, outline="")
        if c["pct"]:
            cv.create_rectangle(0, 0, max(h, w * min(c["pct"], 100) / 100), h, fill=c["col"], outline="")

    # ---------- modelli / skill ----------
    def _attivi(self, chiave) -> str:
        """Nomi attivi (solo quelli ancora in lista), 'A|B' normalizzato."""
        return C.unisci(n for n in self.imp.get(ATTIVI[chiave], []) if n in self.imp.get(chiave, []))

    def _disegna_tasti(self):
        """SKILL a sinistra, MODELLI a destra; se stretto vanno a capo (Flusso)."""
        for w in self.ms.winfo_children():
            w.destroy()
        gruppi = []
        self._drag = None
        self._tasti_w = {"skill": [], "modelli": []}
        for chiave, titolo in (("skill", "SKILL"), ("modelli", "MODELLI")):
            g = [tk.Label(self.ms, text=titolo, bg=T.CARTA, fg=T.SPENTO, font=T.F_TITOLO, padx=4)]
            on = set(self.imp.get(ATTIVI[chiave], []))
            for n in self.imp.get(chiave, []):
                acceso = n in on
                b = tk.Label(self.ms, text=("● " if acceso else "○ ") + n, font=T.F_PICCOLO, padx=10, pady=4,
                             cursor="hand2", bg=COL_TASTO[chiave] if acceso else T.CARTA2,
                             fg="white" if acceso else T.SPENTO)
                # clic = acceso/spento; trascinamento (> soglia) = cambia ordine (P5)
                b.bind("<ButtonPress-1>", lambda e, b=b: self._tasto_premi(e, b))
                b.bind("<B1-Motion>", lambda e, b=b: self._tasto_muovi(e, b))
                b.bind("<ButtonRelease-1>", lambda e, c=chiave, n=n: self._tasto_rilascia(e, c, n))
                self._tasti_w[chiave].append(b)
                g.append(b)
            m = tk.Label(self.ms, text="✎ modifica", font=T.F_PICCOLO, padx=8, pady=4, cursor="hand2",
                         bg=T.CARTA, fg=T.SPENTO)
            m.bind("<Button-1>", lambda e, c=chiave: self.dlg_modifica(c))
            g.append(m)
            gruppi.append(g)
        self.ms.gruppi(gruppi)

    def _tasto_premi(self, e, b):
        self._drag = {"b": b, "x0": e.x_root, "y0": e.y_root, "px": b.winfo_x(), "py": b.winfo_y(),
                      "mosso": False}

    def _tasto_muovi(self, e, b):
        d = self._drag
        if not d or d["b"] is not b:
            return
        dx, dy = e.x_root - d["x0"], e.y_root - d["y0"]
        if not d["mosso"]:
            if max(abs(dx), abs(dy)) <= RI.SOGLIA_TRASCINA:
                return
            d["mosso"] = True
            b.lift()
            b.config(cursor="fleur")
        b.place(x=d["px"] + dx, y=d["py"] + dy)

    def _tasto_rilascia(self, e, chiave, nome):
        d, self._drag = self._drag, None
        if not d:
            return
        if not d["mosso"]:
            self._cambia_tasto(chiave, nome)
            return
        lista = self.imp.get(chiave, [])
        if nome not in lista:
            self._disegna_tasti()
            return
        ws = self._tasti_w[chiave]
        centri = [(w.winfo_x() + w.winfo_width() / 2, w.winfo_y() + w.winfo_height() / 2) for w in ws]
        da = lista.index(nome)
        nuova = RI.sposta(lista, da, RI.indice_rilascio(centri, da, ws[da].winfo_height() / 2))
        if nuova != lista:
            self.imp[chiave] = nuova
            self.arch.salva_impostazioni(self.imp)
        self._disegna_tasti()

    def _cambia_tasto(self, chiave, nome):
        att = self.imp.setdefault(ATTIVI[chiave], [])
        if nome in att:
            att.remove(nome)
        else:
            att.append(nome)
        self.arch.salva_impostazioni(self.imp)
        self._disegna_tasti()

    def dlg_modifica(self, chiave):
        d = tk.Toplevel(self.root)
        d.title(f"Modifica {chiave}")
        d.configure(bg=T.SFONDO)
        d.transient(self.root)
        d.grab_set()
        lb = tk.Listbox(d, height=8, width=28, bg=T.CARTA2, fg=T.TESTO, selectbackground=T.ACCENTO,
                        highlightthickness=0, relief="flat", exportselection=False)
        lb.grid(row=0, column=0, rowspan=4, padx=8, pady=8, sticky="ns")
        ttk.Label(d, text="Nome").grid(row=0, column=1, sticky="w", padx=8, pady=(8, 0))
        ent = ttk.Entry(d, width=22)
        ent.grid(row=1, column=1, sticky="w", padx=8)
        ttk.Label(d, text="Rinomina vale da ora: le letture vecchie\ntengono il nome vecchio.",
                  foreground=T.SPENTO).grid(row=4, column=0, columnspan=2, sticky="w", padx=8, pady=(0, 8))
        lista, att = self.imp.setdefault(chiave, []), self.imp.setdefault(ATTIVI[chiave], [])

        def ricarica():
            lb.delete(0, "end")
            for n in lista:
                lb.insert("end", n)

        def sel():
            i = lb.curselection()
            return lista[i[0]] if i else None

        def scelto(_e=None):
            n = sel()
            if n:
                ent.delete(0, "end")
                ent.insert(0, n)

        lb.bind("<<ListboxSelect>>", scelto)

        def valido(n, vecchio=None):
            if not n or len(n) > 20 or any(c in n for c in "|;\n"):
                messagebox.showerror("Errore", "Nome vuoto, troppo lungo o con | ; dentro.", parent=d)
                return False
            if any(x.lower() == n.lower() and x != vecchio for x in lista):
                messagebox.showerror("Errore", "Nome già presente.", parent=d)
                return False
            return True

        def salva():
            self.arch.salva_impostazioni(self.imp)
            ricarica()
            self._disegna_tasti()

        def aggiungi():
            n = ent.get().strip()
            if valido(n):
                lista.append(n)
                salva()

        def rinomina():
            v, n = sel(), ent.get().strip()
            if not v:
                messagebox.showinfo("Rinomina", "Scegli prima un nome dalla lista.", parent=d)
                return
            if n != v and valido(n, v):
                lista[lista.index(v)] = n
                if v in att:
                    att[att.index(v)] = n
                salva()

        def togli():
            v = sel()
            if not v:
                messagebox.showinfo("Togli", "Scegli prima un nome dalla lista.", parent=d)
                return
            lista.remove(v)
            if v in att:
                att.remove(v)
            ent.delete(0, "end")
            salva()

        bt = tk.Frame(d, bg=T.SFONDO)
        bt.grid(row=2, column=1, sticky="nw", padx=8, pady=6)
        for testo, cmd in (("Aggiungi", aggiungi), ("Rinomina", rinomina), ("Togli", togli)):
            ttk.Button(bt, text=testo, command=cmd).pack(fill="x", pady=2)
        ttk.Button(d, text="Chiudi", command=d.destroy).grid(row=3, column=1, sticky="se", padx=8, pady=8)
        ricarica()

    def _stato_lavoro(self) -> bool:
        ev = [e for e in self.arch.eventi() if e.tipo in ("inizio", "fine")]
        return bool(ev) and ev[-1].tipo == "inizio"

    def _aggiorna_btn_lavoro(self):
        if self.lavoro:
            self.btn_lav.config(text="■  Fine lavoro", bg="#3b1d24", fg=T.ERRORE)
        else:
            self.btn_lav.config(text="▶  Inizio lavoro", bg="#123024", fg=T.OK)

    # ---------- azioni ----------
    def aggiungi_nota(self):
        t = self.ent_nota.get().strip()
        if not t:
            return
        self.arch.aggiungi_evento(A.Evento(adesso(), "nota", t))
        self.ent_nota.delete(0, "end")
        self.ridisegna(nota_nuova=True)

    def cambia_lavoro(self):
        self.lavoro = not self.lavoro
        self.arch.aggiungi_evento(A.Evento(adesso(), "inizio" if self.lavoro else "fine"))
        self._aggiorna_btn_lavoro()
        self.ridisegna()

    def _controlla_presenza(self):
        if sistema.secondi_inattivo() < self.imp["minuti_inattivo"] * 60:
            self.al_pc = True
        self._etichette(self.arch.letture())
        self.root.after(60_000, self._controlla_presenza)

    def _programma(self):
        ms = max(1, int(self.imp.get("minuti", 10))) * 60_000
        self._job = self.root.after(ms, self._giro)

    def _giro(self):
        if not self._edge_attivo():  # Edge manda già le letture: niente doppioni
            self.leggi()
        self._programma()

    def _edge_attivo(self) -> bool:
        lim = timedelta(minutes=int(self.imp.get("minuti", 10)) + 3)
        return self.ultima_edge is not None and adesso() - self.ultima_edge <= lim

    def _da_edge(self, d: dict):
        self.ultima_edge = adesso()
        if isinstance(d.get("uso"), dict):
            uso = A.leggi_risposta(d["uso"])
            if uso.sett is not None or uso.sess is not None:
                self._lettura_ok(uso, "edge")
                return
            d = {"errore": "risposta senza percentuali"}
        err = f"Edge: {d.get('errore', 'errore sconosciuto')}"
        if catena.metodi_attivi(self.imp):  # riserva: Claude Code -> cookie
            self._stato(f"{err} - provo la riserva...", True)
            self.leggi(prima=err)
        else:
            self._lettura_ko(err)

    def leggi(self, prima: str = ""):
        """Catena di riserva (Claude Code -> cookie). prima = errore già avuto da Edge."""
        if self.in_lettura:
            return
        metodi = catena.metodi_attivi(self.imp)
        if not metodi:
            if not self._edge_attivo():
                self._stato("Nessuna lettura: installa l'estensione Edge o metti il cookie in Impostazioni", True)
            return
        self.in_lettura = True
        if not prima:
            self._stato("Leggo...")
        threading.Thread(target=self._leggi_thread, args=(metodi, prima), daemon=True).start()

    def _leggi_thread(self, metodi, prima):
        try:
            uso, m = catena.leggi_catena(self.imp, lambda: self.arch.salva_impostazioni(self.imp), metodi)
            self.root.after(0, self._lettura_ok, uso, m)
        except fonte.ErroreFonte as e:
            msg = f"{prima} | {e}" if prima else str(e)
            self.root.after(0, self._lettura_ko, msg)
        except Exception as e:  # noqa: BLE001 - mai bloccare il giro
            self.root.after(0, self._lettura_ko, f"errore: {e}")

    def _lettura_ok(self, uso: A.Uso, m):
        self.in_lettura = False
        self.fallite, self.avvisato = 0, False
        self.ultimo_uso = uso
        self.arch.aggiungi_lettura(A.Lettura(adesso(), uso.sett, uso.sess, "auto", self.al_pc, self.lavoro,
                                             self._attivi("modelli"), self._attivi("skill")))
        self.al_pc = sistema.secondi_inattivo() < self.imp["minuti_inattivo"] * 60
        nome = catena.NOMI.get(m, m)
        self._stato(f"Ultima lettura {adesso():%H:%M} ({nome})")
        self.ridisegna()

    def _lettura_ko(self, msg):
        self.in_lettura = False
        self.fallite += 1
        self._stato(f"Lettura fallita: {msg}", True)
        if self.fallite >= 2 and not self.avvisato:  # 2 giri falliti (Edge + riserve): avviso, 1 volta
            self.avvisato = True
            self.root.deiconify()
            self.root.lift()
            messagebox.showwarning(
                "Traker uso Claude",
                f"Le letture non funzionano.\n\n{msg}\n\n"
                "Controlla di essere loggato su claude.ai in Edge,\n"
                "oppure rimetti il cookie in Impostazioni.", parent=self.root)

    def _stato(self, t, errore=False):
        self.lbl_stato.config(text=t, fg=T.ERRORE if errore else T.SPENTO)
        self.pallino.delete("all")
        self.pallino.create_oval(1, 1, 9, 9, fill=T.ERRORE if errore else T.OK, outline="")

    # ---------- finestre ----------
    def dlg_manuale(self):
        d = tk.Toplevel(self.root)
        d.title("Lettura manuale")
        d.configure(bg=T.SFONDO)
        d.transient(self.root)
        d.grab_set()
        campi = {}
        for i, (k, lab, val) in enumerate([("ora", "Data e ora (AAAA-MM-GG HH:MM)", A.fmt(adesso())),
                                           ("sett", "Settimanale %", ""),
                                           ("sess", "Sessione 5h % (anche vuoto)", "")]):
            ttk.Label(d, text=lab).grid(row=i, column=0, sticky="w", padx=8, pady=4)
            e = ttk.Entry(d, width=22)
            e.insert(0, val)
            e.grid(row=i, column=1, padx=8, pady=4)
            campi[k] = e

        def ok():
            try:
                ora = A.parse(campi["ora"].get())
                n = lambda s: float(s.replace(",", ".").replace("%", "")) if s.strip() else None
                w, s = n(campi["sett"].get()), n(campi["sess"].get())
                if w is None and s is None:
                    raise ValueError
            except ValueError:
                messagebox.showerror("Errore", "Controlla data/ora e percentuali.", parent=d)
                return
            self.arch.aggiungi_lettura(A.Lettura(ora, w, s, "manuale", None, False,
                                                 self._attivi("modelli"), self._attivi("skill")))
            d.destroy()
            self.ridisegna()

        ttk.Button(d, text="Salva", command=ok).grid(row=3, column=1, sticky="e", padx=8, pady=8)

    def dlg_impostazioni(self):
        d = tk.Toplevel(self.root)
        d.title("Impostazioni")
        d.configure(bg=T.SFONDO)
        d.transient(self.root)
        d.grab_set()
        cc = "trovato" if fonte.token_claude_code() else "non trovato"
        righe = [
            ("Leggi ogni (minuti)", "minuti"),
            ("Non al PC dopo (minuti senza mouse/tastiera)", "minuti_inattivo"),
        ]
        ent = {}
        for i, (lab, k) in enumerate(righe):
            ttk.Label(d, text=lab).grid(row=i, column=0, sticky="w", padx=8, pady=4)
            e = ttk.Entry(d, width=10)
            e.insert(0, str(self.imp[k]))
            e.grid(row=i, column=1, sticky="w", padx=8)
            ent[k] = e
        ttk.Label(d, text="Metodo").grid(row=2, column=0, sticky="w", padx=8, pady=4)
        met = ttk.Combobox(d, state="readonly", values=["auto", "claude_code", "cookie", "manuale"], width=14)
        met.set(self.imp.get("metodo", "auto"))
        met.grid(row=2, column=1, sticky="w", padx=8)
        ttk.Label(d, text=f"Claude Code su questo PC: {cc}").grid(row=3, column=0, columnspan=2, sticky="w", padx=8)
        ttk.Label(d, text="Cookie sessionKey di claude.ai (vuoto = lascia com'è)").grid(
            row=4, column=0, sticky="w", padx=8, pady=(10, 2))
        ck = ttk.Entry(d, width=60, show="*")
        ck.grid(row=5, column=0, columnspan=2, padx=8)
        ttk.Label(d, text="Salvato cifrato col tuo utente Windows. Non darlo a nessuno.",
                  foreground=T.ERRORE).grid(row=6, column=0, columnspan=2, sticky="w", padx=8)

        def ok():
            try:
                for k, e in ent.items():
                    self.imp[k] = max(1, int(e.get()))
            except ValueError:
                messagebox.showerror("Errore", "Minuti: solo numeri interi.", parent=d)
                return
            self.imp["metodo"] = met.get()
            if ck.get().strip():
                self.imp["cookie"] = sistema.cifra(ck.get().strip())
                self.imp["org_id"] = ""
            self.arch.salva_impostazioni(self.imp)
            self.root.after_cancel(self._job)
            self._programma()
            d.destroy()
            self.leggi()

        ttk.Button(d, text="Salva e prova", command=ok).grid(row=7, column=1, sticky="e", padx=8, pady=10)

    # ---------- grafico ----------
    def _intervallo(self, letture):
        ora = adesso()
        return PE.intervallo(self.scatto.get(), ora, A.inizio_settimana(ora),
                             letture[0].ora if letture else None)

    def _grafico_dopo(self):
        """Ridimensionamento: ridisegna solo il grafico, una volta quando il mouse si ferma."""
        if self._job_graf:
            self.root.after_cancel(self._job_graf)
        self._job_graf = self.root.after(80, self._solo_grafico)

    def _solo_grafico(self):
        self._job_graf = None
        letture = self.arch.letture()
        da, a = self._intervallo(letture)
        self.graf.disegna(letture, self.arch.eventi(), da, a, adesso())

    def ridisegna(self, nota_nuova=False):
        letture, eventi = self.arch.letture(), self.arch.eventi()
        self._etichette(letture)
        da, a = self._intervallo(letture)
        self.graf.disegna(letture, eventi, da, a, adesso())
        note = [e for e in eventi if e.tipo == "nota"]
        vals = [f"{i}.  {giorno(e.ora)} {e.ora:%d/%m %H:%M} - {e.testo}" for i, e in enumerate(note, 1)]
        prima = self.sel_nota.current()
        self.sel_nota.config(values=vals)
        self._note = note
        if vals:
            self.sel_nota.current(len(vals) - 1 if nota_nuova or prima < 0 or prima >= len(vals) else prima)
        self.analizza()

    def _etichette(self, letture):
        u, ora = self.ultimo_uso, adesso()
        for k in ("sess", "sett"):
            last = next((x for x in reversed(letture) if getattr(x, k) is not None), None)
            c = self.carte[k]
            c["pct"] = getattr(last, k) if last else None
            c["val"].config(text=f"{c['pct']:g}%" if last else "-")
            rst = LV.arrotonda_reset((u.reset_sess if k == "sess" else u.reset_sett) if u else None)
            if rst:
                quando = f"{rst:%H:%M}" if k == "sess" else f"{giorno(rst)} {rst:%H:%M}"
                c["sotto"].config(text=f"reset {quando}  ·  tra {durata(rst - ora)}")
            else:
                c["sotto"].config(text="reset: in attesa di lettura")
            self._barra(k)

    # ---------- analisi (carta CONFRONTI, P6) ----------
    @staticmethod
    def _badge(lbl, v: str):
        if v:
            lbl.config(text=v, bg=T.CARTA2, fg=COL_VERDETTO.get(v.lower(), T.SPENTO), padx=10, pady=2)
        else:
            lbl.config(text="", bg=T.CARTA, padx=0, pady=0)

    def analizza(self):
        letture = self.arch.letture()
        periodi = LV.periodi_lavoro(self.arch.eventi(), adesso()) if self.var_lavoro.get() else None
        i = self.sel_nota.current()
        if 0 <= i < len(getattr(self, "_note", [])):
            c = self._cn = K.confronto_nota(letture, self._note[i].ora, periodi=periodi)
            self.n_prima.config(text=f"prima {K.num(c.prima)}")
            self.n_dopo.config(text=f"dopo {K.num(c.dopo)}")
            self.n_unita.config(text="pt%/h sett  ·")
            self._badge(self.verdetto, c.verdetto)
            self.n_ore.config(text=f"{K.testo_ore_nota(c)} {K.testo_filtro(c.filtro)}".strip())
        else:
            self._cn = None
            self.n_prima.config(text="Scrivi una nota per confrontare prima/dopo.")
            for w in (self.n_dopo, self.n_unita, self.n_ore):
                w.config(text="")
            self._badge(self.verdetto, "")
        ini = A.inizio_settimana(adesso())
        pc, auto = A.ritmo_per_presenza(A.filtra(letture, ini - timedelta(minutes=1), adesso()), "sett")
        self.lbl_pres.config(text=K.testo_presenza(pc, auto))
        self._combinazioni(letture, periodi)
        self._cosa_dicono(letture)

    def _cambia_solo_lavoro(self):
        self.imp["solo_lavoro"] = bool(self.var_lavoro.get())
        self.arch.salva_impostazioni(self.imp)
        self.analizza()

    def _spiega_combo(self, i: int) -> str:
        k = self._sel_keys[i]
        tab = self._tab_usata if self._tab_usata is not None else self._tab_c
        if k is None or k not in tab:
            return ""
        testo = K.spiega_combo("AB"[i], k, K.periodo_combo(self._letture_c, k), tab[k]["ore"])
        return testo + (f"\n{K.testo_filtro(self._cc.filtro)}" if self._cc and self._cc.filtro else "")

    def _combinazioni(self, letture, periodi=None):
        tab = self._tab_c = C.ritmo_per_combinazione(letture)
        tab_lav = C.ritmo_per_combinazione(letture, periodi) if periodi is not None else None
        self._tab_usata = None
        self._letture_c = letture
        chiavi = sorted(tab, key=lambda k: -tab[k]["ore"])
        scelte = [self._combo_keys[cb.current()] if 0 <= cb.current() < len(self._combo_keys) else None
                  for cb in self.sel_c]
        self._combo_keys = chiavi
        nomi = [C.etichetta(k) for k in chiavi]
        for i, cb in enumerate(self.sel_c):
            cb.config(values=nomi)
            k = scelte[i] if scelte[i] in chiavi else (chiavi[i] if i < len(chiavi) else None)
            if k is not None:
                cb.current(chiavi.index(k))
        sel = self._sel_keys = [chiavi[cb.current()] if cb.current() >= 0 else None for cb in self.sel_c]
        self._cc = None
        for w in (self.c_a, self.c_b, self.c_unita, self.c_motivo):
            w.config(text="")
        self._badge(self.verd_c, "")
        if sel[0] is not None and sel[1] is not None:
            c = self._cc = K.confronto_combinazioni(tab, sel[0], sel[1], tab_lavoro=tab_lav)
            self._tab_usata = tab_lav if c.filtro == "lavoro" else tab
            self.c_a.config(text=f"A {K.num(c.a)}")
            self.c_b.config(text=f"B {K.num(c.b)}")
            self.c_unita.config(text="pt%/h sett  ·")
            self._badge(self.verd_c, c.verdetto)
            self.c_motivo.config(text=f"{c.motivo} {K.testo_filtro(c.filtro)}".strip())
        elif sel[0] is not None:
            self.c_a.config(text=f"A {K.num(tab[sel[0]]['sett'])}")
            self.c_unita.config(text="pt%/h sett")
            self.c_motivo.config(text="(serve una seconda combinazione)")
        else:
            self.c_a.config(text="Accendi modelli/skill: le prossime letture li segnano.")
        self.lbl_class.config(text=K.testo_classifica(C.classifica_modelli(letture, "sett")))

    def _cosa_dicono(self, letture):
        ora = adesso()
        ini = A.inizio_settimana(ora)
        rst = LV.arrotonda_reset(self.ultimo_uso.reset_sett if self.ultimo_uso else None) or ini + timedelta(days=7)
        self.lbl_dati.config(text="\n".join(PR.frasi(A.filtra(letture, ini, ora), rst, ora)))
