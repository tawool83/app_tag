import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

const _appleShortcutsUrl =
    'https://support.apple.com/ko-kr/guide/shortcuts/welcome/ios';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('사용 안내'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          _AppIntro(),
          SizedBox(height: 32),
          _SectionHeader(icon: Icons.nfc, title: 'NFC 태그 규격'),
          SizedBox(height: 12),
          _NfcTagTable(),
          SizedBox(height: 8),
          _CopyHint(),
          SizedBox(height: 32),
          _SectionHeader(icon: Icons.apple, title: 'iOS 단축어(Shortcuts) 사용법'),
          SizedBox(height: 12),
          _IosGuide(),
          SizedBox(height: 32),
          _AppleDocsButton(),
          SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ── 앱 소개 ──────────────────────────────────────────────────────────────────

class _AppIntro extends StatelessWidget {
  const _AppIntro();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.qr_code_scanner,
                size: 28,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 10),
              const Text(
                'App Tag란?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'App Tag는 스마트폰 앱 실행 링크를 QR 코드 또는 NFC 태그로 만들어 주는 앱입니다.',
            style: TextStyle(fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 8),
          const Text(
            '만든 태그를 책상, 가전제품, 문 등에 붙여 두면 스마트폰을 가까이 대거나 QR을 스캔하는 것만으로 원하는 앱을 바로 실행할 수 있습니다.',
            style: TextStyle(fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 12),
          const _IntroBullet(
            icon: Icons.android,
            text: 'Android — 설치된 앱 목록에서 선택 → Play Store 링크로 기록',
          ),
          const SizedBox(height: 6),
          const _IntroBullet(
            icon: Icons.phone_iphone,
            text: 'iOS — 단축어(Shortcuts) 이름 입력 → 단축어 실행 링크로 기록',
          ),
        ],
      ),
    );
  }
}

class _IntroBullet extends StatelessWidget {
  final IconData icon;
  final String text;

  const _IntroBullet({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.4),
          ),
        ),
      ],
    );
  }
}

// ── 섹션 헤더 ────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 22, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

// ── NFC 태그 규격 테이블 ─────────────────────────────────────────────────────

class _NfcTagTable extends StatelessWidget {
  const _NfcTagTable();

  static const _tags = [
    _NfcTag(
      name: 'NTAG213',
      memory: '144 바이트',
      url: '최대 132자',
      note: '일반 용도에 적합',
    ),
    _NfcTag(
      name: 'NTAG215',
      memory: '504 바이트',
      url: '최대 492자',
      note: '링크·단축어 복수 저장 가능',
    ),
    _NfcTag(
      name: 'NTAG216',
      memory: '888 바이트',
      url: '최대 876자',
      note: '대용량 데이터 저장',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _tags.map((tag) => _NfcTagCard(tag: tag)).toList(),
    );
  }
}

class _NfcTag {
  final String name;
  final String memory;
  final String url;
  final String note;

  const _NfcTag({
    required this.name,
    required this.memory,
    required this.url,
    required this.note,
  });
}

class _NfcTagCard extends StatelessWidget {
  final _NfcTag tag;

  const _NfcTagCard({required this.tag});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _copyToClipboard(context, tag.name),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          tag.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.copy, size: 14, color: Colors.grey),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '메모리: ${tag.memory}  •  URL: ${tag.url}',
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tag.note,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('"$text" 클립보드에 복사됨'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _CopyHint extends StatelessWidget {
  const _CopyHint();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.touch_app, size: 14, color: Colors.grey),
        const SizedBox(width: 4),
        Text(
          '태그 이름을 탭하면 클립보드에 복사됩니다.',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}

// ── iOS 단축어 가이드 ────────────────────────────────────────────────────────

class _IosGuide extends StatelessWidget {
  const _IosGuide();

  static const _steps = [
    _IosStep(
      number: '1',
      title: '단축어 앱 열기',
      body: 'iPhone의 기본 앱인 "단축어(Shortcuts)"를 실행합니다.',
    ),
    _IosStep(
      number: '2',
      title: '새 단축어 만들기',
      body: '오른쪽 상단 + 버튼을 눌러 새 단축어를 만듭니다.',
    ),
    _IosStep(
      number: '3',
      title: '앱 열기 액션 추가',
      body: '"앱 열기(Open App)" 액션을 추가하고 원하는 앱을 선택합니다.',
    ),
    _IosStep(
      number: '4',
      title: '단축어 이름 저장',
      body: '단축어 이름을 기억해 두세요. AppTag에서 이 이름으로 NFC 태그를 기록합니다.',
    ),
    _IosStep(
      number: '5',
      title: 'NFC 태그 기록',
      body: 'AppTag에서 단축어 이름을 입력하고 NFC 태그에 기록하면, 태그를 갖다 대면 해당 앱이 바로 실행됩니다.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _steps.map((step) => _IosStepTile(step: step)).toList(),
    );
  }
}

class _IosStep {
  final String number;
  final String title;
  final String body;

  const _IosStep({required this.number, required this.title, required this.body});
}

class _IosStepTile extends StatelessWidget {
  final _IosStep step;

  const _IosStepTile({required this.step});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: Text(
              step.number,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  step.body,
                  style: const TextStyle(fontSize: 14, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Apple 공식 문서 버튼 ─────────────────────────────────────────────────────

class _AppleDocsButton extends StatelessWidget {
  const _AppleDocsButton();

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () async {
        final uri = Uri.parse(_appleShortcutsUrl);
        try {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } catch (_) {
          // ignore: use_build_context_synchronously
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('브라우저를 열 수 없습니다.')),
            );
          }
        }
      },
      icon: const Icon(Icons.open_in_new, size: 18),
      label: const Text('Apple 단축어 공식 사용 설명서'),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
