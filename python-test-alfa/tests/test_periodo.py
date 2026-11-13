import os
import sys
import unittest
from datetime import datetime, timedelta

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from domain import periodo as P  # noqa: E402

ORA = datetime(2026, 11, 13, 12, 0)
SETT = datetime(2026, 11, 10, 20, 0)
PRIMO = datetime(2026, 11, 1, 8, 0)


class TestPeriodo(unittest.TestCase):
    def test_scatti_ore(self):
        for i, ore in ((0, 2), (1, 6), (2, 12), (3, 24), (4, 72), (6, 168)):
            self.assertEqual(P.intervallo(i, ORA, SETT, PRIMO), (ORA - timedelta(hours=ore), ORA))

    def test_settimana_da_reset(self):
        self.assertEqual(P.intervallo(P.SETTIMANA, ORA, SETT, PRIMO), (SETT, ORA))

    def test_tutto_dal_primo_dato(self):
        self.assertEqual(P.intervallo(P.TUTTO, ORA, SETT, PRIMO), (PRIMO, ORA))

    def test_tutto_senza_dati(self):
        self.assertEqual(P.intervallo(P.TUTTO, ORA, SETT, None), (ORA - timedelta(days=1), ORA))

    def test_minimo_1_ora(self):
        s = ORA - timedelta(minutes=5)
        self.assertEqual(P.intervallo(P.SETTIMANA, ORA, s, PRIMO), (s, s + timedelta(hours=1)))
        self.assertEqual(P.intervallo(P.TUTTO, ORA, SETT, ORA), (ORA, ORA + timedelta(hours=1)))

    def test_normalizza(self):
        for male in (None, "x", -1, 8, 2.0, True):
            self.assertEqual(P.normalizza(male), P.PREDEFINITO)
        self.assertEqual(P.normalizza(0), 0)
        self.assertEqual(P.normalizza(7), 7)

    def test_ordine_crescente(self):
        ore = [o for _, o in P.SCATTI if o is not None]
        self.assertEqual(ore, sorted(ore))

    def test_etichetta(self):
        self.assertEqual(P.etichetta(5), "Settimana")
        self.assertEqual(P.etichetta("boh"), "Settimana")


if __name__ == "__main__":
    unittest.main()
