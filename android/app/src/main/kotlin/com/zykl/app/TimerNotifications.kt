package com.zykl.app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import androidx.core.app.NotificationCompat

/**
 * Shared parts of the timer notifications: channels, the Android 16 Live Update request, the PAUSE / RESUME / STOP
 * buttons and the "paused" card that keeps a paused session on the lock screen.
 */
object TimerNotifications {
    // DEFAULT importance so the countdown shows with normal notifications instead of
    // being folded into "Silent". Android never lets an app raise an existing
    // channel's importance, hence a new ID; the old LOW channel is deleted.
    const val CHANNEL_TIMER_ID = "zykl_timer_countdown"
    private const val LEGACY_TIMER_CHANNEL_ID = "takt_desk_timer_channel"
    const val CHANNEL_ALERT_ID = "takt_desk_alert_channel"

    const val PAUSED_NOTIFICATION_ID = 1003

    /** Notification.EXTRA_REQUEST_PROMOTED_ONGOING: public in the SDK from API 36.1, read under this key by
     *  Android 16 already (NotificationCompat 1.17's setRequestPromotedOngoing writes the same extra). */
    private const val EXTRA_REQUEST_PROMOTED_ONGOING = "android.requestPromotedOngoing"

    const val ACCENT = 0xFFFF9E00.toInt()

    private const val REQUEST_PAUSE = 3001
    private const val REQUEST_STOP = 3002
    private const val REQUEST_RESUME = 3003
    private const val REQUEST_PAUSED_STOP = 3004
    private const val REQUEST_OPEN_PAUSED = 3005

    fun createChannels(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        val timerChannel = NotificationChannel(
            CHANNEL_TIMER_ID,
            "ZYKL Active Timer",
            NotificationManager.IMPORTANCE_DEFAULT
        ).apply {
            description = "Live analog timer telemetry on Lockscreen and Always-On Display"
            setSound(null, null)
            enableVibration(false)
            setShowBadge(false)
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

        manager.deleteNotificationChannel(LEGACY_TIMER_CHANNEL_ID)
        manager.createNotificationChannel(timerChannel)
        manager.createNotificationChannel(alertChannel)
    }

    /**
     * Asks Android 16+ to show the countdown as a Live Update: a status-bar chip with the running chronometer and an
     * expanded card on the lock screen / AOD. It only applies while the notification stays promotable (ongoing,
     * titled, standard style, not colorized, channel not MIN); older versions ignore the extra.
     */
    fun requestPromotion(builder: NotificationCompat.Builder): NotificationCompat.Builder =
        builder.addExtras(Bundle().apply { putBoolean(EXTRA_REQUEST_PROMOTED_ONGOING, true) })

    fun title(phase: String, cycleCount: Int): String = when (phase) {
        "shortBreak" -> "ZYKL · SHORT BRK"
        "longBreak" -> "ZYKL · LONG BRK"
        else -> "ZYKL · FOCUS (CYCLE $cycleCount/4)"
    }

    fun openAppIntent(context: Context, requestCode: Int): PendingIntent {
        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        return PendingIntent.getActivity(
            context, requestCode, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    private fun action(
        context: Context,
        receiverAction: String,
        requestCode: Int,
        label: String,
        extras: Bundle? = null
    ): NotificationCompat.Action {
        val intent = Intent(context, WidgetActionReceiver::class.java).apply {
            action = receiverAction
            extras?.let { putExtras(it) }
        }
        val pending = PendingIntent.getBroadcast(
            context, requestCode, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        return NotificationCompat.Action.Builder(0, label, pending).build()
    }

    /** Buttons of the running countdown. */
    fun addRunningActions(context: Context, builder: NotificationCompat.Builder): NotificationCompat.Builder =
        builder
            .addAction(action(context, WidgetActionReceiver.ACTION_NOTIF_PAUSE, REQUEST_PAUSE, "PAUSE"))
            .addAction(action(context, WidgetActionReceiver.ACTION_NOTIF_STOP, REQUEST_STOP, "STOP"))

    /**
     * A paused session: no chronometer, not ongoing (the user may swipe it away), visible on the lock screen. RESUME
     * carries everything the service needs to start again, so it also works after the app process is gone.
     */
    fun showPaused(
        context: Context,
        remainingSeconds: Double,
        targetMinutes: Int,
        phase: String,
        cycleCount: Int,
        profileName: String,
        alarmChimeId: String
    ) {
        val secs = remainingSeconds.toInt().coerceAtLeast(0)
        val resumeExtras = Bundle().apply {
            putDouble(TimerForegroundService.EXTRA_REMAINING_SECONDS, remainingSeconds)
            putInt(TimerForegroundService.EXTRA_TARGET_MINUTES, targetMinutes)
            putString(TimerForegroundService.EXTRA_PHASE, phase)
            putInt(TimerForegroundService.EXTRA_CYCLE_COUNT, cycleCount)
            putString(TimerForegroundService.EXTRA_PROFILE_NAME, profileName)
            putString(TimerForegroundService.EXTRA_ALARM_CHIME_ID, alarmChimeId)
        }
        createChannels(context)
        val notification = NotificationCompat.Builder(context, CHANNEL_TIMER_ID)
            .setSmallIcon(R.drawable.ic_takt_timer)
            .setContentTitle("${title(phase, cycleCount)} · PAUSED")
            .setContentText(String.format(java.util.Locale.ROOT, "%02d:%02d LEFT · %s", secs / 60, secs % 60, profileName))
            .setSilent(true)
            .setOnlyAlertOnce(true)
            .setShowWhen(false)
            .setColor(ACCENT)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setContentIntent(openAppIntent(context, REQUEST_OPEN_PAUSED))
            .setCategory(NotificationCompat.CATEGORY_PROGRESS)
            .addAction(action(context, WidgetActionReceiver.ACTION_NOTIF_RESUME, REQUEST_RESUME, "RESUME", resumeExtras))
            .addAction(action(context, WidgetActionReceiver.ACTION_NOTIF_STOP, REQUEST_PAUSED_STOP, "STOP"))
            .build()
        try {
            (context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager)
                ?.notify(PAUSED_NOTIFICATION_ID, notification)
        } catch (_: SecurityException) {}
    }

    fun cancelPaused(context: Context) {
        (context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager)?.cancel(PAUSED_NOTIFICATION_ID)
    }
}
