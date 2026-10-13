package com.zykl.app

import android.Manifest
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
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
        /** Window brightness of the dimmed desk clock (0..1): readable in a dark room, far below a typical setting. */
        private const val DESK_CLOCK_DIM_BRIGHTNESS = 0.04f

        /** Lockdown's Do Not Disturb claim: set by enableFocusLock, cleared when DND is restored. */
        private const val LOCKDOWN_PREFS = "zykl_lockdown"
        private const val KEY_DND_APPLIED = "dnd_applied"
        private const val KEY_DND_PREVIOUS = "dnd_previous_filter"

        @Volatile
        var lastAlarmTimestamp: Long = 0L

        /** The activity is on screen (resumed). */
        @Volatile
        var isInForeground: Boolean = false
            private set

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

        private const val PERMISSION_PREFS = "zykl_permissions"
        private const val KEY_NOTIFICATION_ASKED = "post_notifications_asked"
        private const val REQUEST_POST_NOTIFICATIONS = 3001
        private const val REQUEST_SAVE_FILE = 3101
        private const val REQUEST_OPEN_FILE = 3102
        /** A ZYKL backup is a few hundred KB at most; refuse anything far bigger. */
        private const val MAX_BACKUP_BYTES = 8 * 1024 * 1024
        private const val AUDIO_DIR = "flutter_assets/assets/audio/"
        private val VINYL_ASSET = Regex("""assets/audio/vinyl_[a-z0-9_]+\.ogg""")

        val FOLEY_ASSETS: Map<String, String> = mapOf(
            "stylusDrop" to "foley_stylus_drop.wav",
            "stylusStop" to "foley_stylus_stop.wav",
            "dialClick" to "foley_dial_click.wav",
            // Crown (CC0 field recordings, see assets/audio/CREDITS.md): push (start / pause / set) and pull out.
            "springButton" to "foley_crown_press.wav",
            "crownPull" to "foley_crown_pull.wav",
            "paperTear" to "foley_paper_tear.wav",
            "inkStamp" to "foley_ink_stamp.wav",
            "switchClick" to "foley_switch_click.wav",
            "bellChime" to "alarm_braun_bell.wav",
            "drawerSlide" to "foley_drawer_slide.wav",
            "drawerLatch" to "foley_drawer_latch.wav",
            "discLoad" to "foley_disc_load.wav",
        ).mapValues { AUDIO_DIR + it.value }

        /** Effects with several takes, one picked at random per play so fast repeats don't sound looped. */
        val FOLEY_VARIANTS: Map<String, List<String>> = mapOf(
            "crownWind" to listOf("foley_crown_wind_a.wav", "foley_crown_wind_b.wav", "foley_crown_wind_c.wav"),
        ).mapValues { (_, files) -> files.map { AUDIO_DIR + it } }

        val ALARM_ASSETS: Map<String, String> = mapOf(
            "braunBell" to "alarm_braun_bell.wav",
            "deskBell" to "alarm_desk_bell.wav",
            "tibetanBowl" to "alarm_tibetan_bowl.wav",
            "zenGong" to "alarm_zen_gong.wav",
            "tubularChime" to "alarm_tubular_chime.wav",
        ).mapValues { AUDIO_DIR + it.value }

        /**
         * Values another app may pass in the `open_feature` extra of this exported
         * launcher (our widgets send "tasks" / "dial", the launcher shortcuts "tasks" / "analytics"). Timer control such as
         * "toggleTimer" must come only from the non-exported WidgetActionReceiver
         * via [sendWidgetAction], never from an external intent.
         */
        private val EXTERNAL_FEATURES = setOf("studio_pro", "tasks", "dial", "analytics")

        fun externalFeature(intent: Intent?): String? =
            intent?.getStringExtra("open_feature")?.takeIf { it in EXTERNAL_FEATURES }

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
    private val DISPLAY_CHANNEL = "com.zykl.app/display"
    private val BACKUP_CHANNEL = "com.zykl.app/backup"
    private val WIDGET_THEME_CHANNEL = "com.zykl.app/widget_theme"

    /** Waiting system file picker (backup export / restore) and what to write once a file is chosen. */
    private var pendingFileResult: MethodChannel.Result? = null
    private var pendingFileContent: ByteArray? = null
    private val AUDIO_CHANNEL = "com.takt.desk/audio"
    private val TIMER_CHANNEL = "com.takt.desk/timer_service"
    private val WIDGET_CHANNEL = "com.takt.desk/app_widget"
    private var widgetChannel: MethodChannel? = null
    private var initialWidgetAction: String? = null
    private var soundscapePlayer: MediaPlayer? = null
    private var masterVolume: Float = 0.8f
    private var alarmPlayer: MediaPlayer? = null
    private var launchedAgain = false
    private val effectPlayer: EffectSoundPlayer by lazy { EffectSoundPlayer(this) }
    private val screenWakeHandler = Handler(Looper.getMainLooper())

    /** FLAG_KEEP_SCREEN_ON has two owners: Monastic Lockdown (plus its 15 s grace after release) and the desk clock
     *  mode while a timer runs. The flag stays while either wants it. */
    private var lockdownKeepsScreenOn = false
    private var deskClockKeepsScreenOn = false

    private fun applyKeepScreenOn() {
        if (lockdownKeepsScreenOn || deskClockKeepsScreenOn) {
            window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        } else {
            window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        }
    }

    private fun lockdownPrefs() = getSharedPreferences(LOCKDOWN_PREFS, Context.MODE_PRIVATE)

    /**
     * Puts Do Not Disturb back to what it was before Monastic Lockdown and forgets the claim. The claim is kept in
     * prefs, not only in memory, so a lockdown that never reached disableFocusLock (process killed, app swiped away
     * after unpinning) is undone on the next start instead of leaving calls silenced. Left alone when the user has
     * changed DND themselves since.
     */
    private fun restoreLockdownDnd() {
        val prefs = lockdownPrefs()
        if (!prefs.getBoolean(KEY_DND_APPLIED, false)) return
        val previous = prefs.getInt(KEY_DND_PREVIOUS, NotificationManager.INTERRUPTION_FILTER_ALL)
        prefs.edit().clear().apply()
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return
        try {
            val notifManager = getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager ?: return
            if (notifManager.isNotificationPolicyAccessGranted &&
                notifManager.currentInterruptionFilter == NotificationManager.INTERRUPTION_FILTER_ALARMS
            ) {
                notifManager.setInterruptionFilter(previous)
            }
        } catch (e: Exception) {
            android.util.Log.w("MainActivity", "DND restore failed: ${e.message}")
        }
    }

    /** Desk clock dimming: a low window brightness override, or the user's own brightness again. */
    private fun setDimmed(dimmed: Boolean) {
        val params = window.attributes
        params.screenBrightness = if (dimmed) DESK_CLOCK_DIM_BRIGHTNESS else WindowManager.LayoutParams.BRIGHTNESS_OVERRIDE_NONE
        window.attributes = params
    }

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
        // Recreated after a process kill, or reopened from Recents: the launch intent is the original one, so its
        // shortcut / widget action ("Start focus") must not run a second time.
        launchedAgain = savedInstanceState != null ||
            (intent?.flags ?: 0) and Intent.FLAG_ACTIVITY_LAUNCHED_FROM_HISTORY != 0
        super.onCreate(savedInstanceState)
        // A fresh activity has no lockdown: undo DND left on by one that ended with the app killed or swiped away.
        restoreLockdownDnd()
        activeInstance = this
        notifyAllWidgets()
        AppShortcuts.publish(this)
    }

    override fun onResume() {
        super.onResume()
        activeInstance = this
        isInForeground = true
        notifyAllWidgets()
    }

    override fun onPause() {
        isInForeground = false
        super.onPause()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        effectPlayer.preload(FOLEY_ASSETS.values.toSet() + FOLEY_VARIANTS.values.flatten() + ALARM_ASSETS.values)
        super.configureFlutterEngine(flutterEngine)
        if (initialWidgetAction == null) {
            initialWidgetAction = if (launchedAgain) null else externalFeature(intent) ?: AppShortcuts.action(this, intent)
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, FOCUS_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "enableFocusLock" -> {
                    try {
                        screenWakeHandler.removeCallbacksAndMessages(null)
                        // 1. Keep Screen Awake
                        lockdownKeepsScreenOn = true
                        applyKeepScreenOn()

                        // 2. Hide System Bars (Immersive Sticky)
                        val controller = WindowCompat.getInsetsController(window, window.decorView)
                        controller.systemBarsBehavior = WindowInsetsControllerCompat.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
                        controller.hide(WindowInsetsCompat.Type.systemBars())

                        // 3. Do Not Disturb (silence notifications & phone calls if permitted). "Alarms only", not
                        //    FILTER_NONE: total silence also muted media, so the vinyl soundscape, the foley and the
                        //    end-of-session chime went quiet the moment lockdown started.
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            val notifManager = getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
                            if (notifManager != null && notifManager.isNotificationPolicyAccessGranted) {
                                val prefs = lockdownPrefs()
                                if (!prefs.getBoolean(KEY_DND_APPLIED, false)) {
                                    prefs.edit()
                                        .putBoolean(KEY_DND_APPLIED, true)
                                        .putInt(KEY_DND_PREVIOUS, notifManager.currentInterruptionFilter)
                                        .apply()
                                }
                                notifManager.setInterruptionFilter(NotificationManager.INTERRUPTION_FILTER_ALARMS)
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
                        restoreLockdownDnd()

                        // 4. Keep screen awake for 15s so user can observe completed timer & hear alarm before timeout
                        screenWakeHandler.removeCallbacksAndMessages(null)
                        screenWakeHandler.postDelayed({
                            lockdownKeepsScreenOn = false
                            applyKeepScreenOn()
                        }, 15000L)

                        result.success(true)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                "isLockTaskPermitted" -> {
                    // Lockdown uses plain screen pinning (startLockTask without a device owner), which every
                    // Android 5+ device allows after the system confirmation. So "available" is always true here;
                    // DevicePolicyManager.isLockTaskPermitted would only matter for a DPC-whitelisted kiosk.
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

                        // Only bundled vinyl loops; anything else falls back to the index table.
                        val assetPath = if (rawAssetPath != null && VINYL_ASSET.matches(rawAssetPath)) {
                            "flutter_assets/$rawAssetPath"
                        } else {
                            when (trackIndex) {
                                0 -> "flutter_assets/assets/audio/vinyl_lofi_rain.ogg"
                                1 -> "flutter_assets/assets/audio/vinyl_brown_noise.ogg"
                                2 -> "flutter_assets/assets/audio/vinyl_library.ogg"
                                3 -> "flutter_assets/assets/audio/vinyl_kyoto_bamboo.ogg"
                                4 -> "flutter_assets/assets/audio/vinyl_campfire.ogg"
                                5 -> "flutter_assets/assets/audio/vinyl_nordic_pines.ogg"
                                6 -> "flutter_assets/assets/audio/vinyl_alpine_brook.ogg"
                                7 -> "flutter_assets/assets/audio/vinyl_ocean_waves.ogg"
                                8 -> "flutter_assets/assets/audio/vinyl_morning_meadow.ogg"
                                9 -> "flutter_assets/assets/audio/vinyl_timber_chamber.ogg"
                                10 -> "flutter_assets/assets/audio/vinyl_warm_tape.ogg"
                                11 -> "flutter_assets/assets/audio/vinyl_rhodes_velvet.ogg"
                                12 -> "flutter_assets/assets/audio/vinyl_acoustic_guitar.ogg"
                                13 -> "flutter_assets/assets/audio/vinyl_ambient_drift.ogg"
                                14 -> "flutter_assets/assets/audio/vinyl_felt_piano_solo.ogg"
                                15 -> "flutter_assets/assets/audio/vinyl_modular_clockwork.ogg"
                                16 -> "flutter_assets/assets/audio/vinyl_goldberg_aria.ogg"
                                17 -> "flutter_assets/assets/audio/vinyl_chopin_nocturne.ogg"
                                18 -> "flutter_assets/assets/audio/vinyl_spanish_romance.ogg"
                                19 -> "flutter_assets/assets/audio/vinyl_chamber_quartet.ogg"
                                else -> "flutter_assets/assets/audio/vinyl_lofi_rain.ogg"
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
                        val asset = FOLEY_VARIANTS[effect]?.random() ?: FOLEY_ASSETS[effect]
                        // Foley follows MASTER VOLUME like the soundscape and the chime preview.
                        if (asset != null) effectPlayer.playFoley(asset, masterVolume)
                        result.success(true)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                "playAlarmChime" -> {
                    try {
                        val chimeId = call.argument<String>("chimeId") ?: "braunBell"
                        val chimeAsset = ALARM_ASSETS[chimeId] ?: ALARM_ASSETS.getValue("braunBell")
                        if (call.argument<Boolean>("preview") == true) {
                            // Settings audition: instant, never de-duplicated,
                            // follows the media stream at the master volume.
                            val vol = call.argument<Number>("volume")?.toFloat() ?: masterVolume
                            effectPlayer.playPreview(chimeAsset, vol)
                            result.success(true)
                            return@setMethodCallHandler
                        }
                        if (!shouldPlayAlarm()) {
                            result.success(true)
                            return@setMethodCallHandler
                        }
                        // Held in a field: a local MediaPlayer can be garbage-collected mid-ring (zen gong is 4.2 s).
                        alarmPlayer?.release()
                        alarmPlayer = null
                        context.assets.openFd(chimeAsset).use { fd ->
                            alarmPlayer = MediaPlayer().apply {
                                setAudioAttributes(
                                    AudioAttributes.Builder()
                                        .setUsage(AudioAttributes.USAGE_ALARM)
                                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                                        .build()
                                )
                                setDataSource(fd.fileDescriptor, fd.startOffset, fd.length)
                                setOnCompletionListener { mp -> mp.release(); if (alarmPlayer === mp) alarmPlayer = null }
                                setOnErrorListener { mp, _, _ ->
                                    mp.release(); if (alarmPlayer === mp) alarmPlayer = null; true
                                }
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
                        val autoStartNext = call.argument<Boolean>("autoStartNext") == true

                        val serviceIntent = Intent(this, TimerForegroundService::class.java).apply {
                            action = TimerForegroundService.ACTION_START
                            putExtra(TimerForegroundService.EXTRA_AUTO_START_NEXT, autoStartNext)
                            (call.argument<Number>("sessionId"))?.toLong()?.let {
                                putExtra(TimerForegroundService.EXTRA_SESSION_ID, it)
                            }
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
                        requestNotificationPermissionOnce()
                        result.success(true)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                "takePendingSessions" -> {
                    result.success(TimerForegroundService.takePendingSessions(this))
                }
                "getRemainingMillis" -> {
                    // Boot-clock remaining time of the native session, or null
                    // when none ran in this process. Negative = already finished.
                    val deadline = TimerForegroundService.deadlineElapsed
                    if (deadline == 0L) {
                        result.success(null)
                    } else {
                        result.success(mapOf(
                            "remainingMillis" to (deadline - SystemClock.elapsedRealtime()),
                            "running" to TimerForegroundService.isCountingDown,
                            "sessionId" to TimerForegroundService.activeSessionId,
                        ))
                    }
                }
                "showPausedNotification" -> {
                    TimerNotifications.showPaused(
                        this,
                        (call.argument<Number>("remainingSeconds"))?.toDouble() ?: 0.0,
                        (call.argument<Number>("targetMinutes"))?.toInt() ?: 25,
                        call.argument<String>("phase") ?: "focus",
                        (call.argument<Number>("cycleCount"))?.toInt() ?: 1,
                        call.argument<String>("profileName") ?: "CLASSIC 25/5",
                        call.argument<String>("alarmChimeId") ?: "braunBell"
                    )
                    result.success(true)
                }
                "clearPausedNotification" -> {
                    TimerNotifications.cancelPaused(this)
                    result.success(true)
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

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, DISPLAY_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "setKeepScreenOn" -> {
                    deskClockKeepsScreenOn = call.argument<Boolean>("enabled") == true
                    applyKeepScreenOn()
                    result.success(true)
                }
                "setDimmed" -> {
                    setDimmed(call.argument<Boolean>("dimmed") == true)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

        // Export / restore through the system file picker (Storage Access Framework): no storage permission, the
        // user picks the place (Downloads, Drive, ...).
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, BACKUP_CHANNEL).setMethodCallHandler { call, result ->
            if (pendingFileResult != null) {
                result.error("BUSY", "A file picker is already open", null)
                return@setMethodCallHandler
            }
            try {
                when (call.method) {
                    "saveFile" -> {
                        pendingFileResult = result
                        pendingFileContent = (call.argument<String>("content") ?: "").toByteArray(Charsets.UTF_8)
                        startActivityForResult(
                            Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
                                addCategory(Intent.CATEGORY_OPENABLE)
                                type = call.argument<String>("mimeType") ?: "application/octet-stream"
                                putExtra(Intent.EXTRA_TITLE, call.argument<String>("fileName") ?: "zykl-export")
                            },
                            REQUEST_SAVE_FILE
                        )
                    }
                    "openFile" -> {
                        pendingFileResult = result
                        startActivityForResult(
                            Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                                addCategory(Intent.CATEGORY_OPENABLE)
                                type = "*/*"
                                putExtra(Intent.EXTRA_MIME_TYPES, arrayOf("application/json", "text/plain", "application/octet-stream"))
                            },
                            REQUEST_OPEN_FILE
                        )
                    }
                    else -> result.notImplemented()
                }
            } catch (e: Exception) {
                pendingFileResult = null
                pendingFileContent = null
                result.error("NO_PICKER", e.message, null)
            }
        }

        // Widget colours follow the app's light/dark mode and hardware edition (own channel: sent only on change).
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WIDGET_THEME_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method != "updateWidgetTheme") {
                result.notImplemented()
                return@setMethodCallHandler
            }
            // Light/dark mode or edition changed in the app: recolour the chassis widgets.
            fun color(key: String, fallback: Int) = (call.argument<Number>(key))?.toInt() ?: fallback
            val d = WidgetTheme.DEFAULT
            WidgetTheme.save(this, WidgetTheme(
                dark = call.argument<Boolean>("dark") ?: d.dark,
                chassis = color("chassis", d.chassis),
                text = color("text", d.text),
                muted = color("muted", d.muted),
                accent = color("accent", d.accent),
                needle = color("needle", d.needle),
                border = color("border", d.border),
            ))
            notifyAllWidgets()
            result.success(true)
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
                    val action = initialWidgetAction
                        ?: if (launchedAgain) null else externalFeature(intent) ?: AppShortcuts.action(this, intent)
                    initialWidgetAction = null
                    intent?.removeExtra("open_feature")
                    AppShortcuts.clear(intent)
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
                            .putInt(TaktAppWidgetProvider.KEY_STATS_DAY, TaktAppWidgetProvider.todayKey())
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
                        val profileName = call.argument<String>("profileName") ?: "CLASSIC 25/5"
                        val alarmChimeId = call.argument<String>("alarmChimeId") ?: "braunBell"
                        val cycleCount = (call.argument<Number>("cycleCount"))?.toInt() ?: 1

                        val prefs = getSharedPreferences(TaktAppWidgetProvider.PREFS_NAME, Context.MODE_PRIVATE)
                        prefs.edit()
                            .putString(TaktAppWidgetProvider.KEY_PROFILE_NAME, profileName)
                            .putString(TaktAppWidgetProvider.KEY_ALARM_CHIME_ID, alarmChimeId)
                            .putInt(TaktAppWidgetProvider.KEY_CYCLE_COUNT, cycleCount)
                            .putInt(TaktAppWidgetProvider.KEY_CYCLES_COMPLETED, cycles)
                            .putInt(TaktAppWidgetProvider.KEY_CYCLES_TARGET, target)
                            .putInt(TaktAppWidgetProvider.KEY_MINUTES_FOCUSED, minutes)
                            .putInt(TaktAppWidgetProvider.KEY_STATS_DAY, TaktAppWidgetProvider.todayKey())
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

    /**
     * Android 13+: the countdown/alert/vinyl notifications are silently dropped
     * without POST_NOTIFICATIONS. Asked in context (first timer start), once per
     * install; afterwards the user can enable it in system settings.
     */
    private fun requestNotificationPermissionOnce() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) return
        if (checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED) return
        val prefs = getSharedPreferences(PERMISSION_PREFS, Context.MODE_PRIVATE)
        if (prefs.getBoolean(KEY_NOTIFICATION_ASKED, false)) return
        prefs.edit().putBoolean(KEY_NOTIFICATION_ASKED, true).apply()
        requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), REQUEST_POST_NOTIFICATIONS)
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == REQUEST_POST_NOTIFICATIONS &&
            grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED &&
            TimerForegroundService.isCountingDown
        ) {
            try {
                startService(Intent(this, TimerForegroundService::class.java).apply {
                    action = TimerForegroundService.ACTION_REFRESH_NOTIFICATION
                })
            } catch (_: Exception) {}
        }
    }

    @Deprecated("FlutterActivity is not a ComponentActivity; the result API is not available here")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != REQUEST_SAVE_FILE && requestCode != REQUEST_OPEN_FILE) return
        val result = pendingFileResult
        if (result == null) {
            // The process was killed while the picker was open: the content to save is gone, so don't leave the empty
            // file the picker created (the user saves again from Settings).
            if (requestCode == REQUEST_SAVE_FILE && resultCode == RESULT_OK) data?.data?.let { deleteQuietly(it) }
            return
        }
        val content = pendingFileContent
        pendingFileResult = null
        pendingFileContent = null
        val uri = data?.data
        if (resultCode != RESULT_OK || uri == null) {
            result.success(null) // cancelled
            return
        }
        val main = Handler(Looper.getMainLooper())
        Thread {
            try {
                if (requestCode == REQUEST_SAVE_FILE) {
                    try {
                        contentResolver.openOutputStream(uri, "wt")?.use { it.write(content ?: ByteArray(0)) }
                            ?: throw IllegalStateException("Cannot write the chosen file")
                    } catch (e: Exception) {
                        deleteQuietly(uri) // no half-written or empty backup left behind
                        throw e
                    }
                    main.post { result.success(true) }
                } else {
                    val bytes = contentResolver.openInputStream(uri)?.use { input ->
                        val out = java.io.ByteArrayOutputStream()
                        val buffer = ByteArray(16 * 1024)
                        while (true) {
                            val n = input.read(buffer)
                            if (n < 0) break
                            out.write(buffer, 0, n)
                            if (out.size() > MAX_BACKUP_BYTES) throw IllegalStateException("File too large")
                        }
                        out.toByteArray()
                    } ?: throw IllegalStateException("Cannot read the chosen file")
                    val text = String(bytes, Charsets.UTF_8)
                    main.post { result.success(text) }
                }
            } catch (e: Exception) {
                main.post { result.error("IO", e.message, null) }
            }
        }.start()
    }

    private fun deleteQuietly(uri: android.net.Uri) {
        try {
            android.provider.DocumentsContract.deleteDocument(contentResolver, uri)
        } catch (_: Exception) {}
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        val action = externalFeature(intent) ?: AppShortcuts.action(this, intent)
        AppShortcuts.clear(intent)
        if (action != null) {
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
        // The lockdown ends with this activity (its Flutter state goes with it), so its DND does too.
        restoreLockdownDnd()
        screenWakeHandler.removeCallbacksAndMessages(null)
        MediaNotificationService.mediaControlListener = null
        safeRelease(soundscapePlayer)
        soundscapePlayer = null
        // The soundscape lives in this activity, so its media notification goes too (before, on Android 7-11 back-exit
        // left a "playing" notification with dead buttons, still holding audio focus).
        try {
            stopService(Intent(this, MediaNotificationService::class.java))
        } catch (_: Exception) {}
        effectPlayer.release()
        super.onDestroy()
    }
}
