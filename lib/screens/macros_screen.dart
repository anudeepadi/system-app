/// Macros Screen
///
/// Displays all macros (presets and user-created) with ability to
/// run, edit, delete, and create new macros.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/macro.dart';
import '../services/macro_provider.dart';
import 'macro_editor_screen.dart';

class MacrosScreen extends StatefulWidget {
  const MacrosScreen({super.key});

  @override
  State<MacrosScreen> createState() => _MacrosScreenState();
}

class _MacrosScreenState extends State<MacrosScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize macros on first load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<MacroProvider>();
      if (provider.macros.isEmpty) {
        provider.init();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Macros'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Create Macro',
            onPressed: () => _openEditor(context),
          ),
        ],
      ),
      body: Consumer<MacroProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.macros.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.playlist_play, size: 64, color: Colors.grey[600]),
                  const SizedBox(height: 16),
                  Text(
                    'No macros yet',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: () => _openEditor(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Create Macro'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: provider.refresh,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Execution status (if running)
                if (provider.executionState != null)
                  _ExecutionStatusCard(
                    state: provider.executionState!,
                    onCancel: provider.cancelExecution,
                    onDismiss: provider.clearExecutionState,
                  ),

                // Preset macros section
                if (provider.presetMacros.isNotEmpty) ...[
                  _SectionHeader(
                    title: 'Quick Actions',
                    subtitle: '${provider.presetMacros.length} presets',
                  ),
                  const SizedBox(height: 8),
                  ...provider.presetMacros.map((m) => _MacroCard(
                        macro: m,
                        onRun: () => _runMacro(context, provider, m),
                        onEdit: null, // Presets can't be edited
                        onDelete: null, // Presets can't be deleted
                        onDuplicate: () => _duplicateMacro(context, provider, m),
                      )),
                  const SizedBox(height: 24),
                ],

                // User macros section
                _SectionHeader(
                  title: 'My Macros',
                  subtitle: '${provider.userMacros.length} custom',
                  trailing: TextButton.icon(
                    onPressed: () => _openEditor(context),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('New'),
                  ),
                ),
                const SizedBox(height: 8),
                if (provider.userMacros.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Icon(Icons.touch_app,
                              size: 40, color: Colors.grey[600]),
                          const SizedBox(height: 12),
                          Text(
                            'Create your first macro',
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Chain multiple actions together',
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...provider.userMacros.map((m) => _MacroCard(
                        macro: m,
                        onRun: () => _runMacro(context, provider, m),
                        onEdit: () => _openEditor(context, macro: m),
                        onDelete: () => _confirmDelete(context, provider, m),
                        onDuplicate: () => _duplicateMacro(context, provider, m),
                      )),
              ],
            ),
          );
        },
      ),
    );
  }

  void _openEditor(BuildContext context, {Macro? macro}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MacroEditorScreen(macro: macro),
      ),
    );
  }

  Future<void> _runMacro(
    BuildContext context,
    MacroProvider provider,
    Macro macro,
  ) async {
    try {
      await provider.runMacroInstance(macro);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _duplicateMacro(
    BuildContext context,
    MacroProvider provider,
    Macro macro,
  ) async {
    try {
      final newMacro = await provider.duplicateMacro(macro.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Created "${newMacro.name}"')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _confirmDelete(
    BuildContext context,
    MacroProvider provider,
    Macro macro,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Macro'),
        content: Text('Delete "${macro.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await provider.deleteMacro(macro.id);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Components
// ============================================================================

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const _SectionHeader({
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _MacroCard extends StatelessWidget {
  final Macro macro;
  final VoidCallback onRun;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onDuplicate;

  const _MacroCard({
    required this.macro,
    required this.onRun,
    this.onEdit,
    this.onDelete,
    this.onDuplicate,
  });

  IconData get _icon {
    switch (macro.iconName) {
      case 'movie':
        return Icons.movie;
      case 'work':
        return Icons.work;
      case 'bedtime':
        return Icons.bedtime;
      case 'groups':
        return Icons.groups;
      case 'coffee':
        return Icons.coffee;
      default:
        return Icons.playlist_play;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onRun,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: macro.isPreset
                      ? const Color(0xFF64C896).withOpacity(0.2)
                      : Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _icon,
                  color:
                      macro.isPreset ? const Color(0xFF64C896) : Colors.blue,
                ),
              ),
              const SizedBox(width: 12),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            macro.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        if (macro.isPreset)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF64C896).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'PRESET',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF64C896),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      macro.description,
                      style: TextStyle(color: Colors.grey[500], fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${macro.steps.length} step${macro.steps.length == 1 ? '' : 's'}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 11),
                    ),
                  ],
                ),
              ),

              // Actions
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 20),
                onSelected: (action) {
                  switch (action) {
                    case 'run':
                      onRun();
                      break;
                    case 'edit':
                      onEdit?.call();
                      break;
                    case 'duplicate':
                      onDuplicate?.call();
                      break;
                    case 'delete':
                      onDelete?.call();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'run',
                    child: ListTile(
                      leading: Icon(Icons.play_arrow),
                      title: Text('Run'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  if (onEdit != null)
                    const PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                        leading: Icon(Icons.edit),
                        title: Text('Edit'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  if (onDuplicate != null)
                    const PopupMenuItem(
                      value: 'duplicate',
                      child: ListTile(
                        leading: Icon(Icons.copy),
                        title: Text('Duplicate'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  if (onDelete != null) ...[
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(Icons.delete, color: Colors.red),
                        title: Text('Delete', style: TextStyle(color: Colors.red)),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExecutionStatusCard extends StatelessWidget {
  final MacroExecutionState state;
  final VoidCallback onCancel;
  final VoidCallback onDismiss;

  const _ExecutionStatusCard({
    required this.state,
    required this.onCancel,
    required this.onDismiss,
  });

  Color get _statusColor {
    switch (state.status) {
      case MacroExecutionStatus.running:
        return Colors.blue;
      case MacroExecutionStatus.completed:
        return const Color(0xFF64C896);
      case MacroExecutionStatus.failed:
        return Colors.orange;
      case MacroExecutionStatus.cancelled:
        return Colors.grey;
      case MacroExecutionStatus.idle:
        return Colors.grey;
    }
  }

  IconData get _statusIcon {
    switch (state.status) {
      case MacroExecutionStatus.running:
        return Icons.play_circle;
      case MacroExecutionStatus.completed:
        return Icons.check_circle;
      case MacroExecutionStatus.failed:
        return Icons.error;
      case MacroExecutionStatus.cancelled:
        return Icons.cancel;
      case MacroExecutionStatus.idle:
        return Icons.circle;
    }
  }

  String get _statusText {
    switch (state.status) {
      case MacroExecutionStatus.running:
        return 'Running step ${state.currentStep + 1} of ${state.totalSteps}';
      case MacroExecutionStatus.completed:
        return 'Completed (${state.successCount}/${state.totalSteps} succeeded)';
      case MacroExecutionStatus.failed:
        return 'Completed with errors (${state.failureCount} failed)';
      case MacroExecutionStatus.cancelled:
        return 'Cancelled';
      case MacroExecutionStatus.idle:
        return 'Idle';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: _statusColor.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_statusIcon, color: _statusColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    state.macroName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _statusColor,
                    ),
                  ),
                ),
                if (state.isRunning)
                  TextButton(
                    onPressed: onCancel,
                    child: const Text('Cancel'),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: onDismiss,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(_statusText, style: TextStyle(color: Colors.grey[400])),
            if (state.isRunning) ...[
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: state.progress,
                backgroundColor: _statusColor.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation(_statusColor),
              ),
            ],
            if (state.results.isNotEmpty && !state.isRunning) ...[
              const SizedBox(height: 12),
              ...state.results.map((r) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Icon(
                          r.success ? Icons.check : Icons.close,
                          size: 14,
                          color: r.success ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            r.toolName,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        Text(
                          '${r.durationMs}ms',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }
}
