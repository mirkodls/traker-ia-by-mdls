// TraKer IA by mdls - Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
#include "sistema.h"

#include <shellapi.h>

#include <vector>

namespace sistema {

namespace {

constexpr const wchar_t kNomeLucchetto[] = L"Local\\TraKerIA_mdls_copia_unica";
constexpr const wchar_t kNomeMessaggio[] = L"TraKerIA_mdls_mostra";
constexpr const wchar_t kChiaveRun[] =
    L"Software\\Microsoft\\Windows\\CurrentVersion\\Run";
constexpr const wchar_t kChiaveApprovato[] =
    L"Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\StartupApproved"
    L"\\Run";
constexpr const wchar_t kNomeVoce[] = L"TraKer IA by mdls";

// Il lucchetto resta aperto finche' il programma vive (Windows lo chiude
// da solo all'uscita).
HANDLE g_lucchetto = nullptr;

std::wstring PercorsoExe() {
  std::vector<wchar_t> buf(MAX_PATH);
  for (;;) {
    const DWORD n =
        GetModuleFileNameW(nullptr, buf.data(), static_cast<DWORD>(buf.size()));
    if (n == 0) {
      return L"";
    }
    if (n < buf.size()) {
      return std::wstring(buf.data(), n);
    }
    buf.resize(buf.size() * 2);
  }
}

// Vero se l'utente ha disattivato la voce in Gestione attivita'.
bool DisattivataDaUtente() {
  HKEY chiave = nullptr;
  if (RegOpenKeyExW(HKEY_CURRENT_USER, kChiaveApprovato, 0, KEY_QUERY_VALUE,
                    &chiave) != ERROR_SUCCESS) {
    return false;
  }
  BYTE dati[12] = {};
  DWORD dim = sizeof(dati);
  DWORD tipo = 0;
  const LONG r = RegQueryValueExW(chiave, kNomeVoce, nullptr, &tipo, dati, &dim);
  RegCloseKey(chiave);
  // Primo byte pari = attiva (02), dispari = disattivata (03).
  return r == ERROR_SUCCESS && tipo == REG_BINARY && dim > 0 &&
         (dati[0] & 1) != 0;
}

void TogliDisattivazione() {
  HKEY chiave = nullptr;
  if (RegOpenKeyExW(HKEY_CURRENT_USER, kChiaveApprovato, 0, KEY_SET_VALUE,
                    &chiave) == ERROR_SUCCESS) {
    RegDeleteValueW(chiave, kNomeVoce);
    RegCloseKey(chiave);
  }
}

}  // namespace

bool AvvioNascosto() {
  int n = 0;
  LPWSTR* argv = CommandLineToArgvW(GetCommandLineW(), &n);
  if (argv == nullptr) {
    return false;
  }
  bool trovato = false;
  for (int i = 1; i < n; i++) {
    if (lstrcmpiW(argv[i], kArgNascosto) == 0) {
      trovato = true;
    }
  }
  LocalFree(argv);
  return trovato;
}

UINT MessaggioMostra() {
  static const UINT messaggio = RegisterWindowMessageW(kNomeMessaggio);
  return messaggio;
}

bool PrendiCopiaUnica() {
  g_lucchetto = CreateMutexW(nullptr, TRUE, kNomeLucchetto);
  if (g_lucchetto != nullptr && GetLastError() != ERROR_ALREADY_EXISTS) {
    return true;
  }
  // Un'altra copia e' aperta: le permetto di venire davanti e la sveglio.
  AllowSetForegroundWindow(ASFW_ANY);
  PostMessageW(HWND_BROADCAST, MessaggioMostra(), 0, 0);
  return false;
}

bool AvvioWindowsAttivo() {
  HKEY chiave = nullptr;
  if (RegOpenKeyExW(HKEY_CURRENT_USER, kChiaveRun, 0, KEY_QUERY_VALUE,
                    &chiave) != ERROR_SUCCESS) {
    return false;
  }
  const LONG r =
      RegQueryValueExW(chiave, kNomeVoce, nullptr, nullptr, nullptr, nullptr);
  RegCloseKey(chiave);
  return r == ERROR_SUCCESS && !DisattivataDaUtente();
}

bool ImpostaAvvioWindows(bool acceso) {
  HKEY chiave = nullptr;
  if (RegCreateKeyExW(HKEY_CURRENT_USER, kChiaveRun, 0, nullptr, 0,
                      KEY_SET_VALUE, nullptr, &chiave,
                      nullptr) != ERROR_SUCCESS) {
    return false;
  }
  LONG r = ERROR_SUCCESS;
  if (acceso) {
    const std::wstring exe = PercorsoExe();
    if (exe.empty()) {
      RegCloseKey(chiave);
      return false;
    }
    const std::wstring comando =
        L"\"" + exe + L"\" " + std::wstring(kArgNascosto);
    r = RegSetValueExW(
        chiave, kNomeVoce, 0, REG_SZ,
        reinterpret_cast<const BYTE*>(comando.c_str()),
        static_cast<DWORD>((comando.size() + 1) * sizeof(wchar_t)));
    if (r == ERROR_SUCCESS) {
      TogliDisattivazione();
    }
  } else {
    r = RegDeleteValueW(chiave, kNomeVoce);
    if (r == ERROR_FILE_NOT_FOUND) {
      r = ERROR_SUCCESS;
    }
  }
  RegCloseKey(chiave);
  return r == ERROR_SUCCESS;
}

std::wstring DaUtf8(const std::string& testo) {
  if (testo.empty()) {
    return L"";
  }
  const int n = MultiByteToWideChar(CP_UTF8, 0, testo.data(),
                                    static_cast<int>(testo.size()), nullptr, 0);
  if (n <= 0) {
    return L"";
  }
  std::wstring out(static_cast<size_t>(n), L'\0');
  MultiByteToWideChar(CP_UTF8, 0, testo.data(), static_cast<int>(testo.size()),
                      out.data(), n);
  return out;
}

}  // namespace sistema
