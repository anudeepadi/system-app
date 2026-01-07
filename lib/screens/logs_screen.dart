/// Logs Screen
///
/// Real-time view of tool execution logs with filtering and details.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/system_provider.dart';
import '../models/messages.dart';
import 'package:intl/intl.dart';

class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key});

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  String? _filterTool;
  bool _filterSuccessOnly = false;
  bool _filterErrorsOnly = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<SystemProvider>(
      builder: (context, provider, _) {
        // Apply filters
        var logs = provider.logs;
        if (_filterTool != null && _filterTool!.isNotEmpty) {
          logs = logs.where((l) => l.tool == _filterTool).toList();
        }
        if (_filterSuccessOnly) {
          logs = logs.where((l) => l.result.success).toList();
        }
        if (_filterErrorsOnly) {
          logs = logs.where((l) => !l.result.success).toList();
        }

        // Get unique tools for filter dropdown
        final toolNames = provider.logs.map((l) => l.tool).toSet().toList()..sort();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Execution Logs'),
            actions: [
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: () => _showFilterSheet(context, toolNames),
              ),
            ],
          ),
          body: logs.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.history, size: 48, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No logs yet',
                        style: TextStyle(color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Execute a tool to see logs here',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    final log = logs[index];
                    return _LogCard(log: log);
                  },
                ),
        );
      },
    );
  }

  void _showFilterSheet(BuildContext context, List<String> toolNames) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161B22),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Filter Logs',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),

                // Tool filter
                DropdownButtonFormField<String?>(
                  value: _filterTool,
                  decoration: InputDecoration(
                    labelText: 'Tool',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: const Color(0xFF21262D),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('All tools'),
                    ),
                    ...toolNames.map((name) => DropdownMenuItem(
                          value: name,
                          child: Text(name),
                        )),
                  ],
                  onChanged: (value) {
                    setSheetState(() => _filterTool = value);
                    setState(() => _filterTool = value);
                  },
                ),

                const SizedBox(height: 16),

                // Success/Error filter
                Row(
                  children: [
                    Expanded(
                      child: FilterChip(
                        label: const Text('Success only'),
                        selected: _filterSuccessOnly,
                        onSelected: (value) {
                          setSheetState(() {
                            _filterSuccessOnly = value;
                            if (value) _filterErrorsOnly = false;
                          });
                          setState(() {
                            _filterSuccessOnly = value;
                            if (value) _filterErrorsOnly = false;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilterChip(
                        label: const Text('Errors only'),
                        selected: _filterErrorsOnly,
                        onSelected: (value) {
                          setSheetState(() {
                            _filterErrorsOnly = value;
                            if (value) _filterSuccessOnly = false;
                          });
                          setState(() {
                            _filterErrorsOnly = value;
                            if (value) _filterSuccessOnly = false;
                          });
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Clear filters
                TextButton(
                  onPressed: () {
                    setSheetState(() {
                      _filterTool = null;
                      _filterSuccessOnly = false;
                      _filterErrorsOnly = false;
                    });
                    setState(() {
                      _filterTool = null;
                      _filterSuccessOnly = false;
                      _filterErrorsOnly = false;
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Clear Filters'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _LogCard extends StatelessWidget {
  final ExecutionLog log;

  const _LogCard({required this.log});

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('HH:mm:ss');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _showDetails(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    log.result.success ? Icons.check_circle : Icons.error,
                    color: log.result.success ? const Color(0xFF64C896) : Colors.red,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      log.tool,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Text(
                    '${log.durationMs}ms',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                log.result.text,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.access_time, size: 12, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    timeFormat.format(log.timestamp),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  if (log.clientType != null) ...[
                    const SizedBox(width: 12),
                    Icon(
                      log.clientType == 'websocket' ? Icons.lan : Icons.api,
                      size: 12,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      log.clientType!,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                  if (log.result.hasImage) ...[
                    const SizedBox(width: 12),
                    Icon(Icons.image, size: 12, color: Colors.grey.shade600),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF161B22),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss.SSS');

          return ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Header
              Row(
                children: [
                  Icon(
                    log.result.success ? Icons.check_circle : Icons.error,
                    color: log.result.success ? const Color(0xFF64C896) : Colors.red,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          log.tool,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          log.result.success ? 'Success' : 'Error',
                          style: TextStyle(
                            color: log.result.success
                                ? const Color(0xFF64C896)
                                : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Details
              _DetailRow('Timestamp', dateFormat.format(log.timestamp)),
              _DetailRow('Duration', '${log.durationMs}ms'),
              if (log.clientType != null) _DetailRow('Client', log.clientType!),
              if (log.clientId != null) _DetailRow('Session', log.clientId!),

              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),

              // Arguments
              const Text(
                'Arguments',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF21262D),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  log.args.isEmpty ? '(none)' : _prettyJson(log.args),
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Result
              const Text(
                'Result',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (log.result.success ? const Color(0xFF64C896) : Colors.red)
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: (log.result.success ? const Color(0xFF64C896) : Colors.red)
                        .withOpacity(0.3),
                  ),
                ),
                child: SelectableText(
                  log.result.text.isEmpty ? '(empty)' : log.result.text,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: log.result.success ? null : Colors.red,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _prettyJson(Map<String, dynamic> json) {
    final buffer = StringBuffer();
    json.forEach((key, value) {
      buffer.writeln('$key: $value');
    });
    return buffer.toString().trim();
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
