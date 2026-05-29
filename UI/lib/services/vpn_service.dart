import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_v2ray/flutter_v2ray.dart';

// Возможные состояния нашего VPN
enum VpnStatus { disconnected, connecting, connected }

class VpnService {
  // Сам плагин ядра V2Ray (работает как SOCKS5-прокси)
  late final FlutterV2ray flutterV2ray;

  // MethodChannel для управления нативным TunVpnService (Kotlin)
  static const _tunChannel = MethodChannel('com.example.my_vpn_client/vpn_tun');

  // Контроллер статуса соединения для UI
  final StreamController<VpnStatus> _statusController =
      StreamController<VpnStatus>.broadcast();
  Stream<VpnStatus> get statusStream => _statusController.stream;

  // Контроллер метрик (скорость и тд)
  final StreamController<V2RayStatus> _metricsController =
      StreamController<V2RayStatus>.broadcast();
  Stream<V2RayStatus> get metricsStream => _metricsController.stream;

  // Текущее состояние
  VpnStatus currentStatus = VpnStatus.disconnected;

  static final VpnService _instance = VpnService._internal();

  factory VpnService() {
    return _instance;
  }

  VpnService._internal() {
    flutterV2ray = FlutterV2ray(
      onStatusChanged: (status) {
        print("V2Ray Status: ${status.state} | Speed: ${status.downloadSpeed}");

        if (status.state == "CONNECTED") {
          _updateStatus(VpnStatus.connected);
        } else if (status.state == "DISCONNECTED") {
          _updateStatus(VpnStatus.disconnected);
        }

        // Отправляем метрики в UI (в proxyOnly-режиме скорость всегда 0 — это нормально)
        _metricsController.add(status);
      },
    );
  }

  // Обязательно вызвать при старте приложения
  Future<void> init() async {
    await flutterV2ray.initializeV2Ray();
  }

  // Меняем статус и оповещаем UI.
  // Проверяем "а вдруг статус не изменился?" — без этого таймер в UI
  // сбрасывался бы каждую секунду из-за onStatusChanged с обновлением скорости.
  void _updateStatus(VpnStatus status) {
    if (currentStatus == status) return;
    currentStatus = status;
    _statusController.add(status);
  }

  // Подключаемся.
  // serverIp — IP VPN-сервера, чтобы исключить его из туннеля (иначе петля).
  Future<void> connect(String configString, {String? serverIp}) async {
    _updateStatus(VpnStatus.connecting);

    try {
      if (await flutterV2ray.requestPermission()) {
        final v2rayURL = FlutterV2ray.parseFromURL(configString);
        print("V2Ray config parsed. Remark: ${v2rayURL.remark}");

        final String rawGenerated = v2rayURL.getFullConfiguration();
        final Map<String, dynamic> config = jsonDecode(rawGenerated);

        // Оставляем оригинальный конфиг V2Ray
        final String finalConfig = jsonEncode(config);

        // Запускаем xray-core в режиме VPN.
        // proxyOnly: false означает, что плагин сам создаст TUN-интерфейс.
        // Мы добавили systemExempted в AndroidManifest, так что краша на Android 14 не будет.
        await flutterV2ray.startV2Ray(
          remark: v2rayURL.remark,
          config: finalConfig,
          proxyOnly: false,
        );
      } else {
        _updateStatus(VpnStatus.disconnected);
      }
    } catch (e) {
      print("VPN Connect Error: $e");
      _updateStatus(VpnStatus.disconnected);
    }
  }

  Future<void> disconnect() async {
    await flutterV2ray.stopV2Ray();
    _updateStatus(VpnStatus.disconnected);
  }

  // Измеряет настоящий пинг от устройства до сервера
  Future<int> getRealPing(String configString) async {
    try {
      // Превращаем vless ссылку в полный JSON конфиг
      final v2rayURL = FlutterV2ray.parseFromURL(configString);
      final rawGenerated = v2rayURL.getFullConfiguration();

      // Используем встроенную функцию плагина (она делает полноценный TLS/HTTP запрос,
      // что предотвращает бан IP-адреса на серверах с защитой от сканирования портов, таких как XTLS Reality).
      return await flutterV2ray.getServerDelay(config: rawGenerated);
    } catch (e) {
      print("Error measuring delay: $e");
      return -1;
    }
  }

  // Чистим стримы при закрытии приложения
  void dispose() {
    _statusController.close();
    _metricsController.close();
  }
}
