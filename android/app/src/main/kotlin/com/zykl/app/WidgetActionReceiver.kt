package com.zykl.app

import android.appwidget.AppWidgetManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.database.sqlite.SQLiteDatabase
import android.os.Build
import android.util.Log
import java.io.File
import org.json.JSONArray

class WidgetActionReceiver : BroadcastReceiver() {
    companion object {
        const val ACTION_TOGGLE_TIMER = "com.zykl.app.ACTION_TOGGLE_TIMER"
        const val ACTION_TOGGLE_TASK = "com.zykl.app.ACTION_TOGGLE_TASK"
        const val EXTRA_TASK_INDEX = "EXTRA_TASK_INDEX"
        const val EXTRA_TASK_ID = "EXTRA_TASK_ID"
    }

    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            ACTION_TOGGLE_TIMER -> handleToggleTimer(context)
            ACTION_TOGGLE_TASK -> {
                val index = intent.getIntExtra(EXTRA_TASK_INDEX, -1)
                val taskId = intent.getIntExtra(EXTRA_TASK_ID, -1)
                handleToggleTask(context, index, taskId)
            }
        }
    }

    private fun handleToggleTimer(context: Context) {
        val prefs = context.getSharedPreferences(TaktAppWidgetProvider.PREFS_NAME, Context.MODE_PRIVATE)
        val currentStatus = prefs.getString(TaktAppWidgetProvider.KEY_STATUS, "STANDBY") ?: "STANDBY"
        val targetMinutes = prefs.getInt(TaktAppWidgetProvider.KEY_TARGET_MINUTES, 25).coerceAtLeast(1)

        if (currentStatus == "STANDBY") {
            // 1. Start foreground timer service
            val serviceIntent = Intent(context, TimerForegroundService::class.java).apply {
                action = TimerForegroundService.ACTION_START
                putExtra(TimerForegroundService.EXTRA_REMAINING_SECONDS, targetMinutes * 60.0)
                putExtra(TimerForegroundService.EXTRA_TARGET_MINUTES, targetMinutes)
                putExtra(TimerForegroundService.EXTRA_PHASE, "focus")
                putExtra(TimerForegroundService.EXTRA_CYCLE_COUNT, 1)
                putExtra(TimerForegroundService.EXTRA_PROFILE_NAME, "CLASSIC 25/5")
                putExtra(TimerForegroundService.EXTRA_ALARM_CHIME_ID, "braunBell")
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(serviceIntent)
            } else {
                context.startService(serviceIntent)
            }

            // 2. Update prefs
            prefs.edit()
                .putString(TaktAppWidgetProvider.KEY_STATUS, "FOCUS")
                .putInt(TaktAppWidgetProvider.KEY_REMAINING_SECONDS, targetMinutes * 60)
                .apply()

            // 3. Notify Flutter app if active
            MainActivity.sendWidgetAction("toggleTimer", mapOf("status" to "FOCUS"))
        } else {
            // 1. Stop foreground timer service
            val serviceIntent = Intent(context, TimerForegroundService::class.java).apply {
                action = TimerForegroundService.ACTION_STOP
            }
            context.startService(serviceIntent)

            // 2. Update prefs
            prefs.edit()
                .putString(TaktAppWidgetProvider.KEY_STATUS, "STANDBY")
                .putInt(TaktAppWidgetProvider.KEY_REMAINING_SECONDS, targetMinutes * 60)
                .apply()

            // 3. Notify Flutter app if active
            MainActivity.sendWidgetAction("toggleTimer", mapOf("status" to "STANDBY"))
        }

        // Refresh widgets immediately
        TaktAppWidgetProvider.updateAllWidgets(context)
        TaktFocusStripWidgetProvider.updateAllWidgets(context)
        TaktAnalogDialWidgetProvider.updateAllWidgets(context)
    }

    private fun handleToggleTask(context: Context, taskIndex: Int, taskId: Int) {
        val prefs = context.getSharedPreferences(TaktAppWidgetProvider.PREFS_NAME, Context.MODE_PRIVATE)
        val tasksJsonStr = prefs.getString(TaktAppWidgetProvider.KEY_TASKS_JSON, "[]") ?: "[]"

        try {
            val jsonArray = JSONArray(tasksJsonStr)
            var targetTaskId = taskId
            var nextCompletedState = false

            if (taskIndex in 0 until jsonArray.length()) {
                val obj = jsonArray.optJSONObject(taskIndex)
                if (obj != null) {
                    val currentDone = obj.optBoolean("is_completed", false)
                    nextCompletedState = !currentDone
                    obj.put("is_completed", nextCompletedState)
                    if (targetTaskId == -1) {
                        targetTaskId = obj.optInt("id", -1)
                    }
                }
            }

            // Save updated JSON back to SharedPreferences
            prefs.edit().putString(TaktAppWidgetProvider.KEY_TASKS_JSON, jsonArray.toString()).apply()

            // Update SQLite database directly so it's persisted permanently
            updateDatabase(context, targetTaskId, nextCompletedState)

            // Notify Flutter app if active
            MainActivity.sendWidgetAction("toggleTask", mapOf(
                "taskId" to targetTaskId,
                "isCompleted" to nextCompletedState
            ))

            // Refresh Task Dispenser Widget immediately
            TaktTaskDispenserWidgetProvider.updateAllWidgets(context)
        } catch (e: Exception) {
            Log.e("WidgetActionReceiver", "Failed to toggle task: ${e.message}")
        }
    }

    private fun updateDatabase(context: Context, taskId: Int, isCompleted: Boolean) {
        if (taskId == -1) return
        val candidates = listOf(
            File(context.filesDir, "takt_desk.sqlite"),
            File(context.filesDir.parentFile, "app_flutter/takt_desk.sqlite"),
            File(context.getDatabasePath("takt_desk.sqlite").path)
        )
        for (file in candidates) {
            if (file.exists()) {
                try {
                    val db = SQLiteDatabase.openDatabase(file.path, null, SQLiteDatabase.OPEN_READWRITE)
                    val completedInt = if (isCompleted) 1 else 0
                    val completedAt = if (isCompleted) System.currentTimeMillis() else null
                    db.execSQL(
                        "UPDATE tasks SET is_completed = ?, completed_at = ? WHERE id = ?",
                        arrayOf<Any?>(completedInt, completedAt, taskId)
                    )
                    db.close()
                    break
                } catch (e: Exception) {
                    Log.w("WidgetActionReceiver", "SQLite update on ${file.path}: ${e.message}")
                }
            }
        }
    }
}
