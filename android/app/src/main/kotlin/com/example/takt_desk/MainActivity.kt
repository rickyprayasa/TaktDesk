package com.example.takt_desk

import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.media.MediaPlayer
import android.os.Build
import android.view.WindowManager
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.WindowInsetsControllerCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val FOCUS_CHANNEL = "com.takt.desk/focus_lock"
    private val AUDIO_CHANNEL = "com.takt.desk/audio"
    private val TIMER_CHANNEL = "com.takt.desk/timer_service"
    private val WIDGET_CHANNEL = "com.takt.desk/app_widget"
    private var previousInterruptionFilter: Int? = null
    private var soundscapePlayer: MediaPlayer? = null
    private var cracklePlayer: MediaPlayer? = null
    private var binauralPlayer: MediaPlayer? = null
    private var masterVolume: Float = 0.8f
    private var primaryGain: Float = 0.80f
    private var crackleGain: Float = 0.35f
    private var binauralGain: Float = 0.25f

    private fun updateAllVolumes() {
        val pVol = (masterVolume * primaryGain).coerceIn(0f, 1f)
        val cVol = (masterVolume * crackleGain).coerceIn(0f, 1f)
        val bVol = (masterVolume * binauralGain).coerceIn(0f, 1f)
        try {
            soundscapePlayer?.setVolume(pVol, pVol)
        } catch (_: Exception) {}
        try {
            cracklePlayer?.setVolume(cVol, cVol)
        } catch (_: Exception) {}
        try {
            binauralPlayer?.setVolume(bVol, bVol)
        } catch (_: Exception) {}
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, FOCUS_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "enableFocusLock" -> {
                    try {
                        // 1. Keep Screen Awake
                        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)

                        // 2. Hide System Bars (Immersive Sticky)
                        val controller = WindowCompat.getInsetsController(window, window.decorView)
                        controller.systemBarsBehavior = WindowInsetsControllerCompat.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
                        controller.hide(WindowInsetsCompat.Type.systemBars())

                        // 3. Android Screen Pinning / Lock Task Mode
                        try {
                            startLockTask()
                        } catch (_: Exception) {}

                        // 4. Do Not Disturb (silence notifications if permitted)
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            val notifManager = getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
                            if (notifManager != null && notifManager.isNotificationPolicyAccessGranted) {
                                previousInterruptionFilter = notifManager.currentInterruptionFilter
                                notifManager.setInterruptionFilter(NotificationManager.INTERRUPTION_FILTER_PRIORITY)
                            }
                        }
                        result.success(true)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                "disableFocusLock" -> {
                    try {
                        // 1. Clear Screen On flag
                        window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)

                        // 2. Restore System Bars
                        val controller = WindowCompat.getInsetsController(window, window.decorView)
                        controller.show(WindowInsetsCompat.Type.systemBars())

                        // 3. Stop Lock Task Mode
                        try {
                            stopLockTask()
                        } catch (_: Exception) {}

                        // 4. Restore Do Not Disturb
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            val notifManager = getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
                            if (notifManager != null && notifManager.isNotificationPolicyAccessGranted) {
                                val restoreFilter = previousInterruptionFilter ?: NotificationManager.INTERRUPTION_FILTER_ALL
                                notifManager.setInterruptionFilter(restoreFilter)
                                previousInterruptionFilter = null
                            }
                        }
                        result.success(true)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                "isLockTaskPermitted" -> {
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

        // 2. Analog Vinyl & Foley Audio Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, AUDIO_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startAmbient" -> {
                    try {
                        val trackIndex = call.argument<Int>("trackIndex") ?: 0
                        masterVolume = (call.argument<Double>("volume") ?: 0.8).toFloat()
                        primaryGain = (call.argument<Double>("primaryVolume") ?: 0.8).toFloat()
                        crackleGain = (call.argument<Double>("crackleVolume") ?: 0.35).toFloat()
                        binauralGain = (call.argument<Double>("binauralVolume") ?: 0.25).toFloat()

                        val assetPath = when (trackIndex) {
                            0 -> "flutter_assets/assets/audio/vinyl_lofi_rain.wav"
                            1 -> "flutter_assets/assets/audio/vinyl_brown_noise.wav"
                            2 -> "flutter_assets/assets/audio/vinyl_library.wav"
                            3 -> "flutter_assets/assets/audio/vinyl_cafe.wav"
                            4 -> "flutter_assets/assets/audio/vinyl_campfire.wav"
                            5 -> "flutter_assets/assets/audio/vinyl_forest.wav"
                            6 -> "flutter_assets/assets/audio/vinyl_cosmic.wav"
                            7 -> "flutter_assets/assets/audio/vinyl_train.wav"
                            else -> "flutter_assets/assets/audio/vinyl_lofi_rain.wav"
                        }

                        // 1. Primary Soundscape Player
                        soundscapePlayer?.apply {
                            if (isPlaying) stop()
                            reset()
                        }
                        soundscapePlayer = soundscapePlayer ?: MediaPlayer()
                        val fdPrimary = context.assets.openFd(assetPath)
                        soundscapePlayer?.apply {
                            reset()
                            setDataSource(fdPrimary.fileDescriptor, fdPrimary.startOffset, fdPrimary.length)
                            isLooping = true
                            prepare()
                            start()
                        }
                        fdPrimary.close()

                        // 2. Vinyl Surface Crackle Player
                        cracklePlayer?.apply {
                            if (isPlaying) stop()
                            reset()
                        }
                        cracklePlayer = cracklePlayer ?: MediaPlayer()
                        val fdCrackle = context.assets.openFd("flutter_assets/assets/audio/vinyl_surface_crackle.wav")
                        cracklePlayer?.apply {
                            reset()
                            setDataSource(fdCrackle.fileDescriptor, fdCrackle.startOffset, fdCrackle.length)
                            isLooping = true
                            prepare()
                            start()
                        }
                        fdCrackle.close()

                        // 3. Binaural Alpha 432 Hz Drone Player
                        binauralPlayer?.apply {
                            if (isPlaying) stop()
                            reset()
                        }
                        binauralPlayer = binauralPlayer ?: MediaPlayer()
                        val fdBinaural = context.assets.openFd("flutter_assets/assets/audio/binaural_alpha_432.wav")
                        binauralPlayer?.apply {
                            reset()
                            setDataSource(fdBinaural.fileDescriptor, fdBinaural.startOffset, fdBinaural.length)
                            isLooping = true
                            prepare()
                            start()
                        }
                        fdBinaural.close()

                        updateAllVolumes()
                        result.success(true)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                "stopAmbient" -> {
                    try {
                        soundscapePlayer?.apply { if (isPlaying) stop(); reset() }
                        cracklePlayer?.apply { if (isPlaying) stop(); reset() }
                        binauralPlayer?.apply { if (isPlaying) stop(); reset() }
                        result.success(true)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                "setMixerLevels" -> {
                    try {
                        primaryGain = (call.argument<Double>("primaryVolume") ?: primaryGain.toDouble()).toFloat()
                        crackleGain = (call.argument<Double>("crackleVolume") ?: crackleGain.toDouble()).toFloat()
                        binauralGain = (call.argument<Double>("binauralVolume") ?: binauralGain.toDouble()).toFloat()
                        updateAllVolumes()
                        result.success(true)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                "setVolume" -> {
                    try {
                        masterVolume = (call.argument<Double>("volume") ?: 0.8).toFloat()
                        updateAllVolumes()
                        result.success(true)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                "playFoley" -> {
                    try {
                        val effect = call.argument<String>("effect")
                        val foleyAsset = when (effect) {
                            "stylusDrop" -> "flutter_assets/assets/audio/foley_stylus_drop.wav"
                            "stylusStop" -> "flutter_assets/assets/audio/foley_stylus_stop.wav"
                            "dialClick" -> "flutter_assets/assets/audio/foley_dial_click.wav"
                            "paperTear" -> "flutter_assets/assets/audio/foley_paper_tear.wav"
                            "inkStamp" -> "flutter_assets/assets/audio/foley_ink_stamp.wav"
                            "switchClick" -> "flutter_assets/assets/audio/foley_switch_click.wav"
                            "bellChime" -> "flutter_assets/assets/audio/foley_bell_chime.wav"
                            "drawerSlide" -> "flutter_assets/assets/audio/foley_drawer_slide.wav"
                            "drawerLatch" -> "flutter_assets/assets/audio/foley_drawer_latch.wav"
                            "discLoad" -> "flutter_assets/assets/audio/foley_disc_load.wav"
                            else -> null
                        }
                        if (foleyAsset != null) {
                            val fd = context.assets.openFd(foleyAsset)
                            val foleyPlayer = MediaPlayer().apply {
                                setDataSource(fd.fileDescriptor, fd.startOffset, fd.length)
                                setOnCompletionListener { mp -> mp.release() }
                                prepare()
                                start()
                            }
                            fd.close()
                        }
                        result.success(true)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, TIMER_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startService" -> {
                    try {
                        val remainingSeconds = (call.argument<Number>("remainingSeconds"))?.toDouble() ?: 0.0
                        val targetMinutes = (call.argument<Number>("targetMinutes"))?.toInt() ?: 25
                        val phase = call.argument<String>("phase") ?: "focus"
                        val cycleCount = (call.argument<Number>("cycleCount"))?.toInt() ?: 1
                        val profileName = call.argument<String>("profileName") ?: "CLASSIC 25/5"

                        val serviceIntent = Intent(this, TimerForegroundService::class.java).apply {
                            action = TimerForegroundService.ACTION_START
                            putExtra(TimerForegroundService.EXTRA_REMAINING_SECONDS, remainingSeconds)
                            putExtra(TimerForegroundService.EXTRA_TARGET_MINUTES, targetMinutes)
                            putExtra(TimerForegroundService.EXTRA_PHASE, phase)
                            putExtra(TimerForegroundService.EXTRA_CYCLE_COUNT, cycleCount)
                            putExtra(TimerForegroundService.EXTRA_PROFILE_NAME, profileName)
                        }

                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            startForegroundService(serviceIntent)
                        } else {
                            startService(serviceIntent)
                        }
                        result.success(true)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                "stopService" -> {
                    try {
                        val serviceIntent = Intent(this, TimerForegroundService::class.java).apply {
                            action = TimerForegroundService.ACTION_STOP
                        }
                        startService(serviceIntent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                else -> result.notImplemented()
            }
        }

        val widgetChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WIDGET_CHANNEL)
        widgetChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "updateWidgetData" -> {
                    try {
                        val cycles = (call.argument<Number>("cyclesCompleted"))?.toInt() ?: 0
                        val target = (call.argument<Number>("cyclesTarget"))?.toInt() ?: 4
                        val minutes = (call.argument<Number>("minutesFocused"))?.toInt() ?: 0
                        val status = call.argument<String>("status") ?: "STANDBY"

                        val prefs = getSharedPreferences(TaktAppWidgetProvider.PREFS_NAME, Context.MODE_PRIVATE)
                        prefs.edit()
                            .putInt(TaktAppWidgetProvider.KEY_CYCLES_COMPLETED, cycles)
                            .putInt(TaktAppWidgetProvider.KEY_CYCLES_TARGET, target)
                            .putInt(TaktAppWidgetProvider.KEY_MINUTES_FOCUSED, minutes)
                            .putString(TaktAppWidgetProvider.KEY_STATUS, status)
                            .apply()

                        TaktAppWidgetProvider.updateAllWidgets(this)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("WIDGET_UPDATE_FAILED", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onDestroy() {
        try {
            soundscapePlayer?.apply { if (isPlaying) stop(); release() }
            soundscapePlayer = null
            cracklePlayer?.apply { if (isPlaying) stop(); release() }
            cracklePlayer = null
            binauralPlayer?.apply { if (isPlaying) stop(); release() }
            binauralPlayer = null
        } catch (_: Exception) {}
        super.onDestroy()
    }
}
