/// Macro Storage Service
///
/// Handles persistence of user-created macros using SharedPreferences.
/// Preset macros are not stored - they come from PresetMacros class.

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/macro.dart';

/// Storage key for macros
const String _macrosKey = 'system_macros';

/// Service for persisting macros locally
class MacroStorage {
  SharedPreferences? _prefs;

  /// Initialize the storage (call before using)
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Get SharedPreferences instance (initializes if needed)
  Future<SharedPreferences> get _preferences async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// Load all user-created macros
  Future<List<Macro>> loadMacros() async {
    final prefs = await _preferences;
    final jsonString = prefs.getString(_macrosKey);

    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }

    try {
      final jsonList = jsonDecode(jsonString) as List;
      return jsonList
          .map((json) => Macro.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // If parsing fails, return empty list (data corruption recovery)
      return [];
    }
  }

  /// Save all user-created macros
  Future<void> saveMacros(List<Macro> macros) async {
    final prefs = await _preferences;

    // Filter out presets - they shouldn't be persisted
    final userMacros = macros.where((m) => !m.isPreset).toList();

    final jsonList = userMacros.map((m) => m.toJson()).toList();
    final jsonString = jsonEncode(jsonList);

    await prefs.setString(_macrosKey, jsonString);
  }

  /// Add or update a single macro
  Future<void> saveMacro(Macro macro) async {
    if (macro.isPreset) {
      // Don't persist presets
      return;
    }

    final macros = await loadMacros();
    final index = macros.indexWhere((m) => m.id == macro.id);

    if (index >= 0) {
      macros[index] = macro;
    } else {
      macros.add(macro);
    }

    await saveMacros(macros);
  }

  /// Delete a macro by ID
  Future<void> deleteMacro(String id) async {
    final macros = await loadMacros();
    macros.removeWhere((m) => m.id == id);
    await saveMacros(macros);
  }

  /// Get a specific macro by ID
  Future<Macro?> getMacro(String id) async {
    // Check presets first
    final preset = PresetMacros.all.where((m) => m.id == id).firstOrNull;
    if (preset != null) {
      return preset;
    }

    // Check user macros
    final macros = await loadMacros();
    return macros.where((m) => m.id == id).firstOrNull;
  }

  /// Clear all user macros
  Future<void> clearAll() async {
    final prefs = await _preferences;
    await prefs.remove(_macrosKey);
  }

  /// Get all macros (presets + user-created)
  Future<List<Macro>> getAllMacros() async {
    final userMacros = await loadMacros();
    return [...PresetMacros.all, ...userMacros];
  }

  /// Check if a macro name already exists
  Future<bool> nameExists(String name, {String? excludeId}) async {
    final allMacros = await getAllMacros();
    return allMacros.any((m) =>
        m.name.toLowerCase() == name.toLowerCase() && m.id != excludeId);
  }

  /// Generate a unique ID for a new macro
  String generateId() {
    return 'macro_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Export macros as JSON string (for backup/sharing)
  Future<String> exportMacros() async {
    final userMacros = await loadMacros();
    return jsonEncode(userMacros.map((m) => m.toJson()).toList());
  }

  /// Import macros from JSON string
  Future<int> importMacros(String jsonString) async {
    try {
      final jsonList = jsonDecode(jsonString) as List;
      final importedMacros = jsonList
          .map((json) => Macro.fromJson(json as Map<String, dynamic>))
          .toList();

      final existingMacros = await loadMacros();
      var importCount = 0;

      for (final macro in importedMacros) {
        // Generate new ID to avoid conflicts
        final newMacro = macro.copyWith(
          id: generateId(),
          isPreset: false,
          updatedAt: DateTime.now(),
        );

        // Check if name doesn't conflict
        if (!existingMacros.any(
            (m) => m.name.toLowerCase() == newMacro.name.toLowerCase())) {
          existingMacros.add(newMacro);
          importCount++;
        }
      }

      await saveMacros(existingMacros);
      return importCount;
    } catch (e) {
      return 0;
    }
  }
}
