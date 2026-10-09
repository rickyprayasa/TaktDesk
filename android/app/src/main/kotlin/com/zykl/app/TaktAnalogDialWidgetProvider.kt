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

            // Draw crisp circular bitmap (320x320 px)
            val dialBitmap = renderAnalogDial(status, remainingSeconds, targetMinutes, isPro)
            views.setImageViewBitmap(R.id.widget_dial_image, dialBitmap)

            // Update bottom status telemetry
            val statusDisplay = when (status) {
                "FOCUS" -> "STATUS: [ ⏸ PAUSE ]"
                "BREAK" -> "STATUS: [ ⏸ BREAK ]"
                else -> "STATUS: [ ▶ START ]"
            }
            views.setTextViewText(R.id.widget_status_text, statusDisplay)

            // 1. Direct interactive action: Tapping clock dial or status button toggles timer in background
            val toggleIntent = Intent(context, WidgetActionReceiver::class.java).apply {
                action = WidgetActionReceiver.ACTION_TOGGLE_TIMER
            }
            val togglePendingIntent = PendingIntent.getBroadcast(
                context,
                202,
                toggleIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_dial_image, togglePendingIntent)
            views.setOnClickPendingIntent(R.id.widget_status_text, togglePendingIntent)

            // 2. Tapping top header / root opens MainActivity to Chronometer dial
            val launchIntent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                        Intent.FLAG_ACTIVITY_CLEAR_TOP or
                        Intent.FLAG_ACTIVITY_SINGLE_TOP
                putExtra("open_feature", "dial")
            }
            val launchPendingIntent = PendingIntent.getActivity(
                context,
                102,
                launchIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_launch_zone, launchPendingIntent)
            views.setOnClickPendingIntent(R.id.widget_root, launchPendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }

        @JvmStatic
        fun renderAnalogDial(
            status: String,
            remainingSeconds: Int,
            targetMinutes: Int,
            isPro: Boolean = true
        ): Bitmap {
            val size = 320
            val bitmap = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
            val canvas = Canvas(bitmap)
            val center = size / 2f
            val radius = size * 0.48f

            // Paints
            val bezelPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = Color.parseColor("#1C1E22")
                style = Paint.Style.FILL
            }
            val bezelStrokePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = Color.parseColor("#2A2C30")
                style = Paint.Style.STROKE
                strokeWidth = 2.5f
            }
            val facePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = Color.parseColor("#EDEAE2") // Braun warm bone
                style = Paint.Style.FILL
            }
            val tickMajorPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = Color.parseColor("#14171A")
                strokeWidth = 2.8f
                style = Paint.Style.STROKE
                strokeCap = Paint.Cap.ROUND
            }
            val tickMinorPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = Color.parseColor("#8E8E93")
                strokeWidth = 1.2f
                style = Paint.Style.STROKE
                strokeCap = Paint.Cap.ROUND
            }
            val brandTextPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = Color.parseColor("#14171A")
                textSize = 15f
                typeface = Typeface.create(Typeface.MONOSPACE, Typeface.BOLD)
                textAlign = Paint.Align.CENTER
                letterSpacing = 0.08f
            }
            val subTextPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = if (status == "FOCUS") Color.parseColor("#FF9E00") else Color.parseColor("#73716B")
                textSize = 12f
                typeface = Typeface.create(Typeface.MONOSPACE, Typeface.BOLD)
                textAlign = Paint.Align.CENTER
                letterSpacing = 0.06f
            }
            val needlePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = Color.parseColor("#FF9E00") // Signature filament amber
                strokeWidth = 3.6f
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

            // 1. Draw outer bezel ring
            canvas.drawCircle(center, center, radius, bezelPaint)
            canvas.drawCircle(center, center, radius, bezelStrokePaint)

            // 2. Draw inner face
            val innerRadius = radius * 0.88f
            canvas.drawCircle(center, center, innerRadius, facePaint)

            // 3. Draw 60 ticks
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

            // 4. Brand text: ZYKL
            canvas.drawText("ZYKL", center, center - innerRadius * 0.32f, brandTextPaint)

            // 5. Lower face telemetry (Digital readout or status)
            // Minutes left (rounded up): the dial widget is redrawn once a minute, not every second.
            val subText = if (status == "FOCUS" || status == "BREAK") {
                "${(remainingSeconds + 59) / 60} MIN"
            } else {
                "STANDBY"
            }
            canvas.drawText(subText, center, center + innerRadius * 0.40f, subTextPaint)

            // 6. Calculate needle angle
            val totalSecs = targetMinutes * 60
            val elapsedSecs = (totalSecs - remainingSeconds).coerceIn(0, totalSecs)
            val needleProgress = if (totalSecs > 0) elapsedSecs.toFloat() / totalSecs.toFloat() else 0f
            val needleAngleDeg = if (status == "STANDBY") 0.0 else (needleProgress * 360.0)
            val needleAngleRad = Math.toRadians(needleAngleDeg)

            // 7. Draw Amber Needle
            val needleLength = innerRadius * 0.78f
            val needleEndX = (center + needleLength * Math.sin(needleAngleRad)).toFloat()
            val needleEndY = (center - needleLength * Math.cos(needleAngleRad)).toFloat()
            val needleTailLength = innerRadius * 0.15f
            val needleTailX = (center - needleTailLength * Math.sin(needleAngleRad)).toFloat()
            val needleTailY = (center + needleTailLength * Math.cos(needleAngleRad)).toFloat()

            canvas.drawLine(needleTailX, needleTailY, needleEndX, needleEndY, needlePaint)

            // 8. Center boss & amber pip
            canvas.drawCircle(center, center, 8f, centerBossPaint)
            canvas.drawCircle(center, center, 3.2f, centerPipPaint)

            return bitmap
        }
    }
}
