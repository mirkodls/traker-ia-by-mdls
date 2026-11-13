// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
//
// Strato ui: solo grafica. Può usare domain. Schermata provvisoria del Blocco 0:
// la grafica vera arriva nel Blocco 3.
import 'package:material_ui/material_ui.dart';

import 'package:traker_ia/domain/info_app.dart';

/// Radice dell'app.
class TrakerApp extends StatelessWidget {
  /// Crea la radice dell'app.
  const TrakerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: nomeApp,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.teal,
      ),
      home: const _SchermataProvvisoria(),
    );
  }
}

class _SchermataProvvisoria extends StatelessWidget {
  const _SchermataProvvisoria();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text(nomeApp)));
  }
}
