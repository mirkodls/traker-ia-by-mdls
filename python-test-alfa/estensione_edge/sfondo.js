// Legge l'uso da claude.ai coi cookie di Edge e lo manda al traker (127.0.0.1:45781).
const TRAKER = "http://127.0.0.1:45781/lettura";
const CLAUDE = "https://claude.ai/api/organizations";
function programma(minuti = 10) {
  chrome.alarms.create("leggi", { delayInMinutes: 0.2, periodInMinutes: minuti });
}
chrome.runtime.onInstalled.addListener(() => programma());
chrome.runtime.onStartup.addListener(() => programma());
console.log("[traker] estensione avviata");
chrome.alarms.onAlarm.addListener((a) => { if (a.name === "leggi") leggi(); });

async function prendi(url) {
  const r = await fetch(url, { credentials: "include", headers: { Accept: "application/json" } });
  if (!r.ok) throw new Error(r.status === 401 || r.status === 403
    ? "non sei loggato su claude.ai in Edge (" + r.status + ")" : "errore HTTP " + r.status);
  return r.json();
}

async function leggi() {
  let msg;
  try {
    const orgs = await prendi(CLAUDE);
    const org = orgs.find((o) => (o.capabilities || []).includes("chat")) || orgs[0];
    if (!org) throw new Error("nessuna organizzazione");
    msg = { uso: await prendi(CLAUDE + "/" + encodeURIComponent(org.uuid) + "/usage") };
  } catch (e) {
    msg = { errore: String((e && e.message) || e) };
  }
  console.log("[traker] letto da claude.ai:", msg);
  try {
    const r = await fetch(TRAKER, { method: "POST", headers: { "Content-Type": "application/json" },
                                    body: JSON.stringify(msg) });
    const risp = await r.json();
    const a = await chrome.alarms.get("leggi");
    if (risp.minuti && (!a || a.periodInMinutes !== risp.minuti)) programma(risp.minuti);
    console.log("[traker] inviato al traker OK");
  } catch (e) {
    console.log("[traker] traker non raggiungibile:", String((e && e.message) || e));
  }
}
