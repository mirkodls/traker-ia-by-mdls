// TraKer IA by mdls - Copyright (C) 2026 Mirko Del Sette. Tutti i diritti riservati.
//
// Canale "traker_ia/telefono": cookie della pagina di login (anche HttpOnly,
// solo letti e passati alla cassaforte, mai nei log), stato batteria,
// pagine dei permessi batteria (popup, pagina app, Samsung, Info app).
// B21: Condividi testo (menu Android) e Salva .md in Documenti/TraKer IA
// (MediaStore, senza permessi).
package mdls.traker_ia

import android.content.ActivityNotFoundException
import android.content.ComponentName
import android.content.ContentUris
import android.content.ContentValues
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.os.PowerManager
import android.provider.MediaStore
import android.provider.Settings
import java.io.File
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
                    "condividi" -> {
                        val testo = call.argument<String>("testo") ?: ""
                        val titolo = call.argument<String>("titolo") ?: ""
                        val i = Intent(Intent.ACTION_SEND)
                            .setType("text/plain")
                            .putExtra(Intent.EXTRA_TEXT, testo)
                            .putExtra(Intent.EXTRA_SUBJECT, titolo)
                        // Testo troppo grande per Android = eccezione: falso.
                        val ok = try {
                            startActivity(Intent.createChooser(i, titolo))
                            true
                        } catch (_: RuntimeException) {
                            false
                        }
                        result.success(ok)
                    }
                    "salvaDocumento" -> {
                        try {
                            result.success(
                                salvaDocumento(
                                    call.argument<String>("nome") ?: "traker-ia.md",
                                    call.argument<String>("testo") ?: "",
                                ),
                            )
                        } catch (e: Exception) {
                            result.error("salva", e.javaClass.simpleName, null)
                        }
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

    /**
     * Scrive [testo] in Documenti/TraKer IA/[nome]; stesso nome = sovrascrive
     * (solo file creati da questa app). Ritorna il percorso da mostrare.
     */
    private fun salvaDocumento(nome: String, testo: String): String {
        val sotto = Environment.DIRECTORY_DOCUMENTS + "/TraKer IA"
        val byte = testo.toByteArray(Charsets.UTF_8)
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            // Android 8-9: cartella Documenti dell'app (senza permessi).
            val d = File(getExternalFilesDir(Environment.DIRECTORY_DOCUMENTS), "TraKer IA")
            d.mkdirs()
            val f = File(d, nome)
            f.writeBytes(byte)
            return f.absolutePath
        }
        val r = contentResolver
        val col = MediaStore.Files.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
        var uri: Uri? = null
        r.query(
            col,
            arrayOf(MediaStore.MediaColumns._ID),
            "${MediaStore.MediaColumns.RELATIVE_PATH}=? AND ${MediaStore.MediaColumns.DISPLAY_NAME}=?",
            arrayOf("$sotto/", nome),
            null,
        )?.use { c ->
            if (c.moveToFirst()) uri = ContentUris.withAppendedId(col, c.getLong(0))
        }
        if (uri == null) {
            val v = ContentValues().apply {
                put(MediaStore.MediaColumns.DISPLAY_NAME, nome)
                put(MediaStore.MediaColumns.MIME_TYPE, "text/markdown")
                put(MediaStore.MediaColumns.RELATIVE_PATH, "$sotto/")
            }
            uri = r.insert(col, v) ?: throw IllegalStateException("insert")
        }
        r.openOutputStream(uri!!, "wt")?.use { it.write(byte) }
            ?: throw IllegalStateException("scrittura")
        return "$sotto/$nome"
    }

    private fun infoApp(pkg: Uri) {
        startActivity(
            Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, pkg)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
        )
    }
}
