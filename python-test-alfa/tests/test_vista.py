import os
import sys
import unittest

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from domain import vista as V  # noqa: E402


class TestVista(unittest.TestCase):
    def test_normalizza(self):
        self.assertEqual(V.normalizza(None), V.base())
        self.assertEqual(V.normalizza({"modo": "boh", "visibili": "x"}), V.base())
        v = V.normalizza({"visibili": {"dati": False, "ignota": False}, "modo": "grafico",
                          "primo_piano": True, "aperte": {"barra": 1}})
        self.assertFalse(v["visibili"]["dati"])
        self.assertNotIn("ignota", v["visibili"])
        self.assertTrue(v["aperte"]["barra"])  # 1 non e' bool: resta default
        self.assertEqual(v["modo"], "grafico")
        self.assertTrue(v["primo_piano"])

    def test_mostra_tutto_ordine(self):
        v = V.base()
        self.assertEqual([s for s, _ in V.mostra(v)], list(V.SEZIONI))
        v = V.cambia_visibile(v, "dati")
        v = V.cambia_aperta(v, "barra")
        m = dict(V.mostra(v))
        self.assertNotIn("dati", m)
        self.assertFalse(m["barra"])
        self.assertTrue(V.con_titoli(v))

    def test_modi_solo(self):
        v = V.scegli_modo(V.base(), "grafico")
        self.assertEqual(V.mostra(v), [("grafico", True)])
        self.assertFalse(V.con_titoli(v))
        self.assertEqual(V.chi_espande(v), "grafico")
        v = V.scegli_modo(v, "intensita")
        self.assertEqual(V.chi_espande(v), "intensita")
        self.assertTrue(V.spuntata(v, "intensita"))
        self.assertFalse(V.spuntata(v, "carte"))

    def test_tutto_riapre(self):
        v = V.cambia_aperta(V.cambia_visibile(V.base(), "dati"), "grafico")
        v = V.scegli_modo(v, "tutto")
        self.assertEqual(V.mostra(v), [(s, True) for s in V.SEZIONI])

    def test_spunta_da_solo(self):
        v = V.scegli_modo(V.base(), "grafico")
        v = V.cambia_visibile(v, "dati")  # da solo grafico: grafico + dati
        self.assertEqual(v["modo"], "tutto")
        self.assertEqual([s for s, _ in V.mostra(v)], ["grafico", "dati"])

    def test_chi_espande(self):
        v = V.base()
        self.assertEqual(V.chi_espande(v), "grafico")
        v = V.cambia_aperta(v, "grafico")
        self.assertEqual(V.chi_espande(v), "intensita")
        v = V.cambia_visibile(v, "intensita")
        self.assertIsNone(V.chi_espande(v))

    def test_primo_piano_non_muta(self):
        v = V.base()
        n = V.cambia_primo_piano(v)
        self.assertTrue(n["primo_piano"])
        self.assertFalse(v["primo_piano"])

    def test_disponi_una_riga(self):
        self.assertEqual(V.disponi([[50, 50]], 200, 4), [(0, 0, 0, 0), (0, 1, 54, 0)])

    def test_disponi_a_capo(self):
        r = V.disponi([[80, 80, 80]], 170, 4)
        self.assertEqual([(x, rg) for _, _, x, rg in r], [(0, 0), (84, 0), (0, 1)])

    def test_disponi_gruppo_destra(self):
        r = V.disponi([[50], [40, 40]], 300, 4)
        self.assertEqual(r[1:], [(1, 0, 216, 0), (1, 1, 260, 0)])

    def test_disponi_gruppo_a_capo(self):
        r = V.disponi([[100, 100], [60, 60]], 250, 4)
        self.assertEqual([(g, x, rg) for g, _, x, rg in r],
                         [(0, 0, 0), (0, 104, 0), (1, 0, 1), (1, 64, 1)])

    def test_disponi_elemento_troppo_largo(self):
        r = V.disponi([[500, 20]], 100, 4)  # mai riga vuota
        self.assertEqual([(x, rg) for _, _, x, rg in r], [(0, 0), (0, 1)])


if __name__ == "__main__":
    unittest.main()
