// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
//
// Strato ui (solo telefono): tutto in una schermata, senza scorrere.
// In alto % piccole + crediti + ⟳ + ⚙, poi il grafico grande (zoom a due
// dita, tasto Piano), sotto nota, progetto attivo e i tasti per Dati,
// Intensità, Confronti, Progetti. B21: stesse funzioni V2 del PC (tranne
// il Resoconto IA via API, solo PC).
import 'dart:async';

import 'package:material_ui/material_ui.dart';

import 'package:traker_ia/domain/periodo.dart';
import 'package:traker_ia/domain/preferenze.dart';
import 'package:traker_ia/domain/traduzioni/testi_it.dart';
import 'package:traker_ia/ui/barra_intensita.dart';
import 'package:traker_ia/ui/barra_piano.dart';
import 'package:traker_ia/ui/dialoghi.dart';
import 'package:traker_ia/ui/grafico.dart';
import 'package:traker_ia/ui/grafico_dati.dart';
import 'package:traker_ia/ui/pagina_progetti.dart';
import 'package:traker_ia/ui/sezioni.dart';
import 'package:traker_ia/ui/stato_app.dart';
import 'package:traker_ia/ui/tema.dart';

/// Schermata unica del telefono.
class SchermoTelefono extends StatelessWidget {
  /// Crea la schermata.
  const SchermoTelefono({required this.stato, required this.mouse, super.key});

  /// Stato dell'app.
  final StatoApp stato;

  /// Mouse/dito sui grafici.
  final MouseGrafici mouse;

  @override
  Widget build(BuildContext context) {
    final DatiGrafico? d = stato.grafico;
    final Preferenze p = stato.preferenze;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _testata(context),
          RigaStato(stato: stato),
          _RigaSottofondo(stato: stato),
          Expanded(
            child: d == null ? const SizedBox.shrink() : _grafico(context, d),
          ),
          const SizedBox(height: 6),
          RigaNota(stato: stato),
          // V2: tasti modelli/skill solo se accesi.
          if (p.modelliSkill) ...<Widget>[
            const SizedBox(height: 6),
            BarraTasti(
              stato: stato,
              compatta: true,
              modifica: (Gruppo g) => apriModifica(context, stato, g),
            ),
          ],
          if (p.lavoroV2 && stato.progetti.isNotEmpty) ...<Widget>[
            const SizedBox(height: 4),
            BarraProgetti(stato: stato, unaRiga: true),
          ],
          const SizedBox(height: 4),
          _tastiSezioni(context),
        ],
      ),
    );
  }

  // ------------------------------------------------------------- testata

  Widget _testata(BuildContext context) {
    final ({String valore, String sotto}) cr = stato.cartaCrediti;
    final ValoreCarta sess = stato.cartaSess;
    final ValoreCarta sett = stato.cartaSett;
    double? quota(double? v) => v == null ? null : (v / 100).clamp(0, 1);
    return Row(
      children: <Widget>[
        Expanded(
          child: _Mini(
            titolo: Testi.cortoSess,
            testo: percento(sess.valore),
            sotto: sess.sotto,
            barra: quota(sess.valore),
            colore: Colori.sess,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _Mini(
            titolo: Testi.cortoSett,
            testo: percento(sett.valore),
            sotto: sett.sotto,
            barra: quota(sett.valore),
            colore: Colori.sett,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _Mini(
            key: const ValueKey<String>('mini-crediti'),
            titolo: Testi.cartaCrediti,
            testo: cr.valore,
            sotto: cr.sotto,
            barra: stato.quotaCrediti,
            colore: Colori.testo,
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            IconButton(
              tooltip: Testi.leggiOra,
              onPressed: stato.inLettura ? null : stato.leggi,
              icon: const Icon(Icons.refresh),
            ),
            IconButton(
              tooltip: Testi.impostazioni,
              onPressed: () => unawaited(_menu(context)),
              icon: const Icon(Icons.settings),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _menu(BuildContext context) async {
    final String? scelta = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colori.carta,
      builder: (BuildContext c) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _voce(c, Icons.settings, Testi.impostazioni, 'imp'),
            _voce(c, Icons.edit_note, Testi.letturaManuale, 'man'),
            _voce(c, Icons.battery_saver, Testi.menuPermessi, 'perm'),
            if (stato.preferenze.modelliSkill) ...<Widget>[
              _voce(
                c,
                Icons.smart_toy_outlined,
                Testi.titoloModifica(Testi.gruppoModelli.toLowerCase()),
                'mod',
              ),
              _voce(
                c,
                Icons.bolt,
                Testi.titoloModifica(Testi.gruppoSkill.toLowerCase()),
                'skill',
              ),
            ],
          ],
        ),
      ),
    );
    if (!context.mounted || scelta == null) {
      return;
    }
    switch (scelta) {
      case 'imp':
        await apriImpostazioni(
          context,
          stato,
          claudeCode: stato.servizi.claudeCodeTrovato,
        );
      case 'man':
        await apriManuale(context, stato);
      case 'perm':
        await apriPermessi(context, stato);
      case 'mod':
        await apriModifica(context, stato, Gruppo.modelli);
      case 'skill':
        await apriModifica(context, stato, Gruppo.skill);
    }
  }

  Widget _voce(BuildContext c, IconData i, String t, String v) => ListTile(
    leading: Icon(i, color: Colori.accento),
    title: Text(t, style: stileNormale),
    onTap: () => Navigator.of(c).pop(v),
  );

  // ------------------------------------------------------------- grafico

  Widget _grafico(BuildContext context, DatiGrafico d) {
    final Preferenze p = stato.preferenze;
    return Carta(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 2),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Slider(
                  value: p.periodo.toDouble(),
                  max: (oreScatti.length - 1).toDouble(),
                  divisions: oreScatti.length - 1,
                  onChanged: (double v) => stato.cambiaPeriodo(v.round()),
                ),
              ),
              Text(
                etichettaScatto(p.periodo),
                style: stileTitolo.copyWith(color: Colori.accento),
              ),
              if (p.lavoroV2)
                TextButton.icon(
                  key: const ValueKey<String>('tasto-piano'),
                  onPressed: () => unawaited(_foglioPiano(context)),
                  icon: const Icon(Icons.calendar_month, size: 16),
                  label: const Text(
                    Testi.tastoPiano,
                    style: TextStyle(fontSize: 12),
                  ),
                )
              else
                const SizedBox(width: 6),
            ],
          ),
          Expanded(
            // Due dita = zoom e spostamento; il grafico resta nel riquadro.
            child: ClipRect(
              child: InteractiveViewer(
                maxScale: 6,
                child: Grafico(
                  tipo: TipoGrafico.principale,
                  dati: d,
                  letture: stato.letture,
                  mouse: mouse,
                  modelliSkill: p.modelliSkill,
                  mostraIdeale: p.lavoroV2 && p.lineaIdeale,
                  mostraAdattiva: p.lavoroV2 && p.lineaAdattiva,
                  stile: p.stileLinee,
                ),
              ),
            ),
          ),
          const Text(Testi.aiutoZoom, style: stilePiccolo),
        ],
      ),
    );
  }

  /// Piano (giorni di lavoro, linee ideale/adattiva) in un foglio dal basso.
  Future<void> _foglioPiano(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colori.sfondo,
    builder: (BuildContext c) => SafeArea(
      child: ListenableBuilder(
        listenable: stato,
        builder: (BuildContext c, Widget? _) => SingleChildScrollView(
          key: const ValueKey<String>('foglio-piano'),
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                Testi.tastoPiano,
                style: stilePiccolo.copyWith(fontWeight: FontWeight.bold),
              ),
              BarraPiano(stato: stato),
              const Text(Testi.spiegaIdeale, style: stilePiccolo),
              const SizedBox(height: 4),
              const Text(Testi.spiegaAdattiva, style: stilePiccolo),
            ],
          ),
        ),
      ),
    ),
  );

  // ------------------------------------------------------------ sezioni

  Widget _intensita() {
    final DatiGrafico? d = stato.grafico;
    if (d == null) {
      return const SizedBox.shrink();
    }
    return Carta(
      padding: const EdgeInsets.all(6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (d.intensitaV2 != null)
            BarraIntensita(stato: stato, serie: d.intensitaV2!),
          SizedBox(
            height: 220,
            child: Grafico(
              tipo: TipoGrafico.intensita,
              dati: d,
              letture: stato.letture,
              mouse: mouse,
              modelliSkill: stato.preferenze.modelliSkill,
              stile: stato.preferenze.stileLinee,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tastiSezioni(BuildContext context) {
    Widget tasto(String chiave, String testo, VoidCallback onTap) => Expanded(
      child: TextButton(
        key: ValueKey<String>('sezione-$chiave'),
        onPressed: onTap,
        child: Text(
          testo,
          style: const TextStyle(fontSize: 11),
          textAlign: TextAlign.center,
          maxLines: 2,
        ),
      ),
    );
    String titolo(String k) => Testi.titoliSezioni[k] ?? k;
    return Row(
      children: <Widget>[
        tasto(
          'dati',
          titolo('dati'),
          () => unawaited(
            _foglio(context, 'dati', () => CartaDati(stato: stato)),
          ),
        ),
        tasto(
          'intensita',
          titolo('intensita'),
          () => unawaited(_foglio(context, 'intensita', _intensita)),
        ),
        tasto(
          'confronti',
          titolo('confronti'),
          () => unawaited(
            _foglio(context, 'confronti', () => CartaConfronti(stato: stato)),
          ),
        ),
        if (stato.preferenze.lavoroV2)
          tasto(
            'progetti',
            Testi.tastoProgetti.toUpperCase(),
            () => unawaited(apriPaginaProgetti(context, stato)),
          ),
      ],
    );
  }

  Future<void> _foglio(
    BuildContext context,
    String chiave,
    Widget Function() corpo,
  ) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colori.sfondo,
    builder: (BuildContext c) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      builder: (BuildContext c, ScrollController sc) => ListenableBuilder(
        listenable: stato,
        builder: (BuildContext c, Widget? _) => ListView(
          controller: sc,
          padding: const EdgeInsets.all(10),
          children: <Widget>[
            Text(
              Testi.titoliSezioni[chiave] ?? chiave,
              style: stilePiccolo.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            corpo(),
          ],
        ),
      ),
    ),
  );
}

/// Interruttore Sottofondo (letture a app chiusa) con intervallo e stima
/// batteria; se la batteria è limitata, avviso che apre i permessi.
class _RigaSottofondo extends StatelessWidget {
  const _RigaSottofondo({required this.stato});

  final StatoApp stato;

  @override
  Widget build(BuildContext context) {
    final bool acceso = stato.preferenze.sfondoAcceso;
    final bool limitata = acceso && stato.batteriaLibera == false;
    return Row(
      children: <Widget>[
        const Icon(Icons.nightlight_outlined, size: 16, color: Colori.spento),
        const SizedBox(width: 6),
        const Text(Testi.sottofondo, style: stileNormale),
        const SizedBox(width: 8),
        Expanded(
          child: limitata
              ? TextButton(
                  onPressed: () => unawaited(apriPermessi(context, stato)),
                  style: TextButton.styleFrom(
                    alignment: Alignment.centerLeft,
                    padding: EdgeInsets.zero,
                  ),
                  child: const Text(
                    Testi.batteriaLimitata,
                    style: TextStyle(color: Colori.errore, fontSize: 11),
                  ),
                )
              : Text(
                  Testi.rigaSottofondo(
                    acceso: acceso,
                    login: stato.cookie,
                    minuti: stato.preferenze.minutiSfondo,
                  ),
                  style: const TextStyle(color: Colori.spento, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
        ),
        Switch(
          value: acceso,
          onChanged: (bool v) => unawaited(stato.cambiaSfondo(acceso: v)),
        ),
      ],
    );
  }
}

/// Carta piccola per il telefono: valore grande, titolo, riga sotto e
/// barretta ([barra] 0-1, null = vuota).
class _Mini extends StatelessWidget {
  const _Mini({
    required this.titolo,
    required this.testo,
    required this.sotto,
    required this.barra,
    required this.colore,
    super.key,
  });

  final String titolo;
  final String testo;
  final String sotto;
  final double? barra;
  final Color colore;

  @override
  Widget build(BuildContext context) => Carta(
    padding: const EdgeInsets.fromLTRB(7, 6, 7, 6),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          titolo,
          style: stilePiccolo.copyWith(fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        // Valori lunghi (es. crediti) si rimpiccioliscono, mai tagliati.
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            testo,
            style: TextStyle(
              color: colore,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              height: 1,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          sotto,
          style: const TextStyle(color: Colori.spento, fontSize: 10),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: barra ?? 0,
            minHeight: 3,
            color: colore,
            backgroundColor: Colori.carta2,
          ),
        ),
      ],
    ),
  );
}
