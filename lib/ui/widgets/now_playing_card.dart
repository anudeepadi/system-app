/// Now Playing Card Widget
///
/// Glassmorphic music player card with album art, controls, and progress.

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/system_theme.dart';
import '../../models/now_playing.dart';
import 'glass_container.dart';

/// Mock now playing data (for demo mode)
class NowPlayingData {
  final String title;
  final String artist;
  final String album;
  final Duration duration;
  final Duration position;
  final bool isPlaying;
  final Color albumColor;

  NowPlayingData({
    required this.title,
    required this.artist,
    required this.album,
    required this.duration,
    required this.position,
    this.isPlaying = true,
    Color? albumColor,
  }) : albumColor = albumColor ?? _generateColor(album);

  double get progress => position.inMilliseconds / duration.inMilliseconds;

  String get positionString => _formatDuration(position);
  String get durationString => _formatDuration(duration);

  static String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  static Color _generateColor(String text) {
    if (text.isEmpty) return SystemColors.electricPurple;
    final hash = text.hashCode;
    final hue = (hash % 360).abs().toDouble();
    return HSLColor.fromAHSL(1.0, hue, 0.7, 0.5).toColor();
  }

  /// Mock data for demo
  static NowPlayingData get mock => NowPlayingData(
        title: 'Midnight City',
        artist: 'M83',
        album: 'Hurry Up, We\'re Dreaming',
        duration: const Duration(minutes: 4, seconds: 3),
        position: const Duration(minutes: 1, seconds: 47),
        isPlaying: true,
      );
}

class NowPlayingCard extends StatefulWidget {
  final NowPlayingData? data;
  final NowPlaying? nowPlaying; // Real data from server
  final ThemeProvider? themeProvider;
  final VoidCallback? onPrevious;
  final VoidCallback? onPlayPause;
  final VoidCallback? onNext;

  const NowPlayingCard({
    super.key,
    this.data,
    this.nowPlaying,
    this.themeProvider,
    this.onPrevious,
    this.onPlayPause,
    this.onNext,
  });

  @override
  State<NowPlayingCard> createState() => _NowPlayingCardState();
}

class _NowPlayingCardState extends State<NowPlayingCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    );
    if (widget.data?.isPlaying ?? false) {
      _rotationController.repeat();
    }
  }

  @override
  void didUpdateWidget(NowPlayingCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.data?.isPlaying ?? false) {
      _rotationController.repeat();
    } else {
      _rotationController.stop();
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  NowPlayingData _convertToData() {
    final np = widget.nowPlaying;
    if (np != null && np.hasMedia) {
      return NowPlayingData(
        title: np.title ?? 'Unknown',
        artist: np.artist ?? 'Unknown Artist',
        album: np.album ?? '',
        duration: np.duration,
        position: np.position,
        isPlaying: np.isPlaying,
      );
    }
    return widget.data ?? NowPlayingData.mock;
  }

  @override
  Widget build(BuildContext context) {
    final data = _convertToData();
    final tp = widget.themeProvider;

    return GlassContainer(
      backgroundColor: tp?.colors.glassBackground,
      borderColor: tp?.colors.glassBorder,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          // Album art and info section
          Container(
            padding: SystemSpacing.paddingMd,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  data.albumColor.withOpacity(0.4),
                  data.albumColor.withOpacity(0.1),
                ],
              ),
            ),
            child: Row(
              children: [
                // Rotating album art
                _buildAlbumArt(data),
                const SizedBox(width: 16),
                // Track info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Source badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1DB954),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              LucideIcons.music,
                              size: 10,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'SPOTIFY',
                              style: SystemTextStyles.monoSmall.copyWith(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Title
                      Text(
                        data.title,
                        style: SystemTextStyles.uiLarge.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // Artist - Album
                      Text(
                        '${data.artist} • ${data.album}',
                        style: SystemTextStyles.uiSmall.copyWith(
                          color: SystemColors.textSecondary,
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

          // Progress bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              children: [
                // Custom progress bar
                _buildProgressBar(data),
                const SizedBox(height: 4),
                // Time labels
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      data.positionString,
                      style: SystemTextStyles.monoSmall.copyWith(
                        color: SystemColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      data.durationString,
                      style: SystemTextStyles.monoSmall.copyWith(
                        color: SystemColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Controls
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ControlButton(
                  icon: LucideIcons.skipBack,
                  onTap: widget.onPrevious,
                ),
                const SizedBox(width: 16),
                _PlayPauseButton(
                  isPlaying: data.isPlaying,
                  color: data.albumColor,
                  onTap: widget.onPlayPause,
                ),
                const SizedBox(width: 16),
                _ControlButton(
                  icon: LucideIcons.skipForward,
                  onTap: widget.onNext,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlbumArt(NowPlayingData data) {
    return AnimatedBuilder(
      animation: _rotationController,
      builder: (context, child) {
        return Transform.rotate(
          angle: data.isPlaying ? _rotationController.value * 2 * pi : 0,
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  data.albumColor,
                  data.albumColor.withOpacity(0.5),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: data.albumColor.withOpacity(0.4),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Vinyl grooves
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.black.withOpacity(0.3),
                      width: 8,
                    ),
                  ),
                ),
                // Center hole
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: SystemColors.background,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: data.albumColor.withOpacity(0.5),
                      width: 2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProgressBar(NowPlayingData data) {
    return Container(
      height: 4,
      decoration: BoxDecoration(
        color: SystemColors.surfaceElevated,
        borderRadius: BorderRadius.circular(2),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: data.progress,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                data.albumColor,
                data.albumColor.withOpacity(0.7),
              ],
            ),
            borderRadius: BorderRadius.circular(2),
            boxShadow: [
              BoxShadow(
                color: data.albumColor.withOpacity(0.5),
                blurRadius: 4,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _ControlButton({
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: SystemColors.glassBackground,
          shape: BoxShape.circle,
          border: Border.all(color: SystemColors.glassBorder),
        ),
        child: Icon(
          icon,
          color: SystemColors.textPrimary,
          size: 20,
        ),
      ),
    );
  }
}

class _PlayPauseButton extends StatelessWidget {
  final bool isPlaying;
  final Color color;
  final VoidCallback? onTap;

  const _PlayPauseButton({
    required this.isPlaying,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color,
              color.withOpacity(0.7),
            ],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(
          isPlaying ? LucideIcons.pause : LucideIcons.play,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }
}
