package no.aerend.customer

import android.app.ActivityManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.os.Bundle
import android.os.PowerManager
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
