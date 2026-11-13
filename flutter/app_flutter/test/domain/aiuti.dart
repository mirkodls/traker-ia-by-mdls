// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
//
// Aiuti comuni ai test del domain.
import 'package:traker_ia/domain/modelli.dart';
import 'package:traker_ia/domain/tempo.dart';

/// 'aaaa-mm-gg hh:mm' -> data (errore se sbagliata).
DateTime t(String s) => interpreta(s)!;

/// Lettura veloce per i test.
Lettura l(
  String ora,
  double? sett,
  double? sess, {
  String modelli = '',
  String skill = '',
  bool? alPc,
  String gestore = gestoreAnthropic,
}) =>
    Lettura(
      ora: t(ora),
      sett: sett,
      sess: sess,
      modelli: modelli,
      skill: skill,
      alPc: alPc,
      gestore: gestore,
    );
