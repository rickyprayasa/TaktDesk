package com.zykl.app

import android.content.Context
import android.os.Build
import android.os.SystemClock
import android.service.quicksettings.Tile
import android.service.quicksettings.TileService

/**
 * Quick Settings tile "ZYKL Focus": the same START / PAUSE as the widgets (app alive → Flutter toggles, keeping the
 * real profile and pausing; app gone → the service starts the user's last profile or stops). Not an active tile: the
 * state is read from the widget prefs each time the shade opens, so nothing has to push updates to it.
 */
class ZyklTileService : TileService() {

    override fun onStartListening() {
        super.onStartListening()
        render()
    }

    override fun onClick() {
        super.onClick()
        val wasRunning = isRunning()
        WidgetActionReceiver.toggleTimer(this)
        // The toggle is asynchronous when Flutter owns the timer; show the expected state right away.
        render(running = !wasRunning)
    }

    private fun prefs() = getSharedPreferences(TaktAppWidgetProvider.PREFS_NAME, Context.MODE_PRIVATE)

    private fun isRunning(): Boolean {
        val status = prefs().getString(TaktAppWidgetProvider.KEY_STATUS, "STANDBY") ?: "STANDBY"
        return status == "FOCUS" || status == "BREAK"
    }

    private fun render(running: Boolean = isRunning()) {
        val tile = qsTile ?: return
        val prefs = prefs()
        tile.state = if (running) Tile.STATE_ACTIVE else Tile.STATE_INACTIVE
        tile.label = getString(R.string.tile_label)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val endElapsed = prefs.getLong(TaktAppWidgetProvider.KEY_END_ELAPSED, 0L)
            val leftMillis = endElapsed - SystemClock.elapsedRealtime()
            val status = prefs.getString(TaktAppWidgetProvider.KEY_STATUS, "FOCUS") ?: "FOCUS"
            tile.subtitle = when {
                running && leftMillis > 0 -> "$status · ${(leftMillis + 59_999) / 60_000} MIN"
                running -> "STARTING"
                else -> "STANDBY"
            }
        }
        tile.updateTile()
    }
}
