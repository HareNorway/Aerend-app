package no.aerend.customer

import android.content.Context
import android.media.AudioAttributes
import android.os.Build
import android.os.VibrationAttributes
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.provider.Settings
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Fjordløpet haptics plan Step 2 (haptics spec §7.1, §11.3): `aerend/game_haptics` on Android.
 *
 * The tier, asked once when the game opens (no list of phone models):
 *  - **off** below API 29, without a vibrator, or with the phone's touch feedback off
 *    (`Settings.System.HAPTIC_FEEDBACK_ENABLED` = 0 → why `system_off`, the setting shows its line; DH3);
 *  - **rich** on API 31+ when every one of CLICK, TICK, LOW_TICK, THUD, QUICK_RISE, QUICK_FALL and SPIN is supported;
 *  - **standard** otherwise (API 29–30 always: the predefined effects).
 *
 * `prepare(table, scale)` builds every `VibrationEffect` once — a composition per pattern for Rich (H02 per step, H09
 * per band), a predefined effect for Standard; nothing is one-shot or hand-made and nothing is built at play time.
 * `play(key)` only calls `vibrate()` with touch attributes; `stop()` cancels. Unlike `AeHaptikk` (USAGE_MEDIA), the game
 * follows the phone's touch-feedback setting, as the spec asks.
 */
class GameHaptics(private val context: Context) : MethodChannel.MethodCallHandler {
    private val vibrator: Vibrator? by lazy {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            (context.getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as? VibratorManager)?.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            context.getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
        }
    }

    private var tier: String? = null
    private val effects = HashMap<String, VibrationEffect>()

    private val touchAttrs: Any? by lazy {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            VibrationAttributes.createForUsage(VibrationAttributes.USAGE_TOUCH)
        } else {
            AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_ASSISTANCE_SONIFICATION).build()
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "capabilities" -> result.success(capabilities())
                "prepare" -> {
                    @Suppress("UNCHECKED_CAST")
                    val table = call.argument<Map<String, Any?>>("table") ?: emptyMap()
                    val scale = (call.argument<Number>("scale") ?: 1.0).toFloat()
                    prepare(table, scale)
                    result.success(null)
                }
                "play" -> {
                    play(call.argument<String>("key") ?: "")
                    result.success(null)
                }
                "stop" -> {
                    stop()
                    result.success(null)
                }
                "release" -> {
                    stop()
                    effects.clear()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        } catch (e: Exception) {
            // A haptic never takes the game down: the worst case is no vibration.
            result.success(null)
        }
    }

    // Asked again each time the game opens: the player may have changed the phone's setting in between.
    private fun capabilities(): Map<String, Any?> {
        val (t, why) = decideTier()
        tier = t
        return mapOf("tier" to t, "why" to why, "sdk" to Build.VERSION.SDK_INT)
    }

    private fun decideTier(): Pair<String, String?> {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) return "off" to "sdk"
        val v = vibrator ?: return "off" to "no_vibrator"
        if (!v.hasVibrator()) return "off" to "no_vibrator"
        if (touchFeedbackOff()) return "off" to "system_off"
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && allPrimitives(v)) return "rich" to null
        return "standard" to null
    }

    private fun touchFeedbackOff(): Boolean =
        try {
            Settings.System.getInt(context.contentResolver, Settings.System.HAPTIC_FEEDBACK_ENABLED, 1) == 0
        } catch (e: Exception) {
            false
        }

    private fun allPrimitives(v: Vibrator): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return false
        val ids = PRIMS.values.toIntArray()
        return v.areAllPrimitivesSupported(*ids)
    }

    private fun prepare(table: Map<String, Any?>, scale: Float) {
        val t = tier ?: decideTier().first.also { tier = it }
        stop()
        effects.clear()
        if (t == "rich" && Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            @Suppress("UNCHECKED_CAST")
            val android = table["android"] as? Map<String, Any?> ?: return
            for ((key, value) in android) {
                val list = value as? List<*> ?: continue
                val c = VibrationEffect.startComposition()
                var n = 0
                for (p in list) {
                    val e = p as? List<*> ?: continue
                    val prim = PRIMS[e[0] as? String] ?: continue
                    val s = ((e[1] as Number).toFloat() * scale).coerceIn(0f, 1f)
                    val delay = (e[2] as Number).toInt()
                    c.addPrimitive(prim, s, delay)
                    n++
                }
                if (n > 0) effects[key] = c.compose()
            }
        } else if (t == "standard" && Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            @Suppress("UNCHECKED_CAST")
            val std = table["standardAndroid"] as? Map<String, Any?> ?: return
            for ((id, kind) in std) {
                val effect = when (kind) {
                    "TICK" -> VibrationEffect.EFFECT_TICK
                    "CLICK" -> VibrationEffect.EFFECT_CLICK
                    "HEAVY_CLICK" -> VibrationEffect.EFFECT_HEAVY_CLICK
                    "DOUBLE_CLICK" -> VibrationEffect.EFFECT_DOUBLE_CLICK
                    else -> continue
                }
                effects[id] = VibrationEffect.createPredefined(effect)
            }
        }
    }

    private fun play(key: String) {
        val v = vibrator ?: return
        // Standard is keyed by the pattern id alone; the stepped patterns (h02.n, h09.n) have none there.
        val e = effects[key] ?: effects[key.substringBefore('.')] ?: return
        val a = touchAttrs
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU && a is VibrationAttributes) {
            v.vibrate(e, a)
        } else if (a is AudioAttributes) {
            @Suppress("DEPRECATION")
            v.vibrate(e, a)
        } else {
            v.vibrate(e)
        }
    }

    private fun stop() {
        vibrator?.cancel()
    }

    companion object {
        const val CHANNEL = "aerend/game_haptics"

        private val PRIMS: Map<String?, Int> by lazy {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                mapOf(
                    "CLICK" to VibrationEffect.Composition.PRIMITIVE_CLICK,
                    "TICK" to VibrationEffect.Composition.PRIMITIVE_TICK,
                    "LOW_TICK" to VibrationEffect.Composition.PRIMITIVE_LOW_TICK,
                    "THUD" to VibrationEffect.Composition.PRIMITIVE_THUD,
                    "QUICK_RISE" to VibrationEffect.Composition.PRIMITIVE_QUICK_RISE,
                    "QUICK_FALL" to VibrationEffect.Composition.PRIMITIVE_QUICK_FALL,
                    "SPIN" to VibrationEffect.Composition.PRIMITIVE_SPIN,
                )
            } else {
                emptyMap()
            }
        }
    }
}
