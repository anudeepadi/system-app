/// Monitor Screen (Dashboard)
///
/// Main dashboard with Bento Box layout showing system status,
/// metrics charts, now playing, and quick actions.

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../theme/system_theme.dart';
import '../../services/system_provider.dart';
import '../widgets/glass_container.dart';
import '../widgets/system_load_chart.dart';
import '../widgets/now_playing_card.dart';
import '../widgets/quick_actions_grid.dart';

class MonitorScreen extends StatefulWidget {
  const MonitorScreen({super.key});

  @override
  State<MonitorScreen> createState() => _MonitorScreenState();
}

class _MonitorScreenState extends State<MonitorScreen> {
  bool _pollingStarted = false;

  void _startPollingIfConnected(SystemProvider provider) {
    if (_pollingStarted || !provider.isConnected) return;
    _pollingStarted = true;
    provider.startNowPlayingPolling();
    provider.refreshStatus();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final systemProvider = context.watch<SystemProvider>();

    // Start polling when connected
    if (systemProvider.isConnected && !_pollingStarted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startPollingIfConnected(systemProvider);
      });
    }

    return Container(
      color: themeProvider.colors.background,
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: _buildHeader(themeProvider),
            ),

            // Bento Grid
            SliverPadding(
              padding: SystemSpacing.paddingMd,
              sliver: SliverToBoxAdapter(
                child: Column(
                  children: [
                    // System Status Card
                    _SystemStatusCard(themeProvider: themeProvider),
                    const SizedBox(height: 16),

                    // System Load Chart
                    SystemLoadChart(themeProvider: themeProvider),
                    const SizedBox(height: 16),

                    // Now Playing and Quick Actions - Side by side on larger screens
                    Consumer<SystemProvider>(
                      builder: (context, provider, _) {
                        return LayoutBuilder(
                          builder: (context, constraints) {
                            final quickActions = QuickActions(provider);
                            if (constraints.maxWidth > 600) {
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: NowPlayingCard(
                                      nowPlaying: provider.nowPlaying,
                                      themeProvider: themeProvider,
                                      onPrevious: () => _handleMediaAction(() => quickActions.previousTrack()),
                                      onPlayPause: () => _handleMediaAction(() => quickActions.playPauseMusic()),
                                      onNext: () => _handleMediaAction(() => quickActions.nextTrack()),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: QuickActionsGrid(
                                      themeProvider: themeProvider,
                                      onActionTap: (action) => _handleQuickAction(action, quickActions),
                                    ),
                                  ),
                                ],
                              );
                            }
                            return Column(
                              children: [
                                NowPlayingCard(
                                  nowPlaying: provider.nowPlaying,
                                  themeProvider: themeProvider,
                                  onPrevious: () => _handleMediaAction(() => quickActions.previousTrack()),
                                  onPlayPause: () => _handleMediaAction(() => quickActions.playPauseMusic()),
                                  onNext: () => _handleMediaAction(() => quickActions.nextTrack()),
                                ),
                                const SizedBox(height: 16),
                                QuickActionsGrid(
                                  themeProvider: themeProvider,
                                  onActionTap: (action) => _handleQuickAction(action, quickActions),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // Recent Activity
                    _RecentActivityCard(themeProvider: themeProvider),
                    const SizedBox(height: 80), // Space for nav bar
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleMediaAction(Future<void> Function() action) async {
    final provider = context.read<SystemProvider>();

    if (!provider.isConnected) {
      _showError('Not connected to server');
      return;
    }

    try {
      await action();
      // Refresh now playing after action
      await provider.refreshNowPlaying();
    } catch (e) {
      _showError('Media control failed: ${e.toString()}');
    }
  }

  Future<void> _handleQuickAction(QuickAction action, QuickActions quickActions) async {
    final provider = context.read<SystemProvider>();

    if (!provider.isConnected) {
      _showError('Not connected to server');
      return;
    }

    try {
      // Use the command field which maps directly to tool names
      switch (action.command) {
        case 'screenshot':
          await provider.callTool('screenshot');
          break;
        case 'dark_mode_toggle':
          await quickActions.toggleDarkMode();
          break;
        case 'lock_screen':
          await quickActions.lockScreen();
          break;
        case 'dnd_toggle':
          await provider.callTool('dnd_toggle');
          break;
        case 'sleep_mac':
          await provider.callTool('sleep_mac');
          break;
        case 'volume_set':
          await provider.callTool('volume_set', {'level': 100});
          break;
        case 'open_terminal':
          await provider.callTool('open_app', {'name': 'Terminal'});
          break;
        default:
          // Generic fallback - try calling the command as a tool directly
          await provider.callTool(action.command);
      }
    } catch (e) {
      _showError('Action failed: ${e.toString()}');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: SystemColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildHeader(ThemeProvider themeProvider) {
    final systemProvider = context.watch<SystemProvider>();
    final isConnected = systemProvider.isConnected;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Logo and title
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      themeProvider.colors.accent,
                      themeProvider.colors.accent.withOpacity(0.5),
                    ],
                  ),
                  borderRadius: SystemRadius.borderSm,
                  boxShadow: [
                    BoxShadow(
                      color: themeProvider.colors.accent.withOpacity(0.3),
                      blurRadius: 12,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Icon(
                  LucideIcons.activity,
                  color: themeProvider.colors.background,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'SYSTEM',
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
                        isConnected ? 'ONLINE' : 'OFFLINE',
                        style: SystemTextStyles.monoLarge.copyWith(
                          color: isConnected
                              ? themeProvider.colors.accent
                              : themeProvider.colors.error,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      PulsingDot(
                        size: 6,
                        color: isConnected
                            ? themeProvider.colors.accent
                            : themeProvider.colors.error,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isConnected
                            ? 'All systems operational'
                            : 'Disconnected',
                        style: SystemTextStyles.uiSmall.copyWith(
                          color: themeProvider.colors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),
          // Notification bell
          GestureDetector(
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: themeProvider.colors.surface,
                borderRadius: SystemRadius.borderSm,
                border: Border.all(color: themeProvider.colors.surfaceElevated),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    LucideIcons.bell,
                    color: themeProvider.colors.textSecondary,
                    size: 20,
                  ),
                  Positioned(
                    top: 8,
                    right: 10,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: themeProvider.colors.error,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: themeProvider.colors.surface,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SystemStatusCard extends StatelessWidget {
  final ThemeProvider themeProvider;

  const _SystemStatusCard({required this.themeProvider});

  @override
  Widget build(BuildContext context) {
    final systemProvider = context.watch<SystemProvider>();
    final status = systemProvider.status;
    final isConnected = systemProvider.isConnected;

    return GlassContainer(
      backgroundColor: themeProvider.colors.glassBackground,
      borderColor: themeProvider.colors.glassBorder,
      padding: SystemSpacing.paddingMd,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.server,
                color: themeProvider.colors.accent,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'SYSTEM STATUS',
                style: SystemTextStyles.monoSmall.copyWith(
                  color: themeProvider.colors.textMuted,
                  letterSpacing: 1.5,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (isConnected
                          ? themeProvider.colors.accent
                          : themeProvider.colors.error)
                      .withOpacity(0.15),
                  borderRadius: SystemRadius.borderSm,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PulsingDot(
                      size: 6,
                      color: isConnected
                          ? themeProvider.colors.accent
                          : themeProvider.colors.error,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isConnected ? 'CONNECTED' : 'DISCONNECTED',
                      style: SystemTextStyles.monoSmall.copyWith(
                        color: isConnected
                            ? themeProvider.colors.accent
                            : themeProvider.colors.error,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatusItem(
                  icon: LucideIcons.battery,
                  label: 'Battery',
                  value: status?.batteryString ?? '--',
                  color: themeProvider.colors.accent,
                  themeProvider: themeProvider,
                ),
              ),
              Expanded(
                child: _StatusItem(
                  icon: LucideIcons.wifi,
                  label: 'WiFi',
                  value: status?.wifiString ?? '--',
                  color: SystemColors.info,
                  themeProvider: themeProvider,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatusItem(
                  icon: LucideIcons.hardDrive,
                  label: 'Storage',
                  value: status?.storageString ?? '--',
                  color: SystemColors.warning,
                  themeProvider: themeProvider,
                ),
              ),
              Expanded(
                child: _StatusItem(
                  icon: LucideIcons.appWindow,
                  label: 'Front App',
                  value: status?.frontApp ?? '--',
                  color: themeProvider.colors.accentSecondary,
                  themeProvider: themeProvider,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final ThemeProvider themeProvider;

  const _StatusItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.themeProvider,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: SystemRadius.borderSm,
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: SystemTextStyles.labelSmall.copyWith(
                  fontSize: 10,
                  color: themeProvider.colors.textMuted,
                ),
              ),
              Text(
                value,
                style: SystemTextStyles.uiMedium.copyWith(
                  fontWeight: FontWeight.w500,
                  color: themeProvider.colors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RecentActivityCard extends StatelessWidget {
  final ThemeProvider themeProvider;

  const _RecentActivityCard({required this.themeProvider});

  @override
  Widget build(BuildContext context) {
    final systemProvider = context.watch<SystemProvider>();
    final logs = systemProvider.logs.take(4).toList();

    // Convert execution logs to activities
    final activities = logs.map((log) => _Activity(
          icon: _getIconForTool(log.tool),
          title: log.tool.replaceAll('_', ' '),
          time: _formatTime(log.timestamp),
          success: log.result.success,
        )).toList();

    // If no real logs, show placeholder
    if (activities.isEmpty) {
      activities.addAll([
        const _Activity(
          icon: LucideIcons.activity,
          title: 'Waiting for activity...',
          time: 'now',
          success: true,
        ),
      ]);
    }

    return GlassContainer(
      backgroundColor: themeProvider.colors.glassBackground,
      borderColor: themeProvider.colors.glassBorder,
      padding: SystemSpacing.paddingMd,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.history,
                color: themeProvider.colors.accentSecondary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'RECENT ACTIVITY',
                style: SystemTextStyles.monoSmall.copyWith(
                  color: themeProvider.colors.textMuted,
                  letterSpacing: 1.5,
                ),
              ),
              const Spacer(),
              Text(
                'View All',
                style: SystemTextStyles.uiSmall.copyWith(
                  color: themeProvider.colors.accentSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...activities.map((activity) => _ActivityTile(
                activity: activity,
                themeProvider: themeProvider,
              )),
        ],
      ),
    );
  }

  IconData _getIconForTool(String toolName) {
    if (toolName.contains('volume')) return LucideIcons.volume2;
    if (toolName.contains('music') || toolName.contains('spotify'))
      return LucideIcons.music;
    if (toolName.contains('screenshot')) return LucideIcons.camera;
    if (toolName.contains('dnd') || toolName.contains('focus'))
      return LucideIcons.bellOff;
    if (toolName.contains('shell')) return LucideIcons.terminal;
    if (toolName.contains('battery')) return LucideIcons.battery;
    if (toolName.contains('wifi') || toolName.contains('bluetooth'))
      return LucideIcons.wifi;
    if (toolName.contains('dark_mode') || toolName.contains('brightness'))
      return LucideIcons.sun;
    if (toolName.contains('notify')) return LucideIcons.bell;
    if (toolName.contains('open')) return LucideIcons.externalLink;
    return LucideIcons.activity;
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _Activity {
  final IconData icon;
  final String title;
  final String time;
  final bool success;

  const _Activity({
    required this.icon,
    required this.title,
    required this.time,
    required this.success,
  });
}

class _ActivityTile extends StatelessWidget {
  final _Activity activity;
  final ThemeProvider themeProvider;

  const _ActivityTile({
    required this.activity,
    required this.themeProvider,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: (activity.success
                      ? themeProvider.colors.accent
                      : themeProvider.colors.error)
                  .withOpacity(0.15),
              borderRadius: SystemRadius.borderSm,
            ),
            child: Icon(
              activity.icon,
              size: 14,
              color: activity.success
                  ? themeProvider.colors.accent
                  : themeProvider.colors.error,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              activity.title,
              style: SystemTextStyles.uiMedium.copyWith(
                color: themeProvider.colors.textPrimary,
              ),
            ),
          ),
          Text(
            activity.time,
            style: SystemTextStyles.monoSmall.copyWith(
              color: themeProvider.colors.textMuted,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
