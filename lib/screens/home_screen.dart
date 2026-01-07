/// Home Screen
///
/// Main dashboard after connecting to SYSTEM server.
/// Shows status, quick actions, and navigation to tools/logs.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/system_provider.dart';
import '../services/macro_provider.dart';
import '../models/messages.dart';
import '../widgets/now_playing_widget.dart';
import '../widgets/screenshot_gallery.dart';
import 'tools_screen.dart';
import 'logs_screen.dart';
import 'macros_screen.dart';
import 'file_browser_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Initialize providers when home screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MacroProvider>().init();
      context.read<SystemProvider>().startNowPlayingPolling();
    });
  }

  @override
  void dispose() {
    // Note: Don't stop polling here as provider outlives this widget
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          DashboardTab(),
          MacrosScreen(),
          FileBrowserScreen(),
          ScreenshotsScreen(),
          ToolsScreen(),
          LogsScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.playlist_play_outlined),
            selectedIcon: Icon(Icons.playlist_play),
            label: 'Macros',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_outlined),
            selectedIcon: Icon(Icons.folder),
            label: 'Files',
          ),
          NavigationDestination(
            icon: Icon(Icons.screenshot_outlined),
            selectedIcon: Icon(Icons.screenshot),
            label: 'Screenshots',
          ),
          NavigationDestination(
            icon: Icon(Icons.build_outlined),
            selectedIcon: Icon(Icons.build),
            label: 'Tools',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'Logs',
          ),
        ],
      ),
    );
  }
}

class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SystemProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('SYSTEM'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: provider.refreshStatus,
              ),
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () => _showDisconnectDialog(context, provider),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: provider.refreshStatus,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Status Card
                _StatusCard(status: provider.status),

                const SizedBox(height: 16),

                // Quick Actions
                const _SectionHeader(title: 'Quick Actions'),
                const SizedBox(height: 8),
                _QuickActionsGrid(provider: provider),

                const SizedBox(height: 24),

                // Now Playing
                const _SectionHeader(title: 'Now Playing'),
                const SizedBox(height: 8),
                const NowPlayingWidget(),

                const SizedBox(height: 24),

                // Recent Activity
                if (provider.logs.isNotEmpty) ...[
                  const _SectionHeader(title: 'Recent Activity'),
                  const SizedBox(height: 8),
                  ...provider.logs.take(5).map((log) => _LogTile(log: log)),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDisconnectDialog(BuildContext context, SystemProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disconnect'),
        content: const Text('Are you sure you want to disconnect from SYSTEM?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              provider.disconnect();
              Navigator.pop(context);
            },
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Colors.grey,
            fontWeight: FontWeight.w600,
          ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final SystemStatus? status;

  const _StatusCard({this.status});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF64C896),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Connected',
                  style: TextStyle(
                    color: Color(0xFF64C896),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _StatusItem(
                    icon: Icons.battery_full,
                    label: 'Battery',
                    value: status?.batteryString ?? '...',
                  ),
                ),
                Expanded(
                  child: _StatusItem(
                    icon: Icons.wifi,
                    label: 'WiFi',
                    value: status?.wifiString ?? '...',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatusItem(
                    icon: Icons.storage,
                    label: 'Storage',
                    value: status?.storageString ?? '...',
                  ),
                ),
                Expanded(
                  child: _StatusItem(
                    icon: Icons.apps,
                    label: 'Front App',
                    value: status?.frontApp ?? '...',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatusItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
              Text(
                value,
                style: const TextStyle(fontSize: 13),
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

class _QuickActionsGrid extends StatelessWidget {
  final SystemProvider provider;

  const _QuickActionsGrid({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _QuickActionChip(
          icon: Icons.lock,
          label: 'Lock',
          onTap: () => _execute(context, provider, 'lock_screen'),
        ),
        _QuickActionChip(
          icon: Icons.dark_mode,
          label: 'Dark Mode',
          onTap: () => _execute(context, provider, 'dark_mode_toggle'),
        ),
        _QuickActionChip(
          icon: Icons.do_not_disturb_on,
          label: 'DND',
          onTap: () => _execute(context, provider, 'dnd_toggle'),
        ),
        _QuickActionChip(
          icon: Icons.screenshot,
          label: 'Screenshot',
          onTap: () => _execute(context, provider, 'screenshot'),
        ),
        _QuickActionChip(
          icon: Icons.bedtime,
          label: 'Sleep',
          onTap: () => _execute(context, provider, 'sleep_display'),
        ),
      ],
    );
  }

  Future<void> _execute(
    BuildContext context,
    SystemProvider provider,
    String tool,
  ) async {
    try {
      await provider.callTool(tool);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$tool executed'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

class _QuickActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: onTap,
    );
  }
}

class _LogTile extends StatelessWidget {
  final ExecutionLog log;

  const _LogTile({required this.log});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: Icon(
        log.result.success ? Icons.check_circle : Icons.error,
        color: log.result.success ? Colors.green : Colors.red,
        size: 20,
      ),
      title: Text(log.tool),
      subtitle: Text(
        log.result.text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text(
        '${log.durationMs}ms',
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
    );
  }
}
