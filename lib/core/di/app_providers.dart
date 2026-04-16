import 'package:flutter_riverpod/flutter_riverpod.dart';

/// ProviderScope 에 주입할 전역 override 목록.
///
/// 각 feature 의 DI 는 feature 내부 providers.dart 에서 자체 등록.
/// 여기서는 전역 수준 override 만 필요 시 추가.
List<Override> buildAppOverrides() => const [];
