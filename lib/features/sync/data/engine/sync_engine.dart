/// 동기화 결과.
class SyncResult {
  final int pulled;
  final int pushed;
  final int deleted;
  final int conflicts;
  final List<String> errors;

  const SyncResult({
    this.pulled = 0,
    this.pushed = 0,
    this.deleted = 0,
    this.conflicts = 0,
    this.errors = const [],
  });

  bool get hasErrors => errors.isNotEmpty;
}

/// 동기화 엔진 (UserQrTemplate 삭제로 인해 비활성).
/// QrTask 기반 동기화로 재구현 필요.
class TemplateSyncEngine {
  const TemplateSyncEngine();

  Future<SyncResult> sync(String userId) async {
    return const SyncResult();
  }
}
