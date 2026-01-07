/// Tools Screen
///
/// Browse and execute all available SYSTEM tools organized by category.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/system_provider.dart';
import '../models/messages.dart';

class ToolsScreen extends StatefulWidget {
  const ToolsScreen({super.key});

  @override
  State<ToolsScreen> createState() => _ToolsScreenState();
}

class _ToolsScreenState extends State<ToolsScreen> {
  String _searchQuery = '';
  ToolCategory? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    return Consumer<SystemProvider>(
      builder: (context, provider, _) {
        final toolsByCategory = provider.toolsByCategory;
        final categories = toolsByCategory.keys.toList()
          ..sort((a, b) => a.label.compareTo(b.label));

        // Filter tools
        List<ToolInfo> filteredTools;
        if (_searchQuery.isNotEmpty) {
          filteredTools = provider.tools
              .where((t) =>
                  t.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                  t.description.toLowerCase().contains(_searchQuery.toLowerCase()))
              .toList();
        } else if (_selectedCategory != null) {
          filteredTools = toolsByCategory[_selectedCategory] ?? [];
        } else {
          filteredTools = provider.tools;
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Tools'),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search ${provider.tools.length} tools...',
                    prefixIcon: const Icon(Icons.search),
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: const Color(0xFF21262D),
                  ),
                  onChanged: (value) => setState(() {
                    _searchQuery = value;
                    if (value.isNotEmpty) _selectedCategory = null;
                  }),
                ),
              ),
            ),
          ),
          body: Column(
            children: [
              // Category filter chips
              if (_searchQuery.isEmpty)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('All'),
                        selected: _selectedCategory == null,
                        onSelected: (_) => setState(() => _selectedCategory = null),
                      ),
                      const SizedBox(width: 8),
                      ...categories.map((cat) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text('${cat.label} (${toolsByCategory[cat]?.length ?? 0})'),
                              selected: _selectedCategory == cat,
                              onSelected: (_) => setState(() => _selectedCategory = cat),
                            ),
                          )),
                    ],
                  ),
                ),

              // Tools list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredTools.length,
                  itemBuilder: (context, index) {
                    final tool = filteredTools[index];
                    return _ToolCard(tool: tool);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ToolCard extends StatelessWidget {
  final ToolInfo tool;

  const _ToolCard({required this.tool});

  @override
  Widget build(BuildContext context) {
    final category = ToolCategory.categorize(tool.name);
    final hasRequiredParams = tool.requiredParams.isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _showToolDialog(context, tool),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      tool.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      category.label,
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                tool.description,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (hasRequiredParams) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  children: tool.requiredParams.map((p) => Chip(
                        label: Text(p),
                        labelStyle: const TextStyle(fontSize: 10),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      )).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showToolDialog(BuildContext context, ToolInfo tool) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF161B22),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _ToolExecutionSheet(tool: tool),
    );
  }
}

class _ToolExecutionSheet extends StatefulWidget {
  final ToolInfo tool;

  const _ToolExecutionSheet({required this.tool});

  @override
  State<_ToolExecutionSheet> createState() => _ToolExecutionSheetState();
}

class _ToolExecutionSheetState extends State<_ToolExecutionSheet> {
  final Map<String, TextEditingController> _controllers = {};
  bool _isExecuting = false;
  String? _result;
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    for (final param in widget.tool.parameters.keys) {
      _controllers[param] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _execute() async {
    setState(() {
      _isExecuting = true;
      _result = null;
      _isError = false;
    });

    try {
      final args = <String, dynamic>{};
      for (final entry in _controllers.entries) {
        final value = entry.value.text.trim();
        if (value.isNotEmpty) {
          // Try to parse as number or bool
          if (value == 'true') {
            args[entry.key] = true;
          } else if (value == 'false') {
            args[entry.key] = false;
          } else if (int.tryParse(value) != null) {
            args[entry.key] = int.parse(value);
          } else if (double.tryParse(value) != null) {
            args[entry.key] = double.parse(value);
          } else {
            args[entry.key] = value;
          }
        }
      }

      final result = await context.read<SystemProvider>().callTool(
            widget.tool.name,
            args.isEmpty ? null : args,
          );

      setState(() {
        _result = result.text;
        _isError = false;
      });
    } catch (e) {
      setState(() {
        _result = e.toString();
        _isError = true;
      });
    } finally {
      setState(() => _isExecuting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
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

              // Tool name
              Text(
                widget.tool.name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.tool.description,
                style: const TextStyle(color: Colors.grey),
              ),

              const SizedBox(height: 24),

              // Parameters
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    if (widget.tool.parameters.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'No parameters required',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      )
                    else
                      ...widget.tool.parameters.entries.map((entry) {
                        final paramName = entry.key;
                        final paramSchema = entry.value as Map<String, dynamic>?;
                        final description = paramSchema?['description'] as String? ?? '';
                        final isRequired = widget.tool.requiredParams.contains(paramName);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: TextField(
                            controller: _controllers[paramName],
                            decoration: InputDecoration(
                              labelText: '$paramName${isRequired ? ' *' : ''}',
                              helperText: description,
                              helperMaxLines: 3,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: const Color(0xFF21262D),
                            ),
                          ),
                        );
                      }),

                    // Result
                    if (_result != null) ...[
                      const Divider(),
                      const SizedBox(height: 16),
                      Text(
                        'Result',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: _isError ? Colors.red : const Color(0xFF64C896),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: (_isError ? Colors.red : const Color(0xFF64C896))
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: (_isError ? Colors.red : const Color(0xFF64C896))
                                .withOpacity(0.3),
                          ),
                        ),
                        child: SelectableText(
                          _result!,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            color: _isError ? Colors.red : null,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Execute button
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _isExecuting ? null : _execute,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isExecuting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Execute', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        );
      },
    );
  }
}
