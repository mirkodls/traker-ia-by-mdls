// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
import 'package:flutter_test/flutter_test.dart';
import 'package:traker_ia/domain/preferenze.dart';
import 'package:traker_ia/domain/stile_linee.dart';

void main() {
  group('StileLinee', () {
    test('base = aspetto di oggi (nessun cambio visivo)', () {
      const StileLinee s = StileLinee();
      expect(s.predefinito, isTrue);
      for (final LineaGrafico l in LineaGrafico.values) {
        expect(s.di(l).alfa, 100, reason: l.nome);
        expect(s.di(l).spessore, l.spessorePredefinito, reason: l.nome);
      }
      expect(s.di(LineaGrafico.adattiva).spessore, 2.4);
      expect(s.di(LineaGrafico.settimana).spessore, 2);
    });

    test('nomi chiavi: v2_linea_<nome>_alfa/_spessore, 6 linee', () {
      expect(LineaGrafico.values.length, 6);
      expect(LineaGrafico.int5h.chiaveAlfa, 'v2_linea_int5h_alfa');
      expect(
        LineaGrafico.settimana.chiaveSpessore,
        'v2_linea_settimana_spessore',
      );
      expect(
        <String>{
          for (final LineaGrafico l in LineaGrafico.values) ...<String>[
            l.chiaveAlfa,
            l.chiaveSpessore,
          ],
        }.length,
        12,
      );
    });

    test('con(): limiti 0-100 e 0,5-6; tornare al base = base', () {
      StileLinee s = const StileLinee();
      s = s.con(LineaGrafico.ideale, alfa: 140, spessore: 9);
      expect(s.di(LineaGrafico.ideale).alfa, 100);
      expect(s.di(LineaGrafico.ideale).spessore, 6);
      s = s.con(LineaGrafico.ideale, alfa: -5, spessore: 0.1);
      expect(s.di(LineaGrafico.ideale).alfa, 0);
      expect(s.di(LineaGrafico.ideale).spessore, 0.5);
      expect(s.predefinito, isFalse);
      s = s.con(LineaGrafico.ideale, alfa: 100, spessore: 2);
      expect(s.predefinito, isTrue);
      expect(s, const StileLinee());
    });

    test('con(): una linea non cambia le altre', () {
      final StileLinee s = const StileLinee().con(
        LineaGrafico.sessione,
        alfa: 40,
        spessore: 4.5,
      );
      expect(s.di(LineaGrafico.sessione).alfa, 40);
      expect(s.di(LineaGrafico.sessione).spessore, 4.5);
      expect(s.di(LineaGrafico.settimana), LineaGrafico.settimana.predefinito);
      expect(s.di(LineaGrafico.adattiva).spessore, 2.4);
      expect(s == const StileLinee(), isFalse);
      expect(s.hashCode == const StileLinee().hashCode, isFalse);
    });

    test('mappa: salva e rilegge identico, 12 chiavi', () {
      final StileLinee s = const StileLinee()
          .con(LineaGrafico.settimana, alfa: 70, spessore: 3.5)
          .con(LineaGrafico.int7gg, alfa: 0, spessore: 6);
      final Map<String, String> m = s.aMappa();
      expect(m.length, 12);
      expect(m['v2_linea_settimana_alfa'], '70');
      expect(m['v2_linea_settimana_spessore'], '3.5');
      expect(m['v2_linea_adattiva_spessore'], '2.4');
      expect(StileLinee.daMappa(m), s);
    });

    test('valori rotti o fuori limiti -> predefinito di quella linea', () {
      final StileLinee s = StileLinee.daMappa(<String, String?>{
        'v2_linea_settimana_alfa': 'abc',
        'v2_linea_settimana_spessore': '99',
        'v2_linea_sessione_alfa': '250',
        'v2_linea_sessione_spessore': '',
        'v2_linea_ideale_alfa': '30',
        'v2_linea_ideale_spessore': '0,5',
        'v2_linea_adattiva_alfa': null,
        'v2_linea_adattiva_spessore': 'nan',
        'v2_linea_int5h_spessore': '-3',
      });
      expect(s.di(LineaGrafico.settimana).alfa, 100);
      expect(s.di(LineaGrafico.settimana).spessore, 2);
      expect(s.di(LineaGrafico.sessione).alfa, 100);
      expect(s.di(LineaGrafico.sessione).spessore, 2);
      expect(s.di(LineaGrafico.ideale).alfa, 30);
      expect(s.di(LineaGrafico.ideale).spessore, 0.5); // virgola ok
      expect(s.di(LineaGrafico.adattiva).spessore, 2.4);
      expect(s.di(LineaGrafico.int5h).spessore, 2);
      expect(StileLinee.daMappa(<String, String?>{}).predefinito, isTrue);
    });

    test('opacita 0-1 per il pittore', () {
      expect(const StileLinea(spessore: 2).opacita, 1);
      expect(const StileLinea(alfa: 25, spessore: 2).opacita, 0.25);
    });
  });

  group('Preferenze: stile e rosso', () {
    test('base: rosso acceso a 95, linee come oggi', () {
      final Preferenze p = Preferenze();
      expect(p.rossoAcceso, isTrue);
      expect(p.sogliaRosso, 95);
      expect(p.stileLinee.predefinito, isTrue);
      final Map<String, String> m = p.aMappa();
      expect(m[Chiavi.v2RossoAcceso], '1');
      expect(m[Chiavi.v2SogliaRosso], '95');
      expect(Preferenze.daMappa(<String, String?>{}).sogliaRosso, 95);
    });

    test('salva e rilegge; chiavi lette all avvio', () {
      final Preferenze p = Preferenze().copia(
        rossoAcceso: false,
        sogliaRosso: 80,
        stileLinee: const StileLinee().con(
          LineaGrafico.ideale,
          alfa: 55,
          spessore: 1.5,
        ),
      );
      final Preferenze q = Preferenze.daMappa(p.aMappa());
      expect(q.rossoAcceso, isFalse);
      expect(q.sogliaRosso, 80);
      expect(q.stileLinee.di(LineaGrafico.ideale).alfa, 55);
      expect(q.stileLinee.di(LineaGrafico.ideale).spessore, 1.5);
      expect(
        Chiavi.tutte,
        containsAll(<String>[
          Chiavi.v2RossoAcceso,
          Chiavi.v2SogliaRosso,
          'v2_linea_settimana_alfa',
          'v2_linea_int7gg_spessore',
        ]),
      );
    });

    test('soglia rossa: solo 50-100, altro -> 95', () {
      expect(sogliaRossoValida(50), 50);
      expect(sogliaRossoValida(100), 100);
      expect(sogliaRossoValida(49), 95);
      expect(sogliaRossoValida(101), 95);
      expect(sogliaRossoValida(null), 95);
      expect(
        Preferenze.daMappa(<String, String?>{Chiavi.v2SogliaRosso: 'x'})
            .sogliaRosso,
        95,
      );
      expect(Preferenze(sogliaRosso: 12).sogliaRosso, 95);
      expect(
        Preferenze.daMappa(<String, String?>{Chiavi.v2RossoAcceso: '0'})
            .rossoAcceso,
        isFalse,
      );
    });

    test('nessuna chiave segreta nelle nuove impostazioni', () {
      final String tutte = Preferenze().aMappa().keys.join(' ');
      for (final String v in <String>[
        'cookie',
        'token',
        'segret',
        'password',
      ]) {
        expect(tutte.contains(v), isFalse, reason: v);
      }
    });
  });
}
