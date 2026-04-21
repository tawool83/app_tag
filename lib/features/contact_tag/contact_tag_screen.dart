import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/utils/tag_payload_encoder.dart';
import '../../l10n/app_localizations.dart';

class ContactTagScreen extends StatefulWidget {
  final Map<String, dynamic>? prefill;
  const ContactTagScreen({super.key, this.prefill});

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
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.screenContactTitle)),
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
        title: Text(AppLocalizations.of(context)!.actionManualInput,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(AppLocalizations.of(context)!.screenContactManualSubtitle),
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
          hintText: AppLocalizations.of(context)!.hintSearchByName,
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
        : AppLocalizations.of(context)!.labelNoPhone;
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
            Text(AppLocalizations.of(context)!.msgContactPermissionRequired,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.msgContactPermissionHint,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => openAppSettings(),
              icon: const Icon(Icons.settings),
              label: Text(AppLocalizations.of(context)!.actionOpenSettings),
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
        isSearching ? AppLocalizations.of(context)!.msgSearchNoResults : AppLocalizations.of(context)!.msgNoContacts,
        style: const TextStyle(color: Colors.grey),
      ),
    );
  }
}
