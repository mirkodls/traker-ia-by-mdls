# Licenze pacchetti — controllo Blocco 0 (13/11/2026)

Fonte: pub.dev (analisi automatica della licenza di ogni pacchetto).
Regola del progetto: solo MIT, BSD o Apache 2.0. Risultato: tutti OK.

| Pacchetto | Licenza | Serve a | Piattaforme |
|---|---|---|---|
| material_ui | BSD-3 | grafica Material (già nell'app) | tutte |
| flutter_lints | BSD-3 | lint (solo sviluppo) | — |
| fl_chart | MIT | grafico | tutte |
| drift + drift_flutter | MIT | database locale (AGGIUNTO Blocco 2; drift_flutter sostituisce sqlite3_flutter_libs, consigliato da drift) | tutte |
| flutter_secure_storage | BSD-3 | segreti cifrati (AGGIUNTO Blocco 2; su Windows serve ATL di Visual Studio per compilare l'exe) | tutte |
| workmanager | MIT | lettura in background (AGGIUNTO Blocco 5, 0.10) | Android (no Windows) |
| flutter_inappwebview | Apache 2.0 | login claude.ai nell'app — NON usato (Blocco 5): scelto webview_flutter, più leggero | Android, Windows |
| webview_flutter | BSD-3 | login claude.ai nell'app (AGGIUNTO Blocco 5, 4.14) | Android |
| tray_manager | MIT | icona vicino all'orologio | Windows |
| launch_at_startup | MIT | avvio con Windows | Windows |
| window_manager | MIT | "Sempre in primo piano" — NON usato (Blocco 3): la versione 0.7 compila codice C in più (nativeapi). Fatto con un piccolo canale nostro in windows/runner/flutter_window.cpp, zero pacchetti | Windows |
| multicast_dns | BSD-3 | sync Wi-Fi: trova dispositivi | tutte tranne web |
| path_provider | BSD-3 | cartella dati dell'app (AGGIUNTO Blocco 2) | tutte |
| cryptography | Apache 2.0 | cifratura sync Wi-Fi | tutte |

Note:
- Nel Blocco 0 NON è stato aggiunto nessun pacchetto: ogni blocco aggiunge solo quelli che gli servono.
- window_manager, path_provider e cryptography non erano nella lista di PROGETTO.md: sono proposte, da decidere nei blocchi che li usano.
- Leggerezza: Blocco 3 ha fatto il grafico con CustomPainter (zero pacchetti): fl_chart NON usato.
- Blocco 3: nessun pacchetto aggiunto (traduzioni = file Dart semplice).
- Quando si aggiunge un pacchetto: ricontrollare anche i pacchetti che si porta dietro (comando: flutter pub deps).
- Apache 2.0: nell'app va mostrata la pagina Licenze (Flutter la genera da solo con showLicensePage).
- Blocco 2, solo sviluppo (non finiscono nell'app): drift_dev (MIT), build_runner (BSD-3).
- Blocco 4 (firma: chat 4): tray_manager e launch_at_startup NON usati. Icona tray, avvio con Windows e una sola copia fatti con codice nostro in windows/runner/sistema.cpp e flutter_window.cpp (API di Windows), zero pacchetti nuovi.
- Blocco 5 (firma: chat 5): webview_flutter (BSD-3, Google) + workmanager (MIT), Mirko ok. Cookie della pagina letto con canale nostro in MainActivity.kt (CookieManager di Android), zero pacchetti in più. Permessi aggiunti da workmanager tolti nel manifest: POST_NOTIFICATIONS, FOREGROUND_SERVICE, FOREGROUND_SERVICE_SHORT_SERVICE.
