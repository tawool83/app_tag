part of '../qr_shape_tab.dart';

// ── 도트 빌트인 행: [■][●] ──────────────────────────────────────────────────

class _DotBuiltinRow extends StatelessWidget {
  final QrDotStyle? selectedBuiltinStyle;
  final ValueChanged<QrDotStyle> onBuiltinSelect;

  const _DotBuiltinRow({
    this.selectedBuiltinStyle,
    required this.onBuiltinSelect,
  });

  static const _builtinPresets = <(String, QrDotStyle)>[
    ('■', QrDotStyle.square),
    ('●', QrDotStyle.circle),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: Row(
        children: _builtinPresets.map((entry) {
          final (label, style) = entry;
          final isSelected = selectedBuiltinStyle == style;
          return _DotChip(
            label: label,
            isSelected: isSelected,
            onTap: () => onBuiltinSelect(style),
          );
        }).toList(),
      ),
    );
  }
}

// ── 도트 사용자 프리셋 행: [+][user...][...] ────────────────────────────────

class _DotUserPresetRow extends StatelessWidget {
  final String? selectedPresetId;
  final List<UserShapePreset> userPresets;
  final VoidCallback onAdd;
  final ValueChanged<UserShapePreset> onUserSelect;
  final ValueChanged<UserShapePreset> onUserLongPress;
  final VoidCallback onShowAll;

  const _DotUserPresetRow({
    required this.selectedPresetId,
    required this.userPresets,
    required this.onAdd,
    required this.onUserSelect,
    required this.onUserLongPress,
    required this.onShowAll,
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
          // 고정: [+] 버튼
          final fixedWidth = _chipSize + _gap;
          final remaining = totalWidth - fixedWidth;
          final maxSlots = (remaining / (_chipSize + _gap)).floor();
          final needMore = userPresets.length > maxSlots && maxSlots > 0;
          final inlineCount = needMore
              ? (maxSlots - 1).clamp(0, userPresets.length)
              : maxSlots.clamp(0, userPresets.length);
          final inlinePresets = userPresets.sublist(0, inlineCount);

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

/// 도트 칩 (빌트인용)
class _DotChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _DotChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.primaryContainer
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 18,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.black87,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── 도트 격자 모달 (보기 / 편집 / 삭제 모드) ────────────────────────────────

enum _DotGridMode { view, delete }

sealed class _DotGridResult {}
class _DotGridDeleteResult extends _DotGridResult { final Set<String> deletedIds; _DotGridDeleteResult(this.deletedIds); }
class _DotGridEditResult extends _DotGridResult { final UserShapePreset preset; _DotGridEditResult(this.preset); }
class _DotGridSelectResult extends _DotGridResult { final UserShapePreset preset; _DotGridSelectResult(this.preset); }

class _DotGridModal extends StatefulWidget {
  final List<UserShapePreset> presets;
  final _DotGridMode mode;
  final String? selectedPresetId;

  const _DotGridModal({
    required this.presets,
    required this.mode,
    this.selectedPresetId,
  });

  @override
  State<_DotGridModal> createState() => _DotGridModalState();
}

class _DotGridModalState extends State<_DotGridModal> {
  final _markedForDeletion = <String>{};

  bool _isSelected(UserShapePreset preset) {
    return preset.id == widget.selectedPresetId;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final screenHeight = MediaQuery.of(context).size.height;
    final isDelete = widget.mode == _DotGridMode.delete;
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
                final isCurrent = _isSelected(preset);
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
                      Navigator.pop(context, _DotGridSelectResult(preset));
                    }
                  },
                  onLongPress: isDelete
                      ? null
                      : () => Navigator.pop(context, _DotGridEditResult(preset)),
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
                          child: ImageFiltered(
                            imageFilter: isMarked
                                ? dart_ui.ImageFilter.blur(
                                    sigmaX: 3, sigmaY: 3)
                                : dart_ui.ImageFilter.blur(
                                    sigmaX: 0, sigmaY: 0),
                            child: CustomPaint(
                              size: const Size(32, 32),
                              painter:
                                  _PresetIconPainter(preset: preset),
                            ),
                          ),
                        ),
                        if (isMarked)
                          const Center(
                            child: Icon(Icons.delete_outline,
                                color: Colors.red, size: 24),
                          ),
                        if (isCurrent && !isMarked)
                          Positioned(
                            right: 2,
                            bottom: 2,
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
          // 삭제 모드: 항상 버튼 표시, 선택 없으면 비활성화
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
                      ? () => Navigator.pop(context, _DotGridDeleteResult(_markedForDeletion))
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
