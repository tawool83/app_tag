# Design: contact-picker

> Plan 참조: `docs/01-plan/features/contact-picker.plan.md`

---

## 1. 설계 개요

| 항목 | 내용 |
|------|------|
| Feature | contact-picker |
| 작성일 | 2026-04-12 |
| 변경 파일 수 | 5개 |
| 신규 파일 | `lib/features/contact_tag/contact_manual_form.dart` |
| 의존성 추가 | `flutter_contacts: ^1.1.9+1` |

---

## 2. 아키텍처 변경

### 2.1 파일 구조

```
lib/features/contact_tag/
  ├── contact_tag_screen.dart     ← 대폭 수정 (피커 메인 화면)
  └── contact_manual_form.dart   ← 신규 (기존 수동 입력 폼 분리)
```

### 2.2 ContactTagScreen 역할 변경

```
Before: 수동 입력 폼 화면
After:  연락처 피커 화면 (직접입력 카드 + 검색 + 연락처 목록)
```

기존 `ContactTagScreen`의 폼 로직은 `ContactManualFormScreen`으로 분리되어 별도 화면으로 push된다.

---

## 3. State 설계

### 3.1 _ContactTagScreenState 필드

```dart
class _ContactTagScreenState extends State<ContactTagScreen> {
  List<Contact> _contacts = [];
  List<Contact> _filtered = [];
  bool _loading = true;
  bool _permissionDenied = false;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadContacts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
```

### 3.2 연락처 로딩

```dart
Future<void> _loadContacts() async {
  setState(() => _loading = true);

  // flutter_contacts 권한 요청 (readOnly)
  final granted = await FlutterContacts.requestPermission(readonly: true);
  if (!granted) {
    setState(() {
      _permissionDenied = true;
      _loading = false;
    });
    return;
  }

  final contacts = await FlutterContacts.getContacts(
    withProperties: true,  // phone, email 포함
    sortBy: ContactSortOrder.firstName,
  );

  setState(() {
    _contacts = contacts;
    _filtered = contacts;
    _loading = false;
  });
}
```

### 3.3 검색 필터

```dart
void _onSearchChanged() {
  final query = _searchController.text.toLowerCase();
  setState(() {
    _filtered = query.isEmpty
        ? _contacts
        : _contacts.where((c) =>
            c.displayName.toLowerCase().contains(query)).toList();
  });
}
```

### 3.4 연락처 선택 → output-selector 이동

```dart
void _onContactSelected(Contact contact) {
  final name  = contact.displayName;
  final phone = contact.phones.isNotEmpty ? contact.phones.first.number : '';
  final email = contact.emails.isNotEmpty ? contact.emails.first.address : '';

  Navigator.pushNamed(
    context,
    '/output-selector',
    arguments: {
      'appName': '연락처',
      'deepLink': TagPayloadEncoder.contact(
        name: name,
        phone: phone,
        email: email,
      ),
      'platform': 'universal',
      'outputType': 'qr',
      'appIconBytes': null,
      'tagType': 'contact',
    },
  );
}
```

---

## 4. UI 컴포넌트 설계

### 4.1 build() 구조

```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(title: const Text('연락처 태그')),
    body: Column(
      children: [
        _DirectInputCard(),      // 고정 최상단
        _SearchField(),          // 검색 입력
        Expanded(child: _buildContactList()),
      ],
    ),
  );
}
```

### 4.2 _DirectInputCard

```dart
Widget _buildDirectInputCard() {
  return Card(
    margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: ListTile(
      leading: const Icon(Icons.edit_note, color: Colors.indigo),
      title: const Text('직접 입력',
          style: TextStyle(fontWeight: FontWeight.w600)),
      subtitle: const Text('이름, 전화번호, 이메일을 직접 입력합니다'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.pushNamed(context, '/contact-manual'),
    ),
  );
}
```

### 4.3 _SearchField

```dart
Widget _buildSearchField() {
  return Padding(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
    child: TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: '이름으로 검색',
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(vertical: 10),
      ),
    ),
  );
}
```

### 4.4 _buildContactList

```dart
Widget _buildContactList() {
  // 로딩 중
  if (_loading) {
    return const Center(child: CircularProgressIndicator());
  }

  // 권한 거부
  if (_permissionDenied) {
    return _buildPermissionDeniedState();
  }

  // 연락처 없음
  if (_filtered.isEmpty) {
    return _buildEmptyState();
  }

  return ListView.builder(
    itemCount: _filtered.length,
    itemBuilder: (_, i) => _buildContactTile(_filtered[i]),
  );
}
```

### 4.5 ContactListTile

```dart
Widget _buildContactTile(Contact contact) {
  final name    = contact.displayName;
  final phone   = contact.phones.isNotEmpty
      ? contact.phones.first.number
      : '전화번호 없음';
  final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

  return ListTile(
    leading: CircleAvatar(
      backgroundColor: Colors.indigo.shade100,
      child: Text(initial,
          style: const TextStyle(
              color: Colors.indigo, fontWeight: FontWeight.bold)),
    ),
    title: Text(name),
    subtitle: Text(phone,
        style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
    onTap: () => _onContactSelected(contact),
  );
}
```

### 4.6 권한 거부 상태

```dart
Widget _buildPermissionDeniedState() {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.contacts, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('연락처 접근 권한이 필요합니다',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text('직접 입력을 사용하거나 설정에서 권한을 허용해주세요.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => openAppSettings(),   // permission_handler
            icon: const Icon(Icons.settings),
            label: const Text('설정 열기'),
          ),
        ],
      ),
    ),
  );
}
```

### 4.7 빈 상태

```dart
Widget _buildEmptyState() {
  final isSearching = _searchController.text.isNotEmpty;
  return Center(
    child: Text(
      isSearching ? '검색 결과가 없습니다.' : '저장된 연락처가 없습니다.',
      style: const TextStyle(color: Colors.grey),
    ),
  );
}
```

---

## 5. ContactManualFormScreen 설계

기존 `ContactTagScreen`의 폼 로직을 그대로 이동. 라우트 `/contact-manual`.

```dart
// lib/features/contact_tag/contact_manual_form.dart

class ContactManualFormScreen extends StatefulWidget {
  const ContactManualFormScreen({super.key});

  @override
  State<ContactManualFormScreen> createState() =>
      _ContactManualFormScreenState();
}

class _ContactManualFormScreenState extends State<ContactManualFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController  = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _onNext() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pushNamed(
      context,
      '/output-selector',
      arguments: {
        'appName': '연락처',
        'deepLink': TagPayloadEncoder.contact(
          name:  _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          email: _emailController.text.trim(),
        ),
        'platform':     'universal',
        'outputType':   'qr',
        'appIconBytes': null,
        'tagType':      'contact',
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('직접 입력')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label('이름 *'),
              _field(_nameController, hint: '홍길동',
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? '이름을 입력해주세요.' : null),
              const SizedBox(height: 16),
              _label('전화번호'),
              _field(_phoneController,
                  hint: '010-0000-0000',
                  keyboardType: TextInputType.phone),
              const SizedBox(height: 16),
              _label('이메일'),
              _field(_emailController,
                  hint: 'example@email.com',
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return null;
                    if (!v.contains('@')) return '올바른 이메일 형식으로 입력해주세요.';
                    return null;
                  }),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _onNext,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('다음'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      );

  Widget _field(
    TextEditingController controller, {
    required String hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) =>
      TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        validator: validator,
      );
}
```

---

## 6. 라우터 변경

**파일**: `lib/app/router.dart`

```dart
// 추가
static const contactManual = '/contact-manual';

// 라우트 매핑 추가
case AppRoutes.contactManual:
  return MaterialPageRoute(
      builder: (_) => const ContactManualFormScreen());
```

---

## 7. pubspec.yaml 변경

```yaml
dependencies:
  flutter_contacts: ^1.1.9+1   # 추가
```

---

## 8. 플랫폼 권한 설정

### 8.1 Android

**파일**: `android/app/src/main/AndroidManifest.xml`

```xml
<!-- <manifest> 태그 내부, <application> 위에 추가 -->
<uses-permission android:name="android.permission.READ_CONTACTS" />
```

### 8.2 iOS

**파일**: `ios/Runner/Info.plist`

```xml
<key>NSContactsUsageDescription</key>
<string>연락처 태그를 만들기 위해 연락처에 접근합니다.</string>
```

---

## 9. 전체 데이터 흐름

```
[홈 화면] → "연락처" 탭
  └─ Navigator.pushNamed('/contact-tag')

[ContactTagScreen.initState()]
  └─ _loadContacts()
       ├─ FlutterContacts.requestPermission(readonly: true)
       │    ├─ 허용 → getContacts(withProperties: true)
       │    │           └─ 이름순 정렬 → _contacts, _filtered 저장
       │    └─ 거부 → _permissionDenied = true
       └─ setState(_loading = false)

[사용자: "직접 입력" 탭]
  └─ Navigator.pushNamed('/contact-manual')
       └─ [ContactManualFormScreen] → 폼 입력 → /output-selector

[사용자: 연락처 항목 탭]
  └─ _onContactSelected(contact)
       └─ Navigator.pushNamed('/output-selector', arguments: {...})

[사용자: 검색 입력]
  └─ _onSearchChanged()
       └─ _filtered = _contacts.where(name contains query)
       └─ setState → ListView 리빌드
```

---

## 10. 파일별 변경 명세

| 파일 | 변경 유형 | 주요 내용 |
|------|---------|---------|
| `pubspec.yaml` | 수정 | `flutter_contacts: ^1.1.9+1` 추가 |
| `android/app/src/main/AndroidManifest.xml` | 수정 | READ_CONTACTS 권한 추가 |
| `ios/Runner/Info.plist` | 수정 | NSContactsUsageDescription 추가 |
| `lib/features/contact_tag/contact_tag_screen.dart` | 대폭 수정 | 피커 UI (직접입력 카드 + 검색 + ListView) |
| `lib/features/contact_tag/contact_manual_form.dart` | 신규 생성 | 기존 수동 폼 로직 이동 |
| `lib/app/router.dart` | 수정 | `/contact-manual` 라우트 추가 |

---

## 11. 수용 기준 (Acceptance Criteria)

- [ ] `/contact-tag` 진입 시 연락처 권한 요청
- [ ] 권한 허용 후 이름순 연락처 목록 표시
- [ ] "직접 입력" 카드가 목록 최상단에 항상 고정
- [ ] "직접 입력" 탭 → `/contact-manual` 화면 이동, 기존 폼 정상 작동
- [ ] 연락처 탭 → `/output-selector`로 name/phone/email 전달
- [ ] 검색 입력 시 실시간 이름 필터링
- [ ] 권한 거부 시 안내 + 설정 열기 버튼 표시
- [ ] 연락처 0개 또는 검색 결과 없을 때 Empty State 표시
- [ ] 로딩 중 CircularProgressIndicator 표시
- [ ] iOS / Android 양쪽 동작
