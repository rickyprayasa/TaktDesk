package com.zykl.app

import android.app.Notification
import android.app.NotificationChannel
import android.app.AlarmManager
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
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

class TimerForegroundService : Service() {
    companion object {
        const val CHANNEL_TIMER_ID = "takt_desk_timer_channel"
        const val CHANNEL_ALERT_ID = "takt_desk_alert_channel"
        const val NOTIFICATION_ID = 1001
        const val ALERT_NOTIFICATION_ID = 1002

        const val ACTION_START = "ACTION_START"
        const val ACTION_STOP = "ACTION_STOP"
        /** Fired by AlarmManager at the absolute end time (works in Doze / screen off). */
        const val ACTION_COMPLETE = "ACTION_COMPLETE"

        const val EXTRA_REMAINING_SECONDS = "EXTRA_REMAINING_SECONDS"
        const val EXTRA_TARGET_MINUTES = "EXTRA_TARGET_MINUTES"
        const val EXTRA_PHASE = "EXTRA_PHASE"
        const val EXTRA_CYCLE_COUNT = "EXTRA_CYCLE_COUNT"
        const val EXTRA_PROFILE_NAME = "EXTRA_PROFILE_NAME"
        const val EXTRA_ALARM_CHIME_ID = "EXTRA_ALARM_CHIME_ID"
        const val EXTRA_END_AT_EPOCH = "EXTRA_END_AT_EPOCH"
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
    /** End-time (epoch ms) of the last session already completed; makes completion idempotent. */
    private var lastCompletedEndAt: Long = 0L
    private var ongoingNotification: Notification? = null

    private fun startWidgetTick(targetEndTime: Long, targetMinutes: Int, phase: String) {
        stopWidgetTick()
        val status = if (phase == "shortBreak" || phase == "longBreak") "BREAK" else "FOCUS"
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
                    .apply()

                try {
                    TaktAnalogDialWidgetProvider.updateAllWidgets(this@TimerForegroundService)
                    TaktFocusStripWidgetProvider.updateAllWidgets(this@TimerForegroundService)
                    TaktAppWidgetProvider.updateAllWidgets(this@TimerForegroundService)
                } catch (_: Throwable) {}

                if (remainingSecs > 0) {
                    handler.postDelayed(this, 1000L)
                }
            }
        }
        widgetTickRunnable = tickRunnable
        handler.post(tickRunnable)
    }

    private fun stopWidgetTick() {
        widgetTickRunnable?.let {
            handler.removeCallbacks(it)
            widgetTickRunnable = null
        }
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

                startCountdown(remainingSeconds, targetMinutes, phase, cycleCount, profileName, alarmChimeId)
            }
            ACTION_STOP -> {
                stopCountdown()
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

        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
        notificationManager?.cancel(ALERT_NOTIFICATION_ID)

        val remainingMillis = (remainingSeconds * 1000).toLong()
        val targetTime = System.currentTimeMillis() + remainingMillis
        deadlineElapsed = SystemClock.elapsedRealtime() + remainingMillis
        isCountingDown = true

        val title = formatTitle(phase, cycleCount)
        val content = "$targetMinutes MIN · $profileName"

        val openAppIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            openAppIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0)
        )

        val notification = NotificationCompat.Builder(this, CHANNEL_TIMER_ID)
            .setSmallIcon(R.drawable.ic_takt_timer)
            .setContentTitle(title)
            .setContentText(content)
            .setOngoing(true)
            .setColor(0xFFFF9E00.toInt())
            .setShowWhen(true)
            .setUsesChronometer(true)
            .setChronometerCountDown(true)
            .setWhen(targetTime)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setContentIntent(pendingIntent)
            .setCategory(NotificationCompat.CATEGORY_PROGRESS)
            .build()
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

        // 1. Acquire temporary 3.5-second wakelock to play bell sound
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
            .setContentText("Standby active. Tap to enter console and begin next phase.")
            .setAutoCancel(true)
            .setColor(0xFFFF9E00.toInt())
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setContentIntent(pendingIntent)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .build()

        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.notify(ALERT_NOTIFICATION_ID, alertNotif)

        // 4. Dismiss ongoing countdown chronometer from notification shade
        stopForeground(STOP_FOREGROUND_REMOVE)

        // 5. Play selected gallery alarm chime unless Flutter in foreground already triggered playback
        if (MainActivity.shouldPlayAlarm()) {
            val fallbackTeardown = Runnable {
                stopSelf()
            }
            handler.postDelayed(fallbackTeardown, 3500)

            playSelectedAlarm(activeAlarmChimeId) {
                handler.removeCallbacks(fallbackTeardown)
                stopSelf()
            }
        } else {
            // Already played by foreground Flutter activity; exit cleanly without duplicate audio
            stopSelf()
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
        stopSelf()

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

    private fun formatTitle(phase: String, cycleCount: Int): String {
        return when (phase) {
            "shortBreak" -> "ZYKL · SHORT BRK"
            "longBreak" -> "ZYKL · LONG BRK"
            else -> "ZYKL · FOCUS (CYCLE $cycleCount/4)"
        }
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
            wakeLock?.acquire(3500)
        } catch (_: Exception) {}
    }

    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

            val timerChannel = NotificationChannel(
                CHANNEL_TIMER_ID,
                "ZYKL Active Timer",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Live analog timer telemetry on Lockscreen and Always-On Display"
                setSound(null, null)
                enableVibration(false)
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            }

            val alertChannel = NotificationChannel(
                CHANNEL_ALERT_ID,
                "ZYKL Session Alerts",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Pomodoro focus and break interval completion alarms"
                enableVibration(true)
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            }

            manager.createNotificationChannel(timerChannel)
            manager.createNotificationChannel(alertChannel)
        }
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
