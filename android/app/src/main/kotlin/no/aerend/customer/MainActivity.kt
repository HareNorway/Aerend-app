package no.aerend.customer

import android.app.ActivityManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.media.AudioAttributes
import android.os.BatteryManager
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
    // Parity plan §3: the motion tier reads the device class and battery
    // saver here (`BergenPerf` in Dart); the thermal status feeds the perf
    // heartbeat and the gentle heat ladder (moderate / severe: decorative
    // motion at 30 fps; critical: motion off).
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
                result.success(haptic(call.arguments as? String ?: "tick"))
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

    // The vibration motor directly (`AeHaptikk` in Dart, Kunde Glatt D3 = the
    // Partner app's kinds). It is not performHapticFeedback, which the phone's
    // touch-vibration setting mutes, and it is tagged media: since Android 12
    // an untagged short effect is treated as touch feedback and muted by the
    // same setting. Silent and vibration-off modes still apply.
    //   tikk    → EFFECT_TICK (EFFECT_CLICK where the phone says it has no tick)
    //   fast    → EFFECT_HEAVY_CLICK
    //   suksess → EFFECT_DOUBLE_CLICK
    //   feil    → waveform 0/40/60/40 ms
    //   tung    → EFFECT_HEAVY_CLICK (the games' single heavy pulse)
    // The kinds from before the plan (tick = a click, confirm = a heavy click,
    // success = a double click) still play as they did (harness
    // `kglattVib: false`). Answers false without a vibrator (Dart then falls
    // back to HapticFeedback). Before API 29 the clicks are short one-shots.
    private fun haptic(kind: String): Boolean {
        val v = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            (getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager).defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
        }
        if (!v.hasVibrator()) return false
        val feil = longArrayOf(0, 40, 60, 40)
        val dobbel = kind == "success" || kind == "suksess"
        val tung = kind == "confirm" || kind == "fast" || kind == "tung"
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            @Suppress("DEPRECATION")
            when {
                kind == "feil" -> v.vibrate(feil, -1)
                dobbel -> v.vibrate(longArrayOf(0, 25, 90, 25), -1)
                tung -> v.vibrate(30)
                else -> v.vibrate(15)
            }
            return true
        }
        val effect = if (kind == "feil") {
            VibrationEffect.createWaveform(feil, -1)
        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            VibrationEffect.createPredefined(
                when {
                    dobbel -> VibrationEffect.EFFECT_DOUBLE_CLICK
                    tung -> VibrationEffect.EFFECT_HEAVY_CLICK
                    kind == "tikk" && !harIkkeTikk(v) -> VibrationEffect.EFFECT_TICK
                    else -> VibrationEffect.EFFECT_CLICK
                },
            )
        } else {
            when {
                dobbel -> VibrationEffect.createWaveform(longArrayOf(0, 25, 90, 25), -1)
                tung -> VibrationEffect.createOneShot(30, VibrationEffect.DEFAULT_AMPLITUDE)
                else -> VibrationEffect.createOneShot(15, VibrationEffect.DEFAULT_AMPLITUDE)
            }
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            v.vibrate(effect, VibrationAttributes.createForUsage(VibrationAttributes.USAGE_MEDIA))
        } else {
            @Suppress("DEPRECATION")
            v.vibrate(effect, AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_MEDIA).build())
        }
        return true
    }

    // API 30+ can say whether the motor has a real tick; some phones (the Vivo
    // V40) answer NO and would play the tick's weak fallback, so they get the
    // click instead (the feel approved on the Partner app, 2026-11-11).
    private fun harIkkeTikk(v: Vibrator): Boolean =
        Build.VERSION.SDK_INT >= Build.VERSION_CODES.R &&
            v.areEffectsSupported(VibrationEffect.EFFECT_TICK)[0] == Vibrator.VIBRATION_EFFECT_SUPPORT_NO

    private fun perfState(): Map<String, Any> {
        val am = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        val mi = ActivityManager.MemoryInfo()
        am.getMemoryInfo(mi)
        val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
        // NONE 0 · LIGHT 1 · MODERATE 2 · SEVERE 3 · CRITICAL 4+ → 0 nominal · 1 fair · 2 serious · 3 critical
        // Heat ladder: the raw status too (moderate 2 vs light 1, both fair).
        val status = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) pm.currentThermalStatus else 0
        val thermal = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            when (status) {
                0 -> 0
                1, 2 -> 1
                3 -> 2
                else -> 3
            }
        } else 0
        // Perf plan: battery level (%), battery temperature (°C from the sticky
        // ACTION_BATTERY_CHANGED intent, tenths of a degree) and the thermal
        // headroom forecast (API 30+, 0..1, 1 = throttling) for the heartbeat.
        val bm = getSystemService(Context.BATTERY_SERVICE) as BatteryManager
        val level = bm.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY)
        val sticky = registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
        val tenths = sticky?.getIntExtra(BatteryManager.EXTRA_TEMPERATURE, -10) ?: -10
        val headroom = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            val h = pm.getThermalHeadroom(10)
            if (h.isNaN()) -1.0 else h.toDouble()
        } else -1.0
        return mapOf(
            "platform" to "android",
            "model" to Build.MODEL,
            "ramMb" to mi.totalMem.toDouble() / 1_048_576.0,
            "lowRam" to am.isLowRamDevice,
            "sdk" to Build.VERSION.SDK_INT,
            "lowPower" to pm.isPowerSaveMode,
            "thermal" to thermal,
            "thermalStatus" to status,
            "battery" to (if (level < 0) -1.0 else level.toDouble()),
            "batteryTemp" to (if (tenths < 0) -1.0 else tenths / 10.0),
            "thermalHeadroom" to headroom,
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
