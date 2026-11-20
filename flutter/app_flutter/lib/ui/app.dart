// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
//
// Strato ui: radice dell'app e finestra principale. Si adatta: largo =
// riquadri affiancati, stretto = impilati, finestra piccola = scorrimento.
import 'dart:async';

import 'package:material_ui/material_ui.dart';

import 'package:traker_ia/domain/info_app.dart';
import 'package:traker_ia/domain/periodo.dart';
import 'package:traker_ia/domain/preferenze.dart';
import 'package:traker_ia/domain/traduzioni/testi_it.dart';
import 'package:traker_ia/domain/vista.dart';
import 'package:traker_ia/ui/barra_intensita.dart';
import 'package:traker_ia/ui/barra_piano.dart';
import 'package:traker_ia/ui/dialoghi.dart';
import 'package:traker_ia/ui/grafico.dart';
import 'package:traker_ia/ui/grafico_dati.dart';
import 'package:traker_ia/ui/pagina_progetti.dart';
import 'package:traker_ia/ui/schermo_telefono.dart';
import 'package:traker_ia/ui/sezioni.dart';
import 'package:traker_ia/ui/stato_app.dart';
import 'package:traker_ia/ui/tema.dart';

/// Larghezza da cui la grafica affianca i riquadri.
const double larghezzaLarga = 900;

/// Radice dell'app.
class TrakerApp extends StatelessWidget {
  /// Crea la radice dell'app.
  const TrakerApp({required this.stato, super.key});

  /// Stato dell'app.
  final StatoApp stato;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: nomeApp,
      debugShowCheckedModeBanner: false,
      theme: temaScuro(),
      home: Finestra(stato: stato),
    );
  }
}

/// Finestra principale.
class Finestra extends StatefulWidget {
  /// Crea la finestra.
  const Finestra({required this.stato, super.key});

  /// Stato dell'app.
  final StatoApp stato;

  @override
  State<Finestra> createState() => _StatoFinestra();
}

class _StatoFinestra extends State<Finestra> {
  final MouseGrafici _mouse = MouseGrafici();
  bool _avvisoAperto = false;

  StatoApp get _s => widget.stato;

  @override
  void initState() {
    super.initState();
    _s.addListener(_controllaAvviso);
  }

  @override
  void dispose() {
    _s.removeListener(_controllaAvviso);
    _mouse.dispose();
    super.dispose();
  }

  void _controllaAvviso() {
    final String? m = _s.avvisoDaMostrare;
    if (m == null || _avvisoAperto) {
      return;
    }
    _s.avvisoVisto();
    _avvisoAperto = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        await apriAvviso(context, m);
      }
      _avvisoAperto = false;
    });
  }

  // ------------------------------------------------------------- menu vista

  Future<void> _menuVista(Offset dove) async {
    final StatoVista v = _s.vista;
    final RenderBox box =
        Overlay.of(context).context.findRenderObject()! as RenderBox;
    final String? scelta = await showMenu<String>(
      context: context,
      color: Colori.carta2,
      position: RelativeRect.fromRect(
        Rect.fromLTWH(dove.dx, dove.dy, 1, 1),
        Offset.zero & box.size,
      ),
      items: <PopupMenuEntry<String>>[
        for (final Sezione s in Sezione.values)
          CheckedPopupMenuItem<String>(
            value: 's:${s.name}',
            checked: v.spuntata(s),
            child: Text(
              Testi.voceSezione(
                s.name,
                modelliSkill: _s.preferenze.modelliSkill,
              ),
            ),
          ),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          value: 'm:tutto',
          child: Text(Testi.modoTutto),
        ),
        const PopupMenuItem<String>(
          value: 'm:grafico',
          child: Text(Testi.modoGrafico),
        ),
        const PopupMenuItem<String>(
          value: 'm:intensita',
          child: Text(Testi.modoIntensita),
        ),
        if (_s.servizi.primoPianoDisponibile) ...<PopupMenuEntry<String>>[
          const PopupMenuDivider(),
          CheckedPopupMenuItem<String>(
            value: 'pp',
            checked: v.primoPiano,
            child: const Text(Testi.primoPiano),
          ),
        ],
      ],
    );
    if (scelta == null) {
      return;
    }
    if (scelta == 'pp') {
      await _s.cambiaPrimoPiano();
    } else if (scelta.startsWith('s:')) {
      await _s.cambiaVisibile(Sezione.values.byName(scelta.substring(2)));
    } else {
      await _s.scegliModo(ModoVista.values.byName(scelta.substring(2)));
    }
  }

  Widget _tastoVista() => Builder(
    builder: (BuildContext c) => FilledButton(
      onPressed: () {
        final RenderBox b = c.findRenderObject()! as RenderBox;
        unawaited(_menuVista(b.localToGlobal(Offset(0, b.size.height))));
      },
      child: const Text(Testi.vista),
    ),
  );

  // ------------------------------------------------------------- sezioni

  Widget _titolo(Sezione s, bool aperta) => InkWell(
    onTap: () => _s.cambiaAperta(s),
    child: Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 4, left: 2),
      child: Text(
        '${aperta ? '▾' : '▸'}  '
        '${Testi.titoloSezione(s.name, modelliSkill: _s.preferenze.modelliSkill)}',
        style: stilePiccolo.copyWith(fontWeight: FontWeight.bold),
      ),
    ),
  );

  Widget _tasti() => Wrap(
    spacing: 6,
    runSpacing: 6,
    children: <Widget>[
      FilledButton(
        onPressed: _s.inLettura ? null : _s.leggi,
        child: const Text(Testi.leggiOra),
      ),
      FilledButton(
        onPressed: () => apriManuale(context, _s),
        child: const Text(Testi.letturaManuale),
      ),
      FilledButton(
        onPressed: () => apriImpostazioni(
          context,
          _s,
          claudeCode: _s.servizi.claudeCodeTrovato,
        ),
        child: const Text(Testi.impostazioni),
      ),
      _tastoVista(),
      if (_s.preferenze.lavoroV2)
        FilledButton(
          key: const ValueKey<String>('tasto-progetti'),
          onPressed: () => apriPaginaProgetti(context, _s),
          child: const Text(Testi.tastoProgetti),
        ),
      const Tooltip(
        message: Testi.inArrivo,
        child: FilledButton(
          onPressed: null,
          child: Text('${Testi.skillTasto} (${Testi.inArrivo})'),
        ),
      ),
    ],
  );

  Widget _carte(bool largo) {
    final Widget sess = CartaPercento(
      titolo: Testi.cartaSess,
      valore: _s.cartaSess,
      colore: Colori.sess,
    );
    final Widget sett = CartaPercento(
      titolo: Testi.cartaSett,
      valore: _s.cartaSett,
      colore: Colori.sett,
    );
    final ({String valore, String sotto}) cr = _s.cartaCrediti;
    final Widget crediti = CartaTesto(
      key: const ValueKey<String>('carta-crediti'),
      titolo: Testi.cartaCrediti,
      valore: cr.valore,
      sotto: cr.sotto,
      colore: Colori.testo,
    );
    final Widget coppia = LayoutBuilder(
      builder: (BuildContext context, BoxConstraints c) => c.maxWidth >= 720
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(flex: 3, child: sess),
                const SizedBox(width: 8),
                Expanded(flex: 3, child: sett),
                const SizedBox(width: 8),
                Expanded(flex: 2, child: crediti),
              ],
            )
          : c.maxWidth >= 480
          ? Column(
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(child: sess),
                    const SizedBox(width: 8),
                    Expanded(child: sett),
                  ],
                ),
                const SizedBox(height: 8),
                crediti,
              ],
            )
          : Column(
              children: <Widget>[
                sess,
                const SizedBox(height: 8),
                sett,
                const SizedBox(height: 8),
                crediti,
              ],
            ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (largo)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(flex: 3, child: coppia),
              const SizedBox(width: 10),
              Expanded(flex: 2, child: _tasti()),
            ],
          )
        else ...<Widget>[coppia, const SizedBox(height: 8), _tasti()],
        RigaStato(stato: _s),
      ],
    );
  }

  Widget _periodo() => Row(
    children: <Widget>[
      const Text(Testi.periodo, style: stileTitolo),
      Flexible(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 260),
          child: Slider(
            value: _s.preferenze.periodo.toDouble(),
            max: (oreScatti.length - 1).toDouble(),
            divisions: oreScatti.length - 1,
            onChanged: (double v) => _s.cambiaPeriodo(v.round()),
          ),
        ),
      ),
      Text(
        etichettaScatto(_s.preferenze.periodo),
        style: stileTitolo.copyWith(color: Colori.accento),
      ),
    ],
  );

  Widget _grafico(DatiGrafico d, double? alt) {
    final Widget g = Grafico(
      tipo: TipoGrafico.principale,
      dati: d,
      letture: _s.letture,
      mouse: _mouse,
      modelliSkill: _s.preferenze.modelliSkill,
      mostraIdeale: _s.preferenze.lavoroV2 && _s.preferenze.lineaIdeale,
      mostraAdattiva: _s.preferenze.lavoroV2 && _s.preferenze.lineaAdattiva,
      stile: _s.preferenze.stileLinee,
    );
    return Carta(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 6),
      child: Column(
        mainAxisSize: alt == null ? MainAxisSize.max : MainAxisSize.min,
        children: <Widget>[
          _periodo(),
          if (_s.preferenze.lavoroV2) BarraPiano(stato: _s),
          if (alt == null)
            Expanded(child: g)
          else
            SizedBox(height: alt, child: g),
        ],
      ),
    );
  }

  Widget _intensita(DatiGrafico d, double? alt) {
    final Widget g = Grafico(
      tipo: TipoGrafico.intensita,
      dati: d,
      letture: _s.letture,
      mouse: _mouse,
      modelliSkill: _s.preferenze.modelliSkill,
      stile: _s.preferenze.stileLinee,
    );
    final bool v2 = d.intensitaV2 != null;
    return Carta(
      padding: const EdgeInsets.all(6),
      child: Column(
        mainAxisSize: alt == null ? MainAxisSize.max : MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (v2) BarraIntensita(stato: _s, serie: d.intensitaV2!),
          if (alt == null)
            Expanded(child: g)
          else
            SizedBox(height: alt, child: g),
        ],
      ),
    );
  }

  Widget _corpo(Sezione s, bool largo, double altGrafico, double altInt) {
    final DatiGrafico? d = _s.grafico;
    return switch (s) {
      Sezione.carte => _carte(largo),
      Sezione.grafico =>
        d == null ? const SizedBox.shrink() : _grafico(d, altGrafico),
      Sezione.intensita =>
        d == null ? const SizedBox.shrink() : _intensita(d, altInt),
      Sezione.barra => Column(
        children: <Widget>[
          // V2: tasti modelli/skill solo se accesi; note sempre.
          if (_s.preferenze.modelliSkill) ...<Widget>[
            BarraTasti(
              stato: _s,
              modifica: (Gruppo g) => apriModifica(context, _s, g),
            ),
            const SizedBox(height: 6),
          ],
          if (_s.preferenze.lavoroV2 && _s.progetti.isNotEmpty) ...<Widget>[
            BarraProgetti(stato: _s),
            const SizedBox(height: 6),
          ],
          RigaNota(stato: _s),
        ],
      ),
      Sezione.dati => CartaDati(stato: _s),
      Sezione.confronti => CartaConfronti(stato: _s),
    };
  }

  Widget _sezione(
    Sezione s,
    bool aperta,
    bool largo,
    double altGrafico,
    double altInt,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      _titolo(s, aperta),
      if (aperta) _corpo(s, largo, altGrafico, altInt),
    ],
  );

  Widget _tutto(BoxConstraints c) {
    final bool largo = c.maxWidth >= larghezzaLarga;
    final double h = c.maxHeight;
    final double altGrafico = (h * 0.42).clamp(220, 640).toDouble();
    final double altInt = (h * 0.15).clamp(90, 240).toDouble();
    final List<(Sezione, bool)> sez = _s.vista.mostra();
    final List<Widget> figli = <Widget>[];
    for (int i = 0; i < sez.length; i++) {
      final (Sezione, bool) x = sez[i];
      final bool coppia =
          largo &&
          x.$1 == Sezione.dati &&
          i + 1 < sez.length &&
          sez[i + 1].$1 == Sezione.confronti;
      if (coppia) {
        final (Sezione, bool) y = sez[i + 1];
        figli.add(
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                flex: 2,
                child: _sezione(x.$1, x.$2, largo, altGrafico, altInt),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 3,
                child: _sezione(y.$1, y.$2, largo, altGrafico, altInt),
              ),
            ],
          ),
        );
        i++;
        continue;
      }
      figli.add(_sezione(x.$1, x.$2, largo, altGrafico, altInt));
    }
    return Scrollbar(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: figli,
        ),
      ),
    );
  }

  Widget _soloUno() {
    final DatiGrafico? d = _s.grafico;
    if (d == null) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.all(8),
      child: _s.vista.modo == ModoVista.grafico
          ? _grafico(d, null)
          : _intensita(d, null),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _s,
          builder: (BuildContext context, _) {
            if (!_s.pronto) {
              return const Center(child: CircularProgressIndicator());
            }
            final bool soloUno = _s.vista.modo != ModoVista.tutto;
            final bool senzaTasti =
                soloUno ||
                !_s.vista.spuntata(Sezione.carte) ||
                !(_s.vista.aperte[Sezione.carte] ?? true);
            return GestureDetector(
              behavior: HitTestBehavior.translucent,
              onSecondaryTapDown: (TapDownDetails d) =>
                  _menuVista(d.globalPosition),
              child: Stack(
                children: <Widget>[
                  Positioned.fill(
                    child: _s.servizi.telefono
                        ? SchermoTelefono(stato: _s, mouse: _mouse)
                        : soloUno
                        ? _soloUno()
                        : LayoutBuilder(
                            builder: (BuildContext context, BoxConstraints c) =>
                                _tutto(c),
                          ),
                  ),
                  if (senzaTasti && !_s.servizi.telefono)
                    Positioned(right: 8, top: 6, child: _tastoVista()),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
