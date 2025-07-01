import 'package:flutter/material.dart';
import '../services/base_api_service.dart';
import '../utils/exceptions.dart';

class BackendTestWidget extends StatefulWidget {
  const BackendTestWidget({super.key});

  @override
  State<BackendTestWidget> createState() => _BackendTestWidgetState();
}

class _BackendTestWidgetState extends State<BackendTestWidget> {
  bool _isConnected = false;
  bool _isLoading = false;
  String _errorMessage = '';
  String _serverInfo = '';
  final BaseApiService _apiService = BaseApiService();

  @override
  void initState() {
    super.initState();
    _testConnection();
  }

  Future<void> _testConnection() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _serverInfo = '';
    });

    try {
      // Intentar conectar con el endpoint de salud del backend
      final response = await _apiService.get('/');

      setState(() {
        _isLoading = false;
        _isConnected = true;
        _serverInfo = response.toString();
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isConnected = false;
        if (e is NetworkException) {
          _errorMessage = e.message;
        } else if (e is ApiException) {
          _errorMessage = e.message;
        } else {
          _errorMessage = 'Error de conexión: $e';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: _isConnected
              ? [Colors.green.withOpacity(0.1), Colors.green.withOpacity(0.05)]
              : _errorMessage.isNotEmpty
              ? [Colors.red.withOpacity(0.1), Colors.red.withOpacity(0.05)]
              : [Colors.blue.withOpacity(0.1), Colors.indigo.withOpacity(0.05)],
        ),
        border: Border.all(
          color: _isConnected
              ? Colors.green.withOpacity(0.3)
              : _errorMessage.isNotEmpty
              ? Colors.red.withOpacity(0.3)
              : Colors.blue.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _isLoading
                      ? Colors.orange
                      : _isConnected
                      ? Colors.green
                      : Colors.red,
                  shape: BoxShape.circle,
                ),
                child: _isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Icon(
                        _isConnected ? Icons.check : Icons.error,
                        color: Colors.white,
                        size: 20,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Estado del Backend',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isLoading
                          ? 'Verificando conexión...'
                          : _isConnected
                          ? 'Conectado correctamente'
                          : 'Sin conexión',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _testConnection,
                icon: Icon(Icons.refresh, size: 16),
                label: Text('Probar', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  minimumSize: Size.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          if (_errorMessage.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.red.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.red.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (_isConnected && _serverInfo.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.green.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: Colors.green, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Servidor: $_serverInfo',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.green.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
