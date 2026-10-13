package com.zykl.app

import android.app.Notification
import android.app.AlarmManager
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.IntentFilter
import android.content.BroadcastReceiver
import android.content.Intent
import android.content.pm.ServiceInfo
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import android.os.SystemClock
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat

class TimerForegroundService : Service() {
    companion object {
        const val CHANNEL_TIMER_ID = TimerNotifications.CHANNEL_TIMER_ID
        const val CHANNEL_ALERT_ID = TimerNotifications.CHANNEL_ALERT_ID
        const val NOTIFICATION_ID = 1001
        const val ALERT_NOTIFICATION_ID = 1002

        /** How long the service and CPU stay up for the finish chime: longest chime (zen gong, 4.2 s) plus MediaPlayer
         *  prepare time and a margin. The chime's completion listener ends it earlier for the short ones. */
        private const val COMPLETION_HOLD_MS = 6500L

        const val ACTION_START = "ACTION_START"
        const val ACTION_STOP = "ACTION_STOP"
        /** Native pause (notification PAUSE while the app is gone): stops the countdown, posts the paused card. */
        const val ACTION_PAUSE = "ACTION_PAUSE"
        /** Fired by AlarmManager at the absolute end time (works in Doze / screen off). */
        const val ACTION_COMPLETE = "ACTION_COMPLETE"

        const val EXTRA_REMAINING_SECONDS = "EXTRA_REMAINING_SECONDS"
        const val EXTRA_TARGET_MINUTES = "EXTRA_TARGET_MINUTES"
        const val EXTRA_PHASE = "EXTRA_PHASE"
        const val EXTRA_CYCLE_COUNT = "EXTRA_CYCLE_COUNT"
        const val EXTRA_PROFILE_NAME = "EXTRA_PROFILE_NAME"
        const val EXTRA_ALARM_CHIME_ID = "EXTRA_ALARM_CHIME_ID"
        const val EXTRA_END_AT_EPOCH = "EXTRA_END_AT_EPOCH"
        /** The user's "auto-start next phase": Flutter starts the next phase as soon as this one ends. */
        const val EXTRA_AUTO_START_NEXT = "EXTRA_AUTO_START_NEXT"
        /** Identifies one countdown (sent by Flutter with START, generated here otherwise). Echoed in the status
         *  query and carried by the completion alarm, so a late answer about a previous phase is recognised. */
        const val EXTRA_SESSION_ID = "EXTRA_SESSION_ID"
        private const val REQUEST_COMPLETE = 2001
        const val ACTION_REFRESH_NOTIFICATION = "ACTION_REFRESH_NOTIFICATION"

        /**
         * Session deadline on the boot-time clock (`SystemClock.elapsedRealtime`),
         * 0 when no session was started in this process. Kept after completion so
         * Flutter can tell "finished while backgrounded" from "never started".
         */
        @Volatile
        var deadlineElapsed: Long = 0L
            private set

        @Volatile
        var isCountingDown: Boolean = false
            private set

        /** Session id of the latest countdown (kept after it finishes, like [deadlineElapsed]); 0 = none yet. */
        @Volatile
        var activeSessionId: Long = 0L
            private set

        /** Focus sessions that finished while Flutter was not running (app closed). */
        private const val PREFS_PENDING = "zykl_pending_sessions"
        private const val KEY_PENDING = "sessions"

        /** Returns and clears "startedAtEpochMs,targetMinutes" entries. */
        fun takePendingSessions(context: Context): List<String> {
            val prefs = context.getSharedPreferences(PREFS_PENDING, Context.MODE_PRIVATE)
            val raw = prefs.getString(KEY_PENDING, "") ?: ""
            prefs.edit().remove(KEY_PENDING).apply()
            return raw.split(';').filter { it.isNotBlank() }
        }

        private fun addPendingSession(context: Context, startedAt: Long, targetMinutes: Int) {
            val prefs = context.getSharedPreferences(PREFS_PENDING, Context.MODE_PRIVATE)
            val raw = prefs.getString(KEY_PENDING, "") ?: ""
            prefs.edit().putString(KEY_PENDING, "$raw$startedAt,$targetMinutes;").apply()
        }
    }

    private val handler = Handler(Looper.getMainLooper())
    private var completionRunnable: Runnable? = null
    private var widgetTickRunnable: Runnable? = null
    private var wakeLock: PowerManager.WakeLock? = null
    private var bellPlayer: MediaPlayer? = null
    private var activeAlarmChimeId: String = "braunBell"
    private var activeTargetMinutes: Int = 25
    private var activePhase: String = "focus"
    private var activeCycleCount: Int = 1
    private var activeProfileName: String = "CLASSIC 25/5"
    private var activeAutoStartNext: Boolean = false
    /** End-time (epoch ms) of the last session already completed; makes completion idempotent. */
    private var lastCompletedEndAt: Long = 0L
    private var ongoingNotification: Notification? = null
    /** The running countdown's builder, re-posted each minute with the minutes left (chip text + progress bar). */
    private var ongoingBuilder: NotificationCompat.Builder? = null
    private var ongoingEndAt: Long = 0L
    private var ongoingTotalSeconds: Int = 0
    private var screenOnReceiver: BroadcastReceiver? = null

    /**
     * Keeps the home-screen widgets current while a phase runs. The Focus Strip shows a Chronometer that counts
     * down by itself (KEY_END_ELAPSED), and the dial widget shows minutes, so this only runs on each minute
     * boundary (it used to redraw a 320x320 dial bitmap and write prefs every second), plus once when the screen
     * turns on, so a dial never shows a stale minute after the CPU slept.
     */
    private fun startWidgetTick(targetEndTime: Long, targetMinutes: Int, phase: String) {
        stopWidgetTick()
        val status = if (phase == "shortBreak" || phase == "longBreak") "BREAK" else "FOCUS"
        val endElapsed = SystemClock.elapsedRealtime() + (targetEndTime - System.currentTimeMillis()).coerceAtLeast(0)
        var firstRun = true
        val tickRunnable = object : Runnable {
            override fun run() {
                val now = System.currentTimeMillis()
                val remainingMillis = (targetEndTime - now).coerceAtLeast(0)
                val remainingSecs = (remainingMillis / 1000).toInt()

                val prefs = getSharedPreferences(TaktAppWidgetProvider.PREFS_NAME, Context.MODE_PRIVATE)
                prefs.edit()
                    .putString(TaktAppWidgetProvider.KEY_STATUS, status)
                    .putInt(TaktAppWidgetProvider.KEY_REMAINING_SECONDS, remainingSecs)
                    .putInt(TaktAppWidgetProvider.KEY_TARGET_MINUTES, targetMinutes)
                    .putLong(TaktAppWidgetProvider.KEY_END_ELAPSED, endElapsed)
                    .apply()

                try {
                    TaktAnalogDialWidgetProvider.updateAllWidgets(this@TimerForegroundService)
                    if (firstRun) {
                        // Status change only: the strip's Chronometer ticks by itself, the console has no countdown.
                        TaktFocusStripWidgetProvider.updateAllWidgets(this@TimerForegroundService)
                        TaktAppWidgetProvider.updateAllWidgets(this@TimerForegroundService)
                    }
                } catch (_: Throwable) {}
                firstRun = false
                refreshRunningNotification()

                if (remainingSecs > 0) {
                    // Next minute boundary of the remaining time (+20 ms so the minute has flipped).
                    val toNextMinute = (remainingMillis % 60_000L).let { if (it == 0L) 60_000L else it }
                    handler.postDelayed(this, toNextMinute + 20L)
                }
            }
        }
        widgetTickRunnable = tickRunnable
        handler.post(tickRunnable)
        screenOnReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context, intent: Intent) {
                handler.removeCallbacks(tickRunnable)
                handler.post(tickRunnable)
            }
        }.also {
            ContextCompat.registerReceiver(this, it, IntentFilter(Intent.ACTION_SCREEN_ON), ContextCompat.RECEIVER_NOT_EXPORTED)
        }
    }

    private fun stopWidgetTick() {
        widgetTickRunnable?.let {
            handler.removeCallbacks(it)
            widgetTickRunnable = null
        }
        screenOnReceiver?.let {
            try { unregisterReceiver(it) } catch (_: Exception) {}
            screenOnReceiver = null
        }
        // Not running any more: the strip's Chronometer must not keep counting.
        getSharedPreferences(TaktAppWidgetProvider.PREFS_NAME, Context.MODE_PRIVATE).edit()
            .putLong(TaktAppWidgetProvider.KEY_END_ELAPSED, 0L)
            .apply()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        createNotificationChannels()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> {
                val remainingSeconds = intent.getDoubleExtra(EXTRA_REMAINING_SECONDS, 0.0)
                val targetMinutes = intent.getIntExtra(EXTRA_TARGET_MINUTES, 25)
                val phase = intent.getStringExtra(EXTRA_PHASE) ?: "focus"
                val cycleCount = intent.getIntExtra(EXTRA_CYCLE_COUNT, 1)
                val profileName = intent.getStringExtra(EXTRA_PROFILE_NAME) ?: "CLASSIC 25/5"
                val alarmChimeId = intent.getStringExtra(EXTRA_ALARM_CHIME_ID) ?: "braunBell"
                activeAutoStartNext = intent.getBooleanExtra(EXTRA_AUTO_START_NEXT, false)
                activeSessionId = intent.getLongExtra(EXTRA_SESSION_ID, 0L)
                    .takeIf { it != 0L } ?: SystemClock.elapsedRealtimeNanos()

                startCountdown(remainingSeconds, targetMinutes, phase, cycleCount, profileName, alarmChimeId)
            }
            ACTION_STOP -> {
                stopCountdown()
            }
            ACTION_PAUSE -> {
                pauseCountdown()
            }
            ACTION_REFRESH_NOTIFICATION -> {
                // Re-post after POST_NOTIFICATIONS was granted mid-session.
                val n = ongoingNotification
                if (isCountingDown && n != null) {
                    (getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager)
                        ?.notify(NOTIFICATION_ID, n)
                }
            }
            ACTION_COMPLETE -> {
                // A completion alarm of an earlier phase that arrives after the next phase started (auto-start, or
                // Dart finished first) must not end the new countdown.
                val sessionId = intent.getLongExtra(EXTRA_SESSION_ID, 0L)
                if (isCountingDown && sessionId != 0L && sessionId != activeSessionId) {
                    return START_NOT_STICKY
                }
                activeAlarmChimeId = intent.getStringExtra(EXTRA_ALARM_CHIME_ID) ?: activeAlarmChimeId
                activeTargetMinutes = intent.getIntExtra(EXTRA_TARGET_MINUTES, activeTargetMinutes)
                val endAt = intent.getLongExtra(EXTRA_END_AT_EPOCH, 0L)
                onTimerFinished(intent.getStringExtra(EXTRA_PHASE) ?: "focus", endAt)
            }
        }
        return START_NOT_STICKY
    }

    private fun startCountdown(
        remainingSeconds: Double,
        targetMinutes: Int,
        phase: String,
        cycleCount: Int,
        profileName: String,
        alarmChimeId: String
    ) {
        cancelScheduledCompletion()
        cancelExactCompletion()
        activeAlarmChimeId = alarmChimeId
        activeTargetMinutes = targetMinutes
        activePhase = phase
        activeCycleCount = cycleCount
        activeProfileName = profileName

        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
        notificationManager?.cancel(ALERT_NOTIFICATION_ID)
        TimerNotifications.cancelPaused(this)

        val remainingMillis = (remainingSeconds * 1000).toLong()
        val targetTime = System.currentTimeMillis() + remainingMillis
        deadlineElapsed = SystemClock.elapsedRealtime() + remainingMillis
        isCountingDown = true

        val title = TimerNotifications.title(phase, cycleCount)
        val content = "$targetMinutes MIN · $profileName"
        val pendingIntent = TimerNotifications.openAppIntent(this, 0)

        // Standard style, ongoing, not colorized: promotable to an Android 16 Live Update (chip + lock screen card).
        val builder = NotificationCompat.Builder(this, CHANNEL_TIMER_ID)
            .setSmallIcon(R.drawable.ic_takt_timer)
            .setContentTitle(title)
            .setContentText(content)
            .setOngoing(true)
            .setSilent(true)
            .setOnlyAlertOnce(true)
            .setColor(TimerNotifications.ACCENT)
            .setShowWhen(true)
            .setUsesChronometer(true)
            .setChronometerCountDown(true)
            .setWhen(targetTime)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setContentIntent(pendingIntent)
            .setCategory(NotificationCompat.CATEGORY_PROGRESS)
        TimerNotifications.addRunningActions(this, builder)
        TimerNotifications.requestPromotion(builder)
        ongoingBuilder = builder
        ongoingEndAt = targetTime
        ongoingTotalSeconds = targetMinutes * 60
        val notification = buildRunningNotification()
        ongoingNotification = notification

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            startForeground(
                NOTIFICATION_ID,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE
            )
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }

        // Schedule completion. AlarmManager is the primary trigger: Handler
        // delays use uptime and stall while the CPU sleeps (screen off), so the
        // Handler is only a same-process fallback; onTimerFinished is idempotent.
        if (remainingMillis > 0) {
            scheduleExactCompletion(targetTime, phase, alarmChimeId)
            val runnable = Runnable {
                onTimerFinished(phase, targetTime)
            }
            completionRunnable = runnable
            handler.postDelayed(runnable, remainingMillis)
        }

        // Start live 1-second widget ticker so analog dial needle and focus strip tick continuously
        startWidgetTick(targetTime, targetMinutes, phase)
    }

    private fun completionPendingIntent(endAt: Long, phase: String, chimeId: String): PendingIntent {
        val intent = Intent(this, TimerForegroundService::class.java).apply {
            action = ACTION_COMPLETE
            putExtra(EXTRA_END_AT_EPOCH, endAt)
            putExtra(EXTRA_PHASE, phase)
            putExtra(EXTRA_ALARM_CHIME_ID, chimeId)
            putExtra(EXTRA_TARGET_MINUTES, activeTargetMinutes)
            putExtra(EXTRA_SESSION_ID, activeSessionId)
        }
        return PendingIntent.getService(
            this,
            REQUEST_COMPLETE,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    private fun scheduleExactCompletion(endAt: Long, phase: String, chimeId: String) {
        try {
            val am = getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
            val pi = completionPendingIntent(endAt, phase, chimeId)
            // Trigger on the boot-time clock: immune to wall-clock changes and
            // keeps counting through deep sleep. endAt (epoch) stays the
            // session identity and drives the widgets/notification.
            val triggerAt = SystemClock.elapsedRealtime() +
                (endAt - System.currentTimeMillis()).coerceAtLeast(0L)
            val canExact = Build.VERSION.SDK_INT < Build.VERSION_CODES.S || am.canScheduleExactAlarms()
            if (canExact) {
                am.setExactAndAllowWhileIdle(AlarmManager.ELAPSED_REALTIME_WAKEUP, triggerAt, pi)
            } else {
                am.setAndAllowWhileIdle(AlarmManager.ELAPSED_REALTIME_WAKEUP, triggerAt, pi)
            }
        } catch (_: Exception) {}
    }

    private fun cancelExactCompletion() {
        try {
            val am = getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
            am.cancel(completionPendingIntent(0L, "focus", activeAlarmChimeId))
        } catch (_: Exception) {}
    }

    private fun onTimerFinished(phase: String, endAt: Long) {
        // Alarm and Handler both target the same end time; only the first wins.
        if (endAt != 0L && endAt == lastCompletedEndAt) return
        lastCompletedEndAt = endAt
        isCountingDown = false
        // Flutter records finished focus sessions itself (timer tick / resume
        // re-sync). If the activity is gone, the Dart side is gone too, so
        // keep the session here and Flutter imports it on next launch.
        if (phase == "focus" && MainActivity.activeInstance == null && endAt > 0L) {
            addPendingSession(this, endAt - activeTargetMinutes * 60_000L, activeTargetMinutes)
        }
        // Flutter alive: tell it now (its own clock may be asleep) so it advances the phase, and with auto-start on
        // starts the next one in this service.
        val handOff = activeAutoStartNext && MainActivity.activeInstance != null
        MainActivity.sendWidgetAction("nativePhaseFinished")
        cancelScheduledCompletion()
        cancelExactCompletion()
        stopWidgetTick()
        val prefs = getSharedPreferences(TaktAppWidgetProvider.PREFS_NAME, Context.MODE_PRIVATE)
        val targetMinutes = prefs.getInt(TaktAppWidgetProvider.KEY_TARGET_MINUTES, 25)
        prefs.edit()
            .putString(TaktAppWidgetProvider.KEY_STATUS, "STANDBY")
            .putInt(TaktAppWidgetProvider.KEY_REMAINING_SECONDS, targetMinutes * 60)
            .apply()

        try {
            TaktAnalogDialWidgetProvider.updateAllWidgets(this)
            TaktFocusStripWidgetProvider.updateAllWidgets(this)
            TaktAppWidgetProvider.updateAllWidgets(this)
        } catch (_: Throwable) {}

        // 1. Keep the CPU awake for the whole chime (the longest, zen gong, is 4.2 s)
        acquireTransientWakeLock()

        // 2. Trigger dual-tap mechanical haptics
        triggerMechanicalHaptics()

        // 3. Post alert notification
        val phaseLabel = when (phase) {
            "shortBreak" -> "SHORT BREAK"
            "longBreak" -> "LONG BREAK"
            else -> "FOCUS"
        }

        val openAppIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val pendingIntent = PendingIntent.getActivity(
            this,
            1,
            openAppIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0)
        )

        val alertNotif = NotificationCompat.Builder(this, CHANNEL_ALERT_ID)
            .setSmallIcon(R.drawable.ic_takt_timer)
            .setContentTitle("ZYKL · $phaseLabel COMPLETED")
            .setContentText(
                if (handOff) "Next phase starting." else "Standby active. Tap to enter console and begin next phase."
            )
            .setAutoCancel(true)
            .setColor(0xFFFF9E00.toInt())
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setContentIntent(pendingIntent)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .build()

        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.notify(ALERT_NOTIFICATION_ID, alertNotif)

        // 4. Dismiss ongoing countdown chronometer from notification shade. With a hand-off it stays until Flutter's
        //    START replaces it: a backgrounded app may not bring a stopped foreground service back.
        if (!handOff) stopForeground(STOP_FOREGROUND_REMOVE)

        // 5. Play selected gallery alarm chime unless Flutter in foreground already triggered playback
        if (MainActivity.shouldPlayAlarm()) {
            val fallbackTeardown = Runnable { finishIfIdle() }
            // Safety net only: the completion listener below stops the service as soon as the chime ends.
            // It must outlast the longest chime, or stopSelf() -> onDestroy() releases the player mid-ring.
            handler.postDelayed(fallbackTeardown, COMPLETION_HOLD_MS)

            playSelectedAlarm(activeAlarmChimeId) {
                handler.removeCallbacks(fallbackTeardown)
                finishIfIdle()
            }
        } else if (handOff) {
            handler.postDelayed({ finishIfIdle() }, COMPLETION_HOLD_MS)
        } else {
            // Already played by foreground Flutter activity; exit cleanly without duplicate audio
            stopSelf()
        }
    }

    /** Ends the service after a finished phase, unless the next phase already started in it (auto-start). */
    private fun finishIfIdle() {
        if (isCountingDown) return
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
    }

    /**
     * The running countdown. On Android 16 it also carries the minutes left as the status-chip text ("24m": some
     * launchers' islands show only that text, not the chronometer) and a progress bar of the session for the expanded
     * Live Update card. Both are refreshed on the minute tick (startWidgetTick).
     */
    private fun buildRunningNotification(): Notification {
        val compat = ongoingBuilder?.build() ?: throw IllegalStateException("no running notification")
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.BAKLAVA) return compat
        return try {
            val leftMillis = (ongoingEndAt - System.currentTimeMillis()).coerceAtLeast(0L)
            val leftMinutes = ((leftMillis + 59_999L) / 60_000L).toInt()
            val total = ongoingTotalSeconds.coerceAtLeast(1)
            val elapsed = (total - (leftMillis / 1000L).toInt()).coerceIn(0, total)
            Notification.Builder.recoverBuilder(this, compat)
                .setShortCriticalText("${leftMinutes}m")
                .setStyle(
                    Notification.ProgressStyle()
                        .setStyledByProgress(true)
                        .setProgressSegments(listOf(Notification.ProgressStyle.Segment(total).setColor(TimerNotifications.ACCENT)))
                        .setProgress(elapsed)
                )
                .build()
        } catch (_: Exception) {
            compat
        }
    }

    private fun refreshRunningNotification() {
        if (!isCountingDown || ongoingBuilder == null) return
        val notification = buildRunningNotification()
        ongoingNotification = notification
        try {
            (getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager)?.notify(NOTIFICATION_ID, notification)
        } catch (_: SecurityException) {}
    }

    /** Stops the countdown and keeps it on the lock screen as a paused card (RESUME starts it again). */
    private fun pauseCountdown() {
        val wasRunning = isCountingDown
        val remainingSeconds = ((deadlineElapsed - SystemClock.elapsedRealtime()) / 1000.0).coerceAtLeast(0.0)
        stopCountdown()
        if (wasRunning && remainingSeconds >= 1.0) {
            TimerNotifications.showPaused(
                this, remainingSeconds, activeTargetMinutes, activePhase, activeCycleCount, activeProfileName,
                activeAlarmChimeId
            )
        }
    }

    private fun stopCountdown() {
        isCountingDown = false
        deadlineElapsed = 0L
        ongoingNotification = null
        cancelScheduledCompletion()
        cancelExactCompletion()
        stopWidgetTick()
        stopForeground(STOP_FOREGROUND_REMOVE)
        // Never cut the finish chime: Flutter stops the service right after a phase ends, often while the chime that
        // phase started is still ringing. The chime's completion (or the hold timeout) ends the service instead.
        if (bellPlayer == null) stopSelf()

        val prefs = getSharedPreferences(TaktAppWidgetProvider.PREFS_NAME, Context.MODE_PRIVATE)
        val targetMinutes = prefs.getInt(TaktAppWidgetProvider.KEY_TARGET_MINUTES, 25)
        prefs.edit()
            .putString(TaktAppWidgetProvider.KEY_STATUS, "STANDBY")
            .putInt(TaktAppWidgetProvider.KEY_REMAINING_SECONDS, targetMinutes * 60)
            .apply()

        try {
            TaktAnalogDialWidgetProvider.updateAllWidgets(this)
            TaktFocusStripWidgetProvider.updateAllWidgets(this)
            TaktAppWidgetProvider.updateAllWidgets(this)
        } catch (_: Throwable) {}
    }

    private fun cancelScheduledCompletion() {
        completionRunnable?.let { handler.removeCallbacks(it) }
        completionRunnable = null
    }

    private fun getAlarmAssetPath(chimeId: String): String {
        return when (chimeId) {
            "braunBell" -> "flutter_assets/assets/audio/alarm_braun_bell.wav"
            "deskBell" -> "flutter_assets/assets/audio/alarm_desk_bell.wav"
            "tibetanBowl" -> "flutter_assets/assets/audio/alarm_tibetan_bowl.wav"
            "zenGong" -> "flutter_assets/assets/audio/alarm_zen_gong.wav"
            "tubularChime" -> "flutter_assets/assets/audio/alarm_tubular_chime.wav"
            else -> "flutter_assets/assets/audio/alarm_braun_bell.wav"
        }
    }

    private fun playSelectedAlarm(chimeId: String, onComplete: (() -> Unit)? = null) {
        try {
            bellPlayer?.release()
            val assetPath = getAlarmAssetPath(chimeId)
            assets.openFd(assetPath).use { afd ->
                bellPlayer = MediaPlayer().apply {
                    setAudioAttributes(
                        AudioAttributes.Builder()
                            .setUsage(AudioAttributes.USAGE_ALARM)
                            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                            .build()
                    )
                    setDataSource(afd.fileDescriptor, afd.startOffset, afd.length)
                    setWakeMode(applicationContext, PowerManager.PARTIAL_WAKE_LOCK)
                    setOnCompletionListener {
                        it.release()
                        bellPlayer = null
                        onComplete?.invoke()
                    }
                    setOnErrorListener { mp, _, _ ->
                        mp.release()
                        bellPlayer = null
                        onComplete?.invoke()
                        true
                    }
                    prepare()
                    start()
                }
            }
        } catch (_: Exception) {
            onComplete?.invoke()
        }
    }

    private fun triggerMechanicalHaptics() {
        try {
            val timings = longArrayOf(0, 120, 80, 120)
            val amplitudes = intArrayOf(0, 200, 0, 255)

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                val vibratorManager = getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as? VibratorManager
                vibratorManager?.defaultVibrator?.vibrate(
                    VibrationEffect.createWaveform(timings, amplitudes, -1)
                )
            } else {
                @Suppress("DEPRECATION")
                val vibrator = getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    vibrator?.vibrate(VibrationEffect.createWaveform(timings, amplitudes, -1))
                } else {
                    @Suppress("DEPRECATION")
                    vibrator?.vibrate(timings, -1)
                }
            }
        } catch (_: Exception) {}
    }

    private fun acquireTransientWakeLock() {
        try {
            val pm = getSystemService(Context.POWER_SERVICE) as? PowerManager
            wakeLock = pm?.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "TaktDesk::CompletionWakeLock")
            wakeLock?.acquire(COMPLETION_HOLD_MS)
        } catch (_: Exception) {}
    }

    private fun createNotificationChannels() {
        TimerNotifications.createChannels(this)
    }

    override fun onDestroy() {
        cancelScheduledCompletion()
        stopWidgetTick()
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
        manager?.cancel(NOTIFICATION_ID)
        bellPlayer?.release()
        bellPlayer = null
        wakeLock?.let {
            if (it.isHeld) it.release()
        }
        wakeLock = null
        super.onDestroy()
    }
}
