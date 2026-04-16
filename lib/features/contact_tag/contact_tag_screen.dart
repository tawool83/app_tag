import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/utils/tag_payload_encoder.dart';

class ContactTagScreen extends StatefulWidget {
  const ContactTagScreen({super.key});

  @override
  State<ContactTagScreen> createState() => _ContactTagScreenState();
}

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

  Future<void> _loadContacts() async {
    setState(() => _loading = true);

    final granted = await FlutterContacts.requestPermission(readonly: true);
    if (!granted) {
      setState(() {
        _permissionDenied = true;
        _loading = false;
      });
      return;
    }

    final contacts = await FlutterContacts.getContacts(
      withProperties: true,
    );
    contacts.sort((a, b) =>
        a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));

    setState(() {
      _contacts = contacts;
      _filtered = contacts;
      _loading = false;
    });
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filtered = query.isEmpty
          ? _contacts
          : _contacts
              .where((c) => c.displayName.toLowerCase().contains(query))
              .toList();
    });
  }

  void _onContactSelected(Contact contact) {
    final name = contact.displayName;
    final phone =
        contact.phones.isNotEmpty ? contact.phones.first.number : '';
    final email =
        contact.emails.isNotEmpty ? contact.emails.first.address : '';

    context.push('/qr-result', extra: {
      'appName': '연락처',
      'deepLink': TagPayloadEncoder.contact(
        name: name,
        phone: phone,
        email: email,
      ),
      'platform': 'universal',
      'appIconBytes': null,
      'tagType': 'contact',
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('연락처 태그')),
      body: Column(
        children: [
          _buildDirectInputCard(),
          _buildSearchField(),
          Expanded(child: _buildContactList()),
        ],
      ),
    );
  }

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
        onTap: () => context.push('/contact-manual'),
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: '이름으로 검색',
          prefixIcon: const Icon(Icons.search),
          border:
              OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }

  Widget _buildContactList() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_permissionDenied) {
      return _buildPermissionDeniedState();
    }
    if (_filtered.isEmpty) {
      return _buildEmptyState();
    }
    return ListView.builder(
      itemCount: _filtered.length,
      itemBuilder: (_, i) => _buildContactTile(_filtered[i]),
    );
  }

  Widget _buildContactTile(Contact contact) {
    final name = contact.displayName;
    final phone = contact.phones.isNotEmpty
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
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            const Text(
              '직접 입력을 사용하거나 설정에서 권한을 허용해주세요.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => openAppSettings(),
              icon: const Icon(Icons.settings),
              label: const Text('설정 열기'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final isSearching = _searchController.text.isNotEmpty;
    return Center(
      child: Text(
        isSearching ? '검색 결과가 없습니다.' : '저장된 연락처가 없습니다.',
        style: const TextStyle(color: Colors.grey),
      ),
    );
  }
}
