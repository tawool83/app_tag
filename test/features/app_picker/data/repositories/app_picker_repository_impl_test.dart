import 'dart:typed_data';

import 'package:app_tag/core/error/failure.dart';
import 'package:app_tag/core/error/result.dart';
import 'package:app_tag/features/app_picker/data/datasources/app_list_datasource.dart';
import 'package:app_tag/features/app_picker/data/repositories/app_picker_repository_impl.dart';
import 'package:app_tag/features/app_picker/domain/entities/app_info.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockDataSource extends Mock implements AppListDataSource {}

void main() {
  late _MockDataSource ds;
  late AppPickerRepositoryImpl sut;

  setUp(() {
    ds = _MockDataSource();
    sut = AppPickerRepositoryImpl(ds);
  });

  test('정상 조회 → Success(List<AppInfo>)', () async {
    final apps = [
      AppInfo(
        appName: 'TestApp',
        packageName: 'com.test.app',
        icon: Uint8List.fromList([0]),
      ),
    ];
    when(() => ds.getInstalledApps()).thenAnswer((_) async => apps);

    final result = await sut.getInstalledApps();

    expect(result.isSuccess, true);
    expect(result.valueOrNull?.length, 1);
    expect(result.valueOrNull?[0].appName, 'TestApp');
  });

  test('빈 목록 → Success([])', () async {
    when(() => ds.getInstalledApps()).thenAnswer((_) async => []);

    final result = await sut.getInstalledApps();

    expect(result.isSuccess, true);
    expect(result.valueOrNull, isEmpty);
  });

  test('예외 발생 → Err(UnexpectedFailure)', () async {
    when(() => ds.getInstalledApps()).thenThrow(Exception('platform crash'));

    final result = await sut.getInstalledApps();

    expect(result.isErr, true);
    expect(result.failureOrNull, isA<UnexpectedFailure>());
  });
}
