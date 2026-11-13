import json
import os
import sys
import unittest
import urllib.request

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from data import ricevitore  # noqa: E402


class TestRicevitore(unittest.TestCase):
    def test_post(self):
        arrivati = []
        srv = ricevitore.avvia(arrivati.append, lambda: 15, porta=0)
        porta = srv.server_address[1]
        try:
            req = urllib.request.Request(f"http://127.0.0.1:{porta}/lettura", method="POST",
                                         data=json.dumps({"errore": "x"}).encode(),
                                         headers={"Content-Type": "application/json"})
            with urllib.request.urlopen(req, timeout=5) as r:
                self.assertEqual(json.loads(r.read()), {"minuti": 15})
            self.assertEqual(arrivati, [{"errore": "x"}])
            req = urllib.request.Request(f"http://127.0.0.1:{porta}/lettura", method="POST", data=b"[1]")
            with self.assertRaises(urllib.error.HTTPError):
                urllib.request.urlopen(req, timeout=5)
        finally:
            srv.shutdown()


if __name__ == "__main__":
    unittest.main()
