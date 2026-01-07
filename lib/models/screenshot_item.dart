/// Screenshot Item Model
///
/// Represents a screenshot file with metadata.

class ScreenshotItem {
  final String name;
  final String path;
  final DateTime? date;
  final String sizeString;

  const ScreenshotItem({
    required this.name,
    required this.path,
    this.date,
    this.sizeString = '',
  });

  /// Parse from server response line
  /// Format: "name|date|size|path"
  factory ScreenshotItem.parse(String line) {
    final parts = line.split('|');
    if (parts.length < 4) {
      return ScreenshotItem(name: line, path: line);
    }

    final name = parts[0];
    final dateStr = parts[1];
    final sizeStr = parts[2];
    final path = parts[3];

    DateTime? date;
    try {
      // Parse "YYYY-MM-DD HH:MM" format
      final dateParts = dateStr.split(' ');
      if (dateParts.length == 2) {
        final ymd = dateParts[0].split('-');
        final hm = dateParts[1].split(':');
        if (ymd.length == 3 && hm.length == 2) {
          date = DateTime(
            int.parse(ymd[0]),
            int.parse(ymd[1]),
            int.parse(ymd[2]),
            int.parse(hm[0]),
            int.parse(hm[1]),
          );
        }
      }
    } catch (_) {}

    return ScreenshotItem(
      name: name,
      path: path,
      date: date,
      sizeString: sizeStr,
    );
  }

  /// Get formatted date string
  String get dateString {
    if (date == null) return 'Unknown';
    final now = DateTime.now();
    final diff = now.difference(date!);

    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inDays == 0) {
      return 'Today ${_pad(date!.hour)}:${_pad(date!.minute)}';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${date!.day}/${date!.month}/${date!.year}';
    }
  }

  String _pad(int n) => n.toString().padLeft(2, '0');

  @override
  String toString() => 'ScreenshotItem($name)';
}
