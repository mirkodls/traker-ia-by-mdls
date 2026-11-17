// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
import 'package:flutter_test/flutter_test.dart';
import 'package:traker_ia/domain/modelli.dart';
import 'package:traker_ia/domain/tempo.dart';
import 'package:traker_ia/ui/grafico_dati.dart';

DateTime _t(String s) => interpreta(s)!;

Lettura _l(String o, double? sett, double? sess, {String fonte = 'auto'}) =>
    Lettura(ora: _t(o), sett: sett, sess: sess, fonte: fonte);

void main() {
  final DateTime da = _t('2026-11-13 10:00');
  final DateTime a = _t('2026-11-13 12:00');

  test('linee: un punto prima e uno dopo, manuali segnati', () {
    final DatiGrafico d = calcolaDatiGrafico(
      <Lettura>[
        _l('2026-11-13 08:00', 5, 1),
        _l('2026-11-13 09:00', 6, 2),
        _l('2026-11-13 10:30', 7, null, fonte: 'manuale'),
        _l('2026-11-13 11:30', 8, 4),
        _l('2026-11-13 13:00', 9, 5),
        _l('2026-11-13 14:00', 10, 6),
      ],
      <Evento>[],
      da,
      a,
      a,
    );
    expect(d.sett.map((PuntoG p) => p.valore), <double>[6, 7, 8, 9]);
    expect(d.sett[1].manuale, isTrue);
    expect(d.sess.map((PuntoG p) => p.valore), <double>[2, 4, 5]);
    expect(d.vuoto, isFalse);
  });

  test('reset, fasce lavoro tagliate, note numerate su tutte', () {
    final DatiGrafico d = calcolaDatiGrafico(
      <Lettura>[_l('2026-11-13 10:10', 50, 40), _l('2026-11-13 10:20', 50, 2)],
      <Evento>[
        Evento(ora: _t('2026-11-13 09:00'), tipo: TipoEvento.nota, testo: 'a'),
        Evento(ora: _t('2026-11-13 09:30'), tipo: TipoEvento.inizio),
        Evento(ora: _t('2026-11-13 11:00'), tipo: TipoEvento.nota, testo: 'b'),
      ],
      da,
      a,
      a,
    );
    expect(d.reset, <DateTime>[_t('2026-11-13 10:20')]);
    expect(d.fasce.single.inizio, da);
    expect(d.fasce.single.fine, a);
    expect(d.note.single.numero, 2);
    expect(d.note.single.testo, 'b');
    expect(d.maxIntensita, greaterThanOrEqualTo(1));
  });

  test('vuoto senza letture; passo intensità', () {
    expect(calcolaDatiGrafico(<Lettura>[], <Evento>[], da, a, a).vuoto, isTrue);
    expect(passoIntensita(da, a), 5);
    expect(passoIntensita(da, da.add(const Duration(days: 7))), 6);
    // mai meno di un punto ogni 5 minuti, mai più di ~1500 punti
    expect(passoIntensita(da, da.add(const Duration(days: 60))), 57);
  });

  test('geometria: x e tempo uno il contrario dell\'altro', () {
    final Geometria g = Geometria(larg: 466, alt: 300, da: da, a: a);
    expect(g.x(da), 48);
    expect(g.x(a), 448);
    expect(g.tempo(248), _t('2026-11-13 11:00'));
    expect(g.tempo(10), isNull);
    expect(g.y(100), 46);
    expect(g.y(0), 270);
    expect(g.disegnabile, isTrue);
    expect(Geometria(larg: 50, alt: 300, da: da, a: a).disegnabile, isFalse);
  });

  test('note vicine scendono; nota sotto il mouse', () {
    final Geometria g = Geometria(larg: 466, alt: 300, da: da, a: a);
    final List<PostoNota> p = postiNote(<NotaG>[
      NotaG(1, _t('2026-11-13 11:00'), 'x'),
      NotaG(2, _t('2026-11-13 11:02'), 'y'),
    ], g);
    expect(p[0].cy, 37);
    expect(p[1].cy, 58);
    expect(notaVicina(p, p[1].x, 58)!.numero, 2);
    expect(notaVicina(p, p[0].x + 3, 200)!.numero, 1);
    expect(notaVicina(p, 60, 200), isNull);
  });

  test('aggancio alla lettura vera vicina', () {
    final List<Lettura> ls = <Lettura>[_l('2026-11-13 11:00', 1, 1)];
    final DateTime t = _t('2026-11-13 11:03');
    expect(
      agganciaLettura(ls, t, 5 * 60 * 1000000, da, a),
      _t('2026-11-13 11:00'),
    );
    expect(agganciaLettura(ls, t, 60 * 1000000, da, a), t);
  });
}
