package com.zykl.app

import android.app.Notification
import android.app.NotificationChannel
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

        const val EXTRA_REMAINING_SECONDS = "EXTRA_REMAINING_SECONDS"
        const val EXTRA_TARGET_MINUTES = "EXTRA_TARGET_MINUTES"
        const val EXTRA_PHASE = "EXTRA_PHASE"
        const val EXTRA_CYCLE_COUNT = "EXTRA_CYCLE_COUNT"
        const val EXTRA_PROFILE_NAME = "EXTRA_PROFILE_NAME"
    }

    private val handler = Handler(Looper.getMainLooper())
    private var completionRunnable: Runnable? = null
    private var wakeLock: PowerManager.WakeLock? = null
    private var bellPlayer: MediaPlayer? = null

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

                startCountdown(remainingSeconds, targetMinutes, phase, cycleCount, profileName)
            }
            ACTION_STOP -> {
                stopCountdown()
            }
        }
        return START_NOT_STICKY
    }

    private fun startCountdown(
        remainingSeconds: Double,
        targetMinutes: Int,
        phase: String,
        cycleCount: Int,
        profileName: String
    ) {
        cancelScheduledCompletion()

        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
        notificationManager?.cancel(ALERT_NOTIFICATION_ID)

        val remainingMillis = (remainingSeconds * 1000).toLong()
        val targetTime = System.currentTimeMillis() + remainingMillis

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

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            startForeground(
                NOTIFICATION_ID,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE
            )
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }

        // Schedule completion alarm
        if (remainingMillis > 0) {
            val runnable = Runnable {
                onTimerFinished(phase)
            }
            completionRunnable = runnable
            handler.postDelayed(runnable, remainingMillis)
        }
    }

    private fun onTimerFinished(phase: String) {
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

        // 5. Fallback safety timer for service teardown if audio fails
        val fallbackTeardown = Runnable {
            stopSelf()
        }
        handler.postDelayed(fallbackTeardown, 2500)

        // 6. Play bell chime and cleanly terminate service once playback finishes
        playBellChime {
            handler.removeCallbacks(fallbackTeardown)
            stopSelf()
        }
    }

    private fun stopCountdown() {
        cancelScheduledCompletion()
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
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

    private fun playBellChime(onComplete: (() -> Unit)? = null) {
        try {
            bellPlayer?.release()
            assets.openFd("flutter_assets/assets/audio/foley_bell_chime.wav").use { afd ->
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
