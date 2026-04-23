import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/logo_manifest.dart';
import '../../domain/entities/qr_template.dart';
import '../../data/datasources/local_default_template_datasource.dart';
import '../../data/repositories/default_template_repository_impl.dart';
import '../../data/repositories/logo_manifest_repository_impl.dart';
import '../../data/repositories/qr_output_repository_impl.dart';
import '../../domain/repositories/default_template_repository.dart';
import '../../domain/repositories/logo_manifest_repository.dart';
import '../../domain/repositories/qr_output_repository.dart';
import '../../domain/usecases/crop_logo_image_usecase.dart';
import '../../domain/usecases/get_default_templates_usecase.dart';
import '../../domain/usecases/load_template_image_usecase.dart';
import '../../domain/usecases/print_qr_code_usecase.dart';
import '../../domain/usecases/rasterize_text_logo_usecase.dart';
import '../../domain/usecases/save_qr_as_svg_usecase.dart';
import '../../domain/usecases/save_qr_to_gallery_usecase.dart';
import '../../domain/usecases/select_logo_asset_usecase.dart';
import '../../domain/usecases/share_qr_image_usecase.dart';

// ── Data layer ────────────────────────────────────────────────────────────────

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

final saveQrAsSvgUseCaseProvider = Provider<SaveQrAsSvgUseCase>((ref) {
  return SaveQrAsSvgUseCase(ref.watch(qrOutputRepositoryProvider));
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

// ── Logo Library (logo-tab-redesign) ─────────────────────────────────────────

final logoManifestRepositoryProvider =
    Provider<LogoManifestRepository>((ref) {
  return LogoManifestRepositoryImpl();
});

final logoManifestProvider = FutureProvider<LogoManifest>((ref) async {
  final repo = ref.watch(logoManifestRepositoryProvider);
  final res = await repo.load();
  return res.fold((m) => m, (_) => LogoManifest.empty);
});

final selectLogoAssetUseCaseProvider =
    Provider<SelectLogoAssetUseCase>((ref) {
  return SelectLogoAssetUseCase(ref.watch(logoManifestRepositoryProvider));
});

final cropLogoImageUseCaseProvider =
    Provider<CropLogoImageUseCase>((ref) {
  return CropLogoImageUseCase();
});

final rasterizeTextLogoUseCaseProvider =
    Provider<RasterizeTextLogoUseCase>((ref) {
  return const RasterizeTextLogoUseCase();
});
