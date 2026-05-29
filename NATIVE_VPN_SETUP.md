# Нативный VPN-сервис — инструкция по запуску

## Зачем это вообще нужно?

На Samsung Galaxy S22 (Android 14) `flutter_v2ray` показывает "CONNECTED",
но трафик не идёт. В логах видно:

```
userfaultfd: MOVE ioctl seems unsupported
```

Это означает, что gVisor-стек (которым пользуется xray-core для TUN)
не работает на ядре этого телефона. Решение — поднять TUN сами через Android API
и пустить трафик через tun2socks → xray SOCKS5.

---

## Шаг 1 — создай ветку

```powershell
cd X:\projects\ucheba\vpn\my_vpn_client
git checkout -b feature/native-vpn-service
```

---

## Шаг 2 — скачай бинарник tun2socks

1. Открой в браузере: https://github.com/xjasonlyu/tun2socks/releases/latest
2. Скачай файл **`tun2socks-linux-arm64.zip`**
   (для Android ARM64; большинство современных телефонов — ARM64)
3. Распакуй архив, внутри будет файл `tun2socks-linux-arm64`
4. Переименуй его в просто **`tun2socks`** (без расширения)
5. Положи в папку:
   ```
   X:\projects\ucheba\vpn\my_vpn_client\UI\android\app\src\main\assets\tun2socks
   ```
   Папку `assets` нужно создать если её нет.

Итоговое расположение:
```
UI/
  android/
    app/
      src/
        main/
          assets/
            tun2socks        ← вот сюда
          kotlin/...
          AndroidManifest.xml
```

---

## Шаг 3 — пересобери и установи APK

```powershell
cd X:\projects\ucheba\vpn\my_vpn_client\UI
$env:JAVA_HOME = "C:\Program Files\Android\Android Studio\jbr"
flutter build apk --debug
```

APK будет в `build/app/outputs/flutter-apk/app-debug.apk`.
Скинь на телефон и установи.

---

## Шаг 4 — проверь в логах

```powershell
$env:PATH += ";$env:LOCALAPPDATA\Android\Sdk\platform-tools"
adb logcat | Select-String "TunVpnService|tun2socks|V2Ray"
```

Должно появиться:
```
TunVpnService: TUN-интерфейс создан, fd=XX
TunVpnService: tun2socks запущен
[tun2socks] level=warning msg="[TCP] ...
```

Если в логах `tun2socks не найден в assets!` — значит бинарник лежит не там.

---

## Шаг 5 — запушь ветку

```powershell
cd X:\projects\ucheba\vpn\my_vpn_client
git add .
git commit -m "feat: нативный Android VPN-сервис (обход userfaultfd на Samsung Android 14)"
git push origin feature/native-vpn-service
```

---

## Как это работает (схема)

```
┌──────────────────────────────────────────────────────────┐
│  Другие приложения (браузер, телеграм и т.д.)            │
│       ↓                                                  │
│  TUN-интерфейс (198.18.0.1/15) — создан через Android API│
│       ↓                                                  │
│  tun2socks — конвертирует IP-пакеты в SOCKS5-запросы     │
│       ↓                                                  │
│  xray-core SOCKS5 @ 127.0.0.1:10808                      │
│       ↓                                                  │
│  VPN-сервер (VLESS+REALITY) @ server.goida2.online        │
│       ↓                                                  │
│  Интернет 🌐                                              │
└──────────────────────────────────────────────────────────┘

Наше приложение (xray + tun2socks) → исключены из TUN
→ подключаются к VPN-серверу напрямую (без петли)
```

---

## Если что-то не работает

**tun2socks выдаёт ошибку разрешений:**
```
Permission denied
```
→ Файл не сделали исполняемым. Это делается автоматически в `TunVpnService.kt`,
но если не помогает — попробуй пересобрать APK.

**Скорость по-прежнему 0:**
→ Проверь что в логах есть `[tun2socks]` строки. Если нет — бинарник не нашёлся.

**"establish() вернул null":**
→ Не выдано разрешение VPN. Зайди в Настройки → VPN → удали старые подключения
и попробуй снова.

**fd://$N не работает:**
→ Старая версия tun2socks. Скачай последнюю с releases.
