package com.zykl.app

import android.content.Context
import android.media.AudioAttributes
import android.media.SoundPool

/**
 * Low-latency player for short one-shot sounds (foley clicks and alarm-chime
 * auditions in Settings).
 *
 * Every asset is decoded once into memory by [SoundPool], so a tap plays with
 * near-zero latency and can never be dropped by the real-alarm de-duplication
 * in [MainActivity.shouldPlayAlarm]. Decoding is async; a play request that
 * arrives before its sample is ready is queued and fired from the load
 * callback, so the very first tap still sounds.
 *
 * Previews cut off the previous preview (single preview voice); foley
 * overlaps freely.
 */
class EffectSoundPlayer(private val context: Context) {
    private val pool: SoundPool = SoundPool.Builder()
        .setMaxStreams(8)
        .setAudioAttributes(
            AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_MEDIA)
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .build()
        )
        .build()

    private val soundIds = HashMap<String, Int>()
    private val loaded = HashSet<Int>()
    private val pending = HashMap<Int, PendingPlay>()
    private var previewStreamId = 0

    private class PendingPlay(val volume: Float, val isPreview: Boolean)

    init {
        pool.setOnLoadCompleteListener { _, sampleId, status ->
            synchronized(this) {
                if (status != 0) {
                    soundIds.entries.removeAll { it.value == sampleId }
                    pending.remove(sampleId)
                    return@setOnLoadCompleteListener
                }
                loaded.add(sampleId)
                pending.remove(sampleId)?.let { startStream(sampleId, it.volume, it.isPreview) }
            }
        }
    }

    /** Starts decoding [assetPaths] (idempotent). Call early to warm the cache. */
    @Synchronized
    fun preload(assetPaths: Collection<String>) {
        assetPaths.forEach { ensureLoaded(it) }
    }

    @Synchronized
    fun playFoley(assetPath: String, volume: Float = 1f) = play(assetPath, volume.coerceIn(0f, 1f), isPreview = false)

    /** Auditions a chime: replaces any preview still ringing. */
    @Synchronized
    fun playPreview(assetPath: String, volume: Float) =
        play(assetPath, volume.coerceIn(0f, 1f), isPreview = true)

    @Synchronized
    fun stopPreview() {
        if (previewStreamId != 0) {
            pool.stop(previewStreamId)
            previewStreamId = 0
        }
    }

    @Synchronized
    fun release() {
        pool.release()
        soundIds.clear()
        loaded.clear()
        pending.clear()
    }

    private fun play(assetPath: String, volume: Float, isPreview: Boolean) {
        val id = ensureLoaded(assetPath) ?: return
        if (isPreview) stopPreview()
        if (loaded.contains(id)) {
            startStream(id, volume, isPreview)
        } else {
            // A newer request for the same sample replaces the queued one.
            pending[id] = PendingPlay(volume, isPreview)
        }
    }

    private fun startStream(sampleId: Int, volume: Float, isPreview: Boolean) {
        val stream = pool.play(sampleId, volume, volume, 1, 0, 1f)
        if (isPreview) previewStreamId = stream
    }

    private fun ensureLoaded(assetPath: String): Int? {
        soundIds[assetPath]?.let { return it }
        return try {
            val id = context.assets.openFd(assetPath).use { pool.load(it, 1) }
            if (id == 0) null else id.also { soundIds[assetPath] = it }
        } catch (_: Exception) {
            null
        }
    }
}
