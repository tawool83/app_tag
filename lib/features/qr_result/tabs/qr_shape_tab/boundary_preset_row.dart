part of '../qr_background_tab.dart';

// ── Boundary 빌트인 행: [🚫] (효과 없음 = 초기화) ──────────────────────────

class _BoundaryBuiltinRow extends StatelessWidget {
  final bool isSelected;
  final VoidCallback onReset;

  const _BoundaryBuiltinRow({
    required this.isSelected,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: Row(
        children: [
          _ShapeButton(
            isSelected: isSelected,
            dimmed: false,
            onTap: onReset,
            tooltip: 'none',
            child: Icon(Icons.block, size: 22,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey),
          ),
        ],
      ),
    );
  }
}

// ── Boundary 사용자 프리셋 행: [+][user...][...] ────────────────────────────

class _BoundaryUserPresetRow extends StatelessWidget {
  final String? selectedPresetId;
  final List<UserShapePreset> userPresets;
  final VoidCallback onAdd;
  final ValueChanged<UserShapePreset> onUserSelect;
  final ValueChanged<UserShapePreset> onUserLongPress;
  final VoidCallback onShowAll;
  final ValueChanged<Set<String>>? onInlineIdsChanged;

  const _BoundaryUserPresetRow({
    required this.selectedPresetId,
    required this.userPresets,
    required this.onAdd,
    required this.onUserSelect,
    required this.onUserLongPress,
    required this.onShowAll,
    this.onInlineIdsChanged,
  });

  static const _chipSize = 48.0;
  static const _gap = 8.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final totalWidth = constraints.maxWidth;
          final fixedWidth = _chipSize + _gap; // [+] 버튼
          final remaining = totalWidth - fixedWidth;
          final maxSlots = (remaining / (_chipSize + _gap)).floor();
          final needMore = userPresets.length > maxSlots && maxSlots > 0;
          final inlineCount = needMore
              ? (maxSlots - 1).clamp(0, userPresets.length)
              : maxSlots.clamp(0, userPresets.length);
          final inlinePresets = userPresets.sublist(0, inlineCount);

          if (onInlineIdsChanged != null) {
            final ids = inlinePresets.map((p) => p.id).toSet();
            WidgetsBinding.instance.addPostFrameCallback((_) {
              onInlineIdsChanged!(ids);
            });
          }

          return Row(
            children: [
              // [+] 추가 버튼
              Padding(
                padding: const EdgeInsets.only(right: _gap),
                child: GestureDetector(
                  onTap: onAdd,
                  child: Container(
                    width: _chipSize,
                    height: _chipSize,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: const Icon(Icons.add, size: 24, color: Colors.grey),
                  ),
                ),
              ),
              // 인라인 사용자 프리셋
              ...inlinePresets.map((p) => _PresetChip(
                    preset: p,
                    isSelected: p.id == selectedPresetId,
                    onTap: () => onUserSelect(p),
                    onLongPress: () => onUserLongPress(p),
                  )),
              // ··· 더보기 버튼
              if (needMore)
                Padding(
                  padding: const EdgeInsets.only(right: _gap),
                  child: GestureDetector(
                    onTap: onShowAll,
                    child: Container(
                      width: _chipSize,
                      height: _chipSize,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: const Center(
                        child: Text('···',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey)),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

// ── Boundary 격자 모달 (보기 / 삭제 모드) ──────────────────────────────────────

enum _BoundaryGridMode { view, delete }

sealed class _BoundaryGridResult {}
class _BoundaryGridDeleteResult extends _BoundaryGridResult { final Set<String> deletedIds; _BoundaryGridDeleteResult(this.deletedIds); }
class _BoundaryGridEditResult extends _BoundaryGridResult { final UserShapePreset preset; _BoundaryGridEditResult(this.preset); }

class _BoundaryGridModal extends StatefulWidget {
  final List<UserShapePreset> presets;
  final _BoundaryGridMode mode;
  final String? selectedPresetId;
  final ValueChanged<UserShapePreset> onSelect;

  const _BoundaryGridModal({
    required this.presets,
    required this.mode,
    required this.onSelect,
    this.selectedPresetId,
  });

  @override
  State<_BoundaryGridModal> createState() => _BoundaryGridModalState();
}

class _BoundaryGridModalState extends State<_BoundaryGridModal> {
  final _markedForDeletion = <String>{};
  String? _localSelectedId;

  @override
  void initState() {
    super.initState();
    _localSelectedId = widget.selectedPresetId;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final screenHeight = MediaQuery.of(context).size.height;
    final isDelete = widget.mode == _BoundaryGridMode.delete;
    return Container(
      constraints: BoxConstraints(maxHeight: screenHeight * 0.6),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 핸들바
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // 격자
          Flexible(
            child: GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: widget.presets.length,
              itemBuilder: (context, i) {
                final preset = widget.presets[i];
                final isMarked = _markedForDeletion.contains(preset.id);
                final isCurrent =
                    !isDelete && preset.id == _localSelectedId;
                return GestureDetector(
                  onTap: () {
                    if (isDelete) {
                      setState(() {
                        if (isMarked) {
                          _markedForDeletion.remove(preset.id);
                        } else {
                          _markedForDeletion.add(preset.id);
                        }
                      });
                    } else {
                      setState(() => _localSelectedId = preset.id);
                      widget.onSelect(preset);
                    }
                  },
                  onLongPress: isDelete
                      ? null
                      : () => Navigator.pop(context, _BoundaryGridEditResult(preset)),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      color: isMarked
                          ? Colors.red.shade50
                          : isCurrent
                              ? Theme.of(context).colorScheme.primaryContainer
                              : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isMarked
                            ? Colors.red
                            : isCurrent
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey.shade300,
                        width: (isMarked || isCurrent) ? 2 : 1,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: CustomPaint(
                            size: const Size(32, 32),
                            painter: _PresetIconPainter(preset: preset),
                          ),
                        ),
                        if (isMarked)
                          const Center(
                            child: Icon(Icons.delete_outline,
                                color: Colors.red, size: 24),
                          ),
                        if (isCurrent && !isMarked)
                          Positioned(
                            right: 4,
                            bottom: 4,
                            child: Icon(Icons.check_circle,
                                color: Theme.of(context).colorScheme.primary,
                                size: 14),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // 삭제 모드: 버튼
          if (isDelete)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: _markedForDeletion.isNotEmpty
                        ? Colors.red
                        : Colors.grey.shade400,
                  ),
                  onPressed: _markedForDeletion.isNotEmpty
                      ? () => Navigator.pop(context, _BoundaryGridDeleteResult(_markedForDeletion))
                      : null,
                  icon: const Icon(Icons.delete, size: 18),
                  label: Text(l10n.actionDeleteCount(_markedForDeletion.length)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
