import 'dart:io';
import 'dart:typed_data';

import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart' show Share, XFile;

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../domain/repositories/qr_output_repository.dart';

class QrOutputRepositoryImpl implements QrOutputRepository {
  const QrOutputRepositoryImpl();

  @override
  Future<Result<bool>> saveToGallery(
      Uint8List imageBytes, String appName) async {
    try {
      final result = await ImageGallerySaver.saveImage(
        imageBytes,
        name: 'apptag_${appName.replaceAll(' ', '_')}',
        isReturnImagePathOfIOS: false,
      );
      final success =
          result['isSuccess'] == true || result['filePath'] != null;
      return Success(success);
    } catch (e, st) {
      return Err(UnexpectedFailure('갤러리 저장 실패: $e',
          cause: e, stackTrace: st));
    }
  }

  @override
  Future<Result<void>> shareImage(
      Uint8List imageBytes, String appName) async {
    try {
      final dir = await getTemporaryDirectory();
      final file = File(
          '${dir.path}/apptag_${appName.replaceAll(' ', '_')}_qr.png');
      await file.writeAsBytes(imageBytes);
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'AppTag: $appName QR 코드',
      );
      return const Success(null);
    } catch (e, st) {
      return Err(UnexpectedFailure('이미지 공유 실패: $e',
          cause: e, stackTrace: st));
    }
  }

  @override
  Future<Result<void>> printQrCode({
    required Uint8List imageBytes,
    required String appName,
    double sizeCm = 5.0,
    String? printTitle,
  }) async {
    try {
      const cmToPt = 28.3465;
      final qrPt = sizeCm * cmToPt;
      final titleText = printTitle ?? appName;

      final doc = pw.Document();
      final image = pw.MemoryImage(imageBytes);

      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  if (titleText.isNotEmpty) ...[
                    pw.Text(
                      titleText,
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 20),
                  ],
                  pw.Image(image, width: qrPt, height: qrPt),
                ],
              ),
            );
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (_) async => doc.save(),
        name: 'AppTag_$appName',
      );
      return const Success(null);
    } catch (e, st) {
      return Err(UnexpectedFailure('QR 인쇄 실패: $e',
          cause: e, stackTrace: st));
    }
  }

  @override
  Future<Result<String>> saveAsSvg(String svgString, String appName) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final svgDir = Directory('${dir.path}/svg');
      if (!svgDir.existsSync()) {
        svgDir.createSync(recursive: true);
      }
      final fileName = 'apptag_${appName.replaceAll(' ', '_')}_qr.svg';
      final file = File('${svgDir.path}/$fileName');
      await file.writeAsString(svgString);
      return Success(file.path);
    } catch (e, st) {
      return Err(UnexpectedFailure('SVG 저장 실패: $e',
          cause: e, stackTrace: st));
    }
  }
}
