/// WebSocket MCP Protocol Messages for SYSTEM
///
/// These models define the message protocol for communication
/// between the Flutter app and the SYSTEM WebSocket server.

import 'dart:convert';

// ============================================================================
// Client -> Server Messages
// ============================================================================

/// Base class for all client messages
sealed class ClientMessage {
  Map<String, dynamic> toJson();
  String encode() => jsonEncode(toJson());
}

/// Authentication message
class AuthMessage extends ClientMessage {
  final String token;
  AuthMessage(this.token);

  @override
  Map<String, dynamic> toJson() => {'type': 'auth', 'token': token};
}

/// Ping message for keepalive
class PingMessage extends ClientMessage {
  @override
  Map<String, dynamic> toJson() => {'type': 'ping'};
}

/// Request to list all available tools
class ListToolsMessage extends ClientMessage {
  final String requestId;
  ListToolsMessage(this.requestId);

  @override
  Map<String, dynamic> toJson() => {'type': 'list_tools', 'requestId': requestId};
}

/// Request to execute a tool
class CallToolMessage extends ClientMessage {
  final String requestId;
  final String name;
  final Map<String, dynamic> args;

  CallToolMessage({
    required this.requestId,
    required this.name,
    this.args = const {},
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'call_tool',
        'requestId': requestId,
        'name': name,
        'args': args,
      };
}

/// Subscribe to real-time updates
class SubscribeMessage extends ClientMessage {
  final List<String> topics;
  SubscribeMessage(this.topics);

  @override
  Map<String, dynamic> toJson() => {'type': 'subscribe', 'topics': topics};
}

/// Unsubscribe from real-time updates
class UnsubscribeMessage extends ClientMessage {
  final List<String> topics;
  UnsubscribeMessage(this.topics);

  @override
  Map<String, dynamic> toJson() => {'type': 'unsubscribe', 'topics': topics};
}

/// Request current system status
class GetStatusMessage extends ClientMessage {
  @override
  Map<String, dynamic> toJson() => {'type': 'get_status'};
}

/// Request execution logs
class GetLogsMessage extends ClientMessage {
  final String? since;
  final String? tool;
  final int? limit;

  GetLogsMessage({this.since, this.tool, this.limit});

  @override
  Map<String, dynamic> toJson() => {
        'type': 'get_logs',
        'options': {
          if (since != null) 'since': since,
          if (tool != null) 'tool': tool,
          if (limit != null) 'limit': limit,
        },
      };
}

/// Request metrics
class GetMetricsMessage extends ClientMessage {
  @override
  Map<String, dynamic> toJson() => {'type': 'get_metrics'};
}

// ============================================================================
// Server -> Client Messages
// ============================================================================

/// Base class for all server messages
sealed class ServerMessage {
  factory ServerMessage.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    return switch (type) {
      'auth_result' => AuthResultMessage.fromJson(json),
      'pong' => PongMessage(),
      'tools_list' => ToolsListMessage.fromJson(json),
      'tool_result' => ToolResultMessage.fromJson(json),
      'status' => StatusMessage.fromJson(json),
      'log' => LogMessage.fromJson(json),
      'logs' => LogsMessage.fromJson(json),
      'metrics' => MetricsMessage.fromJson(json),
      'progress' => ProgressMessage.fromJson(json),
      'error' => ErrorMessage.fromJson(json),
      _ => throw FormatException('Unknown message type: $type'),
    };
  }
}

/// Authentication result
class AuthResultMessage implements ServerMessage {
  final bool success;
  final String? sessionId;
  final String? error;

  AuthResultMessage({required this.success, this.sessionId, this.error});

  factory AuthResultMessage.fromJson(Map<String, dynamic> json) {
    return AuthResultMessage(
      success: json['success'] as bool,
      sessionId: json['sessionId'] as String?,
      error: json['error'] as String?,
    );
  }
}

/// Pong response
class PongMessage implements ServerMessage {}

/// List of available tools
class ToolsListMessage implements ServerMessage {
  final String requestId;
  final List<ToolInfo> tools;

  ToolsListMessage({required this.requestId, required this.tools});

  factory ToolsListMessage.fromJson(Map<String, dynamic> json) {
    return ToolsListMessage(
      requestId: json['requestId'] as String,
      tools: (json['tools'] as List)
          .map((t) => ToolInfo.fromJson(t as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Tool execution result
class ToolResultMessage implements ServerMessage {
  final String requestId;
  final ToolResult result;
  final bool isError;

  ToolResultMessage({
    required this.requestId,
    required this.result,
    this.isError = false,
  });

  factory ToolResultMessage.fromJson(Map<String, dynamic> json) {
    return ToolResultMessage(
      requestId: json['requestId'] as String,
      result: ToolResult.fromJson(json['result'] as Map<String, dynamic>),
      isError: json['isError'] as bool? ?? false,
    );
  }
}

/// System status update
class StatusMessage implements ServerMessage {
  final SystemStatus data;

  StatusMessage({required this.data});

  factory StatusMessage.fromJson(Map<String, dynamic> json) {
    return StatusMessage(
      data: SystemStatus.fromJson(json['data'] as Map<String, dynamic>),
    );
  }
}

/// Single execution log entry
class LogMessage implements ServerMessage {
  final ExecutionLog entry;

  LogMessage({required this.entry});

  factory LogMessage.fromJson(Map<String, dynamic> json) {
    return LogMessage(
      entry: ExecutionLog.fromJson(json['entry'] as Map<String, dynamic>),
    );
  }
}

/// Multiple execution log entries
class LogsMessage implements ServerMessage {
  final List<ExecutionLog> entries;

  LogsMessage({required this.entries});

  factory LogsMessage.fromJson(Map<String, dynamic> json) {
    return LogsMessage(
      entries: (json['entries'] as List)
          .map((e) => ExecutionLog.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// System metrics
class MetricsMessage implements ServerMessage {
  final SystemMetrics data;

  MetricsMessage({required this.data});

  factory MetricsMessage.fromJson(Map<String, dynamic> json) {
    return MetricsMessage(
      data: SystemMetrics.fromJson(json['data'] as Map<String, dynamic>),
    );
  }
}

/// Task progress update
class ProgressMessage implements ServerMessage {
  final String taskId;
  final int step;
  final int total;
  final String message;

  ProgressMessage({
    required this.taskId,
    required this.step,
    required this.total,
    required this.message,
  });

  factory ProgressMessage.fromJson(Map<String, dynamic> json) {
    return ProgressMessage(
      taskId: json['taskId'] as String,
      step: json['step'] as int,
      total: json['total'] as int,
      message: json['message'] as String,
    );
  }
}

/// Error message
class ErrorMessage implements ServerMessage {
  final String code;
  final String message;

  ErrorMessage({required this.code, required this.message});

  factory ErrorMessage.fromJson(Map<String, dynamic> json) {
    return ErrorMessage(
      code: json['code'] as String,
      message: json['message'] as String,
    );
  }
}

// ============================================================================
// Data Models
// ============================================================================

/// Tool information
class ToolInfo {
  final String name;
  final String description;
  final Map<String, dynamic> inputSchema;

  ToolInfo({
    required this.name,
    required this.description,
    required this.inputSchema,
  });

  factory ToolInfo.fromJson(Map<String, dynamic> json) {
    return ToolInfo(
      name: json['name'] as String,
      description: json['description'] as String,
      inputSchema: json['inputSchema'] as Map<String, dynamic>,
    );
  }

  /// Get required parameters from schema
  List<String> get requiredParams {
    final required = inputSchema['required'];
    if (required is List) {
      return required.cast<String>();
    }
    return [];
  }

  /// Get parameter properties from schema
  Map<String, dynamic> get parameters {
    final props = inputSchema['properties'];
    if (props is Map<String, dynamic>) {
      return props;
    }
    return {};
  }
}

/// Tool execution result
class ToolResult {
  final String text;
  final ToolImage? image;

  ToolResult({required this.text, this.image});

  factory ToolResult.fromJson(Map<String, dynamic> json) {
    return ToolResult(
      text: json['text'] as String? ?? '',
      image: json['image'] != null
          ? ToolImage.fromJson(json['image'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// Image result from a tool
class ToolImage {
  final String data;
  final String mimeType;

  ToolImage({required this.data, required this.mimeType});

  factory ToolImage.fromJson(Map<String, dynamic> json) {
    return ToolImage(
      data: json['data'] as String,
      mimeType: json['mimeType'] as String,
    );
  }
}

/// Battery status
class BatteryStatus {
  final int level;
  final bool isCharging;
  final String powerSource;

  BatteryStatus({required this.level, required this.isCharging, required this.powerSource});

  factory BatteryStatus.fromJson(Map<String, dynamic> json) {
    return BatteryStatus(
      level: json['level'] as int? ?? 100,
      isCharging: json['isCharging'] as bool? ?? false,
      powerSource: json['powerSource'] as String? ?? 'Unknown',
    );
  }
}

/// WiFi status
class WifiStatus {
  final bool connected;
  final String? network;

  WifiStatus({required this.connected, this.network});

  factory WifiStatus.fromJson(Map<String, dynamic> json) {
    return WifiStatus(
      connected: json['connected'] as bool? ?? false,
      network: json['network'] as String?,
    );
  }
}

/// Storage status
class StorageStatus {
  final double availableGB;
  final double totalGB;
  final int usedPercent;

  StorageStatus({required this.availableGB, required this.totalGB, required this.usedPercent});

  factory StorageStatus.fromJson(Map<String, dynamic> json) {
    return StorageStatus(
      availableGB: (json['availableGB'] as num?)?.toDouble() ?? 0,
      totalGB: (json['totalGB'] as num?)?.toDouble() ?? 0,
      usedPercent: json['usedPercent'] as int? ?? 0,
    );
  }
}

/// Apps status
class AppsStatus {
  final List<String> running;
  final String? frontApp;

  AppsStatus({required this.running, this.frontApp});

  factory AppsStatus.fromJson(Map<String, dynamic> json) {
    return AppsStatus(
      running: (json['running'] as List?)?.cast<String>() ?? [],
      frontApp: json['frontApp'] as String?,
    );
  }
}

/// System status
class SystemStatus {
  final BatteryStatus battery;
  final WifiStatus wifi;
  final StorageStatus storage;
  final AppsStatus apps;
  final DateTime timestamp;

  SystemStatus({
    required this.battery,
    required this.wifi,
    required this.storage,
    required this.apps,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory SystemStatus.fromJson(Map<String, dynamic> json) {
    return SystemStatus(
      battery: BatteryStatus.fromJson(json['battery'] as Map<String, dynamic>? ?? {}),
      wifi: WifiStatus.fromJson(json['wifi'] as Map<String, dynamic>? ?? {}),
      storage: StorageStatus.fromJson(json['storage'] as Map<String, dynamic>? ?? {}),
      apps: AppsStatus.fromJson(json['apps'] as Map<String, dynamic>? ?? {}),
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
    );
  }

  // Convenience getters for backwards compatibility
  List<String> get runningApps => apps.running;
  String? get frontApp => apps.frontApp;

  // String representations for UI display
  String get batteryString => '${battery.level}%${battery.isCharging ? ' ⚡' : ''}';
  String get wifiString => wifi.connected ? (wifi.network ?? 'Connected') : 'Not connected';
  String get storageString => '${storage.availableGB.toStringAsFixed(1)} GB free';
}

/// Execution log entry
class ExecutionLog {
  final String id;
  final DateTime timestamp;
  final String tool;
  final Map<String, dynamic> args;
  final ExecutionResult result;
  final int durationMs;
  final String? clientId;
  final String? clientType;

  ExecutionLog({
    required this.id,
    required this.timestamp,
    required this.tool,
    required this.args,
    required this.result,
    required this.durationMs,
    this.clientId,
    this.clientType,
  });

  factory ExecutionLog.fromJson(Map<String, dynamic> json) {
    return ExecutionLog(
      id: json['id'] as String? ?? '',
      timestamp: DateTime.parse(json['timestamp'] as String),
      tool: json['tool'] as String,
      args: json['args'] as Map<String, dynamic>? ?? {},
      result: ExecutionResult.fromJson(json['result'] as Map<String, dynamic>),
      durationMs: json['durationMs'] as int,
      clientId: json['clientId'] as String?,
      clientType: json['clientType'] as String?,
    );
  }
}

/// Execution result summary
class ExecutionResult {
  final bool success;
  final String text;
  final bool hasImage;

  ExecutionResult({
    required this.success,
    required this.text,
    this.hasImage = false,
  });

  factory ExecutionResult.fromJson(Map<String, dynamic> json) {
    return ExecutionResult(
      success: json['success'] as bool,
      text: json['text'] as String? ?? '',
      hasImage: json['hasImage'] as bool? ?? false,
    );
  }
}

/// System metrics
class SystemMetrics {
  final int totalExecutions;
  final double successRate;
  final double avgDurationMs;
  final Map<String, int> toolUsage;
  final int activeClients;

  SystemMetrics({
    required this.totalExecutions,
    required this.successRate,
    required this.avgDurationMs,
    required this.toolUsage,
    required this.activeClients,
  });

  factory SystemMetrics.fromJson(Map<String, dynamic> json) {
    return SystemMetrics(
      totalExecutions: json['totalExecutions'] as int,
      successRate: (json['successRate'] as num).toDouble(),
      avgDurationMs: (json['avgDurationMs'] as num).toDouble(),
      toolUsage: (json['toolUsage'] as Map<String, dynamic>)
          .map((k, v) => MapEntry(k, v as int)),
      activeClients: json['activeClients'] as int? ?? 0,
    );
  }
}
