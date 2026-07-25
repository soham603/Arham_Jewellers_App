package com.shreearhamgold.ratneshgold

import android.content.ContentValues
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import android.util.Log
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.shreearhamgold.ratneshgold/file_saver"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "saveToDownloads" -> {
                        val bytes = call.argument<ByteArray>("bytes")
                        val fileName = call.argument<String>("fileName")
                        if (bytes == null || fileName == null) {
                            result.error("INVALID_ARGS", "bytes and fileName are required", null)
                            return@setMethodCallHandler
                        }
                        val path = saveToDownloads(bytes, fileName)
                        if (path != null) {
                            result.success(path)
                        } else {
                            result.error("SAVE_FAILED", "Could not save file to Downloads", null)
                        }
                    }
                    "shareToWhatsApp" -> {
                        val filePath = call.argument<String>("filePath")
                        val message = call.argument<String>("message") ?: ""
                        val phone = call.argument<String>("phone") ?: ""
                        if (filePath == null) {
                            result.error("INVALID_ARGS", "filePath is required", null)
                            return@setMethodCallHandler
                        }
                        val success = shareToWhatsApp(filePath, message, phone)
                        if (success) {
                            result.success(true)
                        } else {
                            result.error("WHATSAPP_NOT_FOUND", "WhatsApp is not installed", null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun saveToDownloads(bytes: ByteArray, fileName: String): String? {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                val contentValues = ContentValues().apply {
                    put(MediaStore.Downloads.DISPLAY_NAME, fileName)
                    put(MediaStore.Downloads.MIME_TYPE, "application/pdf")
                    put(MediaStore.Downloads.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS)
                }

                val resolver = contentResolver
                val uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, contentValues)
                    ?: return null

                resolver.openOutputStream(uri)?.use { outputStream ->
                    outputStream.write(bytes)
                }

                uri.toString()
            } else {
                val downloadsDir = Environment.getExternalStoragePublicDirectory(
                    Environment.DIRECTORY_DOWNLOADS
                )
                if (!downloadsDir.exists()) downloadsDir.mkdirs()

                val file = java.io.File(downloadsDir, fileName)
                FileOutputStream(file).use { it.write(bytes) }

                file.absolutePath
            }
        } catch (e: Exception) {
            e.printStackTrace()
            null
        }
    }

    private fun isPackageInstalled(packageName: String): Boolean {
        return try {
            packageManager.getPackageInfo(packageName, 0)
            true
        } catch (e: PackageManager.NameNotFoundException) {
            false
        }
    }

    private fun shareToWhatsApp(filePath: String, message: String, phone: String): Boolean {
        try {
            val file = File(filePath)
            if (!file.exists()) return false

            val uri: Uri = FileProvider.getUriForFile(
                this,
                "${packageName}.provider",
                file
            )

            val cleanPhone = phone.replace("[^0-9]".toRegex(), "")
            val fallbackPhone = "919408451986"
            val jid = if (cleanPhone.isNotEmpty()) cleanPhone else fallbackPhone

            val whatsAppPackage = when {
                isPackageInstalled("com.whatsapp.w4b") -> "com.whatsapp.w4b"
                isPackageInstalled("com.whatsapp") -> "com.whatsapp"
                else -> return false
            }

            val intent = Intent(Intent.ACTION_SEND).apply {
                setPackage(whatsAppPackage)
                type = "application/pdf"
                putExtra(Intent.EXTRA_STREAM, uri)
                if (message.isNotEmpty()) {
                    putExtra(Intent.EXTRA_TEXT, message)
                }
                putExtra("jid", "${jid}@s.whatsapp.net")
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }

            startActivity(intent)
            return true
        } catch (e: Exception) {
            Log.e("MainActivity", "shareToWhatsApp failed", e)
            return false
        }
    }
}
