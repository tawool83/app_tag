import '../../../../core/error/result.dart';
import '../repositories/nfc_repository.dart';

class CheckNfcAvailabilityUseCase {
  final NfcRepository _repository;
  const CheckNfcAvailabilityUseCase(this._repository);

  Future<Result<bool>> call() => _repository.checkAvailability();
}
