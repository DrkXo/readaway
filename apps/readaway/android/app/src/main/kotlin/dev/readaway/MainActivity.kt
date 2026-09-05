package dev.readaway

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.provider.OpenableColumns
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import java.io.InputStream

class MainActivity : AudioServiceActivity() {
    companion object {
        private const val CHANNEL_NAME = "dev.readaway/file_opener"
    }

    private var methodChannel: MethodChannel? = null
    private var initialFileMap: Map<String, String>? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        intent?.let { handleIntent(it, isInitial = true) }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleIntent(intent, isInitial = false)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_NAME)
        methodChannel?.setMethodCallHandler { call: MethodCall, result: MethodChannel.Result ->
            when (call.method) {
                "getInitialFile" -> {
                    val initial = initialFileMap
                    initialFileMap = null
                    result.success(initial)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun handleIntent(intent: Intent, isInitial: Boolean) {
        if (intent.action != Intent.ACTION_VIEW) return
        val uri: Uri = intent.data ?: return

        try {
            val fileName = getFileName(uri)
            val resolvedPath = resolveUriToFilePath(uri, fileName) ?: return

            val fileMap = mapOf(
                "path" to resolvedPath,
                "fileName" to fileName
            )

            if (isInitial && methodChannel == null) {
                initialFileMap = fileMap
            } else {
                methodChannel?.invokeMethod("openFile", fileMap)
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun getFileName(uri: Uri): String {
        var name: String? = null
        if (uri.scheme == "content") {
            try {
                contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)?.use { cursor ->
                    if (cursor.moveToFirst()) {
                        val index = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                        if (index != -1) {
                            name = cursor.getString(index)
                        }
                    }
                }
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
        if (name.isNullOrEmpty()) {
            name = uri.lastPathSegment
        }
        return name ?: "document"
    }

    private fun resolveUriToFilePath(uri: Uri, fileName: String): String? {
        if (uri.scheme == "file") {
            return uri.path
        }

        if (uri.scheme == "content") {
            val openedFilesDir = File(cacheDir, "opened_files")
            if (!openedFilesDir.exists()) {
                openedFilesDir.mkdirs()
            }

            // Sanitize filename to avoid directory traversal
            val safeFileName = fileName.replace(Regex("[/\\\\?%*:|\"<>]"), "_")
            val targetFile = File(openedFilesDir, safeFileName)

            contentResolver.openInputStream(uri)?.use { inputStream: InputStream ->
                FileOutputStream(targetFile).use { outputStream ->
                    inputStream.copyTo(outputStream)
                }
            }
            return targetFile.absolutePath
        }

        return null
    }
}
