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
            val cycles = prefs.getInt(KEY_CYCLES_COMPLETED, 0)
            val target = prefs.getInt(KEY_CYCLES_TARGET, 4)
            val minutes = prefs.getInt(KEY_MINUTES_FOCUSED, 0)
            val status = prefs.getString(KEY_STATUS, "STANDBY") ?: "STANDBY"

            val views = RemoteViews(context.packageName, R.layout.takt_appwidget_2x2)

            // Update text telemetries
            views.setTextViewText(R.id.widget_cycles_text, "TODAY: $cycles / $target CYCLES")
            views.setTextViewText(R.id.widget_minutes_text, "$minutes MIN FOCUSED")
            views.setTextViewText(R.id.widget_status_text, "STATUS: $status")

            // Update 4 Micro-LED drawables
            val activeLed = R.drawable.ic_widget_led_amber
            val dimLed = R.drawable.ic_widget_led_dim

            views.setImageViewResource(R.id.led_1, if (cycles >= 1) activeLed else dimLed)
            views.setImageViewResource(R.id.led_2, if (cycles >= 2) activeLed else dimLed)
            views.setImageViewResource(R.id.led_3, if (cycles >= 3) activeLed else dimLed)
            views.setImageViewResource(R.id.led_4, if (cycles >= 4) activeLed else dimLed)

            // Smart direct launch PendingIntent
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
