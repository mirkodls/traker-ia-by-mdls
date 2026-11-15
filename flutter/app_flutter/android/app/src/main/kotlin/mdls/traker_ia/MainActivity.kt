// TraKer IA by mdls - Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
//
// Canale "traker_ia/telefono": cookie della pagina di login (anche HttpOnly,
// solo letti e passati alla cassaforte, mai nei log), stato batteria,
// pagine dei permessi batteria (popup, pagina app, Samsung, Info app).
package mdls.traker_ia

import android.content.ActivityNotFoundException
import android.content.ComponentName
import android.content.Intent
import android.net.Uri
import android.os.PowerManager
import android.provider.Settings
import android.webkit.CookieManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.webviewflutter.WebViewFlutterAndroidExternalApi

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "traker_ia/telefono")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "cookie" -> {
                        val sito = call.argument<String>("sito") ?: ""
                        result.success(CookieManager.getInstance().getCookie(sito) ?: "")
                    }
                    "preparaWeb" -> {
                        // Pagina di login: popup nella stessa pagina (senza
                        // questo i popup di login spariscono = pagina nera)
                        // e cookie di terze parti (controlli anti-bot).
                        val id = (call.argument<Number>("id") ?: -1).toLong()
                        @Suppress("DEPRECATION")
                        val w = WebViewFlutterAndroidExternalApi.getWebView(flutterEngine, id)
                        if (w != null) {
                            w.settings.setSupportMultipleWindows(false)
                            CookieManager.getInstance().setAcceptThirdPartyCookies(w, true)
                        }
                        result.success(w != null)
                    }
                    "batteriaLibera" -> {
                        val pm = getSystemService(POWER_SERVICE) as PowerManager
                        result.success(pm.isIgnoringBatteryOptimizations(packageName))
                    }
                    "apriPermesso" -> {
                        apriPermesso(call.argument<String>("voce") ?: "infoApp")
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    /** Apre la pagina del permesso; se manca su questo telefono, Info app. */
    private fun apriPermesso(voce: String) {
        val pkg = Uri.parse("package:$packageName")
        val i = when (voce) {
            // Popup di Android "Consenti senza limiti di batteria".
            "batteria" -> Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS, pkg)
            // Pagina batteria di questa app (non su tutti i telefoni).
            "paginaBatteria" -> Intent("android.settings.VIEW_ADVANCED_POWER_USAGE_DETAIL", pkg)
            // Samsung: Batteria (da li' "App mai in sospensione").
            "samsung" -> Intent().setComponent(
                ComponentName(
                    "com.samsung.android.lool",
                    "com.samsung.android.sm.battery.ui.BatteryActivity",
                ),
            )
            else -> Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, pkg)
        }
        try {
            startActivity(i.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
        } catch (_: ActivityNotFoundException) {
            infoApp(pkg)
        } catch (_: SecurityException) {
            infoApp(pkg)
        }
    }

    private fun infoApp(pkg: Uri) {
        startActivity(
            Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, pkg)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
        )
    }
}
