/// File Item Model
///
/// Represents a file or directory in the file browser.

/// A file or directory entry
class FileItem {
  final String name;
  final String path;
  final bool isDirectory;
  final int size;
  final DateTime? modified;

  const FileItem({
    required this.name,
    required this.path,
    required this.isDirectory,
    this.size = 0,
    this.modified,
  });

  /// Parse from server response line
  /// Format: "d|name|size|date" or "f|name|size|date"
  factory FileItem.parse(String line, String parentPath) {
    final parts = line.split('|');
    if (parts.length < 4) {
      return FileItem(
        name: line,
        path: '$parentPath/$line',
        isDirectory: false,
      );
    }

    final isDir = parts[0] == 'd';
    final name = parts[1];
    final size = int.tryParse(parts[2]) ?? 0;
    final dateStr = parts[3];

    DateTime? modified;
    try {
      // Parse "YYYY-MM-DD HH:MM" format
      final dateParts = dateStr.split(' ');
      if (dateParts.length == 2) {
        final ymd = dateParts[0].split('-');
        final hm = dateParts[1].split(':');
        if (ymd.length == 3 && hm.length == 2) {
          modified = DateTime(
            int.parse(ymd[0]),
            int.parse(ymd[1]),
            int.parse(ymd[2]),
            int.parse(hm[0]),
            int.parse(hm[1]),
          );
        }
      }
    } catch (_) {}

    return FileItem(
      name: name,
      path: '$parentPath/$name',
      isDirectory: isDir,
      size: size,
      modified: modified,
    );
  }

  /// Get file extension
  String get extension {
    if (isDirectory) return '';
    final dot = name.lastIndexOf('.');
    if (dot == -1 || dot == name.length - 1) return '';
    return name.substring(dot + 1).toLowerCase();
  }

  /// Get human-readable size string
  String get sizeString {
    if (isDirectory) return '--';
    if (size == 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    var i = 0;
    var s = size.toDouble();
    while (s >= 1024 && i < suffixes.length - 1) {
      s /= 1024;
      i++;
    }
    return '${s.toStringAsFixed(s < 10 ? 1 : 0)} ${suffixes[i]}';
  }

  /// Get formatted date string
  String get dateString {
    if (modified == null) return '--';
    final now = DateTime.now();
    final diff = now.difference(modified!);

    if (diff.inDays == 0) {
      return 'Today ${_pad(modified!.hour)}:${_pad(modified!.minute)}';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${modified!.day}/${modified!.month}/${modified!.year}';
    }
  }

  String _pad(int n) => n.toString().padLeft(2, '0');

  /// Check if this is a previewable text file
  bool get isPreviewable {
    const textExtensions = [
      'txt', 'md', 'json', 'yaml', 'yml', 'xml', 'html', 'css', 'js', 'ts',
      'dart', 'py', 'rb', 'java', 'kt', 'swift', 'go', 'rs', 'c', 'cpp', 'h',
      'sh', 'bash', 'zsh', 'fish', 'log', 'conf', 'ini', 'toml', 'csv', 'sql',
    ];
    return !isDirectory && textExtensions.contains(extension);
  }

  /// Check if this is an image
  bool get isImage {
    const imageExtensions = ['png', 'jpg', 'jpeg', 'gif', 'webp', 'bmp', 'ico'];
    return !isDirectory && imageExtensions.contains(extension);
  }

  @override
  String toString() => 'FileItem($name, ${isDirectory ? "dir" : sizeString})';
}

/// Root directories available for browsing
enum RootDirectory {
  desktop('Desktop', '~/Desktop'),
  downloads('Downloads', '~/Downloads'),
  documents('Documents', '~/Documents');

  final String label;
  final String path;

  const RootDirectory(this.label, this.path);
}
