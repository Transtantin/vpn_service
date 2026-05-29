import 'package:flutter/material.dart';
import '../models/vpn_server.dart';
import '../services/api_service.dart';
import '../services/vpn_service.dart';

class ServerSelectionScreen extends StatefulWidget {
  const ServerSelectionScreen({super.key});

  @override
  State<ServerSelectionScreen> createState() => _ServerSelectionScreenState();
}

class _ServerSelectionScreenState extends State<ServerSelectionScreen> {
  final ApiService _apiService = ApiService();
  final VpnService _vpnService = VpnService(); // Используем наш синглтон
  
  List<VpnServer>? _servers;
  String? _error;
  bool _isLoadingBest = false;
  
  // Храним реальные пинги для каждого ID сервера
  final Map<String, int> _realPings = {};

  @override
  void initState() {
    super.initState();
    _fetchServers(); // Убрали _initAndFetch, т.к. VpnService уже инициализируется на главном экране
  }

  Future<void> _fetchServers() async {
    try {
      final servers = await _apiService.fetchServers();
      if (mounted) {
        setState(() {
          _servers = servers;
          _error = null;
        });
        // Как только получили серверы — начинаем их прозванивать
        _measureRealPings(servers);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
    }
  }

  // Асинхронно прозваниваем каждый сервер с телефона
  Future<void> _measureRealPings(List<VpnServer> servers) async {
    for (var server in servers) {
      if (!mounted) return;
      if (server.configs.isNotEmpty) {
        try {
          // Берем первый конфиг сервера для проверки через наш сервис
          final ping = await _vpnService.getRealPing(server.configs.first.configString);
          if (mounted) {
            setState(() {
              _realPings[server.id] = ping;
              server.ping = ping; // Обновляем объект, чтобы на главном экране тоже был этот пинг
            });
          }
        } catch (e) {
          if (mounted) {
            setState(() {
              _realPings[server.id] = -1; // Ошибка прозвона
            });
          }
        }
      }
    }
  }

  // Выбрать лучший сервер (теперь по РЕАЛЬНОМУ пингу, а не с бэкенда)
  Future<void> _selectBestServer() async {
    if (_servers == null || _servers!.isEmpty) return;

    setState(() {
      _isLoadingBest = true;
    });

    // Дождемся окончания прозвона хотя бы нескольких секунд, если нужно,
    // но в идеале мы просто ищем сервер с минимальным пингом из уже прозвоненных.
    VpnServer? bestServer;
    int minPing = 999999;

    for (var server in _servers!) {
      final ping = _realPings[server.id];
      if (ping != null && ping > 0 && ping < minPing) {
        minPing = ping;
        bestServer = server;
      }
    }

    // Если ни один еще не прозвонился удачно, берем первый попавшийся
    bestServer ??= _servers!.first;

    if (mounted) {
      Navigator.pop(context, bestServer);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Server'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 60),
            const SizedBox(height: 16),
            Text('Error: $_error', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _error = null;
                  _servers = null;
                });
                _fetchServers();
              },
              child: const Text('Retry'),
            )
          ],
        ),
      );
    }

    if (_servers == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_servers!.isEmpty) {
      return const Center(child: Text('No servers available right now.'));
    }

    return ListView.builder(
      itemCount: _servers!.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildAutoCard();
        }
        final server = _servers![index - 1];
        return _buildServerCard(server);
      },
    );
  }

  Widget _buildAutoCard() {
    return Card(
      color: const Color(0xFF1A3A5C),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: _isLoadingBest
            ? const SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const CircleAvatar(
                backgroundColor: Colors.blueAccent,
                child: Icon(Icons.auto_awesome, color: Colors.white, size: 20),
              ),
        title: const Text(
          'Auto — Best Server',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent),
        ),
        subtitle: const Text(
          'Автоматически выбрать сервер с наименьшим пингом',
          style: TextStyle(fontSize: 12),
        ),
        onTap: _isLoadingBest ? null : _selectBestServer,
      ),
    );
  }

  Widget _buildServerCard(VpnServer server) {
    // Берем реальный пинг, если он уже измерился, иначе показываем загрузку
    final realPing = _realPings[server.id];

    return Card(
      color: const Color(0xFF2C2C2C),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: NetworkImage(server.flagUrl),
          backgroundColor: Colors.transparent,
        ),
        title: Text(server.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(server.location),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (realPing == null)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else if (realPing == -1)
              const Icon(Icons.error, color: Colors.red, size: 16)
            else ...[
              Icon(
                Icons.network_check,
                color: realPing < 150 ? Colors.green : Colors.orange,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text('$realPing ms'),
            ],
          ],
        ),
        onTap: () {
          Navigator.pop(context, server);
        },
      ),
    );
  }
}
