package app.piscatio

import android.content.Intent
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "piscatio/stories")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "available" -> result.success(instagramCanShare())
                    "share" -> {
                        val path = call.argument<String>("path")
                        val appId = call.argument<String>("appId")
                        if (path == null || appId == null) {
                            result.success(false)
                        } else {
                            result.success(
                                shareToStory(
                                    File(path),
                                    appId,
                                    call.argument<String>("top"),
                                    call.argument<String>("bottom"),
                                    call.argument<Boolean>("sticker") ?: false,
                                ),
                            )
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun storyIntent() = Intent(STORY_ACTION).setType("image/*")

    private fun instagramCanShare(): Boolean =
        storyIntent().resolveActivity(packageManager) != null

    /** Opens Instagram's story composer with the card (Meta's documented intent). */
    private fun shareToStory(
        file: File,
        appId: String,
        top: String?,
        bottom: String?,
        sticker: Boolean,
    ): Boolean {
        val uri = try {
            FileProvider.getUriForFile(this, "$packageName.stories", file)
        } catch (e: IllegalArgumentException) {
            return false
        }
        val intent = Intent(STORY_ACTION).apply {
            putExtra("source_application", appId)
            if (sticker) {
                type = "image/*"
                putExtra("interactive_asset_uri", uri)
            } else {
                setDataAndType(uri, "image/png")
            }
            top?.let { putExtra("top_background_color", it) }
            bottom?.let { putExtra("bottom_background_color", it) }
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
        if (intent.resolveActivity(packageManager) == null) return false
        grantUriPermission(INSTAGRAM, uri, Intent.FLAG_GRANT_READ_URI_PERMISSION)
        startActivity(intent)
        return true
    }

    private companion object {
        const val STORY_ACTION = "com.instagram.share.ADD_TO_STORY"
        const val INSTAGRAM = "com.instagram.android"
    }
}
