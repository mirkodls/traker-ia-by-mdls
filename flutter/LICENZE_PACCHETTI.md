# Licenze pacchetti — controllo Blocco 0 (13/11/2026)

Fonte: pub.dev (analisi automatica della licenza di ogni pacchetto).
Regola del progetto: solo MIT, BSD o Apache 2.0. Risultato: tutti OK.

| Pacchetto | Licenza | Serve a | Piattaforme |
|---|---|---|---|
| material_ui | BSD-3 | grafica Material (già nell'app) | tutte |
| flutter_lints | BSD-3 | lint (solo sviluppo) | — |
| fl_chart | MIT | grafico | tutte |
| drift + sqlite3_flutter_libs | MIT | database locale | tutte |
| flutter_secure_storage | BSD-3 | segreti cifrati | tutte |
| workmanager | MIT | lettura in background | Android (no Windows) |
| flutter_inappwebview | Apache 2.0 | login claude.ai nell'app | Android, Windows |
| tray_manager | MIT | icona vicino all'orologio | Windows |
| launch_at_startup | MIT | avvio con Windows | Windows |
| window_manager | MIT | "Sempre in primo piano" | Windows |
| multicast_dns | BSD-3 | sync Wi-Fi: trova dispositivi | tutte tranne web |
| path_provider | BSD-3 | cartella dati dell'app | tutte |
| cryptography | Apache 2.0 | cifratura sync Wi-Fi | tutte |

Note:
- Nel Blocco 0 NON è stato aggiunto nessun pacchetto: ogni blocco aggiunge solo quelli che gli servono.
- window_manager, path_provider e cryptography non erano nella lista di PROGETTO.md: sono proposte, da decidere nei blocchi che li usano.
- Leggerezza: per il grafico il Blocco 3 valuta se basta CustomPainter (zero pacchetti) invece di fl_chart.
- Quando si aggiunge un pacchetto: ricontrollare anche i pacchetti che si porta dietro (comando: flutter pub deps).
- Apache 2.0: nell'app va mostrata la pagina Licenze (Flutter la genera da solo con showLicensePage).
