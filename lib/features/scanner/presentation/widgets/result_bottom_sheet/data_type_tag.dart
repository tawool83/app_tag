import 'package:flutter/material.dart';

import '../../../domain/entities/scan_detected_type.dart';

class DataTypeTag extends StatelessWidget {
  final ScanDetectedType type;

  const DataTypeTag({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(type.icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          type.name.toUpperCase(),
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}
