package dev.readaway

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.OpenableColumns
import android.webkit.MimeTypeMap
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : AudioServiceActivity() {
    companion object {
        private const val CHANNEL_NAME = "dev.readaway/content_resolver"
    }

    private var methodChannel: MethodChannel? = null
    private var initialSendUris: List<String>? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_NAME)
        methodChannel = channel

        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "materialize" -> {
                    try {
                        val uriString = call.arguments as String
                        val uri = Uri.parse(uriString)
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
                "getInitialSharedUris" -> {
                    val uris = initialSendUris ?: extractUrisFromIntent(intent)
                    initialSendUris = null
                    result.success(uris)
                }
                else -> result.notImplemented()
            }
        }

        // Capture any incoming send/share intent on initial launch
        initialSendUris = extractUrisFromIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)

        val uris = extractUrisFromIntent(intent)
        if (uris.isNotEmpty()) {
            methodChannel?.invokeMethod("onSharedUrisReceived", uris)
        }
    }

    private fun extractUrisFromIntent(intent: Intent?): List<String> {
        if (intent == null) return emptyList()
        val uris = mutableListOf<String>()

        when (intent.action) {
            Intent.ACTION_SEND -> {
                val streamUri = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    intent.getParcelableExtra(Intent.EXTRA_STREAM, Uri::class.java)
                } else {
                    @Suppress("DEPRECATION")
                    intent.getParcelableExtra(Intent.EXTRA_STREAM) as? Uri
                }
                if (streamUri != null) {
                    uris.add(streamUri.toString())
                } else {
                    intent.data?.let { uris.add(it.toString()) }
                }
            }
            Intent.ACTION_SEND_MULTIPLE -> {
                val streamUris = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    intent.getParcelableArrayListExtra(Intent.EXTRA_STREAM, Uri::class.java)
                } else {
                    @Suppress("DEPRECATION")
                    intent.getParcelableArrayListExtra(Intent.EXTRA_STREAM)
                }
                streamUris?.forEach { uri ->
                    uris.add(uri.toString())
                }
            }
        }

        if (uris.isEmpty()) {
            intent.clipData?.let { clipData ->
                for (i in 0 until clipData.itemCount) {
                    clipData.getItemAt(i).uri?.let { uri ->
                        val str = uri.toString()
                        if (!uris.contains(str)) {
                            uris.add(str)
                        }
                    }
                }
            }
        }

        return uris
    }

    /// Resolves a content:// or file:// URI to a real filesystem path the reader
    /// can open, copying content:// documents into the app cache with the original
    /// filename and extension preserved.
    private fun materialize(uri: Uri): Pair<String, String> {
        val resolvedName = resolveFileName(uri)
        val path = if (uri.scheme == "content") {
            copyToCache(uri, resolvedName)
        } else {
            uri.path ?: throw IllegalArgumentException("Unsupported URI: $uri")
        }
        return Pair(path, resolvedName)
    }

    private fun resolveFileName(uri: Uri): String {
        var name: String? = null
        if (uri.scheme == "content") {
            try {
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
            } catch (_: Exception) {
                // Ignore and fallback
            }
        }

        if (name.isNullOrBlank()) {
            name = uri.lastPathSegment ?: "document"
        }

        // If the resolved filename has no extension, attempt to deduce it from MIME type
        if (!name!!.contains(".")) {
            val mimeType = try {
                contentResolver.getType(uri)
            } catch (_: Exception) {
                null
            }
            if (mimeType != null) {
                val ext = MimeTypeMap.getSingleton().getExtensionFromMimeType(mimeType)
                if (!ext.isNullOrEmpty()) {
                    name = "$name.$ext"
                }
            }
        }

        return name!!
    }

    private fun copyToCache(uri: Uri, fileName: String): String {
        val openedFilesDir = File(cacheDir, "opened_files")
        if (!openedFilesDir.exists()) {
            openedFilesDir.mkdirs()
        }
        val safeName = fileName.replace(Regex("[/\\\\?%*:|\"<>]"), "_")
        val uniqueName = "${System.currentTimeMillis()}_$safeName"
        val targetFile = File(openedFilesDir, uniqueName)

        contentResolver.openInputStream(uri)?.use { inputStream ->
            FileOutputStream(targetFile).use { outputStream ->
                inputStream.copyTo(outputStream)
            }
        } ?: throw IllegalStateException("Cannot open input stream for: $uri")

        return targetFile.absolutePath
    }
}