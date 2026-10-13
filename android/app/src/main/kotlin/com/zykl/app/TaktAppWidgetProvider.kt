package com.zykl.app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews

class TaktAppWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    companion object {
        const val PREFS_NAME = "takt_widget_prefs"
        const val KEY_CYCLES_COMPLETED = "cycles_completed"
        const val KEY_CYCLES_TARGET = "cycles_target"
        const val KEY_MINUTES_FOCUSED = "minutes_focused"
        const val KEY_STATUS = "status"
        const val KEY_REMAINING_SECONDS = "remaining_seconds"
        const val KEY_TARGET_MINUTES = "target_minutes"
        const val KEY_TASKS_JSON = "tasks_json"
        const val KEY_IS_PRO = "is_pro"
        /** Last profile / chime / cycle the app used, so a widget start without the app open matches it. */
        const val KEY_PROFILE_NAME = "profile_name"
        const val KEY_ALARM_CHIME_ID = "alarm_chime_id"
        const val KEY_CYCLE_COUNT = "cycle_count"
        /** SystemClock.elapsedRealtime() at which the running phase ends (0 = not running). Drives the Focus Strip
         *  Chronometer, which counts down by itself, so widgets need no per-second updates. */
        const val KEY_END_ELAPSED = "end_elapsed_realtime"
        /** Local day (yyyyMMdd) the daily counters were written for; other days read as 0. */
        const val KEY_STATS_DAY = "stats_day"
        /** Settings → DAY STARTS AT (0..6): before this hour it is still the previous day, as in the app. */
        const val KEY_DAY_START_HOUR = "day_start_hour"

        /** Today as the app counts days (Dart `logicalDay`): before [dayStartHour] o'clock, yesterday's date. */
        fun todayKey(dayStartHour: Int = 0): Int {
            val c = java.util.Calendar.getInstance()
            if (c.get(java.util.Calendar.HOUR_OF_DAY) < dayStartHour) c.add(java.util.Calendar.DAY_OF_MONTH, -1)
            return c.get(java.util.Calendar.YEAR) * 10000 + (c.get(java.util.Calendar.MONTH) + 1) * 100 +
                c.get(java.util.Calendar.DAY_OF_MONTH)
        }

        private fun statsAreToday(prefs: android.content.SharedPreferences): Boolean =
            prefs.getInt(KEY_STATS_DAY, 0) == todayKey(prefs.getInt(KEY_DAY_START_HOUR, 0))

        /** Today's completed cycles: 0 once the counters belong to an earlier day (app not opened since the day began). */
        fun cyclesToday(prefs: android.content.SharedPreferences): Int =
            if (statsAreToday(prefs)) prefs.getInt(KEY_CYCLES_COMPLETED, 0) else 0

        fun minutesToday(prefs: android.content.SharedPreferences): Int =
            if (statsAreToday(prefs)) prefs.getInt(KEY_MINUTES_FOCUSED, 0) else 0

        /**
         * The status to show. FOCUS / BREAK only while the countdown service really runs in this process: after a
         * reboot, force-stop or update mid-session the saved status (and end time) would otherwise show a phantom
         * countdown, and the widget toggle would "stop" a session that no longer exists.
         */
        fun liveStatus(prefs: android.content.SharedPreferences): String {
            val status = prefs.getString(KEY_STATUS, "STANDBY") ?: "STANDBY"
            val running = status == "FOCUS" || status == "BREAK"
            return if (running && !TimerForegroundService.isCountingDown) "STANDBY" else status
        }

        /** How many of the 4 LEDs to light: today's cycles as a share of the daily goal (goal 4 = one LED each). */
        fun litLeds(cycles: Int, target: Int): Int =
            if (target <= 0) 0 else ((cycles * 4) / target).coerceIn(0, 4)

        @JvmStatic
        fun updateAllWidgets(context: Context) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val thisWidget = ComponentName(context, TaktAppWidgetProvider::class.java)
            val appWidgetIds = appWidgetManager.getAppWidgetIds(thisWidget)
            for (appWidgetId in appWidgetIds) {
                updateAppWidget(context, appWidgetManager, appWidgetId)
            }
        }

        @JvmStatic
        fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val cycles = cyclesToday(prefs)
            val target = prefs.getInt(KEY_CYCLES_TARGET, 4)
            val minutes = minutesToday(prefs)
            val status = liveStatus(prefs)

            val views = RemoteViews(context.packageName, R.layout.takt_appwidget_2x2)
            WidgetTheme.load(context).apply(
                views, R.id.widget_root,
                textIds = intArrayOf(R.id.theme_text_1, R.id.widget_cycles_text),
                mutedIds = intArrayOf(R.id.theme_muted_1, R.id.widget_minutes_text, R.id.theme_muted_2),
                accentIds = intArrayOf(R.id.widget_status_text),
                dividerIds = intArrayOf(R.id.theme_divider_1, R.id.theme_divider_2),
            )

            // Update text telemetries
            views.setTextViewText(R.id.widget_cycles_text, "TODAY: $cycles / $target CYCLES")
            views.setTextViewText(R.id.widget_minutes_text, "$minutes MIN FOCUSED")
            
            val statusDisplay = when (status) {
                "FOCUS" -> "STATUS: [ ⏸ PAUSE ]"
                "BREAK" -> "STATUS: [ ⏸ BREAK ]"
                else -> "STATUS: [ ▶ START ]"
            }
            views.setTextViewText(R.id.widget_status_text, statusDisplay)

            // Update 4 Micro-LED drawables
            val activeLed = R.drawable.ic_widget_led_amber
            val dimLed = R.drawable.ic_widget_led_dim

            val lit = litLeds(cycles, target)
            views.setImageViewResource(R.id.led_1, if (lit >= 1) activeLed else dimLed)
            views.setImageViewResource(R.id.led_2, if (lit >= 2) activeLed else dimLed)
            views.setImageViewResource(R.id.led_3, if (lit >= 3) activeLed else dimLed)
            views.setImageViewResource(R.id.led_4, if (lit >= 4) activeLed else dimLed)

            // 1. Direct interactive action on STATUS button to toggle timer
            val toggleTimerIntent = Intent(context, WidgetActionReceiver::class.java).apply {
                action = WidgetActionReceiver.ACTION_TOGGLE_TIMER
            }
            val toggleTimerPendingIntent = PendingIntent.getBroadcast(
                context,
                203,
                toggleTimerIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_status_text, toggleTimerPendingIntent)

            // 2. Direct launch PendingIntent for full desk app
            val launchIntent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                        Intent.FLAG_ACTIVITY_CLEAR_TOP or
                        Intent.FLAG_ACTIVITY_SINGLE_TOP
            }
            val pendingIntent = PendingIntent.getActivity(
                context,
                0,
                launchIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
