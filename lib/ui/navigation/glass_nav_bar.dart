/// Glass Navigation Bar
///
/// Floating glassmorphic bottom navigation with animated indicators.

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/system_theme.dart';

/// Navigation item data
class NavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;

  const NavItem({
    required this.label,
    required this.icon,
    IconData? activeIcon,
  }) : activeIcon = activeIcon ?? icon;
}

class GlassNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final List<NavItem> items;

  const GlassNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: ClipRRect(
        borderRadius: SystemRadius.borderXl,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 70,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: SystemColors.surface.withOpacity(0.8),
              borderRadius: SystemRadius.borderXl,
              border: Border.all(
                color: SystemColors.glassBorder,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
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

                return _NavBarItem(
                  item: item,
                  isSelected: isSelected,
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

class _NavBarItem extends StatefulWidget {
  final NavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_NavBarItem> createState() => _NavBarItemState();
}

class _NavBarItemState extends State<_NavBarItem>
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: widget.isSelected
                    ? SystemColors.neonGreen.withOpacity(0.15)
                    : Colors.transparent,
                borderRadius: SystemRadius.borderLg,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      widget.isSelected ? widget.item.activeIcon : widget.item.icon,
                      color: widget.isSelected
                          ? SystemColors.neonGreen
                          : SystemColors.textMuted,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 4),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: SystemTextStyles.monoSmall.copyWith(
                      color: widget.isSelected
                          ? SystemColors.neonGreen
                          : SystemColors.textMuted,
                      fontSize: 10,
                      fontWeight:
                          widget.isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    child: Text(widget.item.label),
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

/// Alternative: Pill-style navigation with sliding indicator
class GlassNavBarPill extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final List<NavItem> items;

  const GlassNavBarPill({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(50)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 60,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: SystemColors.surface.withOpacity(0.9),
              borderRadius: const BorderRadius.all(Radius.circular(50)),
              border: Border.all(
                color: SystemColors.glassBorder,
                width: 1,
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final itemWidth = (constraints.maxWidth - 12) / items.length;
                return Stack(
                  children: [
                    // Sliding indicator
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                      left: selectedIndex * itemWidth + 6,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        width: itemWidth - 12,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              SystemColors.neonGreen,
                              SystemColors.neonGreen.withOpacity(0.7),
                            ],
                          ),
                          borderRadius: const BorderRadius.all(Radius.circular(50)),
                          boxShadow: [
                            BoxShadow(
                              color: SystemColors.neonGreen.withOpacity(0.4),
                              blurRadius: 12,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Items
                    Row(
                      children: items.asMap().entries.map((entry) {
                        final index = entry.key;
                        final item = entry.value;
                        final isSelected = index == selectedIndex;

                        return Expanded(
                          child: GestureDetector(
                            onTap: () => onItemSelected(index),
                            behavior: HitTestBehavior.opaque,
                            child: Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    item.icon,
                                    color: isSelected
                                        ? SystemColors.background
                                        : SystemColors.textMuted,
                                    size: 20,
                                  ),
                                  if (isSelected) ...[
                                    const SizedBox(width: 6),
                                    Text(
                                      item.label,
                                      style: SystemTextStyles.monoSmall.copyWith(
                                        color: SystemColors.background,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
