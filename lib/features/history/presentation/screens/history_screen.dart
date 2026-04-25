import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../qr_task/domain/entities/qr_task.dart';
import '../../../qr_task/domain/entities/qr_task_kind.dart';
import '../../../qr_task/domain/usecases/qr_task_edit_router.dart';
import '../../../qr_task/presentation/providers/qr_task_providers.dart';
import '../../../scan_history/domain/entities/scan_history_entry.dart';
import '../../../scan_history/scan_history_provider.dart';
import '../../../scanner/domain/entities/scan_detected_type.dart';
import '../widgets/history_filter_chips.dart';
import '../widgets/history_list_view.dart';
import '../widgets/history_search_bar.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  String _createdQuery = '';
  String? _createdTypeFilter;
  String _scannedQuery = '';
  String? _scannedTypeFilter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.screenHistoryTitle),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l10n.historyTabCreated),
            Tab(text: l10n.historyTabScanned),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _CreatedHistoryTab(
            query: _createdQuery,
            typeFilter: _createdTypeFilter,
            onQueryChanged: (q) => setState(() => _createdQuery = q),
            onTypeChanged: (t) => setState(() => _createdTypeFilter = t),
          ),
          _ScannedHistoryTab(
            query: _scannedQuery,
            typeFilter: _scannedTypeFilter,
            onQueryChanged: (q) => setState(() => _scannedQuery = q),
            onTypeChanged: (t) => setState(() => _scannedTypeFilter = t),
          ),
        ],
      ),
    );
  }
}

// ── 생성이력 탭 ─────────────────────────────────────────────────────────────

class _CreatedHistoryTab extends ConsumerWidget {
  final String query;
  final String? typeFilter;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<String?> onTypeChanged;

  const _CreatedHistoryTab({
    required this.query,
    required this.typeFilter,
    required this.onQueryChanged,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(qrTaskListNotifierProvider);
    final l10n = AppLocalizations.of(context)!;

    // 필터링
    final filtered = tasks.where((t) {
      if (query.isNotEmpty) {
        final q = query.toLowerCase();
        if (!t.meta.appName.toLowerCase().contains(q) &&
            !t.meta.deepLink.toLowerCase().contains(q)) {
          return false;
        }
      }
      if (typeFilter != null && t.meta.tagType != typeFilter) return false;
      return true;
    }).toList();

    // 이용 가능한 타입 추출
    final availableTypes = tasks
        .map((t) => t.meta.tagType)
        .whereType<String>()
        .toSet()
        .toList()
      ..sort();

    return Column(
      children: [
        HistorySearchBar(onChanged: onQueryChanged),
        if (availableTypes.isNotEmpty)
          HistoryFilterChips(
            availableTypes: availableTypes,
            selectedType: typeFilter,
            onSelected: onTypeChanged,
          ),
        const SizedBox(height: 4),
        Expanded(
          child: HistoryListView<QrTask>(
            items: filtered,
            keyExtractor: (t) => t.id,
            titleExtractor: (t) => t.meta.appName,
            subtitleExtractor: (t) {
              final isQr = t.kind == QrTaskKind.qr;
              return '${isQr ? l10n.labelQrCode : l10n.labelNfcTag} · ${_formatDate(t.updatedAt)}';
            },
            iconExtractor: (t) =>
                t.kind == QrTaskKind.qr ? Icons.qr_code_2 : Icons.nfc,
            iconColorExtractor: (t) =>
                t.kind == QrTaskKind.qr ? Colors.blue : Colors.purple,
            isFavoriteExtractor: (t) => t.isFavorite,
            onTap: (t) {
              if (t.kind == QrTaskKind.qr) {
                QrTaskEditRouter.push(context, t);
              }
            },
            onDelete: (t) =>
                ref.read(qrTaskListNotifierProvider.notifier).delete(t.id),
            onToggleFavorite: (t) => ref
                .read(qrTaskListNotifierProvider.notifier)
                .toggleFavorite(t.id),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

// ── 스캔이력 탭 ─────────────────────────────────────────────────────────────

class _ScannedHistoryTab extends ConsumerWidget {
  final String query;
  final String? typeFilter;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<String?> onTypeChanged;

  const _ScannedHistoryTab({
    required this.query,
    required this.typeFilter,
    required this.onQueryChanged,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyState = ref.watch(scanHistoryProvider);
    final items = historyState.list.items;

    // 필터링
    final filtered = items.where((e) {
      if (query.isNotEmpty) {
        final q = query.toLowerCase();
        if (!e.rawValue.toLowerCase().contains(q) &&
            !e.displayTitle.toLowerCase().contains(q)) {
          return false;
        }
      }
      if (typeFilter != null && e.detectedType.name != typeFilter) return false;
      return true;
    }).toList();

    // 이용 가능한 타입 추출
    final availableTypes = items
        .map((e) => e.detectedType.name)
        .toSet()
        .toList()
      ..sort();

    return Column(
      children: [
        HistorySearchBar(onChanged: onQueryChanged),
        if (availableTypes.isNotEmpty)
          HistoryFilterChips(
            availableTypes: availableTypes,
            selectedType: typeFilter,
            onSelected: onTypeChanged,
          ),
        const SizedBox(height: 4),
        Expanded(
          child: HistoryListView<ScanHistoryEntry>(
            items: filtered,
            keyExtractor: (e) => e.id,
            titleExtractor: (e) => e.displayTitle,
            subtitleExtractor: (e) =>
                '${e.detectedType.name.toUpperCase()} · ${_formatDate(e.scannedAt)}',
            iconExtractor: (e) => e.detectedType.icon,
            iconColorExtractor: (e) => _typeColor(e.detectedType),
            isFavoriteExtractor: (e) => e.isFavorite,
            onTap: (e) {
              // 스캔 이력 탭 → "꾸미기" 로 이동
              context.push(e.detectedType.tagRoute, extra: e.parsedMeta);
            },
            onDelete: (e) =>
                ref.read(scanHistoryProvider.notifier).deleteEntry(e.id),
            onToggleFavorite: (e) =>
                ref.read(scanHistoryProvider.notifier).toggleFavorite(e.id),
          ),
        ),
      ],
    );
  }

  Color _typeColor(ScanDetectedType type) => switch (type) {
        ScanDetectedType.url => Colors.blue,
        ScanDetectedType.wifi => Colors.teal,
        ScanDetectedType.contact => Colors.green,
        ScanDetectedType.sms => Colors.pink,
        ScanDetectedType.email => Colors.deepPurple,
        ScanDetectedType.location => Colors.red,
        ScanDetectedType.event => Colors.orange,
        ScanDetectedType.appDeepLink => Colors.indigo,
        ScanDetectedType.text => Colors.grey,
      };

  String _formatDate(DateTime dt) {
    return '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
