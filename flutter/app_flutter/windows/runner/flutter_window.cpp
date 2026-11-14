#include "flutter_window.h"

#include <windowsx.h>

#include <optional>

#include <flutter/standard_method_codec.h>

#include "flutter/generated_plugin_registrant.h"
#include "resource.h"
#include "sistema.h"

namespace {

// Messaggio dell'icona tray verso la finestra.
constexpr UINT kMessaggioTray = WM_APP + 1;
// Timer: da nascosta ridà memoria a Windows ogni 10 minuti.
constexpr UINT_PTR kTimerMemoria = 7;
constexpr UINT kOgniDieciMinuti = 10 * 60 * 1000;

// Ridà a Windows la memoria non usata adesso (RAM del Task Manager giù).
// Torna da sola quando serve: nessun dato perso.
void LiberaMemoria() {
  SetProcessWorkingSetSize(GetCurrentProcess(), static_cast<SIZE_T>(-1),
                           static_cast<SIZE_T>(-1));
}
constexpr UINT kIdTray = 1;
constexpr UINT kVoceMostra = 1;
constexpr UINT kVoceEsci = 2;

// Legge una stringa da una mappa del canale ("" se manca).
std::string Testo(const flutter::EncodableMap& m, const char* chiave) {
  auto it = m.find(flutter::EncodableValue(std::string(chiave)));
  if (it == m.end()) {
    return "";
  }
  const std::string* s = std::get_if<std::string>(&it->second);
  return s == nullptr ? "" : *s;
}

}  // namespace

FlutterWindow::FlutterWindow(const flutter::DartProject& project,
                             bool nascosta)
    : project_(project), nascosta_all_avvio_(nascosta) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());

  // TraKer IA by mdls: canale nostro (niente pacchetti).
  canale_finestra_ =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          flutter_controller_->engine()->messenger(), "traker_ia/finestra",
          &flutter::StandardMethodCodec::GetInstance());
  canale_finestra_->SetMethodCallHandler(
      [this](const flutter::MethodCall<flutter::EncodableValue>& call,
             std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>
                 result) { GestisciCanale(call, std::move(result)); });
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  // Se Explorer si riavvia, l'icona tray va rimessa.
  messaggio_barra_creata_ = RegisterWindowMessageW(L"TaskbarCreated");
  AggiungiTray();

  if (!nascosta_all_avvio_) {
    flutter_controller_->engine()->SetNextFrameCallback([&]() {
      this->Show();
    });
  }

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy() {
  TogliTray();
  canale_finestra_ = nullptr;
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

void FlutterWindow::GestisciCanale(
    const flutter::MethodCall<flutter::EncodableValue>& call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  const std::string& metodo = call.method_name();
  if (metodo == "primoPiano") {
    const bool* acceso = std::get_if<bool>(call.arguments());
    if (acceso == nullptr) {
      result->Error("argomento", "serve vero/falso");
      return;
    }
    SetWindowPos(GetHandle(), *acceso ? HWND_TOPMOST : HWND_NOTOPMOST, 0, 0, 0,
                 0, SWP_NOMOVE | SWP_NOSIZE | SWP_NOACTIVATE);
    result->Success();
  } else if (metodo == "tray") {
    const auto* m = std::get_if<flutter::EncodableMap>(call.arguments());
    if (m == nullptr) {
      result->Error("argomento", "serve una mappa");
      return;
    }
    const std::wstring testo = sistema::DaUtf8(Testo(*m, "testo"));
    const std::wstring mostra = sistema::DaUtf8(Testo(*m, "mostra"));
    const std::wstring nascondi = sistema::DaUtf8(Testo(*m, "nascondi"));
    const std::wstring esci = sistema::DaUtf8(Testo(*m, "esci"));
    if (!testo.empty()) {
      testo_tray_ = testo;
    }
    if (!mostra.empty()) {
      etichetta_mostra_ = mostra;
    }
    if (!nascondi.empty()) {
      etichetta_nascondi_ = nascondi;
    }
    if (!esci.empty()) {
      etichetta_esci_ = esci;
    }
    AggiornaTestoTray();
    result->Success();
  } else if (metodo == "avvioWindows") {
    result->Success(flutter::EncodableValue(sistema::AvvioWindowsAttivo()));
  } else if (metodo == "impostaAvvioWindows") {
    const bool* acceso = std::get_if<bool>(call.arguments());
    if (acceso == nullptr) {
      result->Error("argomento", "serve vero/falso");
      return;
    }
    result->Success(
        flutter::EncodableValue(sistema::ImpostaAvvioWindows(*acceso)));
  } else {
    result->NotImplemented();
  }
}

// ------------------------------------------------------------------ tray

void FlutterWindow::AggiungiTray() {
  if (icona_tray_ == nullptr) {
    icona_tray_ = static_cast<HICON>(LoadImageW(
        GetModuleHandle(nullptr), MAKEINTRESOURCEW(IDI_APP_ICON), IMAGE_ICON,
        GetSystemMetrics(SM_CXSMICON), GetSystemMetrics(SM_CYSMICON), 0));
  }
  tray_ = NOTIFYICONDATAW{};
  tray_.cbSize = sizeof(tray_);
  tray_.hWnd = GetHandle();
  tray_.uID = kIdTray;
  tray_.uFlags = NIF_ICON | NIF_MESSAGE | NIF_TIP | NIF_SHOWTIP;
  tray_.uCallbackMessage = kMessaggioTray;
  tray_.hIcon = icona_tray_;
  wcsncpy_s(tray_.szTip, testo_tray_.c_str(), _TRUNCATE);
  tray_presente_ = Shell_NotifyIconW(NIM_ADD, &tray_) != FALSE;
  if (tray_presente_) {
    tray_.uVersion = NOTIFYICON_VERSION_4;
    Shell_NotifyIconW(NIM_SETVERSION, &tray_);
  }
}

void FlutterWindow::TogliTray() {
  if (tray_presente_) {
    Shell_NotifyIconW(NIM_DELETE, &tray_);
    tray_presente_ = false;
  }
  if (icona_tray_ != nullptr) {
    DestroyIcon(icona_tray_);
    icona_tray_ = nullptr;
  }
}

void FlutterWindow::AggiornaTestoTray() {
  if (!tray_presente_) {
    return;
  }
  tray_.uFlags = NIF_TIP | NIF_SHOWTIP;
  wcsncpy_s(tray_.szTip, testo_tray_.c_str(), _TRUNCATE);
  Shell_NotifyIconW(NIM_MODIFY, &tray_);
}

void FlutterWindow::MenuTray(int x, int y) {
  HMENU menu = CreatePopupMenu();
  if (menu == nullptr) {
    return;
  }
  const bool visibile = IsWindowVisible(GetHandle()) != FALSE;
  AppendMenuW(menu, MF_STRING, kVoceMostra,
              (visibile ? etichetta_nascondi_ : etichetta_mostra_).c_str());
  AppendMenuW(menu, MF_SEPARATOR, 0, nullptr);
  AppendMenuW(menu, MF_STRING, kVoceEsci, etichetta_esci_.c_str());
  SetMenuDefaultItem(menu, kVoceMostra, FALSE);
  // Senza questo il menu non si chiude cliccando fuori.
  SetForegroundWindow(GetHandle());
  const UINT voce = static_cast<UINT>(
      TrackPopupMenu(menu, TPM_RETURNCMD | TPM_RIGHTBUTTON | TPM_NONOTIFY, x,
                     y, 0, GetHandle(), nullptr));
  PostMessageW(GetHandle(), WM_NULL, 0, 0);
  DestroyMenu(menu);
  if (voce == kVoceMostra) {
    if (visibile) {
      Nascondi();
    } else {
      Mostra();
    }
  } else if (voce == kVoceEsci) {
    Esci();
  }
}

// --------------------------------------------------------------- finestra

void FlutterWindow::Mostra() {
  HWND h = GetHandle();
  KillTimer(h, kTimerMemoria);
  if (IsIconic(h)) {
    ShowWindow(h, SW_RESTORE);
  } else {
    ShowWindow(h, SW_SHOW);
  }
  SetForegroundWindow(h);
}

void FlutterWindow::Nascondi() {
  HWND h = GetHandle();
  ShowWindow(h, SW_HIDE);
  LiberaMemoria();
  SetTimer(h, kTimerMemoria, kOgniDieciMinuti, nullptr);
}

void FlutterWindow::Esci() {
  in_uscita_ = true;
  PostMessageW(GetHandle(), WM_CLOSE, 0, 0);
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  if (message == sistema::MessaggioMostra()) {
    // Una seconda copia chiede di mostrare questa.
    Mostra();
    return 0;
  }
  if (messaggio_barra_creata_ != 0 && message == messaggio_barra_creata_) {
    tray_presente_ = false;
    AggiungiTray();
    return 0;
  }

  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
    case WM_TIMER:
      if (wparam == kTimerMemoria) {
        if (!IsWindowVisible(hwnd)) {
          LiberaMemoria();
        }
        return 0;
      }
      break;
    case WM_SIZE:
      // Ridotta a icona: stessa pulizia, poi Windows gestisce il resto.
      if (wparam == SIZE_MINIMIZED) {
        LiberaMemoria();
      }
      break;
    case WM_CLOSE:
      // X = nascondi: l'app resta accesa nel tray. Esci vero dal menu.
      if (!in_uscita_ && tray_presente_) {
        Nascondi();
        return 0;
      }
      break;
    case kMessaggioTray:
      switch (LOWORD(lparam)) {
        case NIN_SELECT:
        case NIN_KEYSELECT:
          if (IsWindowVisible(hwnd)) {
            Nascondi();
          } else {
            Mostra();
          }
          return 0;
        case WM_CONTEXTMENU:
          MenuTray(GET_X_LPARAM(wparam), GET_Y_LPARAM(wparam));
          return 0;
      }
      return 0;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
