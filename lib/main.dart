import 'package:flutter/material.dart';

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
  // Состояние
  bool isConnected = false;
  // Выбранная локация 
  String selectedLocation = "Выбранный сервер";

  void toggleVpn() {
    setState(() {
      isConnected = !isConnected;
    });
    // тут будет вызов Sing-box
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
                  isConnected ? "CONNECTED" : "DISCONNECTED",
                  style: TextStyle(
                    color: isConnected ? Colors.greenAccent : Colors.redAccent,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  isConnected ? "99:99:23" : "00:00:00", // Таймер 
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
                      ? Colors.green.withOpacity(0.2) 
                      : Colors.grey.withOpacity(0.1),
                  border: Border.all(
                    color: isConnected ? Colors.greenAccent : Colors.grey,
                    width: 2,
                  ),
                  boxShadow: [
                    if (isConnected)
                      BoxShadow(
                        color: Colors.greenAccent.withOpacity(0.4),
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
                _buildStatItem(Icons.arrow_downward, "Download", "0.0 Mb/s"),
                _buildStatItem(Icons.arrow_upward, "Upload", "0.0 Mb/s"),
                _buildStatItem(Icons.network_check, "Ping", isConnected ? "45 ms" : "-"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Виджет карточки выбора локации
  Widget _buildLocationCard() {
    return Container(
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
              Text(selectedLocation, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const Spacer(),
          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        ],
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