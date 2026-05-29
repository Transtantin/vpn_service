package com.example.my_vpn_client

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createSilentNotificationChannel()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // No custom method channels needed anymore, flutter_v2ray handles the VPN
    }

    /**
     * Создаём канал уведомлений ДО того как flutter_v2ray создаст его сам.
     * Android не перезаписывает уже существующий канал — наш LOW importance сохранится.
     */
    private fun createSilentNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                "flutter_v2ray",
                "VPN Service",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Показывает статус VPN подключения"
                setSound(null, null)
                enableVibration(false)
                enableLights(false)
            }
            getSystemService(NotificationManager::class.java)
                .createNotificationChannel(channel)
        }
    }
}
