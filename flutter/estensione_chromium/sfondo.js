// TraKer IA by mdls — Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
//
// Estensione (Edge, Chrome, Brave, Opera): legge l'uso da claude.ai con il
// login del browser e lo manda all'app sul PC (solo 127.0.0.1, porta 45782).
// Non salva niente, non legge cookie, non scrive dati nella console.
'use strict';

const APP = 'http://127.0.0.1:45782/lettura';
const ORGS = 'https://claude.ai/api/organizations';
const ALLARME = 'traker-ia-leggi';
const MINUTI_BASE = 10;

function pianifica(minuti) {
  const m = Math.min(Math.max(Math.round(Number(minuti)) || MINUTI_BASE, 1), 120);
  chrome.alarms.create(ALLARME, { delayInMinutes: 0.1, periodInMinutes: m });
}

chrome.runtime.onInstalled.addListener(() => pianifica(MINUTI_BASE));
chrome.runtime.onStartup.addListener(() => pianifica(MINUTI_BASE));
chrome.alarms.onAlarm.addListener((a) => {
  if (a.name === ALLARME) giro();
});

async function prendiJson(url) {
  const r = await fetch(url, {
    credentials: 'include',
    cache: 'no-store',
    headers: { Accept: 'application/json' },
  });
  if (r.status === 401 || r.status === 403) {
    throw new Error('non sei collegato a claude.ai in questo browser (' + r.status + ')');
  }
  if (!r.ok) throw new Error('errore HTTP ' + r.status);
  return r.json();
}

async function leggiUso() {
  const orgs = await prendiJson(ORGS);
  if (!Array.isArray(orgs) || orgs.length === 0) throw new Error('nessuna organizzazione');
  const conChat = orgs.find((o) => Array.isArray(o.capabilities) && o.capabilities.includes('chat'));
  const org = conChat || orgs[0];
  return prendiJson(ORGS + '/' + encodeURIComponent(org.uuid) + '/usage');
}

async function giro() {
  let msg;
  try {
    msg = { uso: await leggiUso() };
  } catch (e) {
    msg = { errore: String((e && e.message) || e).slice(0, 200) };
  }
  try {
    const r = await fetch(APP, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(msg),
    });
    if (!r.ok) return;
    const risp = await r.json();
    const a = await chrome.alarms.get(ALLARME);
    if (risp && risp.minuti && (!a || a.periodInMinutes !== risp.minuti)) pianifica(risp.minuti);
  } catch (_) {
    // App chiusa: riprova al prossimo giro.
  }
}
