// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
// Обязательно проверь, что путь импорта совпадает с твоим названием проекта!
// import 'package:my_vpn_client/models/vpn_server.dart';
import '../models/vpn_server.dart'; // Если используешь относительный путь

class ApiService {
  // Локальная разработка (комп):      'http://127.0.0.1:8000'
  // Android эмулятор:                 'http://10.0.2.2:8000'
  // Локалка (реальный телефон):       'http://192.168.1.XXX:8000'
  // Продакшн (твой сервер с доменом): 'https://ДОМЕН'
  static const String baseUrl = 'https://server.goida2.online';

  // Функция "Сходи за серверами"
  Future<List<VpnServer>> fetchServers() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/servers'));

      // 200 = Успех, запрос прошел
      if (response.statusCode == 200) {
        // Декодируем строку JSON в список динамических мап
        List<dynamic> jsonList = jsonDecode(response.body);

        // Превращаем каждый элемент из JSON в наш красивый объект VpnServer
        return jsonList.map((json) => VpnServer.fromJson(json)).toList();
      } else {
        // Сервер ответил ошибкой (например, 500)
        throw Exception('Failed to load servers. Status: ${response.statusCode}');
      }
    } catch (e) {
      // Это сработает, если сервер вообще выключен (Connection Refused)
      throw Exception('Error fetching servers: $e');
    }
  }

  // Запрашивает сервер с наименьшим пингом у бэкенда
  Future<VpnServer> fetchBestServer() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/servers/best'));

      if (response.statusCode == 200) {
        return VpnServer.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to get best server. Status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching best server: $e');
    }
  }
}
