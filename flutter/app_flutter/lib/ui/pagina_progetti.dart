// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
//
// Strato ui (V2, B13): pagina Progetti (elenco, crea/modifica, colore,
// settimana in corso, confronto settimane, settimane archiviate) e barra
// "Progetto attivo" della finestra principale.
import 'dart:async';

import 'package:material_ui/material_ui.dart';

import 'package:traker_ia/domain/piani_progetti.dart';
import 'package:traker_ia/domain/progetti.dart';
import 'package:traker_ia/domain/resoconto_periodo.dart';
import 'package:traker_ia/domain/tempo.dart';
import 'package:traker_ia/domain/traduzioni/testi_it.dart';
import 'package:traker_ia/ui/barre_settimane.dart';
import 'package:traker_ia/ui/dialogo_esporta.dart';
import 'package:traker_ia/ui/grafico.dart';
import 'package:traker_ia/ui/progetti_dati.dart';
import 'package:traker_ia/ui/scheda_settimana.dart';
import 'package:traker_ia/ui/stato_app.dart';
import 'package:traker_ia/ui/tema.dart';

// ------------------------------------------------- barra progetto attivo

/// Tasti "Progetto attivo" (più progetti insieme): sotto la nota.
class BarraProgetti extends StatelessWidget {
  /// Crea la barra.
  const BarraProgetti({required this.stato, super.key});

  /// Stato dell'app.
  final StatoApp stato;

  @override
  Widget build(BuildContext context) {
    return Carta(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          const Tooltip(
            message: Testi.spiegaProgettoAttivo,
            child: Text(Testi.progettoAttivo, style: stileTitolo),
          ),
          for (final Progetto p in stato.progetti)
            _TastoProgetto(
              progetto: p,
              colore: coloreProgetto(p.id ?? idSenzaProgetto, stato.progetti),
              attivo: stato.progettiAttivi.contains(p.id),
              onTap: () => stato.cambiaProgettoAttivo(p),
            ),
        ],
      ),
    );
  }
}

class _TastoProgetto extends StatelessWidget {
  const _TastoProgetto({
    required this.progetto,
    required this.colore,
    required this.attivo,
    required this.onTap,
  });

  final Progetto progetto;
  final Color colore;
  final bool attivo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: Testi.spiegaProgettoAttivo,
    child: InkWell(
      key: ValueKey<String>('progetto-attivo-${progetto.id}'),
      borderRadius: BorderRadius.circular(6),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: attivo ? colore.withValues(alpha: 0.28) : Colori.carta2,
          border: Border.all(color: attivo ? colore : Colori.bordo),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: attivo ? colore : Colors.transparent,
                border: Border.all(color: colore, width: 2),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                progetto.nome,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: attivo ? Colori.testo : Colori.spento,
                  fontSize: Misure.normale,
                  fontWeight: attivo ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// ------------------------------------------------------------ pagina

/// Apre la pagina Progetti.
Future<void> apriPaginaProgetti(BuildContext context, StatoApp stato) =>
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext _) => PaginaProgetti(stato: stato),
      ),
    );

/// Pagina Progetti.
class PaginaProgetti extends StatefulWidget {
  /// Crea la pagina.
  const PaginaProgetti({required this.stato, super.key});

  /// Stato dell'app.
  final StatoApp stato;

  @override
  State<PaginaProgetti> createState() => _StatoPagina();
}

class _StatoPagina extends State<PaginaProgetti> {
  final MouseGrafici _mouse = MouseGrafici();
  SchedaSettimana? _scheda;
  int? _filtro;

  StatoApp get _s => widget.stato;

  @override
  void initState() {
    super.initState();
    unawaited(_s.caricaSettimane());
  }

  @override
  void dispose() {
    _s.rilasciaSettimane();
    _mouse.dispose();
    super.dispose();
  }

  void _apri(RigaArchivio r) {
    final SchedaSettimana sc = costruisciScheda(r);
    setState(() => _scheda = sc);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _s,
          builder: (BuildContext context, _) {
            final SchedaSettimana? sc = _scheda;
            return Scrollbar(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                child: sc != null
                    ? SchedaSettimanaView(
                        stato: _s,
                        scheda: sc,
                        mouse: _mouse,
                        onIndietro: () => setState(() => _scheda = null),
                      )
                    : _elenco(context),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _elenco(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      Wrap(
        spacing: 10,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          FilledButton(
            key: const ValueKey<String>('pagina-indietro'),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(Testi.indietro),
          ),
          const Text(Testi.titoloPaginaProgetti, style: stileTitolo),
          FilledButton(
            key: const ValueKey<String>('nuovo-progetto'),
            onPressed: () => apriDialogoProgetto(context, _s),
            style: stileAccento(),
            child: const Text(Testi.nuovoProgetto),
          ),
          OutlinedButton(
            key: const ValueKey<String>('resoconto-ia'),
            onPressed: () => apriDialogoPeriodo(context, _s),
            child: const Text(Testi.tastoResocontoIA),
          ),
        ],
      ),
      const SizedBox(height: 10),
      _cartaProgetti(context),
      if (_s.progetti.isNotEmpty) ...<Widget>[
        const SizedBox(height: 10),
        _cartaInCorso(),
        const SizedBox(height: 10),
        _cartaConfronto(),
        const SizedBox(height: 10),
        _cartaSettimane(),
      ],
    ],
  );

  Widget _titolo(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(t, style: stileTitolo),
  );

  Widget _pallino(Color c) => Container(
    width: 12,
    height: 12,
    decoration: BoxDecoration(color: c, shape: BoxShape.circle),
  );

  // ----------------------------------------------------- elenco progetti

  Widget _cartaProgetti(BuildContext context) => Carta(
    padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _titolo(Testi.titoloElencoProgetti),
        if (_s.progetti.isEmpty)
          const Text(Testi.nessunProgetto, style: stilePiccolo)
        else
          for (final Progetto p in _s.progetti)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: <Widget>[
                  _pallino(coloreProgetto(p.id ?? 0, _s.progetti)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(p.nome, style: stileNormale),
                        if (p.note.trim().isNotEmpty)
                          Text(
                            p.note.trim(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: stilePiccolo,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      alignment: WrapAlignment.end,
                      children: <Widget>[
                        OutlinedButton(
                          key: ValueKey<String>('resoconto-progetto-${p.id}'),
                          onPressed: () => apriDialogoPeriodo(
                            context,
                            _s,
                            tipo: TipoPeriodo.progetto,
                            progettoId: p.id,
                          ),
                          child: const Text(Testi.tastoResocontoIA),
                        ),
                        FilledButton(
                          key: ValueKey<String>('modifica-${p.id}'),
                          onPressed: () =>
                              apriDialogoProgetto(context, _s, progetto: p),
                          child: const Text(Testi.modificaProgetto),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      ],
    ),
  );

  // --------------------------------------------------- settimana in corso

  Widget _cartaInCorso() {
    final Ripartizione? r = _s.ripartizioneCorrente;
    final List<ConsumoProgetto> voci = <ConsumoProgetto>[
      if (r != null)
        for (final ConsumoProgetto c in r.voci)
          if (c.sett.stima > 0 || c.sess.stima > 0 || c.oreAttive > 0) c,
    ];
    return Carta(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      child: Column(
        key: const ValueKey<String>('carta-in-corso'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _titolo(Testi.titoloInCorso),
          if (voci.isEmpty)
            const Text(Testi.nessunConsumoInCorso, style: stilePiccolo)
          else
            for (final ConsumoProgetto c in voci)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: _pallino(
                        coloreProgetto(c.progettoId, _s.progetti),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            nomeProgetto(c.progettoId, _s.progetti),
                            style: stileNormale,
                          ),
                          Text(
                            Testi.rigaInCorso(
                              Testi.stimaPt(
                                c.sett.stima,
                                c.sett.min,
                                c.sett.max,
                              ),
                              Testi.oreAttiveCorto(durata(c.oreAttive)),
                            ),
                            style: stilePiccolo,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------- confronto

  Widget _pillola(String testo, bool acceso, VoidCallback onTap, Key k) =>
      InkWell(
        key: k,
        borderRadius: BorderRadius.circular(5),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: acceso ? Colori.accento : Colori.carta2,
            border: Border.all(color: acceso ? Colori.accento : Colori.bordo),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Text(
            testo,
            style: TextStyle(
              color: acceso ? Colors.white : Colori.spento,
              fontSize: Misure.piccolo,
              fontWeight: acceso ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      );

  Widget _cartaConfronto() {
    final List<RigaArchivio>? righe = _s.settimane;
    final List<BarraSettimana> barre = righe == null
        ? const <BarraSettimana>[]
        : barreSettimane(righe, progettoId: _filtro);
    final Set<int> conRighe = <int>{
      for (final RigaArchivio r in righe ?? const <RigaArchivio>[])
        r.progettoId,
    };
    return Carta(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      child: Column(
        key: const ValueKey<String>('carta-confronto'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _titolo(Testi.titoloConfronto),
          const Text(Testi.spiegaConfronto, style: stilePiccolo),
          const SizedBox(height: 6),
          Wrap(
            spacing: 5,
            runSpacing: 5,
            children: <Widget>[
              _pillola(
                Testi.filtroTutti,
                _filtro == null,
                () => setState(() => _filtro = null),
                const ValueKey<String>('filtro-tutti'),
              ),
              for (final int id in conRighe.toList()..sort())
                _pillola(
                  nomeProgetto(id, _s.progetti),
                  _filtro == id,
                  () => setState(() => _filtro = id),
                  ValueKey<String>('filtro-$id'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (righe == null)
            const SizedBox(
              height: 24,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else if (barre.isEmpty)
            const Text(Testi.nessunaSettimana, style: stilePiccolo)
          else
            BarreSettimane(barre: barre, progetti: _s.progetti),
        ],
      ),
    );
  }

  // ------------------------------------------------- settimane archiviate

  Widget _cartaSettimane() {
    final List<RigaArchivio>? righe = _s.settimane;
    return Carta(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      child: Column(
        key: const ValueKey<String>('carta-settimane'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _titolo(Testi.titoloSettimane),
          if (righe == null)
            const SizedBox(
              height: 24,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else if (righe.isEmpty)
            const Text(Testi.nessunaSettimana, style: stilePiccolo)
          else
            for (final GruppoSettimana g in raggruppaSettimane(righe))
              _gruppo(g),
        ],
      ),
    );
  }

  Widget _gruppo(GruppoSettimana g) {
    final DateTime? fine = g.fine;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Wrap(
            spacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              Text(
                Testi.intervalloSettimana(
                  quandoData(g.inizio),
                  fine == null ? '…' : quandoData(fine),
                ),
                style: stileTitolo.copyWith(color: Colori.testo),
              ),
              OutlinedButton(
                key: ValueKey<String>(
                  'esporta-sett-${g.inizio.toIso8601String()}',
                ),
                onPressed: () => apriDialogoPeriodo(
                  context,
                  _s,
                  tipo: TipoPeriodo.settimana,
                  quando: g.inizio,
                ),
                child: const Text(Testi.tastoEsportaIA),
              ),
            ],
          ),
          for (final RigaArchivio r in g.righe)
            InkWell(
              key: ValueKey<String>('riga-${r.id}'),
              onTap: () => _apri(r),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: _pallino(
                        coloreProgetto(r.progettoId, _s.progetti),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            nomeProgetto(r.progettoId, _s.progetti),
                            style: stileNormale,
                          ),
                          Text(
                            Testi.rigaArchivio(
                              Testi.stimaPt(
                                r.sett.stima,
                                r.sett.min,
                                r.sett.max,
                              ),
                              Testi.stimaPt(
                                r.sess.stima,
                                r.sess.min,
                                r.sess.max,
                              ),
                              Testi.oreAttiveCorto(durata(r.oreAttive)),
                            ),
                            style: stilePiccolo,
                          ),
                        ],
                      ),
                    ),
                    const Text('›', style: stileTitolo),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------ dialogo progetto

/// Dialogo nuovo progetto ([progetto] null) o modifica.
Future<void> apriDialogoProgetto(
  BuildContext context,
  StatoApp stato, {
  Progetto? progetto,
}) => showDialog<void>(
  context: context,
  builder: (BuildContext _) =>
      _DialogoProgetto(stato: stato, progetto: progetto),
);

class _DialogoProgetto extends StatefulWidget {
  const _DialogoProgetto({required this.stato, required this.progetto});

  final StatoApp stato;
  final Progetto? progetto;

  @override
  State<_DialogoProgetto> createState() => _StatoDialogoProgetto();
}

class _StatoDialogoProgetto extends State<_DialogoProgetto> {
  late final TextEditingController _nome = TextEditingController(
    text: widget.progetto?.nome ?? '',
  );
  late final TextEditingController _note = TextEditingController(
    text: widget.progetto?.note ?? '',
  );
  late int _colore = _coloreIniziale();
  String? _errore;

  int _coloreIniziale() {
    final Progetto? p = widget.progetto;
    if (p == null) {
      return coloriProgetto[widget.stato.progetti.length %
          coloriProgetto.length];
    }
    return coloreProgetto(p.id ?? 0, widget.stato.progetti).toARGB32();
  }

  @override
  void dispose() {
    _nome.dispose();
    _note.dispose();
    super.dispose();
  }

  bool get _rinomina {
    final Progetto? p = widget.progetto;
    return p != null && normalizzaNome(_nome.text) != normalizzaNome(p.nome);
  }

  Future<void> _salva() async {
    final String? e = await widget.stato.salvaProgetto(
      Progetto(
        id: widget.progetto?.id,
        nome: _nome.text,
        colore: _colore,
        note: _note.text,
      ),
    );
    if (!mounted) {
      return;
    }
    if (e != null) {
      setState(() => _errore = e);
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(
      widget.progetto == null
          ? Testi.titoloNuovoProgetto
          : Testi.titoloModificaProgetto,
    ),
    content: SizedBox(
      width: 340,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: TextField(
                key: const ValueKey<String>('campo-nome-progetto'),
                controller: _nome,
                style: stileNormale,
                decoration: const InputDecoration(
                  labelText: Testi.campoNomeProgetto,
                ),
                onChanged: (_) => setState(() => _errore = null),
              ),
            ),
            if (_rinomina)
              const Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: Text(
                  Testi.avvisoRinomina,
                  key: ValueKey<String>('avviso-rinomina'),
                  style: TextStyle(
                    color: Colori.errore,
                    fontSize: Misure.piccolo,
                  ),
                ),
              ),
            const Text(Testi.campoColoreProgetto, style: stilePiccolo),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                for (int i = 0; i < coloriProgetto.length; i++)
                  GestureDetector(
                    key: ValueKey<String>('colore-$i'),
                    onTap: () => setState(() => _colore = coloriProgetto[i]),
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: Color(coloriProgetto[i]),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _colore == coloriProgetto[i]
                              ? Colors.white
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              key: const ValueKey<String>('campo-note-progetto'),
              controller: _note,
              style: stileNormale,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: Testi.campoNoteProgetto,
              ),
            ),
            if (_errore != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _errore!,
                  style: const TextStyle(color: Colori.errore),
                ),
              ),
          ],
        ),
      ),
    ),
    actions: <Widget>[
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text(Testi.annulla),
      ),
      FilledButton(
        key: const ValueKey<String>('salva-progetto'),
        onPressed: _salva,
        style: stileAccento(),
        child: const Text(Testi.salva),
      ),
    ],
  );
}
