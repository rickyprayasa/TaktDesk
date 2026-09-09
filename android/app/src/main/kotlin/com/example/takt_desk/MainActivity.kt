package com.example.takt_desk

import android.app.NotificationManager
import android.content.Context
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
    private val FOCUS_CHANNEL = "com.tuneeca.takt_desk/focus_lock"
    private val AUDIO_CHANNEL = "com.tuneeca.takt_desk/audio"
    private var previousInterruptionFilter: Int? = null
    private var ambientPlayer: MediaPlayer? = null

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
                        val volume = (call.argument<Double>("volume") ?: 0.8).toFloat()
                        val assetPath = when (trackIndex) {
                            0 -> "flutter_assets/assets/audio/vinyl_lofi_rain.wav"
                            1 -> "flutter_assets/assets/audio/vinyl_brown_noise.wav"
                            2 -> "flutter_assets/assets/audio/vinyl_library.wav"
                            3 -> "flutter_assets/assets/audio/vinyl_cafe.wav"
                            else -> "flutter_assets/assets/audio/vinyl_lofi_rain.wav"
                        }
                        val fd = context.assets.openFd(assetPath)
                        ambientPlayer?.apply {
                            if (isPlaying) {
                                stop()
                            }
                            reset()
                        }
                        ambientPlayer = ambientPlayer ?: MediaPlayer()
                        ambientPlayer?.apply {
                            reset()
                            setDataSource(fd.fileDescriptor, fd.startOffset, fd.length)
                            isLooping = true
                            setVolume(volume, volume)
                            prepare()
                            start()
                        }
                        fd.close()
                        result.success(true)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                "stopAmbient" -> {
                    try {
                        ambientPlayer?.apply {
                            if (isPlaying) {
                                stop()
                            }
                            reset()
                        }
                        result.success(true)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                "setVolume" -> {
                    try {
                        val volume = (call.argument<Double>("volume") ?: 0.8).toFloat()
                        ambientPlayer?.setVolume(volume, volume)
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
    }

    override fun onDestroy() {
        try {
            ambientPlayer?.apply {
                if (isPlaying) stop()
                release()
            }
            ambientPlayer = null
        } catch (_: Exception) {}
        super.onDestroy()
    }
}
