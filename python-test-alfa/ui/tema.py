"""Colori, caratteri e stili (tema scuro)."""
from __future__ import annotations

import contextlib
import sys
import tkinter as tk
from tkinter import ttk

SFONDO = "#0b1220"
CARTA = "#151e2e"
CARTA2 = "#1c2740"
BORDO = "#26324a"
TESTO = "#e5e9f0"
SPENTO = "#8b97ad"
SETT = "#60a5fa"
SETT_AREA = "#15294a"
SESS = "#fb923c"
NOTA = "#c084fc"
RESET = "#4b5875"
LAVORO = "#10291c"
OK = "#34d399"
ERRORE = "#f87171"
GRIGLIA = "#1d2738"
ACCENTO = "#3b82f6"

F = "Segoe UI" if sys.platform == "win32" else "DejaVu Sans"
F_PICCOLO = (F, 9)
F_NORMALE = (F, 10)
F_TITOLO = (F, 10, "bold")
F_GRANDE = (F, 26, "bold")
F_CARTA = (F, -28, "bold")  # numero carte %: 28 px
F_SEZIONE = (F, 9, "bold")  # titoli sezione cliccabili


SC = 1.0  # fattore schermo (DPI/96), fissato da scala()


def px(n: float) -> int:
    """Pixel scalati col DPI (a 96 dpi = n)."""
    return max(1, round(n * SC))


def scala(root: tk.Tk):
    """Scaling Tk coerente col DPI reale: testi (punti) e misure in pixel crescono insieme."""
    global SC, F_CARTA
    with contextlib.suppress(Exception):
        dpi = float(root.winfo_fpixels("1i"))
        if dpi >= 48:
            root.tk.call("tk", "scaling", dpi / 72)
            SC = max(1.0, dpi / 96)
    F_CARTA = (F, -px(28), "bold")


def applica(root: tk.Tk):
    root.configure(bg=SFONDO)
    st = ttk.Style(root)
    st.theme_use("clam")
    st.configure(".", background=SFONDO, foreground=TESTO, font=F_NORMALE,
                 fieldbackground=CARTA2, bordercolor=BORDO, lightcolor=BORDO, darkcolor=BORDO)
    st.configure("TFrame", background=SFONDO)
    st.configure("Carta.TFrame", background=CARTA)
    st.configure("TLabel", background=SFONDO, foreground=TESTO)
    st.configure("Carta.TLabel", background=CARTA, foreground=TESTO)
    st.configure("Spento.TLabel", background=CARTA, foreground=SPENTO, font=F_PICCOLO)
    st.configure("Titolo.TLabel", background=CARTA, foreground=SPENTO, font=F_TITOLO)
    st.configure("TButton", background=CARTA2, foreground=TESTO, padding=(12, 6), borderwidth=0,
                 focusthickness=0)
    st.map("TButton", background=[("active", BORDO), ("pressed", BORDO)])
    st.configure("Accento.TButton", background=ACCENTO, foreground="white")
    st.map("Accento.TButton", background=[("active", "#2563eb"), ("pressed", "#1d4ed8")])
    st.configure("TEntry", fieldbackground=CARTA2, foreground=TESTO, insertcolor=TESTO,
                 padding=6, borderwidth=0)
    st.configure("TCombobox", fieldbackground=CARTA2, background=CARTA2, foreground=TESTO,
                 arrowcolor=TESTO, padding=4, borderwidth=0)
    st.map("TCombobox", fieldbackground=[("readonly", CARTA2)], foreground=[("readonly", TESTO)],
           selectbackground=[("readonly", CARTA2)], selectforeground=[("readonly", TESTO)])
    root.option_add("*TCombobox*Listbox.background", CARTA2)
    root.option_add("*TCombobox*Listbox.foreground", TESTO)
    root.option_add("*TCombobox*Listbox.selectBackground", ACCENTO)


def barra_titolo_scura(finestra: tk.Misc):
    """Barra del titolo scura su Windows 10/11 (se non va, niente)."""
    if sys.platform != "win32":
        return
    with contextlib.suppress(Exception):
        import ctypes
        finestra.update_idletasks()
        hwnd = ctypes.windll.user32.GetParent(finestra.winfo_id())
        v = ctypes.c_int(1)
        for attr in (20, 19):
            if ctypes.windll.dwmapi.DwmSetWindowAttribute(hwnd, attr, ctypes.byref(v), 4) == 0:
                break
