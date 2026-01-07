/// Personal OS API Provider
///
/// Handles REST API communication with the Personal OS backend
/// for tasks, AI chat, and focus management.

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Task model matching the Personal OS API
class Task {
  final String filename;
  final String title;
  final String priority;
  final String status;
  final String? context;  // category from API
  final String? deadline;
  final List<String> tags;
  final String? notes;
  final int? estimatedMinutes;

  Task({
    required this.filename,
    required this.title,
    required this.priority,
    required this.status,
    this.context,
    this.deadline,
    this.tags = const [],
    this.notes,
    this.estimatedMinutes,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      filename: json['filename'] ?? '',
      title: json['title'] ?? 'Untitled',
      priority: json['priority'] ?? 'P2',
      status: json['status'] ?? 'n',
      context: json['category'],  // API uses 'category'
      deadline: json['due_date'],  // API uses 'due_date'
      tags: List<String>.from(json['tags'] ?? []),
      notes: json['body_content'],  // API uses 'body_content'
      estimatedMinutes: json['estimated_time'] != null
          ? (json['estimated_time'] as num).toInt() ~/ 60  // API uses seconds
          : null,
    );
  }

  /// Human-readable status
  String get statusText {
    switch (status) {
      case 'n':
        return 'Not Started';
      case 's':
        return 'Started';
      case 'b':
        return 'Blocked';
      case 'd':
        return 'Done';
      default:
        return status;
    }
  }

  /// Status color indicator
  String get statusEmoji {
    switch (status) {
      case 'n':
        return '○';
      case 's':
        return '◐';
      case 'b':
        return '✕';
      case 'd':
        return '●';
      default:
        return '?';
    }
  }
}

/// Chat message from AI
class ChatResponse {
  final String response;
  final String model;
  final int durationMs;

  ChatResponse({
    required this.response,
    required this.model,
    required this.durationMs,
  });

  factory ChatResponse.fromJson(Map<String, dynamic> json) {
    return ChatResponse(
      response: json['response'] ?? '',
      model: json['model'] ?? 'unknown',
      durationMs: json['duration_ms'] ?? 0,
    );
  }
}

/// Daily focus data
class DailyFocus {
  final String date;
  final String summary;
  final List<String> topPriorities;
  final String recommendation;

  DailyFocus({
    required this.date,
    required this.summary,
    required this.topPriorities,
    required this.recommendation,
  });

  factory DailyFocus.fromJson(Map<String, dynamic> json) {
    return DailyFocus(
      date: json['date'] ?? '',
      summary: json['summary'] ?? '',
      topPriorities: List<String>.from(json['top_priorities'] ?? []),
      recommendation: json['recommendation'] ?? '',
    );
  }
}

/// Priority distribution
class PriorityStats {
  final int p0;
  final int p1;
  final int p2;
  final int p3;

  PriorityStats({
    required this.p0,
    required this.p1,
    required this.p2,
    required this.p3,
  });

  factory PriorityStats.fromJson(Map<String, dynamic> json) {
    return PriorityStats(
      p0: json['P0'] ?? 0,
      p1: json['P1'] ?? 0,
      p2: json['P2'] ?? 0,
      p3: json['P3'] ?? 0,
    );
  }

  int get total => p0 + p1 + p2 + p3;
}

/// Personal OS API Provider
class PersonalOsProvider extends ChangeNotifier {
  static const String defaultBaseUrl = 'http://localhost:8765';
  static const String defaultToken = 'test-token-12345';

  String _baseUrl;
  String _token;
  bool _isConnected = false;
  bool _isLoading = false;
  String? _error;

  List<Task> _tasks = [];
  DailyFocus? _dailyFocus;
  PriorityStats? _priorityStats;
  List<ChatMessage> _chatHistory = [];
  bool _isChatting = false;

  PersonalOsProvider({
    String? baseUrl,
    String? token,
  })  : _baseUrl = baseUrl ?? defaultBaseUrl,
        _token = token ?? defaultToken;

  // Getters
  bool get isConnected => _isConnected;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Task> get tasks => _tasks;
  DailyFocus? get dailyFocus => _dailyFocus;
  PriorityStats? get priorityStats => _priorityStats;
  List<ChatMessage> get chatHistory => _chatHistory;
  bool get isChatting => _isChatting;

  /// Filter tasks by priority
  List<Task> tasksByPriority(String priority) {
    return _tasks.where((t) => t.priority == priority).toList();
  }

  /// Filter tasks by status
  List<Task> tasksByStatus(String status) {
    return _tasks.where((t) => t.status == status).toList();
  }

  /// Get active tasks (not done)
  List<Task> get activeTasks {
    return _tasks.where((t) => t.status != 'd').toList();
  }

  /// HTTP headers with auth
  Map<String, String> get _headers => {
        'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json',
      };

  /// Check server health and connection
  Future<bool> checkConnection() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/health'),
      ).timeout(const Duration(seconds: 5));

      _isConnected = response.statusCode == 200;
      _error = null;
      notifyListeners();
      return _isConnected;
    } catch (e) {
      _isConnected = false;
      _error = 'Connection failed: $e';
      notifyListeners();
      return false;
    }
  }

  /// Connect to the API
  Future<void> connect({String? baseUrl, String? token}) async {
    if (baseUrl != null) _baseUrl = baseUrl;
    if (token != null) _token = token;

    _isLoading = true;
    notifyListeners();

    try {
      final connected = await checkConnection();
      if (connected) {
        // Load initial data
        await Future.wait([
          fetchTasks(),
          fetchDailyFocus(),
          fetchPriorities(),
        ]);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch all tasks
  Future<void> fetchTasks({String? priority}) async {
    try {
      String url = '$_baseUrl/tasks';
      if (priority != null) {
        url += '?priority=$priority';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        // Handle both {tasks: [...]} and direct [...] formats
        final List<dynamic> data = decoded is Map ? decoded['tasks'] ?? [] : decoded;
        _tasks = data.map((t) => Task.fromJson(t)).toList();
        _error = null;
      } else {
        _error = 'Failed to fetch tasks: ${response.statusCode}';
      }
    } catch (e) {
      _error = 'Error fetching tasks: $e';
    }
    notifyListeners();
  }

  /// Get a single task
  Future<Task?> fetchTask(String filename) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/tasks/$filename'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return Task.fromJson(json.decode(response.body));
      }
    } catch (e) {
      _error = 'Error fetching task: $e';
      notifyListeners();
    }
    return null;
  }

  /// Update task status
  Future<bool> updateTaskStatus(String filename, String status) async {
    try {
      final response = await http.patch(
        Uri.parse('$_baseUrl/tasks/$filename/status'),
        headers: _headers,
        body: json.encode({'status': status}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        // Update local task
        final index = _tasks.indexWhere((t) => t.filename == filename);
        if (index >= 0) {
          final oldTask = _tasks[index];
          _tasks[index] = Task(
            filename: oldTask.filename,
            title: oldTask.title,
            priority: oldTask.priority,
            status: status,
            context: oldTask.context,
            deadline: oldTask.deadline,
            tags: oldTask.tags,
            notes: oldTask.notes,
            estimatedMinutes: oldTask.estimatedMinutes,
          );
          notifyListeners();
        }
        return true;
      } else {
        _error = 'Failed to update status: ${response.statusCode}';
        notifyListeners();
      }
    } catch (e) {
      _error = 'Error updating status: $e';
      notifyListeners();
    }
    return false;
  }

  /// Fetch daily focus
  Future<void> fetchDailyFocus() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/focus'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        _dailyFocus = DailyFocus.fromJson(json.decode(response.body));
        _error = null;
      }
    } catch (e) {
      // Focus might not be generated yet, not critical
      debugPrint('Focus not available: $e');
    }
    notifyListeners();
  }

  /// Fetch priority distribution
  Future<void> fetchPriorities() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/priorities'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        _priorityStats = PriorityStats.fromJson(json.decode(response.body));
        _error = null;
      }
    } catch (e) {
      debugPrint('Priorities not available: $e');
    }
    notifyListeners();
  }

  /// Send chat message to AI
  Future<ChatResponse?> sendChatMessage(String message) async {
    _isChatting = true;
    _chatHistory.add(ChatMessage(
      content: message,
      isUser: true,
      timestamp: DateTime.now(),
    ));
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/chat'),
        headers: _headers,
        body: json.encode({'message': message}),
      ).timeout(const Duration(seconds: 60)); // Chat can take 10-30s

      if (response.statusCode == 200) {
        final chatResponse = ChatResponse.fromJson(json.decode(response.body));
        _chatHistory.add(ChatMessage(
          content: chatResponse.response,
          isUser: false,
          timestamp: DateTime.now(),
          metadata: 'Model: ${chatResponse.model} | ${chatResponse.durationMs}ms',
        ));
        _error = null;
        return chatResponse;
      } else {
        _error = 'Chat failed: ${response.statusCode}';
        _chatHistory.add(ChatMessage(
          content: 'Error: ${response.statusCode} - ${response.body}',
          isUser: false,
          timestamp: DateTime.now(),
          isError: true,
        ));
      }
    } catch (e) {
      _error = 'Chat error: $e';
      _chatHistory.add(ChatMessage(
        content: 'Error: $e',
        isUser: false,
        timestamp: DateTime.now(),
        isError: true,
      ));
    } finally {
      _isChatting = false;
      notifyListeners();
    }
    return null;
  }

  /// Clear chat history
  void clearChatHistory() {
    _chatHistory.clear();
    notifyListeners();
  }

  /// Refresh all data
  Future<void> refresh() async {
    _isLoading = true;
    notifyListeners();

    try {
      await Future.wait([
        fetchTasks(),
        fetchDailyFocus(),
        fetchPriorities(),
      ]);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

/// Chat message for history
class ChatMessage {
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final String? metadata;
  final bool isError;

  ChatMessage({
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.metadata,
    this.isError = false,
  });
}
