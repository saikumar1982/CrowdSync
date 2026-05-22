package com.crowdsync.app

import android.os.Handler
import android.os.HandlerThread
import android.os.SystemClock
import kotlin.math.roundToLong

class ClockSync {
    private val thread = HandlerThread("CrowdSyncClockSync").also { it.start() }
    private val handler = Handler(thread.looper)
    private var offsetMs = 0L

    fun ntpSync(hostIp: String): Long {
        // LAN-only placeholder for Router mode. Nearby Star/Mesh feeds exact
        // four-timestamp samples through updateOffsetFromSample.
        if (hostIp.isBlank()) return offsetMs
        return offsetMs
    }

    fun updateOffsetFromSample(
        hostSendMicros: Long,
        clientReceiveMicros: Long,
        clientSendMicros: Long,
        hostReceiveMicros: Long,
    ): Long {
        val offsetMicros = ((clientReceiveMicros - hostSendMicros).toDouble() +
            (clientSendMicros - hostReceiveMicros).toDouble()) / 2.0
        offsetMs = (offsetMicros / 1000.0).roundToLong()
        return offsetMs
    }

    fun getSyncedElapsedRealtime(): Long = SystemClock.elapsedRealtime() + offsetMs

    fun postAtSyncedTime(runnable: Runnable, syncedTimeMs: Long) {
        handler.postAtTime(runnable, syncedTimeMs - offsetMs)
    }

    fun reset() {
        offsetMs = 0L
    }

    fun dispose() {
        thread.quitSafely()
    }
}
