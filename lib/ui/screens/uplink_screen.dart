/// Uplink Screen (Chat Interface)
///
/// Terminal-style chat interface for communicating with the AI agent.
/// Connected to Personal OS API for real AI conversations.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../theme/system_theme.dart';
import '../../services/personal_os_provider.dart';
import '../widgets/glass_container.dart';

class UplinkScreen extends StatefulWidget {
  final double bottomPadding;

  const UplinkScreen({super.key, this.bottomPadding = 100});

  @override
  State<UplinkScreen> createState() => _UplinkScreenState();
}

class _UplinkScreenState extends State<UplinkScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocusNode = FocusNode();

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    final provider = context.read<PersonalOsProvider>();
    if (!provider.isConnected) {
      _showError('Not connected to Personal OS API');
      return;
    }

    _inputController.clear();
    provider.sendChatMessage(text);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: SystemColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final personalOs = context.watch<PersonalOsProvider>();

    // Scroll to bottom when new messages arrive
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (personalOs.chatHistory.isNotEmpty) {
        _scrollToBottom();
      }
    });

    return Container(
      color: themeProvider.colors.background,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(personalOs, themeProvider),

            // Connection banner
            if (!personalOs.isConnected)
              _buildConnectionBanner(themeProvider),

            // Messages
            Expanded(
              child: personalOs.chatHistory.isEmpty
                  ? _buildEmptyState(personalOs.isConnected, themeProvider)
                  : ListView.builder(
                      controller: _scrollController,
                      padding: SystemSpacing.paddingMd,
                      itemCount: personalOs.chatHistory.length + (personalOs.isChatting ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (personalOs.isChatting && index == personalOs.chatHistory.length) {
                          return _buildTypingIndicator(themeProvider);
                        }
                        return _MessageBubble(
                          message: personalOs.chatHistory[index],
                          themeProvider: themeProvider,
                        );
                      },
                    ),
            ),

            // Input area
            _buildInputArea(personalOs, themeProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(PersonalOsProvider provider, ThemeProvider themeProvider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: themeProvider.colors.surface.withOpacity(0.5),
        border: Border(
          bottom: BorderSide(
            color: themeProvider.colors.surfaceElevated,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: SystemColors.electricPurple.withOpacity(0.15),
              borderRadius: SystemRadius.borderSm,
            ),
            child: Icon(
              LucideIcons.bot,
              color: SystemColors.electricPurple,
              size: 18,
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
                      'UPLINK',
                      style: SystemTextStyles.monoSmall.copyWith(
                        color: themeProvider.colors.textPrimary,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      ' // ',
                      style: SystemTextStyles.monoSmall.copyWith(
                        color: themeProvider.colors.textMuted,
                      ),
                    ),
                    Text(
                      provider.isConnected ? 'CONNECTED' : 'OFFLINE',
                      style: SystemTextStyles.monoSmall.copyWith(
                        color: provider.isConnected
                            ? themeProvider.colors.accent
                            : SystemColors.error,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  provider.isConnected
                      ? 'AI Agent Ready • Ask me anything'
                      : 'Start Personal OS API to chat',
                  style: SystemTextStyles.uiSmall.copyWith(
                    color: themeProvider.colors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          if (provider.chatHistory.isNotEmpty)
            IconButton(
              icon: Icon(LucideIcons.trash2, color: themeProvider.colors.textMuted),
              onPressed: () => provider.clearChatHistory(),
            ),
        ],
      ),
    );
  }

  Widget _buildConnectionBanner(ThemeProvider themeProvider) {
    return Container(
      margin: const EdgeInsets.all(16),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Not connected to AI',
                  style: SystemTextStyles.uiSmall.copyWith(
                    color: SystemColors.warning,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Start the Personal OS API server',
                  style: SystemTextStyles.uiSmall.copyWith(
                    color: SystemColors.warning.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => context.read<PersonalOsProvider>().connect(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: SystemColors.warning.withOpacity(0.2),
                borderRadius: SystemRadius.borderSm,
              ),
              child: Text(
                'RETRY',
                style: SystemTextStyles.monoSmall.copyWith(
                  color: SystemColors.warning,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isConnected, ThemeProvider themeProvider) {
    final personalOs = context.watch<PersonalOsProvider>();
    final p0Tasks = personalOs.tasks.where((t) => t.priority == 'P0' && t.status != 'd').toList();

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: SystemColors.electricPurple.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.messageSquare,
                size: 48,
                color: SystemColors.electricPurple.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isConnected ? 'Start a conversation' : 'AI Offline',
              style: SystemTextStyles.uiLarge.copyWith(
                color: themeProvider.colors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isConnected
                  ? 'Ask about your tasks, get recommendations,\nor chat about anything'
                  : 'Connect to Personal OS API to chat with AI',
              style: SystemTextStyles.uiMedium.copyWith(
                color: themeProvider.colors.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
            if (isConnected) ...[
              const SizedBox(height: 24),
              // Show P0 tasks as quick prompts
              if (p0Tasks.isNotEmpty) ...[
                Text(
                  'QUICK ACTIONS',
                  style: SystemTextStyles.monoSmall.copyWith(
                    color: themeProvider.colors.textMuted,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    ...p0Tasks.take(3).map((task) => _buildTaskChip(task, themeProvider)),
                  ],
                ),
                const SizedBox(height: 16),
              ],
              // General suggestions
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  _buildSuggestionChip('What should I work on today?', themeProvider),
                  _buildSuggestionChip('Summarize my priorities', themeProvider),
                  _buildSuggestionChip('What\'s blocking me?', themeProvider),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTaskChip(Task task, ThemeProvider themeProvider) {
    return GestureDetector(
      onTap: () {
        _inputController.text = 'Help me with: ${task.title}';
        _sendMessage();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: SystemColors.error.withOpacity(0.1),
          borderRadius: SystemRadius.borderMd,
          border: Border.all(color: SystemColors.error.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: SystemColors.error,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              task.title.length > 25 ? '${task.title.substring(0, 25)}...' : task.title,
              style: SystemTextStyles.uiSmall.copyWith(
                color: themeProvider.colors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionChip(String text, ThemeProvider themeProvider) {
    return GestureDetector(
      onTap: () {
        _inputController.text = text;
        _sendMessage();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: themeProvider.colors.surfaceElevated,
          borderRadius: SystemRadius.borderMd,
          border: Border.all(color: themeProvider.colors.glassBorder),
        ),
        child: Text(
          text,
          style: SystemTextStyles.uiSmall.copyWith(
            color: themeProvider.colors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator(ThemeProvider themeProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          _buildAvatar(isUser: false, themeProvider: themeProvider),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: themeProvider.colors.surface,
              borderRadius: SystemRadius.borderMd,
              border: Border.all(color: themeProvider.colors.surfaceElevated),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: SystemColors.electricPurple,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Thinking...',
                  style: SystemTextStyles.uiSmall.copyWith(
                    color: themeProvider.colors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea(PersonalOsProvider provider, ThemeProvider themeProvider) {
    final isEnabled = provider.isConnected && !provider.isChatting;

    return Container(
      padding: EdgeInsets.fromLTRB(12, 12, 12, 12 + widget.bottomPadding),
      decoration: BoxDecoration(
        color: themeProvider.colors.surface,
        border: Border(
          top: BorderSide(color: themeProvider.colors.surfaceElevated),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: themeProvider.colors.background,
                borderRadius: SystemRadius.borderMd,
                border: Border.all(
                  color: isEnabled
                      ? themeProvider.colors.surfaceElevated
                      : themeProvider.colors.surfaceElevated.withOpacity(0.5),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    '>',
                    style: SystemTextStyles.monoMedium.copyWith(
                      color: isEnabled
                          ? themeProvider.colors.accent
                          : themeProvider.colors.textMuted,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      focusNode: _inputFocusNode,
                      enabled: isEnabled,
                      style: SystemTextStyles.monoMedium.copyWith(
                        color: themeProvider.colors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: isEnabled
                            ? 'Ask me anything...'
                            : provider.isChatting
                                ? 'Waiting for response...'
                                : 'Connect to chat',
                        hintStyle: SystemTextStyles.monoMedium.copyWith(
                          color: themeProvider.colors.textMuted,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                      textInputAction: TextInputAction.send,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: isEnabled ? _sendMessage : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: isEnabled
                    ? LinearGradient(
                        colors: [
                          themeProvider.colors.accent,
                          themeProvider.colors.accent.withOpacity(0.7),
                        ],
                      )
                    : null,
                color: isEnabled ? null : themeProvider.colors.surfaceElevated,
                borderRadius: SystemRadius.borderMd,
                boxShadow: isEnabled
                    ? [
                        BoxShadow(
                          color: themeProvider.colors.accent.withOpacity(0.3),
                          blurRadius: 8,
                          spreadRadius: 0,
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                LucideIcons.send,
                color: isEnabled
                    ? themeProvider.colors.background
                    : themeProvider.colors.textMuted,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar({required bool isUser, required ThemeProvider themeProvider}) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isUser
            ? themeProvider.colors.accent.withOpacity(0.2)
            : SystemColors.electricPurple.withOpacity(0.2),
        borderRadius: SystemRadius.borderSm,
      ),
      child: Icon(
        isUser ? LucideIcons.user : LucideIcons.bot,
        color: isUser ? themeProvider.colors.accent : SystemColors.electricPurple,
        size: 16,
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final ThemeProvider themeProvider;

  const _MessageBubble({
    required this.message,
    required this.themeProvider,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            _buildAvatar(isUser: false),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: message.isError
                        ? SystemColors.error.withOpacity(0.15)
                        : message.isUser
                            ? themeProvider.colors.accent.withOpacity(0.15)
                            : themeProvider.colors.surface,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(message.isUser ? 12 : 4),
                      topRight: Radius.circular(message.isUser ? 4 : 12),
                      bottomLeft: const Radius.circular(12),
                      bottomRight: const Radius.circular(12),
                    ),
                    border: Border.all(
                      color: message.isError
                          ? SystemColors.error.withOpacity(0.3)
                          : message.isUser
                              ? themeProvider.colors.accent.withOpacity(0.3)
                              : themeProvider.colors.surfaceElevated,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildContent(context),
                      if (message.metadata != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          message.metadata!,
                          style: SystemTextStyles.monoSmall.copyWith(
                            color: themeProvider.colors.textMuted,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTime(message.timestamp),
                  style: SystemTextStyles.monoSmall.copyWith(
                    color: themeProvider.colors.textMuted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 8),
            _buildAvatar(isUser: true),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar({required bool isUser}) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isUser
            ? themeProvider.colors.accent.withOpacity(0.2)
            : SystemColors.electricPurple.withOpacity(0.2),
        borderRadius: SystemRadius.borderSm,
      ),
      child: Icon(
        isUser ? LucideIcons.user : LucideIcons.bot,
        color: isUser ? themeProvider.colors.accent : SystemColors.electricPurple,
        size: 16,
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    // Check if content contains code block
    if (message.content.contains('```')) {
      return _buildContentWithCodeBlock(context);
    }

    return SelectableText(
      message.content,
      style: SystemTextStyles.uiMedium.copyWith(
        color: message.isError
            ? SystemColors.error
            : themeProvider.colors.textPrimary,
        height: 1.4,
      ),
    );
  }

  Widget _buildContentWithCodeBlock(BuildContext context) {
    final parts = message.content.split('```');
    List<Widget> widgets = [];

    for (int i = 0; i < parts.length; i++) {
      if (i % 2 == 0) {
        // Regular text
        if (parts[i].trim().isNotEmpty) {
          widgets.add(SelectableText(
            parts[i].trim(),
            style: SystemTextStyles.uiMedium.copyWith(
              color: themeProvider.colors.textPrimary,
              height: 1.4,
            ),
          ));
        }
      } else {
        // Code block
        String code = parts[i];
        // Remove language identifier (e.g., "bash", "python")
        final lines = code.split('\n');
        if (lines.isNotEmpty && !lines[0].contains(' ')) {
          code = lines.skip(1).join('\n');
        }
        widgets.add(const SizedBox(height: 8));
        widgets.add(_CodeBlock(code: code.trim(), themeProvider: themeProvider));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _CodeBlock extends StatelessWidget {
  final String code;
  final ThemeProvider themeProvider;

  const _CodeBlock({required this.code, required this.themeProvider});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: themeProvider.colors.background,
        borderRadius: SystemRadius.borderSm,
        border: Border.all(color: themeProvider.colors.surfaceElevated),
      ),
      child: Stack(
        children: [
          SelectableText(
            code,
            style: SystemTextStyles.mono.copyWith(
              color: themeProvider.colors.accent,
              fontSize: 12,
              height: 1.5,
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: code));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Copied to clipboard'),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: themeProvider.colors.surface,
                  ),
                );
              },
              child: Icon(
                LucideIcons.copy,
                size: 14,
                color: themeProvider.colors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
