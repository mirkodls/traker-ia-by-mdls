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
import 'package:traker_ia/ui/scheda_grafico.dart';
import 'package:traker_ia/ui/servizi.dart';
import 'package:traker_ia/ui/sezione_ia.dart';
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

class _StatoImpostazioni extends State<_Impostazioni>
    with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(
    length: _tel ? 3 : 4,
    vsync: this,
  )..addListener(() => setState(() {}));
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
    _tab.dispose();
    _minuti.dispose();
    _cookie.dispose();
    _cartella.dispose();
    super.dispose();
  }

  Future<void> _salva() async {
    final int? m = int.tryParse(_minuti.text.trim());
    if (m == null || m < 1 || m > 120) {
      setState(() => _errore = Testi.erroreMinuti);
      _tab.animateTo(0);
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

  Future<void> _importa() async {
    final String e = await widget.stato.importaOra(_cartella.text);
    if (mounted) {
      setState(() => _esitoImport = e);
    }
  }

  /// Gruppo di impostazioni: titolo, una riga di spiegazione, contenuto.
  Widget _gruppo(String titolo, String spiega, List<Widget> figli) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(titolo, style: stileNormale.copyWith(fontWeight: FontWeight.bold)),
        Text(spiega, style: stilePiccolo),
        const SizedBox(height: 10),
        ...figli,
      ],
    ),
  );

  /// Telefono: login nell'app (scheda Accesso).
  List<Widget> _loginTelefono() {
    final StatoApp st = widget.stato;
    return <Widget>[
      Text(
        _esitoLogin ??
            Testi.statoLogin(fatto: st.cookie, scaduto: st.loginScaduto),
        style: TextStyle(
          color: st.loginScaduto ? Colori.errore : Colori.spento,
          fontSize: Misure.piccolo,
        ),
      ),
      const SizedBox(height: 6),
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
      const SizedBox(height: 12),
    ];
  }

  /// Telefono: letture a app chiusa, intervallo, batteria, permessi
  /// (scheda Generale).
  List<Widget> _sottofondoTelefono() {
    final StatoApp st = widget.stato;
    return <Widget>[
      // B21: interruttore anche qui (come nella schermata); cambia subito.
      ListenableBuilder(
        listenable: st,
        builder: (BuildContext _, Widget? _) => Row(
          children: <Widget>[
            const Expanded(child: Text(Testi.sottofondo, style: stileNormale)),
            Switch(
              key: const ValueKey<String>('imp-sottofondo'),
              value: st.preferenze.sfondoAcceso,
              onChanged: (bool v) => unawaited(st.cambiaSfondo(acceso: v)),
            ),
          ],
        ),
      ),
      const Text(Testi.campoMinutiSfondo, style: stilePiccolo),
      // Cambia subito (non serve Salva); si aggiorna da sola.
      ListenableBuilder(
        listenable: st,
        builder: (BuildContext _, Widget? _) => DropdownButton<int>(
          value: st.preferenze.minutiSfondo,
          isExpanded: true,
          dropdownColor: Colori.carta2,
          style: stileNormale,
          items: <DropdownMenuItem<int>>[
            for (final int m in sceltaMinutiSfondo)
              DropdownMenuItem<int>(
                value: m,
                child: Text(Testi.sceltaMinutiSfondo(m)),
              ),
          ],
          onChanged: (int? v) =>
              unawaited(st.cambiaMinutiSfondo(v ?? minutiSfondoPredefiniti)),
        ),
      ),
      ListenableBuilder(
        listenable: st,
        builder: (BuildContext _, Widget? _) => Text(
          Testi.batteria(st.batteriaLibera),
          style: TextStyle(
            color: st.batteriaLibera == false ? Colori.errore : Colori.spento,
            fontSize: Misure.piccolo,
          ),
        ),
      ),
      const SizedBox(height: 6),
      OutlinedButton(
        onPressed: () => unawaited(apriPermessi(context, st)),
        child: const Text(Testi.titoloPermessi),
      ),
      const SizedBox(height: 6),
      const Text(Testi.spiegaSfondo, style: stilePiccolo),
    ];
  }

  Widget _schedaGenerale() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      _gruppo(Testi.gruppoLetture, Testi.spiegaLetture, <Widget>[
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
          onChanged: (String? v) => setState(() => _metodo = v ?? metodoAuto),
        ),
      ]),
      if (widget.stato.servizi.avvioWindowsDisponibile)
        _gruppo(Testi.gruppoAvvio, Testi.spiegaAvvio, <Widget>[
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _avvio,
            onChanged: (bool v) => setState(() => _avvio = v),
            title: const Text(Testi.avvioWindows, style: stileNormale),
          ),
          const Text(Testi.spiegaX, style: stilePiccolo),
        ]),
      if (_tel)
        _gruppo(
          Testi.gruppoSottofondo,
          Testi.spiegaSottofondoGruppo,
          _sottofondoTelefono(),
        ),
      if (_errore != null)
        Text(_errore!, style: const TextStyle(color: Colori.errore)),
    ],
  );

  Widget _schedaAccesso() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      _gruppo(Testi.gruppoAccesso, Testi.spiegaAccesso, <Widget>[
        if (_tel) ..._loginTelefono(),
        _campo(_cookie, Testi.campoCookie, segreto: true),
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                Testi.cookieSalvato(widget.stato.cookie && !_cancellaCookie),
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
      ]),
      if (widget.stato.servizi.collegamentiDisponibili)
        _gruppo(Testi.collegaFonti, Testi.spiegaCollegamenti, <Widget>[
          Text(Testi.claudeCode(widget.claudeCode), style: stilePiccolo),
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
        ])
      else if (!_tel)
        Text(Testi.claudeCode(widget.claudeCode), style: stilePiccolo),
      if (!_tel)
        _gruppo(Testi.gruppoVecchiDati, Testi.spiegaVecchiDati, <Widget>[
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
        ]),
    ],
  );

  /// Pagina scorrevole di una scheda.
  Widget _pagina(Widget figlio) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
    child: figlio,
  );

  @override
  Widget build(BuildContext context) => Dialog(
    // PC: grande (820x780, si stringe se lo schermo è piccolo).
    // Telefono: schermo intero.
    insetPadding: _tel
        ? EdgeInsets.zero
        : EdgeInsets.symmetric(
            horizontal: MediaQuery.sizeOf(context).width < 600 ? 12 : 40,
            vertical: 24,
          ),
    child: _tel
        ? SizedBox.expand(child: _contenuto())
        : SizedBox(width: 820, height: 780, child: _contenuto()),
  );

  Widget _contenuto() => Column(
    children: <Widget>[
      const Padding(
        padding: EdgeInsets.fromLTRB(20, 16, 20, 4),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            Testi.titoloImpostazioni,
            style: TextStyle(
              color: Colori.testo,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      TabBar(
        key: const Key('schede-impostazioni'),
        controller: _tab,
        tabs: <Widget>[
          const Tab(text: Testi.schedaGenerale),
          const Tab(text: Testi.schedaAccesso),
          const Tab(text: Testi.schedaGrafico),
          if (!_tel) const Tab(text: Testi.titoloIA),
        ],
      ),
      // Tutte le schede restano vive (si perde nulla cambiando scheda).
      Expanded(
        child: IndexedStack(
          index: _tab.index,
          children: <Widget>[
            _pagina(_schedaGenerale()),
            _pagina(_schedaAccesso()),
            SchedaGrafico(stato: widget.stato),
            if (!_tel)
              _pagina(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(Testi.siSalvaDaSolo, style: stilePiccolo),
                    const SizedBox(height: 6),
                    SezioneIA(stato: widget.stato),
                  ],
                ),
              ),
          ],
        ),
      ),
      const Divider(height: 1),
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(Testi.notaSalvataggio, style: stilePiccolo),
            const SizedBox(height: 4),
            SizedBox(
              width: double.infinity,
              child: Wrap(
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                children: <Widget>[
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
              ),
            ),
          ],
        ),
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

/// Telefono: pagina permessi (solo batteria). Ogni passo apre la pagina
/// giusta di Android; tornando nell'app lo stato si aggiorna.
Future<void> apriPermessi(BuildContext context, StatoApp stato) =>
    showDialog<void>(
      context: context,
      builder: (BuildContext c) => _Permessi(stato: stato),
    );

class _Permessi extends StatefulWidget {
  const _Permessi({required this.stato});

  final StatoApp stato;

  @override
  State<_Permessi> createState() => _StatoPermessi();
}

class _StatoPermessi extends State<_Permessi> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.resumed) {
      unawaited(widget.stato.aggiornaBatteria());
    }
  }

  Widget _riga(String testo, String bottone, String voce, {bool? ok}) =>
      Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Row(
          children: <Widget>[
            if (ok != null)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Icon(
                  ok ? Icons.check_circle : Icons.error,
                  color: ok ? Colori.ok : Colori.errore,
                  size: 18,
                ),
              ),
            Expanded(child: Text(testo, style: stilePiccolo)),
            const SizedBox(width: 6),
            OutlinedButton(
              onPressed: () =>
                  unawaited(widget.stato.servizi.apriPermesso(voce)),
              child: Text(bottone),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) => AlertDialog(
    insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
    title: const Text(Testi.titoloPermessi),
    content: SizedBox(
      width: 460,
      child: ListenableBuilder(
        listenable: widget.stato,
        builder: (BuildContext _, Widget? _) => SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(Testi.spiegaPermessi, style: stilePiccolo),
              _riga(
                Testi.permessoBatteria,
                Testi.consenti,
                Permesso.batteria,
                ok: widget.stato.batteriaLibera,
              ),
              _riga(
                Testi.permessoPaginaBatteria,
                Testi.apri,
                Permesso.paginaBatteria,
              ),
              _riga(Testi.permessoSamsung, Testi.apri, Permesso.samsung),
              const SizedBox(height: 8),
              Text(
                Testi.batteria(widget.stato.batteriaLibera),
                style: TextStyle(
                  color: widget.stato.batteriaLibera == false
                      ? Colori.errore
                      : Colori.spento,
                  fontSize: Misure.piccolo,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    actions: <Widget>[
      FilledButton(
        onPressed: () => Navigator.of(context).pop(),
        style: stileAccento(),
        child: const Text(Testi.fatto),
      ),
    ],
  );
}
