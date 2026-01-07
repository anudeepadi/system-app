/// Now Playing Model
///
/// Represents the currently playing track from Spotify or Apple Music.

/// Source of the currently playing media
enum MediaSource {
  spotify,
  music, // Apple Music
  none,
}

/// Current playback state
class NowPlaying {
  final MediaSource source;
  final String? title;
  final String? artist;
  final String? album;
  final Duration position;
  final Duration duration;
  final bool isPlaying;

  const NowPlaying({
    required this.source,
    this.title,
    this.artist,
    this.album,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.isPlaying = false,
  });

  /// No music playing
  static const none = NowPlaying(source: MediaSource.none);

  /// Whether any media is available (playing or paused)
  bool get hasMedia => source != MediaSource.none && title != null;

  /// Progress as percentage (0.0 to 1.0)
  double get progress {
    if (duration.inSeconds == 0) return 0.0;
    return (position.inSeconds / duration.inSeconds).clamp(0.0, 1.0);
  }

  /// Formatted position string (e.g., "1:23")
  String get positionString => _formatDuration(position);

  /// Formatted duration string (e.g., "3:45")
  String get durationString => _formatDuration(duration);

  /// Formatted progress string (e.g., "1:23 / 3:45")
  String get progressString => '$positionString / $durationString';

  /// Source display name
  String get sourceName {
    switch (source) {
      case MediaSource.spotify:
        return 'Spotify';
      case MediaSource.music:
        return 'Apple Music';
      case MediaSource.none:
        return '';
    }
  }

  /// Parse from server response
  /// Format: "source|title|artist|album|positionSec|durationSec|isPlaying"
  factory NowPlaying.parse(String response) {
    try {
      final parts = response.split('|');
      if (parts.length < 7) return NowPlaying.none;

      final sourceStr = parts[0].toLowerCase();
      MediaSource source;
      switch (sourceStr) {
        case 'spotify':
          source = MediaSource.spotify;
          break;
        case 'music':
          source = MediaSource.music;
          break;
        default:
          return NowPlaying.none;
      }

      final title = parts[1].isNotEmpty ? parts[1] : null;
      final artist = parts[2].isNotEmpty ? parts[2] : null;
      final album = parts[3].isNotEmpty ? parts[3] : null;
      final positionSec = int.tryParse(parts[4]) ?? 0;
      final durationSec = int.tryParse(parts[5]) ?? 0;
      final isPlaying = parts[6].toLowerCase() == 'true';

      return NowPlaying(
        source: source,
        title: title,
        artist: artist,
        album: album,
        position: Duration(seconds: positionSec),
        duration: Duration(seconds: durationSec),
        isPlaying: isPlaying,
      );
    } catch (e) {
      return NowPlaying.none;
    }
  }

  /// Format duration as "m:ss" or "h:mm:ss"
  static String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  String toString() {
    if (!hasMedia) return 'NowPlaying(none)';
    return 'NowPlaying($sourceName: $title by $artist, ${isPlaying ? "playing" : "paused"} at $progressString)';
  }
}
