import os
import sys
import unittest

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from domain import riordino as R  # noqa: E402


class TestSposta(unittest.TestCase):
    def test_avanti_indietro(self):
        self.assertEqual(R.sposta(list("abcd"), 0, 2), list("bcad"))
        self.assertEqual(R.sposta(list("abcd"), 3, 1), list("adbc"))

    def test_stesso_posto_e_fuori(self):
        self.assertEqual(R.sposta(list("abc"), 1, 1), list("abc"))
        self.assertEqual(R.sposta(list("abc"), 9, 0), list("abc"))
        self.assertEqual(R.sposta(list("abc"), 0, 99), list("bca"))
        self.assertEqual(R.sposta(list("abc"), 2, -5), list("cab"))

    def test_non_muta(self):
        o = ["a", "b"]
        R.sposta(o, 0, 1)
        self.assertEqual(o, ["a", "b"])
        self.assertEqual(R.sposta([], 0, 0), [])


class TestRilascio(unittest.TestCase):
    riga = [(10, 5), (60, 5), (110, 5)]

    def test_una_riga(self):
        c = list(self.riga)
        c[0] = (100, 5)
        self.assertEqual(R.indice_rilascio(c, 0, 8), 1)
        c[0] = (500, 5)
        self.assertEqual(R.indice_rilascio(c, 0, 8), 2)
        c[0] = (-50, 5)
        self.assertEqual(R.indice_rilascio(c, 0, 8), 0)

    def test_resta_dov_e(self):
        self.assertEqual(R.indice_rilascio(self.riga, 1, 8), 1)

    def test_a_capo(self):
        c = [(10, 5), (60, 5), (10, 35), (60, 35)]
        c[3] = (5, 5)  # ultimo trascinato in cima a sinistra
        self.assertEqual(R.indice_rilascio(c, 3, 10), 0)
        c = [(10, 5), (60, 5), (10, 35), (60, 35)]
        c[0] = (30, 35)  # primo trascinato nella 2a riga tra i due
        self.assertEqual(R.indice_rilascio(c, 0, 10), 2)


class TestRiquadro(unittest.TestCase):
    def test_destra_sotto(self):
        x, y, ok = R.posiziona_riquadro(100, 50, 80, 40, 400, 300)
        self.assertEqual((x, y, ok), (114, 64, True))

    def test_non_entra_sotto_va_sopra(self):
        x, y, ok = R.posiziona_riquadro(100, 280, 80, 60, 400, 300)
        self.assertEqual((x, y), (114, 280 - 14 - 60))
        self.assertTrue(ok)

    def test_non_entra_destra_va_sinistra(self):
        x, y, ok = R.posiziona_riquadro(380, 50, 80, 40, 400, 300)
        self.assertEqual(x, 380 - 14 - 80)
        self.assertTrue(ok)

    def test_area_troppo_bassa(self):
        _, _, ok = R.posiziona_riquadro(100, 40, 120, 90, 400, 90)
        self.assertFalse(ok)

    def test_area_troppo_stretta(self):
        _, _, ok = R.posiziona_riquadro(50, 50, 300, 40, 200, 300)
        self.assertFalse(ok)


if __name__ == "__main__":
    unittest.main()
