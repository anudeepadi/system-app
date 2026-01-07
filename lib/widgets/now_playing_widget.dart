/// Now Playing Widget
///
/// Displays current track info with progress bar and playback controls.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/now_playing.dart';
import '../services/system_provider.dart';

class NowPlayingWidget extends StatelessWidget {
  const NowPlayingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SystemProvider>(
      builder: (context, provider, _) {
        final nowPlaying = provider.nowPlaying;

        if (nowPlaying == null || !nowPlaying.hasMedia) {
          return _buildNoMedia(context, provider);
        }

        return _buildPlayer(context, provider, nowPlaying);
      },
    );
  }

  Widget _buildNoMedia(BuildContext context, SystemProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.music_note, color: Colors.grey),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No music playing',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Open Spotify or Apple Music',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.skip_previous),
                  onPressed: () => provider.callTool('spotify_player_previous'),
                ),
                IconButton.filled(
                  icon: const Icon(Icons.play_arrow),
                  iconSize: 32,
                  onPressed: () => provider.callTool('spotify_player_togglePlayPause'),
                ),
                IconButton(
                  icon: const Icon(Icons.skip_next),
                  onPressed: () => provider.callTool('spotify_player_next'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayer(
    BuildContext context,
    SystemProvider provider,
    NowPlaying nowPlaying,
  ) {
    // Generate a color based on album name for visual variety
    final albumColor = _getAlbumColor(nowPlaying.album ?? nowPlaying.title ?? '');

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Album art area with gradient
          Container(
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  albumColor.withOpacity(0.6),
                  albumColor.withOpacity(0.2),
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Album art placeholder
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: albumColor.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                      ),
                    ),
                    child: Icon(
                      nowPlaying.source == MediaSource.spotify
                          ? Icons.music_note
                          : Icons.album,
                      size: 36,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Track info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Source badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: nowPlaying.source == MediaSource.spotify
                                ? const Color(0xFF1DB954)
                                : const Color(0xFFFC3C44),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            nowPlaying.sourceName,
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Title
                        Text(
                          nowPlaying.title ?? 'Unknown',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        // Artist - Album
                        Text(
                          '${nowPlaying.artist ?? 'Unknown'}${nowPlaying.album != null ? ' • ${nowPlaying.album}' : ''}',
                          style: TextStyle(
                            color: Colors.grey[300],
                            fontSize: 12,
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
          ),

          // Progress bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                // Progress slider
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 6,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 12,
                    ),
                  ),
                  child: Slider(
                    value: nowPlaying.progress,
                    onChanged: (value) {
                      // Seeking not implemented yet
                    },
                    activeColor: albumColor,
                    inactiveColor: albumColor.withOpacity(0.3),
                  ),
                ),
                // Time labels
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        nowPlaying.positionString,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                      ),
                      Text(
                        nowPlaying.durationString,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Playback controls
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.volume_down),
                  onPressed: () => provider.callTool('volume_down'),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.skip_previous),
                  iconSize: 28,
                  onPressed: () => provider.callTool(
                    nowPlaying.source == MediaSource.spotify
                        ? 'spotify_player_previous'
                        : 'music_previous',
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  icon: Icon(
                    nowPlaying.isPlaying ? Icons.pause : Icons.play_arrow,
                  ),
                  iconSize: 36,
                  style: IconButton.styleFrom(
                    backgroundColor: albumColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(12),
                  ),
                  onPressed: () => provider.callTool(
                    nowPlaying.source == MediaSource.spotify
                        ? 'spotify_player_togglePlayPause'
                        : 'music_pause',
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.skip_next),
                  iconSize: 28,
                  onPressed: () => provider.callTool(
                    nowPlaying.source == MediaSource.spotify
                        ? 'spotify_player_next'
                        : 'music_next',
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.volume_up),
                  onPressed: () => provider.callTool('volume_up'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Generate a color based on string (for album art gradient)
  Color _getAlbumColor(String text) {
    if (text.isEmpty) return const Color(0xFF64C896);

    final hash = text.hashCode;
    final hue = (hash % 360).abs().toDouble();
    return HSLColor.fromAHSL(1.0, hue, 0.6, 0.4).toColor();
  }
}
