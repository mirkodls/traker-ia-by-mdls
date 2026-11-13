# PROGETTO — Traker uso IA (nome app: da decidere)

Scritto: 12/11/2026, chat di progettazione. Approvato da Mirko: da confermare.

## 1. Obiettivo
App che legge da sola, ogni X minuti, quanto hai usato il tuo abbonamento IA
(barra 5 ore e barra settimanale, in %), salva lo storico sul tuo dispositivo,
disegna la curva e ti dice se dopo una tua nota il consumo è SCESO, SALITO o COSTANTE.
Da pubblicare. Riscrittura in Flutter dell'app Python che c'è già in questa cartella
(funziona, resta come riferimento: non si tocca più).

## 2. Decisioni prese
- Tecnologia: Flutter (Dart). Codice unico per tutte le piattaforme (~80%).
- Piattaforme: prima Windows + Android. Dopo: Linux, Mac, iOS.
- Gestori IA: logica pronta per più gestori. Nell'MVP legge SOLO Anthropic (Claude).
  Dopo: OpenAI Codex/ChatGPT (stesse 2 barre), poi forse altri.
- Licenza: chiusa, tutti i diritti riservati (Mirko Del Sette).
- Nome app: da decidere. Consiglio: senza la parola "Claude" (marchio Anthropic).
- Cartella PC: C:\Users\User\Desktop\applicazione traker claude
  python-test-alfa\ = app Python (riferimento) · flutter\ = documenti + app Flutter in flutter\app_flutter\
- Repo GitHub: mirkodls/traker-ia-by-mdls (privato, poi pubblico). Stesse 2 sezioni. MAI dati personali.
- Niente server di Mirko: ognuno tiene i SUOI dati sul SUO dispositivo.
- Lingua testi: italiano subito; inglese prima della pubblicazione (struttura pronta da subito).

## 3. Funzioni (tutte, anche dopo l'MVP)
Lettura
- Windows: estensione browser (Edge/Chrome/Brave/Opera, un solo pacchetto) che legge
  da claude.ai e manda all'app; riserva 1: token di Claude Code se installato;
  riserva 2: cookie incollato a mano. Primo che funziona vince.
- Android: login a claude.ai DENTRO l'app (finestra web), poi lettura in background
  ogni ~15 minuti (minimo permesso da Android).
- Lettura manuale (tasto) e inserimento a mano di una lettura.
- Avviso a schermo se falliscono 2 giri di lettura di fila (una volta, fino al prossimo OK).
Dati e analisi
- Storico locale (database sul dispositivo).
- Import dei vecchi letture.csv ed eventi.csv dell'app Python.
- Reset settimanale e 5 ore riconosciuti da soli (calo della %), segnati sul grafico.
- Note/marcatori: verdetto SCESO / SALITO / COSTANTE (soglia ±10%) sul ritmo pt%/ora
  prima e dopo la nota.
- Inizio lavoro / Fine lavoro: periodi colorati sul grafico.
- Pannello combinazioni:
  - DESTRA: icone modello (Opus, Sonnet, Fable…), accendi/spegni, anche più insieme.
  - SINISTRA: tasti skill col nome scritto a mano (es. "caveman", "skill risparmio v2").
  - Tutti si aggiungono, rinominano, tolgono a mano (modelli nuovi, nomi propri).
  - Ogni lettura salva modelli + skill accesi = "combinazione".
  - Confronto tra 2 combinazioni (es. Opus+caveman vs Opus senza; Opus+4 skill vs
    Opus+1 skill): ore raccolte, pt/ora, verdetto SCESO/SALITO/COSTANTE.
  - Periodi con più chat diverse insieme = "misto". "Dato debole" sotto ~1-2 ore.
  - Classifica consumo per modello. Stesso meccanismo di Inizio/Fine lavoro.
- Mouse sulla linea (dito su Android): linea verticale + riquadro con ora, % settimanale,
  % 5 ore, modelli e skill accesi. Tra due letture % stimata con "~".
- Riga intensità: grafico piccolo sotto il principale, stessa linea del tempo,
  ritmo pt%/ora sulla barra 5 ore, media mobile ~30 min, reset esclusi. Mostra i picchi.
- Previsione fine piano: "a questo ritmo finisci il giorno X alle Y, reset il giorno Z".
- Budget del giorno: "oggi puoi usare ancora X punti per arrivare al reset".
- Riquadro "Cosa dicono i dati": frasi fisse riempite coi numeri (niente IA, offline).
- Dato debole: se un periodo ha +1 punto o meno, scrive "poco dato, aspetta".
- Ritmo tra due note: tocchi due note, vedi pt/ora nel mezzo.
- Grafico a candele: una candela per ora/giorno sul ritmo (apre, chiude, max, min).
- Log di Claude Code (PC): modello e token esatti per messaggio, solo per chi lo usa.
- Tasto "Copia riepilogo per Claude": testo coi numeri da incollare in una chat.
- "Al PC" o "in automatico" (solo desktop): consumo diviso tra i due.
- Intervallo letture: Windows libero; Android minimo ~15 min. Sotto 5 min l'app avvisa
  (più rischio blocco Cloudflare, nessuna precisione in più: la % è a numeri interi).
Grafica
- Una sola grafica che si adatta: schermo largo = riquadri affiancati, stretto = impilati.
- Stile: tema scuro dell'app Python attuale (colori di ui/tema.py e ui/grafico.py).
Sistema
- Windows: icona vicino all'orologio (tray), avvio con Windows, una sola copia aperta.
Sync (tra dispositivi della STESSA persona)
- Wi-Fi locale: PC e telefono sulla stessa rete si passano i dati. Abbinamento con
  codice. Niente account.
- Google Drive personale: dati nella cartella nascosta dell'app nel TUO Drive.
- I dati si sommano: se il sync arriva tardi, il grafico si completa da solo.

## 4. Sicurezza
- Cookie e token di claude.ai = segreti. Solo sul dispositivo, cifrati.
  Mai sincronizzati, mai nei log, mai nella cartella del progetto.
- Il sync passa solo: percentuali, orari, note, periodi di lavoro.
- Sync Wi-Fi: dati cifrati con la chiave nata dall'abbinamento.

## 5. Tecnologie (pacchetti proposti, licenza da ricontrollare nel Blocco 0)
- Grafico: fl_chart · Database: drift (SQLite) · Segreti: flutter_secure_storage
- Android background: workmanager · Finestra web: flutter_inappwebview
- Tray: tray_manager · Avvio con Windows: launch_at_startup
- Sync Wi-Fi: ricerca dispositivi in rete (mDNS) + collegamento HTTP locale cifrato
- Google Drive (dopo MVP): login Google + Drive cartella app
- Regola: si usano solo pacchetti con licenza MIT/BSD/Apache; nell'app pagina "Licenze".

## 6. Architettura anti-bug
- 3 strati: lib/ui (grafica) · lib/domain (logica pura, niente Flutter) · lib/data
  (database, letture, sync, cose di sistema).
- Le cose diverse per piattaforma stanno dietro un'interfaccia nel domain;
  le versioni Windows/Android stanno in data.
- Gestore IA = interfaccia: "dammi barra breve e barra lunga con % e ora di reset".
  Anthropic è il primo; Codex si aggiunge senza toccare la logica.
- Ogni logica nuova = test automatici. Lint rigido. Test verdi prima di dire "fatto".
- Codice di altri progetti: solo capire la logica e la licenza, poi riscrivere.

## 7. Come si compila (stime, da verificare nel Blocco 0)
- Test e controlli: nel cloud della chat (copia dei file, flutter test, ricopia).
- Windows (.exe): sul PC di Mirko. Serve Flutter + Visual Studio Build Tools
  (parte C++), circa 10 GB su disco, una volta sola. Le chat preparano un .bat.
- Android (.apk): proviamo nel cloud della chat. Rischio: il download dell'SDK Android
  può essere bloccato. Riserva: Android Studio sul PC di Mirko.
- Le chat non hanno un terminale sul PC: i comandi sul PC li lancia Mirko con .bat.

## 8. Rischi (onesti)
- Anthropic legge l'uso da indirizzi NON ufficiali: possono cambiare o bloccarsi.
- Cloudflare di claude.ai può bloccare letture fatte fuori dal browser.
- Android: il background ogni 15 minuti non è garantito (risparmio batteria).
- Repo diventerà pubblico: un errore nel .gitignore pubblica dati personali. Controllo a mano prima di ogni push.
- Pubblicazione: Google Play chiede account sviluppatore (~25$ una volta) e,
  per account nuovi personali, un test chiuso con più tester per giorni (da verificare).
  Windows senza firma digitale: avviso SmartScreen all'installazione.

## 9. Scartati (non si fanno)
- Cattura schermo (privacy).
- Lettura elenco chat di claude.ai dall'estensione (non ufficiale, niente token, privacy).
- IA dentro l'app che chiama un gestore da sola (chiave a pagamento, privacy, lavoro).
- Abbonamento mensile (senza server non si giustifica).

## 10. Vendita (si decide dopo l'MVP)
- Prima: Mirko la usa, poi 2-3 persone la provano.
- Se si vende: tramite store (Google Play, Microsoft Store) → aggiornamenti e pagamenti
  li gestisce lo store (trattiene ~15%, stima). Niente codici licenza fatti in casa.
- Modello più adatto se si vende: base gratis + Pro una tantum (~5 €, stima).
- Rischio: gli indirizzi non ufficiali possono cambiare e l'app smette di leggere
  finché non esce un aggiornamento. Chi ha pagato si lamenta.

## 11. Fasi
1. MVP Windows + Android (Blocchi 0-6) → Mirko lo usa e lo prova.
2. Dopo MVP: lista FUORI DA MVP in BLOCCHI.md, una cosa per volta.
3. Poi: Linux, Mac, iOS.

## 12. Aggiunte 13/11/2026 (chat coordinamento, decise da Mirko)
- Nome app: TraKer IA by mdls.
- Entrano nell'MVP le idee nate usando l'app Python (giro 2, P4-P7):
  - Sezioni nascondibili (menu Vista), modo "Solo grafico" / "Solo intensità", "Sempre in primo piano".
  - Grafica che si adatta anche a finestra piccola, con barra di scorrimento se non entra.
  - Tasti modelli e skill trascinabili per cambiare l'ordine (clic = accendi/spegni).
  - Riquadro del mouse mai tagliato (esce dal grafico se serve).
  - Cursore periodo: 2h, 6h, 12h, 24h, 3 giorni, Settimana, 7 giorni, Tutto.
  - Carta CONFRONTI unica e compatta, con spiegazione su ogni numero (mouse sopra / dito tenuto premuto) e "Come leggere".
  - Linee nitide anche con schermo ingrandito (125%, 150%).
- Leggerezza: l'app deve essere leggera e fluida (regole in STATO_FLUTTER.md).

## 13. Skill (aggiunta 13/11/2026 sera, chat coordinamento, decisa da Mirko)
- Nella prima versione: tasto "Skill" disattivato con scritta "in arrivo".
- Dopo l'MVP: sezione Skill con 5 skill da copiare (caveman, risparmio token, consiglio modello, progetto a blocchi, risparmio GitHub Actions). Tasti "Copia testo" e "Salva .zip". Testi puliti, senza dati personali.
