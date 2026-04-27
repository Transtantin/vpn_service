package com.example.my_vpn_client

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Создаём канал уведомлений ДО того как плагин flutter_v2ray
        // создаст его сам. Android не перезаписывает уже существующий канал,
        // поэтому наш LOW importance сохранится — без звука и вибрации.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                "flutter_v2ray",          // ID канала, который использует плагин
                "VPN Service",            // название в настройках телефона
                NotificationManager.IMPORTANCE_LOW  // тихое уведомление
            )
            channel.description = "Показывает статус VPN подключения"
            channel.setSound(null, null)      // без звука
            channel.enableVibration(false)    // без вибрации
            channel.enableLights(false)       // без мигания LED

            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }
}
