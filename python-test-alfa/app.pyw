"""Traker uso Claude - avvio. Doppio clic su avvia.bat."""
import os
import sys
import tkinter as tk

BASE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, BASE)

from ui.finestra import App  # noqa: E402

if __name__ == "__main__":
    if sys.platform == "win32":
        try:  # nitidezza: prima di creare Tk. 2 = per-monitor; fallback = system DPI aware
            import ctypes
            try:
                ctypes.windll.shcore.SetProcessDpiAwareness(2)
            except Exception:  # noqa: BLE001
                ctypes.windll.user32.SetProcessDPIAware()
        except Exception:  # noqa: BLE001
            pass
    root = tk.Tk()
    App(root, os.path.join(BASE, "dati"))
    if "--ridotto" in sys.argv:
        root.iconify()
    root.mainloop()
