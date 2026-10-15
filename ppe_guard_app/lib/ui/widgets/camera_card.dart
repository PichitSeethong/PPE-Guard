import 'package:flutter/material.dart';

import '../../core/constants/app_palette.dart';
import '../../core/utils/date_time_formatter.dart';
import '../../models/camera_status.dart';
import 'status_pill.dart';

class CameraCard extends StatelessWidget {
  const CameraCard({super.key, required this.camera});

  final CameraStatus camera;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(color: AppPalette.blueSoft, borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.videocam_outlined, color: AppPalette.navy),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(camera.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900)),
                      const SizedBox(height: 2),
                      Text(camera.location, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppPalette.mutedInk, fontSize: 12)),
                    ],
                  ),
                ),
                StatusPill(status: camera.status, compact: true),
              ],
            ),
            const Padding(padding: EdgeInsets.symmetric(vertical: 15), child: Divider()),
            _InfoRow(icon: Icons.bolt_outlined, label: 'สถานะ PPE ล่าสุด', value: camera.lastStatus == 'SAFE' ? 'ปลอดภัย' : camera.lastStatus == 'NOT_SAFE' ? 'ไม่ปลอดภัย' : '-'),
            const SizedBox(height: 9),
            _InfoRow(icon: Icons.schedule_outlined, label: 'สัญญาณล่าสุด', value: DateTimeFormatter.dateTime(camera.lastHeartbeatAt)),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppPalette.mutedInk, size: 17),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: AppPalette.mutedInk, fontSize: 12)),
        const Spacer(),
        Flexible(child: Text(value, textAlign: TextAlign.end, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700))),
      ],
    );
  }
}
