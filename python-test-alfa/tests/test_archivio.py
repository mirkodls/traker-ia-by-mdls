import os
import sys
import tempfile
import unittest

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from data.archivio import CAMPI_L, Archivio  # noqa: E402
from domain import analisi as A  # noqa: E402

VECCHIO = "ora;settimanale;sessione;fonte;al_pc;lavoro\n2026-11-11 17:10;20;15;manuale;;0\n"


class TestArchivio(unittest.TestCase):
    def setUp(self):
        self.dir = tempfile.mkdtemp()

    def test_migra_colonne_in_fondo(self):
        with open(os.path.join(self.dir, "letture.csv"), "w", encoding="utf-8", newline="") as f:
            f.write(VECCHIO)
        a = Archivio(self.dir)
        with open(a.f_l, encoding="utf-8") as f:
            righe = f.read().splitlines()
        self.assertEqual(righe[0], ";".join(CAMPI_L))
        self.assertEqual(righe[1], "2026-11-11 17:10;20;15;manuale;;0;;")
        a.aggiungi_lettura(A.Lettura(A.parse("2026-11-11 18:00"), 22, 15, "auto", True, False,
                                     "Opus|Sonnet", "caveman"))
        ls = Archivio(self.dir).letture()  # seconda apertura: niente doppia migrazione
        self.assertEqual(len(ls), 2)
        self.assertEqual((ls[0].modelli, ls[0].skill), ("", ""))
        self.assertEqual((ls[1].modelli, ls[1].skill), ("Opus|Sonnet", "caveman"))

    def test_impostazioni_default_liste(self):
        a = Archivio(self.dir)
        d = a.impostazioni()
        self.assertEqual(d["modelli"], ["Opus", "Sonnet", "Fable", "Haiku"])
        self.assertEqual(d["skill"], ["caveman"])
        d["modelli"].append("X")
        self.assertNotIn("X", a.impostazioni()["modelli"])  # default non sporcato

    def test_cache_si_aggiorna(self):
        a = Archivio(self.dir)
        n = len(a.letture())
        a.letture().clear()  # copia: la cache non si sporca
        self.assertEqual(len(a.letture()), n)
        a.aggiungi_lettura(A.Lettura(A.parse("2026-11-12 10:00"), 30, 5))
        self.assertEqual(len(a.letture()), n + 1)
        a.aggiungi_evento(A.Evento(A.parse("2026-11-12 10:05"), "nota", "x"))
        self.assertEqual(a.eventi()[-1].testo, "x")


if __name__ == "__main__":
    unittest.main()
