import 'dart:convert';

import 'package:hive/hive.dart';

import '../../../scanner/domain/entities/scan_detected_type.dart';
import '../../domain/entities/scan_history_entry.dart';

part 'scan_history_model.g.dart';

/// Hive DTO for ScanHistoryEntry.
///
/// typeId: 4 (기존: 0=폐기, 1=UserQrTemplateModel, 2=QrTaskModel, 3=UserColorPaletteModel)
@HiveType(typeId: 4)
class ScanHistoryModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime scannedAt;

  @HiveField(2)
  final String detectedType;

  @HiveField(3)
  final String payloadJson;

  static const String boxName = 'scan_history_box';

  ScanHistoryModel({
    required this.id,
    required this.scannedAt,
    required this.detectedType,
    required this.payloadJson,
  });

  ScanHistoryEntry toEntity() {
    final map = jsonDecode(payloadJson) as Map<String, dynamic>;
    return ScanHistoryEntry(
      id: id,
      scannedAt: scannedAt,
      rawValue: map['rawValue'] as String? ?? '',
      detectedType: ScanDetectedType.values.firstWhere(
        (e) => e.name == detectedType,
        orElse: () => ScanDetectedType.text,
      ),
      parsedMeta: map['parsedMeta'] as Map<String, dynamic>? ?? const {},
      isFavorite: map['isFavorite'] as bool? ?? false,
    );
  }

  factory ScanHistoryModel.fromEntity(ScanHistoryEntry e) {
    return ScanHistoryModel(
      id: e.id,
      scannedAt: e.scannedAt,
      detectedType: e.detectedType.name,
      payloadJson: jsonEncode({
        'rawValue': e.rawValue,
        'parsedMeta': e.parsedMeta,
        'isFavorite': e.isFavorite,
      }),
    );
  }
}
