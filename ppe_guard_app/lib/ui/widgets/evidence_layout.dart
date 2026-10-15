import 'package:flutter/material.dart';

import 'evidence_image.dart';

/// Wide screens show evidence beside the information, not above all of it.
/// Narrow screens keep a bounded preview and one vertical scroll surface.
class EvidenceLayout extends StatelessWidget {
  const EvidenceLayout({
    super.key,
    required this.image,
    required this.information,
    this.header,
    this.imageFirstOnMobile = true,
    this.showMissingImage = true,
  });

  final ImageProvider<Object>? image;
  final Widget information;
  final Widget? header;
  final bool imageFirstOnMobile;
  final bool showMissingImage;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 960;
          final availableHeight = constraints.hasBoundedHeight
              ? constraints.maxHeight
              : MediaQuery.sizeOf(context).height;
          final previewHeight = (availableHeight * (wide ? .70 : .40))
              .clamp(140.0, wide ? 500.0 : 320.0)
              .toDouble();
          final hasPreview = image != null || showMissingImage;
          final preview = EvidenceImage(
            key: const ValueKey('evidence-preview'),
            image: image,
            height: previewHeight,
          );
          final details = KeyedSubtree(
            key: const ValueKey('evidence-information'),
            child: information,
          );
          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1280),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(wide ? 24 : 16, 12,
                    wide ? 24 : 16, 24),
                children: [
                  if (header != null) ...[
                    header!,
                    const SizedBox(height: 18),
                  ],
                  if (wide && hasPreview)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 5, child: preview),
                        const SizedBox(width: 24),
                        Expanded(flex: 6, child: details),
                      ],
                    )
                  else ...[
                    if (hasPreview && imageFirstOnMobile) ...[
                      preview,
                      const SizedBox(height: 16),
                    ],
                    details,
                    if (hasPreview && !imageFirstOnMobile) ...[
                      const SizedBox(height: 16),
                      preview,
                    ],
                  ],
                ],
              ),
            ),
          );
        },
      );
}
