/// Connect Screen
///
/// Initial screen for entering WebSocket URL and authentication token.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/system_provider.dart';
import '../services/system_mcp_client.dart';

class ConnectScreen extends StatefulWidget {
  const ConnectScreen({super.key});

  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen> {
  // Pre-configured for your local network
  final _urlController = TextEditingController(text: 'ws://192.168.18.49:3001');
  final _tokenController = TextEditingController(
    text: '655dca3cc3c7fb6c6003d2001f0fcbcd0b59c82b7c7da13b92b71d408d0a639b',
  );
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _urlController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    final url = _urlController.text.trim();
    final token = _tokenController.text.trim();

    if (url.isEmpty) {
      setState(() => _error = 'Please enter a WebSocket URL');
      return;
    }

    if (token.isEmpty) {
      setState(() => _error = 'Please enter an authentication token');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await context.read<SystemProvider>().connect(url, token);
    } catch (e) {
      setState(() {
        _error = e is SystemMCPException ? e.message : e.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),

              // Logo/Title
              const Column(
                children: [
                  Text(
                    'SYSTEM',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 8,
                      color: Color(0xFF64C896),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Control Your Mac From Anywhere',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),

              const Spacer(),

              // Connection form
              TextField(
                controller: _urlController,
                decoration: InputDecoration(
                  labelText: 'WebSocket URL',
                  hintText: 'ws://localhost:3001',
                  prefixIcon: const Icon(Icons.link),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: const Color(0xFF21262D),
                ),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: _tokenController,
                decoration: InputDecoration(
                  labelText: 'Auth Token',
                  hintText: 'From bridge.config.json',
                  prefixIcon: const Icon(Icons.key),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: const Color(0xFF21262D),
                ),
                obscureText: true,
              ),

              if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              FilledButton(
                onPressed: _isLoading ? null : _connect,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Connect',
                        style: TextStyle(fontSize: 16),
                      ),
              ),

              const Spacer(),

              // Help text
              const Text(
                'Run "npm start" on your Mac to start the SYSTEM server.\n'
                'Find your auth token in bridge.config.json',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
