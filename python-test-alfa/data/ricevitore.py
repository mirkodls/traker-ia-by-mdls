"""Riceve le letture dall'estensione Edge: POST http://127.0.0.1:45781/lettura
Corpo: {"uso": <risposta /usage>} oppure {"errore": "testo"}. Risposta: {"minuti": N}.
Ascolta SOLO su 127.0.0.1 (non raggiungibile da altri PC)."""
from __future__ import annotations

import json
import threading
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

PORTA = 45781


def avvia(su_messaggio, minuti, porta: int = PORTA):
    """su_messaggio(dict) chiamato nel thread del server; minuti() -> int.
    Ritorna il server, o None se la porta è occupata."""

    class H(BaseHTTPRequestHandler):
        def do_POST(self):
            if self.path != "/lettura":
                self.send_error(404)
                return
            try:
                n = min(int(self.headers.get("Content-Length", 0)), 1_000_000)
                dati = json.loads(self.rfile.read(n).decode("utf-8"))
                if not isinstance(dati, dict):
                    raise ValueError
            except ValueError:
                self.send_error(400)
                return
            su_messaggio(dati)
            corpo = json.dumps({"minuti": int(minuti())}).encode()
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(corpo)))
            self.end_headers()
            self.wfile.write(corpo)

        def log_message(self, *a):  # niente log (niente dati in giro)
            pass

    try:
        srv = ThreadingHTTPServer(("127.0.0.1", porta), H)
    except OSError:
        return None
    threading.Thread(target=srv.serve_forever, daemon=True).start()
    return srv
