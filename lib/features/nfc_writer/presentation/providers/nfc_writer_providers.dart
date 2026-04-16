import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/nfc_manager_datasource.dart';
import '../../data/repositories/nfc_repository_impl.dart';
import '../../domain/repositories/nfc_repository.dart';
import '../../domain/usecases/check_nfc_availability_usecase.dart';
import '../../domain/usecases/write_nfc_tag_usecase.dart';

// ── Data layer ────────────────────────────────────────────────────────────────

final nfcDataSourceProvider = Provider<NfcManagerDataSource>((ref) {
  return const NfcManagerDataSource();
});

final nfcRepositoryProvider = Provider<NfcRepository>((ref) {
  return NfcRepositoryImpl(ref.watch(nfcDataSourceProvider));
});

// ── UseCases ──────────────────────────────────────────────────────────────────

final checkNfcAvailabilityUseCaseProvider =
    Provider<CheckNfcAvailabilityUseCase>((ref) {
  return CheckNfcAvailabilityUseCase(ref.watch(nfcRepositoryProvider));
});

final writeNfcTagUseCaseProvider = Provider<WriteNfcTagUseCase>((ref) {
  return WriteNfcTagUseCase(ref.watch(nfcRepositoryProvider));
});
