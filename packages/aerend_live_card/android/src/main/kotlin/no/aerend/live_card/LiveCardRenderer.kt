package no.aerend.live_card

import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.LinearGradient
import android.graphics.Matrix
import android.graphics.Paint
import android.graphics.Path
import android.graphics.RadialGradient
import android.graphics.RectF
import android.graphics.Shader
import android.graphics.Typeface
import android.net.Uri
import android.os.Build
import android.os.SystemClock
import android.view.View
import android.widget.RemoteViews
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin

/**
 * Draws «Låseskjerm · leveringsstatus» as a notification: the header (Æ, ÆREND, the order's code, LIVE), the stage
 * and its line, the countdown (a Chronometer, so it ticks without the app), the track (the mint bar, the four steps
 * and the stage's Ægil — a bitmap drawn here), and the route with «Åpne». The design's motion (Ægil walking, the
 * steam, the pulse) cannot run in a notification; each stage shows its frame.
 *
 * The view is built in Dart (`NtfLiveCard.view`): keys `title`, `sub`, `code`, `live`, `eta_ms`, `time_text`,
 * `time_sub`, `stage`, `progress`, `pickup`, `rider`, `labels`, `route`, `open`, `link`, `ongoing`, `timeout_ms`.
 */
class LiveCardRenderer(private val ctx: Context, private val assets: FlutterPlugin.FlutterAssets) {
    companion object {
        const val CHANNEL = "ntf_live_v2"
        private val MINT = Color.parseColor("#5CE0B8")
        private val INK = Color.parseColor("#0B2A30")
    }

    private val d = ctx.resources.displayMetrics.density
    private val images = HashMap<String, Bitmap?>()

    fun show(id: Int, v: Map<String, Any?>): Boolean {
        if (Build.VERSION.SDK_INT >= 33 &&
            ContextCompat.checkSelfPermission(ctx, Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED
        ) return false
        ensureChannel()

        val title = str(v, "title")
        val sub = str(v, "sub")
        val stage = (v["stage"] as? Number)?.toInt()?.coerceIn(0, 3) ?: 0
        val progress = ((v["progress"] as? Number)?.toFloat() ?: (stage / 3f)).coerceIn(0f, 1f)
        val labels = (v["labels"] as? List<*>)?.map { "$it" } ?: listOf("Bekreftet", "Tilberedes", "På vei", "Levert")
        val pickup = v["pickup"] == true
        val rider = str(v, "rider").ifEmpty { "bike" }
        val ongoing = v["ongoing"] != false
        val etaMs = (v["eta_ms"] as? Number)?.toLong()

        val big = RemoteViews(ctx.packageName, R.layout.aerend_live_card_big)
        val small = RemoteViews(ctx.packageName, R.layout.aerend_live_card_small)
        big.setTextViewText(R.id.lc_code, str(v, "code"))
        big.setTextViewText(R.id.lc_live, "●  " + str(v, "live").ifEmpty { "LIVE" })
        big.setTextViewText(R.id.lc_time_sub, str(v, "time_sub"))
        big.setTextViewText(R.id.lc_route, str(v, "route"))
        big.setTextViewText(R.id.lc_open, str(v, "open").ifEmpty { "Åpne" } + " ›")
        for (rv in listOf(big, small)) {
            rv.setTextViewText(R.id.lc_title, title)
            rv.setTextViewText(R.id.lc_sub, sub)
            // The countdown ticks on its own (a count-down Chronometer); past the time, or done, it is a word.
            val left = if (etaMs == null) -1L else etaMs - System.currentTimeMillis()
            if (left > 60_000L) {
                rv.setChronometer(R.id.lc_timer, SystemClock.elapsedRealtime() + left, null, true)
                rv.setChronometerCountDown(R.id.lc_timer, true)
                rv.setViewVisibility(R.id.lc_timer, View.VISIBLE)
                rv.setViewVisibility(R.id.lc_time, View.GONE)
            } else {
                rv.setViewVisibility(R.id.lc_timer, View.GONE)
                rv.setViewVisibility(R.id.lc_time, View.VISIBLE)
                rv.setTextViewText(R.id.lc_time, str(v, "time_text"))
            }
        }
        big.setImageViewBitmap(R.id.lc_track, track(stage, progress, labels, pickup, rider))
        small.setImageViewBitmap(R.id.lc_bar, bar(stage, progress))

        val link = str(v, "link")
        val tap = if (link.isEmpty()) ctx.packageManager.getLaunchIntentForPackage(ctx.packageName)
        else Intent(Intent.ACTION_VIEW, Uri.parse(link)).setPackage(ctx.packageName)
        tap?.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
        val pi = tap?.let { PendingIntent.getActivity(ctx, id, it, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE) }

        val iconId = ctx.resources.getIdentifier("ic_notification", "drawable", ctx.packageName).takeIf { it != 0 }
            ?: ctx.applicationInfo.icon
        val n = NotificationCompat.Builder(ctx, CHANNEL)
            .setSmallIcon(iconId)
            .setColor(Color.parseColor("#1E4F5C"))
            .setContentTitle(title)
            .setContentText(sub)
            .setStyle(NotificationCompat.DecoratedCustomViewStyle())
            .setCustomContentView(small)
            .setCustomBigContentView(big)
            .setOngoing(ongoing)
            .setAutoCancel(!ongoing)
            .setOnlyAlertOnce(true)
            .setSilent(true)
            .setShowWhen(false)
            .setCategory(NotificationCompat.CATEGORY_STATUS)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
        pi?.let { n.setContentIntent(it) }
        (v["timeout_ms"] as? Number)?.toLong()?.takeIf { it > 0 }?.let { n.setTimeoutAfter(it) }
        NotificationManagerCompat.from(ctx).notify(id, n.build())
        return true
    }

    /**
     * Default importance (silent: no sound, no vibration, no heads-up): Android hides *silent* (low) notifications on
     * the lock screen by default, and the card is for the lock screen.
     */
    private fun ensureChannel() {
        if (Build.VERSION.SDK_INT < 26) return
        val nm = ctx.getSystemService(NotificationManager::class.java) ?: return
        if (nm.getNotificationChannel(CHANNEL) != null) return
        val c = NotificationChannel(CHANNEL, "Bestillingen din nå", NotificationManager.IMPORTANCE_DEFAULT).apply {
            description = "Bestillingen som er på vei, på låseskjermen og oppdatert uten nye varsler."
            setSound(null, null)
            enableVibration(false)
            setShowBadge(false)
            lockscreenVisibility = android.app.Notification.VISIBILITY_PUBLIC
        }
        nm.createNotificationChannel(c)
    }

    // ── the track ────────────────────────────────────────────────────────────────────────────────────────────

    /**
     * 320 × 92 dp, as in the design's 88 px track: the bar at 61 (5 high), the nodes at 63.5 with their labels below,
     * the stage's figure standing on the bar (bottom at 59).
     */
    private fun track(stage: Int, p: Float, labels: List<String>, pickup: Boolean, rider: String): Bitmap {
        val w = 320 * d
        val h = 92 * d
        val bmp = Bitmap.createBitmap(w.toInt(), h.toInt(), Bitmap.Config.ARGB_8888)
        val c = Canvas(bmp)
        val x0 = 8 * d
        val x1 = w - 8 * d
        val tw = x1 - x0
        val foot = 59 * d
        fun at(f: Float) = x0 + tw * f

        // The store at a third: full while the food is made (and when a pickup is ready), faded otherwise.
        val storeFull = stage == 1 || (pickup && stage == 2)
        val storeScale = if (storeFull) 1f else if (stage == 0) .86f else .8f
        val storeAlpha = if (storeFull) 1f else when (stage) { 0 -> .6f; 2 -> .45f; else -> .3f }
        val store = img("store")
        val ss = 56 * d * storeScale
        store?.let { draw(c, it, at(1 / 3f) - ss / 2, foot - ss, ss, storeAlpha, false) }
        if (stage == 1) steam(c, at(1 / 3f) - 12 * d, foot - ss - 2 * d)
        if (pickup && stage == 2) klar(c, at(1 / 3f), foot - ss - 6 * d)

        // Ægil: walking to the store, riding to the door, or celebrating at the end.
        when {
            stage == 0 -> img("side")?.let { val s = 54 * d; draw(c, it, x0 + tw * p - s * p, foot - s, s, 1f, false) }
            stage == 2 && !pickup -> {
                val vehicle = img(if (rider == "van") "van" else "bike")
                val s = (if (rider == "van") 72 else 60) * d
                vehicle?.let { draw(c, it, x0 + tw * p - s * p, foot - s, s, 1f, true) }
            }
            stage >= 3 -> {
                val s = 54 * d
                if (!pickup) img(if (rider == "van") "van" else "bike")?.let { val b = 46 * d; draw(c, it, x1 - s - b + 6 * d, foot - b, b, 1f, true) }
                img("front")?.let { draw(c, it, x1 - s, foot - s, s, 1f, false) }
                sparks(c, x1 - s / 2, foot - s)
            }
        }

        // The bar and its mint fill.
        val barTop = 61 * d
        val barH = 5 * d
        val bg = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = Color.argb(41, 255, 255, 255) }
        c.drawRoundRect(RectF(x0, barTop, x1, barTop + barH), 3 * d, 3 * d, bg)
        if (p > 0f) {
            val fill = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                shader = LinearGradient(x0, 0f, at(p), 0f, intArrayOf(Color.parseColor("#3CC79F"), MINT, Color.parseColor("#A6F8DD")), floatArrayOf(0f, .7f, 1f), Shader.TileMode.CLAMP)
            }
            c.drawRoundRect(RectF(x0, barTop, at(p), barTop + barH), 3 * d, 3 * d, fill)
        }

        // The four steps.
        val cy = 63.5f * d
        val r = 6 * d
        val bold = Typeface.create("sans-serif", Typeface.BOLD)
        val medium = Typeface.create("sans-serif-medium", Typeface.NORMAL)
        for (i in 0..3) {
            val cx = at(i / 3f)
            val ok = i < stage || (i == 3 && stage >= 3)
            val now = i == stage && stage < 3
            if (now) {
                c.drawCircle(cx, cy, r + 6 * d, Paint(Paint.ANTI_ALIAS_FLAG).apply { color = MINT; alpha = 40 })
                c.drawCircle(cx, cy, r + 1.5f * d, Paint(Paint.ANTI_ALIAS_FLAG).apply { color = MINT; alpha = 90; style = Paint.Style.STROKE; strokeWidth = 3 * d })
            }
            val dot = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = when { ok -> MINT; now -> Color.WHITE; else -> Color.argb(66, 255, 255, 255) }
                if (ok) setShadowLayer(5 * d, 0f, 0f, Color.argb(140, 92, 224, 184))
            }
            c.drawCircle(cx, cy, r, dot)
            if (ok) {
                val k = 0.8f * d
                val path = Path().apply { moveTo(cx - 3 * k, cy + .2f * k); lineTo(cx - 1 * k, cy + 2.2f * k); lineTo(cx + 3 * k, cy - 2.2f * k) }
                c.drawPath(path, Paint(Paint.ANTI_ALIAS_FLAG).apply { color = INK; style = Paint.Style.STROKE; strokeWidth = 2 * k; strokeCap = Paint.Cap.ROUND; strokeJoin = Paint.Join.ROUND })
            }
            val tp = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                textSize = 10.5f * d
                typeface = if (ok || now) bold else medium
                color = if (ok || now) Color.argb(242, 255, 255, 255) else Color.argb(128, 255, 255, 255)
            }
            val label = labels.getOrElse(i) { "" }
            val tw2 = tp.measureText(label)
            val lx = when (i) { 0 -> cx - 6 * d; 3 -> cx + 6 * d - tw2; else -> cx - tw2 / 2 }
            c.drawText(label, lx.coerceAtLeast(0f), 84 * d, tp)
        }
        return bmp
    }

    /** The collapsed card's slim track: the bar and four dots. */
    private fun bar(stage: Int, p: Float): Bitmap {
        val w = 320 * d
        val h = 12 * d
        val bmp = Bitmap.createBitmap(w.toInt(), h.toInt(), Bitmap.Config.ARGB_8888)
        val c = Canvas(bmp)
        val x0 = 5 * d
        val x1 = w - 5 * d
        val y = h / 2
        c.drawRoundRect(RectF(x0, y - 2 * d, x1, y + 2 * d), 2 * d, 2 * d, Paint(Paint.ANTI_ALIAS_FLAG).apply { color = Color.argb(41, 255, 255, 255) })
        if (p > 0f) c.drawRoundRect(RectF(x0, y - 2 * d, x0 + (x1 - x0) * p, y + 2 * d), 2 * d, 2 * d, Paint(Paint.ANTI_ALIAS_FLAG).apply { color = MINT })
        for (i in 0..3) {
            val ok = i < stage || (i == 3 && stage >= 3)
            val now = i == stage && stage < 3
            c.drawCircle(x0 + (x1 - x0) * i / 3f, y, 4.5f * d, Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = when { ok -> MINT; now -> Color.WHITE; else -> Color.argb(66, 255, 255, 255) }
            })
        }
        return bmp
    }

    /** `lsDamp`: three soft puffs over the store. */
    private fun steam(c: Canvas, x: Float, y: Float) {
        for ((i, dx) in listOf(0f, 9f, 17f).withIndex()) {
            val cx = x + dx * d
            val cy = y - (i % 2) * 4 * d
            val rr = 6 * d
            c.drawCircle(cx, cy, rr, Paint(Paint.ANTI_ALIAS_FLAG).apply {
                shader = RadialGradient(cx, cy, rr, Color.argb(200, 255, 255, 255), Color.argb(0, 255, 255, 255), Shader.TileMode.CLAMP)
            })
        }
    }

    /** «KLAR» over the store (a pickup that is ready). */
    private fun klar(c: Canvas, cx: Float, bottom: Float) {
        val tp = Paint(Paint.ANTI_ALIAS_FLAG).apply { textSize = 9.5f * d; typeface = Typeface.create("sans-serif", Typeface.BOLD); color = INK; letterSpacing = .08f }
        val tw = tp.measureText("KLAR")
        val rect = RectF(cx - 20 * d, bottom - 16 * d, cx + 20 * d, bottom)
        c.drawRoundRect(rect, 8 * d, 8 * d, Paint(Paint.ANTI_ALIAS_FLAG).apply { color = MINT; setShadowLayer(6 * d, 0f, 0f, Color.argb(150, 92, 224, 184)) })
        c.drawText("KLAR", cx - tw / 2, bottom - 4.5f * d, tp)
    }

    /** `lsGnist`: a few four-pointed sparks around the celebration. */
    private fun sparks(c: Canvas, cx: Float, top: Float) {
        val spots = listOf(Triple(-30f, 6f, MINT), Triple(26f, 0f, Color.parseColor("#F2C14E")), Triple(-14f, -8f, Color.parseColor("#F2C14E")), Triple(34f, 22f, MINT))
        for ((dx, dy, col) in spots) {
            val x = cx + dx * d
            val y = top + dy * d
            val s = 4 * d
            val path = Path().apply {
                moveTo(x, y - s); quadTo(x, y, x + s, y); quadTo(x, y, x, y + s); quadTo(x, y, x - s, y); quadTo(x, y, x, y - s); close()
            }
            c.drawPath(path, Paint(Paint.ANTI_ALIAS_FLAG).apply { color = col })
        }
    }

    private fun draw(c: Canvas, b: Bitmap, left: Float, top: Float, size: Float, alpha: Float, flip: Boolean) {
        val scale = size / maxOf(b.width, b.height)
        val m = Matrix()
        if (flip) {
            m.postScale(-scale, scale)
            m.postTranslate(left + b.width * scale, top + (size - b.height * scale))
        } else {
            m.postScale(scale, scale)
            m.postTranslate(left, top + (size - b.height * scale))
        }
        c.drawBitmap(b, m, Paint(Paint.ANTI_ALIAS_FLAG or Paint.FILTER_BITMAP_FLAG).apply { this.alpha = (alpha * 255).toInt() })
    }

    /** The Ægil figures, from the app's Flutter assets (the PNGs in assets/images/dashboard). */
    private fun img(name: String): Bitmap? = images.getOrPut(name) {
        try {
            ctx.assets.open(assets.getAssetFilePathByName("assets/images/dashboard/$name.png")).use { BitmapFactory.decodeStream(it) }
        } catch (e: Exception) {
            null
        }
    }

    private fun str(v: Map<String, Any?>, k: String): String = (v[k] ?: "").toString()
}
