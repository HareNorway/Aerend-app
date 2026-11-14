package no.aerend.live_card

import android.content.Context
import androidx.core.app.NotificationManagerCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * `aerend/live_card`: the customer's order as a live card on the lock screen and in the shade («Ærend Kunde Bergen»,
 * Låseskjerm · leveringsstatus). A plugin (not MainActivity code) so it is registered in every Flutter engine — also
 * the one Firebase starts for a push while the app is closed.
 */
class LiveCardPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private var channel: MethodChannel? = null
    private var renderer: LiveCardRenderer? = null
    private var context: Context? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        renderer = LiveCardRenderer(binding.applicationContext, binding.flutterAssets)
        channel = MethodChannel(binding.binaryMessenger, "aerend/live_card").also { it.setMethodCallHandler(this) }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel?.setMethodCallHandler(null)
        channel = null
        renderer = null
        context = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "show" -> {
                val id = call.argument<Int>("id")
                val view = call.argument<Map<String, Any?>>("view")
                if (id == null || view == null) return result.error("args", "id and view", null)
                result.success(try {
                    renderer?.show(id, view) ?: false
                } catch (e: Exception) {
                    android.util.Log.w("LiveCard", "show failed", e)
                    false
                })
            }
            "cancel" -> {
                val id = call.argument<Int>("id") ?: return result.error("args", "id", null)
                context?.let { NotificationManagerCompat.from(it).cancel(id) }
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }
}
