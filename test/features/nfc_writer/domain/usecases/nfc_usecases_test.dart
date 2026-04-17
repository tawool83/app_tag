import 'package:app_tag/core/error/failure.dart';
import 'package:app_tag/core/error/result.dart';
import 'package:app_tag/features/nfc_writer/domain/entities/nfc_write_result.dart';
import 'package:app_tag/features/nfc_writer/domain/repositories/nfc_repository.dart';
import 'package:app_tag/features/nfc_writer/domain/usecases/check_nfc_availability_usecase.dart';
import 'package:app_tag/features/nfc_writer/domain/usecases/write_nfc_tag_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockNfcRepo extends Mock implements NfcRepository {}

void main() {
  late _MockNfcRepo repo;

  setUp(() {
    repo = _MockNfcRepo();
  });

  group('CheckNfcAvailabilityUseCase', () {
    test('NFC 사용 가능 → Success(true)', () async {
      when(() => repo.checkAvailability())
          .thenAnswer((_) async => const Success(true));

      final result = await CheckNfcAvailabilityUseCase(repo)();

      expect(result.isSuccess, true);
      expect(result.valueOrNull, true);
    });

    test('NFC 사용 불가 → Success(false)', () async {
      when(() => repo.checkAvailability())
          .thenAnswer((_) async => const Success(false));

      final result = await CheckNfcAvailabilityUseCase(repo)();

      expect(result.valueOrNull, false);
    });

    test('에러 발생 → Err', () async {
      when(() => repo.checkAvailability())
          .thenAnswer((_) async => const Err(UnexpectedFailure('NFC error')));

      final result = await CheckNfcAvailabilityUseCase(repo)();

      expect(result.isErr, true);
    });
  });

  group('WriteNfcTagUseCase', () {
    test('기본 쓰기 → repo.writeTag 위임', () async {
      when(() => repo.writeTag(
            deepLink: any(named: 'deepLink'),
            iosShortcutName: any(named: 'iosShortcutName'),
          )).thenAnswer((_) async =>
              const Success(NfcWriteResult(hasCrossPlatformRecord: false)));

      final result = await WriteNfcTagUseCase(repo)(
        deepLink: 'https://example.com',
      );

      expect(result.isSuccess, true);
      expect(result.valueOrNull?.hasCrossPlatformRecord, false);
      verify(() => repo.writeTag(
            deepLink: 'https://example.com',
            iosShortcutName: null,
          )).called(1);
    });

    test('iOS 단축어 포함 쓰기', () async {
      when(() => repo.writeTag(
            deepLink: any(named: 'deepLink'),
            iosShortcutName: any(named: 'iosShortcutName'),
          )).thenAnswer((_) async =>
              const Success(NfcWriteResult(hasCrossPlatformRecord: true)));

      final result = await WriteNfcTagUseCase(repo)(
        deepLink: 'https://example.com',
        iosShortcutName: '카카오톡',
      );

      expect(result.valueOrNull?.hasCrossPlatformRecord, true);
      verify(() => repo.writeTag(
            deepLink: 'https://example.com',
            iosShortcutName: '카카오톡',
          )).called(1);
    });

    test('쓰기 실패 → PlatformFailure', () async {
      when(() => repo.writeTag(
            deepLink: any(named: 'deepLink'),
            iosShortcutName: any(named: 'iosShortcutName'),
          )).thenAnswer(
              (_) async => const Err(PlatformFailure('쓰기 불가능한 태그입니다.')));

      final result = await WriteNfcTagUseCase(repo)(
        deepLink: 'https://example.com',
      );

      expect(result.isErr, true);
      expect(result.failureOrNull, isA<PlatformFailure>());
    });
  });
}
