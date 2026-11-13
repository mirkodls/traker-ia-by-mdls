import os
import sys
import unittest

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from domain import analisi as A  # noqa: E402
from domain import combinazioni as C  # noqa: E402

T = A.parse


def L(ora, sett, sess=None, m="", s=""):
    return A.Lettura(T(ora), sett, sess, modelli=m, skill=s)


class TestCombinazioni(unittest.TestCase):
    def test_norm(self):
        self.assertEqual(C.norm("Sonnet| Opus|Opus|"), "Opus|Sonnet")
        self.assertEqual(C.norm(""), "")
        self.assertEqual(C.unisci(["Haiku", "Fable"]), "Fable|Haiku")

    def test_etichetta(self):
        self.assertEqual(C.etichetta(("", "")), "(non segnato)")
        self.assertEqual(C.etichetta(("Opus|Sonnet", "caveman")), "Opus + Sonnet  ·  caveman")
        self.assertEqual(C.etichetta(("", "caveman")), "nessun modello  ·  caveman")

    def test_ritmo_per_combinazione(self):
        ls = [L("2026-11-12 10:00", 10, 0, "Opus"),
              L("2026-11-12 12:00", 16, 30, "Opus", "caveman"),   # 2h: +6 sett, +30 sess
              L("2026-11-12 13:00", 18, 35, "Sonnet", "caveman"),  # 1h: +2, +5
              L("2026-11-12 14:00", 20, 3, "Sonnet", "caveman")]   # sess reset escluso
        r = C.ritmo_per_combinazione(ls)
        a = r[("Opus", "caveman")]
        self.assertAlmostEqual(a["ore"], 2)
        self.assertAlmostEqual(a["sett"], 3)
        self.assertAlmostEqual(a["sess"], 15)
        b = r[("Sonnet", "caveman")]
        self.assertAlmostEqual(b["ore"], 2)       # sett 2h, sess 1h (reset escluso)
        self.assertAlmostEqual(b["sett"], 2)
        self.assertAlmostEqual(b["sess"], 5)

    def test_righe_vecchie_non_segnate(self):
        ls = [L("2026-11-12 10:00", 10), L("2026-11-12 11:00", 12)]
        self.assertIn(("", ""), C.ritmo_per_combinazione(ls))

    def test_confronta(self):
        c1 = {"ore": 3, "sett": 2.0, "sess": 10}
        self.assertEqual(C.confronta(c1, {"ore": 2, "sett": 1.0, "sess": 5}), "SCESO")
        self.assertEqual(C.confronta(c1, {"ore": 2, "sett": 3.0, "sess": 5}), "SALITO")
        self.assertEqual(C.confronta(c1, {"ore": 2, "sett": 2.1, "sess": 5}), "COSTANTE")
        self.assertEqual(C.confronta(c1, {"ore": 0.5, "sett": 1.0, "sess": 5}), "DATO DEBOLE")
        self.assertEqual(C.confronta(c1, None), "DATO DEBOLE")
        self.assertEqual(C.confronta(c1, {"ore": 2, "sett": None, "sess": 5}), "DATO DEBOLE")
        self.assertEqual(C.confronta(c1, {"ore": 2, "sett": 2, "sess": 5}, "sess"), "SCESO")

    def test_classifica(self):
        ls = [L("2026-11-12 10:00", 10, None, "Opus"),
              L("2026-11-12 12:00", 18, None, "Opus"),            # Opus 4/h
              L("2026-11-12 14:00", 20, None, "Haiku|Opus")]      # 1/h per entrambi
        cl = C.classifica_modelli(ls)
        self.assertEqual([m for m, _, _ in cl], ["Opus", "Haiku"])
        self.assertAlmostEqual(cl[0][1], 4)
        self.assertAlmostEqual(cl[0][2], 10 / 4)
        self.assertAlmostEqual(cl[1][2], 1)

    def test_stato_a(self):
        ls = [L("2026-11-12 10:00", 10, None, "Opus"), L("2026-11-12 12:00", 12, None, "Sonnet", "caveman")]
        self.assertEqual(C.stato_a(ls, T("2026-11-12 11:00")), ("Sonnet", "caveman"))
        self.assertEqual(C.stato_a(ls, T("2026-11-12 10:00")), ("Opus", ""))
        self.assertEqual(C.stato_a(ls, T("2026-11-12 13:00")), ("Sonnet", "caveman"))
        self.assertIsNone(C.stato_a([], T("2026-11-12 13:00")))


if __name__ == "__main__":
    unittest.main()
