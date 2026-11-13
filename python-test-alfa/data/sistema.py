"""Cose di Windows: secondi senza input (tastiera/mouse) e cifratura DPAPI."""
from __future__ import annotations

import base64
import ctypes
import sys

WIN = sys.platform == "win32"


def secondi_inattivo() -> float:
    if not WIN:
        return 0.0

    class LASTINPUTINFO(ctypes.Structure):
        _fields_ = [("cbSize", ctypes.c_uint), ("dwTime", ctypes.c_uint)]

    li = LASTINPUTINFO()
    li.cbSize = ctypes.sizeof(li)
    if not ctypes.windll.user32.GetLastInputInfo(ctypes.byref(li)):
        return 0.0
    tick = ctypes.windll.kernel32.GetTickCount() & 0xFFFFFFFF
    return ((tick - li.dwTime) & 0xFFFFFFFF) / 1000.0


class _BLOB(ctypes.Structure):
    _fields_ = [("cbData", ctypes.c_uint), ("pbData", ctypes.POINTER(ctypes.c_char))]


def _dpapi(dati: bytes, cifra: bool) -> bytes:
    buf = ctypes.create_string_buffer(dati, len(dati))
    inp = _BLOB(len(dati), ctypes.cast(buf, ctypes.POINTER(ctypes.c_char)))
    out = _BLOB()
    c = ctypes.windll.crypt32
    f = c.CryptProtectData if cifra else c.CryptUnprotectData
    if not f(ctypes.byref(inp), None, None, None, None, 0, ctypes.byref(out)):
        raise OSError("DPAPI fallito")
    try:
        return ctypes.string_at(out.pbData, out.cbData)
    finally:
        ctypes.windll.kernel32.LocalFree(out.pbData)


def cifra(testo: str) -> str:
    """Cifrato legato al tuo utente Windows (non leggibile da altri PC/utenti)."""
    if not testo:
        return ""
    b = testo.encode("utf-8")
    return base64.b64encode(_dpapi(b, True) if WIN else b).decode()


def decifra(s: str) -> str:
    if not s:
        return ""
    try:
        b = base64.b64decode(s)
        return (_dpapi(b, False) if WIN else b).decode("utf-8")
    except (OSError, ValueError):
        return ""
