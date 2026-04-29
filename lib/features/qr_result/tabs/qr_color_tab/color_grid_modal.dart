part of '../qr_color_tab.dart';

// ── 색상/그라디언트 격자 모달 (view / delete 모드) ────────────────────────

enum _ColorGridMode { view, delete }

sealed class _ColorGridResult {}

class _ColorGridDeleteResult extends _ColorGridResult {
  final Set<String> deletedIds;
  _ColorGridDeleteResult(this.deletedIds);
}

class _ColorGridEditResult extends _ColorGridResult {
  final UserColorPalette preset;
  _ColorGridEditResult(this.preset);
}

class _ColorGridModal extends StatefulWidget {
  final List<UserColorPalette> presets;
  final _ColorGridMode mode;
  final bool isGradient;
  final String? selectedPresetId;
  final ValueChanged<UserColorPalette> onSelect;

  const _ColorGridModal({
    required this.presets,
    required this.mode,
    required this.isGradient,
    required this.onSelect,
    this.selectedPresetId,
  });

  @override
  State<_ColorGridModal> createState() => _ColorGridModalState();
}

class _ColorGridModalState extends State<_ColorGridModal> {
  final _markedForDeletion = <String>{};
  String? _localSelectedId;

  @override
  void initState() {
    super.initState();
    _localSelectedId = widget.selectedPresetId;
  }

  bool _isSelected(UserColorPalette preset) =>
      preset.id == _localSelectedId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final screenHeight = MediaQuery.of(context).size.height;
    final isDelete = widget.mode == _ColorGridMode.delete;

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
                      setState(() => _localSelectedId = preset.id);
                      widget.onSelect(preset);
                    }
                  },
                  // 그라디언트만 롱프레스로 편집 진입 (solid 는 모달에서 편집 지원 X — 메인 행에서만)
                  onLongPress: (isDelete || !widget.isGradient)
                      ? null
                      : () => Navigator.pop(
                          context, _ColorGridEditResult(preset)),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      color: isMarked ? Colors.red.shade50 : Colors.grey.shade100,
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
                        Center(child: _buildPreview(preset, isMarked)),
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
          // 삭제 버튼 (delete 모드)
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
                      ? () => Navigator.pop(context,
                          _ColorGridDeleteResult(_markedForDeletion))
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

  Widget _buildPreview(UserColorPalette preset, bool isMarked) {
    final opacity = isMarked ? 0.4 : 1.0;
    if (widget.isGradient) {
      final g = _qrGradientFromPalette(preset);
      return Opacity(
        opacity: opacity,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: g.type == 'radial'
                ? RadialGradient(colors: g.colors, stops: g.stops)
                : LinearGradient(
                    colors: g.colors,
                    stops: g.stops,
                    transform: GradientRotation(g.angleDegrees * math.pi / 180),
                  ),
            shape: BoxShape.circle,
          ),
        ),
      );
    } else {
      return Opacity(
        opacity: opacity,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Color(preset.solidColorArgb ?? 0xFF000000),
            shape: BoxShape.circle,
          ),
        ),
      );
    }
  }
}
