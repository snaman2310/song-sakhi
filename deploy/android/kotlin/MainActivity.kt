package com.song.sakhi.song_sakhi

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.media.projection.MediaProjectionManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Hosts the Flutter UI and exposes the small native bridge used by the floating
 * nudge: asking for screen-capture consent, starting/stopping [CaptureService]
 * and fetching a screenshot for OCR.
 */
class MainActivity : FlutterActivity() {

    companion object {
        private const val CHANNEL = "song_sakhi/capture"
        private const val REQ_CAPTURE = 7421
    }

    private var channel: MethodChannel? = null
    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val ch = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        channel = ch

        CaptureService.onStopped = {
            runOnUiThread { ch.invokeMethod("captureStopped", null) }
        }

        ch.setMethodCallHandler { call, result ->
            when (call.method) {
                "start" -> requestCapture(result)
                "startMicOnly" -> {
                    CaptureService.startMicOnly(applicationContext) { ok ->
                        runOnUiThread { result.success(ok) }
                    }
                }
                "stop" -> {
                    CaptureService.stop(applicationContext)
                    result.success(true)
                }
                "isCapturing" -> result.success(CaptureService.isCapturing())
                "captureFrame" -> {
                    CaptureService.captureFrame { path ->
                        runOnUiThread { result.success(path) }
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun requestCapture(result: MethodChannel.Result) {
        if (CaptureService.isCapturing()) {
            result.success(true)
            return
        }
        if (pendingResult != null) {
            result.error("BUSY", "A screen capture request is already open.", null)
            return
        }
        pendingResult = result
        val mpm = getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
        @Suppress("DEPRECATION")
        startActivityForResult(mpm.createScreenCaptureIntent(), REQ_CAPTURE)
    }

    @Suppress("DEPRECATION")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode != REQ_CAPTURE) {
            super.onActivityResult(requestCode, resultCode, data)
            return
        }
        val result = pendingResult
        pendingResult = null
        if (resultCode == Activity.RESULT_OK && data != null) {
            CaptureService.startCapture(applicationContext, resultCode, data) { ok ->
                runOnUiThread { result?.success(ok) }
            }
        } else {
            result?.success(false)
        }
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        CaptureService.onStopped = null
        channel?.setMethodCallHandler(null)
        channel = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
