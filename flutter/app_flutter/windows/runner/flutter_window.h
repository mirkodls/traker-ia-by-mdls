#ifndef RUNNER_FLUTTER_WINDOW_H_
#define RUNNER_FLUTTER_WINDOW_H_

#include <flutter/dart_project.h>
#include <flutter/encodable_value.h>
#include <flutter/flutter_view_controller.h>
#include <flutter/method_channel.h>
#include <shellapi.h>

#include <memory>
#include <string>

#include "win32_window.h"

// A window that does nothing but host a Flutter view.
// TraKer IA by mdls: + icona tray, X = nascondi, avvio con Windows.
class FlutterWindow : public Win32Window {
 public:
  // Creates a new FlutterWindow hosting a Flutter view running |project|.
  // |nascosta| = non mostrare la finestra all'avvio (solo icona tray).
  FlutterWindow(const flutter::DartProject& project, bool nascosta);
  virtual ~FlutterWindow();

 protected:
  // Win32Window:
  bool OnCreate() override;
  void OnDestroy() override;
  LRESULT MessageHandler(HWND window, UINT const message, WPARAM const wparam,
                         LPARAM const lparam) noexcept override;

 private:
  // Canale "traker_ia/finestra": primo piano, tray, avvio con Windows.
  void GestisciCanale(
      const flutter::MethodCall<flutter::EncodableValue>& call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  // Icona tray.
  void AggiungiTray();
  void TogliTray();
  void AggiornaTestoTray();
  void MenuTray(int x, int y);

  // Finestra.
  void Mostra();
  void Nascondi();
  void Esci();

  // The project to run.
  flutter::DartProject project_;

  // The Flutter instance hosted by this window.
  std::unique_ptr<flutter::FlutterViewController> flutter_controller_;

  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>>
      canale_finestra_;

  bool nascosta_all_avvio_;
  bool in_uscita_ = false;
  bool tray_presente_ = false;
  NOTIFYICONDATAW tray_{};
  HICON icona_tray_ = nullptr;
  UINT messaggio_barra_creata_ = 0;
  std::wstring testo_tray_ = L"TraKer IA by mdls";
  std::wstring etichetta_mostra_ = L"Mostra";
  std::wstring etichetta_nascondi_ = L"Nascondi";
  std::wstring etichetta_esci_ = L"Esci";
};

#endif  // RUNNER_FLUTTER_WINDOW_H_
