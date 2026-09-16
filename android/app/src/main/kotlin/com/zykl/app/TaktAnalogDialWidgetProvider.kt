package com.zykl.app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Typeface
import android.widget.RemoteViews

class TaktAnalogDialWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    companion object {
        @JvmStatic
        fun updateAllWidgets(context: Context) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val thisWidget = ComponentName(context, TaktAnalogDialWidgetProvider::class.java)
            val appWidgetIds = appWidgetManager.getAppWidgetIds(thisWidget)
            for (appWidgetId in appWidgetIds) {
                updateAppWidget(context, appWidgetManager, appWidgetId)
            }
        }

        @JvmStatic
        fun updateAppWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
            val prefs = context.getSharedPreferences(TaktAppWidgetProvider.PREFS_NAME, Context.MODE_PRIVATE)
            val isPro = prefs.getBoolean(TaktAppWidgetProvider.KEY_IS_PRO, false)
            val status = prefs.getString(TaktAppWidgetProvider.KEY_STATUS, "STANDBY") ?: "STANDBY"
            val remainingSeconds = prefs.getInt(TaktAppWidgetProvider.KEY_REMAINING_SECONDS, 0).coerceAtLeast(0)
            val targetMinutes = prefs.getInt(TaktAppWidgetProvider.KEY_TARGET_MINUTES, 25).coerceAtLeast(1)

            val views = RemoteViews(context.packageName, R.layout.takt_appwidget_analog_dial_2x2)

            // Draw procedural Bitmap (400x400 px)
            // If not Pro, needle remains parked in standby alignment (0°)
            val dialBitmap = renderAnalogDial(if (isPro) status else "STANDBY", remainingSeconds, targetMinutes)
            views.setImageViewBitmap(R.id.widget_dial_image, dialBitmap)

            val timeBadgeText = if (!isPro) {
                "[ STUDIO PRO // UNLOCK ]"
            } else if (status == "FOCUS" || status == "BREAK") {
                val mins = remainingSeconds / 60
                val secs = remainingSeconds % 60
                String.format(java.util.Locale.ROOT, "%02d:%02d", mins, secs)
            } else {
                "STANDBY"
            }
            views.setTextViewText(R.id.widget_time_badge, timeBadgeText)
            if (!isPro) {
                views.setTextColor(R.id.widget_time_badge, Color.parseColor("#FF9E00"))
            } else {
                views.setTextColor(R.id.widget_time_badge, Color.parseColor("#F2EFE9"))
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
                102,
                launchIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }

        @JvmStatic
        fun renderAnalogDial(status: String, remainingSeconds: Int, targetMinutes: Int): Bitmap {
            val size = 400
            val bitmap = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
            val canvas = Canvas(bitmap)
            val center = size / 2f
            val radius = size * 0.46f

            // Paints
            val bezelPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = Color.parseColor("#1C1E22")
                style = Paint.Style.FILL
            }
            val bezelStrokePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = Color.parseColor("#2A2C30")
                style = Paint.Style.STROKE
                strokeWidth = 3f
            }
            val facePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = Color.parseColor("#EDEAE2") // Braun warm bone
                style = Paint.Style.FILL
            }
            val tickMajorPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = Color.parseColor("#14171A")
                strokeWidth = 3.5f
                style = Paint.Style.STROKE
                strokeCap = Paint.Cap.ROUND
            }
            val tickMinorPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = Color.parseColor("#8E8E93")
                strokeWidth = 1.5f
                style = Paint.Style.STROKE
                strokeCap = Paint.Cap.ROUND
            }
            val brandTextPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = Color.parseColor("#14171A")
                textSize = 20f
                typeface = Typeface.create(Typeface.MONOSPACE, Typeface.BOLD)
                textAlign = Paint.Align.CENTER
            }
            val needlePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = Color.parseColor("#FF9E00") // Signature filament amber
                strokeWidth = 4.5f
                style = Paint.Style.STROKE
                strokeCap = Paint.Cap.ROUND
            }
            val centerBossPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = Color.parseColor("#14171A")
                style = Paint.Style.FILL
            }
            val centerPipPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = Color.parseColor("#FF9E00")
                style = Paint.Style.FILL
            }

            // Draw outer bezel ring
            canvas.drawCircle(center, center, radius, bezelPaint)
            canvas.drawCircle(center, center, radius, bezelStrokePaint)

            // Draw inner face
            val innerRadius = radius * 0.88f
            canvas.drawCircle(center, center, innerRadius, facePaint)

            // Draw 60 ticks
            for (i in 0 until 60) {
                val angleDeg = i * 6.0
                val angleRad = Math.toRadians(angleDeg)
                val isMajor = i % 5 == 0
                val tickLength = if (isMajor) innerRadius * 0.14f else innerRadius * 0.07f
                val p = if (isMajor) tickMajorPaint else tickMinorPaint

                val startX = (center + (innerRadius - tickLength) * Math.sin(angleRad)).toFloat()
                val startY = (center - (innerRadius - tickLength) * Math.cos(angleRad)).toFloat()
                val endX = (center + (innerRadius - 4f) * Math.sin(angleRad)).toFloat()
                val endY = (center - (innerRadius - 4f) * Math.cos(angleRad)).toFloat()
                canvas.drawLine(startX, startY, endX, endY, p)
            }

            // Brand text: ZYKL
            canvas.drawText("ZYKL", center, center - innerRadius * 0.32f, brandTextPaint)

            // Calculate needle angle
            val totalSecs = targetMinutes * 60
            val elapsedSecs = (totalSecs - remainingSeconds).coerceIn(0, totalSecs)
            val needleProgress = if (totalSecs > 0) elapsedSecs.toFloat() / totalSecs.toFloat() else 0f
            val needleAngleDeg = if (status == "STANDBY") 0.0 else (needleProgress * 360.0)
            val needleAngleRad = Math.toRadians(needleAngleDeg)

            // Draw Amber Needle
            val needleLength = innerRadius * 0.78f
            val needleEndX = (center + needleLength * Math.sin(needleAngleRad)).toFloat()
            val needleEndY = (center - needleLength * Math.cos(needleAngleRad)).toFloat()
            val needleTailLength = innerRadius * 0.15f
            val needleTailX = (center - needleTailLength * Math.sin(needleAngleRad)).toFloat()
            val needleTailY = (center + needleTailLength * Math.cos(needleAngleRad)).toFloat()

            canvas.drawLine(needleTailX, needleTailY, needleEndX, needleEndY, needlePaint)

            // Center boss & amber pip
            canvas.drawCircle(center, center, 10f, centerBossPaint)
            canvas.drawCircle(center, center, 4f, centerPipPaint)

            return bitmap
        }
    }
}
