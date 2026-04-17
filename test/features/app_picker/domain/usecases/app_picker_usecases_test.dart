import 'dart:typed_data';

import 'package:app_tag/core/error/failure.dart';
import 'package:app_tag/core/error/result.dart';
import 'package:app_tag/features/app_picker/domain/entities/app_info.dart';
import 'package:app_tag/features/app_picker/domain/repositories/app_picker_repository.dart';
import 'package:app_tag/features/app_picker/domain/usecases/get_installed_apps_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAppPickerRepo extends Mock implements AppPickerRepository {}

void main() {
  late _MockAppPickerRepo repo;
  late GetInstalledAppsUseCase sut;

  setUp(() {
    repo = _MockAppPickerRepo();
    sut = GetInstalledAppsUseCase(repo);
  });

  test('앱 목록 조회 성공 → Success(List<AppInfo>)', () async {
    final apps = [
      AppInfo(
        appName: '카카오톡',
        packageName: 'com.kakao.talk',
        icon: Uint8List.fromList([1, 2, 3]),
      ),
      const AppInfo(
        appName: 'Chrome',
        packageName: 'com.android.chrome',
      ),
    ];
    when(() => repo.getInstalledApps())
        .thenAnswer((_) async => Success(apps));

    final result = await sut();

    expect(result.isSuccess, true);
    expect(result.valueOrNull?.length, 2);
    expect(result.valueOrNull?[0].appName, '카카오톡');
    expect(result.valueOrNull?[0].packageName, 'com.kakao.talk');
    expect(result.valueOrNull?[0].icon, isNotNull);
    expect(result.valueOrNull?[1].icon, isNull);
    verify(() => repo.getInstalledApps()).called(1);
  });

  test('빈 목록 → Success([])', () async {
    when(() => repo.getInstalledApps())
        .thenAnswer((_) async => const Success(<AppInfo>[]));

    final result = await sut();

    expect(result.isSuccess, true);
    expect(result.valueOrNull, isEmpty);
  });

  test('에러 → Err(UnexpectedFailure)', () async {
    when(() => repo.getInstalledApps())
        .thenAnswer((_) async => const Err(UnexpectedFailure('platform error')));

    final result = await sut();

    expect(result.isErr, true);
    expect(result.failureOrNull, isA<UnexpectedFailure>());
  });
}
