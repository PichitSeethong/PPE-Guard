import 'package:flutter/material.dart';

import '../../core/constants/app_palette.dart';
import '../../core/utils/date_time_formatter.dart';
import '../../models/ppe_event.dart';
import '../../services/api_client.dart';
import 'evidence_image.dart';
import 'status_pill.dart';

class EventCard extends StatelessWidget {
  const EventCard({
    super.key,
    required this.event,
    this.onTap,
    this.compact = false,
  });

  final PpeEvent event;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final imageUrl = event.imageUrl == null ? '' : ApiClient.instance.evidenceUrl(event.imageUrl!);
    final content = Padding(
      padding: const EdgeInsets.all(14),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final horizontal = !compact && constraints.maxWidth > 560 && imageUrl.isNotEmpty;
          final information = _Information(event: event, compact: compact);
          final preview = imageUrl.isEmpty ? const _ImagePlaceholder() : _EventImage(url: imageUrl, compact: compact);
          return horizontal
              ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [preview, const SizedBox(width: 14), Expanded(child: information)])
              : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [if (!compact && imageUrl.isNotEmpty) preview, if (!compact && imageUrl.isNotEmpty) const SizedBox(height: 14), information]);
        },
      ),
    );

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(onTap: onTap, child: content),
    );
  }
}

class _Information extends StatelessWidget {
  const _Information({required this.event, required this.compact});

  final PpeEvent event;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(event.cameraId, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900))),
            StatusPill(status: event.status, compact: true),
          ],
        ),
        const SizedBox(height: 8),
        Text(event.missingThai, maxLines: compact ? 1 : 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: event.isSafe ? AppPalette.teal : AppPalette.red, fontWeight: FontWeight.w700, fontSize: compact ? 12 : 14)),
        const SizedBox(height: 10),
        Row(
          children: [
            const Icon(Icons.schedule_outlined, size: 15, color: AppPalette.mutedInk),
            const SizedBox(width: 5),
            Expanded(child: Text(DateTimeFormatter.dateTime(event.capturedAt), style: const TextStyle(color: AppPalette.mutedInk, fontSize: 12))),
            if (!event.isSafe && !event.acknowledged) const Icon(Icons.notifications_active_outlined, color: AppPalette.red, size: 18),
          ],
        ),
      ],
    );
  }
}

class _EventImage extends StatelessWidget {
  const _EventImage({required this.url, required this.compact});

  final String url;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: compact ? 0 : 190,
      child: EvidenceImage(
        image: NetworkImage(url),
        height: compact ? 0 : 142,
        allowExpand: false,
        cornerRadius: 15,
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder({this.loading = false});

  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 190,
      height: 142,
      color: AppPalette.surfaceSoft,
      alignment: Alignment.center,
      child: loading
          ? const CircularProgressIndicator(strokeWidth: 2)
          : const Icon(Icons.image_not_supported_outlined, color: AppPalette.mutedInk),
    );
  }
}
