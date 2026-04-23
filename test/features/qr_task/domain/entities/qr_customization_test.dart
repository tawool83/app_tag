import 'dart:convert';

import 'package:app_tag/features/qr_task/domain/entities/qr_customization.dart';
import 'package:app_tag/features/qr_task/domain/entities/qr_gradient_data.dart';
import 'package:app_tag/features/qr_task/domain/entities/qr_task.dart';
import 'package:app_tag/features/qr_task/domain/entities/qr_task_kind.dart';
import 'package:app_tag/features/qr_task/domain/entities/qr_task_meta.dart';
import 'package:app_tag/features/qr_task/domain/entities/sticker_spec.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('QrCustomization JSON', () {
    test('default 인스턴스 왕복 무손실', () {
      const c = QrCustomization();
      final round = QrCustomization.fromJson(c.toJson());

      expect(round.qrColorArgb, c.qrColorArgb);
      expect(round.gradient, isNull);
      expect(round.roundFactor, c.roundFactor);
      expect(round.eyeOuter, c.eyeOuter);
      expect(round.eyeInner, c.eyeInner);
      expect(round.dotStyle, c.dotStyle);
      expect(round.embedIcon, c.embedIcon);
      expect(round.printSizeCm, c.printSizeCm);
      expect(round.sticker.logoPosition, 'center');
    });

    test('모든 필드 채워서 왕복', () {
      final c = QrCustomization(
        qrColorArgb: 0xFF0066CC,
        gradient: const QrGradientData(
          type: 'linear',
          colorsArgb: [0xFF0066CC, 0xFF6A0DAD],
          stops: [0.0, 1.0],
          angleDegrees: 90,
        ),
        roundFactor: 0.5,
        eyeOuter: 'circleRound',
        eyeInner: 'star',
        randomEyeSeed: 12345,
        quietZoneColorArgb: 0xFFEEEEEE,
        dotStyle: 'dots',
        embedIcon: true,
        centerEmoji: '★',
        centerIconBase64: 'iVBORw0KGgo=',
        printSizeCm: 7.5,
        sticker: const StickerSpec(
          logoPosition: 'bottomRight',
          logoBackground: 'circle',
          topText: StickerTextSpec(
            content: '상단 텍스트',
            colorArgb: 0xFFFF0000,
            fontFamily: 'serif',
            fontSize: 18,
          ),
          bottomText: StickerTextSpec(
            content: 'BOTTOM',
            colorArgb: 0xFF00FF00,
            fontSize: 12,
          ),
        ),
        activeTemplateId: 'tpl-001',
      );

      final round = QrCustomization.fromJson(jsonDecode(jsonEncode(c.toJson())) as Map<String, dynamic>);

      expect(round.qrColorArgb, 0xFF0066CC);
      expect(round.gradient!.type, 'linear');
      expect(round.gradient!.colorsArgb, [0xFF0066CC, 0xFF6A0DAD]);
      expect(round.gradient!.stops, [0.0, 1.0]);
      expect(round.gradient!.angleDegrees, 90);
      expect(round.roundFactor, 0.5);
      expect(round.eyeOuter, 'circleRound');
      expect(round.eyeInner, 'star');
      expect(round.randomEyeSeed, 12345);
      expect(round.quietZoneColorArgb, 0xFFEEEEEE);
      expect(round.dotStyle, 'dots');
      expect(round.embedIcon, true);
      expect(round.centerEmoji, '★');
      expect(round.centerIconBase64, 'iVBORw0KGgo=');
      expect(round.printSizeCm, 7.5);
      expect(round.sticker.logoPosition, 'bottomRight');
      expect(round.sticker.logoBackground, 'circle');
      expect(round.sticker.topText!.content, '상단 텍스트');
      expect(round.sticker.topText!.colorArgb, 0xFFFF0000);
      expect(round.sticker.topText!.fontFamily, 'serif');
      expect(round.sticker.topText!.fontSize, 18);
      expect(round.sticker.bottomText!.content, 'BOTTOM');
      expect(round.activeTemplateId, 'tpl-001');
    });

    test('누락 필드는 기본값으로 복원', () {
      final partial = <String, dynamic>{
        'qrColorArgb': 0xFFAABBCC,
      };

      final c = QrCustomization.fromJson(partial);

      expect(c.qrColorArgb, 0xFFAABBCC);
      expect(c.roundFactor, 0.0);
      expect(c.eyeOuter, 'square');
      expect(c.dotStyle, 'square');
      expect(c.embedIcon, false);
      expect(c.printSizeCm, 5.0);
      expect(c.sticker.logoPosition, 'center');
      expect(c.gradient, isNull);
    });

    test('Base64 가짜 PNG 문자열 왕복 보존', () {
      const fake = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8/5+hHgAHggJ/PchI7wAAAABJRU5ErkJggg==';
      const c = QrCustomization(centerIconBase64: fake);
      final round = QrCustomization.fromJson(c.toJson());
      expect(round.centerIconBase64, fake);
    });
  });

  group('QrTask payload 왕복', () {
    test('toPayloadJson → fromPayloadMap 무손실', () {
      final task = QrTask(
        id: 'task-1',
        createdAt: DateTime.utc(2026, 4, 15, 10),
        updatedAt: DateTime.utc(2026, 4, 15, 10, 30),
        kind: QrTaskKind.qr,
        name: '클립보드 2026-04-15 10:00',
        meta: const QrTaskMeta(
          appName: '클립보드',
          deepLink: 'hello world',
          platform: 'universal',
          tagType: 'clipboard',
        ),
        customization: const QrCustomization(qrColorArgb: 0xFF112233),
      );

      final json = task.toPayloadJson();
      final map = jsonDecode(json) as Map<String, dynamic>;

      expect(map['schemaVersion'], QrTask.currentSchemaVersion);
      expect(map['taskId'], 'task-1');
      expect(map['kind'], 'qr');

      final restored = QrTask.fromPayloadMap(
        id: task.id,
        createdAt: task.createdAt,
        kind: QrTaskKind.fromName(map['kind'] as String),
        map: map,
      );

      expect(restored.id, task.id);
      expect(restored.createdAt, task.createdAt);
      expect(restored.updatedAt, task.updatedAt);
      expect(restored.kind, QrTaskKind.qr);
      expect(restored.meta.appName, '클립보드');
      expect(restored.meta.platform, 'universal');
      expect(restored.meta.tagType, 'clipboard');
      expect(restored.customization.qrColorArgb, 0xFF112233);
    });

    test('updatedAt 누락 시 createdAt 으로 fallback', () {
      final created = DateTime.utc(2026, 1, 1);
      final restored = QrTask.fromPayloadMap(
        id: 'x',
        createdAt: created,
        kind: QrTaskKind.nfc,
        map: const {},
      );
      expect(restored.updatedAt, created);
      expect(restored.kind, QrTaskKind.nfc);
      expect(restored.meta.appName, '');
      expect(restored.customization.eyeOuter, 'square');
    });
  });

  group('QrTaskKind.fromName', () {
    test('정상 값', () {
      expect(QrTaskKind.fromName('qr'), QrTaskKind.qr);
      expect(QrTaskKind.fromName('nfc'), QrTaskKind.nfc);
    });
    test('알 수 없는 값 → qr fallback', () {
      expect(QrTaskKind.fromName('unknown'), QrTaskKind.qr);
      expect(QrTaskKind.fromName(null), QrTaskKind.qr);
    });
  });
}
