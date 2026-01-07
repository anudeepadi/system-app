/// Macro Models
///
/// Data classes for the custom macros system.
/// Macros are sequences of tool calls that can be saved and executed together.

import 'dart:convert';

/// A single step in a macro - one tool call with arguments
class MacroStep {
  final String toolName;
  final Map<String, dynamic> args;
  final int delayAfterMs; // Delay before next step executes

  const MacroStep({
    required this.toolName,
    this.args = const {},
    this.delayAfterMs = 0,
  });

  MacroStep copyWith({
    String? toolName,
    Map<String, dynamic>? args,
    int? delayAfterMs,
  }) {
    return MacroStep(
      toolName: toolName ?? this.toolName,
      args: args ?? this.args,
      delayAfterMs: delayAfterMs ?? this.delayAfterMs,
    );
  }

  Map<String, dynamic> toJson() => {
        'toolName': toolName,
        'args': args,
        'delayAfterMs': delayAfterMs,
      };

  factory MacroStep.fromJson(Map<String, dynamic> json) => MacroStep(
        toolName: json['toolName'] as String,
        args: Map<String, dynamic>.from(json['args'] as Map? ?? {}),
        delayAfterMs: json['delayAfterMs'] as int? ?? 0,
      );
}

/// A complete macro with metadata and steps
class Macro {
  final String id;
  final String name;
  final String description;
  final String? iconName; // Material icon name
  final List<MacroStep> steps;
  final bool isPreset; // Built-in presets can't be deleted
  final DateTime createdAt;
  final DateTime updatedAt;

  const Macro({
    required this.id,
    required this.name,
    required this.description,
    this.iconName,
    required this.steps,
    this.isPreset = false,
    required this.createdAt,
    required this.updatedAt,
  });

  Macro copyWith({
    String? id,
    String? name,
    String? description,
    String? iconName,
    List<MacroStep>? steps,
    bool? isPreset,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Macro(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      iconName: iconName ?? this.iconName,
      steps: steps ?? this.steps,
      isPreset: isPreset ?? this.isPreset,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'iconName': iconName,
        'steps': steps.map((s) => s.toJson()).toList(),
        'isPreset': isPreset,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Macro.fromJson(Map<String, dynamic> json) => Macro(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String,
        iconName: json['iconName'] as String?,
        steps: (json['steps'] as List)
            .map((s) => MacroStep.fromJson(s as Map<String, dynamic>))
            .toList(),
        isPreset: json['isPreset'] as bool? ?? false,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );

  String encode() => jsonEncode(toJson());

  static Macro decode(String json) =>
      Macro.fromJson(jsonDecode(json) as Map<String, dynamic>);

  /// Total estimated duration based on step delays
  int get totalDelayMs => steps.fold(0, (sum, step) => sum + step.delayAfterMs);
}

/// Status of macro execution
enum MacroExecutionStatus {
  idle,
  running,
  completed,
  failed,
  cancelled,
}

/// Result of a single step execution
class MacroStepResult {
  final int stepIndex;
  final String toolName;
  final bool success;
  final String resultText;
  final int durationMs;
  final String? error;

  const MacroStepResult({
    required this.stepIndex,
    required this.toolName,
    required this.success,
    required this.resultText,
    required this.durationMs,
    this.error,
  });
}

/// Current state of macro execution
class MacroExecutionState {
  final String macroId;
  final String macroName;
  final int currentStep;
  final int totalSteps;
  final MacroExecutionStatus status;
  final String? error;
  final List<MacroStepResult> results;
  final DateTime startedAt;
  final DateTime? completedAt;

  const MacroExecutionState({
    required this.macroId,
    required this.macroName,
    required this.currentStep,
    required this.totalSteps,
    required this.status,
    this.error,
    this.results = const [],
    required this.startedAt,
    this.completedAt,
  });

  MacroExecutionState copyWith({
    String? macroId,
    String? macroName,
    int? currentStep,
    int? totalSteps,
    MacroExecutionStatus? status,
    String? error,
    List<MacroStepResult>? results,
    DateTime? startedAt,
    DateTime? completedAt,
  }) {
    return MacroExecutionState(
      macroId: macroId ?? this.macroId,
      macroName: macroName ?? this.macroName,
      currentStep: currentStep ?? this.currentStep,
      totalSteps: totalSteps ?? this.totalSteps,
      status: status ?? this.status,
      error: error ?? this.error,
      results: results ?? this.results,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  /// Progress as percentage (0.0 to 1.0)
  double get progress =>
      totalSteps > 0 ? currentStep / totalSteps : 0.0;

  /// Whether the macro is currently executing
  bool get isRunning => status == MacroExecutionStatus.running;

  /// Whether execution has finished (success, failure, or cancelled)
  bool get isFinished =>
      status == MacroExecutionStatus.completed ||
      status == MacroExecutionStatus.failed ||
      status == MacroExecutionStatus.cancelled;

  /// Count of successful steps
  int get successCount => results.where((r) => r.success).length;

  /// Count of failed steps
  int get failureCount => results.where((r) => !r.success).length;

  /// Total execution time
  Duration? get duration => completedAt != null
      ? completedAt!.difference(startedAt)
      : DateTime.now().difference(startedAt);
}

/// Preset macro definitions
class PresetMacros {
  static final movieMode = Macro(
    id: 'preset_movie_mode',
    name: 'Movie Mode',
    description: 'DND on, Dark Mode, Volume 50%',
    iconName: 'movie',
    isPreset: true,
    steps: [
      const MacroStep(toolName: 'dnd_toggle', delayAfterMs: 300),
      const MacroStep(toolName: 'dark_mode_toggle', delayAfterMs: 300),
      const MacroStep(toolName: 'volume_set', args: {'level': 50}),
    ],
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
  );

  static final workMode = Macro(
    id: 'preset_work_mode',
    name: 'Work Mode',
    description: 'Open work apps, enable DND',
    iconName: 'work',
    isPreset: true,
    steps: [
      const MacroStep(
          toolName: 'open_app', args: {'name': 'Slack'}, delayAfterMs: 1000),
      const MacroStep(
          toolName: 'open_app',
          args: {'name': 'Visual Studio Code'},
          delayAfterMs: 500),
      const MacroStep(toolName: 'dnd_toggle'),
    ],
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
  );

  static final goodNight = Macro(
    id: 'preset_good_night',
    name: 'Good Night',
    description: 'DND, lock screen, sleep display',
    iconName: 'bedtime',
    isPreset: true,
    steps: [
      const MacroStep(toolName: 'dnd_toggle', delayAfterMs: 300),
      const MacroStep(toolName: 'lock_screen', delayAfterMs: 500),
      const MacroStep(toolName: 'sleep_display'),
    ],
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
  );

  static final meetingMode = Macro(
    id: 'preset_meeting_mode',
    name: 'Meeting Mode',
    description: 'DND on, mute volume',
    iconName: 'groups',
    isPreset: true,
    steps: [
      const MacroStep(toolName: 'dnd_toggle', delayAfterMs: 300),
      const MacroStep(toolName: 'volume_mute'),
    ],
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
  );

  static final breakTime = Macro(
    id: 'preset_break_time',
    name: 'Break Time',
    description: 'Open Music, set volume 30%',
    iconName: 'coffee',
    isPreset: true,
    steps: [
      const MacroStep(
          toolName: 'open_app', args: {'name': 'Music'}, delayAfterMs: 1000),
      const MacroStep(toolName: 'volume_set', args: {'level': 30}),
    ],
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
  );

  static List<Macro> get all => [
        movieMode,
        workMode,
        goodNight,
        meetingMode,
        breakTime,
      ];
}
