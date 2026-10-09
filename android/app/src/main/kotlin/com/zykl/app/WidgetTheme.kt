package com.zykl.app

import android.content.Context
import android.content.res.ColorStateList
import android.os.Build
import android.widget.RemoteViews

/**
 * Colours of the chassis widgets (Console, Focus Strip, Analog Dial), pushed by the app whenever the light/dark mode
 * or the hardware edition changes (MainActivity "updateWidgetTheme"). Until the app has run once it is the original
 * dark look. The Task Dispenser stays thermal paper in every theme.
 */
data class WidgetTheme(
    val dark: Boolean,
    val chassis: Int,
    val text: Int,
    val muted: Int,
    val accent: Int,
    val needle: Int,
    val border: Int,
) {
    companion object {
        const val KEY_DARK = "theme_dark"
        const val KEY_CHASSIS = "theme_chassis"
        const val KEY_TEXT = "theme_text"
        const val KEY_MUTED = "theme_muted"
        const val KEY_ACCENT = "theme_accent"
        const val KEY_NEEDLE = "theme_needle"
        const val KEY_BORDER = "theme_border"

        val DEFAULT = WidgetTheme(
            dark = true,
            chassis = 0xFF141414.toInt(),
            text = 0xFFF2EFE9.toInt(),
            muted = 0xFF8E8E93.toInt(),
            accent = 0xFFFF9E00.toInt(),
            needle = 0xFFFF9E00.toInt(),
            border = 0xFF2A2A2A.toInt(),
        )

        fun load(context: Context): WidgetTheme {
            val p = context.getSharedPreferences(TaktAppWidgetProvider.PREFS_NAME, Context.MODE_PRIVATE)
            if (!p.contains(KEY_CHASSIS)) return DEFAULT
            return WidgetTheme(
                dark = p.getBoolean(KEY_DARK, DEFAULT.dark),
                chassis = p.getInt(KEY_CHASSIS, DEFAULT.chassis),
                text = p.getInt(KEY_TEXT, DEFAULT.text),
                muted = p.getInt(KEY_MUTED, DEFAULT.muted),
                accent = p.getInt(KEY_ACCENT, DEFAULT.accent),
                needle = p.getInt(KEY_NEEDLE, DEFAULT.needle),
                border = p.getInt(KEY_BORDER, DEFAULT.border),
            )
        }

        fun save(context: Context, theme: WidgetTheme) {
            context.getSharedPreferences(TaktAppWidgetProvider.PREFS_NAME, Context.MODE_PRIVATE).edit()
                .putBoolean(KEY_DARK, theme.dark)
                .putInt(KEY_CHASSIS, theme.chassis)
                .putInt(KEY_TEXT, theme.text)
                .putInt(KEY_MUTED, theme.muted)
                .putInt(KEY_ACCENT, theme.accent)
                .putInt(KEY_NEEDLE, theme.needle)
                .putInt(KEY_BORDER, theme.border)
                .apply()
        }
    }

    /**
     * Chassis colour on [rootId] (Android 12+ tints the rounded shape with the exact edition colour; older versions
     * pick the dark or light chassis drawable) and the text / divider colours by role.
     */
    fun apply(
        views: RemoteViews,
        rootId: Int,
        textIds: IntArray = intArrayOf(),
        mutedIds: IntArray = intArrayOf(),
        accentIds: IntArray = intArrayOf(),
        dividerIds: IntArray = intArrayOf(),
    ) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            views.setColorStateList(rootId, "setBackgroundTintList", ColorStateList.valueOf(chassis))
        } else {
            views.setInt(
                rootId, "setBackgroundResource",
                if (dark) R.drawable.widget_chassis_bg else R.drawable.widget_chassis_bg_light
            )
        }
        textIds.forEach { views.setTextColor(it, text) }
        mutedIds.forEach { views.setTextColor(it, muted) }
        accentIds.forEach { views.setTextColor(it, accent) }
        dividerIds.forEach { views.setInt(it, "setBackgroundColor", border) }
    }
}
