// TraKer IA by mdls - Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
//
// Canale "traker_ia/telefono": cookie della pagina di login (anche HttpOnly,
// solo letti e passati alla cassaforte, mai nei log), stato batteria,
// apertura di Info app.
package mdls.traker_ia

import android.content.Intent
import android.net.Uri
import android.os.PowerManager
import android.provider.Settings
import android.webkit.CookieManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

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
                    "batteriaLibera" -> {
                        val pm = getSystemService(POWER_SERVICE) as PowerManager
                        result.success(pm.isIgnoringBatteryOptimizations(packageName))
                    }
                    "apriInfoApp" -> {
                        val i = Intent(
                            Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                            Uri.fromParts("package", packageName, null),
                        )
                        i.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        startActivity(i)
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
