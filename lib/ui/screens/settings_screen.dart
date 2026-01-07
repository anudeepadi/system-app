/// Settings Screen
///
/// App configuration, theme toggle, server connection, and integrations.

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../theme/system_theme.dart';
import '../../services/system_provider.dart';
import '../../services/auth_service.dart';
import '../widgets/glass_container.dart';

class SettingsScreen extends StatefulWidget {
  final double bottomPadding;

  const SettingsScreen({super.key, this.bottomPadding = 100});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDark;

    return Container(
      color: themeProvider.colors.background,
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(16, 0, 16, widget.bottomPadding),
          children: [
            // Header
            _buildHeader(themeProvider),
            const SizedBox(height: 16),

            // Appearance Section
            _buildSectionHeader('APPEARANCE', LucideIcons.palette),
            const SizedBox(height: 8),
            _buildAppearanceSection(themeProvider, isDark),
            const SizedBox(height: 24),

            // Connection Section
            _buildSectionHeader('CONNECTION', LucideIcons.plug),
            const SizedBox(height: 8),
            _buildConnectionSection(),
            const SizedBox(height: 24),

            // Integrations Section
            _buildSectionHeader('INTEGRATIONS', LucideIcons.box),
            const SizedBox(height: 8),
            _buildIntegrationsSection(themeProvider),
            const SizedBox(height: 24),

            // About Section
            _buildSectionHeader('ABOUT', LucideIcons.info),
            const SizedBox(height: 8),
            _buildAboutSection(themeProvider),
            const SizedBox(height: 24),

            // Account Section
            _buildSectionHeader('ACCOUNT', LucideIcons.user),
            const SizedBox(height: 8),
            _buildAccountSection(themeProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeProvider themeProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: themeProvider.colors.accentSecondary.withOpacity(0.15),
              borderRadius: SystemRadius.borderSm,
            ),
            child: Icon(
              LucideIcons.settings,
              color: themeProvider.colors.accentSecondary,
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
                    'SETTINGS',
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
                    'CONFIG',
                    style: SystemTextStyles.monoLarge.copyWith(
                      color: themeProvider.colors.accentSecondary,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'Customize your experience',
                style: SystemTextStyles.uiSmall.copyWith(
                  color: themeProvider.colors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    final themeProvider = context.watch<ThemeProvider>();
    return Row(
      children: [
        Icon(icon, color: themeProvider.colors.textMuted, size: 14),
        const SizedBox(width: 8),
        Text(
          title,
          style: SystemTextStyles.monoSmall.copyWith(
            color: themeProvider.colors.textMuted,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildAppearanceSection(ThemeProvider themeProvider, bool isDark) {
    return GlassContainer(
      backgroundColor: themeProvider.colors.glassBackground,
      borderColor: themeProvider.colors.glassBorder,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          // Theme Toggle
          _SettingsTile(
            icon: isDark ? LucideIcons.moon : LucideIcons.sun,
            iconColor: isDark ? SystemColors.electricPurple : SystemColors.warning,
            title: 'Theme',
            subtitle: isDark ? 'Dark Mode' : 'Light Mode',
            trailing: Switch.adaptive(
              value: isDark,
              activeColor: SystemColors.neonGreen,
              onChanged: (value) => themeProvider.toggleTheme(),
            ),
          ),
          Divider(height: 1, color: themeProvider.colors.surfaceElevated),
          // Theme Preview
          _SettingsTile(
            icon: LucideIcons.paintbrush,
            iconColor: themeProvider.colors.accent,
            title: 'Accent Color',
            subtitle: 'Neon Green',
            trailing: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: themeProvider.colors.accent,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: themeProvider.colors.accent.withOpacity(0.4),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionSection() {
    final themeProvider = context.watch<ThemeProvider>();

    return Consumer<SystemProvider>(
      builder: (context, provider, _) {
        return GlassContainer(
          backgroundColor: themeProvider.colors.glassBackground,
          borderColor: themeProvider.colors.glassBorder,
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _SettingsTile(
                icon: LucideIcons.server,
                iconColor: provider.isConnected
                    ? SystemColors.neonGreen
                    : SystemColors.error,
                title: 'Server Status',
                subtitle: provider.isConnected
                    ? 'Connected to ${provider.serverUrl ?? "server"}'
                    : 'Not connected',
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: (provider.isConnected
                            ? SystemColors.neonGreen
                            : SystemColors.error)
                        .withOpacity(0.15),
                    borderRadius: SystemRadius.borderSm,
                  ),
                  child: Text(
                    provider.isConnected ? 'ONLINE' : 'OFFLINE',
                    style: SystemTextStyles.monoSmall.copyWith(
                      color: provider.isConnected
                          ? SystemColors.neonGreen
                          : SystemColors.error,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
              Divider(height: 1, color: themeProvider.colors.surfaceElevated),
              _SettingsTile(
                icon: LucideIcons.refreshCw,
                iconColor: SystemColors.info,
                title: 'Reconnect',
                subtitle: 'Force reconnection to server',
                onTap: () {
                  if (!provider.isConnected) {
                    provider.connect(provider.serverUrl ?? '', provider.token ?? '');
                  }
                },
              ),
              Divider(height: 1, color: themeProvider.colors.surfaceElevated),
              _SettingsTile(
                icon: LucideIcons.logOut,
                iconColor: SystemColors.warning,
                title: 'Disconnect',
                subtitle: 'Disconnect from current server',
                onTap: () => provider.disconnect(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildIntegrationsSection(ThemeProvider themeProvider) {
    return GlassContainer(
      backgroundColor: themeProvider.colors.glassBackground,
      borderColor: themeProvider.colors.glassBorder,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _SettingsTile(
            icon: LucideIcons.brain,
            iconColor: const Color(0xFF9C5EF8),
            title: 'Personal Brain MCP',
            subtitle: 'Semantic search & knowledge graph',
            trailing: _IntegrationBadge(enabled: false),
            onTap: () => _showIntegrationInfo(context, 'Personal Brain MCP'),
          ),
          Divider(height: 1, color: themeProvider.colors.surfaceElevated),
          _SettingsTile(
            icon: LucideIcons.listChecks,
            iconColor: const Color(0xFF4CAF50),
            title: 'PersonalOS',
            subtitle: 'AI-powered task management',
            trailing: _IntegrationBadge(enabled: false),
            onTap: () => _showIntegrationInfo(context, 'PersonalOS'),
          ),
          Divider(height: 1, color: themeProvider.colors.surfaceElevated),
          _SettingsTile(
            icon: LucideIcons.mic,
            iconColor: const Color(0xFF2196F3),
            title: 'Jarvis',
            subtitle: 'Voice-controlled AI assistant',
            trailing: _IntegrationBadge(enabled: false),
            onTap: () => _showIntegrationInfo(context, 'Jarvis'),
          ),
          Divider(height: 1, color: themeProvider.colors.surfaceElevated),
          _SettingsTile(
            icon: LucideIcons.home,
            iconColor: const Color(0xFF03A9F4),
            title: 'Home Assistant',
            subtitle: 'Smart home control',
            trailing: _IntegrationBadge(enabled: false),
            onTap: () => _showIntegrationInfo(context, 'Home Assistant'),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection(ThemeProvider themeProvider) {
    return GlassContainer(
      backgroundColor: themeProvider.colors.glassBackground,
      borderColor: themeProvider.colors.glassBorder,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _SettingsTile(
            icon: LucideIcons.activity,
            iconColor: themeProvider.colors.accent,
            title: 'SYSTEM',
            subtitle: 'Version 1.0.0',
          ),
          Divider(height: 1, color: themeProvider.colors.surfaceElevated),
          _SettingsTile(
            icon: LucideIcons.github,
            iconColor: themeProvider.colors.textSecondary,
            title: 'Source Code',
            subtitle: 'View on GitHub',
            trailing: Icon(
              LucideIcons.externalLink,
              size: 16,
              color: themeProvider.colors.textMuted,
            ),
          ),
          Divider(height: 1, color: themeProvider.colors.surfaceElevated),
          _SettingsTile(
            icon: LucideIcons.fileText,
            iconColor: themeProvider.colors.textSecondary,
            title: 'Documentation',
            subtitle: 'Read the docs',
            trailing: Icon(
              LucideIcons.externalLink,
              size: 16,
              color: themeProvider.colors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSection(ThemeProvider themeProvider) {
    final authProvider = context.watch<AuthProvider>();
    final session = authProvider.session;

    return GlassContainer(
      backgroundColor: themeProvider.colors.glassBackground,
      borderColor: themeProvider.colors.glassBorder,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _SettingsTile(
            icon: LucideIcons.server,
            iconColor: themeProvider.colors.accent,
            title: 'Connected Server',
            subtitle: session?.serverUrl ?? 'Not connected',
          ),
          Divider(height: 1, color: themeProvider.colors.surfaceElevated),
          _SettingsTile(
            icon: LucideIcons.clock,
            iconColor: SystemColors.info,
            title: 'Session Started',
            subtitle: session != null
                ? _formatSessionTime(session.connectedAt)
                : 'N/A',
          ),
          Divider(height: 1, color: themeProvider.colors.surfaceElevated),
          _SettingsTile(
            icon: LucideIcons.logOut,
            iconColor: SystemColors.error,
            title: 'Logout',
            subtitle: 'Disconnect and return to login',
            trailing: Icon(
              LucideIcons.chevronRight,
              size: 18,
              color: themeProvider.colors.textMuted,
            ),
            onTap: () => _showLogoutConfirmation(context),
          ),
        ],
      ),
    );
  }

  String _formatSessionTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    return '${diff.inDays} days ago';
  }

  void _showLogoutConfirmation(BuildContext context) {
    final themeProvider = context.read<ThemeProvider>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: themeProvider.colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: SystemRadius.borderLg,
        ),
        title: Row(
          children: [
            Icon(
              LucideIcons.logOut,
              color: SystemColors.error,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              'Logout',
              style: SystemTextStyles.uiXLarge.copyWith(
                color: themeProvider.colors.textPrimary,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to logout? You will need to enter your credentials again to reconnect.',
          style: SystemTextStyles.uiMedium.copyWith(
            color: themeProvider.colors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: SystemTextStyles.uiMedium.copyWith(
                color: themeProvider.colors.textMuted,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: SystemColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: SystemRadius.borderSm,
              ),
            ),
            onPressed: () async {
              Navigator.pop(context);
              // Disconnect from servers
              final systemProvider = context.read<SystemProvider>();
              systemProvider.disconnect();
              // Logout
              final authProvider = context.read<AuthProvider>();
              await authProvider.logout();
            },
            child: Text(
              'Logout',
              style: SystemTextStyles.uiMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showIntegrationInfo(BuildContext context, String name) {
    final themeProvider = context.read<ThemeProvider>();

    showModalBottomSheet(
      context: context,
      backgroundColor: themeProvider.colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: themeProvider.colors.textMuted,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              name,
              style: SystemTextStyles.uiXLarge.copyWith(
                color: themeProvider.colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This integration is not yet configured. Add it in your SYSTEM server settings to enable this feature.',
              style: SystemTextStyles.uiMedium.copyWith(
                color: themeProvider.colors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeProvider.colors.accent,
                  foregroundColor: themeProvider.colors.background,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: SystemRadius.borderMd,
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Got it',
                  style: SystemTextStyles.uiMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.15),
                borderRadius: SystemRadius.borderSm,
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: SystemTextStyles.uiMedium.copyWith(
                      color: themeProvider.colors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: SystemTextStyles.uiSmall.copyWith(
                      color: themeProvider.colors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

class _IntegrationBadge extends StatelessWidget {
  final bool enabled;

  const _IntegrationBadge({required this.enabled});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (enabled ? SystemColors.neonGreen : SystemColors.textMuted)
            .withOpacity(0.15),
        borderRadius: SystemRadius.borderSm,
      ),
      child: Text(
        enabled ? 'ENABLED' : 'SETUP',
        style: SystemTextStyles.monoSmall.copyWith(
          color: enabled ? SystemColors.neonGreen : SystemColors.textMuted,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }
}
