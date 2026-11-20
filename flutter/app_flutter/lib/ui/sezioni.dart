// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
//
// Strato ui: sezioni della finestra (carte, tasti modelli/skill + nota,
// "Cosa dicono i dati", carta CONFRONTI).
import 'dart:async';

import 'package:material_ui/material_ui.dart';

import 'package:traker_ia/domain/analisi.dart';
import 'package:traker_ia/domain/combinazioni.dart';
import 'package:traker_ia/domain/confronti.dart';
import 'package:traker_ia/domain/modelli.dart';
import 'package:traker_ia/domain/preferenze.dart';
import 'package:traker_ia/domain/tempo.dart';
import 'package:traker_ia/domain/traduzioni/testi_it.dart';
import 'package:traker_ia/ui/stato_app.dart';
import 'package:traker_ia/ui/tema.dart';

// ------------------------------------------------------------------ carte

/// Carta con la percentuale (sessione o settimana).
class CartaPercento extends StatelessWidget {
  /// Crea la carta.
  const CartaPercento({
    required this.titolo,
    required this.valore,
    required this.colore,
    super.key,
  });

  /// Titolo.
  final String titolo;

  /// Valore e riga sotto.
  final ValoreCarta valore;

  /// Colore del numero e della barra.
  final Color colore;

  @override
  Widget build(BuildContext context) {
    final double? v = valore.valore;
    return Carta(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(
                percento(v),
                style: TextStyle(
                  color: colore,
                  fontSize: Misure.carta,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(titolo, style: stileTitolo),
                    Text(valore.sotto, style: stilePiccolo),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: v == null ? 0 : (v / 100).clamp(0, 1).toDouble(),
              minHeight: 4,
              color: colore,
              backgroundColor: Colori.carta2,
            ),
          ),
        ],
      ),
    );
  }
}

/// Carta testo (es. CREDITI): valore grande, titolo e riga sotto.
class CartaTesto extends StatelessWidget {
  /// Crea la carta.
  const CartaTesto({
    required this.titolo,
    required this.valore,
    required this.sotto,
    required this.colore,
    super.key,
  });

  /// Titolo.
  final String titolo;

  /// Valore grande (es. '0,00 \$').
  final String valore;

  /// Riga sotto.
  final String sotto;

  /// Colore del valore.
  final Color colore;

  @override
  Widget build(BuildContext context) => Carta(
    padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
    child: Row(
      children: <Widget>[
        Text(
          valore,
          style: TextStyle(
            color: colore,
            fontSize: Misure.carta,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(titolo, style: stileTitolo),
              Text(sotto, style: stilePiccolo),
            ],
          ),
        ),
      ],
    ),
  );
}

/// Riga di stato: pallino + testo.
class RigaStato extends StatelessWidget {
  /// Crea la riga.
  const RigaStato({required this.stato, super.key});

  /// Stato dell'app.
  final StatoApp stato;

  @override
  Widget build(BuildContext context) {
    final Color c = stato.statoErrore ? Colori.errore : Colori.ok;
    return Padding(
      padding: const EdgeInsets.only(top: 6, left: 2),
      child: Row(
        children: <Widget>[
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: c, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              stato.stato,
              style: stilePiccolo.copyWith(
                color: stato.statoErrore ? Colori.errore : Colori.spento,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------ tasti

/// Tasto modello/skill: clic = accendi/spegni, trascina = cambia ordine.
class _Tasto extends StatelessWidget {
  const _Tasto({
    required this.gruppo,
    required this.nome,
    required this.acceso,
    required this.stato,
    this.fisso = false,
  });

  final Gruppo gruppo;
  final String nome;
  final bool acceso;
  final StatoApp stato;

  /// Telefono: solo tocco, niente trascina (ordine dalla rotella ⚙).
  final bool fisso;

  Widget _faccia({bool ombra = false}) {
    final Color sfondo = acceso
        ? (gruppo == Gruppo.modelli ? Colori.accento : Colori.skill)
        : Colori.carta2;
    final Color testo = acceso ? Colors.white : Colori.spento;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: sfondo,
        borderRadius: BorderRadius.circular(14),
        boxShadow: ombra
            ? const <BoxShadow>[BoxShadow(blurRadius: 6, color: Colors.black54)]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (gruppo == Gruppo.modelli)
            Container(
              width: 16,
              height: 16,
              margin: const EdgeInsets.only(right: 6),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: acceso ? Colors.white24 : Colori.bordo,
              ),
              child: Text(
                nome.characters.first.toUpperCase(),
                style: TextStyle(
                  color: testo,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 5),
              child: Text(
                acceso ? '●' : '○',
                style: TextStyle(color: testo, fontSize: 10),
              ),
            ),
          Text(
            nome,
            style: TextStyle(color: testo, fontSize: Misure.piccolo),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (fisso) {
      return GestureDetector(
        onTap: () => stato.tocca(gruppo, nome),
        child: _faccia(),
      );
    }
    final List<String> lista = stato.preferenze.elenco(gruppo);
    return DragTarget<(Gruppo, String)>(
      onWillAcceptWithDetails: (DragTargetDetails<(Gruppo, String)> d) =>
          d.data.$1 == gruppo && d.data.$2 != nome,
      onAcceptWithDetails: (DragTargetDetails<(Gruppo, String)> d) {
        final List<String> n = List<String>.of(lista)..remove(d.data.$2);
        n.insert(lista.indexOf(nome).clamp(0, n.length), d.data.$2);
        unawaited(stato.riordina(gruppo, n));
      },
      builder: (BuildContext context, List<(Gruppo, String)?> sopra, _) =>
          Draggable<(Gruppo, String)>(
            data: (gruppo, nome),
            feedback: Material(
              type: MaterialType.transparency,
              child: _faccia(ombra: true),
            ),
            childWhenDragging: Opacity(opacity: 0.3, child: _faccia()),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => stato.tocca(gruppo, nome),
                child: Container(
                  decoration: sopra.isEmpty
                      ? null
                      : const BoxDecoration(
                          border: Border(
                            left: BorderSide(color: Colori.testo, width: 2),
                          ),
                        ),
                  child: _faccia(),
                ),
              ),
            ),
          ),
    );
  }
}

/// Gruppo di tasti con titolo e "modifica".
class _GruppoTasti extends StatelessWidget {
  const _GruppoTasti({
    required this.gruppo,
    required this.stato,
    required this.modifica,
    this.destra = false,
    this.compatta = false,
  });

  final Gruppo gruppo;
  final StatoApp stato;
  final VoidCallback modifica;
  final bool destra;
  final bool compatta;

  @override
  Widget build(BuildContext context) {
    final Preferenze p = stato.preferenze;
    final Set<String> acc = p.accesi(gruppo).toSet();
    final List<Widget> figli = <Widget>[
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text(
          gruppo == Gruppo.modelli ? Testi.gruppoModelli : Testi.gruppoSkill,
          style: stileTitolo,
        ),
      ),
      for (final String n in p.elenco(gruppo))
        _Tasto(
          gruppo: gruppo,
          nome: n,
          acceso: acc.contains(n),
          stato: stato,
          fisso: compatta,
        ),
      if (!compatta)
        TextButton(
          onPressed: modifica,
          style: TextButton.styleFrom(foregroundColor: Colori.spento),
          child: const Text(
            Testi.modifica,
            style: TextStyle(fontSize: Misure.piccolo),
          ),
        ),
    ];
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      alignment: destra ? WrapAlignment.end : WrapAlignment.start,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: figli,
    );
  }
}

/// Barra tasti: skill a sinistra, modelli a destra (a capo se stretto).
class BarraTasti extends StatelessWidget {
  /// Crea la barra.
  const BarraTasti({
    required this.stato,
    required this.modifica,
    this.compatta = false,
    super.key,
  });

  /// Telefono: una riga sola che scorre di lato (modelli poi skill).
  final bool compatta;

  /// Stato dell'app.
  final StatoApp stato;

  /// Apre il dialogo modifica del gruppo.
  final void Function(Gruppo) modifica;

  @override
  Widget build(BuildContext context) {
    if (compatta) {
      // Telefono: tasti fermi (vanno a capo), solo tocco.
      return Carta(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _GruppoTasti(
              gruppo: Gruppo.modelli,
              stato: stato,
              modifica: () => modifica(Gruppo.modelli),
              compatta: true,
            ),
            const SizedBox(height: 4),
            _GruppoTasti(
              gruppo: Gruppo.skill,
              stato: stato,
              modifica: () => modifica(Gruppo.skill),
              compatta: true,
            ),
          ],
        ),
      );
    }
    final Widget sk = _GruppoTasti(
      gruppo: Gruppo.skill,
      stato: stato,
      modifica: () => modifica(Gruppo.skill),
    );
    final Widget mo = _GruppoTasti(
      gruppo: Gruppo.modelli,
      stato: stato,
      modifica: () => modifica(Gruppo.modelli),
      destra: true,
    );
    return Tooltip(
      message: Testi.aiutoTasti,
      waitDuration: const Duration(seconds: 2),
      child: Carta(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints c) => c.maxWidth >= 700
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(child: sk),
                    const SizedBox(width: 12),
                    Expanded(child: mo),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[sk, const SizedBox(height: 6), mo],
                ),
        ),
      ),
    );
  }
}

/// Riga nota + inizio/fine lavoro.
class RigaNota extends StatefulWidget {
  /// Crea la riga.
  const RigaNota({required this.stato, super.key});

  /// Stato dell'app.
  final StatoApp stato;

  @override
  State<RigaNota> createState() => _StatoRigaNota();
}

class _StatoRigaNota extends State<RigaNota> {
  final TextEditingController _testo = TextEditingController();

  @override
  void dispose() {
    _testo.dispose();
    super.dispose();
  }

  Future<void> _aggiungi() async {
    final String t = _testo.text;
    _testo.clear();
    await widget.stato.aggiungiNota(t);
  }

  @override
  Widget build(BuildContext context) {
    final bool lav = widget.stato.lavoro;
    final Widget tastoLavoro = Tooltip(
      message: Testi.spiegaLavoro,
      child: FilledButton(
        onPressed: widget.stato.cambiaLavoro,
        style: FilledButton.styleFrom(
          backgroundColor: lav ? Colori.fineSfondo : Colori.inizioSfondo,
          foregroundColor: lav ? Colori.errore : Colori.ok,
        ),
        child: Text(
          lav ? Testi.fineLavoro : Testi.inizioLavoro,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
    final Widget campo = Row(
      children: <Widget>[
        const Text('✎', style: TextStyle(color: Colori.nota, fontSize: 17)),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: _testo,
            style: stileNormale,
            decoration: const InputDecoration(hintText: Testi.scriviNota),
            onSubmitted: (_) => _aggiungi(),
          ),
        ),
      ],
    );
    final Widget aggiungi = FilledButton(
      onPressed: _aggiungi,
      style: stileAccento(),
      child: const Text(Testi.aggiungiNota),
    );
    final Widget nota = Row(
      children: <Widget>[
        Expanded(child: campo),
        const SizedBox(width: 8),
        aggiungi,
      ],
    );
    return Carta(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints c) => c.maxWidth >= 520
            ? Row(
                children: <Widget>[
                  Expanded(child: nota),
                  const SizedBox(width: 8),
                  tastoLavoro,
                ],
              )
            : Column(
                // Stretto (telefono): campo nota intero, tasti sotto.
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  campo,
                  const SizedBox(height: 6),
                  Row(
                    children: <Widget>[
                      Expanded(child: aggiungi),
                      const SizedBox(width: 8),
                      Expanded(child: tastoLavoro),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}

// ------------------------------------------------------------------ dati

/// Riquadro "Cosa dicono i dati" (previsione, budget, ore a pieno regime).
class CartaDati extends StatelessWidget {
  /// Crea il riquadro.
  const CartaDati({required this.stato, super.key});

  /// Stato dell'app.
  final StatoApp stato;

  @override
  Widget build(BuildContext context) => Carta(
    child: SizedBox(
      width: double.infinity,
      child: Text(
        stato.frasi.join('\n'),
        style: stileNormale.copyWith(height: 1.5),
      ),
    ),
  );
}

// ------------------------------------------------------------------ confronti

Color _coloreVerdetto(Verdetto v) => switch (v) {
  Verdetto.sceso => Colori.ok,
  Verdetto.salito => Colori.errore,
  Verdetto.costante => Colori.sett,
  Verdetto.datoDebole => Colori.spento,
};

/// Testo con spiegazione al passaggio del mouse (dito tenuto sul telefono).
class _Spiegato extends StatelessWidget {
  const _Spiegato(this.testo, {this.spiega = '', this.stile = stileNormale});

  final String testo;
  final String spiega;
  final TextStyle stile;

  @override
  Widget build(BuildContext context) {
    final Widget t = Text(testo, style: stile);
    return spiega.isEmpty ? t : Tooltip(message: spiega, child: t);
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.v);

  final Verdetto v;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: spiegaVerdetto(v),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: Colori.carta2,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        v.etichetta,
        style: TextStyle(
          color: _coloreVerdetto(v),
          fontSize: Misure.normale,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  );
}

Widget _tendina<T>({
  required T? valore,
  required List<T> voci,
  required String Function(T) nome,
  required void Function(T) scelto,
  double larghezza = 260,
}) => SizedBox(
  width: larghezza,
  child: DropdownButtonHideUnderline(
    child: DropdownButton<T>(
      isExpanded: true,
      isDense: true,
      value: valore,
      dropdownColor: Colori.carta2,
      style: stileNormale,
      items: <DropdownMenuItem<T>>[
        for (final T v in voci)
          DropdownMenuItem<T>(
            value: v,
            child: Text(nome(v), overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: (T? v) {
        if (v != null) {
          scelto(v);
        }
      },
    ),
  ),
);

/// Carta CONFRONTI: nota prima/dopo, combinazioni A/B, classifica.
class CartaConfronti extends StatelessWidget {
  /// Crea la carta.
  const CartaConfronti({required this.stato, super.key});

  /// Stato dell'app.
  final StatoApp stato;

  static const String _unitaSpiega =
      '${Testi.pth}\n${Testi.sett}\n${Testi.freccia}';

  List<Widget> _rigaNota() {
    final ConfrontoNota? c = stato.confrontoNota;
    final List<Evento> note = stato.note;
    final Map<DateTime, int> numeri = <DateTime, int>{
      for (int i = 0; i < note.length; i++) note[i].ora: i + 1,
    };
    return <Widget>[
      const Text(Testi.nota, style: stileTitolo),
      if (note.isNotEmpty)
        _tendina<Evento>(
          valore: stato.notaScelta,
          voci: note,
          nome: (Evento e) =>
              Testi.voceNota(numeri[e.ora] ?? 0, quandoData(e.ora), e.testo),
          scelto: stato.scegliNota,
          larghezza: 300,
        ),
      if (c == null)
        const Text(Testi.nessunaNota, style: stilePiccolo)
      else ...<Widget>[
        _Spiegato(Testi.prima(numero(c.prima)), spiega: spiegaPrima(c)),
        const Text('→', style: stilePiccolo),
        _Spiegato(
          Testi.dopo(numero(c.dopo)),
          spiega: spiegaDopo(c, stato.adesso),
        ),
        const _Spiegato('${Testi.unitaSett}  ·', spiega: _unitaSpiega),
        _Badge(c.verdetto),
        _Spiegato(
          '${testoOreNota(c)} ${testoFiltro(c.filtro)}'.trim(),
          spiega: Testi.spiegaOreNota,
          stile: stilePiccolo,
        ),
      ],
      Tooltip(
        message: Testi.spiegaSoloLavoro,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Checkbox(
              value: stato.preferenze.soloLavoro,
              visualDensity: VisualDensity.compact,
              onChanged: (bool? v) =>
                  stato.cambiaSoloLavoro(acceso: v ?? false),
            ),
            const Text(Testi.contaSoloLavoro, style: stilePiccolo),
          ],
        ),
      ),
    ];
  }

  String _spiegaCombo(int lato, Combo? k) {
    if (k == null) {
      return '';
    }
    final RitmoCombo? r = stato.tabellaCombo[k];
    if (r == null) {
      return '';
    }
    final String base = spiegaCombo(
      lato == 0 ? 'A' : 'B',
      k,
      stato.periodoDi(k),
      r.ore,
    );
    final ConfrontoCombo? cc = stato.confrontoCombo;
    final String f = cc == null ? '' : testoFiltro(cc.filtro);
    return f.isEmpty ? base : '$base\n$f';
  }

  List<Widget> _rigaCombo() {
    final List<Combo> voci = stato.combinazioni;
    final Combo? a = stato.comboA;
    final Combo? b = stato.comboB;
    final ConfrontoCombo? c = stato.confrontoCombo;
    return <Widget>[
      const Text(Testi.combinazioni, style: stileTitolo),
      if (voci.isEmpty)
        const Text(Testi.nessunaCombo, style: stilePiccolo)
      else ...<Widget>[
        const Text('A', style: stileTitolo),
        _tendina<Combo>(
          valore: a,
          voci: voci,
          nome: etichetta,
          scelto: (Combo k) => stato.scegliCombo(0, k),
        ),
        if (voci.length > 1) ...<Widget>[
          const Text(Testi.vs, style: stilePiccolo),
          const Text('B', style: stileTitolo),
          _tendina<Combo>(
            valore: b,
            voci: voci,
            nome: etichetta,
            scelto: (Combo k) => stato.scegliCombo(1, k),
          ),
        ],
        if (c != null) ...<Widget>[
          _Spiegato(Testi.lato('A', numero(c.a)), spiega: _spiegaCombo(0, a)),
          const Text('·', style: stilePiccolo),
          _Spiegato(Testi.lato('B', numero(c.b)), spiega: _spiegaCombo(1, b)),
          const _Spiegato('${Testi.unitaSett}  ·', spiega: _unitaSpiega),
          _Badge(c.verdetto),
          _Spiegato(
            '${c.motivo} ${testoFiltro(c.filtro)}'.trim(),
            spiega: spiegaVerdetto(Verdetto.datoDebole),
            stile: stilePiccolo,
          ),
        ] else if (a != null) ...<Widget>[
          _Spiegato(
            Testi.lato('A', numero(stato.tabellaCombo[a]?.sett)),
            spiega: _spiegaCombo(0, a),
          ),
          const Text(Testi.unitaSett, style: stilePiccolo),
          const Text(Testi.serveSecondaCombo, style: stilePiccolo),
        ],
      ],
    ];
  }

  @override
  Widget build(BuildContext context) => Carta(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const Tooltip(
          message: Testi.comeLeggere,
          child: Text(
            Testi.comeLeggereBreve,
            style: TextStyle(
              color: Colori.accento,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: _rigaNota(),
        ),
        // V2: combinazioni A/B e classifica solo con modelli/skill accesi.
        if (stato.preferenze.modelliSkill) ...<Widget>[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: _rigaCombo(),
          ),
          const SizedBox(height: 8),
          _Spiegato(
            stato.classifica,
            spiega: '${Testi.pth}\n${Testi.sett}\n${Testi.spiegaClassifica}',
            stile: stilePiccolo,
          ),
        ],
      ],
    ),
  );
}
