# TraKer IA by mdls

App che legge da sola quanto hai usato il tuo abbonamento Claude (barra delle 5 ore e barra settimanale, in %), salva lo storico **solo sul tuo dispositivo**, disegna la curva e ti dice se dopo una tua nota il consumo è **sceso, salito o costante**.

Funziona su **Windows** e **Android**. Versione per iPhone: in preparazione.

## Scarica

| Per | Link diretto | Dimensione |
|---|---|---|
| Android (telefono) | [**TraKerIA.apk**](https://github.com/mirkodls/traker-ia-by-mdls/releases/latest/download/TraKerIA.apk) | ~20 MB |
| Windows (PC) | [**TraKerIA-Windows.zip**](https://github.com/mirkodls/traker-ia-by-mdls/releases/latest/download/TraKerIA-Windows.zip) | ~13 MB |

Tutte le versioni: [pagina Release](https://github.com/mirkodls/traker-ia-by-mdls/releases).

## Installazione su Android

1. Dal telefono apri il link **TraKerIA.apk** qui sopra e scarica il file.
2. Apri il file scaricato (notifica o app "File" → Download).
3. Se Android dice "installazione bloccata": tocca **Impostazioni** e attiva **Consenti da questa fonte**. Poi torna indietro e tocca **Installa**.
4. Apri **TraKer IA**. Al primo avvio fai il login a claude.ai dentro l'app: serve per leggere le tue percentuali.
5. Per non perdere letture: Impostazioni Android → Batteria → TraKer IA → **Senza restrizioni**.

La lettura in background avviene circa ogni 15 minuti (è il minimo che Android permette).

## Installazione su Windows

1. Scarica **TraKerIA-Windows.zip**.
2. Tasto destro sul file → **Estrai tutto…** → scegli una cartella tua (esempio `C:\TraKerIA`). Non usare la cartella Download se la pulisci spesso.
3. Apri la cartella `TraKerIA` e fai doppio clic su **traker_ia.exe**.
4. Se Windows mostra "Windows ha protetto il PC": clic su **Ulteriori informazioni** → **Esegui comunque**. Succede perché il programma non ha ancora una firma a pagamento di Microsoft. Il codice è tutto qui nel repository.
5. Per leggere le percentuali l'app usa l'estensione browser (Edge, Chrome, Brave, Opera): la guida è dentro l'app, in Impostazioni.

## Sincronizzare PC e telefono

Con PC e telefono sulla stessa rete Wi-Fi, apri Impostazioni → Sincronizzazione sull'app e abbina i due dispositivi con il codice. I dati passano cifrati, solo in casa tua: nessun server mio.

## Privacy e sicurezza

- I tuoi dati restano sul tuo dispositivo. Nessun server, nessuna raccolta.
- Il cookie di claude.ai è salvato cifrato e **mai** inviato altrove.
- Il progetto non contiene chiavi, password o dati personali.

## Aggiornare

Scarica di nuovo il file dalla stessa pagina e installalo sopra: i dati restano. Su Windows chiudi prima l'app (icona accanto all'orologio → Esci).

## Problemi

Apri una segnalazione: [Issues](https://github.com/mirkodls/traker-ia-by-mdls/issues).

## Per chi sviluppa

Codice Flutter in `flutter/app_flutter` (3 strati: `ui/`, `domain/`, `data/`). Prova con `flutter analyze` e `flutter test`. `python-test-alfa/` è la vecchia versione Python, solo riferimento.

## Licenza

Tutti i diritti riservati, © 2026 Mirko Del Sette. Il codice è visibile ma non si può copiare, modificare o ridistribuire senza permesso scritto. Vedi [LICENSE](LICENSE).

TraKer IA non è un prodotto di Anthropic e non è affiliato ad Anthropic. "Claude" è un marchio di Anthropic.
