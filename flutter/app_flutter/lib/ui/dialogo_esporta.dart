// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
//
// Strato ui (V2, B14+B17): dialogo "Esporta per IA". Il testo si crea UNA
// volta all'apertura (mai in build); Copia lo mette negli appunti, Salva .md
// lo scrive nella cartella scelta. B17: Resoconto IA lo manda all'IA scelta
// (dopo conferma costo), salva la risposta come ..._resoconto.md e la
// mostra; i resoconti già salvati della settimana si rileggono da qui.
// B20: scelta PERIODO in cima (Giorno / Settimana / Progetto): il testo
// contiene solo i dati del periodo; si ricalcola solo quando cambia la
// scelta (mai in build). Progetto: fine automatica o spostata a mano.
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import 'package:traker_ia/domain/archivio_settimane.dart';
import 'package:traker_ia/domain/export_ia.dart';
import 'package:traker_ia/domain/piani_progetti.dart';
import 'package:traker_ia/domain/progetti.dart';
import 'package:traker_ia/domain/resoconto_ia.dart';
import 'package:traker_ia/domain/resoconto_periodo.dart';
import 'package:traker_ia/domain/tempo.dart';
import 'package:traker_ia/domain/traduzioni/testi_it.dart';
import 'package:traker_ia/ui/dialogo_resoconto.dart';
import 'package:traker_ia/ui/progetti_dati.dart';
import 'package:traker_ia/ui/stato_app.dart';
import 'package:traker_ia/ui/tema.dart';

/// Quanti caratteri del testo si vedono nell'anteprima.
const int anteprimaEsportaCaratteri = 3000;

/// Apre il dialogo per esportare le [righe] fisse (1 progetto di una
/// settimana archiviata), senza scelta periodo.
Future<void> apriDialogoEsporta(
  BuildContext context,
  StatoApp stato,
  List<SettimanaProgetto> righe,
) => showDialog<void>(
  context: context,
  builder: (BuildContext _) => _DialogoEsporta(stato: stato, righe: righe),
);

/// B20: apre il dialogo con la scelta periodo, già su [tipo]. [quando] =
/// un istante del giorno/settimana (null = adesso); [progettoId] = progetto
/// già scelto.
Future<void> apriDialogoPeriodo(
  BuildContext context,
  StatoApp stato, {
  TipoPeriodo tipo = TipoPeriodo.giorno,
  DateTime? quando,
  int? progettoId,
}) => showDialog<void>(
  context: context,
  builder: (BuildContext _) => _DialogoEsporta(
    stato: stato,
    tipo: tipo,
    quando: quando,
    progettoId: progettoId,
  ),
);

class _DialogoEsporta extends StatefulWidget {
  const _DialogoEsporta({
    required this.stato,
    this.righe,
    this.tipo = TipoPeriodo.giorno,
    this.quando,
    this.progettoId,
  });

  final StatoApp stato;

  /// Righe fisse (null = scelta periodo).
  final List<SettimanaProgetto>? righe;
  final TipoPeriodo tipo;
  final DateTime? quando;
  final int? progettoId;

  @override
  State<_DialogoEsporta> createState() => _StatoDialogoEsporta();
}

class _StatoDialogoEsporta extends State<_DialogoEsporta> {
  String _testoIA = '';
  late final TextEditingController _cartella = TextEditingController(
    text: widget.stato.servizi.cartellaEsportaPredefinita,
  );
  String? _esito;
  bool _errore = false;
  bool _occupato = false;
  List<FileResoconto> _salvati = <FileResoconto>[];

  // B20: scelta periodo (solo se righe == null).
  late TipoPeriodo _tipo = widget.tipo;
  late DateTime _quando = widget.quando ?? widget.stato.adesso;
  late int? _progetto = widget.progettoId;
  List<IntervalloProgetto> _periodi = <IntervalloProgetto>[];
  int _scelta = 0;
  DateTime? _fineMano;
  PeriodoIA? _periodo;

  bool get _conPeriodo => widget.righe == null;

  List<Progetto> get _progetti => <Progetto>[
    for (final Progetto p in widget.stato.progetti)
      if (p.id != null && p.id != idSenzaProgetto) p,
  ];

  @override
  void initState() {
    super.initState();
    if (_conPeriodo) {
      final List<Progetto> ps = _progetti;
      if (_progetto == null && ps.isNotEmpty) {
        _progetto = ps.first.id;
      }
      _caricaPeriodi();
    }
    _ricalcola();
    unawaited(_caricaSalvati());
  }

  /// Periodi del progetto scelto; scelta = il più recente.
  void _caricaPeriodi() {
    final int? id = _progetto;
    _periodi = id == null
        ? <IntervalloProgetto>[]
        : periodiProgetto(
            id,
            widget.stato.eventi,
            widget.stato.progetti,
            widget.stato.adesso,
          );
    _scelta = _periodi.isEmpty ? 0 : _periodi.length - 1;
    _fineMano = null;
  }

  /// Periodo attuale dalla scelta (null = niente da mostrare).
  PeriodoIA? _calcolaPeriodo() {
    final DateTime ora = widget.stato.adesso;
    switch (_tipo) {
      case TipoPeriodo.giorno:
        return periodoGiorno(_quando, ora);
      case TipoPeriodo.settimana:
        return periodoSettimana(_quando, ora);
      case TipoPeriodo.progetto:
        final int? id = _progetto;
        if (id == null || _periodi.isEmpty) {
          return null;
        }
        final List<IntervalloProgetto> sc = _scelta < 0
            ? _periodi
            : <IntervalloProgetto>[
                _periodi[_scelta.clamp(0, _periodi.length - 1)],
              ];
        return periodoProgetto(id, sc, fine: _fineMano);
    }
  }

  /// Ricalcola il testo (solo quando cambia la scelta, mai in build).
  void _ricalcola() {
    if (!_conPeriodo) {
      _testoIA = _crea();
      return;
    }
    final PeriodoIA? p = _calcolaPeriodo();
    _periodo = p;
    if (p == null) {
      _testoIA = '';
      return;
    }
    final StatoApp s = widget.stato;
    _testoIA = esportaPeriodo(
      p,
      letture: s.letture,
      eventi: s.eventi,
      progetti: s.progetti,
      archiviate: <SettimanaProgetto>[
        for (final RigaArchivio r in s.settimane ?? const <RigaArchivio>[])
          r.riga,
      ],
      piano: Piano(
        nome: 'Piano',
        giorniMask: s.preferenze.giorniPiano,
        inizio: p.da,
      ),
    );
  }

  void _cambia(void Function() f) {
    setState(() {
      f();
      _esito = null;
      _salvati = <FileResoconto>[];
      _ricalcola();
    });
    unawaited(_caricaSalvati());
  }

  DateTime? get _inizio {
    if (_conPeriodo) {
      return _periodo?.da;
    }
    final List<SettimanaProgetto> r = widget.righe!;
    return r.isEmpty ? null : r.first.inizio;
  }

  /// Nome del progetto nei nomi file ('' = tutta la settimana).
  String get _nomeProgetto {
    if (_conPeriodo) {
      final int? id = _periodo?.progettoId;
      return id == null ? '' : nomeProgetto(id, widget.stato.progetti);
    }
    final List<SettimanaProgetto> r = widget.righe!;
    return r.length == 1
        ? nomeProgetto(r.first.progettoId, widget.stato.progetti)
        : '';
  }

  /// Parte del nome file dopo la data.
  String get _parteNome {
    final PeriodoIA? p = _periodo;
    return _conPeriodo && p != null
        ? parteNomePeriodo(p, nomeProgetto: _nomeProgetto)
        : _nomeProgetto;
  }

  Future<void> _caricaSalvati() async {
    final DateTime? i = _inizio;
    final PeriodoIA? p = _periodo;
    final String c = _cartella.text.trim();
    if (i == null || c.isEmpty) {
      return;
    }
    try {
      final List<FileResoconto> l = await widget.stato.servizi.resocontiSalvati(
        c,
        inizio: i,
      );
      if (mounted && _inizio == i) {
        setState(
          () => _salvati = <FileResoconto>[
            for (final FileResoconto f in l)
              if (!_conPeriodo ||
                  (p != null &&
                      resocontoDelPeriodo(
                        f.nome,
                        p,
                        nomeProgetto: _nomeProgetto,
                      )))
                f,
          ],
        );
      }
    } on Object {
      // cartella illeggibile: elenco vuoto
    }
  }

  void _mostra(String testo, {bool errore = false}) {
    if (mounted) {
      setState(() {
        _esito = testo;
        _errore = errore;
      });
    }
  }

  Future<void> _resoconto() async {
    final String cart = _cartella.text.trim();
    if (cart.isEmpty) {
      _mostra(Testi.cartellaEsportaVuota, errore: true);
      return;
    }
    if (_testoIA.isEmpty) {
      return;
    }
    final ConfigIA c = widget.stato.preferenze.ia;
    if (c.fornitore.chiaveObbligatoria &&
        await widget.stato.servizi.fineChiaveIA(c.fornitore) == null) {
      _mostra(Testi.mancaChiaveIA, errore: true);
      return;
    }
    if (!mounted || !await confermaInvioIA(context, c)) {
      return;
    }
    setState(() => _occupato = true);
    _mostra(Testi.attendoIA);
    String? testo;
    String? percorso;
    try {
      final String risposta = await widget.stato.servizi.chiediIA(c, _testoIA);
      testo = testoFileResoconto(
        risposta: risposta,
        config: c,
        creato: DateTime.now(),
      );
      percorso = await widget.stato.servizi.salvaTestoInCartella(
        cartella: cart,
        nome: nomeFileResoconto(_inizio ?? DateTime.now(), nome: _parteNome),
        testo: testo,
      );
      _mostra(Testi.resocontoSalvato(percorso));
    } on ErroreIA catch (e) {
      _mostra(Testi.erroreIA(e.messaggio), errore: true);
    } on Object catch (e) {
      _mostra(Testi.erroreSalvaEsporta('$e'), errore: true);
    }
    if (mounted) {
      setState(() => _occupato = false);
    }
    await _caricaSalvati();
    if (testo != null && percorso != null && mounted) {
      await apriDialogoResoconto(
        context,
        widget.stato.servizi,
        testo: testo,
        percorso: percorso,
      );
    }
  }

  Future<void> _apriSalvato(FileResoconto f) async {
    try {
      final String t = await widget.stato.servizi.leggiTestoFile(f.percorso);
      if (mounted) {
        await apriDialogoResoconto(
          context,
          widget.stato.servizi,
          testo: t,
          percorso: f.percorso,
        );
      }
    } on Object catch (e) {
      _mostra(Testi.erroreLeggiFile('$e'), errore: true);
    }
  }

  String _crea() {
    final List<SettimanaProgetto> righe = widget.righe!;
    final Map<int, String> nomi = <int, String>{
      for (final SettimanaProgetto r in righe)
        r.progettoId: nomeProgetto(r.progettoId, widget.stato.progetti),
    };
    return esportaPerIA(righe, nomi);
  }

  String get _nomeFile {
    final DateTime? i = _inizio;
    if (i == null) {
      return nomeFileEsportazione(DateTime.now());
    }
    return nomeFileEsportazione(i, nome: _parteNome);
  }

  @override
  void dispose() {
    _cartella.dispose();
    super.dispose();
  }

  Future<void> _copia() async {
    if (_testoIA.isEmpty) {
      return;
    }
    await Clipboard.setData(ClipboardData(text: _testoIA));
    if (!mounted) {
      return;
    }
    setState(() {
      _esito = Testi.copiatoEsporta;
      _errore = false;
    });
  }

  Future<void> _salva() async {
    if (_testoIA.isEmpty) {
      return;
    }
    final String c = _cartella.text.trim();
    if (c.isEmpty) {
      setState(() {
        _esito = Testi.cartellaEsportaVuota;
        _errore = true;
      });
      return;
    }
    String msg;
    bool err = false;
    try {
      final String p = await widget.stato.servizi.salvaTestoInCartella(
        cartella: c,
        nome: _nomeFile,
        testo: _testoIA,
      );
      msg = Testi.salvatoEsporta(p);
    } on Object catch (e) {
      msg = Testi.erroreSalvaEsporta('$e');
      err = true;
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _esito = msg;
      _errore = err;
    });
  }

  // ------------------------------------------------------ scelta periodo

  void _sposta(int verso) => _cambia(() {
    final DateTime q = _quando;
    _quando = _tipo == TipoPeriodo.giorno
        ? DateTime(q.year, q.month, q.day + verso, 12)
        : DateTime(q.year, q.month, q.day + 7 * verso, q.hour, q.minute);
  });

  /// Sposta la fine del progetto di [d] (mai oltre adesso, mai prima
  /// dell'inizio).
  void _spostaFine(Duration d) {
    final PeriodoIA? p = _periodo;
    if (p == null) {
      return;
    }
    final DateTime ora = widget.stato.adesso;
    DateTime f = p.a.add(d);
    if (f.isAfter(ora)) {
      f = ora;
    }
    if (!f.isAfter(p.da)) {
      return;
    }
    _cambia(() => _fineMano = f);
  }

  Widget _tastoPiccolo(String k, String t, VoidCallback? f) => OutlinedButton(
    key: ValueKey<String>(k),
    onPressed: f,
    style: OutlinedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      minimumSize: const Size(0, 32),
    ),
    child: Text(t, style: stilePiccolo),
  );

  String _etichetta(PeriodoIA p) => Testi.etichettaPeriodo(
    p.tipo == TipoPeriodo.giorno
        ? quandoData(p.da).substring(0, 9)
        : quandoData(p.da),
    quandoData(p.a),
    aperto: p.aperto,
    soloGiorno: p.tipo == TipoPeriodo.giorno,
  );

  List<Widget> _scegliPeriodo() {
    final PeriodoIA? p = _periodo;
    final DateTime ora = widget.stato.adesso;
    final List<Progetto> ps = _progetti;
    return <Widget>[
      SegmentedButton<TipoPeriodo>(
        key: const ValueKey<String>('periodo-tipo'),
        showSelectedIcon: false,
        segments: const <ButtonSegment<TipoPeriodo>>[
          ButtonSegment<TipoPeriodo>(
            value: TipoPeriodo.giorno,
            label: Text(Testi.periodoGiorno),
          ),
          ButtonSegment<TipoPeriodo>(
            value: TipoPeriodo.settimana,
            label: Text(Testi.periodoSettimana),
          ),
          ButtonSegment<TipoPeriodo>(
            value: TipoPeriodo.progetto,
            label: Text(Testi.periodoProgetto),
          ),
        ],
        selected: <TipoPeriodo>{_tipo},
        onSelectionChanged: (Set<TipoPeriodo> v) => _cambia(() {
          _tipo = v.first;
          _quando = ora;
        }),
      ),
      const SizedBox(height: 6),
      if (_tipo != TipoPeriodo.progetto && p != null)
        Row(
          children: <Widget>[
            IconButton(
              key: const ValueKey<String>('periodo-prima'),
              tooltip: Testi.periodoPrima,
              onPressed: () => _sposta(-1),
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: Text(
                _etichetta(p),
                key: const ValueKey<String>('periodo-etichetta'),
                textAlign: TextAlign.center,
                style: stileNormale,
              ),
            ),
            IconButton(
              key: const ValueKey<String>('periodo-dopo'),
              tooltip: Testi.periodoDopo,
              onPressed: p.aperto ? null : () => _sposta(1),
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
      if (_tipo == TipoPeriodo.progetto) ...<Widget>[
        if (ps.isEmpty)
          const Text(Testi.nessunProgettoResoconto, style: stilePiccolo)
        else ...<Widget>[
          DropdownButton<int>(
            key: const ValueKey<String>('periodo-progetto'),
            isExpanded: true,
            value: _progetto,
            items: <DropdownMenuItem<int>>[
              for (final Progetto x in ps)
                DropdownMenuItem<int>(
                  value: x.id,
                  child: Text(x.nome, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: (int? v) => _cambia(() {
              _progetto = v;
              _caricaPeriodi();
            }),
          ),
          if (_periodi.isEmpty)
            const Text(Testi.nessunPeriodoProgetto, style: stilePiccolo)
          else ...<Widget>[
            DropdownButton<int>(
              key: const ValueKey<String>('periodo-scelta'),
              isExpanded: true,
              value: _scelta,
              items: <DropdownMenuItem<int>>[
                for (int i = 0; i < _periodi.length; i++)
                  DropdownMenuItem<int>(
                    value: i,
                    child: Text(
                      Testi.etichettaPeriodo(
                        quandoData(_periodi[i].inizio),
                        quandoData(_periodi[i].fine),
                        aperto: _periodi[i].aperto,
                      ),
                      overflow: TextOverflow.ellipsis,
                      style: stilePiccolo,
                    ),
                  ),
                if (_periodi.length > 1)
                  const DropdownMenuItem<int>(
                    value: -1,
                    child: Text(
                      Testi.tuttiPeriodi,
                      overflow: TextOverflow.ellipsis,
                      style: stilePiccolo,
                    ),
                  ),
              ],
              onChanged: (int? v) => _cambia(() {
                _scelta = v ?? 0;
                _fineMano = null;
              }),
            ),
            if (p != null) ...<Widget>[
              Text(
                Testi.fineProgetto(
                  p.aperto ? Testi.fineAdesso : quandoData(p.a),
                  aMano: p.fineAMano,
                ),
                key: const ValueKey<String>('periodo-fine'),
                style: stileNormale,
              ),
              const Text(Testi.spiegaFineAMano, style: stilePiccolo),
              const SizedBox(height: 4),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: <Widget>[
                  _tastoPiccolo(
                    'fine-meno-giorno',
                    Testi.menoGiorno,
                    () => _spostaFine(const Duration(days: -1)),
                  ),
                  _tastoPiccolo(
                    'fine-meno-ora',
                    Testi.menoOra,
                    () => _spostaFine(const Duration(hours: -1)),
                  ),
                  _tastoPiccolo(
                    'fine-piu-ora',
                    Testi.piuOra,
                    p.a.isBefore(ora)
                        ? () => _spostaFine(const Duration(hours: 1))
                        : null,
                  ),
                  _tastoPiccolo(
                    'fine-piu-giorno',
                    Testi.piuGiorno,
                    p.a.isBefore(ora)
                        ? () => _spostaFine(const Duration(days: 1))
                        : null,
                  ),
                  _tastoPiccolo(
                    'fine-automatica',
                    Testi.fineAutomatica,
                    _fineMano == null
                        ? null
                        : () => _cambia(() => _fineMano = null),
                  ),
                ],
              ),
            ],
          ],
        ],
      ],
      const SizedBox(height: 8),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final bool vuoto = _testoIA.isEmpty;
    final String anteprima = _testoIA.length > anteprimaEsportaCaratteri
        ? '${_testoIA.substring(0, anteprimaEsportaCaratteri)}\n…'
        : _testoIA;
    return AlertDialog(
      title: const Text(Testi.titoloEsportaIA),
      content: SizedBox(
        width: 380,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (_conPeriodo) ..._scegliPeriodo(),
              const Text(Testi.spiegaEsportaIA, style: stilePiccolo),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 160),
                child: SingleChildScrollView(
                  child: SelectableText(
                    anteprima,
                    key: const ValueKey<String>('esporta-anteprima'),
                    style: stilePiccolo.copyWith(
                      fontFamily: 'Consolas',
                      color: Colori.testo,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              FilledButton(
                key: const ValueKey<String>('esporta-copia'),
                onPressed: vuoto ? null : _copia,
                style: stileAccento(),
                child: const Text(Testi.tastoCopiaEsporta),
              ),
              const SizedBox(height: 8),
              TextField(
                key: const ValueKey<String>('esporta-cartella'),
                controller: _cartella,
                onSubmitted: (String _) => unawaited(_caricaSalvati()),
                style: stileNormale,
                decoration: const InputDecoration(
                  labelText: Testi.campoCartellaEsporta,
                ),
              ),
              const SizedBox(height: 6),
              FilledButton(
                key: const ValueKey<String>('esporta-salva'),
                onPressed: vuoto ? null : _salva,
                child: const Text(Testi.tastoSalvaMd),
              ),
              const SizedBox(height: 6),
              FilledButton(
                key: const ValueKey<String>('esporta-resoconto'),
                onPressed: _occupato || vuoto ? null : _resoconto,
                style: stileAccento(),
                child: const Text(Testi.tastoResocontoIA),
              ),
              if (_occupato)
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: LinearProgressIndicator(),
                ),
              if (_esito != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    _esito!,
                    key: const ValueKey<String>('esporta-esito'),
                    style: stilePiccolo.copyWith(
                      color: _errore ? Colori.errore : Colori.testo,
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              const Text(Testi.titoloResocontiSalvati, style: stileNormale),
              if (_salvati.isEmpty)
                const Text(Testi.nessunResoconto, style: stilePiccolo)
              else
                for (final FileResoconto f in _salvati)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      key: ValueKey<String>('resoconto-salvato-${f.nome}'),
                      onPressed: () => unawaited(_apriSalvato(f)),
                      child: Text(f.nome, style: stilePiccolo),
                    ),
                  ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          key: const ValueKey<String>('esporta-chiudi'),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(Testi.tastoChiudi),
        ),
      ],
    );
  }
}
