import 'package:flutter/material.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import '../domain/entities/qr_template.dart';
import 'qr_preview_section.dart' show buildQrGradientShader;

/// 템플릿 선택 그리드에서 사용하는 썸네일 카드.
/// thumbnailUrl이 있으면 네트워크 이미지, 없으면 소형 PrettyQrView 렌더.
class TemplateThumbnail extends StatelessWidget {
  final QrTemplate template;
  final bool isSelected;
  final VoidCallback onTap;

  const TemplateThumbnail({
    super.key,
    required this.template,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.shade300,
            width: isSelected ? 2.0 : 1.0,
          ),
          borderRadius: BorderRadius.circular(8),
          color: Colors.white,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: _buildPreview(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 6),
              child: Text(
                template.name,
                style: const TextStyle(fontSize: 10),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (template.isPremium)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                margin: const EdgeInsets.only(bottom: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.shade700,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'PRO',
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
    if (template.thumbnailUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.network(
          template.thumbnailUrl!,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildQrPreview(),
        ),
      );
    }
    return _buildQrPreview();
  }

  Widget _buildQrPreview() {
    final style = template.style;
    final gradient = style.foreground.isGradient ? style.foreground.gradient : null;
    final dotColor = gradient != null
        ? Colors.black
        : (style.foreground.solidColor ?? Colors.black);
    final roundFactor = template.roundFactor ?? 0.0;

    final qr = PrettyQrView.data(
      data: 'https://example.com',
      errorCorrectLevel: QrErrorCorrectLevel.M,
      decoration: PrettyQrDecoration(
        shape: PrettyQrSmoothSymbol(
          roundFactor: roundFactor,
          color: dotColor,
        ),
      ),
    );

    if (gradient != null) {
      return ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: (bounds) => buildQrGradientShader(gradient, bounds),
        child: qr,
      );
    }

    return qr;
  }
}
