package com.song.sakhi.song_sakhi

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.content.pm.ServiceInfo
import android.graphics.Bitmap
import android.graphics.PixelFormat
import android.hardware.display.DisplayManager
import android.hardware.display.VirtualDisplay
import android.media.Image
import android.media.ImageReader
import android.media.projection.MediaProjection
import android.media.projection.MediaProjectionManager
import android.os.Build
import android.os.Handler
import android.os.HandlerThread
import android.os.IBinder
import android.util.DisplayMetrics
import android.util.Log
import android.view.WindowManager
import java.io.File
import java.io.FileOutputStream
import java.util.concurrent.atomic.AtomicBoolean

/**
 * Foreground service behind the floating nudge.
 *
 * It does two jobs:
 *  1. Keeps the app process alive and lets the microphone keep working while the
 *     user is inside Instagram (Android only allows background mic use from a
 *     foreground service of type "microphone" that was started while the app was
 *     visible).
 *  2. Optionally holds a MediaProjection so Dart can ask for a screenshot of
 *     whatever is on screen (used for on-device OCR of reel text).
 *
 * Frames are written to a single JPEG in the cache dir and the path is handed to
 * Dart, which runs ML Kit on it.
 */
class CaptureService : Service() {

    companion object {
        private const val TAG = "SongSakhiCapture"
        const val ACTION_START_CAPTURE = "song_sakhi.capture.START_CAPTURE"
        const val ACTION_START_MIC_ONLY = "song_sakhi.capture.START_MIC_ONLY"
        const val EXTRA_CODE = "code"
        const val EXTRA_DATA = "data"
        private const val CHANNEL_ID = "song_sakhi_nudge"
        private const val NOTIF_ID = 4107
        private const val MAX_FRAME_WIDTH = 1080
        private const val FRAME_TIMEOUT_MS = 2500L

        @Volatile private var instance: CaptureService? = null

        /** Called when the system or the user ends screen sharing. */
        @Volatile var onStopped: (() -> Unit)? = null

        @Volatile private var onStartResult: ((Boolean) -> Unit)? = null

        fun isCapturing(): Boolean = instance?.projection != null

        fun isRunning(): Boolean = instance != null

        fun startCapture(ctx: Context, resultCode: Int, data: Intent, cb: (Boolean) -> Unit) {
            onStartResult = cb
            val i = Intent(ctx, CaptureService::class.java)
                .setAction(ACTION_START_CAPTURE)
                .putExtra(EXTRA_CODE, resultCode)
                .putExtra(EXTRA_DATA, data)
            launch(ctx, i)
        }

        fun startMicOnly(ctx: Context, cb: (Boolean) -> Unit) {
            onStartResult = cb
            launch(ctx, Intent(ctx, CaptureService::class.java).setAction(ACTION_START_MIC_ONLY))
        }

        private fun launch(ctx: Context, intent: Intent) {
            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    ctx.startForegroundService(intent)
                } else {
                    ctx.startService(intent)
                }
            } catch (e: Exception) {
                Log.e(TAG, "Could not start service", e)
                onStartResult?.invoke(false)
                onStartResult = null
            }
        }

        fun stop(ctx: Context) {
            ctx.stopService(Intent(ctx, CaptureService::class.java))
        }

        /** Delivers the path of a fresh screenshot, or null if none could be taken. */
        fun captureFrame(cb: (String?) -> Unit) {
            val svc = instance
            if (svc == null) cb(null) else svc.requestFrame(cb)
        }
    }

    private var projection: MediaProjection? = null
    private var display: VirtualDisplay? = null
    private var reader: ImageReader? = null
    private var thread: HandlerThread? = null
    private var handler: Handler? = null

    private val closed = AtomicBoolean(false)
    private val wantFrame = AtomicBoolean(false)
    private val lock = Any()
    private var pendingCb: ((String?) -> Unit)? = null
    private var pendingToken: Any? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        instance = this
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START_CAPTURE -> {
                val code = intent.getIntExtra(EXTRA_CODE, 0)
                val data: Intent? = if (Build.VERSION.SDK_INT >= 33) {
                    intent.getParcelableExtra(EXTRA_DATA, Intent::class.java)
                } else {
                    @Suppress("DEPRECATION")
                    intent.getParcelableExtra(EXTRA_DATA)
                }
                if (data == null || !enterForeground(withProjection = true)) {
                    failStart()
                    return START_NOT_STICKY
                }
                val ok = try {
                    beginProjection(code, data)
                } catch (e: Exception) {
                    Log.e(TAG, "MediaProjection setup failed", e)
                    false
                }
                if (!ok) {
                    failStart()
                    return START_NOT_STICKY
                }
                deliverStart(true)
            }
            ACTION_START_MIC_ONLY -> {
                if (!enterForeground(withProjection = false)) {
                    failStart()
                    return START_NOT_STICKY
                }
                deliverStart(true)
            }
        }
        return START_NOT_STICKY
    }

    // ---- foreground / notification ------------------------------------------------

    private fun enterForeground(withProjection: Boolean): Boolean {
        createChannel()
        val notification = buildNotification()
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                var type = 0
                if (withProjection) {
                    type = type or ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PROJECTION
                }
                val micGranted = checkCallingOrSelfPermission(Manifest.permission.RECORD_AUDIO) ==
                    PackageManager.PERMISSION_GRANTED
                if (micGranted && Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                    type = type or ServiceInfo.FOREGROUND_SERVICE_TYPE_MICROPHONE
                }
                if (type == 0) {
                    // Mic-only start without the permission: nothing useful to keep alive.
                    Log.e(TAG, "No foreground type available (mic permission missing)")
                    return false
                }
                startForeground(NOTIF_ID, notification, type)
            } else {
                startForeground(NOTIF_ID, notification)
            }
            return true
        } catch (e: Exception) {
            Log.e(TAG, "startForeground failed", e)
            return false
        }
    }

    private fun createChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            nm.createNotificationChannel(
                NotificationChannel(CHANNEL_ID, "Floating nudge", NotificationManager.IMPORTANCE_LOW)
            )
        }
    }

    private fun buildNotification(): Notification {
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
        }
        builder
            .setContentTitle("Song Sakhi nudge is on")
            .setContentText("Open a reel and tap the floating circle to find its songs.")
            .setSmallIcon(applicationInfo.icon)
            .setOngoing(true)
        packageManager.getLaunchIntentForPackage(packageName)?.let { launch ->
            val pi = PendingIntent.getActivity(
                this, 0, launch, PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
            )
            builder.setContentIntent(pi)
        }
        return builder.build()
    }

    // ---- screen capture -----------------------------------------------------------

    private fun screenSize(): Triple<Int, Int, Int> {
        val wm = getSystemService(Context.WINDOW_SERVICE) as WindowManager
        val dpi = resources.displayMetrics.densityDpi
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            val b = wm.maximumWindowMetrics.bounds
            Triple(b.width(), b.height(), dpi)
        } else {
            val m = DisplayMetrics()
            @Suppress("DEPRECATION")
            wm.defaultDisplay.getRealMetrics(m)
            Triple(m.widthPixels, m.heightPixels, m.densityDpi)
        }
    }

    private fun beginProjection(code: Int, data: Intent): Boolean {
        val mpm = getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
        val proj = mpm.getMediaProjection(code, data) ?: return false

        val t = HandlerThread("song_sakhi_capture").also { it.start() }
        val h = Handler(t.looper)
        thread = t
        handler = h

        // Android 14+ requires a callback to be registered before capturing.
        proj.registerCallback(object : MediaProjection.Callback() {
            override fun onStop() {
                h.post {
                    teardown()
                    onStopped?.invoke()
                    stopSelf()
                }
            }
        }, h)

        val (sw, sh, dpi) = screenSize()
        val scale = if (sw > MAX_FRAME_WIDTH) MAX_FRAME_WIDTH.toFloat() / sw else 1f
        val w = (sw * scale).toInt().coerceAtLeast(2)
        val hgt = (sh * scale).toInt().coerceAtLeast(2)

        val r = ImageReader.newInstance(w, hgt, PixelFormat.RGBA_8888, 2)
        r.setOnImageAvailableListener({ rd -> onImage(rd) }, h)
        display = proj.createVirtualDisplay(
            "song_sakhi_capture",
            w, hgt, dpi,
            DisplayManager.VIRTUAL_DISPLAY_FLAG_AUTO_MIRROR,
            r.surface, null, h
        )
        reader = r
        projection = proj
        return true
    }

    private fun requestFrame(cb: (String?) -> Unit) {
        val h = handler
        if (h == null || projection == null || closed.get()) {
            cb(null)
            return
        }
        val token = Any()
        val previous = synchronized(lock) {
            val p = pendingCb
            pendingCb = cb
            pendingToken = token
            p
        }
        previous?.invoke(null)
        wantFrame.set(true)
        // A still screen produces no new frames; give up instead of hanging Dart.
        h.postDelayed({
            val expired = synchronized(lock) { pendingToken === token }
            if (expired) deliverFrame(null)
        }, FRAME_TIMEOUT_MS)
    }

    private fun onImage(rd: ImageReader) {
        val image: Image? = try {
            rd.acquireLatestImage()
        } catch (e: Exception) {
            null
        }
        if (image == null) return
        try {
            if (!wantFrame.compareAndSet(true, false)) return
            val bmp = toBitmap(image)
            val file = File(cacheDir, "nudge_frame.jpg")
            FileOutputStream(file).use { out -> bmp.compress(Bitmap.CompressFormat.JPEG, 85, out) }
            bmp.recycle()
            deliverFrame(file.absolutePath)
        } catch (e: Exception) {
            Log.e(TAG, "Frame conversion failed", e)
            deliverFrame(null)
        } finally {
            image.close()
        }
    }

    private fun toBitmap(image: Image): Bitmap {
        val plane = image.planes[0]
        val pixelStride = plane.pixelStride
        val rowPadding = plane.rowStride - pixelStride * image.width
        val padded = Bitmap.createBitmap(
            image.width + rowPadding / pixelStride, image.height, Bitmap.Config.ARGB_8888
        )
        padded.copyPixelsFromBuffer(plane.buffer)
        if (rowPadding == 0) return padded
        val cropped = Bitmap.createBitmap(padded, 0, 0, image.width, image.height)
        padded.recycle()
        return cropped
    }

    private fun deliverFrame(path: String?) {
        val cb = synchronized(lock) {
            val c = pendingCb
            pendingCb = null
            pendingToken = null
            c
        }
        wantFrame.set(false)
        cb?.invoke(path)
    }

    // ---- lifecycle ----------------------------------------------------------------

    private fun deliverStart(ok: Boolean) {
        onStartResult?.invoke(ok)
        onStartResult = null
    }

    private fun failStart() {
        deliverStart(false)
        stopSelf()
    }

    private fun teardown() {
        if (!closed.compareAndSet(false, true)) return
        deliverFrame(null)
        try { display?.release() } catch (_: Exception) {}
        try { reader?.close() } catch (_: Exception) {}
        try { projection?.stop() } catch (_: Exception) {}
        display = null
        reader = null
        projection = null
        thread?.quitSafely()
        thread = null
        handler = null
    }

    override fun onDestroy() {
        teardown()
        deliverStart(false)
        instance = null
        super.onDestroy()
    }
}
