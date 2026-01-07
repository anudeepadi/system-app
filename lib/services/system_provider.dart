/// SYSTEM State Provider
///
/// Provides reactive state management for the Flutter app using Provider.
/// Wraps SystemMCPClient with ChangeNotifier for UI updates.

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'system_mcp_client.dart';
import '../models/messages.dart';
import '../models/now_playing.dart';

/// Categories of tools for organized display
enum ToolCategory {
  system('System', ['battery_status', 'wifi_status', 'storage_status', 'running_apps', 'front_app']),
  media('Media', ['music_play', 'music_pause', 'music_next', 'music_previous', 'music_current', 'volume_set', 'volume_get', 'volume_up', 'volume_down', 'volume_mute', 'now_playing']),
  display('Display', ['brightness_set', 'brightness_get', 'dark_mode_toggle', 'dark_mode_status', 'night_shift_toggle', 'screenshot']),
  power('Power', ['lock_screen', 'sleep_display', 'sleep_mac', 'dnd_toggle']),
  wireless('Wireless', ['bluetooth_status', 'bluetooth_toggle', 'wifi_toggle']),
  windows('Windows', ['window_list', 'window_focus', 'window_minimize', 'app_quit']),
  apps('Apps', ['open_app', 'open_url', 'browser_url', 'browser_tabs']),
  communication('Communication', ['notify', 'say', 'send_imessage', 'clipboard_get', 'clipboard_set', 'imessage_unread', 'mail_unread']),
  productivity('Productivity', ['calendar_today', 'calendar_upcoming', 'calendar_create', 'reminders_list', 'reminders_create']),
  notes('Notes', ['notes_list', 'notes_search', 'notes_create', 'notes_read']),
  finder('Finder', ['finder_search', 'finder_downloads', 'finder_desktop', 'finder_reveal', 'finder_trash', 'finder_list', 'file_preview', 'file_info']),
  screenshots('Screenshots', ['screenshot_list', 'screenshot_get']),
  shell('Shell', ['shell', 'shell_list', 'applescript']),
  spotify('Spotify', [
    'spotify_player_search', 'spotify_player_nowPlaying', 'spotify_player_togglePlayPause',
    'spotify_player_next', 'spotify_player_previous', 'spotify_player_volume',
    'spotify_player_toggleShuffle', 'spotify_player_current_track'
  ]),
  raycast('Raycast', ['raycast', 'shortcut_run', 'shortcut_list']),
  other('Other', []);

  final String label;
  final List<String> toolNames;

  const ToolCategory(this.label, this.toolNames);

  static ToolCategory categorize(String toolName) {
    for (final cat in ToolCategory.values) {
      if (cat.toolNames.contains(toolName)) return cat;
    }
    return ToolCategory.other;
  }
}

/// Main state provider for SYSTEM
class SystemProvider extends ChangeNotifier {
  final SystemMCPClient _client = SystemMCPClient();

  // Connection state
  ConnectionState _connectionState = ConnectionState.disconnected;
  String? _errorMessage;

  // Data
  List<ToolInfo> _tools = [];
  SystemStatus? _status;
  SystemMetrics? _metrics;
  final List<ExecutionLog> _logs = [];
  final Map<String, ProgressMessage> _activeProgress = {};

  // Now Playing
  NowPlaying? _nowPlaying;
  Timer? _nowPlayingTimer;
  bool _nowPlayingEnabled = false;

  // Subscriptions
  StreamSubscription? _statusSub;
  StreamSubscription? _logSub;
  StreamSubscription? _progressSub;
  StreamSubscription? _stateSub;

  // Connection info
  String? _serverUrl;
  String? _token;

  // Getters
  ConnectionState get connectionState => _connectionState;
  String? get errorMessage => _errorMessage;
  bool get isConnected => _connectionState == ConnectionState.connected;
  List<ToolInfo> get tools => _tools;
  SystemStatus? get status => _status;
  SystemMetrics? get metrics => _metrics;
  List<ExecutionLog> get logs => List.unmodifiable(_logs);
  Map<String, ProgressMessage> get activeProgress => Map.unmodifiable(_activeProgress);
  String? get sessionId => _client.sessionId;
  NowPlaying? get nowPlaying => _nowPlaying;
  bool get isNowPlayingEnabled => _nowPlayingEnabled;
  String? get serverUrl => _serverUrl;
  String? get token => _token;

  /// Get tools organized by category
  Map<ToolCategory, List<ToolInfo>> get toolsByCategory {
    final result = <ToolCategory, List<ToolInfo>>{};
    for (final tool in _tools) {
      final category = ToolCategory.categorize(tool.name);
      result.putIfAbsent(category, () => []).add(tool);
    }
    return result;
  }

  /// Connect to SYSTEM server
  Future<void> connect(String url, String token) async {
    _errorMessage = null;
    _serverUrl = url;
    _token = token;
    notifyListeners();

    try {
      // Subscribe to state changes
      _stateSub = _client.stateStream.listen((state) {
        _connectionState = state;
        notifyListeners();
      });

      await _client.connect(url, token);

      // Load tools
      _tools = await _client.listTools();

      // Subscribe to updates
      _client.subscribe(['status', 'logs', 'progress']);

      _statusSub = _client.statusStream.listen((status) {
        _status = status;
        notifyListeners();
      });

      _logSub = _client.logStream.listen((log) {
        _logs.insert(0, log);
        if (_logs.length > 100) _logs.removeLast();
        notifyListeners();
      });

      _progressSub = _client.progressStream.listen((progress) {
        if (progress.step >= progress.total) {
          _activeProgress.remove(progress.taskId);
        } else {
          _activeProgress[progress.taskId] = progress;
        }
        notifyListeners();
      });

      // Get initial status
      try {
        _status = await _client.getStatus();
        notifyListeners();
      } catch (_) {}

    } catch (e) {
      _errorMessage = e.toString();
      _connectionState = ConnectionState.error;
      notifyListeners();
      rethrow;
    }
  }

  /// Disconnect from server
  Future<void> disconnect() async {
    await _statusSub?.cancel();
    await _logSub?.cancel();
    await _progressSub?.cancel();
    await _stateSub?.cancel();
    await _client.disconnect();
    _status = null;
    _logs.clear();
    _activeProgress.clear();
    notifyListeners();
  }

  /// Execute a tool
  Future<ToolResult> callTool(String name, [Map<String, dynamic>? args]) async {
    return _client.callTool(name, args);
  }

  /// Refresh tools list
  Future<void> refreshTools() async {
    _tools = await _client.listTools(forceRefresh: true);
    notifyListeners();
  }

  /// Refresh status
  Future<void> refreshStatus() async {
    try {
      _status = await _client.getStatus();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to get status: $e';
      notifyListeners();
    }
  }

  /// Get metrics
  Future<void> refreshMetrics() async {
    try {
      _metrics = await _client.getMetrics();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to get metrics: $e';
      notifyListeners();
    }
  }

  /// Start polling for now playing info
  void startNowPlayingPolling() {
    if (_nowPlayingEnabled) return;
    _nowPlayingEnabled = true;
    _refreshNowPlaying(); // Fetch immediately
    _nowPlayingTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _refreshNowPlaying(),
    );
  }

  /// Stop polling for now playing info
  void stopNowPlayingPolling() {
    _nowPlayingEnabled = false;
    _nowPlayingTimer?.cancel();
    _nowPlayingTimer = null;
  }

  /// Refresh now playing data
  Future<void> _refreshNowPlaying() async {
    if (!isConnected) return;
    try {
      final result = await _client.callTool('now_playing');
      _nowPlaying = NowPlaying.parse(result.text);
      notifyListeners();
    } catch (e) {
      // Silently fail - don't spam errors for polling
      _nowPlaying = NowPlaying.none;
    }
  }

  /// Manually refresh now playing
  Future<void> refreshNowPlaying() async {
    await _refreshNowPlaying();
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _nowPlayingTimer?.cancel();
    _statusSub?.cancel();
    _logSub?.cancel();
    _progressSub?.cancel();
    _stateSub?.cancel();
    _client.dispose();
    super.dispose();
  }
}

/// Quick actions for common operations
class QuickActions {
  final SystemProvider provider;

  QuickActions(this.provider);

  Future<String> getBatteryStatus() async {
    final result = await provider.callTool('battery_status');
    return result.text;
  }

  Future<String> getWifiStatus() async {
    final result = await provider.callTool('wifi_status');
    return result.text;
  }

  Future<void> playPauseMusic() async {
    await provider.callTool('music_pause');
  }

  Future<void> nextTrack() async {
    await provider.callTool('music_next');
  }

  Future<void> previousTrack() async {
    await provider.callTool('music_previous');
  }

  Future<String> getCurrentTrack() async {
    final result = await provider.callTool('music_current');
    return result.text;
  }

  Future<void> setVolume(int level) async {
    await provider.callTool('volume_set', {'level': level});
  }

  Future<void> toggleDarkMode() async {
    await provider.callTool('dark_mode_toggle');
  }

  Future<void> lockScreen() async {
    await provider.callTool('lock_screen');
  }

  Future<void> notify(String message, {String? title, String? sound}) async {
    await provider.callTool('notify', {
      'message': message,
      if (title != null) 'title': title,
      if (sound != null) 'sound': sound,
    });
  }

  Future<void> openApp(String name) async {
    await provider.callTool('open_app', {'name': name});
  }

  Future<void> openUrl(String url) async {
    await provider.callTool('open_url', {'url': url});
  }

  Future<String> runShell(String command) async {
    final result = await provider.callTool('shell', {'command': command});
    return result.text;
  }
}
