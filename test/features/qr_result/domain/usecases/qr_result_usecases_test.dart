import 'dart:typed_data';

import 'package:app_tag/core/error/failure.dart';
import 'package:app_tag/core/error/result.dart';
import 'package:app_tag/features/qr_result/domain/entities/qr_template.dart';
import 'package:app_tag/features/qr_result/domain/entities/user_qr_template.dart';
import 'package:app_tag/features/qr_result/domain/repositories/default_template_repository.dart';
import 'package:app_tag/features/qr_result/domain/repositories/qr_output_repository.dart';
import 'package:app_tag/features/qr_result/domain/repositories/user_template_repository.dart';
import 'package:app_tag/features/qr_result/domain/usecases/clear_user_templates_usecase.dart';
import 'package:app_tag/features/qr_result/domain/usecases/delete_user_template_usecase.dart';
import 'package:app_tag/features/qr_result/domain/usecases/get_default_templates_usecase.dart';
import 'package:app_tag/features/qr_result/domain/usecases/get_user_templates_usecase.dart';
import 'package:app_tag/features/qr_result/domain/usecases/load_template_image_usecase.dart';
import 'package:app_tag/features/qr_result/domain/usecases/save_qr_to_gallery_usecase.dart';
import 'package:app_tag/features/qr_result/domain/usecases/save_user_template_usecase.dart';
import 'package:app_tag/features/qr_result/domain/usecases/share_qr_image_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockDefaultTemplateRepo extends Mock
    implements DefaultTemplateRepository {}

class _MockUserTemplateRepo extends Mock implements UserTemplateRepository {}

class _MockQrOutputRepo extends Mock implements QrOutputRepository {}

class _FakeUserQrTemplate extends Fake implements UserQrTemplate {}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeUserQrTemplate());
    registerFallbackValue(Uint8List(0));
  });

  // ── DefaultTemplate UseCases ────────────────────────────────────────

  group('GetDefaultTemplatesUseCase', () {
    late _MockDefaultTemplateRepo repo;
    late GetDefaultTemplatesUseCase sut;

    setUp(() {
      repo = _MockDefaultTemplateRepo();
      sut = GetDefaultTemplatesUseCase(repo);
    });

    test('성공 시 QrTemplateManifest 반환', () async {
      const manifest = QrTemplateManifest.empty;
      when(() => repo.getTemplates())
          .thenAnswer((_) async => const Success(manifest));

      final result = await sut();

      expect(result.isSuccess, true);
      expect(result.valueOrNull, manifest);
      verify(() => repo.getTemplates()).called(1);
    });

    test('실패 시 Err 반환', () async {
      when(() => repo.getTemplates())
          .thenAnswer((_) async => const Err(UnexpectedFailure('fail')));

      final result = await sut();

      expect(result.isErr, true);
    });
  });

  group('LoadTemplateImageUseCase', () {
    late _MockDefaultTemplateRepo repo;
    late LoadTemplateImageUseCase sut;

    setUp(() {
      repo = _MockDefaultTemplateRepo();
      sut = LoadTemplateImageUseCase(repo);
    });

    test('URL 전달 → repo.loadImageBytes 위임', () async {
      final bytes = Uint8List.fromList([1, 2, 3]);
      when(() => repo.loadImageBytes(any()))
          .thenAnswer((_) async => Success(bytes));

      final result = await sut('https://example.com/icon.png');

      expect(result.valueOrNull, bytes);
      verify(() => repo.loadImageBytes('https://example.com/icon.png'))
          .called(1);
    });
  });

  // ── UserTemplate UseCases ───────────────────────────────────────────

  group('UserTemplate UseCases', () {
    late _MockUserTemplateRepo repo;

    setUp(() {
      repo = _MockUserTemplateRepo();
    });

    test('GetUserTemplatesUseCase → repo.getAll 위임', () async {
      when(() => repo.getAll())
          .thenAnswer((_) async => const Success(<UserQrTemplate>[]));

      final result = await GetUserTemplatesUseCase(repo)();

      expect(result.isSuccess, true);
      expect(result.valueOrNull, isEmpty);
    });

    test('SaveUserTemplateUseCase → repo.save 위임', () async {
      when(() => repo.save(any()))
          .thenAnswer((_) async => const Success(null));

      final result = await SaveUserTemplateUseCase(repo)(_FakeUserQrTemplate());

      expect(result.isSuccess, true);
      verify(() => repo.save(any())).called(1);
    });

    test('DeleteUserTemplateUseCase → repo.delete 위임', () async {
      when(() => repo.delete(any()))
          .thenAnswer((_) async => const Success(null));

      final result = await DeleteUserTemplateUseCase(repo)('id-1');

      expect(result.isSuccess, true);
      verify(() => repo.delete('id-1')).called(1);
    });

    test('ClearUserTemplatesUseCase → repo.clearAll 위임', () async {
      when(() => repo.clearAll())
          .thenAnswer((_) async => const Success(null));

      final result = await ClearUserTemplatesUseCase(repo)();

      expect(result.isSuccess, true);
      verify(() => repo.clearAll()).called(1);
    });
  });

  // ── QrOutput UseCases ───────────────────────────────────────────────

  group('QrOutput UseCases', () {
    late _MockQrOutputRepo repo;
    final testBytes = Uint8List.fromList([0x89, 0x50, 0x4E, 0x47]);

    setUp(() {
      repo = _MockQrOutputRepo();
    });

    test('SaveQrToGalleryUseCase → repo.saveToGallery 위임', () async {
      when(() => repo.saveToGallery(any(), any()))
          .thenAnswer((_) async => const Success(true));

      final result = await SaveQrToGalleryUseCase(repo)(testBytes, 'TestApp');

      expect(result.valueOrNull, true);
      verify(() => repo.saveToGallery(testBytes, 'TestApp')).called(1);
    });

    test('ShareQrImageUseCase → repo.shareImage 위임', () async {
      when(() => repo.shareImage(any(), any()))
          .thenAnswer((_) async => const Success(null));

      final result = await ShareQrImageUseCase(repo)(testBytes, 'TestApp');

      expect(result.isSuccess, true);
    });
  });
}
