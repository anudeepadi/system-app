/// Macro Editor Screen
///
/// Create or edit a macro by configuring steps (tool calls).
/// Each step can have a tool selection, arguments, and delay.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/macro.dart';
import '../models/messages.dart';
import '../services/macro_provider.dart';
import '../services/system_provider.dart';

class MacroEditorScreen extends StatefulWidget {
  final Macro? macro; // null = create new, otherwise edit

  const MacroEditorScreen({super.key, this.macro});

  @override
  State<MacroEditorScreen> createState() => _MacroEditorScreenState();
}

class _MacroEditorScreenState extends State<MacroEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _selectedIcon;
  List<_EditableStep> _steps = [];
  bool _isSaving = false;

  bool get _isEditing => widget.macro != null;

  @override
  void initState() {
    super.initState();
    if (widget.macro != null) {
      _nameController.text = widget.macro!.name;
      _descriptionController.text = widget.macro!.description;
      _selectedIcon = widget.macro!.iconName;
      _steps = widget.macro!.steps
          .map((s) => _EditableStep(
                toolName: s.toolName,
                args: Map.from(s.args),
                delayAfterMs: s.delayAfterMs,
              ))
          .toList();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Macro' : 'New Macro'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Name field
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Name',
                hintText: 'My Macro',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: const Color(0xFF21262D),
              ),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Name is required' : null,
            ),

            const SizedBox(height: 16),

            // Description field
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
                hintText: 'What this macro does',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: const Color(0xFF21262D),
              ),
              maxLines: 2,
            ),

            const SizedBox(height: 16),

            // Icon picker
            _IconPicker(
              selectedIcon: _selectedIcon,
              onChanged: (icon) => setState(() => _selectedIcon = icon),
            ),

            const SizedBox(height: 24),

            // Steps section
            Row(
              children: [
                const Text(
                  'Steps',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _addStep,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Step'),
                ),
              ],
            ),

            const SizedBox(height: 8),

            if (_steps.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(Icons.touch_app, size: 40, color: Colors.grey[600]),
                      const SizedBox(height: 12),
                      Text(
                        'No steps yet',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Add steps to build your macro',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
              )
            else
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _steps.length,
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) newIndex--;
                    final step = _steps.removeAt(oldIndex);
                    _steps.insert(newIndex, step);
                  });
                },
                itemBuilder: (context, index) => _StepCard(
                  key: ValueKey('step_$index'),
                  index: index,
                  step: _steps[index],
                  onEdit: () => _editStep(index),
                  onDelete: () => setState(() => _steps.removeAt(index)),
                  isLast: index == _steps.length - 1,
                ),
              ),

            const SizedBox(height: 80), // Space for FAB
          ],
        ),
      ),
      floatingActionButton: _steps.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _testRun,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Test Run'),
            )
          : null,
    );
  }

  void _addStep() async {
    final tools = context.read<SystemProvider>().tools;
    if (tools == null || tools.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No tools available. Connect first.')),
      );
      return;
    }

    final step = await showModalBottomSheet<_EditableStep>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _StepEditorSheet(tools: tools),
    );

    if (step != null) {
      setState(() => _steps.add(step));
    }
  }

  void _editStep(int index) async {
    final tools = context.read<SystemProvider>().tools;
    if (tools == null) return;

    final step = await showModalBottomSheet<_EditableStep>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _StepEditorSheet(
        tools: tools,
        existingStep: _steps[index],
      ),
    );

    if (step != null) {
      setState(() => _steps[index] = step);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_steps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one step')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final provider = context.read<MacroProvider>();
      final macroSteps = _steps
          .map((s) => MacroStep(
                toolName: s.toolName!,
                args: s.args,
                delayAfterMs: s.delayAfterMs,
              ))
          .toList();

      if (_isEditing) {
        await provider.updateMacro(widget.macro!.copyWith(
          name: _nameController.text,
          description: _descriptionController.text,
          iconName: _selectedIcon,
          steps: macroSteps,
        ));
      } else {
        await provider.createMacro(
          name: _nameController.text,
          description: _descriptionController.text,
          iconName: _selectedIcon,
          steps: macroSteps,
        );
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'Macro updated' : 'Macro created'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _testRun() async {
    if (_steps.isEmpty) return;

    // Create a temporary macro and run it
    final tempMacro = Macro(
      id: 'temp_test',
      name: _nameController.text.isEmpty ? 'Test' : _nameController.text,
      description: 'Test run',
      steps: _steps
          .map((s) => MacroStep(
                toolName: s.toolName!,
                args: s.args,
                delayAfterMs: s.delayAfterMs,
              ))
          .toList(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      await context.read<MacroProvider>().runMacroInstance(tempMacro);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}

// ============================================================================
// Helper Classes
// ============================================================================

class _EditableStep {
  String? toolName;
  Map<String, dynamic> args;
  int delayAfterMs;

  _EditableStep({
    this.toolName,
    Map<String, dynamic>? args,
    this.delayAfterMs = 0,
  }) : args = args ?? {};
}

// ============================================================================
// Components
// ============================================================================

class _IconPicker extends StatelessWidget {
  final String? selectedIcon;
  final ValueChanged<String?> onChanged;

  const _IconPicker({required this.selectedIcon, required this.onChanged});

  static const _icons = {
    'movie': Icons.movie,
    'work': Icons.work,
    'bedtime': Icons.bedtime,
    'groups': Icons.groups,
    'coffee': Icons.coffee,
    'music_note': Icons.music_note,
    'home': Icons.home,
    'settings': Icons.settings,
    'star': Icons.star,
    'bolt': Icons.bolt,
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Icon',
          style: TextStyle(color: Colors.grey[400], fontSize: 12),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final entry in _icons.entries)
              InkWell(
                onTap: () => onChanged(
                    selectedIcon == entry.key ? null : entry.key),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: selectedIcon == entry.key
                        ? const Color(0xFF64C896).withOpacity(0.2)
                        : const Color(0xFF21262D),
                    borderRadius: BorderRadius.circular(8),
                    border: selectedIcon == entry.key
                        ? Border.all(color: const Color(0xFF64C896))
                        : null,
                  ),
                  child: Icon(
                    entry.value,
                    color: selectedIcon == entry.key
                        ? const Color(0xFF64C896)
                        : Colors.grey,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _StepCard extends StatelessWidget {
  final int index;
  final _EditableStep step;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool isLast;

  const _StepCard({
    super.key,
    required this.index,
    required this.step,
    required this.onEdit,
    required this.onDelete,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF64C896).withOpacity(0.2),
          child: Text(
            '${index + 1}',
            style: const TextStyle(
              color: Color(0xFF64C896),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(step.toolName ?? 'No tool selected'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (step.args.isNotEmpty)
              Text(
                step.args.entries.map((e) => '${e.key}: ${e.value}').join(', '),
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            if (step.delayAfterMs > 0 && !isLast)
              Text(
                'Then wait ${step.delayAfterMs}ms',
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 20, color: Colors.red),
              onPressed: onDelete,
            ),
            const Icon(Icons.drag_handle),
          ],
        ),
      ),
    );
  }
}

class _StepEditorSheet extends StatefulWidget {
  final List<ToolInfo> tools;
  final _EditableStep? existingStep;

  const _StepEditorSheet({required this.tools, this.existingStep});

  @override
  State<_StepEditorSheet> createState() => _StepEditorSheetState();
}

class _StepEditorSheetState extends State<_StepEditorSheet> {
  String? _selectedTool;
  final Map<String, TextEditingController> _argControllers = {};
  final _delayController = TextEditingController(text: '0');
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    if (widget.existingStep != null) {
      _selectedTool = widget.existingStep!.toolName;
      _delayController.text = widget.existingStep!.delayAfterMs.toString();

      // Initialize arg controllers for existing step
      for (final entry in widget.existingStep!.args.entries) {
        _argControllers[entry.key] =
            TextEditingController(text: entry.value.toString());
      }
    }
  }

  @override
  void dispose() {
    for (final c in _argControllers.values) {
      c.dispose();
    }
    _delayController.dispose();
    super.dispose();
  }

  ToolInfo? get _tool =>
      widget.tools.where((t) => t.name == _selectedTool).firstOrNull;

  List<ToolInfo> get _filteredTools {
    if (_searchQuery.isEmpty) return widget.tools;
    final q = _searchQuery.toLowerCase();
    return widget.tools
        .where((t) =>
            t.name.toLowerCase().contains(q) ||
            t.description.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF161B22),
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    _selectedTool == null ? 'Select Tool' : 'Configure Step',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (_selectedTool != null)
                    TextButton(
                      onPressed: _save,
                      child: const Text('Done'),
                    ),
                ],
              ),
            ),

            const Divider(),

            // Content
            Expanded(
              child: _selectedTool == null
                  ? _buildToolSelector(scrollController)
                  : _buildToolConfig(scrollController),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolSelector(ScrollController scrollController) {
    return Column(
      children: [
        // Search
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search tools...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: const Color(0xFF21262D),
            ),
            onChanged: (v) => setState(() => _searchQuery = v),
          ),
        ),

        // Tool list
        Expanded(
          child: ListView.builder(
            controller: scrollController,
            itemCount: _filteredTools.length,
            itemBuilder: (context, index) {
              final tool = _filteredTools[index];
              return ListTile(
                title: Text(tool.name),
                subtitle: Text(
                  tool.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () => setState(() {
                  _selectedTool = tool.name;
                  _argControllers.clear();
                  // Initialize controllers for tool params
                  for (final param in tool.parameters.keys) {
                    _argControllers[param] = TextEditingController();
                  }
                }),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildToolConfig(ScrollController scrollController) {
    final tool = _tool;
    if (tool == null) return const SizedBox();

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      children: [
        // Tool info
        Card(
          child: ListTile(
            leading: const Icon(Icons.build, color: Color(0xFF64C896)),
            title: Text(tool.name),
            subtitle: Text(tool.description),
            trailing: TextButton(
              onPressed: () => setState(() {
                _selectedTool = null;
                _argControllers.clear();
              }),
              child: const Text('Change'),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Parameters
        if (tool.parameters.isNotEmpty) ...[
          const Text(
            'Parameters',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          for (final param in tool.parameters.entries) ...[
            TextFormField(
              controller: _argControllers[param.key],
              decoration: InputDecoration(
                labelText: param.key +
                    (tool.requiredParams.contains(param.key) ? ' *' : ''),
                hintText: param.value['description']?.toString(),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: const Color(0xFF21262D),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ],

        // Delay
        const Text(
          'Delay after (ms)',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _delayController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: '0',
            helperText: 'Wait time before next step',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: const Color(0xFF21262D),
          ),
        ),

        const SizedBox(height: 24),

        FilledButton(
          onPressed: _save,
          child: const Text('Add Step'),
        ),
      ],
    );
  }

  void _save() {
    if (_selectedTool == null) return;

    final args = <String, dynamic>{};
    for (final entry in _argControllers.entries) {
      final value = entry.value.text.trim();
      if (value.isNotEmpty) {
        // Try to parse as number or bool
        if (int.tryParse(value) != null) {
          args[entry.key] = int.parse(value);
        } else if (double.tryParse(value) != null) {
          args[entry.key] = double.parse(value);
        } else if (value.toLowerCase() == 'true') {
          args[entry.key] = true;
        } else if (value.toLowerCase() == 'false') {
          args[entry.key] = false;
        } else {
          args[entry.key] = value;
        }
      }
    }

    Navigator.pop(
      context,
      _EditableStep(
        toolName: _selectedTool,
        args: args,
        delayAfterMs: int.tryParse(_delayController.text) ?? 0,
      ),
    );
  }
}
