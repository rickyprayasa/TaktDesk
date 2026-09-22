package com.zykl.app

import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.view.WindowManager
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.WindowInsetsControllerCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        @Volatile
        var lastAlarmTimestamp: Long = 0L

        @Volatile
        var activeInstance: MainActivity? = null

        fun shouldPlayAlarm(): Boolean {
            val now = System.currentTimeMillis()
            return if (now - lastAlarmTimestamp > 3500L) {
                lastAlarmTimestamp = now
                true
            } else {
                false
            }
        }

        fun sendWidgetAction(action: String, data: Map<String, Any>? = null) {
            activeInstance?.let { activity ->
                activity.runOnUiThread {
                    val args = mutableMapOf<String, Any>("action" to action)
                    if (data != null) args.putAll(data)
                    activity.widgetChannel?.invokeMethod("onWidgetAction", args)
                }
            }
        }
    }

    private val FOCUS_CHANNEL = "com.takt.desk/focus_lock"
    private val AUDIO_CHANNEL = "com.takt.desk/audio"
    private val TIMER_CHANNEL = "com.takt.desk/timer_service"
    private val WIDGET_CHANNEL = "com.takt.desk/app_widget"
    private var widgetChannel: MethodChannel? = null
    private var initialWidgetAction: String? = null
    private var previousInterruptionFilter: Int? = null
    private var soundscapePlayer: MediaPlayer? = null
    private var masterVolume: Float = 0.8f
    private val screenWakeHandler = Handler(Looper.getMainLooper())

    private fun safeStopAndReset(player: MediaPlayer?) {
        try {
            if (player?.isPlaying == true) {
                player.stop()
            }
        } catch (_: Exception) {}
        try {
            player?.reset()
        } catch (_: Exception) {}
    }

    private fun safeRelease(player: MediaPlayer?) {
        try {
            if (player?.isPlaying == true) {
                player.stop()
            }
        } catch (_: Exception) {}
        try {
            player?.release()
        } catch (_: Exception) {}
    }

    private fun updateVolume() {
        val vol = masterVolume.coerceIn(0f, 1f)
        try {
            soundscapePlayer?.setVolume(vol, vol)
        } catch (_: Exception) {}
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        activeInstance = this
        notifyAllWidgets()
    }

    override fun onResume() {
        super.onResume()
        activeInstance = this
        notifyAllWidgets()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        if (initialWidgetAction == null) {
            initialWidgetAction = intent?.getStringExtra("open_feature")
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, FOCUS_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "enableFocusLock" -> {
                    try {
                        screenWakeHandler.removeCallbacksAndMessages(null)
                        // 1. Keep Screen Awake
                        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)

                        // 2. Hide System Bars (Immersive Sticky)
                        val controller = WindowCompat.getInsetsController(window, window.decorView)
                        controller.systemBarsBehavior = WindowInsetsControllerCompat.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
                        controller.hide(WindowInsetsCompat.Type.systemBars())

                        // 3. Do Not Disturb (silence all notifications & phone calls if permitted)
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            val notifManager = getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
                            if (notifManager != null && notifManager.isNotificationPolicyAccessGranted) {
                                previousInterruptionFilter = notifManager.currentInterruptionFilter
                                notifManager.setInterruptionFilter(NotificationManager.INTERRUPTION_FILTER_NONE)
                            }
                        }

                        // 4. Native Android App Pinning (Lock Task Mode)
                        try {
                            startLockTask()
                        } catch (e: Exception) {
                            android.util.Log.w("MainActivity", "startLockTask failed: ${e.message}")
                        }

                        result.success(true)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                "disableFocusLock" -> {
                    try {
                        // 1. Native Android App Pinning (Stop Lock Task Mode)
                        try {
                            stopLockTask()
                        } catch (e: Exception) {
                            android.util.Log.w("MainActivity", "stopLockTask failed: ${e.message}")
                        }

                        // 2. Restore System Bars
                        val controller = WindowCompat.getInsetsController(window, window.decorView)
                        controller.show(WindowInsetsCompat.Type.systemBars())

                        // 3. Restore Do Not Disturb
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            val notifManager = getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
                            if (notifManager != null && notifManager.isNotificationPolicyAccessGranted) {
                                val restoreFilter = previousInterruptionFilter ?: NotificationManager.INTERRUPTION_FILTER_ALL
                                notifManager.setInterruptionFilter(restoreFilter)
                                previousInterruptionFilter = null
                            }
                        }

                        // 4. Keep screen awake for 15s so user can observe completed timer & hear alarm before timeout
                        screenWakeHandler.removeCallbacksAndMessages(null)
                        screenWakeHandler.postDelayed({
                            window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                        }, 15000L)

                        result.success(true)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                "isLockTaskPermitted" -> {
                    result.success(true)
                }
                "isNotificationPolicyAccessGranted" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        val notifManager = getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
                        result.success(notifManager?.isNotificationPolicyAccessGranted == true)
                    } else {
                        result.success(true)
                    }
                }
                "openNotificationPolicySettings" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        try {
                            val intent = Intent(Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS).apply {
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            result.success(false)
                        }
                    } else {
                        result.success(false)
                    }
                }
                "openUrl" -> {
                    val url = call.argument<String>("url")
                    if (!url.isNullOrBlank()) {
                        try {
                            val uri = android.net.Uri.parse(url)
                            val scheme = uri.scheme?.lowercase()
                            if (scheme == "http" || scheme == "https" || scheme == "mailto" || scheme == "market") {
                                val intent = Intent(Intent.ACTION_VIEW, uri).apply {
                                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                }
                                startActivity(intent)
                                result.success(true)
                            } else {
                                result.error("INVALID_SCHEME", "Only http/https/mailto/market allowed", null)
                            }
                        } catch (e: Exception) {
                            result.error("URL_ERROR", e.localizedMessage, null)
                        }
                    } else {
                        result.error("INVALID_ARGS", "URL is null or empty", null)
                    }
                }
                "getDeviceInfo" -> {
                    try {
                        val pInfo = packageManager.getPackageInfo(packageName, 0)
                        val versionName = pInfo.versionName ?: "1.0.0"
                        val versionCode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                            pInfo.longVersionCode
                        } else {
                            @Suppress("DEPRECATION")
                            pInfo.versionCode.toLong()
                        }
                        val info = mapOf(
                            "manufacturer" to Build.MANUFACTURER,
                            "model" to Build.MODEL,
                            "device" to Build.DEVICE,
                            "brand" to Build.BRAND,
                            "osVersion" to Build.VERSION.RELEASE,
                            "sdkInt" to Build.VERSION.SDK_INT,
                            "versionName" to versionName,
                            "versionCode" to versionCode
                        )
                        result.success(info)
                    } catch (e: Exception) {
                        result.success(mapOf(
                            "manufacturer" to Build.MANUFACTURER,
                            "model" to Build.MODEL,
                            "device" to Build.DEVICE,
                            "brand" to Build.BRAND,
                            "osVersion" to Build.VERSION.RELEASE,
                            "sdkInt" to Build.VERSION.SDK_INT,
                            "versionName" to "1.0.0",
                            "versionCode" to 104
                        ))
                    }
                }
                "sendFeedbackEmail" -> {
                    try {
                        val subject = call.argument<String>("subject") ?: "[ZYKL Feedback]"
                        val body = call.argument<String>("body") ?: ""
                        val to = "support@zykl.app"

                        val uriText = "mailto:$to?subject=${android.net.Uri.encode(subject)}&body=${android.net.Uri.encode(body)}"
                        val uri = android.net.Uri.parse(uriText)

                        // Attempt 1: Try Gmail app specifically
                        val gmailIntent = Intent(Intent.ACTION_SENDTO, uri).apply {
                            setPackage("com.google.android.gm")
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }

                        try {
                            startActivity(gmailIntent)
                            result.success(true)
                        } catch (_: Exception) {
                            // Attempt 2: System email chooser
                            val mailIntent = Intent(Intent.ACTION_SENDTO, uri).apply {
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                            val chooser = Intent.createChooser(mailIntent, "Kirim Feedback via").apply {
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                            startActivity(chooser)
                            result.success(true)
                        }
                    } catch (e: Exception) {
                        result.error("EMAIL_ERROR", e.localizedMessage, null)
                    }
                }
                "openPlayStore" -> {
                    try {
                        val pkg = packageName
                        val marketUri = android.net.Uri.parse("market://details?id=$pkg")
                        val marketIntent = Intent(Intent.ACTION_VIEW, marketUri).apply {
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_NO_HISTORY)
                        }
                        startActivity(marketIntent)
                        result.success(true)
                    } catch (_: Exception) {
                        try {
                            val pkg = packageName
                            val webUri = android.net.Uri.parse("https://play.google.com/store/apps/details?id=$pkg")
                            val webIntent = Intent(Intent.ACTION_VIEW, webUri).apply {
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                            startActivity(webIntent)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("PLAYSTORE_ERROR", e.localizedMessage, null)
                        }
                    }
                }
                else -> result.notImplemented()
            }
        }

        // 2. Analog Vinyl & Foley Audio Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, AUDIO_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startAmbient" -> {
                    try {
                        val trackIndex = call.argument<Number>("trackIndex")?.toInt() ?: 0
                        masterVolume = (call.argument<Number>("volume")?.toDouble() ?: 0.8).toFloat()
                        val rawAssetPath = call.argument<String>("assetPath")

                        val assetPath = if (!rawAssetPath.isNullOrEmpty()) {
                            "flutter_assets/$rawAssetPath"
                        } else {
                            when (trackIndex) {
                                0 -> "flutter_assets/assets/audio/vinyl_lofi_rain.wav"
                                1 -> "flutter_assets/assets/audio/vinyl_brown_noise.wav"
                                2 -> "flutter_assets/assets/audio/vinyl_library.wav"
                                3 -> "flutter_assets/assets/audio/vinyl_kyoto_bamboo.wav"
                                4 -> "flutter_assets/assets/audio/vinyl_campfire.wav"
                                5 -> "flutter_assets/assets/audio/vinyl_nordic_pines.wav"
                                6 -> "flutter_assets/assets/audio/vinyl_alpine_brook.wav"
                                7 -> "flutter_assets/assets/audio/vinyl_ocean_waves.wav"
                                8 -> "flutter_assets/assets/audio/vinyl_morning_meadow.wav"
                                9 -> "flutter_assets/assets/audio/vinyl_timber_chamber.wav"
                                10 -> "flutter_assets/assets/audio/vinyl_warm_tape.wav"
                                11 -> "flutter_assets/assets/audio/vinyl_rhodes_velvet.wav"
                                12 -> "flutter_assets/assets/audio/vinyl_acoustic_guitar.wav"
                                13 -> "flutter_assets/assets/audio/vinyl_ambient_drift.wav"
                                14 -> "flutter_assets/assets/audio/vinyl_felt_piano_solo.wav"
                                15 -> "flutter_assets/assets/audio/vinyl_modular_clockwork.wav"
                                16 -> "flutter_assets/assets/audio/vinyl_goldberg_aria.wav"
                                17 -> "flutter_assets/assets/audio/vinyl_chopin_nocturne.wav"
                                18 -> "flutter_assets/assets/audio/vinyl_spanish_romance.wav"
                                19 -> "flutter_assets/assets/audio/vinyl_chamber_quartet.wav"
                                else -> "flutter_assets/assets/audio/vinyl_lofi_rain.wav"
                            }
                        }

                        // Primary Soundscape Player
                        safeStopAndReset(soundscapePlayer)
                        val pPlayer = soundscapePlayer ?: MediaPlayer().also { soundscapePlayer = it }
                        val fd = try {
                            context.assets.openFd(assetPath)
                        } catch (_: Exception) {
                            context.assets.openFd(assetPath.removePrefix("flutter_assets/"))
                        }
                        fd.use {
                            pPlayer.setDataSource(it.fileDescriptor, it.startOffset, it.length)
                            pPlayer.isLooping = true
                            pPlayer.prepare()
                        }

                        updateVolume()

                        pPlayer.start()

                        result.success(true)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                "stopAmbient" -> {
                    try {
                        safeStopAndReset(soundscapePlayer)
                        result.success(true)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                "setVolume" -> {
                    try {
                        masterVolume = (call.argument<Number>("volume")?.toDouble() ?: 0.8).toFloat()
                        updateVolume()
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
                            "bellChime" -> "flutter_assets/assets/audio/alarm_braun_bell.wav"
                            "drawerSlide" -> "flutter_assets/assets/audio/foley_drawer_slide.wav"
                            "drawerLatch" -> "flutter_assets/assets/audio/foley_drawer_latch.wav"
                            "discLoad" -> "flutter_assets/assets/audio/foley_disc_load.wav"
                            else -> null
                        }
                        if (foleyAsset != null) {
                            context.assets.openFd(foleyAsset).use { fd ->
                                MediaPlayer().apply {
                                    setDataSource(fd.fileDescriptor, fd.startOffset, fd.length)
                                    setOnCompletionListener { mp -> mp.release() }
                                    prepare()
                                    start()
                                }
                            }
                        }
                        result.success(true)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                "playAlarmChime" -> {
                    try {
                        if (!shouldPlayAlarm()) {
                            result.success(true)
                            return@setMethodCallHandler
                        }
                        val chimeId = call.argument<String>("chimeId") ?: "braunBell"
                        val chimeAsset = when (chimeId) {
                            "braunBell" -> "flutter_assets/assets/audio/alarm_braun_bell.wav"
                            "deskBell" -> "flutter_assets/assets/audio/alarm_desk_bell.wav"
                            "tibetanBowl" -> "flutter_assets/assets/audio/alarm_tibetan_bowl.wav"
                            "zenGong" -> "flutter_assets/assets/audio/alarm_zen_gong.wav"
                            "tubularChime" -> "flutter_assets/assets/audio/alarm_tubular_chime.wav"
                            else -> "flutter_assets/assets/audio/alarm_braun_bell.wav"
                        }
                        context.assets.openFd(chimeAsset).use { fd ->
                            MediaPlayer().apply {
                                setAudioAttributes(
                                    AudioAttributes.Builder()
                                        .setUsage(AudioAttributes.USAGE_ALARM)
                                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                                        .build()
                                )
                                setDataSource(fd.fileDescriptor, fd.startOffset, fd.length)
                                setOnCompletionListener { mp -> mp.release() }
                                prepare()
                                start()
                            }
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
                        val alarmChimeId = call.argument<String>("alarmChimeId") ?: "braunBell"

                        val serviceIntent = Intent(this, TimerForegroundService::class.java).apply {
                            action = TimerForegroundService.ACTION_START
                            putExtra(TimerForegroundService.EXTRA_REMAINING_SECONDS, remainingSeconds)
                            putExtra(TimerForegroundService.EXTRA_TARGET_MINUTES, targetMinutes)
                            putExtra(TimerForegroundService.EXTRA_PHASE, phase)
                            putExtra(TimerForegroundService.EXTRA_CYCLE_COUNT, cycleCount)
                            putExtra(TimerForegroundService.EXTRA_PROFILE_NAME, profileName)
                            putExtra(TimerForegroundService.EXTRA_ALARM_CHIME_ID, alarmChimeId)
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

        val mediaChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.zykl.app/media_notification")
        MediaNotificationService.mediaControlListener = { action ->
            runOnUiThread {
                mediaChannel.invokeMethod("onMediaControlAction", mapOf("action" to action))
            }
        }
        mediaChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "startMediaNotification" -> {
                    try {
                        val trackIndex = (call.argument<Number>("trackIndex"))?.toInt() ?: 0
                        val trackName = call.argument<String>("trackName") ?: "LO-FI RAIN"
                        val isPlaying = call.argument<Boolean>("isPlaying") ?: false
                        val volume = (call.argument<Number>("volume"))?.toDouble() ?: 0.8
                        val phase = call.argument<String>("phase") ?: "focus"
                        val remainingSeconds = (call.argument<Number>("remainingSeconds"))?.toDouble() ?: 1500.0
                        val cycleCount = (call.argument<Number>("cycleCount"))?.toInt() ?: 1

                        val serviceIntent = Intent(this, MediaNotificationService::class.java).apply {
                            action = MediaNotificationService.ACTION_START
                            putExtra(MediaNotificationService.EXTRA_TRACK_INDEX, trackIndex)
                            putExtra(MediaNotificationService.EXTRA_TRACK_NAME, trackName)
                            putExtra(MediaNotificationService.EXTRA_IS_PLAYING, isPlaying)
                            putExtra(MediaNotificationService.EXTRA_VOLUME, volume)
                            putExtra(MediaNotificationService.EXTRA_PHASE, phase)
                            putExtra(MediaNotificationService.EXTRA_REMAINING_SECONDS, remainingSeconds)
                            putExtra(MediaNotificationService.EXTRA_CYCLE_COUNT, cycleCount)
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
                "updatePlaybackState" -> {
                    try {
                        val isPlaying = call.argument<Boolean>("isPlaying") ?: false
                        val trackIndex = (call.argument<Number>("trackIndex"))?.toInt() ?: 0
                        val trackName = call.argument<String>("trackName") ?: "LO-FI RAIN"
                        val volume = (call.argument<Number>("volume"))?.toDouble() ?: 0.8

                        val serviceIntent = Intent(this, MediaNotificationService::class.java).apply {
                            action = MediaNotificationService.ACTION_UPDATE_PLAYBACK
                            putExtra(MediaNotificationService.EXTRA_IS_PLAYING, isPlaying)
                            putExtra(MediaNotificationService.EXTRA_TRACK_INDEX, trackIndex)
                            putExtra(MediaNotificationService.EXTRA_TRACK_NAME, trackName)
                            putExtra(MediaNotificationService.EXTRA_VOLUME, volume)
                        }
                        startService(serviceIntent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                "updateTimerTelemetry" -> {
                    try {
                        val phase = call.argument<String>("phase") ?: "focus"
                        val remainingSeconds = (call.argument<Number>("remainingSeconds"))?.toDouble() ?: 1500.0
                        val cycleCount = (call.argument<Number>("cycleCount"))?.toInt() ?: 1

                        val serviceIntent = Intent(this, MediaNotificationService::class.java).apply {
                            action = MediaNotificationService.ACTION_UPDATE_TIMER
                            putExtra(MediaNotificationService.EXTRA_PHASE, phase)
                            putExtra(MediaNotificationService.EXTRA_REMAINING_SECONDS, remainingSeconds)
                            putExtra(MediaNotificationService.EXTRA_CYCLE_COUNT, cycleCount)
                        }
                        startService(serviceIntent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                "stopMediaNotification" -> {
                    try {
                        val serviceIntent = Intent(this, MediaNotificationService::class.java).apply {
                            action = MediaNotificationService.ACTION_STOP
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
        this.widgetChannel = widgetChannel
        widgetChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "getInitialAction" -> {
                    val action = initialWidgetAction ?: intent?.getStringExtra("open_feature")
                    initialWidgetAction = null
                    intent?.removeExtra("open_feature")
                    result.success(action)
                }
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

                        notifyAllWidgets()
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("WIDGET_UPDATE_FAILED", e.message, null)
                    }
                }
                "updateAllWidgetData" -> {
                    try {
                        val cycles = (call.argument<Number>("cyclesCompleted"))?.toInt() ?: 0
                        val target = (call.argument<Number>("cyclesTarget"))?.toInt() ?: 4
                        val minutes = (call.argument<Number>("minutesFocused"))?.toInt() ?: 0
                        val status = call.argument<String>("status") ?: "STANDBY"
                        val remainingSeconds = (call.argument<Number>("remainingSeconds"))?.toInt() ?: 0
                        val targetMinutes = (call.argument<Number>("targetMinutes"))?.toInt() ?: 25
                        val tasksList = call.argument<List<Map<String, Any>>>("tasks") ?: emptyList()
                        val tasksJson = org.json.JSONArray(tasksList).toString()
                        val isPro = call.argument<Boolean>("isPro") ?: false

                        val prefs = getSharedPreferences(TaktAppWidgetProvider.PREFS_NAME, Context.MODE_PRIVATE)
                        prefs.edit()
                            .putInt(TaktAppWidgetProvider.KEY_CYCLES_COMPLETED, cycles)
                            .putInt(TaktAppWidgetProvider.KEY_CYCLES_TARGET, target)
                            .putInt(TaktAppWidgetProvider.KEY_MINUTES_FOCUSED, minutes)
                            .putString(TaktAppWidgetProvider.KEY_STATUS, status)
                            .putInt(TaktAppWidgetProvider.KEY_REMAINING_SECONDS, remainingSeconds)
                            .putInt(TaktAppWidgetProvider.KEY_TARGET_MINUTES, targetMinutes)
                            .putString(TaktAppWidgetProvider.KEY_TASKS_JSON, tasksJson)
                            .putBoolean(TaktAppWidgetProvider.KEY_IS_PRO, isPro)
                            .apply()

                        notifyAllWidgets()
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("WIDGET_UPDATE_FAILED", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        val action = intent.getStringExtra("open_feature")
        if (!action.isNullOrEmpty()) {
            widgetChannel?.invokeMethod("onWidgetAction", mapOf("action" to action))
        }
    }

    private fun notifyAllWidgets() {
        try {
            TaktAppWidgetProvider.updateAllWidgets(this)
            TaktFocusStripWidgetProvider.updateAllWidgets(this)
            TaktAnalogDialWidgetProvider.updateAllWidgets(this)
            TaktTaskDispenserWidgetProvider.updateAllWidgets(this)
        } catch (_: Throwable) {}
    }

    override fun onDestroy() {
        if (activeInstance == this) {
            activeInstance = null
        }
        screenWakeHandler.removeCallbacksAndMessages(null)
        MediaNotificationService.mediaControlListener = null
        safeRelease(soundscapePlayer)
        soundscapePlayer = null
        super.onDestroy()
    }
}
