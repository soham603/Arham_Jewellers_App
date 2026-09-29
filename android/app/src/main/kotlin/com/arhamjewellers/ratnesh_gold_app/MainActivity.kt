package com.shreearhamgold.ratneshgold

import android.Manifest
import android.content.ContentValues
import android.content.Intent
import android.content.pm.PackageManager
import android.media.MediaScannerConnection
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import android.util.Log
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.shreearhamgold.ratneshgold/file_saver"

    private val GALLERY_PERMISSION_REQUEST = 4001
    private var pendingGalleryResult: MethodChannel.Result? = null
    private var pendingGalleryBytes: ByteArray? = null
    private var pendingGalleryFileName: String? = null

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
                    "saveImageToGallery" -> {
                        val bytes = call.argument<ByteArray>("bytes")
                        val fileName = call.argument<String>("fileName")
                        if (bytes == null || fileName == null) {
                            result.error("INVALID_ARGS", "bytes and fileName are required", null)
                            return@setMethodCallHandler
                        }
                        handleSaveImageToGallery(bytes, fileName, result)
                    }
                    "shareToWhatsApp" -> {
                        val filePath = call.argument<String>("filePath")
                        val message = call.argument<String>("message") ?: ""
                        val phone = call.argument<String>("phone") ?: ""
                        val packageName = call.argument<String>("packageName")
                        if (filePath == null) {
                            result.error("INVALID_ARGS", "filePath is required", null)
                            return@setMethodCallHandler
                        }
                        val success = shareToWhatsApp(filePath, message, phone, packageName)
                        if (success) {
                            result.success(true)
                        } else {
                            result.error("WHATSAPP_NOT_FOUND", "WhatsApp is not installed", null)
                        }
                    }
                    "getAvailableWhatsAppPackages" -> {
                        val packages = getAvailableWhatsAppPackages()
                        result.success(packages)
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

    private fun handleSaveImageToGallery(
        bytes: ByteArray,
        fileName: String,
        result: MethodChannel.Result
    ) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q &&
            ContextCompat.checkSelfPermission(this, Manifest.permission.WRITE_EXTERNAL_STORAGE)
            != PackageManager.PERMISSION_GRANTED
        ) {
            if (pendingGalleryResult != null) {
                result.error("BUSY", "Another save is already in progress", null)
                return
            }
            pendingGalleryResult = result
            pendingGalleryBytes = bytes
            pendingGalleryFileName = fileName
            ActivityCompat.requestPermissions(
                this,
                arrayOf(Manifest.permission.WRITE_EXTERNAL_STORAGE),
                GALLERY_PERMISSION_REQUEST
            )
            return
        }
        finishSaveImageToGallery(bytes, fileName, result)
    }

    private fun finishSaveImageToGallery(
        bytes: ByteArray,
        fileName: String,
        result: MethodChannel.Result
    ) {
        val path = saveImageToGallery(bytes, fileName)
        if (path != null) {
            result.success(path)
        } else {
            result.error("SAVE_FAILED", "Could not save image to gallery", null)
        }
    }

    private fun saveImageToGallery(bytes: ByteArray, fileName: String): String? {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                val contentValues = ContentValues().apply {
                    put(MediaStore.Images.Media.DISPLAY_NAME, fileName)
                    put(MediaStore.Images.Media.MIME_TYPE, "image/jpeg")
                    put(
                        MediaStore.Images.Media.RELATIVE_PATH,
                        "${Environment.DIRECTORY_PICTURES}/Ratnesh Gold"
                    )
                    put(MediaStore.Images.Media.IS_PENDING, 1)
                }

                val resolver = contentResolver
                val uri = resolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, contentValues)
                    ?: return null

                try {
                    resolver.openOutputStream(uri)?.use { outputStream ->
                        outputStream.write(bytes)
                    }
                } catch (e: Exception) {
                    resolver.delete(uri, null, null)
                    throw e
                }

                contentValues.clear()
                contentValues.put(MediaStore.Images.Media.IS_PENDING, 0)
                resolver.update(uri, contentValues, null, null)

                uri.toString()
            } else {
                val picturesDir = Environment.getExternalStoragePublicDirectory(
                    Environment.DIRECTORY_PICTURES
                )
                val galleryDir = File(picturesDir, "Ratnesh Gold")
                if (!galleryDir.exists()) galleryDir.mkdirs()

                val file = File(galleryDir, fileName)
                FileOutputStream(file).use { it.write(bytes) }

                MediaScannerConnection.scanFile(
                    this,
                    arrayOf(file.absolutePath),
                    arrayOf("image/jpeg"),
                    null
                )

                file.absolutePath
            }
        } catch (e: Exception) {
            e.printStackTrace()
            null
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)

        if (requestCode != GALLERY_PERMISSION_REQUEST) return

        val result = pendingGalleryResult
        val bytes = pendingGalleryBytes
        val fileName = pendingGalleryFileName
        pendingGalleryResult = null
        pendingGalleryBytes = null
        pendingGalleryFileName = null

        if (result == null || bytes == null || fileName == null) return

        val granted = grantResults.isNotEmpty() &&
            grantResults[0] == PackageManager.PERMISSION_GRANTED

        if (granted) {
            finishSaveImageToGallery(bytes, fileName, result)
        } else {
            result.error(
                "PERMISSION_DENIED",
                "Storage permission is required to save images",
                null
            )
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

    private fun getAvailableWhatsAppPackages(): List<String> {
        val packages = mutableListOf<String>()
        if (isPackageInstalled("com.whatsapp")) packages.add("com.whatsapp")
        if (isPackageInstalled("com.whatsapp.w4b")) packages.add("com.whatsapp.w4b")
        return packages
    }

    private fun shareToWhatsApp(filePath: String, message: String, phone: String, targetPackage: String? = null): Boolean {
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

            val hasWhatsApp = isPackageInstalled("com.whatsapp")
            val hasWhatsAppBusiness = isPackageInstalled("com.whatsapp.w4b")

            if (!hasWhatsApp && !hasWhatsAppBusiness) return false

            val resolvedPackage = when {
                targetPackage != null && isPackageInstalled(targetPackage) -> targetPackage
                hasWhatsApp -> "com.whatsapp"
                hasWhatsAppBusiness -> "com.whatsapp.w4b"
                else -> return false
            }

            val sendIntent = Intent(Intent.ACTION_SEND).apply {
                type = "application/pdf"
                setPackage(resolvedPackage)
                putExtra(Intent.EXTRA_STREAM, uri)
                if (message.isNotEmpty()) {
                    putExtra(Intent.EXTRA_TEXT, message)
                }
                putExtra("jid", "${jid}@s.whatsapp.net")
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }

            startActivity(sendIntent)
            return true
        } catch (e: Exception) {
            Log.e("MainActivity", "shareToWhatsApp failed", e)
            return false
        }
    }
}
