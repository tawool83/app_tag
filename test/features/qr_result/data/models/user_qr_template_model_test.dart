import 'dart:typed_data';

import 'package:app_tag/features/qr_result/data/models/user_qr_template_model.dart';
import 'package:app_tag/features/qr_result/domain/entities/user_qr_template.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserQrTemplateModel 왕복 변환', () {
    test('fromEntity → toEntity 왕복 불변 (전체 필드)', () {
      final entity = UserQrTemplate(
        id: 'tpl-1',
        name: '파란 QR',
        createdAt: DateTime.utc(2026, 4, 17),
        qrColorValue: 0xFF0000FF,
        gradientJson: '{"type":"linear","colors":["#0000FF","#00FF00"]}',
        roundFactor: 0.5,
        dotStyleIndex: 1,
        eyeOuterIndex: 2,
        eyeInnerIndex: 1,
        randomEyeSeed: 42,
        quietZoneColorValue: 0xFFEEEEEE,
        logoPositionIndex: 1,
        logoBackgroundIndex: 1,
        topTextContent: '상단 텍스트',
        topTextColorValue: 0xFFFF0000,
        topTextFont: 'serif',
        topTextSize: 18.0,
        bottomTextContent: '하단 텍스트',
        bottomTextColorValue: 0xFF00FF00,
        bottomTextFont: 'monospace',
        bottomTextSize: 12.0,
        thumbnailBytes: Uint8List.fromList([1, 2, 3]),
      );

      final model = UserQrTemplateModel.fromEntity(entity);
      final restored = model.toEntity();

      expect(restored.id, entity.id);
      expect(restored.name, entity.name);
      expect(restored.createdAt, entity.createdAt);
      expect(restored.qrColorValue, entity.qrColorValue);
      expect(restored.gradientJson, entity.gradientJson);
      expect(restored.roundFactor, entity.roundFactor);
      expect(restored.dotStyleIndex, entity.dotStyleIndex);
      expect(restored.eyeOuterIndex, entity.eyeOuterIndex);
      expect(restored.eyeInnerIndex, entity.eyeInnerIndex);
      expect(restored.randomEyeSeed, entity.randomEyeSeed);
      expect(restored.quietZoneColorValue, entity.quietZoneColorValue);
      expect(restored.logoPositionIndex, entity.logoPositionIndex);
      expect(restored.logoBackgroundIndex, entity.logoBackgroundIndex);
      expect(restored.topTextContent, entity.topTextContent);
      expect(restored.topTextColorValue, entity.topTextColorValue);
      expect(restored.topTextFont, entity.topTextFont);
      expect(restored.topTextSize, entity.topTextSize);
      expect(restored.bottomTextContent, entity.bottomTextContent);
      expect(restored.bottomTextColorValue, entity.bottomTextColorValue);
      expect(restored.bottomTextFont, entity.bottomTextFont);
      expect(restored.bottomTextSize, entity.bottomTextSize);
      expect(restored.thumbnailBytes, entity.thumbnailBytes);
    });

    test('nullable 필드 null 왕복', () {
      final entity = UserQrTemplate(
        id: 'tpl-2',
        name: '기본',
        createdAt: DateTime.utc(2026, 1, 1),
      );

      final restored = UserQrTemplateModel.fromEntity(entity).toEntity();

      expect(restored.gradientJson, isNull);
      expect(restored.randomEyeSeed, isNull);
      expect(restored.topTextContent, isNull);
      expect(restored.bottomTextContent, isNull);
      expect(restored.thumbnailBytes, isNull);
    });

    test('기본값 보존', () {
      final entity = UserQrTemplate(
        id: 'tpl-3',
        name: '기본값',
        createdAt: DateTime.utc(2026, 1, 1),
      );

      final restored = UserQrTemplateModel.fromEntity(entity).toEntity();

      expect(restored.qrColorValue, 0xFF000000);
      expect(restored.roundFactor, 0.0);
      expect(restored.quietZoneColorValue, 0xFFFFFFFF);
      expect(restored.dotStyleIndex, 0);
      expect(restored.eyeOuterIndex, 0);
      expect(restored.eyeInnerIndex, 0);
    });
  });
}
