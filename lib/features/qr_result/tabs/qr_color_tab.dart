import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/entities/qr_template.dart' show QrGradient;
import '../qr_result_provider.dart' show qrResultProvider, qrSafeColors, kQrPresetGradients;

/// [색상] 탭: 단색 / 그라디언트 서브탭.
class QrColorTab extends ConsumerStatefulWidget {
  final ValueChanged<Color> onColorSelected;
  final ValueChanged<QrGradient?> onGradientChanged;

  const QrColorTab({
    super.key,
    required this.onColorSelected,
    required this.onGradientChanged,
  });

  @override
  ConsumerState<QrColorTab> createState() => _QrColorTabState();
}

class _QrColorTabState extends ConsumerState<QrColorTab>
    with SingleTickerProviderStateMixin {
  late final TabController _innerTabController;

  @override
  void initState() {
    super.initState();
    _innerTabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _innerTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(qrResultProvider);
    final selectedColor = state.qrColor;
    final customGradient = state.customGradient;

    return Column(
      children: [
        // 서브탭 바: 단색 / 그라디언트
        TabBar(
          controller: _innerTabController,
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 13),
          tabs: const [
            Tab(text: '단색'),
            Tab(text: '그라디언트'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _innerTabController,
            children: [
              // ── 단색 탭 ──────────────────────────────────────────────────
              _SolidColorPanel(
                selected: selectedColor,
                onSelected: (c) {
                  // 단색 탭으로 전환 시 그라디언트 해제
                  widget.onGradientChanged(null);
                  widget.onColorSelected(c);
                },
              ),
              // ── 그라디언트 탭 ────────────────────────────────────────────
              _GradientPanel(
                selected: customGradient,
                onSelected: widget.onGradientChanged,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── 단색 패널: 팔레트 + HSV 컬러 휠 ─────────────────────────────────────────────

class _SolidColorPanel extends StatelessWidget {
  final Color selected;
  final ValueChanged<Color> onSelected;

  const _SolidColorPanel({required this.selected, required this.onSelected});

  Future<void> _openColorWheel(BuildContext context) async {
    Color temp = selected;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('색상 선택'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: temp,
            onColorChanged: (c) => temp = c,
            enableAlpha: false,
            labelTypes: const [],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('확인'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      onSelected(temp);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 직접 색상 선택 (HSV 컬러 휠)
          GestureDetector(
            onTap: () => _openColorWheel(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: selected,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text('직접 선택',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  const SizedBox(width: 4),
                  Icon(Icons.colorize_outlined,
                      size: 16, color: Colors.grey.shade600),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          const Text('추천 색상',
              style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 10),

          // 팔레트 (WCAG 안전 색상)
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: qrSafeColors.map((c) {
              final isSelected = c.toARGB32() == selected.toARGB32();
              return GestureDetector(
                onTap: () => onSelected(c),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.transparent,
                      width: 3,
                    ),
                    boxShadow: isSelected
                        ? [BoxShadow(color: c.withValues(alpha: 0.5), blurRadius: 6)]
                        : null,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ── 그라디언트 패널 ────────────────────────────────────────────────────────────

class _GradientPanel extends StatelessWidget {
  final QrGradient? selected;
  final ValueChanged<QrGradient?> onSelected;

  const _GradientPanel({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('그라디언트 프리셋',
              style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: kQrPresetGradients.map((g) {
              final isSelected = selected != null &&
                  selected!.type == g.type &&
                  selected!.angleDegrees == g.angleDegrees &&
                  selected!.colors.first.toARGB32() ==
                      g.colors.first.toARGB32();
              return GestureDetector(
                onTap: () => onSelected(g),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: g.type == 'radial'
                        ? RadialGradient(colors: g.colors, stops: g.stops)
                        : LinearGradient(
                            colors: g.colors,
                            stops: g.stops,
                            transform: GradientRotation(
                                g.angleDegrees * 3.14159 / 180),
                          ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.transparent,
                      width: 3,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                                color: g.colors.first.withValues(alpha: 0.4),
                                blurRadius: 6)
                          ]
                        : null,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
