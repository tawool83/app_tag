import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../l10n/app_localizations.dart';

/// "새로 만들기" 바텀시트 — 9개 타일 그리드.
class CreatePickerSheet extends StatelessWidget {
  const CreatePickerSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tiles = _buildTiles(context, l10n);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.sheetCreateTitle,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.0,
            children: tiles.map((t) => _TileCard(tile: t)).toList(),
          ),
        ],
      ),
    );
  }

  List<_Tile> _buildTiles(BuildContext context, AppLocalizations l10n) {
    return [
      _Tile(
        icon: Platform.isAndroid ? Icons.apps : CupertinoIcons.square_stack_3d_up,
        label: Platform.isAndroid ? l10n.tileAppAndroid : l10n.tileAppIos,
        color: const Color(0xFF5C6BC0),
        route: Platform.isAndroid ? '/app-picker' : '/ios-input',
      ),
      _Tile(
        icon: Icons.content_paste,
        label: l10n.tileClipboard,
        color: const Color(0xFF78909C),
        route: '/clipboard-tag',
      ),
      _Tile(
        icon: Icons.language,
        label: l10n.tileWebsite,
        color: const Color(0xFF42A5F5),
        route: '/website-tag',
      ),
      _Tile(
        icon: Icons.contact_phone,
        label: l10n.tileContact,
        color: const Color(0xFF66BB6A),
        route: '/contact-tag',
      ),
      _Tile(
        icon: Icons.wifi,
        label: l10n.tileWifi,
        color: const Color(0xFF26A69A),
        route: '/wifi-tag',
      ),
      _Tile(
        icon: Icons.location_on,
        label: l10n.tileLocation,
        color: const Color(0xFFEF5350),
        route: '/location-tag',
      ),
      _Tile(
        icon: Icons.event,
        label: l10n.tileEvent,
        color: const Color(0xFFFFA726),
        route: '/event-tag',
      ),
      _Tile(
        icon: Icons.email,
        label: l10n.tileEmail,
        color: const Color(0xFF7E57C2),
        route: '/email-tag',
      ),
      _Tile(
        icon: Icons.sms,
        label: l10n.tileSms,
        color: const Color(0xFFEC407A),
        route: '/sms-tag',
      ),
    ];
  }
}

class _Tile {
  final IconData icon;
  final String label;
  final Color color;
  final String route;

  const _Tile({
    required this.icon,
    required this.label,
    required this.color,
    required this.route,
  });
}

class _TileCard extends StatelessWidget {
  final _Tile tile;
  const _TileCard({required this.tile});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: tile.color,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          context.push(tile.route);
        },
        borderRadius: BorderRadius.circular(14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(tile.icon, color: Colors.white, size: 28),
            const SizedBox(height: 6),
            Text(
              tile.label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
