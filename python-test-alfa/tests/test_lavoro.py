import os
import sys
import unittest

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from domain import analisi as A  # noqa: E402
from domain import combinazioni as C  # noqa: E402
from domain import confronti as K  # noqa: E402
from domain import lavoro as LV  # noqa: E402

T = A.parse


def L(ora, sett, sess=None, m="", s=""):
    return A.Lettura(T(ora), sett, sess, modelli=m, skill=s)


def E(ora, tipo):
    return A.Evento(T(ora), tipo)


class TestPeriodi(unittest.TestCase):
    def test_chiusi_e_aperto(self):
        ev = [E("2026-11-11 10:00", "inizio"), E("2026-11-11 12:00", "fine"),
              E("2026-11-11 12:00", "inizio"), E("2026-11-11 13:00", "nota"), E("2026-11-11 14:00", "fine"),
              E("2026-11-11 18:00", "inizio")]
        p = LV.periodi_lavoro(ev, T("2026-11-11 20:00"))
        self.assertEqual(p, [(T("2026-11-11 10:00"), T("2026-11-11 12:00")),
                             (T("2026-11-11 12:00"), T("2026-11-11 14:00")),
                             (T("2026-11-11 18:00"), T("2026-11-11 20:00"))])

    def test_doppi_e_orfani(self):
        ev = [E("2026-11-11 09:00", "fine"), E("2026-11-11 10:00", "inizio"),
              E("2026-11-11 11:00", "inizio"), E("2026-11-11 12:00", "fine")]
        self.assertEqual(LV.periodi_lavoro(ev, T("2026-11-11 20:00")),
                         [(T("2026-11-11 10:00"), T("2026-11-11 12:00"))])

    def test_vuoto(self):
        self.assertEqual(LV.periodi_lavoro([], T("2026-11-11 20:00")), [])


class TestRitmo(unittest.TestCase):
    def setUp(self):
        # 10:00 0 -> 12:00 4 (2 pt/h) -> 14:00 4 (0 pt/h)
        self.l = [L("2026-11-11 10:00", 0), L("2026-11-11 12:00", 4), L("2026-11-11 14:00", 4)]

    def test_senza_periodi_uguale_a_ritmo(self):
        r, h = LV.ritmo_ore(self.l)
        self.assertAlmostEqual(r, A.ritmo(self.l))
        self.assertAlmostEqual(h, 4.0)

    def test_taglio_proporzionale(self):
        p = [(T("2026-11-11 11:00"), T("2026-11-11 13:00"))]
        r, h = LV.ritmo_ore(self.l, periodi=p)
        self.assertAlmostEqual(h, 2.0)       # 1 h nella prima coppia + 1 h nella seconda
        self.assertAlmostEqual(r, 1.0)       # (2 + 0) / 2

    def test_reset_escluso(self):
        ls = self.l + [L("2026-11-11 15:00", 0), L("2026-11-11 16:00", 1)]
        p = [(T("2026-11-11 14:00"), T("2026-11-11 16:00"))]
        r, h = LV.ritmo_ore(ls, periodi=p)
        self.assertAlmostEqual(h, 1.0)
        self.assertAlmostEqual(r, 1.0)

    def test_nessuna_sovrapposizione(self):
        r, h = LV.ritmo_ore(self.l, periodi=[(T("2026-11-12 10:00"), T("2026-11-12 11:00"))])
        self.assertIsNone(r)
        self.assertEqual(h, 0.0)


class TestNotaLavoro(unittest.TestCase):
    def setUp(self):
        # settimana dal mar 10/11 20:00; nota mer 11/11 12:00
        self.l = [L("2026-11-11 08:00", 0), L("2026-11-11 10:00", 2), L("2026-11-11 12:00", 6),
                  L("2026-11-11 14:00", 6), L("2026-11-11 16:00", 8)]
        self.nota = T("2026-11-11 12:00")

    def test_spunta_spenta_invariato(self):
        c = K.confronto_nota(self.l, self.nota)
        self.assertEqual(c.filtro, "")
        self.assertAlmostEqual(c.prima, 1.5)
        self.assertAlmostEqual(c.dopo, 0.5)
        self.assertEqual(c.verdetto, "SCESO")

    def test_solo_lavoro(self):
        p = [(T("2026-11-11 10:00"), T("2026-11-11 12:00")), (T("2026-11-11 14:00"), T("2026-11-11 16:00"))]
        c = K.confronto_nota(self.l, self.nota, periodi=p)
        self.assertEqual(c.filtro, "lavoro")
        self.assertAlmostEqual(c.prima, 2.0)
        self.assertAlmostEqual(c.dopo, 1.0)
        self.assertAlmostEqual(c.ore_prima, 2.0)
        self.assertAlmostEqual(c.ore_dopo, 2.0)
        self.assertEqual(c.verdetto, "SCESO")

    def test_un_lato_senza_lavoro_conta_tutto(self):
        p = [(T("2026-11-11 14:00"), T("2026-11-11 16:00"))]
        c = K.confronto_nota(self.l, self.nota, periodi=p)
        self.assertEqual(c.filtro, "tutto")
        self.assertAlmostEqual(c.prima, 1.5)
        self.assertAlmostEqual(c.ore_prima, 4.0)
        self.assertEqual(K.testo_filtro(c.filtro), "(nessun periodo lavoro: conta tutto)")


class TestCombinazioniLavoro(unittest.TestCase):
    def setUp(self):
        self.l = [L("2026-11-11 10:00", 0), L("2026-11-11 12:00", 4, m="Opus"),
                  L("2026-11-11 14:00", 5, m="Sonnet")]
        self.ka, self.kb = ("Opus", ""), ("Sonnet", "")

    def test_tab_filtrata(self):
        p = [(T("2026-11-11 11:00"), T("2026-11-11 14:00"))]
        tab = C.ritmo_per_combinazione(self.l, p)
        self.assertAlmostEqual(tab[self.ka]["ore"], 1.0)
        self.assertAlmostEqual(tab[self.ka]["sett"], 2.0)
        self.assertAlmostEqual(tab[self.kb]["ore"], 2.0)

    def test_confronto_lavoro_e_ricaduta(self):
        tutto = C.ritmo_per_combinazione(self.l)
        p = [(T("2026-11-11 11:00"), T("2026-11-11 14:00"))]
        c = K.confronto_combinazioni(tutto, self.ka, self.kb, tab_lavoro=C.ritmo_per_combinazione(self.l, p))
        self.assertEqual(c.filtro, "lavoro")
        self.assertAlmostEqual(c.a, 2.0)
        p2 = [(T("2026-11-11 13:00"), T("2026-11-11 14:00"))]  # Opus senza ore di lavoro
        c2 = K.confronto_combinazioni(tutto, self.ka, self.kb, tab_lavoro=C.ritmo_per_combinazione(self.l, p2))
        self.assertEqual(c2.filtro, "tutto")
        self.assertAlmostEqual(c2.a, 2.0)
        self.assertAlmostEqual(c2.b, 0.5)


class TestArrotondaReset(unittest.TestCase):
    def test_casi(self):
        f = LV.arrotonda_reset
        self.assertEqual(f(T("2026-11-17 19:59")), T("2026-11-17 20:00"))
        self.assertEqual(f(T("2026-11-17 19:58")), T("2026-11-17 20:00"))
        self.assertEqual(f(T("2026-11-17 20:02")), T("2026-11-17 20:00"))
        self.assertEqual(f(T("2026-11-17 19:57")), T("2026-11-17 19:57"))
        self.assertEqual(f(T("2026-11-17 20:03")), T("2026-11-17 20:03"))
        self.assertEqual(f(T("2026-11-17 23:59")), T("2026-11-18 00:00"))
        self.assertIsNone(f(None))
