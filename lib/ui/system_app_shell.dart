/// SYSTEM App Shell
///
/// Main application shell with navigation between all views.

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../theme/system_theme.dart';
import 'navigation/glass_nav_bar.dart';
import 'screens/monitor_screen.dart';
import 'screens/uplink_screen.dart';
import 'screens/tasks_screen.dart';
import 'screens/tools_screen.dart';
import 'screens/settings_screen.dart';

/// Bottom navigation bar height + margin
const double kNavBarHeight = 86;

class SystemAppShell extends StatefulWidget {
  const SystemAppShell({super.key});

  @override
  State<SystemAppShell> createState() => _SystemAppShellState();
}

class _SystemAppShellState extends State<SystemAppShell> {
  int _selectedIndex = 0;

  final List<NavItem> _navItems = const [
    NavItem(
      label: 'Monitor',
      icon: LucideIcons.layoutDashboard,
      activeIcon: LucideIcons.layoutDashboard,
    ),
    NavItem(
      label: 'Uplink',
      icon: LucideIcons.messageSquare,
      activeIcon: LucideIcons.messageSquare,
    ),
    NavItem(
      label: 'Tasks',
      icon: LucideIcons.checkSquare,
      activeIcon: LucideIcons.checkSquare,
    ),
    NavItem(
      label: 'Tools',
      icon: LucideIcons.wrench,
      activeIcon: LucideIcons.wrench,
    ),
    NavItem(
      label: 'Settings',
      icon: LucideIcons.settings,
      activeIcon: LucideIcons.settings,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      backgroundColor: themeProvider.colors.background,
      body: Stack(
        children: [
          // Main content
          IndexedStack(
            index: _selectedIndex,
            children: [
              const MonitorScreen(),
              const UplinkScreen(bottomPadding: kNavBarHeight),
              const TasksScreen(bottomPadding: kNavBarHeight),
              const ToolsScreen(bottomPadding: kNavBarHeight),
              const SettingsScreen(bottomPadding: kNavBarHeight),
            ],
          ),

          // Floating navigation bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _ThemedNavBar(
              selectedIndex: _selectedIndex,
              items: _navItems,
              onItemSelected: (index) {
                setState(() => _selectedIndex = index);
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Theme-aware navigation bar
class _ThemedNavBar extends StatelessWidget {
  final int selectedIndex;
  final List<NavItem> items;
  final ValueChanged<int> onItemSelected;

  const _ThemedNavBar({
    required this.selectedIndex,
    required this.items,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDark;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: ClipRRect(
        borderRadius: SystemRadius.borderXl,
        child: BackdropFilter(
          filter: isDark
              ? ImageFilter.blur(sigmaX: 20, sigmaY: 20)
              : ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            height: 70,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: isDark
                  ? SystemColors.surfaceDark.withOpacity(0.85)
                  : SystemColors.surfaceLight.withOpacity(0.95),
              borderRadius: SystemRadius.borderXl,
              border: Border.all(
                color: themeProvider.colors.glassBorder,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                  blurRadius: 20,
                  spreadRadius: -5,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final isSelected = index == selectedIndex;

                return _ThemedNavItem(
                  item: item,
                  isSelected: isSelected,
                  isDark: isDark,
                  onTap: () => onItemSelected(index),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class _ThemedNavItem extends StatefulWidget {
  final NavItem item;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _ThemedNavItem({
    required this.item,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_ThemedNavItem> createState() => _ThemedNavItemState();
}

class _ThemedNavItemState extends State<_ThemedNavItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.isDark
        ? SystemColors.neonGreen
        : SystemColors.neonGreenLight;
    final textMuted = widget.isDark
        ? SystemColors.textMutedDark
        : SystemColors.textMutedLight;

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: widget.isSelected
                    ? accent.withOpacity(0.15)
                    : Colors.transparent,
                borderRadius: SystemRadius.borderLg,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.isSelected
                        ? widget.item.activeIcon
                        : widget.item.icon,
                    color: widget.isSelected ? accent : textMuted,
                    size: 24,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.item.label,
                    style: SystemTextStyles.monoSmall.copyWith(
                      color: widget.isSelected ? accent : textMuted,
                      fontSize: 10,
                      fontWeight: widget.isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
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
