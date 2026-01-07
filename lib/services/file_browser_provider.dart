/// File Browser Provider
///
/// State management for file browser navigation.

import 'package:flutter/foundation.dart';
import '../models/file_item.dart';
import 'system_provider.dart';

class FileBrowserProvider extends ChangeNotifier {
  final SystemProvider _systemProvider;

  // Current state
  List<FileItem> _items = [];
  String _currentPath = '';
  List<String> _pathStack = [];
  bool _isLoading = false;
  String? _error;
  bool _showHidden = false;

  // Preview state
  String? _previewContent;
  FileItem? _previewFile;
  bool _isLoadingPreview = false;

  FileBrowserProvider(this._systemProvider);

  // Getters
  List<FileItem> get items => _items;
  String get currentPath => _currentPath;
  List<String> get breadcrumbs => _pathStack;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get showHidden => _showHidden;
  bool get canGoBack => _pathStack.length > 1;
  String? get previewContent => _previewContent;
  FileItem? get previewFile => _previewFile;
  bool get isLoadingPreview => _isLoadingPreview;

  /// Get current directory name
  String get currentDirName {
    if (_currentPath.isEmpty) return 'Files';
    return _currentPath.split('/').last;
  }

  /// Navigate to a root directory
  Future<void> navigateToRoot(RootDirectory root) async {
    _pathStack = [root.path];
    _currentPath = root.path;
    await _loadDirectory();
  }

  /// Navigate into a directory
  Future<void> navigateInto(FileItem item) async {
    if (!item.isDirectory) return;
    _pathStack.add(item.path);
    _currentPath = item.path;
    await _loadDirectory();
  }

  /// Go back one directory
  Future<void> goBack() async {
    if (_pathStack.length <= 1) return;
    _pathStack.removeLast();
    _currentPath = _pathStack.last;
    await _loadDirectory();
  }

  /// Navigate to a specific breadcrumb index
  Future<void> navigateToBreadcrumb(int index) async {
    if (index < 0 || index >= _pathStack.length) return;
    _pathStack = _pathStack.sublist(0, index + 1);
    _currentPath = _pathStack.last;
    await _loadDirectory();
  }

  /// Toggle hidden files
  Future<void> toggleHidden() async {
    _showHidden = !_showHidden;
    await _loadDirectory();
  }

  /// Refresh current directory
  Future<void> refresh() async {
    await _loadDirectory();
  }

  /// Load current directory contents
  Future<void> _loadDirectory() async {
    if (_currentPath.isEmpty) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _systemProvider.callTool('finder_list', {
        'path': _currentPath,
        'showHidden': _showHidden,
      });

      if (result.text.startsWith('Access denied') || result.text.startsWith('Error')) {
        _error = result.text;
        _items = [];
      } else if (result.text == 'Empty directory') {
        _items = [];
      } else {
        _items = result.text
            .split('\n')
            .where((line) => line.isNotEmpty)
            .map((line) => FileItem.parse(line, _currentPath))
            .toList();

        // Sort: directories first, then by name
        _items.sort((a, b) {
          if (a.isDirectory != b.isDirectory) {
            return a.isDirectory ? -1 : 1;
          }
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });
      }
    } catch (e) {
      _error = e.toString();
      _items = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Preview a text file
  Future<void> loadPreview(FileItem item) async {
    if (!item.isPreviewable) return;

    _previewFile = item;
    _previewContent = null;
    _isLoadingPreview = true;
    notifyListeners();

    try {
      final result = await _systemProvider.callTool('file_preview', {
        'path': item.path,
        'lines': 50,
      });
      _previewContent = result.text;
    } catch (e) {
      _previewContent = 'Error loading preview: $e';
    }

    _isLoadingPreview = false;
    notifyListeners();
  }

  /// Close preview
  void closePreview() {
    _previewFile = null;
    _previewContent = null;
    notifyListeners();
  }

  /// Get file info
  Future<String> getFileInfo(FileItem item) async {
    try {
      final result = await _systemProvider.callTool('file_info', {
        'path': item.path,
      });
      return result.text;
    } catch (e) {
      return 'Error getting file info: $e';
    }
  }

  /// Reveal in Finder
  Future<void> revealInFinder(FileItem item) async {
    await _systemProvider.callTool('finder_reveal', {'path': item.path});
  }

  /// Move to trash
  Future<bool> moveToTrash(FileItem item) async {
    try {
      await _systemProvider.callTool('finder_trash', {'path': item.path});
      await refresh();
      return true;
    } catch (e) {
      _error = 'Failed to trash: $e';
      notifyListeners();
      return false;
    }
  }

  /// Clear state
  void clear() {
    _items = [];
    _currentPath = '';
    _pathStack = [];
    _error = null;
    _previewFile = null;
    _previewContent = null;
    notifyListeners();
  }
}
