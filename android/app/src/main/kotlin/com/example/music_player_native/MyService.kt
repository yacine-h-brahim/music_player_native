package com.example.music_player_native

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.graphics.Color
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.Build
import android.os.IBinder
import androidx.annotation.RequiresApi
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import java.util.*
import kotlin.math.sqrt

class MyService : Service() {
    // Declare sensor manager and accelerometer
    private var sensorManager: SensorManager? = null
    private var acceleration = 0f
    private var currentAcceleration = 0f
    private var lastAcceleration = 0f

    private fun initializeSensor() {
        // Initialize sensor manager and accelerometer
        sensorManager = getSystemService(Context.SENSOR_SERVICE) as SensorManager
        sensorManager?.registerListener(
                sensorListener,
                sensorManager!!.getDefaultSensor(Sensor.TYPE_ACCELEROMETER),
                SensorManager.SENSOR_DELAY_NORMAL
        )

        acceleration = 10f
        currentAcceleration = SensorManager.GRAVITY_EARTH
        lastAcceleration = SensorManager.GRAVITY_EARTH
    }

    private val sensorListener: SensorEventListener =
            object : SensorEventListener {
                override fun onSensorChanged(event: SensorEvent) {

                    // Fetching x,y,z values
                    val x = event.values[0]
                    val y = event.values[1]
                    val z = event.values[2]
                    lastAcceleration = currentAcceleration

                    // Getting current accelerations
                    // with the help of fetched x,y,z values
                    currentAcceleration = sqrt((x * x + y * y + z * z).toDouble()).toFloat()
                    val delta: Float = currentAcceleration - lastAcceleration
                    acceleration = acceleration * 0.9f + delta

                    // acceleration value is over 12
                    if (acceleration > 9) {

                        sendBroadcastToMainActivity(ACTION_SHAKE)
                    }
                }
                override fun onAccuracyChanged(sensor: Sensor, accuracy: Int) {}
            }
    private lateinit var builder: NotificationCompat.Builder
    private lateinit var channel: NotificationChannel
    private lateinit var manager: NotificationManagerCompat

    ////////////////

    private val notificationId = 1
    private var serviceRunning = false
    companion object {
        const val ACTION_PREVIOUS = "action.PREVIOUS"
        const val ACTION_NEXT = "action.NEXT"
        const val ACTION_PLAY_PAUSE = "action.PLAY_PAUSE"
        const val ACTION_SHAKE = "action.SHAKE"
    }
    @RequiresApi(Build.VERSION_CODES.O)
    private fun createNotificationChannel(channelId: String, channelName: String): String {
        channel = NotificationChannel(channelId, channelName, NotificationManager.IMPORTANCE_NONE)
        channel.lightColor = Color.BLUE
        channel.lockscreenVisibility = Notification.VISIBILITY_PRIVATE
        manager = NotificationManagerCompat.from(this)
        manager.createNotificationChannel(channel)
        return channelId
    }

    private fun startForeground() {
        val channelId =
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    createNotificationChannel("music_player_service", "Music Player Service")
                } else {
                    ""
                }

        val notificationIntent = Intent(this, MainActivity::class.java)
        val pendingIntent =
                PendingIntent.getActivity(
                        this,
                        0,
                        notificationIntent,
                        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )

        // Create intents for button actions
        val previousIntent = Intent(this, MyService::class.java).apply { action = ACTION_PREVIOUS }
        val previousPendingIntent =
                PendingIntent.getService(
                        this,
                        0,
                        previousIntent,
                        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )

        val nextIntent = Intent(this, MyService::class.java).apply { action = ACTION_NEXT }
        val nextPendingIntent =
                PendingIntent.getService(
                        this,
                        0,
                        nextIntent,
                        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )

        val stopPauseIntent =
                Intent(this, MyService::class.java).apply { action = ACTION_PLAY_PAUSE }
        val stopPausePendingIntent =
                PendingIntent.getService(
                        this,
                        0,
                        stopPauseIntent,
                        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )

        builder =
                NotificationCompat.Builder(this, channelId)
                        .setOngoing(true)
                        .setOnlyAlertOnce(true)
                        .setSmallIcon(R.mipmap.ic_launcher)
                        .setContentTitle("Music Player is running")
                        .setContentText(trackName)
                        .setCategory(Notification.CATEGORY_SERVICE)
                        .setContentIntent(pendingIntent)
                        .addAction(
                                android.R.drawable.ic_media_previous,
                                "Previous",
                                previousPendingIntent
                        )
                        .addAction(
                                android.R.drawable.ic_media_pause,
                                "Play/Pause",
                                stopPausePendingIntent
                        )
                        .addAction(android.R.drawable.ic_media_next, "Next", nextPendingIntent)
        serviceRunning = true
        startForeground(notificationId, builder.build())
    }

    private fun stopPendingIntent(): PendingIntent {
        val stopIntent = Intent(this, MyService::class.java)
        stopIntent.action = "STOP_SERVICE"
        stopIntent.addFlags(Intent.FLAG_INCLUDE_STOPPED_PACKAGES)

        return PendingIntent.getService(
                this,
                0,
                stopIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
        )
    }

    private fun sendBroadcastToMainActivity(value: String?) {
        val intent = Intent(broadcastAction)
        intent.putExtra("ACTION_PERFORMED", value)

        sendBroadcast(intent)
    }

    private val broadcastAction = "NotificationActionBroadcast"

    private fun performAction(action: String?) {
        when (action) {
            ACTION_PREVIOUS -> {
                println("Previous action performed")
                sendBroadcastToMainActivity(action)
            }
            ACTION_NEXT -> {
                println("Next action performed")
                sendBroadcastToMainActivity(action)
            }
            ACTION_PLAY_PAUSE -> {
                println("ACTION_PLAY_PAUSE performed")
                sendBroadcastToMainActivity(action)
            }
            else -> {
                println("Unknown action: $action")
            }
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        println("onStartCommand")

        intent?.let {
            val action = it.action
            performAction(action)
        }
        return START_NOT_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }
    private fun stopService() {
        stopForeground(true)
        stopSelf()
    }
    override fun onCreate() {
        super.onCreate()
        registerReceiver(serviceReceiver, IntentFilter("MainActivityToService"))
        println("onCreate0")
        println(trackName)

        initializeSensor()
    }

    override fun onDestroy() {
        super.onDestroy()
        sensorManager!!.unregisterListener(sensorListener)
        unregisterReceiver(serviceReceiver)

        stopService()
    }
    var trackName: String? = "not"

    private val serviceReceiver =
            object : BroadcastReceiver() {
                override fun onReceive(context: Context?, intent: Intent?) {

                    if (intent?.action == "MainActivityToService") {
                        // isFlashlightOn = intent.getBooleanExtra("resultValue", false)
                        trackName = intent.getStringExtra("TRACK_NAME")
                        println(trackName)
                        println("9-----------")

                        // if (serviceRunning == false) {
                            startForeground()
                        // }
                    }
                }
            }
}
