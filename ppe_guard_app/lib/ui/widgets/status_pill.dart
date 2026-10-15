import 'package:flutter/material.dart';

import '../../core/constants/app_palette.dart';
import '../../core/constants/ppe.dart';

class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.status, this.compact = false});

  final String status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final normalized = status.toUpperCase();
    final isSafe = normalized == Ppe.safe || normalized == 'ONLINE';
    final isOffline = normalized == Ppe.offline;
    final color = isSafe
        ? AppPalette.green
        : isOffline
            ? AppPalette.mutedInk
            : AppPalette.red;
    final background = isSafe
        ? AppPalette.greenSoft
        : isOffline
            ? AppPalette.surfaceSoft
            : AppPalette.redSoft;
    final label = normalized == Ppe.safe
        ? 'ปลอดภัย'
        : normalized == Ppe.notSafe
            ? 'ไม่ปลอดภัย'
            : normalized == 'ONLINE'
                ? 'ออนไลน์'
                : 'ออฟไลน์';

    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 9 : 12, vertical: compact ? 5 : 7),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: compact ? 7 : 8, height: compact ? 7 : 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 7),
          Text(label, style: TextStyle(color: color, fontSize: compact ? 11 : 12, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
