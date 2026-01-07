/// File Browser Screen
///
/// Browse Desktop, Downloads, and Documents with preview support.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/file_item.dart';
import '../services/file_browser_provider.dart';

class FileBrowserScreen extends StatelessWidget {
  const FileBrowserScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<FileBrowserProvider>(
      builder: (context, provider, _) {
        // Show root selection if no path
        if (provider.currentPath.isEmpty) {
          return _RootSelection(provider: provider);
        }

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: provider.canGoBack
                  ? provider.goBack
                  : () => provider.clear(),
            ),
            title: Text(provider.currentDirName),
            actions: [
              IconButton(
                icon: Icon(
                  provider.showHidden ? Icons.visibility : Icons.visibility_off,
                ),
                tooltip: provider.showHidden ? 'Hide hidden files' : 'Show hidden files',
                onPressed: provider.toggleHidden,
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: provider.refresh,
              ),
            ],
          ),
          body: Column(
            children: [
              // Breadcrumbs
              _Breadcrumbs(provider: provider),

              // Content
              Expanded(
                child: provider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : provider.error != null
                        ? _ErrorView(error: provider.error!)
                        : provider.items.isEmpty
                            ? const _EmptyView()
                            : _FileList(provider: provider),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RootSelection extends StatelessWidget {
  final FileBrowserProvider provider;

  const _RootSelection({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Files')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Text(
              'Select a folder to browse',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          _RootCard(
            icon: Icons.desktop_mac,
            title: 'Desktop',
            subtitle: 'Files on your desktop',
            color: Colors.blue,
            onTap: () => provider.navigateToRoot(RootDirectory.desktop),
          ),
          const SizedBox(height: 12),
          _RootCard(
            icon: Icons.download,
            title: 'Downloads',
            subtitle: 'Downloaded files',
            color: Colors.green,
            onTap: () => provider.navigateToRoot(RootDirectory.downloads),
          ),
          const SizedBox(height: 12),
          _RootCard(
            icon: Icons.folder,
            title: 'Documents',
            subtitle: 'Your documents',
            color: Colors.orange,
            onTap: () => provider.navigateToRoot(RootDirectory.documents),
          ),
        ],
      ),
    );
  }
}

class _RootCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _RootCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _Breadcrumbs extends StatelessWidget {
  final FileBrowserProvider provider;

  const _Breadcrumbs({required this.provider});

  @override
  Widget build(BuildContext context) {
    final crumbs = provider.breadcrumbs;
    if (crumbs.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 40,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: crumbs.length,
        separatorBuilder: (_, __) => const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Icon(Icons.chevron_right, size: 18, color: Colors.grey),
        ),
        itemBuilder: (context, index) {
          final path = crumbs[index];
          final name = path.split('/').last;
          final isLast = index == crumbs.length - 1;

          return Center(
            child: InkWell(
              onTap: isLast ? null : () => provider.navigateToBreadcrumb(index),
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(
                  name,
                  style: TextStyle(
                    fontWeight: isLast ? FontWeight.bold : FontWeight.normal,
                    color: isLast ? null : Colors.grey,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FileList extends StatelessWidget {
  final FileBrowserProvider provider;

  const _FileList({required this.provider});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: provider.items.length,
      itemBuilder: (context, index) {
        final item = provider.items[index];
        return _FileListTile(
          item: item,
          onTap: () {
            if (item.isDirectory) {
              provider.navigateInto(item);
            } else if (item.isPreviewable) {
              provider.loadPreview(item);
              _showPreviewSheet(context, provider);
            }
          },
          onLongPress: () => _showFileOptions(context, provider, item),
        );
      },
    );
  }

  void _showPreviewSheet(BuildContext context, FileBrowserProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Consumer<FileBrowserProvider>(
            builder: (context, prov, _) {
              return Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                child: Column(
                  children: [
                    // Handle
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    // Header
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.description, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              prov.previewFile?.name ?? 'Preview',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              prov.closePreview();
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    // Content
                    Expanded(
                      child: prov.isLoadingPreview
                          ? const Center(child: CircularProgressIndicator())
                          : SingleChildScrollView(
                              controller: scrollController,
                              padding: const EdgeInsets.all(16),
                              child: SelectableText(
                                prov.previewContent ?? '',
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showFileOptions(
    BuildContext context,
    FileBrowserProvider provider,
    FileItem item,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Get Info'),
              onTap: () async {
                Navigator.pop(context);
                final info = await provider.getFileInfo(item);
                if (context.mounted) {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(item.name),
                      content: Text(info),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.folder_open),
              title: const Text('Reveal in Finder'),
              onTap: () {
                Navigator.pop(context);
                provider.revealInFinder(item);
              },
            ),
            if (!item.isDirectory)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Move to Trash', style: TextStyle(color: Colors.red)),
                onTap: () async {
                  Navigator.pop(context);
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Move to Trash?'),
                      content: Text('Are you sure you want to trash "${item.name}"?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          child: const Text('Trash'),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    provider.moveToTrash(item);
                  }
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _FileListTile extends StatelessWidget {
  final FileItem item;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _FileListTile({
    required this.item,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: _FileIcon(item: item),
      title: Text(
        item.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        item.isDirectory ? 'Folder' : '${item.sizeString} • ${item.dateString}',
        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
      ),
      trailing: item.isDirectory
          ? const Icon(Icons.chevron_right)
          : item.isPreviewable
              ? const Icon(Icons.visibility, size: 18, color: Colors.grey)
              : null,
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }
}

class _FileIcon extends StatelessWidget {
  final FileItem item;

  const _FileIcon({required this.item});

  @override
  Widget build(BuildContext context) {
    if (item.isDirectory) {
      return const Icon(Icons.folder, color: Colors.amber, size: 32);
    }

    IconData icon;
    Color color;

    switch (item.extension) {
      case 'pdf':
        icon = Icons.picture_as_pdf;
        color = Colors.red;
        break;
      case 'doc':
      case 'docx':
        icon = Icons.description;
        color = Colors.blue;
        break;
      case 'xls':
      case 'xlsx':
        icon = Icons.table_chart;
        color = Colors.green;
        break;
      case 'png':
      case 'jpg':
      case 'jpeg':
      case 'gif':
      case 'webp':
        icon = Icons.image;
        color = Colors.purple;
        break;
      case 'mp3':
      case 'wav':
      case 'm4a':
        icon = Icons.audio_file;
        color = Colors.orange;
        break;
      case 'mp4':
      case 'mov':
      case 'avi':
        icon = Icons.video_file;
        color = Colors.pink;
        break;
      case 'zip':
      case 'tar':
      case 'gz':
      case 'rar':
        icon = Icons.folder_zip;
        color = Colors.brown;
        break;
      case 'txt':
      case 'md':
      case 'json':
      case 'yaml':
      case 'yml':
        icon = Icons.article;
        color = Colors.grey;
        break;
      case 'js':
      case 'ts':
      case 'dart':
      case 'py':
      case 'java':
      case 'swift':
      case 'go':
      case 'rs':
        icon = Icons.code;
        color = Colors.teal;
        break;
      default:
        icon = Icons.insert_drive_file;
        color = Colors.grey;
    }

    return Icon(icon, color: color, size: 32);
  }
}

class _ErrorView extends StatelessWidget {
  final String error;

  const _ErrorView({required this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.folder_open, size: 48, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'This folder is empty',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
