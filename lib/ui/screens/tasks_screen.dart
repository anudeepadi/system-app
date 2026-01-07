/// Tasks Screen
///
/// Today's to-do list with priority levels and completion tracking.
/// Connected to Personal OS API for real task data.

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../theme/system_theme.dart';
import '../../services/personal_os_provider.dart';
import '../widgets/glass_container.dart';

/// Priority color helper
Color priorityColor(String priority) {
  switch (priority) {
    case 'P0':
      return SystemColors.error;
    case 'P1':
      return SystemColors.warning;
    case 'P2':
      return SystemColors.info;
    case 'P3':
      return SystemColors.textMuted;
    default:
      return SystemColors.textMuted;
  }
}

/// Priority description helper
String priorityDescription(String priority) {
  switch (priority) {
    case 'P0':
      return 'Do today';
    case 'P1':
      return 'This week';
    case 'P2':
      return 'Scheduled';
    case 'P3':
      return 'Someday';
    default:
      return priority;
  }
}

class TasksScreen extends StatefulWidget {
  final double bottomPadding;

  const TasksScreen({super.key, this.bottomPadding = 100});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  @override
  void initState() {
    super.initState();
    // Refresh tasks when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<PersonalOsProvider>();
      if (provider.isConnected && provider.tasks.isEmpty) {
        provider.fetchTasks();
      }
    });
  }

  Future<void> _toggleTaskStatus(Task task) async {
    final provider = context.read<PersonalOsProvider>();
    // Toggle between 'n' (not started) and 'd' (done)
    final newStatus = task.status == 'd' ? 'n' : 'd';
    await provider.updateTaskStatus(task.filename, newStatus);
  }

  Future<void> _cycleTaskStatus(Task task) async {
    final provider = context.read<PersonalOsProvider>();
    // Cycle: n -> s -> d -> n
    String newStatus;
    switch (task.status) {
      case 'n':
        newStatus = 's';
        break;
      case 's':
        newStatus = 'd';
        break;
      case 'd':
        newStatus = 'n';
        break;
      case 'b':
        newStatus = 's';
        break;
      default:
        newStatus = 'n';
    }
    await provider.updateTaskStatus(task.filename, newStatus);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final personalOs = context.watch<PersonalOsProvider>();

    final tasks = personalOs.tasks;
    final p0Tasks = tasks.where((t) => t.priority == 'P0').toList();
    final p1Tasks = tasks.where((t) => t.priority == 'P1').toList();
    final otherTasks = tasks.where((t) =>
        t.priority == 'P2' || t.priority == 'P3').toList();

    final completedCount = tasks.where((t) => t.status == 'd').length;
    final totalCount = tasks.length;

    return Container(
      color: themeProvider.colors.background,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(completedCount, totalCount, personalOs, themeProvider),

            // Connection status banner
            if (!personalOs.isConnected)
              _buildConnectionBanner(themeProvider),

            // Task List
            Expanded(
              child: personalOs.isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: themeProvider.colors.accent,
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => personalOs.fetchTasks(),
                      color: themeProvider.colors.accent,
                      child: ListView(
                        padding: EdgeInsets.fromLTRB(16, 0, 16, widget.bottomPadding),
                        children: [
                          // Daily Focus Card (if available)
                          if (personalOs.dailyFocus != null) ...[
                            _buildFocusCard(personalOs.dailyFocus!, themeProvider),
                            const SizedBox(height: 16),
                          ],

                          // Progress indicator
                          _buildProgressCard(completedCount, totalCount, personalOs.priorityStats, themeProvider),
                          const SizedBox(height: 16),

                          // P0 Tasks (Do Today)
                          if (p0Tasks.isNotEmpty) ...[
                            _buildSectionHeader('DO TODAY', 'P0', p0Tasks.length, themeProvider),
                            const SizedBox(height: 8),
                            ...p0Tasks.map((task) => _TaskCard(
                                  task: task,
                                  onTap: () => _toggleTaskStatus(task),
                                  onLongPress: () => _cycleTaskStatus(task),
                                  themeProvider: themeProvider,
                                )),
                            const SizedBox(height: 16),
                          ],

                          // P1 Tasks (This Week)
                          if (p1Tasks.isNotEmpty) ...[
                            _buildSectionHeader('THIS WEEK', 'P1', p1Tasks.length, themeProvider),
                            const SizedBox(height: 8),
                            ...p1Tasks.map((task) => _TaskCard(
                                  task: task,
                                  onTap: () => _toggleTaskStatus(task),
                                  onLongPress: () => _cycleTaskStatus(task),
                                  themeProvider: themeProvider,
                                )),
                            const SizedBox(height: 16),
                          ],

                          // Other Tasks
                          if (otherTasks.isNotEmpty) ...[
                            _buildSectionHeader('LATER', 'P2', otherTasks.length, themeProvider),
                            const SizedBox(height: 8),
                            ...otherTasks.map((task) => _TaskCard(
                                  task: task,
                                  onTap: () => _toggleTaskStatus(task),
                                  onLongPress: () => _cycleTaskStatus(task),
                                  themeProvider: themeProvider,
                                )),
                          ],

                          // Empty state
                          if (tasks.isEmpty && !personalOs.isLoading)
                            _buildEmptyState(personalOs.isConnected, themeProvider),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(int completed, int total, PersonalOsProvider provider, ThemeProvider themeProvider) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: themeProvider.colors.accentSecondary.withOpacity(0.15),
              borderRadius: SystemRadius.borderSm,
            ),
            child: Icon(
              LucideIcons.checkSquare,
              color: themeProvider.colors.accentSecondary,
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
                      'TASKS',
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
                      provider.isConnected ? 'LIVE' : 'OFFLINE',
                      style: SystemTextStyles.monoLarge.copyWith(
                        color: provider.isConnected
                            ? themeProvider.colors.accent
                            : SystemColors.error,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  total > 0
                      ? '$completed of $total completed'
                      : provider.isConnected ? 'No tasks found' : 'Connect to load tasks',
                  style: SystemTextStyles.uiSmall.copyWith(
                    color: themeProvider.colors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          if (provider.isLoading)
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: themeProvider.colors.accent,
              ),
            )
          else
            IconButton(
              icon: Icon(LucideIcons.refreshCw, color: themeProvider.colors.textSecondary),
              onPressed: () => provider.refresh(),
            ),
        ],
      ),
    );
  }

  Widget _buildConnectionBanner(ThemeProvider themeProvider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SystemColors.warning.withOpacity(0.15),
        borderRadius: SystemRadius.borderSm,
        border: Border.all(color: SystemColors.warning.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.wifiOff, color: SystemColors.warning, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Not connected to Personal OS API',
              style: SystemTextStyles.uiSmall.copyWith(
                color: SystemColors.warning,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => context.read<PersonalOsProvider>().connect(),
            child: Text(
              'RETRY',
              style: SystemTextStyles.monoSmall.copyWith(
                color: SystemColors.warning,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFocusCard(DailyFocus focus, ThemeProvider themeProvider) {
    return GlassContainer(
      backgroundColor: themeProvider.colors.accent.withOpacity(0.1),
      borderColor: themeProvider.colors.accent.withOpacity(0.3),
      padding: SystemSpacing.paddingMd,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.target, color: themeProvider.colors.accent, size: 18),
              const SizedBox(width: 8),
              Text(
                'DAILY FOCUS',
                style: SystemTextStyles.monoSmall.copyWith(
                  color: themeProvider.colors.accent,
                  letterSpacing: 1.5,
                ),
              ),
              const Spacer(),
              Text(
                focus.date,
                style: SystemTextStyles.monoSmall.copyWith(
                  color: themeProvider.colors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            focus.summary,
            style: SystemTextStyles.uiMedium.copyWith(
              color: themeProvider.colors.textPrimary,
            ),
          ),
          if (focus.topPriorities.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: focus.topPriorities.map((p) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: themeProvider.colors.surfaceElevated,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  p,
                  style: SystemTextStyles.uiSmall.copyWith(
                    color: themeProvider.colors.textSecondary,
                  ),
                ),
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressCard(int completed, int total, PriorityStats? stats, ThemeProvider themeProvider) {
    final progress = total > 0 ? completed / total : 0.0;

    return GlassContainer(
      backgroundColor: themeProvider.colors.glassBackground,
      borderColor: themeProvider.colors.glassBorder,
      padding: SystemSpacing.paddingMd,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progress',
                style: SystemTextStyles.uiMedium.copyWith(
                  color: themeProvider.colors.textSecondary,
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: SystemTextStyles.monoMedium.copyWith(
                  color: themeProvider.colors.accent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: themeProvider.colors.surfaceElevated,
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      themeProvider.colors.accent,
                      themeProvider.colors.accent.withOpacity(0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: themeProvider.colors.accent.withOpacity(0.4),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Priority breakdown
          if (stats != null) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatBadge('P0', stats.p0, SystemColors.error),
                _buildStatBadge('P1', stats.p1, SystemColors.warning),
                _buildStatBadge('P2', stats.p2, SystemColors.info),
                _buildStatBadge('P3', stats.p3, SystemColors.textMuted),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatBadge(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          '$count',
          style: SystemTextStyles.monoMedium.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: SystemTextStyles.monoSmall.copyWith(
            color: color.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, String priority, int count, ThemeProvider themeProvider) {
    final color = priorityColor(priority);
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: SystemTextStyles.monoSmall.copyWith(
            color: themeProvider.colors.textMuted,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '$count',
            style: SystemTextStyles.monoSmall.copyWith(
              color: color,
              fontSize: 10,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(bool isConnected, ThemeProvider themeProvider) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isConnected ? LucideIcons.inbox : LucideIcons.cloudOff,
            size: 48,
            color: themeProvider.colors.textMuted,
          ),
          const SizedBox(height: 16),
          Text(
            isConnected ? 'No tasks found' : 'Not connected',
            style: SystemTextStyles.uiMedium.copyWith(
              color: themeProvider.colors.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isConnected
                ? 'Add tasks in your Personal OS system'
                : 'Start the Personal OS API server',
            style: SystemTextStyles.uiSmall.copyWith(
              color: themeProvider.colors.textMuted,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final ThemeProvider themeProvider;

  const _TaskCard({
    required this.task,
    required this.onTap,
    this.onLongPress,
    required this.themeProvider,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = task.status == 'd';
    final isInProgress = task.status == 's';
    final isBlocked = task.status == 'b';
    final color = priorityColor(task.priority);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isCompleted
                ? themeProvider.colors.surface.withOpacity(0.5)
                : themeProvider.colors.surface,
            borderRadius: SystemRadius.borderMd,
            border: Border.all(
              color: isBlocked
                  ? SystemColors.error.withOpacity(0.5)
                  : isInProgress
                      ? themeProvider.colors.accent.withOpacity(0.5)
                      : isCompleted
                          ? themeProvider.colors.accent.withOpacity(0.3)
                          : themeProvider.colors.surfaceElevated,
            ),
          ),
          child: Row(
            children: [
              // Status indicator
              _buildStatusIndicator(isCompleted, isInProgress, isBlocked, color),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: SystemTextStyles.uiMedium.copyWith(
                        color: isCompleted
                            ? themeProvider.colors.textMuted
                            : themeProvider.colors.textPrimary,
                        decoration:
                            isCompleted ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    if (task.context != null || task.deadline != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (task.context != null) ...[
                            Icon(
                              LucideIcons.folder,
                              size: 12,
                              color: themeProvider.colors.textMuted,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              task.context!,
                              style: SystemTextStyles.uiSmall.copyWith(
                                color: themeProvider.colors.textMuted,
                              ),
                            ),
                          ],
                          if (task.context != null && task.deadline != null)
                            const SizedBox(width: 12),
                          if (task.deadline != null) ...[
                            Icon(
                              LucideIcons.calendar,
                              size: 12,
                              color: themeProvider.colors.textMuted,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              task.deadline!,
                              style: SystemTextStyles.uiSmall.copyWith(
                                color: themeProvider.colors.textMuted,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              // Tags
              if (task.tags.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: themeProvider.colors.accentSecondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    task.tags.first,
                    style: SystemTextStyles.monoSmall.copyWith(
                      color: themeProvider.colors.accentSecondary,
                      fontSize: 10,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(bool isCompleted, bool isInProgress, bool isBlocked, Color priorityCol) {
    if (isCompleted) {
      return Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: themeProvider.colors.accent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          LucideIcons.check,
          color: themeProvider.colors.background,
          size: 14,
        ),
      );
    }

    if (isBlocked) {
      return Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: SystemColors.error.withOpacity(0.2),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: SystemColors.error, width: 2),
        ),
        child: Icon(
          LucideIcons.x,
          color: SystemColors.error,
          size: 14,
        ),
      );
    }

    if (isInProgress) {
      return Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: themeProvider.colors.accent.withOpacity(0.2),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: themeProvider.colors.accent, width: 2),
        ),
        child: Icon(
          LucideIcons.play,
          color: themeProvider.colors.accent,
          size: 12,
        ),
      );
    }

    // Not started
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: priorityCol, width: 2),
      ),
    );
  }
}
