# NFC 크로스 플랫폼 태그 Design Document

> **Feature**: nfc-cross-platform
> **Architecture**: Option B — Clean Architecture
> **Date**: 2026-04-10
> **Status**: Draft

---

## 1. Overview

하나의 NFC 태그에 Android URI(`package:`)와 iOS URI(`shortcuts://`) 레코드를 공존시켜, 두 플랫폼 사용자가 각자 독립적으로 자기 레코드만 갱신하는 Read-Merge-Write 구조.

---

## 2. Architecture

### 2.1 컴포넌트 구조

```
lib/
├── services/
│   ├── ndef_record_helper.dart   ← [신규] NDEF 레코드 식별 / 병합
│   └── nfc_service.dart          ← [수정] readNdefRecords() 추가
├── features/
│   └── nfc_writer/
│       ├── nfc_writer_provider.dart  ← [수정] RMW 흐름 조율
│       └── nfc_writer_screen.dart    ← [수정] iOS 단축어 입력 UI
```

### 2.2 레코드 구분 전략

두 플랫폼 모두 URI 레코드를 사용하되, URI **스킴**으로 구분:

| 플랫폼 | URI 스킴 | 예시 |
|--------|----------|------|
| Android | `package:` | `package:com.kakao.talk` |
| iOS | `shortcuts://` | `shortcuts://run-shortcut?name=카카오톡` |

기존 Android write 방식(`NdefRecord.createUri`)을 그대로 유지하면서 스킴 기반 식별 추가.

---

## 3. 상세 설계

### 3.1 NdefRecordHelper (신규)

**파일**: `lib/services/ndef_record_helper.dart`

```dart
import 'dart:typed_data';
import 'package:nfc_manager/nfc_manager.dart';

class NdefRecordHelper {
  /// Android URI 레코드 여부 (package: 스킴)
  static bool isAndroidRecord(NdefRecord record) {
    final uri = _extractUri(record);
    return uri != null && uri.startsWith('package:');
  }

  /// iOS URI 레코드 여부 (shortcuts:// 스킴)
  static bool isIosRecord(NdefRecord record) {
    final uri = _extractUri(record);
    return uri != null && uri.startsWith('shortcuts://');
  }

  /// 기존 레코드 목록에서 현재 플랫폼 레코드만 교체, 나머지 보존
  static List<NdefRecord> merge({
    required List<NdefRecord> existing,
    required NdefRecord newRecord,
    required bool isAndroid,
  }) {
    final preserved = existing.where((r) {
      return isAndroid ? !isAndroidRecord(r) : !isIosRecord(r);
    }).toList();
    return [...preserved, newRecord];
  }

  /// URI 레코드에서 URI 문자열 추출
  static String? _extractUri(NdefRecord record) {
    try {
      if (record.typeNameFormat != NdefTypeNameFormat.wellKnown) return null;
      if (record.type.isEmpty || record.type[0] != 0x55) return null; // 'U'
      if (record.payload.isEmpty) return null;
      final prefixCode = record.payload[0];
      final prefix = _uriPrefix(prefixCode);
      final body = String.fromCharCodes(record.payload.sublist(1));
      return '$prefix$body';
    } catch (_) {
      return null;
    }
  }

  /// NFC URI 접두어 코드 → 문자열 변환 (NFC Forum URI prefix table)
  static String _uriPrefix(int code) {
    const prefixes = {
      0x00: '', 0x01: 'http://www.', 0x02: 'https://www.',
      0x03: 'http://', 0x04: 'https://', 0x05: 'tel:',
      0x06: 'mailto:', 0x07: 'ftp://anonymous:anonymous@',
    };
    return prefixes[code] ?? '';
  }
}
```

### 3.2 NfcService (수정)

**파일**: `lib/services/nfc_service.dart`

추가 메서드: `readNdefRecords()`

```dart
/// 태그에서 기존 NDEF 레코드 목록 반환
/// 빈 태그 또는 읽기 실패 시 빈 리스트 반환 (에러 아님)
Future<List<NdefRecord>> readNdefRecords(NfcTag tag) async {
  try {
    final ndef = Ndef.from(tag);
    if (ndef == null) return [];
    final message = await ndef.read();
    return message?.records ?? [];
  } catch (_) {
    return []; // 읽기 실패 = 빈 태그로 간주
  }
}
```

기존 `writeNdefTag()` 시그니처 변경 — records 리스트를 직접 받도록:

```dart
/// NDEF 메시지(레코드 목록)를 태그에 기록
Future<void> writeNdefMessage({
  required NfcTag tag,
  required List<NdefRecord> records,
}) async {
  final ndef = Ndef.from(tag);
  if (ndef == null || !ndef.isWritable) {
    throw Exception('쓰기 불가능한 태그입니다.');
  }
  await ndef.write(NdefMessage(records));
}
```

### 3.3 NfcWriterNotifier (수정)

**파일**: `lib/features/nfc_writer/nfc_writer_provider.dart`

```dart
// State 확장
class NfcWriterState {
  final NfcWriteStatus status;
  final String? errorMessage;
  final bool hasCrossPlatformRecord; // 태그에 이미 다른 플랫폼 레코드 존재 여부

  const NfcWriterState({
    this.status = NfcWriteStatus.idle,
    this.errorMessage,
    this.hasCrossPlatformRecord = false,
  });
  // copyWith 포함
}

// Notifier 핵심 로직
void startWrite({
  required String deepLink,
  String? iosShortcutName, // Android → iOS 단축어 함께 기록 시 사용
}) {
  state = state.copyWith(status: NfcWriteStatus.waiting);
  NfcManager.instance.startSession(
    onDiscovered: (NfcTag tag) async {
      try {
        // 1. 기존 레코드 읽기
        final existing = await _nfcService.readNdefRecords(tag);

        // 2. 현재 플랫폼 레코드 생성
        final myRecord = NdefRecord.createUri(Uri.parse(deepLink));

        // 3. 병합
        final isAndroid = Platform.isAndroid;
        var records = NdefRecordHelper.merge(
          existing: existing,
          newRecord: myRecord,
          isAndroid: isAndroid,
        );

        // 4. Android에서 iOS 단축어도 함께 기록
        if (isAndroid && iosShortcutName != null && iosShortcutName.isNotEmpty) {
          final iosUri = 'shortcuts://run-shortcut?name=${Uri.encodeComponent(iosShortcutName)}';
          final iosRecord = NdefRecord.createUri(Uri.parse(iosUri));
          // 기존 iOS 레코드 교체
          records = NdefRecordHelper.merge(
            existing: records,
            newRecord: iosRecord,
            isAndroid: false,
          );
        }

        // 5. 쓰기
        await _nfcService.writeNdefMessage(tag: tag, records: records);
        await NfcManager.instance.stopSession();

        if (mounted) {
          state = state.copyWith(status: NfcWriteStatus.success);
        }
      } catch (e) {
        await NfcManager.instance.stopSession(errorMessage: '$e');
        if (mounted) {
          state = state.copyWith(
            status: NfcWriteStatus.error,
            errorMessage: 'NFC 기록에 실패했습니다.',
          );
        }
      }
    },
  );
}
```

### 3.4 NfcWriterScreen (수정)

**파일**: `lib/features/nfc_writer/nfc_writer_screen.dart`

```
변경 사항:
1. Android 플랫폼일 때 "iOS 단축어도 함께 기록" 체크박스 표시
2. 체크 시 단축어 이름 입력 필드 표시
3. startWrite() 호출 시 iosShortcutName 전달
```

**UI 구조 (Android 기준)**:

```
┌────────────────────────────────────┐
│ NFC 기록                    [✕]    │
├────────────────────────────────────┤
│                                    │
│         카카오톡                   │
│                                    │
│    ○  (대기 중 애니메이션)         │
│                                    │
│  NFC 태그를 스마트폰 뒷면에        │
│  가져다 대세요                     │
│                                    │
│  ┌──────────────────────────────┐  │
│  │ ☑ iOS 단축어도 함께 기록    │  │
│  │                              │  │
│  │ 단축어 이름: [카카오톡     ] │  │
│  └──────────────────────────────┘  │
│                                    │
│          [취소]                    │
└────────────────────────────────────┘
```

---

## 4. Read-Merge-Write 플로우

```
NfcWriterScreen                NfcWriterNotifier          NfcService / NdefRecordHelper
      │                               │                              │
      │ startWrite(deepLink,          │                              │
      │   iosShortcutName?)           │                              │
      │──────────────────────────────>│                              │
      │                               │ NFC 세션 시작                │
      │                               │──────────────────────────────>│
      │                               │   태그 감지됨               │
      │                               │<──────────────────────────────│
      │                               │                              │
      │                               │ readNdefRecords(tag)         │
      │                               │──────────────────────────────>│
      │                               │   [기존 레코드 목록]        │
      │                               │<──────────────────────────────│
      │                               │                              │
      │                               │ NdefRecordHelper.merge()     │
      │                               │ (현재 플랫폼 레코드 교체)   │
      │                               │                              │
      │                               │ writeNdefMessage(records)   │
      │                               │──────────────────────────────>│
      │                               │   성공                      │
      │                               │<──────────────────────────────│
      │   status: success             │                              │
      │<──────────────────────────────│                              │
```

---

## 5. 엣지 케이스

| 케이스 | 처리 방식 |
|--------|-----------|
| 빈 태그 (첫 쓰기) | 읽기 → 빈 리스트 반환 → 자기 레코드만 기록 |
| 이미 같은 플랫폼 레코드 있음 | 기존 레코드 교체 (덮어쓰기) |
| 다른 플랫폼 레코드 있음 | 보존 + 자기 레코드 추가 |
| 두 플랫폼 레코드 모두 있음 | 자기 레코드만 교체, 상대방 보존 |
| 읽기 실패 (빈 태그로 간주) | 빈 리스트로 폴백, 자기 레코드만 기록 |
| 쓰기 실패 | 에러 메시지 표시, 재시도 버튼 제공 |
| 태그 용량 초과 | 에러 메시지: "태그 용량이 부족합니다" |

---

## 6. 구현 순서

1. `lib/services/ndef_record_helper.dart` 생성
2. `lib/services/nfc_service.dart` — `readNdefRecords()` + `writeNdefMessage()` 추가, 기존 `writeNdefTag()` 제거
3. `lib/features/nfc_writer/nfc_writer_provider.dart` — RMW 흐름으로 교체
4. `lib/features/nfc_writer/nfc_writer_screen.dart` — iOS 단축어 입력 UI 추가

---

## 7. 변경 파일 요약

| 파일 | 유형 | 주요 변경 |
|------|------|-----------|
| `lib/services/ndef_record_helper.dart` | 신규 | isAndroidRecord, isIosRecord, merge |
| `lib/services/nfc_service.dart` | 수정 | readNdefRecords(), writeNdefMessage() 추가 |
| `lib/features/nfc_writer/nfc_writer_provider.dart` | 수정 | RMW 흐름, iosShortcutName 파라미터 |
| `lib/features/nfc_writer/nfc_writer_screen.dart` | 수정 | iOS 단축어 입력 체크박스 + 필드 |
