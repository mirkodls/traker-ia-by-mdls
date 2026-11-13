import os
import sys
import unittest

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from domain import analisi as A  # noqa: E402
from domain import previsione as P  # noqa: E402

T = A.parse
RESET = T("2026-11-17 20:00")  # martedi


def L(ora, sett):
    return A.Lettura(T(ora), sett, None)


class TestPrevisione(unittest.TestCase):
    def test_ritmo_costante(self):
        ls = [L("2026-11-12 10:00", 40), L("2026-11-12 12:00", 44), L("2026-11-12 14:00", 48)]
        p = P.previsione(ls, RESET)
        self.assertAlmostEqual(p.ritmo, 2.0)
        self.assertEqual(p.ora_100, T("2026-11-13 16:00"))  # (100-48)/2 = 26h
        self.assertTrue(p.prima_del_reset)
        self.assertFalse(p.debole)

    def test_dopo_il_reset(self):
        ls = [L("2026-11-12 10:00", 10), L("2026-11-12 14:00", 11.5)]
        p = P.previsione(ls, RESET)
        self.assertFalse(p.prima_del_reset)

    def test_debole(self):
        ls = [L("2026-11-12 10:00", 40), L("2026-11-12 14:00", 41)]
        self.assertTrue(P.previsione(ls, RESET).debole)

    def test_nessun_consumo(self):
        ls = [L("2026-11-12 10:00", 40), L("2026-11-12 14:00", 40)]
        p = P.previsione(ls, RESET)
        self.assertIsNone(p.ora_100)
        self.assertTrue(p.debole)

    def test_vuoto(self):
        p = P.previsione([], RESET)
        self.assertIsNone(p.att)
        self.assertTrue(p.debole)

    def test_reset_in_mezzo_escluso(self):
        ls = [L("2026-11-12 10:00", 90), L("2026-11-12 11:00", 2), L("2026-11-12 13:00", 6)]
        self.assertAlmostEqual(P.previsione(ls, RESET).ritmo, 2.0)

    def test_finestra_limitata(self):
        ls = [L("2026-11-12 00:00", 0), L("2026-11-12 02:00", 20), L("2026-11-12 10:00", 20),
              L("2026-11-12 12:00", 24)]
        self.assertAlmostEqual(P.previsione(ls, RESET, ore=6).ritmo,
                               A.ritmo(ls, "sett", T("2026-11-12 06:00"), T("2026-11-12 12:00")))


class TestBudget(unittest.TestCase):
    def test_budget(self):
        self.assertAlmostEqual(P.budget_giorno(50, T("2026-11-15 20:00"), RESET), 25.0)

    def test_budget_pieno_o_scaduto(self):
        self.assertEqual(P.budget_giorno(100, T("2026-11-15 20:00"), RESET), 0.0)
        self.assertIsNone(P.budget_giorno(50, RESET, RESET))
        self.assertIsNone(P.budget_giorno(None, T("2026-11-15 20:00"), RESET))


class TestFullGas(unittest.TestCase):
    def test_solo_coppie_con_consumo(self):
        ls = [L("2026-11-12 08:00", 10), L("2026-11-12 09:00", 14),   # 4 pt in 1h
              L("2026-11-12 12:00", 14),                              # pausa
              L("2026-11-12 13:00", 18)]                              # 4 pt in 1h
        self.assertAlmostEqual(P.ritmo_attivo(ls), 4.0)
        self.assertAlmostEqual(P.ore_full_gas_rimaste(ls), (100 - 18) / 4.0)

    def test_senza_consumo(self):
        ls = [L("2026-11-12 08:00", 10), L("2026-11-12 09:00", 10)]
        self.assertIsNone(P.ritmo_attivo(ls))
        self.assertIsNone(P.ore_full_gas_rimaste(ls))


class TestFrasi(unittest.TestCase):
    ADESSO = T("2026-11-15 20:00")

    def test_finisci(self):
        ls = [L("2026-11-15 10:00", 40), L("2026-11-15 12:00", 48)]
        f = P.frasi(ls, RESET, self.ADESSO)
        self.assertTrue(f[0].startswith("A questo ritmo finisci"))
        self.assertIn("Reset mar 20:00", f[0])
        self.assertTrue(any(x.startswith("Oggi puoi usare ancora") for x in f))
        self.assertTrue(any("A pieno regime" in x for x in f))

    def test_debole(self):
        ls = [L("2026-11-15 10:00", 40), L("2026-11-15 12:00", 41)]
        self.assertEqual(P.frasi(ls, RESET, self.ADESSO)[0], "Dato debole: aspetta.")

    def test_arrivi_al_reset(self):
        ls = [L("2026-11-15 10:00", 10), L("2026-11-15 14:00", 12.5)]
        self.assertIn("senza finire", P.frasi(ls, RESET, self.ADESSO)[0])

    def test_vuoto(self):
        self.assertEqual(len(P.frasi([], RESET, self.ADESSO)), 1)


if __name__ == "__main__":
    unittest.main()
