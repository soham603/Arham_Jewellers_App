package com.arhamjewellers.ratnesh_gold_app

import android.content.ContentValues
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.arhamjewellers/file_saver"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "saveToDownloads") {
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
                } else {
                    result.notImplemented()
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
}
