package com.crowdsync.app

import android.content.Context
import android.hardware.camera2.CameraCharacteristics
import android.hardware.camera2.CameraManager
import android.net.wifi.WifiManager
import android.os.Handler
import android.os.HandlerThread
import android.os.PowerManager
import android.os.SystemClock
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlin.math.abs
import kotlin.math.max
import kotlin.math.roundToLong
import kotlin.random.Random

class CrowdSyncNativeModule(private val context: Context) : MethodChannel.MethodCallHandler {
    private lateinit var channel: MethodChannel
    private val timingThread = HandlerThread("CrowdSyncTiming").also { it.start() }
    private val handler = Handler(timingThread.looper)
    private val cameraManager = context.getSystemService(Context.CAMERA_SERVICE) as CameraManager
    private val clockSync = ClockSync()
    private var wakeLock: PowerManager.WakeLock? = null
    private var wifiLock: WifiManager.WifiLock? = null

    private var clientMinusHostMicros = 0.0
    private var roundTripMicros = 0.0
    private var driftPpm = 0.0
    private var samples = 0
    private var lastHostMicros = 0L
    private var lastUpdatedMicros = 0L

    private var torchCameraId: String? = null
    private var torchEnabled = false
    private var torchRunnable: Runnable? = null

    fun install(messenger: BinaryMessenger) {
        channel = MethodChannel(messenger, "crowdsync/native_sync")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "nowMicros" -> result.success(nowMicros())
                "resetClock" -> {
                    resetClock()
                    result.success(null)
                }
                "ntpSync" -> result.success(clockSync.ntpSync(call.argument<String>("hostIp") ?: ""))
                "syncedElapsedRealtimeMs" -> result.success(clockSync.getSyncedElapsedRealtime())
                "acquirePerformanceLocks" -> {
                    acquirePerformanceLocks()
                    result.success(null)
                }
                "releasePerformanceLocks" -> {
                    releasePerformanceLocks()
                    result.success(null)
                }
                "audioTrackDriftMicros" -> result.success(0L)
                "updateClock" -> {
                    updateClock(
                        hostSendMicros = call.longArg("hostSendMicros"),
                        clientReceiveMicros = call.longArg("clientReceiveMicros"),
                        clientSendMicros = call.longArg("clientSendMicros"),
                        hostReceiveMicros = call.longArg("hostReceiveMicros"),
                    )
                    result.success(snapshot())
                }
                "hostToLocalMicros" -> {
                    result.success(call.longArg("hostMicros") + clientMinusHostMicros.roundToLong())
                }
                "localToHostMicros" -> {
                    result.success(call.longArg("localMicros") - clientMinusHostMicros.roundToLong())
                }
                "currentEstimate" -> result.success(snapshot())
                "scheduleFlashlight" -> {
                    scheduleFlashlight(
                        mode = call.argument<String>("mode") ?: "off",
                        optIn = call.argument<Boolean>("optIn") ?: false,
                        localStartMicros = call.longArg("localStartMicros"),
                        beatMicros = call.longArg("beatMicros", 500_000L),
                        durationMicros = call.longArg("durationMicros", 0L),
                    )
                    result.success(null)
                }
                "stopFlashlight" -> {
                    stopFlashlight(disable = true)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        } catch (error: Throwable) {
            result.error("CROWDSYNC_NATIVE", error.message, null)
        }
    }

    private fun nowMicros(): Long = SystemClock.elapsedRealtimeNanos() / 1_000L

    private fun resetClock() {
        clockSync.reset()
        clientMinusHostMicros = 0.0
        roundTripMicros = 0.0
        driftPpm = 0.0
        samples = 0
        lastHostMicros = 0L
        lastUpdatedMicros = 0L
    }

    private fun updateClock(
        hostSendMicros: Long,
        clientReceiveMicros: Long,
        clientSendMicros: Long,
        hostReceiveMicros: Long,
    ) {
        val clientProcessing = max(0L, clientSendMicros - clientReceiveMicros)
        val rtt = max(0L, (hostReceiveMicros - hostSendMicros) - clientProcessing)
        val offset = ((clientReceiveMicros - hostSendMicros).toDouble() +
            (clientSendMicros - hostReceiveMicros).toDouble()) / 2.0
        val alpha = if (samples == 0) 1.0 else 0.22
        val nextOffset = (clientMinusHostMicros * (1.0 - alpha)) + (offset * alpha)
        val nextRtt = (roundTripMicros * (1.0 - alpha)) + (rtt.toDouble() * alpha)

        if (samples > 0 && lastHostMicros > 0L) {
            val hostDelta = hostSendMicros - lastHostMicros
            val offsetDelta = nextOffset - clientMinusHostMicros
            if (abs(hostDelta) > 500_000L) {
                driftPpm = (offsetDelta / hostDelta.toDouble()) * 1_000_000.0
            }
        }

        clientMinusHostMicros = nextOffset
        clockSync.updateOffsetFromSample(
            hostSendMicros = hostSendMicros,
            clientReceiveMicros = clientReceiveMicros,
            clientSendMicros = clientSendMicros,
            hostReceiveMicros = hostReceiveMicros,
        )
        roundTripMicros = nextRtt
        samples += 1
        lastHostMicros = hostSendMicros
        lastUpdatedMicros = nowMicros()
    }

    private fun snapshot(): Map<String, Any> = mapOf(
        "clientMinusHostMicros" to clientMinusHostMicros.roundToLong(),
        "roundTripMicros" to roundTripMicros.roundToLong(),
        "driftPpm" to driftPpm,
        "samples" to samples,
        "lastUpdatedMicros" to lastUpdatedMicros,
    )

    private fun scheduleFlashlight(
        mode: String,
        optIn: Boolean,
        localStartMicros: Long,
        beatMicros: Long,
        durationMicros: Long,
    ) {
        stopFlashlight(disable = mode == "off" || !optIn)
        if (!optIn || mode == "off") return

        val startDelayMs = max(0L, (localStartMicros - nowMicros()) / 1_000L)
        handler.postDelayed({
            if (durationMicros > 0L) {
                handler.postDelayed({ stopFlashlight(disable = true) }, durationMicros / 1_000L)
            }
            when (mode) {
                "steady" -> setTorch(true)
                "pulse" -> loopTorch(max(140L, beatMicros / 1_000L))
                "strobe" -> loopTorch(120L)
                "bassReactive" -> loopBass(max(120L, beatMicros / 2_000L))
                else -> setTorch(false)
            }
        }, startDelayMs)
    }

    private fun loopTorch(periodMs: Long) {
        val runnable = object : Runnable {
            override fun run() {
                setTorch(!torchEnabled)
                handler.postDelayed(this, periodMs)
            }
        }
        torchRunnable = runnable
        handler.post(runnable)
    }

    private fun loopBass(periodMs: Long) {
        val runnable = object : Runnable {
            override fun run() {
                val hit = Random.nextFloat() > 0.35f
                setTorch(hit && !torchEnabled)
                handler.postDelayed(this, periodMs)
            }
        }
        torchRunnable = runnable
        handler.post(runnable)
    }

    private fun stopFlashlight(disable: Boolean) {
        torchRunnable?.let { handler.removeCallbacks(it) }
        torchRunnable = null
        if (disable) setTorch(false)
    }

    private fun setTorch(enabled: Boolean) {
        val cameraId = torchCameraId ?: findTorchCameraId()?.also { torchCameraId = it } ?: return
        try {
            cameraManager.setTorchMode(cameraId, enabled)
            torchEnabled = enabled
        } catch (_: Throwable) {
            torchEnabled = false
        }
    }

    private fun findTorchCameraId(): String? {
        for (id in cameraManager.cameraIdList) {
            val characteristics = cameraManager.getCameraCharacteristics(id)
            val hasFlash = characteristics.get(CameraCharacteristics.FLASH_INFO_AVAILABLE) == true
            val lensFacing = characteristics.get(CameraCharacteristics.LENS_FACING)
            if (hasFlash && lensFacing == CameraCharacteristics.LENS_FACING_BACK) return id
        }
        return null
    }

    private fun acquirePerformanceLocks() {
        val powerManager = context.getSystemService(Context.POWER_SERVICE) as PowerManager
        val wifiManager = context.applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
        if (wakeLock?.isHeld != true) {
            wakeLock = powerManager.newWakeLock(
                PowerManager.PARTIAL_WAKE_LOCK,
                "CrowdSync:SyncWakeLock",
            ).also { it.acquire(6 * 60 * 60 * 1000L) }
        }
        if (wifiLock?.isHeld != true) {
            wifiLock = wifiManager.createWifiLock(
                WifiManager.WIFI_MODE_FULL_HIGH_PERF,
                "CrowdSync:WifiHighPerf",
            ).also { it.acquire() }
        }
    }

    private fun releasePerformanceLocks() {
        if (wakeLock?.isHeld == true) wakeLock?.release()
        if (wifiLock?.isHeld == true) wifiLock?.release()
        wakeLock = null
        wifiLock = null
    }

    private fun MethodCall.longArg(name: String, fallback: Long = 0L): Long {
        val value = argument<Any>(name) ?: return fallback
        return when (value) {
            is Long -> value
            is Int -> value.toLong()
            is Double -> value.roundToLong()
            is String -> value.toLongOrNull() ?: fallback
            else -> fallback
        }
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
        stopFlashlight(disable = true)
        releasePerformanceLocks()
        clockSync.dispose()
        timingThread.quitSafely()
    }
}
