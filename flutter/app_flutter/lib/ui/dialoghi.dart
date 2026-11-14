// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
//
// Strato ui: finestre di dialogo (lettura manuale, impostazioni, modifica
// tasti, avviso letture fallite).
import 'dart:async';

import 'package:material_ui/material_ui.dart';

import 'package:traker_ia/domain/catena.dart';
import 'package:traker_ia/domain/collegamenti.dart';
import 'package:traker_ia/domain/fornitori.dart';
import 'package:traker_ia/domain/preferenze.dart';
import 'package:traker_ia/domain/sfondo.dart';
import 'package:traker_ia/domain/tempo.dart';
import 'package:traker_ia/domain/traduzioni/testi_it.dart';
import 'package:traker_ia/ui/pagina_login.dart';
import 'package:traker_ia/ui/servizi.dart';
import 'package:traker_ia/ui/stato_app.dart';
import 'package:traker_ia/ui/tema.dart';

Widget _campo(
  TextEditingController c,
  String etichetta, {
  bool segreto = false,
}) => Padding(
  padding: const EdgeInsets.only(bottom: 10),
  child: TextField(
    controller: c,
    obscureText: segreto,
    style: stileNormale,
    decoration: InputDecoration(labelText: etichetta),
  ),
);

// ------------------------------------------------------------------ manuale

/// Dialogo lettura manuale.
Future<void> apriManuale(BuildContext context, StatoApp stato) =>
    showDialog<void>(
      context: context,
      builder: (BuildContext _) => _Manuale(stato: stato),
    );

class _Manuale extends StatefulWidget {
  const _Manuale({required this.stato});

  final StatoApp stato;

  @override
  State<_Manuale> createState() => _StatoManuale();
}

class _StatoManuale extends State<_Manuale> {
  late final TextEditingController _ora = TextEditingController(
    text: formatta(widget.stato.adesso),
  );
  final TextEditingController _sett = TextEditingController();
  final TextEditingController _sess = TextEditingController();
  String? _errore;

  @override
  void dispose() {
    _ora.dispose();
    _sett.dispose();
    _sess.dispose();
    super.dispose();
  }

  Future<void> _salva() async {
    final DateTime? ora = interpreta(_ora.text);
    double? w;
    double? s;
    try {
      w = percentoUtente(_sett.text);
      s = percentoUtente(_sess.text);
    } on FormatException {
      w = null;
      s = null;
    }
    if (ora == null || (w == null && s == null)) {
      setState(() => _errore = Testi.erroreManuale);
      return;
    }
    await widget.stato.aggiungiManuale(ora, w, s);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text(Testi.titoloManuale),
    content: SizedBox(
      width: 340,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _campo(_ora, Testi.campoOra),
          _campo(_sett, Testi.campoSett),
          _campo(_sess, Testi.campoSess),
          if (_errore != null)
            Text(_errore!, style: const TextStyle(color: Colori.errore)),
        ],
      ),
    ),
    actions: <Widget>[
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text(Testi.annulla),
      ),
      FilledButton(
        onPressed: _salva,
        style: stileAccento(),
        child: const Text(Testi.salva),
      ),
    ],
  );
}

// ------------------------------------------------------------- impostazioni

/// Dialogo impostazioni.
Future<void> apriImpostazioni(
  BuildContext context,
  StatoApp stato, {
  required bool claudeCode,
}) => showDialog<void>(
  context: context,
  builder: (BuildContext _) =>
      _Impostazioni(stato: stato, claudeCode: claudeCode),
);

class _Impostazioni extends StatefulWidget {
  const _Impostazioni({required this.stato, required this.claudeCode});

  final StatoApp stato;
  final bool claudeCode;

  @override
  State<_Impostazioni> createState() => _StatoImpostazioni();
}

class _StatoImpostazioni extends State<_Impostazioni> {
  late final TextEditingController _minuti = TextEditingController(
    text: '${widget.stato.preferenze.minuti}',
  );
  final TextEditingController _cookie = TextEditingController();
  late final TextEditingController _cartella = TextEditingController(
    text: widget.stato.cartellaImport,
  );
  late final bool _tel = widget.stato.servizi.telefono;
  late String _metodo = metodoValido(
    widget.stato.preferenze.metodo,
    telefono: _tel,
  );
  String? _esitoLogin;
  bool _cancellaCookie = false;
  late bool _avvio = widget.stato.avvioWindows;
  String? _esitoClaudeCode;
  String? _errore;
  String? _esitoImport;

  @override
  void dispose() {
    _minuti.dispose();
    _cookie.dispose();
    _cartella.dispose();
    super.dispose();
  }

  Future<void> _salva() async {
    final int? m = int.tryParse(_minuti.text.trim());
    if (m == null || m < 1 || m > 120) {
      setState(() => _errore = Testi.erroreMinuti);
      return;
    }
    final String ck = _cookie.text.trim();
    _cookie.clear();
    Navigator.of(context).pop();
    await widget.stato.salvaImpostazioni(
      minuti: m,
      metodo: _metodo,
      cartella: _cartella.text,
      cookie: _cancellaCookie ? '' : (ck.isEmpty ? null : ck),
      avvioWindows: _avvio,
    );
  }

  Future<void> _accediClaudeCode() async {
    final bool ok = await widget.stato.servizi.accediClaudeCode();
    if (mounted) {
      setState(
        () => _esitoClaudeCode = ok
            ? Testi.claudeCodeAperto
            : Testi.claudeCodeErrore,
      );
    }
  }

  Future<void> _login(FornitoreWeb f) async {
    final StatoApp st = widget.stato;
    final String? valore = await apriLogin(context, st.servizi, f);
    if (valore == null) {
      return;
    }
    if (mounted) {
      setState(() => _esitoLogin = Testi.loginFatto);
    }
    await st.salvaLoginWeb(valore);
  }

  Future<void> _infoApp() async {
    await widget.stato.servizi.apriInfoApp();
  }

  Future<void> _importa() async {
    final String e = await widget.stato.importaOra(_cartella.text);
    if (mounted) {
      setState(() => _esitoImport = e);
    }
  }

  /// Telefono: login nell'app, batteria Samsung, letture a app chiusa.
  List<Widget> _telefono() {
    final StatoApp st = widget.stato;
    return <Widget>[
      const Text(Testi.titoloAccesso, style: stileNormale),
      Text(
        _esitoLogin ??
            Testi.statoLogin(fatto: st.cookie, scaduto: st.loginScaduto),
        style: TextStyle(
          color: st.loginScaduto ? Colori.errore : Colori.spento,
          fontSize: Misure.piccolo,
        ),
      ),
      Wrap(
        spacing: 10,
        runSpacing: 6,
        children: <Widget>[
          for (final FornitoreWeb f in fornitoriWeb)
            FilledButton(
              onPressed: () => unawaited(_login(f)),
              style: stileAccento(),
              child: Text(Testi.accedi(f.nome)),
            ),
        ],
      ),
      const SizedBox(height: 10),
      // Si aggiorna da sola tornando da Info app.
      ListenableBuilder(
        listenable: st,
        builder: (BuildContext _, Widget? _) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              Testi.batteria(st.batteriaLibera),
              style: TextStyle(
                color: st.batteriaLibera == false
                    ? Colori.errore
                    : Colori.spento,
                fontSize: Misure.piccolo,
              ),
            ),
            if (st.batteriaLibera != true) ...<Widget>[
              const Text(Testi.passiBatteria, style: stilePiccolo),
              OutlinedButton(
                onPressed: () => unawaited(_infoApp()),
                child: const Text(Testi.apriInfoApp),
              ),
            ],
          ],
        ),
      ),
      const Text(Testi.spiegaSfondo, style: stilePiccolo),
    ];
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    // Telefono: bordi stretti, più spazio ai campi.
    insetPadding: _tel
        ? const EdgeInsets.symmetric(horizontal: 12, vertical: 24)
        : const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
    title: const Text(Testi.titoloImpostazioni),
    content: SizedBox(
      width: 460,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _campo(_minuti, Testi.campoMinuti),
            const Text(Testi.campoMetodo, style: stilePiccolo),
            DropdownButton<String>(
              value: _metodo,
              isExpanded: true,
              dropdownColor: Colori.carta2,
              style: stileNormale,
              items: <DropdownMenuItem<String>>[
                for (final String m in metodiDisponibili(telefono: _tel))
                  DropdownMenuItem<String>(
                    value: m,
                    child: Text(Testi.nomiMetodi[m] ?? m),
                  ),
              ],
              onChanged: (String? v) =>
                  setState(() => _metodo = v ?? metodoAuto),
            ),
            const SizedBox(height: 6),
            if (_tel)
              ..._telefono()
            else
              Text(Testi.claudeCode(widget.claudeCode), style: stilePiccolo),
            const SizedBox(height: 14),
            _campo(_cookie, Testi.campoCookie, segreto: true),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    Testi.cookieSalvato(
                      widget.stato.cookie && !_cancellaCookie,
                    ),
                    style: stilePiccolo,
                  ),
                ),
                if (widget.stato.cookie)
                  TextButton(
                    onPressed: () => setState(() => _cancellaCookie = true),
                    child: const Text(Testi.cancellaCookie),
                  ),
              ],
            ),
            const Text(
              Testi.avvisoCookie,
              style: TextStyle(color: Colori.errore, fontSize: Misure.piccolo),
            ),
            if (!_tel) ...<Widget>[
              const SizedBox(height: 14),
              _campo(_cartella, Testi.campoCartella),
              Row(
                children: <Widget>[
                  FilledButton(
                    onPressed: _importa,
                    child: const Text(Testi.importaOra),
                  ),
                  const SizedBox(width: 10),
                  if (_esitoImport != null)
                    Expanded(child: Text(_esitoImport!, style: stilePiccolo)),
                ],
              ),
            ],
            if (widget.stato.servizi.avvioWindowsDisponibile) ...<Widget>[
              const SizedBox(height: 14),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _avvio,
                onChanged: (bool v) => setState(() => _avvio = v),
                title: const Text(Testi.avvioWindows, style: stileNormale),
              ),
              const Text(Testi.spiegaX, style: stilePiccolo),
            ],
            if (widget.stato.servizi.collegamentiDisponibili) ...<Widget>[
              const SizedBox(height: 14),
              const Text(Testi.collegaFonti, style: stileNormale),
              const SizedBox(height: 6),
              Wrap(
                spacing: 10,
                runSpacing: 6,
                children: <Widget>[
                  OutlinedButton(
                    onPressed: () => showDialog<void>(
                      context: context,
                      builder: (_) =>
                          DialogoEstensione(servizi: widget.stato.servizi),
                    ),
                    child: const Text(Testi.installaEstensione),
                  ),
                  OutlinedButton(
                    onPressed: _accediClaudeCode,
                    child: const Text(Testi.accediClaudeCode),
                  ),
                ],
              ),
              if (_esitoClaudeCode != null)
                Text(_esitoClaudeCode!, style: stilePiccolo),
            ],
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
        onPressed: _salva,
        style: stileAccento(),
        child: const Text(Testi.salvaEProva),
      ),
    ],
  );
}

// ---------------------------------------------------------- modifica tasti

/// Dialogo per aggiungere/rinominare/togliere modelli o skill.
Future<void> apriModifica(BuildContext context, StatoApp stato, Gruppo g) =>
    showDialog<void>(
      context: context,
      builder: (BuildContext _) => _Modifica(stato: stato, gruppo: g),
    );

class _Modifica extends StatefulWidget {
  const _Modifica({required this.stato, required this.gruppo});

  final StatoApp stato;
  final Gruppo gruppo;

  @override
  State<_Modifica> createState() => _StatoModifica();
}

class _StatoModifica extends State<_Modifica> {
  final TextEditingController _nome = TextEditingController();
  String? _scelto;
  String? _errore;

  @override
  void dispose() {
    _nome.dispose();
    super.dispose();
  }

  bool _valido(String n, {String? vecchio}) {
    final String? e = widget.stato.preferenze.erroreNome(
      widget.gruppo,
      n,
      vecchio: vecchio,
    );
    setState(
      () => _errore = e == null
          ? null
          : (e == 'doppio' ? Testi.nomeDoppio : Testi.nomeNonValido),
    );
    return e == null;
  }

  Future<void> _aggiungi() async {
    if (_valido(_nome.text)) {
      await widget.stato.aggiungiTasto(widget.gruppo, _nome.text);
      _nome.clear();
      setState(() {});
    }
  }

  Future<void> _rinomina() async {
    final String? v = _scelto;
    if (v == null) {
      setState(() => _errore = Testi.scegliNome);
      return;
    }
    if (_nome.text.trim() != v && _valido(_nome.text, vecchio: v)) {
      await widget.stato.rinominaTasto(widget.gruppo, v, _nome.text);
      setState(() => _scelto = _nome.text.trim());
    }
  }

  Future<void> _togli() async {
    final String? v = _scelto;
    if (v == null) {
      setState(() => _errore = Testi.scegliNome);
      return;
    }
    await widget.stato.togliTasto(widget.gruppo, v);
    _nome.clear();
    setState(() => _scelto = null);
  }

  /// Sposta il nome scelto di [passo] posti (su = -1, giù = +1).
  Future<void> _sposta(int passo) async {
    final String? v = _scelto;
    if (v == null) {
      setState(() => _errore = Testi.scegliNome);
      return;
    }
    final List<String> l = List<String>.of(
      widget.stato.preferenze.elenco(widget.gruppo),
    );
    final int i = l.indexOf(v);
    final int j = i + passo;
    if (i < 0 || j < 0 || j >= l.length) {
      return;
    }
    l
      ..removeAt(i)
      ..insert(j, v);
    await widget.stato.riordina(widget.gruppo, l);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final List<String> lista = widget.stato.preferenze.elenco(widget.gruppo);
    final String nomeGruppo = widget.gruppo == Gruppo.modelli
        ? Testi.gruppoModelli
        : Testi.gruppoSkill;
    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
      title: Text(Testi.titoloModifica(nomeGruppo.toLowerCase())),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              LayoutBuilder(
                builder: (BuildContext c, BoxConstraints k) {
                  // Material (non Container colorato): si vede il nome scelto.
                  final Widget elenco = Material(
                    color: Colori.carta2,
                    child: SizedBox(
                      width: k.maxWidth < 400 ? double.infinity : 200,
                      height: k.maxWidth < 400 ? 170 : 220,
                      child: ListView(
                        children: <Widget>[
                          for (final String n in lista)
                            ListTile(
                              dense: true,
                              selected: n == _scelto,
                              selectedTileColor: Colori.accento,
                              selectedColor: Colors.white,
                              title: Text(n),
                              onTap: () => setState(() {
                                _scelto = n;
                                _nome.text = n;
                                _errore = null;
                              }),
                            ),
                        ],
                      ),
                    ),
                  );
                  final Widget tasti = Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      _campo(_nome, Testi.campoNome),
                      FilledButton(
                        onPressed: _aggiungi,
                        child: const Text(Testi.aggiungi),
                      ),
                      const SizedBox(height: 4),
                      FilledButton(
                        onPressed: _rinomina,
                        child: const Text(Testi.rinomina),
                      ),
                      const SizedBox(height: 4),
                      FilledButton(
                        onPressed: _togli,
                        child: const Text(Testi.togli),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => unawaited(_sposta(-1)),
                              child: const Text(Testi.su),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => unawaited(_sposta(1)),
                              child: const Text(Testi.giu),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                  return k.maxWidth < 400
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            elenco,
                            const SizedBox(height: 8),
                            tasti,
                          ],
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            elenco,
                            const SizedBox(width: 12),
                            Expanded(child: tasti),
                          ],
                        );
                },
              ),
              const SizedBox(height: 8),
              if (_errore != null)
                Text(_errore!, style: const TextStyle(color: Colori.errore)),
              const Text(Testi.notaRinomina, style: stilePiccolo),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(Testi.chiudi),
        ),
      ],
    );
  }
}

// ------------------------------------------------------------------ avviso

/// Avviso dopo 2 letture fallite di fila.
Future<void> apriAvviso(BuildContext context, String messaggio) =>
    showDialog<void>(
      context: context,
      builder: (BuildContext c) => AlertDialog(
        title: const Text(Testi.titoloAvviso),
        content: Text(Testi.testoAvviso(messaggio)),
        actions: <Widget>[
          FilledButton(
            onPressed: () => Navigator.of(c).pop(),
            style: stileAccento(),
            child: const Text(Testi.ok),
          ),
        ],
      ),
    );

/// Mini guida estensione: scegli browser, poi 5 passi con 2 tasti.
class DialogoEstensione extends StatefulWidget {
  /// Crea il dialogo.
  const DialogoEstensione({required this.servizi, super.key});

  /// Servizi dell'app.
  final Servizi servizi;

  @override
  State<DialogoEstensione> createState() => _DialogoEstensioneStato();
}

class _DialogoEstensioneStato extends State<DialogoEstensione> {
  BrowserEstensione _scelto = browserEstensione.first;
  String? _cartella;
  bool _nonTrovato = false;

  @override
  void initState() {
    super.initState();
    // La cartella la prepara l'app da sola.
    unawaited(_prepara());
  }

  Future<String> _prepara() async {
    final String c = _cartella ?? await widget.servizi.preparaEstensione();
    if (mounted && _cartella == null) {
      setState(() => _cartella = c);
    }
    return c;
  }

  Future<void> _apriPagina() async {
    final bool ok = await widget.servizi.apriPaginaEstensioni(_scelto.id);
    if (mounted) {
      setState(() => _nonTrovato = !ok);
    }
  }

  Future<void> _apriCartella() async {
    await widget.servizi.mostraCartella(await _prepara());
  }

  Widget _passo(int n, String testo, [Widget? tasto]) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: <Widget>[
        Expanded(child: Text('$n. $testo', style: stileNormale)),
        ?tasto,
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final BrowserEstensione b = _scelto;
    return AlertDialog(
      title: const Text(Testi.titoloEstensione),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: <Widget>[
                  for (final BrowserEstensione x in browserEstensione)
                    if (x.pronto)
                      ChoiceChip(
                        label: Text(x.nome),
                        selected: b.id == x.id,
                        onSelected: (_) => setState(() {
                          _scelto = x;
                          _nonTrovato = false;
                        }),
                      ),
                ],
              ),
              const Text(Testi.firefoxInArrivo, style: stilePiccolo),
              const SizedBox(height: 12),
              _passo(
                1,
                Testi.passoPagina(b.pagina),
                OutlinedButton(
                  onPressed: _apriPagina,
                  child: const Text(Testi.apriPagina),
                ),
              ),
              if (_nonTrovato)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    Testi.browserNonTrovato(b.pagina),
                    style: stilePiccolo,
                  ),
                ),
              _passo(2, Testi.passoSviluppatore),
              _passo(
                3,
                Testi.passoCartella,
                OutlinedButton(
                  onPressed: _cartella == null ? null : _apriCartella,
                  child: const Text(Testi.apriCartella),
                ),
              ),
              _passo(4, Testi.passoTrascina),
              _passo(5, Testi.passoFatto),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(Testi.chiudi),
        ),
      ],
    );
  }
}
