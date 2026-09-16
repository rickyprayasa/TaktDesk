package com.zykl.app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.view.View
import android.widget.RemoteViews

class TaktTaskDispenserWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    companion object {
        @JvmStatic
        fun updateAllWidgets(context: Context) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val thisWidget = ComponentName(context, TaktTaskDispenserWidgetProvider::class.java)
            val appWidgetIds = appWidgetManager.getAppWidgetIds(thisWidget)
            for (appWidgetId in appWidgetIds) {
                updateAppWidget(context, appWidgetManager, appWidgetId)
            }
        }

        @JvmStatic
        fun updateAppWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
            val prefs = context.getSharedPreferences(TaktAppWidgetProvider.PREFS_NAME, Context.MODE_PRIVATE)
            val isPro = prefs.getBoolean(TaktAppWidgetProvider.KEY_IS_PRO, false)
            val tasksJsonStr = prefs.getString(TaktAppWidgetProvider.KEY_TASKS_JSON, "[]") ?: "[]"
            val jsonArray = try {
                org.json.JSONArray(tasksJsonStr)
            } catch (_: Exception) {
                org.json.JSONArray()
            }

            val views = RemoteViews(context.packageName, R.layout.takt_appwidget_task_dispenser_4x2)

            val rowIds = intArrayOf(R.id.task_row_1, R.id.task_row_2, R.id.task_row_3, R.id.task_row_4, R.id.task_row_5)
            val checkIds = intArrayOf(R.id.task_check_1, R.id.task_check_2, R.id.task_check_3, R.id.task_check_4, R.id.task_check_5)
            val titleIds = intArrayOf(R.id.task_title_1, R.id.task_title_2, R.id.task_title_3, R.id.task_title_4, R.id.task_title_5)

            if (!isPro) {
                views.setTextViewText(R.id.widget_quota_text, "STUDIO PRO")
                views.setTextViewText(R.id.widget_footer_action, "[ ★ TAP TO UNLOCK PRO ↗ ]")

                val previewChecks = arrayOf("[★]", "[ ]", "[ ]", "[ ]", "[ ]")
                val previewTitles = arrayOf(
                    "STUDIO PRO // UNLOCK",
                    "SYNC ACTIVE TASKS",
                    "MONOSPACE RECEIPT",
                    "ROTARY DISPENSER",
                    "LIFETIME Rp 69.000"
                )

                for (i in 0 until 5) {
                    views.setViewVisibility(rowIds[i], View.VISIBLE)
                    views.setTextViewText(checkIds[i], previewChecks[i])
                    views.setTextViewText(titleIds[i], previewTitles[i])
                    val textColor = if (i == 0) Color.parseColor("#B45309") else Color.parseColor("#14171A")
                    views.setTextColor(checkIds[i], textColor)
                    views.setTextColor(titleIds[i], textColor)
                }
            } else {
                views.setTextViewText(R.id.widget_footer_action, "[ + OPEN ROTARY DISPENSER ↗ ]")

                val totalCount = jsonArray.length()
                var completedCount = 0
                for (j in 0 until totalCount) {
                    if (jsonArray.optJSONObject(j)?.optBoolean("is_completed", false) == true) {
                        completedCount++
                    }
                }

                for (i in 0 until 5) {
                    if (i < totalCount) {
                        val obj = jsonArray.optJSONObject(i)
                        val title = obj?.optString("title", "") ?: ""
                        val isDone = obj?.optBoolean("is_completed", false) ?: false

                        views.setViewVisibility(rowIds[i], View.VISIBLE)
                        views.setTextViewText(checkIds[i], if (isDone) "[✓]" else "[ ]")
                        views.setTextColor(checkIds[i], if (isDone) Color.parseColor("#B45309") else Color.parseColor("#14171A"))

                        val titleText: CharSequence = if (isDone && title.isNotEmpty()) {
                            android.text.SpannableString(title).apply {
                                setSpan(
                                    android.text.style.StrikethroughSpan(),
                                    0,
                                    length,
                                    android.text.Spanned.SPAN_EXCLUSIVE_EXCLUSIVE
                                )
                            }
                        } else {
                            title
                        }
                        views.setTextViewText(titleIds[i], titleText)
                        views.setTextColor(titleIds[i], if (isDone) Color.parseColor("#8E8E93") else Color.parseColor("#14171A"))
                    } else if (totalCount == 0 && i == 0) {
                        views.setViewVisibility(rowIds[0], View.VISIBLE)
                        views.setTextViewText(checkIds[0], "[ ]")
                        views.setTextColor(checkIds[0], Color.parseColor("#73716B"))
                        views.setTextViewText(titleIds[0], "NO ACTIVE TASKS // TAP TO DISPENSE")
                        views.setTextColor(titleIds[0], Color.parseColor("#73716B"))
                    } else {
                        views.setViewVisibility(rowIds[i], View.GONE)
                    }
                }

                val quotaText = String.format(java.util.Locale.ROOT, "%d/%d DONE", completedCount, totalCount)
                views.setTextViewText(R.id.widget_quota_text, quotaText)
            }

            // PendingIntent
            val launchIntent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                        Intent.FLAG_ACTIVITY_CLEAR_TOP or
                        Intent.FLAG_ACTIVITY_SINGLE_TOP
                if (!isPro) {
                    putExtra("open_feature", "studio_pro")
                }
            }
            val pendingIntent = PendingIntent.getActivity(
                context,
                103,
                launchIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)
            views.setOnClickPendingIntent(R.id.widget_footer_action, pendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
