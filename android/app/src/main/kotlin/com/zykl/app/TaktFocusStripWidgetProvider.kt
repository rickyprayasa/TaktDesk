package com.zykl.app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews

class TaktFocusStripWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    companion object {
        @JvmStatic
        fun updateAllWidgets(context: Context) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val thisWidget = ComponentName(context, TaktFocusStripWidgetProvider::class.java)
            val appWidgetIds = appWidgetManager.getAppWidgetIds(thisWidget)
            for (appWidgetId in appWidgetIds) {
                updateAppWidget(context, appWidgetManager, appWidgetId)
            }
        }

        @JvmStatic
        fun updateAppWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
            val prefs = context.getSharedPreferences(TaktAppWidgetProvider.PREFS_NAME, Context.MODE_PRIVATE)
            val cycles = prefs.getInt(TaktAppWidgetProvider.KEY_CYCLES_COMPLETED, 0)
            val target = prefs.getInt(TaktAppWidgetProvider.KEY_CYCLES_TARGET, 4)
            val status = prefs.getString(TaktAppWidgetProvider.KEY_STATUS, "STANDBY") ?: "STANDBY"
            val remainingSeconds = prefs.getInt(TaktAppWidgetProvider.KEY_REMAINING_SECONDS, 0)

            val views = RemoteViews(context.packageName, R.layout.takt_appwidget_focus_strip_4x1)

            // Format status & time
            val statusText = if (status == "FOCUS" || status == "BREAK") {
                val mins = remainingSeconds / 60
                val secs = remainingSeconds % 60
                val timeFormatted = String.format("%02d:%02d", mins, secs)
                "$status // $timeFormatted"
            } else {
                "STANDBY // READY"
            }
            views.setTextViewText(R.id.widget_status_text, statusText)
            views.setTextViewText(R.id.widget_cycles_text, "$cycles/$target CYC")

            // Action button text
            val actionText = when (status) {
                "FOCUS" -> "[ ⏸ PAUSE ]"
                "BREAK" -> "[ ⏸ BREAK ]"
                else -> "[ START ➔ ]"
            }
            views.setTextViewText(R.id.widget_action_btn, actionText)

            // Update 4 Micro-LEDs
            val activeLed = R.drawable.ic_widget_led_amber
            val dimLed = R.drawable.ic_widget_led_dim
            val lit = TaktAppWidgetProvider.litLeds(cycles, target)
            views.setImageViewResource(R.id.led_1, if (lit >= 1) activeLed else dimLed)
            views.setImageViewResource(R.id.led_2, if (lit >= 2) activeLed else dimLed)
            views.setImageViewResource(R.id.led_3, if (lit >= 3) activeLed else dimLed)
            views.setImageViewResource(R.id.led_4, if (lit >= 4) activeLed else dimLed)

            // 1. Direct interactive action on [ START ➔ ] / [ ⏸ PAUSE ] button without opening app
            val toggleTimerIntent = Intent(context, WidgetActionReceiver::class.java).apply {
                action = WidgetActionReceiver.ACTION_TOGGLE_TIMER
            }
            val toggleTimerPendingIntent = PendingIntent.getBroadcast(
                context,
                201,
                toggleTimerIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_action_btn, toggleTimerPendingIntent)

            // 2. Tapping the widget body opens MainActivity
            val launchIntent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                        Intent.FLAG_ACTIVITY_CLEAR_TOP or
                        Intent.FLAG_ACTIVITY_SINGLE_TOP
            }
            val appPendingIntent = PendingIntent.getActivity(
                context,
                101,
                launchIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_root, appPendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
