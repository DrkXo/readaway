package dev.readaway

import android.net.Uri
import android.provider.OpenableColumns
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : AudioServiceActivity() {
    companion object {
        private const val CHANNEL_NAME = "dev.readaway/content_resolver"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_NAME)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "materialize" -> {
                        try {
                            val uri = Uri.parse(call.arguments as String)
                            val fileMap = materialize(uri)
                            result.success(
                                mapOf(
                                    "path" to fileMap.first,
                                    "fileName" to fileMap.second,
                                )
                            )
                        } catch (e: Exception) {
                            result.error("materialize_failed", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    /// Resolves a content:// or file:// URI to a real filesystem path the reader
    /// can open, copying content:// documents into the app cache (scoped storage
    /// prevents opening them in place).
    private fun materialize(uri: Uri): Pair<String, String> {
        val path = if (uri.scheme == "content") copyToCache(uri) else uri.path
            ?: throw IllegalArgumentException("Unsupported URI: $uri")

        var name: String? = null
        if (uri.scheme == "content") {
            contentResolver.query(
                uri,
                arrayOf(OpenableColumns.DISPLAY_NAME),
                null,
                null,
                null,
            )?.use { cursor ->
                if (cursor.moveToFirst()) {
                    val index = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                    if (index != -1) {
                        name = cursor.getString(index)
                    }
                }
            }
        }
        return Pair(path, name ?: uri.lastPathSegment ?: "document")
    }

    private fun copyToCache(uri: Uri): String {
        val openedFilesDir = File(cacheDir, "opened_files")
        if (!openedFilesDir.exists()) {
            openedFilesDir.mkdirs()
        }
        val fileName = uri.lastPathSegment ?: "document"
        val safeName = fileName.replace(Regex("[/\\\\?%*:|\"<>]"), "_")
        val targetFile = File(openedFilesDir, safeName)

        contentResolver.openInputStream(uri)?.use { inputStream ->
            FileOutputStream(targetFile).use { outputStream ->
                inputStream.copyTo(outputStream)
            }
        }
        return targetFile.absolutePath
    }
}