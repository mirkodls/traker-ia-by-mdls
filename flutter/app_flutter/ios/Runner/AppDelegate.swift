// TraKer IA by mdls - Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
//
// B23 iPhone. Canale "traker_ia/telefono" (come MainActivity.kt su Android):
// cookie della pagina di login (anche HttpOnly, solo letti e passati alla
// cassaforte, mai nei log), stato "Aggiorna in background", Impostazioni
// dell'app, Condividi testo, Salva .md in File > TraKer IA.
// Sottofondo: BGAppRefreshTask (workmanager), iPhone decide quando.
import Flutter
import UIKit
import WebKit
import workmanager_apple

/// Nome del lavoro in sottofondo: uguale a `lavoroLetture` in Dart e a
/// BGTaskSchedulerPermittedIdentifiers in Info.plist.
let lavoroLetture = "traker_ia_letture"

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Motore in sottofondo: stessi plugin dell'app (database, cassaforte, rete).
    WorkmanagerPlugin.setPluginRegistrantCallback { registry in
      GeneratedPluginRegistrant.register(with: registry)
    }
    // iPhone consegna il lavoro solo se registrato qui (prima della fine).
    WorkmanagerPlugin.registerPeriodicTask(
      withIdentifier: lavoroLetture,
      earliestBeginInSeconds: NSNumber(value: 60 * 60)
    )
    WorkmanagerPlugin.registerLaunchHandlers()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    guard let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "TrakerTelefono") else {
      return
    }
    let canale = FlutterMethodChannel(
      name: "traker_ia/telefono",
      binaryMessenger: registrar.messenger()
    )
    canale.setMethodCallHandler { call, result in
      Telefono.gestisci(call, result)
    }
  }
}

/// Comandi del telefono chiamati da Dart.
enum Telefono {
  static func gestisci(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    let arg = call.arguments as? [String: Any] ?? [:]
    switch call.method {
    case "cookie":
      cookie(sito: arg["sito"] as? String ?? "", result)
    case "preparaWeb":
      // Su iPhone non serve (popup e cookie gia' giusti in WKWebView).
      result(true)
    case "batteriaLibera":
      // "Aggiorna app in background": spento = letture a app chiusa bloccate.
      switch UIApplication.shared.backgroundRefreshStatus {
      case .available: result(true)
      case .denied, .restricted: result(false)
      @unknown default: result(nil)
      }
    case "apriPermesso":
      // Una sola pagina su iPhone: Impostazioni > TraKer IA.
      if let u = URL(string: UIApplication.openSettingsURLString) {
        UIApplication.shared.open(u)
      }
      result(true)
    case "condividi":
      result(condividi(arg["testo"] as? String ?? "", titolo: arg["titolo"] as? String ?? ""))
    case "salvaDocumento":
      do {
        result(try salva(arg["nome"] as? String ?? "traker-ia.md", arg["testo"] as? String ?? ""))
      } catch {
        result(FlutterError(code: "salva", message: String(describing: type(of: error)), details: nil))
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  /// "nome=valore; nome2=valore2" dei cookie di [sito] (anche HttpOnly).
  /// Mai nei log.
  private static func cookie(sito: String, _ result: @escaping FlutterResult) {
    guard let host = URL(string: sito)?.host?.lowercased() else {
      result("")
      return
    }
    WKWebsiteDataStore.default().httpCookieStore.getAllCookies { tutti in
      let suoi = tutti.filter { c in
        var d = c.domain.lowercased()
        if d.hasPrefix(".") { d.removeFirst() }
        return host == d || host.hasSuffix("." + d)
      }
      let testo = suoi.map { "\($0.name)=\($0.value)" }.joined(separator: "; ")
      DispatchQueue.main.async { result(testo) }
    }
  }

  /// Pagina in primo piano (per mostrare Condividi).
  private static func pagina() -> UIViewController? {
    let scene = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .first { $0.activationState == .foregroundActive }
      ?? UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
    var vc = scene?.windows.first { $0.isKeyWindow }?.rootViewController
      ?? scene?.windows.first?.rootViewController
    while let sopra = vc?.presentedViewController { vc = sopra }
    return vc
  }

  /// Menu "Condividi" di iPhone col testo (falso = non riuscito).
  private static func condividi(_ testo: String, titolo: String) -> Bool {
    guard let vc = pagina() else { return false }
    let foglio = UIActivityViewController(activityItems: [testo], applicationActivities: nil)
    foglio.setValue(titolo, forKey: "subject")
    // iPad: il foglio deve sapere da dove uscire.
    if let pop = foglio.popoverPresentationController {
      pop.sourceView = vc.view
      pop.sourceRect = CGRect(x: vc.view.bounds.midX, y: vc.view.bounds.midY, width: 0, height: 0)
      pop.permittedArrowDirections = []
    }
    vc.present(foglio, animated: true)
    return true
  }

  /// Scrive in Documenti dell'app/TraKer IA/[nome] (visibile in app File >
  /// Sul mio iPhone > TraKer IA). Stesso nome = sovrascrive.
  private static func salva(_ nome: String, _ testo: String) throws -> String {
    let doc = try FileManager.default.url(
      for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
    let cartella = doc.appendingPathComponent("TraKer IA", isDirectory: true)
    try FileManager.default.createDirectory(at: cartella, withIntermediateDirectories: true)
    // Solo il nome: niente "../" o sottocartelle.
    let pulito = (nome as NSString).lastPathComponent
    let file = cartella.appendingPathComponent(pulito.isEmpty ? "traker-ia.md" : pulito)
    try Data(testo.utf8).write(to: file, options: .atomic)
    return "File > Sul mio iPhone > TraKer IA > \(file.lastPathComponent)"
  }
}
