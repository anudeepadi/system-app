/// Quick Actions Grid Widget
///
/// 2x2 grid of glassmorphic action buttons for common commands.

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/system_theme.dart';
import 'glass_container.dart';

/// Action button data model
class QuickAction {
  final String label;
  final IconData icon;
  final Color color;
  final String command;

  const QuickAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.command,
  });

  static const List<QuickAction> defaults = [
    QuickAction(
      label: 'Sleep Mac',
      icon: LucideIcons.moon,
      color: Color(0xFF64B5F6),
      command: 'sleep_mac',
    ),
    QuickAction(
      label: 'Max Volume',
      icon: LucideIcons.volume2,
      color: Color(0xFF00FF9D),
      command: 'volume_set',
    ),
    QuickAction(
      label: 'Toggle DND',
      icon: LucideIcons.bellOff,
      color: Color(0xFFBB86FC),
      command: 'dnd_toggle',
    ),
    QuickAction(
      label: 'Open Terminal',
      icon: LucideIcons.terminal,
      color: Color(0xFFFFB86C),
      command: 'open_terminal',
    ),
  ];
}

class QuickActionsGrid extends StatelessWidget {
  final List<QuickAction> actions;
  final ThemeProvider? themeProvider;
  final Function(QuickAction)? onActionTap;

  const QuickActionsGrid({
    super.key,
    this.actions = QuickAction.defaults,
    this.themeProvider,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    final tp = themeProvider;

    return GlassContainer(
      backgroundColor: tp?.colors.glassBackground,
      borderColor: tp?.colors.glassBorder,
      padding: SystemSpacing.paddingMd,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                LucideIcons.zap,
                color: tp?.colors.accent ?? SystemColors.neonGreen,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'QUICK ACTIONS',
                style: SystemTextStyles.monoSmall.copyWith(
                  color: tp?.colors.textMuted ?? SystemColors.textMuted,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 2x2 Grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.4,
            children: actions.map((action) {
              return _ActionButton(
                action: action,
                themeProvider: tp,
                onTap: () => onActionTap?.call(action),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatefulWidget {
  final QuickAction action;
  final ThemeProvider? themeProvider;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.action,
    this.themeProvider,
    this.onTap,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _controller.reverse();
    widget.onTap?.call();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final tp = widget.themeProvider;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                color: _isPressed
                    ? widget.action.color.withOpacity(0.2)
                    : tp?.colors.surface ?? SystemColors.surface,
                borderRadius: SystemRadius.borderMd,
                border: Border.all(
                  color: _isPressed
                      ? widget.action.color.withOpacity(0.5)
                      : tp?.colors.surfaceElevated ?? SystemColors.surfaceElevated,
                  width: 1,
                ),
                boxShadow: _isPressed
                    ? [
                        BoxShadow(
                          color: widget.action.color.withOpacity(0.2),
                          blurRadius: 12,
                          spreadRadius: 0,
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: widget.action.color.withOpacity(0.15),
                      borderRadius: SystemRadius.borderSm,
                    ),
                    child: Icon(
                      widget.action.icon,
                      color: widget.action.color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.action.label,
                    style: SystemTextStyles.uiSmall.copyWith(
                      color: tp?.colors.textPrimary ?? SystemColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Extended quick actions row for additional commands
class QuickActionsRow extends StatelessWidget {
  final List<QuickAction> actions;
  final Function(QuickAction)? onActionTap;

  const QuickActionsRow({
    super.key,
    required this.actions,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: actions.map((action) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _CompactActionButton(
              action: action,
              onTap: () => onActionTap?.call(action),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _CompactActionButton extends StatelessWidget {
  final QuickAction action;
  final VoidCallback? onTap;

  const _CompactActionButton({
    required this.action,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: SystemColors.surface,
          borderRadius: SystemRadius.borderSm,
          border: Border.all(color: SystemColors.surfaceElevated),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              action.icon,
              color: action.color,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              action.label,
              style: SystemTextStyles.uiSmall.copyWith(
                color: SystemColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
