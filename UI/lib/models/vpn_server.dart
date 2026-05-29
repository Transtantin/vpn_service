// lib/models/vpn_server.dart

// 1. Создаем enum для протоколов, как в Python
enum Protocol {
  vless,
  shadowsocks,
  wireguard,
  fptn,
  unknown // На случай, если бэкенд пришлет что-то новое
}

// Хелпер для парсинга строкового протокола из JSON
Protocol _protocolFromString(String source) {
  return Protocol.values.firstWhere(
    (e) => e.name == source, 
    orElse: () => Protocol.unknown
  );
}

// 2. Создаем класс для конфигурации
class ServerConfig {
  final Protocol protocol;
  final String configString;
  final int priority;

  ServerConfig({
    required this.protocol,
    required this.configString,
    required this.priority,
  });

  // Фабрика для сборки из JSON
  factory ServerConfig.fromJson(Map<String, dynamic> json) {
    return ServerConfig(
      protocol: _protocolFromString(json['protocol'] as String),
      configString: json['config_string'] as String,
      priority: json['priority'] as int,
    );
  }
}

// 3. Обновляем основную модель
class VpnServer {
  final String id;
  final String name;
  final String location;
  final String flagUrl;
  final String ip;
  int ping;
  final List<ServerConfig> configs; // <--- Наш новый список

  VpnServer({
    required this.id,
    required this.name,
    required this.location,
    required this.flagUrl,
    required this.ip,
    required this.ping,
    this.configs = const [],
  });

  // Обновляем fromJson, чтобы он парсил вложенный список
  factory VpnServer.fromJson(Map<String, dynamic> json) {
    return VpnServer(
      id: json['id'] as String,
      name: json['name'] as String,
      location: json['location'] as String,
      flagUrl: json['flagUrl'] as String,
      ip: json['ip'] as String,
      ping: json['ping'] as int,
      configs: (json['configs'] as List<dynamic>?)
              ?.map((e) => ServerConfig.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}


// MOCK_SERVERS пока можно закомментировать или удалить, 
// скоро мы будем тянуть их из сети в VpnTracker/VpnService!