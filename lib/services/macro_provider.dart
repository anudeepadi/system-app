/// Macro Provider
///
/// State management for the macros system.
/// Handles loading, saving, and executing macros.

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/macro.dart';
import 'macro_storage.dart';
import 'system_provider.dart';

/// Provider for macro state management
class MacroProvider extends ChangeNotifier {
  final MacroStorage _storage = MacroStorage();
  final SystemProvider _systemProvider;

  // State
  List<Macro> _macros = [];
  MacroExecutionState? _executionState;
  bool _isLoading = false;
  String? _error;

  // Execution control
  bool _cancelRequested = false;

  MacroProvider(this._systemProvider);

  // ============================================================================
  // Getters
  // ============================================================================

  /// All macros (presets + user-created)
  List<Macro> get macros => List.unmodifiable(_macros);

  /// Only preset macros
  List<Macro> get presetMacros => _macros.where((m) => m.isPreset).toList();

  /// Only user-created macros
  List<Macro> get userMacros => _macros.where((m) => !m.isPreset).toList();

  /// Current execution state (null if not executing)
  MacroExecutionState? get executionState => _executionState;

  /// Whether a macro is currently being executed
  bool get isExecuting => _executionState?.isRunning ?? false;

  /// Whether macros are being loaded
  bool get isLoading => _isLoading;

  /// Last error message
  String? get error => _error;

  // ============================================================================
  // Initialization
  // ============================================================================

  /// Initialize the provider (load macros from storage)
  Future<void> init() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _storage.init();
      _macros = await _storage.getAllMacros();
    } catch (e) {
      _error = 'Failed to load macros: $e';
      // Fall back to presets only
      _macros = PresetMacros.all;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh macros from storage
  Future<void> refresh() async {
    try {
      _macros = await _storage.getAllMacros();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to refresh macros: $e';
      notifyListeners();
    }
  }

  // ============================================================================
  // CRUD Operations
  // ============================================================================

  /// Create a new macro
  Future<Macro> createMacro({
    required String name,
    required String description,
    String? iconName,
    required List<MacroStep> steps,
  }) async {
    final macro = Macro(
      id: _storage.generateId(),
      name: name,
      description: description,
      iconName: iconName,
      steps: steps,
      isPreset: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _storage.saveMacro(macro);
    _macros = await _storage.getAllMacros();
    notifyListeners();

    return macro;
  }

  /// Update an existing macro
  Future<void> updateMacro(Macro macro) async {
    if (macro.isPreset) {
      throw Exception('Cannot modify preset macros');
    }

    final updated = macro.copyWith(updatedAt: DateTime.now());
    await _storage.saveMacro(updated);
    _macros = await _storage.getAllMacros();
    notifyListeners();
  }

  /// Delete a macro by ID
  Future<void> deleteMacro(String id) async {
    final macro = _macros.firstWhere((m) => m.id == id);
    if (macro.isPreset) {
      throw Exception('Cannot delete preset macros');
    }

    await _storage.deleteMacro(id);
    _macros = await _storage.getAllMacros();
    notifyListeners();
  }

  /// Get a macro by ID
  Macro? getMacro(String id) {
    return _macros.where((m) => m.id == id).firstOrNull;
  }

  /// Duplicate a macro (creates a copy with new ID)
  Future<Macro> duplicateMacro(String id) async {
    final original = getMacro(id);
    if (original == null) {
      throw Exception('Macro not found');
    }

    return createMacro(
      name: '${original.name} (Copy)',
      description: original.description,
      iconName: original.iconName,
      steps: original.steps,
    );
  }

  // ============================================================================
  // Execution
  // ============================================================================

  /// Run a macro by ID
  Future<MacroExecutionState> runMacro(String id) async {
    final macro = getMacro(id);
    if (macro == null) {
      throw Exception('Macro not found');
    }

    return runMacroInstance(macro);
  }

  /// Run a macro instance
  Future<MacroExecutionState> runMacroInstance(Macro macro) async {
    if (isExecuting) {
      throw Exception('Another macro is already running');
    }

    if (!_systemProvider.isConnected) {
      throw Exception('Not connected to server');
    }

    _cancelRequested = false;

    // Initialize execution state
    _executionState = MacroExecutionState(
      macroId: macro.id,
      macroName: macro.name,
      currentStep: 0,
      totalSteps: macro.steps.length,
      status: MacroExecutionStatus.running,
      results: [],
      startedAt: DateTime.now(),
    );
    notifyListeners();

    final results = <MacroStepResult>[];

    try {
      for (var i = 0; i < macro.steps.length; i++) {
        // Check for cancellation
        if (_cancelRequested) {
          _executionState = _executionState!.copyWith(
            status: MacroExecutionStatus.cancelled,
            completedAt: DateTime.now(),
          );
          notifyListeners();
          return _executionState!;
        }

        final step = macro.steps[i];
        final stepStart = DateTime.now();

        // Update current step
        _executionState = _executionState!.copyWith(
          currentStep: i,
        );
        notifyListeners();

        try {
          // Execute the tool
          final result = await _systemProvider.callTool(step.toolName, step.args);

          results.add(MacroStepResult(
            stepIndex: i,
            toolName: step.toolName,
            success: true,
            resultText: result.text,
            durationMs: DateTime.now().difference(stepStart).inMilliseconds,
          ));
        } catch (e) {
          results.add(MacroStepResult(
            stepIndex: i,
            toolName: step.toolName,
            success: false,
            resultText: '',
            durationMs: DateTime.now().difference(stepStart).inMilliseconds,
            error: e.toString(),
          ));

          // Continue execution even if a step fails
          // (user can choose to stop on error in future enhancement)
        }

        // Update results
        _executionState = _executionState!.copyWith(
          results: List.from(results),
        );
        notifyListeners();

        // Wait for delay before next step (if not last step)
        if (i < macro.steps.length - 1 && step.delayAfterMs > 0) {
          await Future.delayed(Duration(milliseconds: step.delayAfterMs));
        }
      }

      // All steps completed
      final hasErrors = results.any((r) => !r.success);
      _executionState = _executionState!.copyWith(
        currentStep: macro.steps.length,
        status: hasErrors
            ? MacroExecutionStatus.failed
            : MacroExecutionStatus.completed,
        completedAt: DateTime.now(),
      );
      notifyListeners();
    } catch (e) {
      _executionState = _executionState!.copyWith(
        status: MacroExecutionStatus.failed,
        error: e.toString(),
        completedAt: DateTime.now(),
      );
      notifyListeners();
    }

    return _executionState!;
  }

  /// Cancel the currently running macro
  void cancelExecution() {
    if (isExecuting) {
      _cancelRequested = true;
    }
  }

  /// Clear the execution state (after viewing results)
  void clearExecutionState() {
    _executionState = null;
    notifyListeners();
  }

  // ============================================================================
  // Import/Export
  // ============================================================================

  /// Export user macros as JSON
  Future<String> exportMacros() async {
    return _storage.exportMacros();
  }

  /// Import macros from JSON
  Future<int> importMacros(String json) async {
    final count = await _storage.importMacros(json);
    if (count > 0) {
      await refresh();
    }
    return count;
  }

  // ============================================================================
  // Cleanup
  // ============================================================================

  @override
  void dispose() {
    _cancelRequested = true;
    super.dispose();
  }
}
