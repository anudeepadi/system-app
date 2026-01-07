/// SYSTEM MCP WebSocket Client
///
/// Provides a high-level API for connecting to the SYSTEM WebSocket server
/// and executing Mac control tools from a Flutter mobile app.

import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/messages.dart';

/// Connection states for the MCP client
enum ConnectionState {
  disconnected,
  connecting,
  authenticating,
  connected,
  error,
}

/// Exception thrown by SystemMCPClient
class SystemMCPException implements Exception {
  final String code;
  final String message;

  SystemMCPException(this.code, this.message);

  @override
  String toString() => 'SystemMCPException($code): $message';
}

/// Main client for interacting with SYSTEM WebSocket MCP Server
class SystemMCPClient {
  WebSocketChannel? _channel;
  String? _sessionId;

  // State management
  ConnectionState _state = ConnectionState.disconnected;
  final _stateController = StreamController<ConnectionState>.broadcast();

  // Message streams
  final _statusController = StreamController<SystemStatus>.broadcast();
  final _logController = StreamController<ExecutionLog>.broadcast();
  final _progressController = StreamController<ProgressMessage>.broadcast();
  final _metricsController = StreamController<SystemMetrics>.broadcast();

  // Pending requests
  final Map<String, Completer<ServerMessage>> _pendingRequests = {};
  int _requestCounter = 0;

  // Tool cache
  List<ToolInfo>? _toolsCache;

  // Connection config
  String? _url;
  String? _token;
  Timer? _pingTimer;

  /// Current connection state
  ConnectionState get state => _state;

  /// Stream of connection state changes
  Stream<ConnectionState> get stateStream => _stateController.stream;

  /// Stream of system status updates (requires 'status' subscription)
  Stream<SystemStatus> get statusStream => _statusController.stream;

  /// Stream of execution log entries (requires 'logs' subscription)
  Stream<ExecutionLog> get logStream => _logController.stream;

  /// Stream of task progress updates (requires 'progress' subscription)
  Stream<ProgressMessage> get progressStream => _progressController.stream;

  /// Stream of metrics updates
  Stream<SystemMetrics> get metricsStream => _metricsController.stream;

  /// Current session ID (available after successful auth)
  String? get sessionId => _sessionId;

  /// Whether the client is connected and authenticated
  bool get isConnected => _state == ConnectionState.connected;

  /// Cached list of tools (available after first listTools call)
  List<ToolInfo>? get cachedTools => _toolsCache;

  /// Connect to the SYSTEM WebSocket server
  ///
  /// [url] - WebSocket URL (e.g., 'ws://localhost:3001')
  /// [token] - Authentication token from bridge.config.json
  Future<void> connect(String url, String token) async {
    if (_state == ConnectionState.connected) {
      throw SystemMCPException('ALREADY_CONNECTED', 'Already connected');
    }

    _url = url;
    _token = token;
    _setState(ConnectionState.connecting);

    try {
      _channel = WebSocketChannel.connect(Uri.parse(url));

      // Listen for messages
      _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDisconnect,
      );

      // Authenticate
      _setState(ConnectionState.authenticating);
      final authResult = await _authenticate(token);

      if (authResult.success) {
        _sessionId = authResult.sessionId;
        _setState(ConnectionState.connected);
        _startPingTimer();
      } else {
        throw SystemMCPException('AUTH_FAILED', authResult.error ?? 'Authentication failed');
      }
    } catch (e) {
      _setState(ConnectionState.error);
      rethrow;
    }
  }

  /// Disconnect from the server
  Future<void> disconnect() async {
    _pingTimer?.cancel();
    _pendingRequests.clear();
    await _channel?.sink.close();
    _channel = null;
    _sessionId = null;
    _setState(ConnectionState.disconnected);
  }

  /// List all available tools
  Future<List<ToolInfo>> listTools({bool forceRefresh = false}) async {
    _ensureConnected();

    if (_toolsCache != null && !forceRefresh) {
      return _toolsCache!;
    }

    final requestId = _nextRequestId();
    final completer = Completer<ServerMessage>();
    _pendingRequests[requestId] = completer;

    _send(ListToolsMessage(requestId));

    final response = await completer.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw SystemMCPException('TIMEOUT', 'Request timed out'),
    );

    if (response is ToolsListMessage) {
      _toolsCache = response.tools;
      return response.tools;
    }

    throw SystemMCPException('UNEXPECTED_RESPONSE', 'Unexpected response type');
  }

  /// Execute a tool
  ///
  /// [name] - Tool name (e.g., 'battery_status', 'music_play')
  /// [args] - Tool arguments
  Future<ToolResult> callTool(String name, [Map<String, dynamic>? args]) async {
    _ensureConnected();

    final requestId = _nextRequestId();
    final completer = Completer<ServerMessage>();
    _pendingRequests[requestId] = completer;

    _send(CallToolMessage(
      requestId: requestId,
      name: name,
      args: args ?? {},
    ));

    final response = await completer.future.timeout(
      const Duration(seconds: 30),
      onTimeout: () => throw SystemMCPException('TIMEOUT', 'Tool execution timed out'),
    );

    if (response is ToolResultMessage) {
      if (response.isError) {
        throw SystemMCPException('TOOL_ERROR', response.result.text);
      }
      return response.result;
    }

    throw SystemMCPException('UNEXPECTED_RESPONSE', 'Unexpected response type');
  }

  /// Subscribe to real-time updates
  ///
  /// Topics: 'status', 'logs', 'progress'
  void subscribe(List<String> topics) {
    _ensureConnected();
    _send(SubscribeMessage(topics));
  }

  /// Unsubscribe from real-time updates
  void unsubscribe(List<String> topics) {
    _ensureConnected();
    _send(UnsubscribeMessage(topics));
  }

  /// Get current system status
  Future<SystemStatus> getStatus() async {
    _ensureConnected();
    _send(GetStatusMessage());

    // Wait for status message
    return await statusStream.first.timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw SystemMCPException('TIMEOUT', 'Status request timed out'),
    );
  }

  // Pending logs/metrics completers
  Completer<List<ExecutionLog>>? _pendingLogsRequest;
  Completer<SystemMetrics>? _pendingMetricsRequest;

  /// Get execution logs
  Future<List<ExecutionLog>> getLogs({
    String? since,
    String? tool,
    int? limit,
  }) async {
    _ensureConnected();

    _pendingLogsRequest = Completer<List<ExecutionLog>>();
    _send(GetLogsMessage(since: since, tool: tool, limit: limit));

    return _pendingLogsRequest!.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        _pendingLogsRequest = null;
        throw SystemMCPException('TIMEOUT', 'Logs request timed out');
      },
    );
  }

  /// Get system metrics
  Future<SystemMetrics> getMetrics() async {
    _ensureConnected();

    _pendingMetricsRequest = Completer<SystemMetrics>();
    _send(GetMetricsMessage());

    return _pendingMetricsRequest!.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        _pendingMetricsRequest = null;
        throw SystemMCPException('TIMEOUT', 'Metrics request timed out');
      },
    );
  }

  // ============================================================================
  // Private Methods
  // ============================================================================

  // Pending auth completer
  Completer<AuthResultMessage>? _pendingAuthRequest;

  Future<AuthResultMessage> _authenticate(String token) async {
    _pendingAuthRequest = Completer<AuthResultMessage>();
    _send(AuthMessage(token));

    return _pendingAuthRequest!.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        _pendingAuthRequest = null;
        throw SystemMCPException('AUTH_TIMEOUT', 'Authentication timed out');
      },
    );
  }

  void _send(ClientMessage message) {
    _channel?.sink.add(message.encode());
  }

  void _handleMessage(dynamic data) {
    try {
      final json = jsonDecode(data as String) as Map<String, dynamic>;
      final message = ServerMessage.fromJson(json);

      switch (message) {
        case ToolsListMessage msg:
          _pendingRequests[msg.requestId]?.complete(msg);
          _pendingRequests.remove(msg.requestId);

        case ToolResultMessage msg:
          _pendingRequests[msg.requestId]?.complete(msg);
          _pendingRequests.remove(msg.requestId);

        case StatusMessage msg:
          _statusController.add(msg.data);

        case LogMessage msg:
          _logController.add(msg.entry);

        case ProgressMessage msg:
          _progressController.add(msg);

        case MetricsMessage msg:
          _metricsController.add(msg.data);
          _pendingMetricsRequest?.complete(msg.data);
          _pendingMetricsRequest = null;

        case ErrorMessage msg:
          // Complete any pending request with error
          for (final completer in _pendingRequests.values) {
            completer.completeError(SystemMCPException(msg.code, msg.message));
          }
          _pendingRequests.clear();

        case PongMessage _:
          // Heartbeat response - connection is alive
          break;

        case AuthResultMessage msg:
          _pendingAuthRequest?.complete(msg);
          _pendingAuthRequest = null;

        case LogsMessage msg:
          _pendingLogsRequest?.complete(msg.entries);
          _pendingLogsRequest = null;
      }
    } catch (e) {
      // Log parsing errors but don't crash
      print('Error parsing message: $e');
    }
  }

  void _handleError(Object error) {
    print('WebSocket error: $error');
    _setState(ConnectionState.error);
  }

  void _handleDisconnect() {
    _pingTimer?.cancel();
    _setState(ConnectionState.disconnected);

    // Complete all pending requests with disconnect error
    final error = SystemMCPException('DISCONNECTED', 'Connection closed');
    for (final completer in _pendingRequests.values) {
      completer.completeError(error);
    }
    _pendingRequests.clear();
  }

  void _setState(ConnectionState newState) {
    if (_state != newState) {
      _state = newState;
      _stateController.add(newState);
    }
  }

  void _ensureConnected() {
    if (_state != ConnectionState.connected) {
      throw SystemMCPException('NOT_CONNECTED', 'Not connected to server');
    }
  }

  String _nextRequestId() {
    _requestCounter++;
    return 'req_$_requestCounter';
  }

  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 25), (_) {
      if (_state == ConnectionState.connected) {
        _send(PingMessage());
      }
    });
  }

  /// Dispose of the client and release resources
  void dispose() {
    _pingTimer?.cancel();
    _channel?.sink.close();
    _stateController.close();
    _statusController.close();
    _logController.close();
    _progressController.close();
    _metricsController.close();
  }
}
