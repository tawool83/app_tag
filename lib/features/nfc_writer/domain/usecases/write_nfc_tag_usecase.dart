import '../../../../core/error/result.dart';
import '../entities/nfc_write_result.dart';
import '../repositories/nfc_repository.dart';

class WriteNfcTagUseCase {
  final NfcRepository _repository;
  const WriteNfcTagUseCase(this._repository);

  Future<Result<NfcWriteResult>> call({
    required String deepLink,
    String? iosShortcutName,
  }) =>
      _repository.writeTag(
        deepLink: deepLink,
        iosShortcutName: iosShortcutName,
      );
}
