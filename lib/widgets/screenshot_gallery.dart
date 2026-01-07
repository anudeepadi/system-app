/// Screenshot Gallery Widget
///
/// Displays recent screenshots in a grid with preview and share options.

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/screenshot_item.dart';
import '../services/system_provider.dart';

class ScreenshotGallery extends StatefulWidget {
  const ScreenshotGallery({super.key});

  @override
  State<ScreenshotGallery> createState() => _ScreenshotGalleryState();
}

class _ScreenshotGalleryState extends State<ScreenshotGallery> {
  List<ScreenshotItem> _screenshots = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadScreenshots();
  }

  Future<void> _loadScreenshots() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final provider = context.read<SystemProvider>();
      final result = await provider.callTool('screenshot_list', {'limit': 20});

      if (result.text == 'No screenshots found') {
        setState(() {
          _screenshots = [];
          _isLoading = false;
        });
        return;
      }

      final items = result.text
          .split('\n')
          .where((line) => line.isNotEmpty)
          .map((line) => ScreenshotItem.parse(line))
          .toList();

      // Sort by date, newest first
      items.sort((a, b) {
        if (a.date == null && b.date == null) return 0;
        if (a.date == null) return 1;
        if (b.date == null) return -1;
        return b.date!.compareTo(a.date!);
      });

      setState(() {
        _screenshots = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            FilledButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              onPressed: _loadScreenshots,
            ),
          ],
        ),
      );
    }

    if (_screenshots.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.screenshot, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No screenshots found',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Take a screenshot on your Mac\n(Cmd+Shift+3 or Cmd+Shift+4)',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
              onPressed: _loadScreenshots,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadScreenshots,
      child: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.2,
        ),
        itemCount: _screenshots.length,
        itemBuilder: (context, index) {
          return _ScreenshotCard(
            item: _screenshots[index],
            onTap: () => _showScreenshot(context, _screenshots[index]),
          );
        },
      ),
    );
  }

  void _showScreenshot(BuildContext context, ScreenshotItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _ScreenshotViewer(item: item),
      ),
    );
  }
}

class _ScreenshotCard extends StatelessWidget {
  final ScreenshotItem item;
  final VoidCallback onTap;

  const _ScreenshotCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Thumbnail placeholder
            Expanded(
              child: Container(
                color: Colors.grey[800],
                child: const Center(
                  child: Icon(
                    Icons.image,
                    size: 32,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${item.dateString} • ${item.sizeString}',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScreenshotViewer extends StatefulWidget {
  final ScreenshotItem item;

  const _ScreenshotViewer({required this.item});

  @override
  State<_ScreenshotViewer> createState() => _ScreenshotViewerState();
}

class _ScreenshotViewerState extends State<_ScreenshotViewer> {
  Uint8List? _imageData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final provider = context.read<SystemProvider>();
      final result = await provider.callTool('screenshot_get', {
        'path': widget.item.path,
      });

      // The result should contain base64 image data
      // Parse the response to extract image data
      if (result.text.startsWith('Error') || result.text.startsWith('Access denied')) {
        setState(() {
          _error = result.text;
          _isLoading = false;
        });
        return;
      }

      // Try to decode as base64
      try {
        final bytes = base64Decode(result.text);
        setState(() {
          _imageData = bytes;
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _error = 'Failed to decode image';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(widget.item.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.folder_open),
            tooltip: 'Reveal in Finder',
            onPressed: () {
              context.read<SystemProvider>().callTool('finder_reveal', {
                'path': widget.item.path,
              });
            },
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Loading screenshot...',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_imageData != null) {
      return InteractiveViewer(
        minScale: 0.5,
        maxScale: 4.0,
        child: Center(
          child: Image.memory(
            _imageData!,
            fit: BoxFit.contain,
          ),
        ),
      );
    }

    return const Center(
      child: Text(
        'Unable to load image',
        style: TextStyle(color: Colors.grey),
      ),
    );
  }
}

/// Screenshots screen wrapper
class ScreenshotsScreen extends StatelessWidget {
  const ScreenshotsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Screenshots'),
        actions: [
          IconButton(
            icon: const Icon(Icons.camera_alt),
            tooltip: 'Take Screenshot',
            onPressed: () async {
              final provider = context.read<SystemProvider>();
              await provider.callTool('screenshot');
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Screenshot captured'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: const ScreenshotGallery(),
    );
  }
}
