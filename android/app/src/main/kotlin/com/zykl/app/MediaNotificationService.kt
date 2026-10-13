package com.zykl.app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.ServiceInfo
import android.content.res.AssetFileDescriptor
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.media.MediaPlayer
import android.os.Build
import android.os.IBinder
import android.support.v4.media.MediaMetadataCompat
import android.support.v4.media.session.MediaSessionCompat
import android.support.v4.media.session.PlaybackStateCompat
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import androidx.media.app.NotificationCompat.MediaStyle

class MediaNotificationService : Service() {
    companion object {
        const val CHANNEL_ID = "zykl_media_playback_channel"
        const val CHANNEL_PLAYBACK_ID = "zykl_media_playback_channel"
        const val NOTIFICATION_ID = 2001

        const val ACTION_START = "com.zykl.app.ACTION_START"
        const val ACTION_UPDATE_PLAYBACK = "com.zykl.app.ACTION_UPDATE_PLAYBACK"
        const val ACTION_UPDATE_TIMER = "com.zykl.app.ACTION_UPDATE_TIMER"
        const val ACTION_STOP = "com.zykl.app.ACTION_STOP"
        const val ACTION_PREV = "com.zykl.app.ACTION_PREV"
        const val ACTION_PLAY_PAUSE = "com.zykl.app.ACTION_PLAY_PAUSE"
        const val ACTION_NEXT = "com.zykl.app.ACTION_NEXT"

        const val EXTRA_TRACK_INDEX = "EXTRA_TRACK_INDEX"
        const val EXTRA_TRACK_NAME = "EXTRA_TRACK_NAME"
        const val EXTRA_IS_PLAYING = "EXTRA_IS_PLAYING"
        const val EXTRA_VOLUME = "EXTRA_VOLUME"
        const val EXTRA_PHASE = "EXTRA_PHASE"
        const val EXTRA_REMAINING_SECONDS = "EXTRA_REMAINING_SECONDS"
        const val EXTRA_CYCLE_COUNT = "EXTRA_CYCLE_COUNT"
        const val EXTRA_PLAY_AUDIO = "EXTRA_PLAY_AUDIO"

        const val ACTION_MEDIA_CONTROL = "com.zykl.app.MEDIA_CONTROL"
        const val EXTRA_CONTROL_ACTION = "action"

        var mediaControlListener: ((String) -> Unit)? = null
    }

    private lateinit var mediaSession: MediaSessionCompat
    private var audioManager: AudioManager? = null
    private var audioFocusRequest: AudioFocusRequest? = null
    private var mediaPlayer: MediaPlayer? = null
    private var vinylDiscBitmap: Bitmap? = null

    private var currentTrackIndex: Int = 0
    private var currentTrackName: String = "LO-FI RAIN"
    private var isPlaying: Boolean = false
    private var resumeOnFocusGain: Boolean = false
    /** Paused by a call or another app's short sound: Flutter echoes the pause back (ACTION_UPDATE_PLAYBACK), which
     *  must not cancel the resume when focus returns. */
    private var pausedByTransientLoss: Boolean = false
    private var currentVolume: Float = 0.8f
    private var currentPhase: String = "focus"
    private var currentRemainingSeconds: Double = 1500.0
    private var currentCycleCount: Int = 1
    private var isNativeAudioEnabled: Boolean = false

    private val audioFocusChangeListener = AudioManager.OnAudioFocusChangeListener { focusChange ->
        when (focusChange) {
            AudioManager.AUDIOFOCUS_LOSS -> {
                resumeOnFocusGain = false
                pausedByTransientLoss = false
                if (isPlaying) {
                    isPlaying = false
                    handleMediaControl("pause")
                    pauseAudio()
                    updatePlaybackState()
                    updateNotification()
                }
            }
            AudioManager.AUDIOFOCUS_LOSS_TRANSIENT -> {
                if (isPlaying) {
                    resumeOnFocusGain = true
                    pausedByTransientLoss = true
                    isPlaying = false
                    handleMediaControl("pause")
                    pauseAudio()
                    updatePlaybackState()
                    updateNotification()
                }
            }
            AudioManager.AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK -> {
                setAudioVolume(currentVolume * 0.3f)
            }
            AudioManager.AUDIOFOCUS_GAIN -> {
                setAudioVolume(currentVolume)
                pausedByTransientLoss = false
                if (resumeOnFocusGain) {
                    resumeOnFocusGain = false
                    isPlaying = true
                    handleMediaControl("play")
                    resumeAudio()
                    updatePlaybackState()
                    updateNotification()
                }
            }
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        audioManager = getSystemService(Context.AUDIO_SERVICE) as? AudioManager
        createNotificationChannels()
        initMediaSession()
        ContextCompat.registerReceiver(
            this, noisyReceiver, IntentFilter(AudioManager.ACTION_AUDIO_BECOMING_NOISY), ContextCompat.RECEIVER_NOT_EXPORTED
        )
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> {
                parseIntentExtras(intent)
                if (isPlaying) {
                    if (requestAudioFocus()) {
                        if (isNativeAudioEnabled) {
                            playAudioTrack(currentTrackIndex, currentVolume)
                        }
                    } else {
                        refuseToPlay()
                    }
                }
                updatePlaybackState()
                val notification = buildNotification()
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                    startForeground(
                        NOTIFICATION_ID,
                        notification,
                        ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK
                    )
                } else {
                    startForeground(NOTIFICATION_ID, notification)
                }
            }
            ACTION_UPDATE_PLAYBACK -> {
                val wasPlaying = isPlaying
                val previousTrackIndex = currentTrackIndex
                parseIntentExtras(intent)
                if (isPlaying) {
                    if (requestAudioFocus()) {
                        if (isNativeAudioEnabled) {
                            if (!wasPlaying || previousTrackIndex != currentTrackIndex) {
                                playAudioTrack(currentTrackIndex, currentVolume)
                            } else {
                                resumeAudio()
                            }
                        }
                    } else {
                        refuseToPlay()
                    }
                } else {
                    // Flutter's echo of a pause made here for a call keeps the resume armed.
                    if (!pausedByTransientLoss) resumeOnFocusGain = false
                    pauseAudio()
                }
                updatePlaybackState()
                updateNotification()
            }
            ACTION_UPDATE_TIMER -> {
                parseTimerExtras(intent)
                updateNotification()
            }
            ACTION_STOP -> {
                stopServiceAndNotification()
                return START_NOT_STICKY
            }
            ACTION_PREV -> {
                handleMediaControl("previous")
            }
            ACTION_NEXT -> {
                handleMediaControl("next")
            }
            ACTION_PLAY_PAUSE -> {
                pausedByTransientLoss = false
                if (isPlaying) {
                    isPlaying = false
                    resumeOnFocusGain = false
                    handleMediaControl("pause")
                    pauseAudio()
                } else {
                    if (requestAudioFocus()) {
                        isPlaying = true
                        handleMediaControl("play")
                        resumeAudio()
                    } else {
                        isPlaying = false
                    }
                }
                updatePlaybackState()
                updateNotification()
            }
        }
        return START_NOT_STICKY
    }

    @Suppress("DEPRECATION")
    private fun parseIntentExtras(intent: Intent) {
        if (intent.hasExtra(EXTRA_TRACK_INDEX)) {
            currentTrackIndex = intent.getIntExtra(EXTRA_TRACK_INDEX, currentTrackIndex)
        }
        val trackName = intent.getStringExtra(EXTRA_TRACK_NAME)
        if (!trackName.isNullOrBlank()) {
            currentTrackName = trackName
        }
        if (intent.hasExtra(EXTRA_IS_PLAYING)) {
            isPlaying = intent.getBooleanExtra(EXTRA_IS_PLAYING, isPlaying)
        }
        if (intent.hasExtra(EXTRA_VOLUME)) {
            val volObj = intent.extras?.get(EXTRA_VOLUME)
            if (volObj is Number) {
                currentVolume = volObj.toFloat()
            }
        }
        if (intent.hasExtra(EXTRA_PLAY_AUDIO)) {
            isNativeAudioEnabled = intent.getBooleanExtra(EXTRA_PLAY_AUDIO, isNativeAudioEnabled)
        }
        parseTimerExtras(intent)
    }

    @Suppress("DEPRECATION")
    private fun parseTimerExtras(intent: Intent) {
        val phase = intent.getStringExtra(EXTRA_PHASE)
        if (!phase.isNullOrBlank()) {
            currentPhase = phase
        }
        if (intent.hasExtra(EXTRA_REMAINING_SECONDS)) {
            val secObj = intent.extras?.get(EXTRA_REMAINING_SECONDS)
            if (secObj is Number) {
                currentRemainingSeconds = secObj.toDouble()
            }
        }
        if (intent.hasExtra(EXTRA_CYCLE_COUNT)) {
            currentCycleCount = intent.getIntExtra(EXTRA_CYCLE_COUNT, currentCycleCount)
        }
    }

    @Suppress("DEPRECATION")
    private fun initMediaSession() {
        mediaSession = MediaSessionCompat(this, "ZYKL_MEDIA_SESSION").apply {
            setFlags(
                MediaSessionCompat.FLAG_HANDLES_MEDIA_BUTTONS or
                        MediaSessionCompat.FLAG_HANDLES_TRANSPORT_CONTROLS
            )
            setCallback(object : MediaSessionCompat.Callback() {
                override fun onPlay() {
                    if (requestAudioFocus()) {
                        isPlaying = true
                        handleMediaControl("play")
                        resumeAudio()
                    } else {
                        isPlaying = false
                    }
                    updatePlaybackState()
                    updateNotification()
                }

                override fun onPause() {
                    isPlaying = false
                    resumeOnFocusGain = false
                    handleMediaControl("pause")
                    pauseAudio()
                    updatePlaybackState()
                    updateNotification()
                }

                override fun onSkipToNext() {
                    handleMediaControl("next")
                }

                override fun onSkipToPrevious() {
                    handleMediaControl("previous")
                }

                override fun onStop() {
                    handleMediaControl("stop")
                    stopServiceAndNotification()
                }
            })
            isActive = true
        }
    }

    /**
     * Audio focus refused (a phone or VoIP call is on): the soundscape must not play into it. Flutter already started
     * it, so tell Flutter to lift the needle, which stops it.
     */
    private fun refuseToPlay() {
        isPlaying = false
        resumeOnFocusGain = false
        handleMediaControl("pause")
    }

    /** Headphones unplugged / Bluetooth gone: pause instead of carrying on through the speaker. */
    private val noisyReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            if (intent.action != AudioManager.ACTION_AUDIO_BECOMING_NOISY || !isPlaying) return
            isPlaying = false
            resumeOnFocusGain = false
            pausedByTransientLoss = false
            handleMediaControl("pause")
            pauseAudio()
            updatePlaybackState()
            updateNotification()
        }
    }

    private fun handleMediaControl(action: String) {
        mediaControlListener?.invoke(action)

        val broadcastIntent = Intent(ACTION_MEDIA_CONTROL).apply {
            putExtra(EXTRA_CONTROL_ACTION, action)
            setPackage(packageName)
        }
        sendBroadcast(broadcastIntent)
    }

    private fun updatePlaybackState() {
        val actions = PlaybackStateCompat.ACTION_PLAY or
                PlaybackStateCompat.ACTION_PAUSE or
                PlaybackStateCompat.ACTION_PLAY_PAUSE or
                PlaybackStateCompat.ACTION_SKIP_TO_NEXT or
                PlaybackStateCompat.ACTION_SKIP_TO_PREVIOUS or
                PlaybackStateCompat.ACTION_STOP

        val state = if (isPlaying) {
            PlaybackStateCompat.STATE_PLAYING
        } else {
            PlaybackStateCompat.STATE_PAUSED
        }

        val playbackState = PlaybackStateCompat.Builder()
            .setActions(actions)
            .setState(state, PlaybackStateCompat.PLAYBACK_POSITION_UNKNOWN, 1.0f)
            .build()

        mediaSession.setPlaybackState(playbackState)

        val metadata = MediaMetadataCompat.Builder()
            .putString(MediaMetadataCompat.METADATA_KEY_TITLE, formatTrackTitle(currentTrackName))
            .putString(MediaMetadataCompat.METADATA_KEY_ARTIST, "ZYKL · POMODORO FOCUS TIMER")
            .putString(MediaMetadataCompat.METADATA_KEY_ALBUM, "ZYKL TP-01 SOUNDSCAPE")
            .putBitmap(MediaMetadataCompat.METADATA_KEY_ALBUM_ART, getVinylBitmap())
            .build()
        mediaSession.setMetadata(metadata)
    }

    private fun buildNotification(): Notification {
        val playPauseIcon = if (isPlaying) R.drawable.ic_media_pause else R.drawable.ic_media_play

        val prevPendingIntent = createActionPendingIntent(ACTION_PREV, 101)
        val playPausePendingIntent = createActionPendingIntent(ACTION_PLAY_PAUSE, 102)
        val nextPendingIntent = createActionPendingIntent(ACTION_NEXT, 103)

        val openAppIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val contentPendingIntent = PendingIntent.getActivity(
            this,
            0,
            openAppIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0)
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_takt_timer)
            .setLargeIcon(getVinylBitmap())
            .setContentTitle(formatTrackTitle(currentTrackName))
            .setContentText(formatTelemetryText(currentPhase, currentRemainingSeconds, currentCycleCount))
            .setSubText("ZYKL · POMODORO FOCUS TIMER")
            .setColor(0xFFFF9E00.toInt())
            .setContentIntent(contentPendingIntent)
            .setOngoing(isPlaying)
            .setShowWhen(false)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setCategory(NotificationCompat.CATEGORY_TRANSPORT)
            .setStyle(
                MediaStyle()
                    .setMediaSession(mediaSession.sessionToken)
                    .setShowActionsInCompactView(0, 1, 2)
            )
            .addAction(R.drawable.ic_media_prev, "Previous", prevPendingIntent)
            .addAction(playPauseIcon, "Play/Pause", playPausePendingIntent)
            .addAction(R.drawable.ic_media_next, "Next", nextPendingIntent)
            .build()
    }

    private fun updateNotification() {
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
        manager?.notify(NOTIFICATION_ID, buildNotification())
    }

    private fun createActionPendingIntent(action: String, requestCode: Int): PendingIntent {
        val intent = Intent(this, MediaNotificationService::class.java).apply {
            this.action = action
        }
        val flags = PendingIntent.FLAG_UPDATE_CURRENT or
                (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0)
        return PendingIntent.getService(this, requestCode, intent, flags)
    }

    private fun formatTrackTitle(name: String): String {
        val clean = name.trim()
        val upper = if (clean.isEmpty()) "LO-FI RAIN" else clean.uppercase()
        return if (upper.contains("33⅓") || upper.contains("RPM")) {
            upper
        } else {
            "$upper · 33⅓ RPM"
        }
    }

    private fun formatTelemetryText(phase: String, remainingSeconds: Double, cycleCount: Int): String {
        val phaseLabel = when (phase.lowercase()) {
            "shortbreak" -> "SHORT BRK"
            "longbreak" -> "LONG BRK"
            else -> "FOCUS"
        }
        // Minutes left (rounded up), not mm:ss: the timer's own notification already runs an exact system
        // chronometer, so this one is re-posted once a minute instead of every second.
        val totalSecs = remainingSeconds.toInt().coerceAtLeast(0)
        val timeStr = "${(totalSecs + 59) / 60} MIN"
        val cycleStr = "CYCLE ${cycleCount.coerceIn(1, 4)}/4"
        return "ZYKL TP-01 // $phaseLabel $timeStr · $cycleStr"
    }

    private fun getVinylBitmap(): Bitmap {
        val existing = vinylDiscBitmap
        if (existing != null && !existing.isRecycled) {
            return existing
        }
        val generated = createVinylDiscBitmap(128)
        vinylDiscBitmap = generated
        return generated
    }

    private fun createVinylDiscBitmap(size: Int = 128): Bitmap {
        val bitmap = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        val center = size / 2f
        val outerRadius = size / 2f - 2f

        val paint = Paint(Paint.ANTI_ALIAS_FLAG)

        // 1. Vinyl Base Outer Disc (Dark matte slate)
        paint.style = Paint.Style.FILL
        paint.color = Color.parseColor("#18181A")
        canvas.drawCircle(center, center, outerRadius, paint)

        // 2. Vinyl Edge Rim
        paint.style = Paint.Style.STROKE
        paint.strokeWidth = 2f
        paint.color = Color.parseColor("#2E2E33")
        canvas.drawCircle(center, center, outerRadius, paint)

        // 3. Concentric Vinyl Grooves (Micro sound tracks)
        paint.style = Paint.Style.STROKE
        paint.strokeWidth = 1f
        val grooveRadii = floatArrayOf(
            outerRadius * 0.88f,
            outerRadius * 0.82f,
            outerRadius * 0.76f,
            outerRadius * 0.70f,
            outerRadius * 0.64f,
            outerRadius * 0.58f,
            outerRadius * 0.52f,
            outerRadius * 0.46f
        )
        for (i in grooveRadii.indices) {
            paint.color = if (i % 2 == 0) Color.parseColor("#242428") else Color.parseColor("#1E1E22")
            canvas.drawCircle(center, center, grooveRadii[i], paint)
        }

        // 4. Center Record Label (Monastic matte plate)
        paint.style = Paint.Style.FILL
        paint.color = Color.parseColor("#222226")
        val labelRadius = outerRadius * 0.38f
        canvas.drawCircle(center, center, labelRadius, paint)

        paint.style = Paint.Style.STROKE
        paint.strokeWidth = 1.5f
        paint.color = Color.parseColor("#3A3A40")
        canvas.drawCircle(center, center, labelRadius, paint)

        // 5. Dieter Rams Amber Spindle / Center Pip (#FF9E00)
        paint.style = Paint.Style.FILL
        paint.color = 0xFFFF9E00.toInt()
        val amberPipRadius = outerRadius * 0.14f
        canvas.drawCircle(center, center, amberPipRadius, paint)

        // 6. Spindle Center Hole (Inner dark aperture)
        paint.color = Color.parseColor("#0E0E10")
        val centerHoleRadius = outerRadius * 0.05f
        canvas.drawCircle(center, center, centerHoleRadius, paint)

        return bitmap
    }

    private fun requestAudioFocus(): Boolean {
        val am = audioManager ?: return false
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val playbackAttributes = AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_MEDIA)
                .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                .build()
            val request = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN)
                .setAudioAttributes(playbackAttributes)
                .setAcceptsDelayedFocusGain(false)
                .setOnAudioFocusChangeListener(audioFocusChangeListener)
                .build()
            audioFocusRequest = request
            am.requestAudioFocus(request) == AudioManager.AUDIOFOCUS_REQUEST_GRANTED
        } else {
            @Suppress("DEPRECATION")
            am.requestAudioFocus(
                audioFocusChangeListener,
                AudioManager.STREAM_MUSIC,
                AudioManager.AUDIOFOCUS_GAIN
            ) == AudioManager.AUDIOFOCUS_REQUEST_GRANTED
        }
    }

    private fun abandonAudioFocus() {
        val am = audioManager ?: return
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            audioFocusRequest?.let {
                am.abandonAudioFocusRequest(it)
            }
            audioFocusRequest = null
        } else {
            @Suppress("DEPRECATION")
            am.abandonAudioFocus(audioFocusChangeListener)
        }
    }

    private fun getAssetPath(trackIndex: Int): String {
        return when (trackIndex) {
            0 -> "vinyl_lofi_rain.ogg"
            1 -> "vinyl_brown_noise.ogg"
            2 -> "vinyl_library.ogg"
            3 -> "vinyl_kyoto_bamboo.ogg"
            4 -> "vinyl_campfire.ogg"
            5 -> "vinyl_nordic_pines.ogg"
            6 -> "vinyl_warm_tape.ogg"
            7 -> "vinyl_rhodes_velvet.ogg"
            8 -> "vinyl_acoustic_guitar.ogg"
            9 -> "vinyl_ambient_drift.ogg"
            10 -> "vinyl_felt_piano_solo.ogg"
            11 -> "vinyl_modular_clockwork.ogg"
            else -> "vinyl_lofi_rain.ogg"
        }
    }

    private fun openAssetFd(fileName: String): AssetFileDescriptor {
        return try {
            assets.openFd("flutter_assets/assets/audio/$fileName")
        } catch (_: Exception) {
            assets.openFd("assets/audio/$fileName")
        }
    }

    private fun playAudioTrack(index: Int, vol: Float) {
        try {
            mediaPlayer?.stop()
            mediaPlayer?.release()
            mediaPlayer = null

            val fileName = getAssetPath(index)
            openAssetFd(fileName).use { afd ->
                mediaPlayer = MediaPlayer().apply {
                    setAudioAttributes(
                        AudioAttributes.Builder()
                            .setUsage(AudioAttributes.USAGE_MEDIA)
                            .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                            .build()
                    )
                    setDataSource(afd.fileDescriptor, afd.startOffset, afd.length)
                    isLooping = true
                    val clamped = vol.coerceIn(0f, 1f)
                    setVolume(clamped, clamped)
                    prepare()
                    start()
                }
            }
        } catch (_: Exception) {}
    }

    private fun pauseAudio() {
        try {
            if (mediaPlayer?.isPlaying == true) {
                mediaPlayer?.pause()
            }
        } catch (_: Exception) {}
    }

    private fun resumeAudio() {
        try {
            if (isNativeAudioEnabled) {
                if (mediaPlayer == null) {
                    playAudioTrack(currentTrackIndex, currentVolume)
                } else if (mediaPlayer?.isPlaying == false) {
                    mediaPlayer?.start()
                }
            }
        } catch (_: Exception) {}
    }

    private fun setAudioVolume(vol: Float) {
        try {
            val clamped = vol.coerceIn(0f, 1f)
            mediaPlayer?.setVolume(clamped, clamped)
        } catch (_: Exception) {}
    }

    private fun releaseAudio() {
        try {
            if (mediaPlayer?.isPlaying == true) {
                mediaPlayer?.stop()
            }
            mediaPlayer?.release()
        } catch (_: Exception) {}
        mediaPlayer = null
    }

    private fun stopServiceAndNotification() {
        abandonAudioFocus()
        releaseAudio()
        stopForeground(STOP_FOREGROUND_REMOVE)
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
        manager?.cancel(NOTIFICATION_ID)
        stopSelf()
    }

    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

            val mediaChannel = NotificationChannel(
                CHANNEL_ID,
                "ZYKL Media & Focus Controller",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Background vinyl soundscape and Pomodoro telemetry controller"
                setSound(null, null)
                enableVibration(false)
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            }

            manager.createNotificationChannel(mediaChannel)
        }
    }

    override fun onTaskRemoved(rootIntent: Intent?) {
        stopServiceAndNotification()
        super.onTaskRemoved(rootIntent)
    }

    override fun onDestroy() {
        try { unregisterReceiver(noisyReceiver) } catch (_: Exception) {}
        abandonAudioFocus()
        releaseAudio()
        stopForeground(STOP_FOREGROUND_REMOVE)
        try {
            mediaSession.isActive = false
            mediaSession.release()
        } catch (_: Exception) {}
        vinylDiscBitmap = null
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
        manager?.cancel(NOTIFICATION_ID)
        super.onDestroy()
    }
}
