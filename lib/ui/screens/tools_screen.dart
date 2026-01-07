/// Tools Screen
///
/// Grid of available Mac control tools organized by category.

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../theme/system_theme.dart';
import '../../services/system_provider.dart';
import '../widgets/glass_container.dart';

/// Tool category model
class ToolCategory {
  final String name;
  final IconData icon;
  final Color color;
  final List<Tool> tools;

  const ToolCategory({
    required this.name,
    required this.icon,
    required this.color,
    required this.tools,
  });
}

/// Individual tool model
class Tool {
  final String name;
  final String description;
  final IconData icon;
  final String command;
  final Map<String, dynamic>? args;

  const Tool({
    required this.name,
    required this.description,
    required this.icon,
    required this.command,
    this.args,
  });
}

/// All available tools organized by category
final List<ToolCategory> toolCategories = [
  ToolCategory(
    name: 'System',
    icon: LucideIcons.monitor,
    color: SystemColors.neonGreen,
    tools: [
      Tool(
        name: 'Lock Screen',
        description: 'Lock your Mac',
        icon: LucideIcons.lock,
        command: 'lock_screen',
      ),
      Tool(
        name: 'Sleep Display',
        description: 'Turn off display',
        icon: LucideIcons.monitorOff,
        command: 'sleep_display',
      ),
      Tool(
        name: 'Sleep Mac',
        description: 'Put Mac to sleep',
        icon: LucideIcons.moon,
        command: 'sleep_mac',
      ),
      Tool(
        name: 'Screenshot',
        description: 'Capture screen',
        icon: LucideIcons.camera,
        command: 'screenshot',
      ),
    ],
  ),
  ToolCategory(
    name: 'Audio',
    icon: LucideIcons.volume2,
    color: SystemColors.electricPurple,
    tools: [
      Tool(
        name: 'Volume Up',
        description: 'Increase volume',
        icon: LucideIcons.volumeX,
        command: 'volume_up',
      ),
      Tool(
        name: 'Volume Down',
        description: 'Decrease volume',
        icon: LucideIcons.volume1,
        command: 'volume_down',
      ),
      Tool(
        name: 'Mute',
        description: 'Toggle mute',
        icon: LucideIcons.volumeX,
        command: 'volume_mute',
      ),
      Tool(
        name: 'Max Volume',
        description: 'Set to 100%',
        icon: LucideIcons.volume2,
        command: 'volume_set',
        args: {'level': 100},
      ),
    ],
  ),
  ToolCategory(
    name: 'Media',
    icon: LucideIcons.music,
    color: const Color(0xFF1DB954),
    tools: [
      Tool(
        name: 'Play/Pause',
        description: 'Toggle playback',
        icon: LucideIcons.playCircle,
        command: 'spotify_player_togglePlayPause',
      ),
      Tool(
        name: 'Next Track',
        description: 'Skip to next',
        icon: LucideIcons.skipForward,
        command: 'spotify_player_next',
      ),
      Tool(
        name: 'Previous',
        description: 'Go back',
        icon: LucideIcons.skipBack,
        command: 'spotify_player_previous',
      ),
      Tool(
        name: 'Now Playing',
        description: 'Get current track',
        icon: LucideIcons.disc,
        command: 'now_playing',
      ),
    ],
  ),
  ToolCategory(
    name: 'Display',
    icon: LucideIcons.sun,
    color: SystemColors.warning,
    tools: [
      Tool(
        name: 'Dark Mode',
        description: 'Toggle dark mode',
        icon: LucideIcons.moon,
        command: 'dark_mode_toggle',
      ),
      Tool(
        name: 'Night Shift',
        description: 'Toggle night shift',
        icon: LucideIcons.sunset,
        command: 'night_shift_toggle',
      ),
      Tool(
        name: 'Brightness Up',
        description: 'Increase brightness',
        icon: LucideIcons.sunDim,
        command: 'brightness_set',
        args: {'level': 100},
      ),
      Tool(
        name: 'Brightness Down',
        description: 'Decrease brightness',
        icon: LucideIcons.sunMedium,
        command: 'brightness_set',
        args: {'level': 50},
      ),
    ],
  ),
  ToolCategory(
    name: 'Focus',
    icon: LucideIcons.bellOff,
    color: SystemColors.info,
    tools: [
      Tool(
        name: 'Do Not Disturb',
        description: 'Toggle DND',
        icon: LucideIcons.bellOff,
        command: 'dnd_toggle',
      ),
      Tool(
        name: 'Focus Mode',
        description: 'Start focus session',
        icon: LucideIcons.focus,
        command: 'pomodoro_start_focus',
      ),
      Tool(
        name: 'Take Break',
        description: 'Start break timer',
        icon: LucideIcons.coffee,
        command: 'pomodoro_start_break',
      ),
    ],
  ),
  ToolCategory(
    name: 'Apps',
    icon: LucideIcons.layoutGrid,
    color: const Color(0xFFFF6B6B),
    tools: [
      Tool(
        name: 'Terminal',
        description: 'Open Terminal',
        icon: LucideIcons.terminal,
        command: 'open_app',
        args: {'name': 'Terminal'},
      ),
      Tool(
        name: 'Finder',
        description: 'Open Finder',
        icon: LucideIcons.folder,
        command: 'open_app',
        args: {'name': 'Finder'},
      ),
      Tool(
        name: 'Safari',
        description: 'Open Safari',
        icon: LucideIcons.compass,
        command: 'open_app',
        args: {'name': 'Safari'},
      ),
      Tool(
        name: 'VS Code',
        description: 'Open VS Code',
        icon: LucideIcons.code2,
        command: 'open_app',
        args: {'name': 'Visual Studio Code'},
      ),
    ],
  ),
  ToolCategory(
    name: 'Connectivity',
    icon: LucideIcons.wifi,
    color: const Color(0xFF00BCD4),
    tools: [
      Tool(
        name: 'WiFi',
        description: 'Toggle WiFi',
        icon: LucideIcons.wifi,
        command: 'wifi_toggle',
      ),
      Tool(
        name: 'Bluetooth',
        description: 'Toggle Bluetooth',
        icon: LucideIcons.bluetooth,
        command: 'bluetooth_toggle',
      ),
      Tool(
        name: 'WiFi Status',
        description: 'Check connection',
        icon: LucideIcons.wifi,
        command: 'wifi_status',
      ),
    ],
  ),
  ToolCategory(
    name: 'Messages',
    icon: LucideIcons.messageCircle,
    color: const Color(0xFF4CAF50),
    tools: [
      Tool(
        name: 'Unread iMessages',
        description: 'Check unread count',
        icon: LucideIcons.messageSquare,
        command: 'imessage_unread',
      ),
      Tool(
        name: 'Unread Mail',
        description: 'Check mail count',
        icon: LucideIcons.mail,
        command: 'mail_unread',
      ),
    ],
  ),
];

class ToolsScreen extends StatefulWidget {
  final double bottomPadding;

  const ToolsScreen({super.key, this.bottomPadding = 100});

  @override
  State<ToolsScreen> createState() => _ToolsScreenState();
}

class _ToolsScreenState extends State<ToolsScreen> {
  String? _lastExecutedTool;
  bool _isExecuting = false;
  String? _lastResult;

  Future<void> _executeTool(Tool tool) async {
    setState(() {
      _isExecuting = true;
      _lastExecutedTool = tool.name;
      _lastResult = null;
    });

    try {
      final provider = context.read<SystemProvider>();
      final result = await provider.callTool(tool.command, tool.args);

      setState(() {
        _lastResult = result.text;
        _isExecuting = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(LucideIcons.checkCircle, color: SystemColors.neonGreen, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${tool.name}: ${result.text}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            backgroundColor: SystemColors.surface,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _lastResult = 'Error: $e';
        _isExecuting = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(LucideIcons.alertCircle, color: SystemColors.error, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text('${tool.name} failed: $e')),
              ],
            ),
            backgroundColor: SystemColors.surface,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Container(
      color: themeProvider.colors.background,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(themeProvider),

            // Tools grid
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.fromLTRB(16, 0, 16, widget.bottomPadding),
                itemCount: toolCategories.length,
                itemBuilder: (context, index) {
                  return _CategorySection(
                    category: toolCategories[index],
                    onToolTap: _executeTool,
                    isExecuting: _isExecuting,
                    executingTool: _lastExecutedTool,
                    themeProvider: themeProvider,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeProvider themeProvider) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: SystemColors.warning.withOpacity(0.15),
              borderRadius: SystemRadius.borderSm,
            ),
            child: Icon(
              LucideIcons.wrench,
              color: SystemColors.warning,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'TOOLS',
                      style: SystemTextStyles.monoLarge.copyWith(
                        color: themeProvider.colors.textPrimary,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    Text(
                      ' // ',
                      style: SystemTextStyles.monoLarge.copyWith(
                        color: themeProvider.colors.textMuted,
                      ),
                    ),
                    Text(
                      'CONTROL',
                      style: SystemTextStyles.monoLarge.copyWith(
                        color: SystemColors.warning,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${toolCategories.length} categories • ${toolCategories.fold<int>(0, (sum, cat) => sum + cat.tools.length)} tools',
                  style: SystemTextStyles.uiSmall.copyWith(
                    color: themeProvider.colors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          if (_isExecuting)
            Container(
              padding: const EdgeInsets.all(8),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(themeProvider.colors.accent),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  final ToolCategory category;
  final Function(Tool) onToolTap;
  final bool isExecuting;
  final String? executingTool;
  final ThemeProvider themeProvider;

  const _CategorySection({
    required this.category,
    required this.onToolTap,
    required this.isExecuting,
    this.executingTool,
    required this.themeProvider,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassContainer(
        backgroundColor: themeProvider.colors.glassBackground,
        borderColor: themeProvider.colors.glassBorder,
        padding: SystemSpacing.paddingMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category header
            Row(
              children: [
                Icon(category.icon, color: category.color, size: 18),
                const SizedBox(width: 8),
                Text(
                  category.name.toUpperCase(),
                  style: SystemTextStyles.monoSmall.copyWith(
                    color: themeProvider.colors.textMuted,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Tools grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 2.2,
              children: category.tools.map((tool) {
                final isThisExecuting = isExecuting && executingTool == tool.name;
                return _ToolButton(
                  tool: tool,
                  color: category.color,
                  isExecuting: isThisExecuting,
                  onTap: () => onToolTap(tool),
                  themeProvider: themeProvider,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolButton extends StatefulWidget {
  final Tool tool;
  final Color color;
  final bool isExecuting;
  final VoidCallback onTap;
  final ThemeProvider themeProvider;

  const _ToolButton({
    required this.tool,
    required this.color,
    required this.isExecuting,
    required this.onTap,
    required this.themeProvider,
  });

  @override
  State<_ToolButton> createState() => _ToolButtonState();
}

class _ToolButtonState extends State<_ToolButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _isPressed
              ? widget.color.withOpacity(0.2)
              : widget.themeProvider.colors.surfaceElevated,
          borderRadius: SystemRadius.borderSm,
          border: Border.all(
            color: _isPressed
                ? widget.color.withOpacity(0.5)
                : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            widget.isExecuting
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(widget.color),
                    ),
                  )
                : Icon(
                    widget.tool.icon,
                    color: widget.color,
                    size: 16,
                  ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.tool.name,
                    style: SystemTextStyles.uiSmall.copyWith(
                      color: widget.themeProvider.colors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    widget.tool.description,
                    style: SystemTextStyles.uiSmall.copyWith(
                      color: widget.themeProvider.colors.textMuted,
                      fontSize: 10,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
