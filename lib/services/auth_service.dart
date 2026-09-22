/// Authentication Service
///
/// Handles login/logout, token storage, and session management.

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// User session data
class UserSession {
  final String serverUrl;
  final String token;
  final String? personalOsUrl;
  final String? personalOsToken;
  final DateTime connectedAt;

  UserSession({
    required this.serverUrl,
    required this.token,
    this.personalOsUrl,
    this.personalOsToken,
    DateTime? connectedAt,
  }) : connectedAt = connectedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'serverUrl': serverUrl,
        'token': token,
        'personalOsUrl': personalOsUrl,
        'personalOsToken': personalOsToken,
        'connectedAt': connectedAt.toIso8601String(),
      };

  factory UserSession.fromJson(Map<String, dynamic> json) => UserSession(
        serverUrl: json['serverUrl'] ?? '',
        token: json['token'] ?? '',
        personalOsUrl: json['personalOsUrl'],
        personalOsToken: json['personalOsToken'],
        connectedAt: json['connectedAt'] != null
            ? DateTime.parse(json['connectedAt'])
            : null,
      );
}

/// Connection configuration
class ConnectionConfig {
  final String serverUrl;
  final String token;
  final String? personalOsUrl;
  final String? personalOsToken;
  final bool rememberMe;

  ConnectionConfig({
    required this.serverUrl,
    required this.token,
    this.personalOsUrl,
    this.personalOsToken,
    this.rememberMe = true,
  });

  /// Default configuration for development
  static ConnectionConfig get defaults => ConnectionConfig(
        serverUrl: 'ws://192.168.18.49:3001',
        token: '',
        personalOsUrl: 'http://192.168.18.49:8765',
        personalOsToken: 'test-token-12345',
        rememberMe: true,
      );
}

/// Authentication Provider
class AuthProvider extends ChangeNotifier {
  static const String _keyServerUrl = 'auth_server_url';
  static const String _keyToken = 'auth_token';
  static const String _keyPersonalOsUrl = 'auth_personal_os_url';
  static const String _keyPersonalOsToken = 'auth_personal_os_token';
  static const String _keyRememberMe = 'auth_remember_me';
  static const String _keyIsLoggedIn = 'auth_is_logged_in';

  SharedPreferences? _prefs;
  UserSession? _session;
  bool _isLoading = true;
  bool _isLoggedIn = false;
  String? _error;

  // Getters
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;
  UserSession? get session => _session;
  String? get error => _error;

  /// Initialize the auth service
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      _prefs = await SharedPreferences.getInstance();

      // Check if user was previously logged in with remember me
      final rememberMe = _prefs?.getBool(_keyRememberMe) ?? false;
      final wasLoggedIn = _prefs?.getBool(_keyIsLoggedIn) ?? false;

      if (rememberMe && wasLoggedIn) {
        final serverUrl = _prefs?.getString(_keyServerUrl);
        final token = _prefs?.getString(_keyToken);

        if (serverUrl != null && token != null) {
          _session = UserSession(
            serverUrl: serverUrl,
            token: token,
            personalOsUrl: _prefs?.getString(_keyPersonalOsUrl),
            personalOsToken: _prefs?.getString(_keyPersonalOsToken),
          );
          _isLoggedIn = true;
        }
      }
    } catch (e) {
      debugPrint('Auth initialization error: $e');
      _error = 'Failed to initialize authentication';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Login with connection configuration
  Future<bool> login(ConnectionConfig config) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Validate the connection (basic URL validation)
      if (config.serverUrl.isEmpty || config.token.isEmpty) {
        throw Exception('Server URL and token are required');
      }

      // Create session
      _session = UserSession(
        serverUrl: config.serverUrl,
        token: config.token,
        personalOsUrl: config.personalOsUrl,
        personalOsToken: config.personalOsToken,
      );

      // Save to preferences if remember me is enabled
      if (config.rememberMe) {
        await _prefs?.setString(_keyServerUrl, config.serverUrl);
        await _prefs?.setString(_keyToken, config.token);
        if (config.personalOsUrl != null) {
          await _prefs?.setString(_keyPersonalOsUrl, config.personalOsUrl!);
        }
        if (config.personalOsToken != null) {
          await _prefs?.setString(_keyPersonalOsToken, config.personalOsToken!);
        }
        await _prefs?.setBool(_keyRememberMe, true);
      }
      await _prefs?.setBool(_keyIsLoggedIn, true);

      _isLoggedIn = true;
      return true;
    } catch (e) {
      _error = e.toString();
      _session = null;
      _isLoggedIn = false;
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Logout and clear session
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Clear stored credentials
      await _prefs?.remove(_keyServerUrl);
      await _prefs?.remove(_keyToken);
      await _prefs?.remove(_keyPersonalOsUrl);
      await _prefs?.remove(_keyPersonalOsToken);
      await _prefs?.setBool(_keyIsLoggedIn, false);

      _session = null;
      _isLoggedIn = false;
      _error = null;
    } catch (e) {
      debugPrint('Logout error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get saved server URL for auto-fill
  String? getSavedServerUrl() {
    return _prefs?.getString(_keyServerUrl);
  }

  /// Get saved Personal OS URL for auto-fill
  String? getSavedPersonalOsUrl() {
    return _prefs?.getString(_keyPersonalOsUrl);
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
