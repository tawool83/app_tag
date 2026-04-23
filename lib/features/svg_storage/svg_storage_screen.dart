import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart' show Share, XFile;
import '../../l10n/app_localizations.dart';

/// 저장된 SVG 파일 목록을 보여주는 화면.
class SvgStorageScreen extends StatefulWidget {
  const SvgStorageScreen({super.key});

  @override
  State<SvgStorageScreen> createState() => _SvgStorageScreenState();
}

class _SvgStorageScreenState extends State<SvgStorageScreen> {
  List<File> _files = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    final dir = await getApplicationDocumentsDirectory();
    final svgDir = Directory('${dir.path}/svg');
    if (!svgDir.existsSync()) {
      setState(() {
        _files = [];
        _loading = false;
      });
      return;
    }
    final files = svgDir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.svg'))
        .toList()
      ..sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
    setState(() {
      _files = files;
      _loading = false;
    });
  }

  Future<void> _shareFile(File file) async {
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'image/svg+xml')],
    );
  }

  Future<void> _deleteFile(File file) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.dialogDeleteTitle),
        content: Text(l10n.svgStorageDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.actionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.actionDelete,
                style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await file.delete();
      _loadFiles();
    }
  }

  String _displayName(File file) {
    final name = file.uri.pathSegments.last;
    // Remove .svg extension for display
    return name.endsWith('.svg') ? name.substring(0, name.length - 4) : name;
  }

  String _fileSize(File file) {
    final bytes = file.lengthSync();
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _fileDate(File file) {
    final modified = file.statSync().modified;
    return '${modified.year}-${modified.month.toString().padLeft(2, '0')}-${modified.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.drawerSvgStorage),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _files.isEmpty
              ? _buildEmptyState(l10n)
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _files.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, i) => _buildFileItem(_files[i], l10n),
                ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.folder_open, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            l10n.svgStorageEmpty,
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildFileItem(File file, AppLocalizations l10n) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.image_outlined,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
      ),
      title: Text(
        _displayName(file),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${_fileSize(file)}  •  ${_fileDate(file)}',
        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.share, size: 20),
            tooltip: l10n.actionShare,
            onPressed: () => _shareFile(file),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
            tooltip: l10n.actionDelete,
            onPressed: () => _deleteFile(file),
          ),
        ],
      ),
    );
  }
}
