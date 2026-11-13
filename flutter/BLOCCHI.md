# BLOCCHI — Traker uso IA (Flutter)

Scritto: 12/11/2026, chat di progettazione. Leggi prima PROGETTO.md.

## MVP (prima versione da provare, Windows + Android)
- Lettura automatica Windows: estensione browser Chromium + token Claude Code + cookie, catena con riserve.
- Lettura automatica Android: login claude.ai dentro l'app + background ~15 min.
- Lettura manuale e inserimento a mano.
- Storico locale + import vecchi letture.csv/eventi.csv.
- Grafico (settimanale + 5 ore), reset segnati, note con verdetto SCESO/SALITO/COSTANTE.
- Inizio/Fine lavoro.
- Pannello combinazioni: modelli a destra (icone), skill a sinistra (tasti scrivibili), tutti modificabili; confronto tra 2 combinazioni + classifica per modello.
- Mouse/dito sulla linea: % in ogni punto (stimata "~" tra due letture).
- Riga intensità (pt%/ora, media 30 min) in un grafico piccolo sotto.
- Previsione fine piano + budget del giorno.
- Riquadro "Cosa dicono i dati" (frasi a regole, niente IA).
- Avviso dopo 2 giri di lettura falliti.
- Windows: icona tray + avvio con Windows + una sola copia aperta.
- Sync Wi-Fi locale tra dispositivi della stessa persona.
- Solo gestore Anthropic, ma logica già multi-gestore.

## FUORI DA MVP
- Sync Google Drive personale.
- Gestore OpenAI Codex/ChatGPT (poi altri gestori).
- "Al PC" / "in automatico" (solo desktop).
- Estensione Firefox + pubblicazione su AMO.
- Installer Windows, firma digitale, store (Microsoft Store, Google Play).
- Testi in inglese, pagina privacy, pagina licenze completa.
- Esporta CSV (apribile con Excel).
- Log di Claude Code (modello e token esatti).
- Ritmo tra due note · avviso "dato debole" · grafico a candele.
- Tasto "Copia riepilogo per Claude".
- Decisione vendita / store (dopo prova di Mirko + 2-3 persone).
- Linux, Mac, iOS.
- GitHub Actions automatiche.

## SCARTATI
Cattura schermo · elenco chat claude.ai · IA dentro l'app · abbonamento mensile.

## Blocchi
| N | Nome | Cosa fa |
|---|------|---------|
| 0 | Base | Flutter sul PC (.bat), crea flutter\app_flutter\ con lib/ui lib/domain lib/data, lint rigido, LICENSE chiusa, STATO_FLUTTER.md, prova test e build Android nel cloud. |
| 1 | Logica + test | Modelli (gestore, lettura, evento, periodo con nome), ritmo pt%/h, reset, verdetto ±10%, inizio/fine lavoro, combinazioni modelli+skill e confronto, intensità (media mobile), % stimata tra letture, previsione fine piano, budget del giorno, frasi "Cosa dicono i dati", catena letture (regole), avviso 2 KO, import CSV, unione dati per sync (senza doppioni). Solo domain, tutto testato. |
| 2 | Dati + letture Windows | Database, segreti cifrati, lettore Anthropic (token Claude Code, cookie), ricevitore locale per l'estensione, estensione browser Chromium riscritta, import CSV dal file vero. |
| 3 | Grafica | Tema scuro, grafica che si adatta largo/stretto, grafico, note, manuale, inizio/fine, pannello combinazioni (modelli dx, skill sx, modificabili), mouse/dito sulla linea, grafico intensità, previsione + budget, riquadro "Cosa dicono i dati", impostazioni, avviso. Testi in file traduzioni (solo IT). |
| 4 | Windows sistema | Tray, avvio con Windows, una sola copia, .bat per compilare l'exe sul PC, prova dal vivo. |
| 5 | Android | Login claude.ai in-app, cookie salvato cifrato, lettura in background, apk, prova sul telefono. |
| 6 | Sync Wi-Fi | Abbinamento con codice, ricerca in rete, scambio cifrato, unione dati, prova PC ↔ telefono. FINE MVP. |
| 7+ | Dopo MVP | Uno per volta dalla lista FUORI DA MVP (si decide a fine MVP). |

Ordine obbligato (agg. 13/11 sera, deciso da Mirko: prima app desktop Windows completa, poi Android, poi sync): 0 → 1 → 2 → 3 → 4 → 5 → 6. Una chat alla volta. Prima del Blocco 3 Mirko lancia flutter\strumenti_pc\installa_flutter.bat (grafica si prova sul PC).

## Primo messaggio per ogni chat (copia e incolla)
Blocco 0: Base. Collega cartella C:\Users\User\Desktop\applicazione traker claude, leggi flutter\PROGETTO.md, flutter\BLOCCHI.md e flutter\STATO_FLUTTER.md. Prepara .bat per installare Flutter e Build Tools sul PC, crea flutter\app_flutter con i 3 strati, lint rigido, LICENSE chiusa, controlla licenze pacchetti, prova test e build Android nel cloud.
Blocco 1: Logica + test. Collega cartella C:\Users\User\Desktop\applicazione traker claude, leggi flutter\STATO_FLUTTER.md. Scrivi lib/domain con test, partendo dalla logica di python-test-alfa\domain\analisi.py e python-test-alfa\data\catena.py (capire e riscrivere), multi-gestore, combinazioni modelli+skill e confronto, intensità, % stimata tra letture, previsione, budget, frasi "Cosa dicono i dati", import CSV, unione dati per sync.
Blocco 2: Dati + letture Windows. Collega cartella C:\Users\User\Desktop\applicazione traker claude, leggi flutter\STATO_FLUTTER.md. Scrivi lib/data: database, segreti cifrati, lettore Anthropic (Claude Code + cookie), ricevitore locale, nuova estensione browser Chromium, import CSV vero.
Blocco 3: Grafica. Collega cartella C:\Users\User\Desktop\applicazione traker claude, leggi flutter\STATO_FLUTTER.md. Scrivi lib/ui: tema scuro da python-test-alfa\ui\tema.py e python-test-alfa\ui\grafico.py, grafica largo/stretto, grafico, note, manuale, inizio/fine, pannello combinazioni (modelli dx, skill sx), mouse sulla linea, grafico intensità, previsione + budget, riquadro "Cosa dicono i dati", impostazioni, avviso.
Blocco 4: Windows sistema. Collega cartella C:\Users\User\Desktop\applicazione traker claude, leggi flutter\STATO_FLUTTER.md. Tray, avvio con Windows, una sola copia, .bat per compilare l'exe, guidami nella prova dal vivo.
Blocco 5: Android. Collega cartella C:\Users\User\Desktop\applicazione traker claude, leggi flutter\STATO_FLUTTER.md. Login claude.ai in-app, cookie cifrato, lettura in background ~15 min, apk, guidami nella prova sul telefono.
Blocco 6: Sync Wi-Fi. Collega cartella C:\Users\User\Desktop\applicazione traker claude, leggi flutter\STATO_FLUTTER.md. Abbinamento con codice, ricerca in rete, scambio cifrato, unione dati, guidami nella prova PC e telefono.

## Testo istruzioni progetto — VECCHIO, usare flutter\ISTRUZIONI_PROGETTO_FLUTTER.txt
---
TRAKER USO IA (Flutter). Nome app: da decidere (senza "Claude"). Windows + Android prima; dopo Linux/Mac/iOS. Multi-gestore, MVP solo Anthropic. Da pubblicare. Licenza chiusa (Mirko Del Sette). App Python nella cartella = solo riferimento, non toccarla.
Rif: PROGETTO.md, BLOCCHI.md, STATO_FLUTTER.md. Decisioni prese = non richiedere.

STILE: italiano, caveman, cortissimo: risposta -> motivo -> passo dopo. Frasi complete solo per sicurezza, azioni irreversibili, ordine passi, domande. Mai togliere non/mai/solo. Percorsi/comandi veri, passo passo ("doppio clic su..."), meglio .bat. Mai funzioni non chieste: prima chiedere. Onesto su rischi; stime = stime.
CONSIGLIO MODELLO: a ogni compito, prima riga "Consiglio: modello X, concentrazione Y — motivo" + "(li imposti tu a mano)".
FILE TRA CHAT: STATO_FLUTTER densi solo per IA (abbreviazioni, file:riga). File per Mirko e testi app = testo normale. Un autore per file, condivisi solo in aggiunta con firma.

CODICE: Flutter in app_flutter\. 3 strati lib/ui · lib/domain (puro, niente Flutter) · lib/data. Piattaforma e gestore IA dietro interfacce nel domain. Logica nuova = test. Lint rigido. flutter analyze + flutter test ok prima di "fatto" (nel cloud della chat). Solo pacchetti MIT/BSD/Apache. Mai copiare codice di altri: capire logica, controllare licenza, riscrivere. Testi app in file traduzioni.
SICUREZZA: cookie/token claude.ai = segreto. Solo sul dispositivo, cifrato. Mai nella cartella progetto, mai nei log, mai nel sync. Sync = solo percentuali, orari, note, periodi lavoro.

FONTE UNICA: cartella C:\Users\User\Desktop\applicazione traker claude (niente GitHub per ora). Una chat alla volta. Mai sovrascrivere file che un'altra chat aperta sta toccando. Comandi sul PC li lancia Mirko con .bat.
UNA CHAT = UN BLOCCO. Leggi solo STATO_FLUTTER.md + file del blocco. Serve altro blocco → fermati e chiedi.
LIMITE CHAT: max ~25 messaggi o blocco finito. A ~20 messaggi prepara DA SOLO il passaggio (stato salvato + prompt per chat nuova), senza aspettare che Mirko lo chieda. Fine chat: aggiungi a STATO_FLUTTER.md max 15 righe (fatto, file toccati, problemi aperti, prossimo passo).
NUMERO CHAT
- Primo messaggio contiene "Blocco N" → sei CHAT N, fisso.
- Ordine che nomina altro numero → NON eseguire, rispondi: "Sono la chat N. Accetto solo ordini della chat N."
- Ordini senza numero → esegui se del tuo blocco.
- Ordini di altro blocco senza numero → fermati e chiedi.

DATI INIZIALI: importare dati/letture.csv e dati/eventi.csv dell'app Python. Reset sett.: martedì 20:00.
FUORI DA MVP: Google Drive, Codex/altri gestori, al PC/automatico, Firefox/AMO, installer/firma/store, inglese, privacy, esporta CSV, log Claude Code, ritmo tra 2 note, dato debole, candele, copia riepilogo, decisione vendita, Linux/Mac/iOS, repo GitHub/Actions.
SCARTATI (non proporre): cattura schermo, elenco chat claude.ai, IA dentro l'app, abbonamento.
---

## Aggiunte 13/11/2026 (chat coordinamento, decise da Mirko)
Nome app: TraKer IA by mdls. Entrano nell'MVP (vedi PROGETTO.md §12):
- Blocco 1 (logica, con test): ordine sezioni/visibilità/modi vista, riordino tasti, periodi del cursore, testi dei confronti e delle spiegazioni.
- Blocco 3 (grafica): menu Vista + Solo grafico/Solo intensità + Sempre in primo piano (solo Windows), finestra piccola con scorrimento, tasti trascinabili, riquadro mouse mai tagliato, cursore periodo, carta CONFRONTI con spiegazioni, nitidezza con schermo ingrandito.
Riferimento Python (in python-test-alfa\): domain/vista.py, riordino.py, periodo.py, confronti.py, lavoro.py, ui/layout.py, ui/tooltip.py (capire e riscrivere).
Testo istruzioni progetto aggiornato col nome: file ISTRUZIONI_PROGETTO_FLUTTER.txt.
- P8 Python: spunta "Conta solo lavoro" nei confronti + orario reset arrotondato (±2 min a :00) → anche in MVP (Blocco 1 logica, Blocco 3 grafica).

## Aggiunta 13/11/2026 sera (chat coordinamento, decisa da Mirko) — Skill
- MVP (Blocco 3): tasto "Skill" visibile ma DISATTIVATO con scritta "in arrivo". Nient'altro.
- FUORI DA MVP: sezione Skill nell'app. Per ogni skill: nome, a cosa serve, tasto "Copia testo" e "Salva .zip" (da caricare su claude.ai > Impostazioni > Skill). Skill: caveman · risparmio token (progetto multi-chat) · consiglio modello · progetto a blocchi · risparmio GitHub Actions (separata). Testi riscritti puliti: niente nomi, percorsi, % o dati di Mirko. Testi in file traduzioni.
