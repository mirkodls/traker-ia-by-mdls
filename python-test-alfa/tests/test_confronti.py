import os
import sys
import unittest

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from domain import analisi as A  # noqa: E402
from domain import combinazioni as C  # noqa: E402
from domain import confronti as K  # noqa: E402

T = A.parse


def L(ora, sett, sess=None, m="", s=""):
    return A.Lettura(T(ora), sett, sess, modelli=m, skill=s)


class TestFormati(unittest.TestCase):
    def test_num_ore(self):
        self.assertEqual(K.num(0.944), "0,94")
        self.assertEqual(K.num(None), "-")
        self.assertEqual(K.ore(0.14), "0,1 h")
        self.assertEqual(K.ore(None), "-")

    def test_quando(self):
        self.assertEqual(K.quando(T("2026-11-12 20:00")), "gio 12/11 20:00")


class TestNota(unittest.TestCase):
    def setUp(self):
        # reset sett mar 10/11 20:00; nota mer 11/11 20:00
        self.ls = [L("2026-11-10 20:00", 0), L("2026-11-11 08:00", 12),   # 12h: +12 -> 1,0
                   L("2026-11-11 20:00", 24),                              # 12h: +12 -> 1,0
                   L("2026-11-12 08:00", 30),                              # 12h: +6 -> 0,5
                   ]

    def test_ore_contate(self):
        self.assertAlmostEqual(K.ore_contate(self.ls, "sett"), 36)
        da, a = T("2026-11-11 08:00"), T("2026-11-12 08:00")
        self.assertAlmostEqual(K.ore_contate(self.ls, "sett", da, a), 24)
        self.assertAlmostEqual(K.ore_contate(self.ls, "sett", T("2026-11-11 14:00"), T("2026-11-11 15:00")), 1)

    def test_ore_contate_reset_escluso(self):
        ls = [L("2026-11-12 10:00", 50), L("2026-11-12 11:00", 5), L("2026-11-12 12:00", 7)]
        self.assertAlmostEqual(K.ore_contate(ls, "sett"), 1)

    def test_confronto_nota(self):
        c = K.confronto_nota(self.ls, T("2026-11-11 20:00"))
        self.assertAlmostEqual(c.prima, 1.0)
        self.assertAlmostEqual(c.dopo, 0.5)
        self.assertAlmostEqual(c.ore_prima, 24)
        self.assertAlmostEqual(c.ore_dopo, 12)
        self.assertEqual(c.verdetto, "SCESO")
        self.assertEqual(c.da, T("2026-11-10 20:00"))
        self.assertEqual(K.testo_ore_nota(c), "(24,0 h prima / 12,0 h dopo)")

    def test_nota_senza_dati_dopo(self):
        c = K.confronto_nota(self.ls, T("2026-11-12 08:00"))
        self.assertIsNone(c.dopo)
        self.assertEqual(c.verdetto, K.DEBOLE)
        self.assertEqual(c.ore_dopo, 0)


class TestCombo(unittest.TestCase):
    def setUp(self):
        self.ls = [L("2026-11-12 10:00", 10, 0, "Opus", "caveman"),
                   L("2026-11-12 12:00", 12, 10, "Opus", "caveman"),    # A: 2h, +2 -> 1,0
                   L("2026-11-12 12:06", 12, 10, "Sonnet", "caveman")]  # B: 0,1h, +0 -> 0
        self.tab = C.ritmo_per_combinazione(self.ls)
        self.ka, self.kb = ("Opus", "caveman"), ("Sonnet", "caveman")

    def test_motivo_debole(self):
        self.assertEqual(K.motivo_debole(2, 0.1), "(B solo 0,1 h)")
        self.assertEqual(K.motivo_debole(0.5, 0.1), "(A solo 0,5 h, B solo 0,1 h)")
        self.assertEqual(K.motivo_debole(2, 2), "")
        self.assertEqual(K.motivo_debole(None, 2), "(manca un dato)")

    def test_confronto_debole(self):
        c = K.confronto_combinazioni(self.tab, self.ka, self.kb)
        self.assertEqual(c.verdetto, K.DEBOLE)
        self.assertEqual(c.motivo, "(B solo 0,1 h)")
        self.assertAlmostEqual(c.a, 1.0)
        self.assertAlmostEqual(c.b, 0.0)

    def test_confronto_valido(self):
        ls = [L("2026-11-12 10:00", 10, m="Opus"), L("2026-11-12 12:00", 14, m="Opus"),
              L("2026-11-12 14:00", 15, m="Sonnet")]
        tab = C.ritmo_per_combinazione(ls)
        c = K.confronto_combinazioni(tab, ("Opus", ""), ("Sonnet", ""))
        self.assertEqual(c.verdetto, "SCESO")
        self.assertEqual(c.motivo, "")

    def test_combo_mancante(self):
        c = K.confronto_combinazioni(self.tab, self.ka, ("Haiku", ""))
        self.assertEqual((c.verdetto, c.b, c.motivo), (K.DEBOLE, None, "(manca un dato)"))

    def test_periodo_combo(self):
        self.assertEqual(K.periodo_combo(self.ls, self.ka), (T("2026-11-12 10:00"), T("2026-11-12 12:00")))
        self.assertIsNone(K.periodo_combo(self.ls, ("Haiku", "")))

    def test_testi(self):
        self.assertEqual(K.testo_classifica([]), "Classifica modelli: ancora nessun dato.")
        t = K.testo_classifica([("Opus", 2.0, 0.874), ("Sonnet", 0.5, 0.4)])
        self.assertIn("Opus 0,87 (2,0 h)", t)
        self.assertIn("Sonnet 0,40 (0,5 h)", t)
        self.assertEqual(K.testo_presenza(0.5, None), "Al PC 0,50  ·  automatico -  pt%/h sett (questa settimana)")


class TestSpiegazioni(unittest.TestCase):
    def test_verdetti_tutti_spiegati(self):
        for v in ("SCESO", "SALITO", "COSTANTE", K.DEBOLE):
            self.assertTrue(K.spiega_verdetto(v))
        self.assertEqual(K.spiega_verdetto(""), "")

    def test_spiega_combo_non_segnato(self):
        t = K.spiega_combo("A", ("", ""), (T("2026-11-12 10:00"), T("2026-11-12 12:00")), 2.0)
        self.assertIn("non segnato", t)
        self.assertIn("2,0 h", t)
        self.assertIn("pt%/h", t)
        self.assertNotIn("non segnato", K.spiega_combo("A", ("Opus", ""), None, None))

    def test_spiega_nota_periodi(self):
        c = K.ConfrontoNota(1, 0.5, 24, 12, "SCESO", T("2026-11-10 20:00"), T("2026-11-11 20:00"))
        self.assertIn("mar 10/11 20:00", K.spiega_prima(c))
        self.assertIn("mer 11/11 20:00", K.spiega_prima(c))
        self.assertIn("gio 12/11 08:00", K.spiega_dopo(c, T("2026-11-12 08:00")))


if __name__ == "__main__":
    unittest.main()
