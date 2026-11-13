import os
import sys
import unittest

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from data import catena, fonte  # noqa: E402
from domain import analisi as A  # noqa: E402


class TestCatena(unittest.TestCase):
    def test_primo_cade_secondo_vince(self):
        chiamati = []

        def finto(m, imp, salva):
            chiamati.append(m)
            if m == "claude_code":
                raise fonte.ErroreFonte("scaduto")
            return A.Uso(10, 20, None, None)

        uso, m = catena.leggi_catena({}, lambda: None, ["claude_code", "cookie"], finto)
        self.assertEqual((m, uso.sett, chiamati), ("cookie", 20, ["claude_code", "cookie"]))

    def test_tutti_cadono(self):
        def finto(m, imp, salva):
            raise fonte.ErroreFonte("no")
        with self.assertRaises(fonte.ErroreFonte) as c:
            catena.leggi_catena({}, lambda: None, ["claude_code", "cookie"], finto)
        self.assertIn("Claude Code: no", str(c.exception))
        self.assertIn("cookie: no", str(c.exception))

    def test_metodi(self):
        self.assertEqual(catena.metodi_attivi({"metodo": "manuale"}), [])
        self.assertEqual(catena.metodi_attivi({"metodo": "cookie"}), ["cookie"])
        m = catena.metodi_attivi({"metodo": "auto", "cookie": "x"})
        self.assertEqual(m[-1], "cookie")


if __name__ == "__main__":
    unittest.main()
