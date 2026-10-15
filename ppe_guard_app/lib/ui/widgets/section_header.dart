import 'package:flutter/material.dart';

import '../../core/constants/app_palette.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
  });

  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: AppPalette.ink, fontSize: 19, fontWeight: FontWeight.w900)),
              if (subtitle != null) ...[
                const SizedBox(height: 3),
                Text(subtitle!, style: const TextStyle(color: AppPalette.mutedInk, fontSize: 13)),
              ],
            ],
          ),
        ),
        if (action != null) action!,
      ],
    );
  }
}
