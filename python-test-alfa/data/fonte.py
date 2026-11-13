"""Lettura dati di utilizzo da Anthropic. 2 metodi:
1) token di Claude Code (%USERPROFILE%\\.claude\\.credentials.json) -> api.anthropic.com/api/oauth/usage
2) cookie sessionKey di claude.ai -> claude.ai/api/organizations/{id}/usage
Codice scritto da zero; metodo osservato in progetti MIT (claude-meter, Claude-Usage-Tracker).
"""
from __future__ import annotations

import json
import os
import urllib.error
import urllib.request

URL_OAUTH = "https://api.anthropic.com/api/oauth/usage"
URL_ORG = "https://claude.ai/api/organizations"
UA_BROWSER = ("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
              "(KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36")


class ErroreFonte(Exception):
    pass


def file_claude_code() -> str:
    return os.path.join(os.path.expanduser("~"), ".claude", ".credentials.json")


def token_claude_code():
    try:
        with open(file_claude_code(), encoding="utf-8") as f:
            d = json.load(f)
    except (OSError, ValueError):
        return None
    return (d.get("claudeAiOauth") or {}).get("accessToken")


def _get(url, headers, timeout=15):
    req = urllib.request.Request(url, headers=headers)
    try:
        with urllib.request.urlopen(req, timeout=timeout) as r:
            return json.loads(r.read().decode("utf-8"))
    except urllib.error.HTTPError as e:
        if e.code in (401, 403):
            raise ErroreFonte(f"accesso negato ({e.code}): login scaduto o bloccato")
        if e.code == 429:
            raise ErroreFonte("troppe richieste (429): aumenta i minuti")
        raise ErroreFonte(f"errore HTTP {e.code}")
    except (urllib.error.URLError, TimeoutError, OSError) as e:
        raise ErroreFonte(f"rete: {e}")
    except ValueError:
        raise ErroreFonte("risposta non valida")


def leggi_claude_code(token: str) -> dict:
    return _get(URL_OAUTH, {
        "Authorization": f"Bearer {token}",
        "anthropic-beta": "oauth-2025-04-20",
        "anthropic-version": "2023-06-01",
        "Accept": "application/json",
        "User-Agent": "claude-traker-mirko/1.0",
    })


def _header_cookie(cookie: str) -> dict:
    c = cookie.strip()
    if "=" not in c:
        c = f"sessionKey={c}"
    return {"Cookie": c, "Accept": "application/json", "User-Agent": UA_BROWSER,
            "Referer": "https://claude.ai/settings/usage"}


def trova_org(cookie: str) -> str:
    lista = _get(URL_ORG, _header_cookie(cookie))
    if not isinstance(lista, list) or not lista:
        raise ErroreFonte("nessuna organizzazione trovata")
    for o in lista:  # preferisci quella con chat (abbonamento claude.ai)
        if "chat" in (o.get("capabilities") or []):
            return o["uuid"]
    return lista[0]["uuid"]


def leggi_cookie(cookie: str, org_id: str) -> dict:
    return _get(f"{URL_ORG}/{org_id}/usage", _header_cookie(cookie))
