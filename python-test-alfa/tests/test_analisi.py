import os
import sys
import tempfile
import unittest
from datetime import datetime

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from data.archivio import Archivio  # noqa: E402
from domain import analisi as A  # noqa: E402

P = A.parse


class TestAnalisi(unittest.TestCase):
    def test_risposta_percento(self):
        u = A.leggi_risposta({"five_hour": {"utilization": 14.0, "resets_at": "2026-11-11T22:00:00.123456789Z"},
                              "seven_day": {"utilization": 21, "resets_at": None}})
        self.assertEqual((u.sess, u.sett), (14.0, 21.0))
        self.assertIsNotNone(u.reset_sess)
        self.assertIsNone(u.reset_sett)

    def test_risposta_frazione(self):
        u = A.leggi_risposta({"five_hour": {"utilization": 0.14}, "seven_day": {"utilization": 0.25}})
        self.assertAlmostEqual(u.sess, 14.0)
        self.assertAlmostEqual(u.sett, 25.0)

    def test_risposta_vuota(self):
        u = A.leggi_risposta({"five_hour": None})
        self.assertIsNone(u.sess)

    def test_inizio_settimana(self):
        self.assertEqual(A.inizio_settimana(P("2026-11-11 21:11")), P("2026-11-10 20:00"))
        self.assertEqual(A.inizio_settimana(P("2026-11-10 19:59")), P("2026-11-03 20:00"))
        self.assertEqual(A.inizio_settimana(P("2026-11-10 20:00")), P("2026-11-10 20:00"))

    def test_ritmo_e_reset(self):
        ls = [A.Lettura(P("2026-11-11 10:00"), 10, 50), A.Lettura(P("2026-11-11 12:00"), 14, 80),
              A.Lettura(P("2026-11-11 13:00"), 15, 2)]
        self.assertAlmostEqual(A.ritmo(ls, "sett"), 5 / 3)
        self.assertEqual(A.trova_reset(ls, "sess"), [P("2026-11-11 13:00")])
        self.assertAlmostEqual(A.ritmo(ls, "sess"), 15.0)  # coppia col reset esclusa

    def test_confronto_esempio(self):
        ls = [A.Lettura(P("2026-11-10 20:00"), 0, None), A.Lettura(P("2026-11-11 17:10"), 20, 15),
              A.Lettura(P("2026-11-11 21:11"), 24, 10)]
        prima, dopo, v = A.confronto(ls, P("2026-11-11 17:28"))
        self.assertAlmostEqual(dopo, 4 / (241 / 60))
        self.assertTrue(0.9 < prima < 1.1)
        self.assertEqual(v, "costante")

    def test_verdetto(self):
        self.assertEqual(A.verdetto(1.0, 0.5), "sceso")
        self.assertEqual(A.verdetto(1.0, 1.5), "salito")
        self.assertEqual(A.verdetto(1.0, 1.05), "costante")
        self.assertEqual(A.verdetto(None, 1), "dati insufficienti")

    def test_presenza(self):
        ls = [A.Lettura(P("2026-11-11 10:00"), 10, None, al_pc=True),
              A.Lettura(P("2026-11-11 11:00"), 12, None, al_pc=True),
              A.Lettura(P("2026-11-11 12:00"), 13, None, al_pc=False)]
        self.assertEqual(A.ritmo_per_presenza(ls), (2.0, 1.0))


class TestIntensita(unittest.TestCase):
    def test_costante(self):
        ls = [A.Lettura(P("2026-11-11 10:00"), None, 10), A.Lettura(P("2026-11-11 11:00"), None, 20)]
        s = A.serie_intensita(ls, P("2026-11-11 10:30"), P("2026-11-11 11:00"))
        self.assertEqual(len(s), 7)
        for _, v in s:
            self.assertAlmostEqual(v, 10.0)

    def test_reset_escluso(self):
        ls = [A.Lettura(P("2026-11-11 10:00"), None, 80), A.Lettura(P("2026-11-11 10:30"), None, 90),
              A.Lettura(P("2026-11-11 11:00"), None, 2), A.Lettura(P("2026-11-11 11:30"), None, 7)]
        s = dict(A.serie_intensita(ls, P("2026-11-11 10:00"), P("2026-11-11 11:30"), 30, 30))
        self.assertAlmostEqual(s[P("2026-11-11 10:30")], 20.0)
        self.assertIsNone(s[P("2026-11-11 11:00")])   # solo coppia col reset
        self.assertAlmostEqual(s[P("2026-11-11 11:30")], 10.0)

    def test_senza_dati(self):
        s = A.serie_intensita([], P("2026-11-11 10:00"), P("2026-11-11 10:10"))
        self.assertEqual([v for _, v in s], [None, None, None])


class TestValoreA(unittest.TestCase):
    def setUp(self):
        self.ls = [A.Lettura(P("2026-11-11 10:00"), 10, 20), A.Lettura(P("2026-11-11 11:00"), 20, 40),
                   A.Lettura(P("2026-11-11 12:00"), 22, 2)]

    def test_esatto(self):
        self.assertEqual(A.valore_a(self.ls, "sett", P("2026-11-11 11:00")), (20, True))

    def test_esatto_con_tolleranza(self):
        self.assertEqual(A.valore_a(self.ls, "sett", P("2026-11-11 11:01"), tol_s=120), (20, True))

    def test_interpolato(self):
        v, esatto = A.valore_a(self.ls, "sett", P("2026-11-11 10:30"))
        self.assertAlmostEqual(v, 15.0)
        self.assertFalse(esatto)

    def test_reset_nessun_valore(self):
        self.assertEqual(A.valore_a(self.ls, "sess", P("2026-11-11 11:30")), (None, False))

    def test_fuori_dati(self):
        self.assertEqual(A.valore_a(self.ls, "sett", P("2026-11-11 09:00")), (None, False))
        self.assertEqual(A.valore_a([], "sett", P("2026-11-11 09:00")), (None, False))

    def test_intensita_a_come_serie(self):
        ls = [A.Lettura(P("2026-11-11 10:00"), None, 10), A.Lettura(P("2026-11-11 11:00"), None, 20)]
        self.assertAlmostEqual(A.intensita_a(ls, P("2026-11-11 10:45")), 10.0)
        self.assertIsNone(A.intensita_a([], P("2026-11-11 10:45")))


class TestArchivio(unittest.TestCase):
    def test_dati_iniziali_e_scrittura(self):
        with tempfile.TemporaryDirectory() as d:
            a = Archivio(d)
            self.assertEqual(len(a.letture()), 0)  # archivio nuovo = vuoto
            self.assertEqual(a.eventi(), [])
            a.aggiungi_lettura(A.Lettura(datetime(2026, 11, 11, 22, 0), 26.5, None, "auto", True, True))
            ult = Archivio(d).letture()[-1]
            self.assertEqual((ult.sett, ult.sess, ult.al_pc, ult.lavoro), (26.5, None, True, True))
            a.salva_impostazioni({**a.impostazioni(), "minuti": 15})
            self.assertEqual(a.impostazioni()["minuti"], 15)


if __name__ == "__main__":
    unittest.main()
