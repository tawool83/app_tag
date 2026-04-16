import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../../../core/error/result.dart';
import '../../../../models/qr_template.dart';
import '../../data/datasources/hive_user_template_datasource.dart';
import '../../data/datasources/local_default_template_datasource.dart';
import '../../data/models/user_qr_template_model.dart';
import '../../data/repositories/default_template_repository_impl.dart';
import '../../data/repositories/qr_output_repository_impl.dart';
import '../../data/repositories/user_template_repository_impl.dart';
import '../../domain/repositories/default_template_repository.dart';
import '../../domain/repositories/qr_output_repository.dart';
import '../../domain/repositories/user_template_repository.dart';
import '../../domain/usecases/clear_user_templates_usecase.dart';
import '../../domain/usecases/delete_user_template_usecase.dart';
import '../../domain/usecases/get_default_templates_usecase.dart';
import '../../domain/usecases/get_user_templates_usecase.dart';
import '../../domain/usecases/load_template_image_usecase.dart';
import '../../domain/usecases/print_qr_code_usecase.dart';
import '../../domain/usecases/save_qr_to_gallery_usecase.dart';
import '../../domain/usecases/save_user_template_usecase.dart';
import '../../domain/usecases/share_qr_image_usecase.dart';

// ── Data layer ────────────────────────────────────────────────────────────────

final userTemplateBoxProvider = Provider<Box<UserQrTemplateModel>>((ref) {
  return Hive.box<UserQrTemplateModel>(HiveUserTemplateDataSource.boxName);
});

final hiveUserTemplateDataSourceProvider =
    Provider<HiveUserTemplateDataSource>((ref) {
  return HiveUserTemplateDataSource(ref.watch(userTemplateBoxProvider));
});

final userTemplateRepositoryProvider = Provider<UserTemplateRepository>((ref) {
  return UserTemplateRepositoryImpl(
      ref.watch(hiveUserTemplateDataSourceProvider));
});

final defaultTemplateDataSourceProvider =
    Provider<LocalDefaultTemplateDataSource>((ref) {
  return LocalDefaultTemplateDataSource();
});

final defaultTemplateRepositoryProvider =
    Provider<DefaultTemplateRepository>((ref) {
  return DefaultTemplateRepositoryImpl(
      ref.watch(defaultTemplateDataSourceProvider));
});

final qrOutputRepositoryProvider = Provider<QrOutputRepository>((ref) {
  return const QrOutputRepositoryImpl();
});

// ── UseCases ──────────────────────────────────────────────────────────────────

final getUserTemplatesUseCaseProvider =
    Provider<GetUserTemplatesUseCase>((ref) {
  return GetUserTemplatesUseCase(ref.watch(userTemplateRepositoryProvider));
});

final saveUserTemplateUseCaseProvider =
    Provider<SaveUserTemplateUseCase>((ref) {
  return SaveUserTemplateUseCase(ref.watch(userTemplateRepositoryProvider));
});

final deleteUserTemplateUseCaseProvider =
    Provider<DeleteUserTemplateUseCase>((ref) {
  return DeleteUserTemplateUseCase(ref.watch(userTemplateRepositoryProvider));
});

final clearUserTemplatesUseCaseProvider =
    Provider<ClearUserTemplatesUseCase>((ref) {
  return ClearUserTemplatesUseCase(ref.watch(userTemplateRepositoryProvider));
});

final getDefaultTemplatesUseCaseProvider =
    Provider<GetDefaultTemplatesUseCase>((ref) {
  return GetDefaultTemplatesUseCase(
      ref.watch(defaultTemplateRepositoryProvider));
});

final loadTemplateImageUseCaseProvider =
    Provider<LoadTemplateImageUseCase>((ref) {
  return LoadTemplateImageUseCase(ref.watch(defaultTemplateRepositoryProvider));
});

final saveQrToGalleryUseCaseProvider = Provider<SaveQrToGalleryUseCase>((ref) {
  return SaveQrToGalleryUseCase(ref.watch(qrOutputRepositoryProvider));
});

final shareQrImageUseCaseProvider = Provider<ShareQrImageUseCase>((ref) {
  return ShareQrImageUseCase(ref.watch(qrOutputRepositoryProvider));
});

final printQrCodeUseCaseProvider = Provider<PrintQrCodeUseCase>((ref) {
  return PrintQrCodeUseCase(ref.watch(qrOutputRepositoryProvider));
});

// ── Convenience FutureProvider ────────────────────────────────────────────────

final defaultTemplatesProvider =
    FutureProvider.autoDispose<QrTemplateManifest>((ref) async {
  final result = await ref.watch(getDefaultTemplatesUseCaseProvider)();
  return result.fold(
    (manifest) => manifest,
    (_) => QrTemplateManifest.empty,
  );
});
