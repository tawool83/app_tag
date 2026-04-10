import 'dart:typed_data';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:share_plus/share_plus.dart' show Share, XFile;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:io';

class QrService {
  /// RepaintBoundary 키를 사용해 QR 위젯을 PNG 이미지로 캡처
  Future<Uint8List?> captureQrImage(RenderRepaintBoundary boundary) async {
    final image = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  /// QR 이미지를 갤러리에 저장
  Future<bool> saveToGallery(Uint8List imageBytes, String appName) async {
    final result = await ImageGallerySaver.saveImage(
      imageBytes,
      name: 'apptag_${appName.replaceAll(' ', '_')}',
      isReturnImagePathOfIOS: false,
    );
    return result['isSuccess'] == true || result['filePath'] != null;
  }

  /// 공유 시트를 통해 QR 이미지 공유
  Future<void> shareImage(Uint8List imageBytes, String appName) async {
    final dir = await getTemporaryDirectory();
    final file = File(
        '${dir.path}/apptag_${appName.replaceAll(' ', '_')}_qr.png');
    await file.writeAsBytes(imageBytes);
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'AppTag: $appName QR 코드',
    );
  }

  /// 시스템 프린트 다이얼로그를 통해 QR 코드 인쇄
  /// [sizeCm] 인쇄할 QR 크기 (cm, 정사각형). 1cm = 28.3465 PDF points
  Future<void> printQrCode({
    required Uint8List imageBytes,
    required String appName,
    double sizeCm = 5.0,
  }) async {
    const cmToPt = 28.3465;
    final qrPt = sizeCm * cmToPt;

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
                pw.Text(
                  appName,
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Image(image, width: qrPt, height: qrPt),
                pw.SizedBox(height: 12),
                pw.Text(
                  'Scan to launch app',
                  style: pw.TextStyle(
                    fontSize: 12,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'AppTag_$appName',
    );
  }
}
