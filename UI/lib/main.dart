import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'models/vpn_server.dart';
import 'screens/server_selection_screen.dart';
import 'services/vpn_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My VPN',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFF121212),
        useMaterial3: true,
      ),
      home: const VpnHomeScreen(),
    );
  }
}

class VpnHomeScreen extends StatefulWidget {
  const VpnHomeScreen({super.key});

  @override
  State<VpnHomeScreen> createState() => _VpnHomeScreenState();
}

class _VpnHomeScreenState extends State<VpnHomeScreen> {

  final VpnService _vpnService = VpnService();
  String speedDown = "0.0 Kb/s";
  String speedUp = "0.0 Kb/s";

  // Таймер сессии
  Timer? _sessionTimer;
  int _secondsConnected = 0;

  // Форматируем секунды в HH:MM:SS
  String get _formattedTime {
    final hours = _secondsConnected ~/ 3600;
    final minutes = (_secondsConnected % 3600) ~/ 60;
    final seconds = _secondsConnected % 60;
    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  void _startTimer() {
    _secondsConnected = 0;
    _sessionTimer?.cancel(); // на всякий случай отменяем предыдущий
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _secondsConnected++;
        });
      }
    });
  }

  void _stopTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = null;
    setState(() {
      _secondsConnected = 0;
    });
  }
  @override
  void initState() {
    super.initState();
    _vpnService.init(); // Поднимаем движок Xray
    
    // 1. Слушаем изменение статуса соединения
    _vpnService.statusStream.listen((status) {
      if (mounted) {
        setState(() {
          isConnected = (status == VpnStatus.connected);
        });

        // Запускаем или останавливаем таймер вместе со статусом
        if (status == VpnStatus.connected) {
          _startTimer();
        } else if (status == VpnStatus.disconnected) {
          _stopTimer();
        }
      }
    });

    // 2. Подписываемся на метрики (скорость скачивания и тд)
    _vpnService.metricsStream.listen((status) {
      if (mounted) {
        setState(() {
          speedDown = "${(status.downloadSpeed / 1024).toStringAsFixed(1)} KB/s";
          speedUp = "${(status.uploadSpeed / 1024).toStringAsFixed(1)} KB/s";
        });
      }
    });
  }
  @override
  void dispose() {
    _sessionTimer?.cancel();
    _vpnService.dispose();
    super.dispose();
  }

  // Состояние
  bool isConnected = false;
  VpnServer? selectedServer; // Теперь это объект, а не строка


  void toggleVpn() async {
    if (_vpnService.currentStatus == VpnStatus.disconnected) {
      if (selectedServer == null || selectedServer!.configs.isEmpty) {
        // Показываем ошибку, если сервер не выбран
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a server first!')),
        );
        return;
      }
      
      // Берем ПЕРВЫЙ конфиг (vless) из выбранного сервера (Умный режим)
      final configToConnect = selectedServer!.configs.first.configString;
      // Передаём IP сервера чтобы он не шёл через сам туннель
      await _vpnService.connect(configToConnect, serverIp: selectedServer!.ip);
    } else {
      await _vpnService.disconnect();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My VPN"),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 1: Статус и Локация
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                _buildLocationCard(),
                const SizedBox(height: 20),
                Text(
                  _vpnService.currentStatus == VpnStatus.connecting 
                      ? "CONNECTING..." 
                      : (isConnected ? "CONNECTED" : "DISCONNECTED"),
                  style: TextStyle(
                    color: isConnected ? Colors.greenAccent : (_vpnService.currentStatus == VpnStatus.connecting ? Colors.orangeAccent : Colors.redAccent),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _formattedTime, // считает секунды с момента подключения
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w300,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),

          // 2: Кнопка включения
          Center(
            child: GestureDetector(
              onTap: toggleVpn,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isConnected 
                      ? Colors.green.withValues(alpha: 0.2) 
                      : Colors.grey.withValues(alpha: 0.1),
                  border: Border.all(
                    color: isConnected ? Colors.greenAccent : Colors.grey,
                    width: 2,
                  ),
                  boxShadow: [
                    if (isConnected)
                      BoxShadow(
                        color: Colors.greenAccent.withValues(alpha: 0.4),
                        blurRadius: 30,
                        spreadRadius: 5,
                      )
                  ],
                ),
                child: Icon(
                  Icons.power_settings_new,
                  size: 80,
                  color: isConnected ? Colors.greenAccent : Colors.grey,
                ),
              ),
            ),
          ),

          // 3: Нижняя панель (пинг, скорость)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFF1E1E1E),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(Icons.arrow_downward, "Download", speedDown),
                _buildStatItem(Icons.arrow_upward, "Upload", speedUp),
                _buildStatItem(
                  Icons.network_check, 
                  "Ping", 
                  isConnected && selectedServer != null ? "${selectedServer!.ping} ms" : "-"
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Виджет карточки выбора локации
  Widget _buildLocationCard() {
    return InkWell(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ServerSelectionScreen()),
        );

        if (result != null && result is VpnServer) {
          setState(() {
            selectedServer = result;
          });
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF2C2C2C),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(Icons.public, color: Colors.blueAccent),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Location", style: TextStyle(color: Colors.grey, fontSize: 12)),
                Text(
                  selectedServer?.name ?? "Select Server", 
                  style: const TextStyle(fontWeight: FontWeight.bold)
                ),
              ],
            ),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  // Виджет статистики
  Widget _buildStatItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey, size: 20),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }
}