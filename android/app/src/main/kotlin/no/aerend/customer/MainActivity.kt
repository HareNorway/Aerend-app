package no.aerend.customer

import android.app.ActivityManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.media.AudioAttributes
import android.os.Build
import android.os.Bundle
import android.os.PowerManager
import android.os.VibrationAttributes
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterFragmentActivity() {
    // Parity plan §3: the motion tier reads the device class, battery saver
    // and the thermal status here (`BergenPerf` in Dart).
    private var perfChannel: MethodChannel? = null
    private var thermalListener: Any? = null
    private var powerReceiver: BroadcastReceiver? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "aerend/perf")
        perfChannel = channel
        channel.setMethodCallHandler { call, result ->
            if (call.method == "info") result.success(perfState()) else result.notImplemented()
        }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "aerend/haptic").setMethodCallHandler { call, result ->
            if (call.method == "play") {
                haptic(call.arguments as? String ?: "tick")
                result.success(null)
            } else result.notImplemented()
        }
        val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val l = PowerManager.OnThermalStatusChangedListener { pushPerf() }
            pm.addThermalStatusListener(l)
            thermalListener = l
        }
        val r = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) = pushPerf()
        }
        registerReceiver(r, IntentFilter(PowerManager.ACTION_POWER_SAVE_MODE_CHANGED))
        powerReceiver = r
    }

    private fun pushPerf() {
        runOnUiThread { perfChannel?.invokeMethod("changed", perfState()) }
    }

    // The vibration motor directly (`aeTick` / `aeConfirm` / `aeSuccess` in
    // Dart): tick = a click, confirm = a heavy click, success = a double
    // click. It is not performHapticFeedback, which the phone's
    // touch-vibration setting mutes, and it is tagged media: since Android 12
    // an untagged short effect is treated as touch feedback and muted by the
    // same setting. Silent and vibration-off modes still apply.
    private fun haptic(kind: String) {
        val v = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            (getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager).defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
        }
        if (!v.hasVibrator()) return
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            @Suppress("DEPRECATION")
            when (kind) {
                "success" -> v.vibrate(longArrayOf(0, 25, 90, 25), -1)
                "confirm" -> v.vibrate(30)
                else -> v.vibrate(15)
            }
            return
        }
        val effect = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            VibrationEffect.createPredefined(
                when (kind) {
                    "success" -> VibrationEffect.EFFECT_DOUBLE_CLICK
                    "confirm" -> VibrationEffect.EFFECT_HEAVY_CLICK
                    else -> VibrationEffect.EFFECT_CLICK
                },
            )
        } else {
            when (kind) {
                "success" -> VibrationEffect.createWaveform(longArrayOf(0, 25, 90, 25), -1)
                "confirm" -> VibrationEffect.createOneShot(30, VibrationEffect.DEFAULT_AMPLITUDE)
                else -> VibrationEffect.createOneShot(15, VibrationEffect.DEFAULT_AMPLITUDE)
            }
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            v.vibrate(effect, VibrationAttributes.createForUsage(VibrationAttributes.USAGE_MEDIA))
        } else {
            @Suppress("DEPRECATION")
            v.vibrate(effect, AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_MEDIA).build())
        }
    }

    private fun perfState(): Map<String, Any> {
        val am = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        val mi = ActivityManager.MemoryInfo()
        am.getMemoryInfo(mi)
        val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
        // NONE 0 · LIGHT 1 · MODERATE 2 · SEVERE 3 · CRITICAL 4+ → 0 nominal · 1 fair · 2 serious · 3 critical
        val thermal = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            when (pm.currentThermalStatus) {
                0 -> 0
                1, 2 -> 1
                3 -> 2
                else -> 3
            }
        } else 0
        return mapOf(
            "platform" to "android",
            "model" to Build.MODEL,
            "ramMb" to mi.totalMem.toDouble() / 1_048_576.0,
            "lowRam" to am.isLowRamDevice,
            "sdk" to Build.VERSION.SDK_INT,
            "lowPower" to pm.isPowerSaveMode,
            "thermal" to thermal,
        )
    }

    override fun onDestroy() {
        val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            (thermalListener as? PowerManager.OnThermalStatusChangedListener)?.let { pm.removeThermalStatusListener(it) }
        }
        powerReceiver?.let { unregisterReceiver(it) }
        super.onDestroy()
    }
}
