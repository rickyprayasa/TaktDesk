package com.zykl.app

import android.content.Context
import android.content.Intent
import androidx.core.content.pm.ShortcutInfoCompat
import androidx.core.content.pm.ShortcutManagerCompat
import androidx.core.graphics.drawable.IconCompat
import java.util.UUID

/**
 * Long-press launcher shortcuts: Start focus, Tasks, Focus analytics. Published as dynamic shortcuts (so they follow
 * the dev-pro applicationId too). "Start focus" controls the timer, which external intents to the exported launcher
 * activity may not do, so it carries a per-install secret only our own shortcut knows.
 */
object AppShortcuts {
    const val ACTION_START_FOCUS = "startFocus"
    private const val EXTRA_SHORTCUT_ACTION = "shortcut_action"
    private const val EXTRA_SHORTCUT_TOKEN = "shortcut_token"
    private const val PREFS = "zykl_shortcuts"
    private const val KEY_TOKEN = "token"

    private fun token(context: Context): String {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        return prefs.getString(KEY_TOKEN, null) ?: UUID.randomUUID().toString().also {
            prefs.edit().putString(KEY_TOKEN, it).apply()
        }
    }

    fun publish(context: Context) {
        fun open(feature: String) = Intent(context, MainActivity::class.java)
            .setAction(Intent.ACTION_VIEW)
            .putExtra("open_feature", feature)

        val shortcuts = listOf(
            ShortcutInfoCompat.Builder(context, "start_focus")
                .setShortLabel("Start focus")
                .setLongLabel("Start focus session")
                .setIcon(IconCompat.createWithResource(context, R.drawable.ic_shortcut_focus))
                .setIntent(
                    Intent(context, MainActivity::class.java)
                        .setAction(Intent.ACTION_VIEW)
                        .putExtra(EXTRA_SHORTCUT_ACTION, ACTION_START_FOCUS)
                        .putExtra(EXTRA_SHORTCUT_TOKEN, token(context))
                )
                .setRank(0)
                .build(),
            ShortcutInfoCompat.Builder(context, "tasks")
                .setShortLabel("Tasks")
                .setLongLabel("Task dispenser")
                .setIcon(IconCompat.createWithResource(context, R.drawable.ic_shortcut_tasks))
                .setIntent(open("tasks"))
                .setRank(1)
                .build(),
            ShortcutInfoCompat.Builder(context, "analytics")
                .setShortLabel("Analytics")
                .setLongLabel("Focus analytics")
                .setIcon(IconCompat.createWithResource(context, R.drawable.ic_shortcut_analytics))
                .setIntent(open("analytics"))
                .setRank(2)
                .build(),
        )
        try {
            ShortcutManagerCompat.setDynamicShortcuts(context, shortcuts)
        } catch (_: Exception) {
            // Rate limited or unsupported launcher: the shortcuts are a convenience only.
        }
    }

    /** The action of one of our own shortcuts in [intent] (token checked), else null. Consumes the extras. */
    fun action(context: Context, intent: Intent?): String? {
        val action = intent?.getStringExtra(EXTRA_SHORTCUT_ACTION) ?: return null
        val valid = action == ACTION_START_FOCUS && intent.getStringExtra(EXTRA_SHORTCUT_TOKEN) == token(context)
        return if (valid) action else null
    }

    fun clear(intent: Intent?) {
        intent?.removeExtra(EXTRA_SHORTCUT_ACTION)
        intent?.removeExtra(EXTRA_SHORTCUT_TOKEN)
    }
}
