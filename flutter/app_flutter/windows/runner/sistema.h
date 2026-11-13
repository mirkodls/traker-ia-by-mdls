// TraKer IA by mdls - Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
//
// Funzioni Windows senza pacchetti: una sola copia, avvio con Windows.
#ifndef RUNNER_SISTEMA_H_
#define RUNNER_SISTEMA_H_

#include <windows.h>

#include <string>

namespace sistema {

// Argomento messo nell'avvio con Windows: parte nascosta nel tray.
constexpr const wchar_t kArgNascosto[] = L"--nascosto";

// Vero se la riga di comando contiene --nascosto.
bool AvvioNascosto();

// Prende il "lucchetto" della copia unica. Falso = c'e' gia' un'altra copia
// aperta: in quel caso le chiede di mostrarsi.
bool PrendiCopiaUnica();

// Messaggio che una seconda copia manda alla prima: "mostrati".
UINT MessaggioMostra();

// Vero se l'app parte con Windows (voce presente e non disattivata in
// Gestione attivita' > App di avvio).
bool AvvioWindowsAttivo();

// Acceso: scrive la voce col percorso dell'exe attuale + --nascosto e la
// riattiva se era disattivata. Spento: toglie la voce. Vero = riuscito.
bool ImpostaAvvioWindows(bool acceso);

// Testo UTF-8 (da Dart) -> testo Windows.
std::wstring DaUtf8(const std::string& testo);

}  // namespace sistema

#endif  // RUNNER_SISTEMA_H_
