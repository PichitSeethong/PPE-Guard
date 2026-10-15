import 'package:flutter/material.dart';

import '../../core/constants/app_palette.dart';
import '../../core/constants/ppe.dart';
import '../../core/utils/date_time_formatter.dart';
import '../../models/ppe_event.dart';
import '../../repositories/event_repository.dart';
import '../../services/api_client.dart';
import '../../services/auth_store.dart';
import '../../services/refresh_signal.dart';
import '../widgets/async_state.dart';
import '../widgets/evidence_layout.dart';
import '../widgets/status_pill.dart';

class EventDetailScreen extends StatefulWidget {
  const EventDetailScreen({super.key, required this.eventId});
  final String eventId;

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  late Future<PpeEvent> _future;
  bool _acknowledging = false;

  @override
  void initState() {
    super.initState();
    _future = EventRepository.instance.byId(widget.eventId);
  }

  Future<void> _refresh() async {
    final next = EventRepository.instance.byId(widget.eventId);
    setState(() {
      _future = next;
    });
    try {
      await next;
    } catch (_) {}
  }

  Future<void> _acknowledge(PpeEvent event) async {
    if (_acknowledging) return;
    setState(() {
      _acknowledging = true;
    });
    try {
      final updated = await EventRepository.instance.acknowledge(event.id);
      if (!mounted) return;
      setState(() {
        _future = Future.value(updated);
      });
      RefreshSignal.publish();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('รับทราบเหตุการณ์แล้ว')));
    } on ApiException catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() {
        _acknowledging = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('รายละเอียดเหตุการณ์'), actions: [IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh_rounded))]),
      body: FutureBuilder<PpeEvent>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) return const LoadingView();
          if (snapshot.hasError) return ErrorView(message: snapshot.error.toString(), onRetry: _refresh);
          final event = snapshot.data!;
          final canAcknowledge = AuthStore.instance.user.value?.canAcknowledge == true;
          final relative = event.imageUrl;
          return EvidenceLayout(
            image: relative == null || relative.isEmpty
                ? null
                : NetworkImage(ApiClient.instance.evidenceUrl(relative)),
            header: Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(event.cameraId, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)), const SizedBox(height: 4), Text(DateTimeFormatter.dateTime(event.capturedAt), style: const TextStyle(color: AppPalette.mutedInk))])), StatusPill(status: event.status)]),
            information: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
              Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('ผลการตรวจ PPE', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                const SizedBox(height: 14),
                if (event.isSafe) const _Tag(text: 'ตรวจพบ PPE ครบทุกชิ้น', color: AppPalette.green, background: AppPalette.greenSoft) else ...[
                  const Text('อุปกรณ์ที่ขาด', style: TextStyle(color: AppPalette.mutedInk, fontSize: 13, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, runSpacing: 8, children: event.missingPpe.map((item) => _Tag(text: Ppe.thai(item), color: AppPalette.red, background: AppPalette.redSoft)).toList()),
                ],
                const SizedBox(height: 18),
                const Divider(),
                const SizedBox(height: 12),
                _KeyValue(label: 'ความมั่นใจของโมเดล', value: '${(event.confidence * 100).toStringAsFixed(1)}%'),
                _KeyValue(label: 'จำนวนบุคคลที่พบ', value: '${event.personCount} คน'),
                _KeyValue(label: 'โมเดล', value: event.modelVersion ?? '-'),
              ]))),
              const SizedBox(height: 12),
              Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('สถานะการจัดการ', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                const SizedBox(height: 12),
                _KeyValue(label: 'เวลาเริ่มเหตุการณ์', value: DateTimeFormatter.dateTime(event.capturedAt)),
                _KeyValue(label: 'เวลากลับมาปลอดภัย', value: DateTimeFormatter.dateTime(event.resolvedAt)),
                _KeyValue(label: 'ระยะเวลา', value: DateTimeFormatter.duration(event.durationSeconds)),
                _KeyValue(label: 'ผู้รับทราบ', value: event.acknowledgedBy ?? (event.acknowledged ? 'รับทราบแล้ว' : 'รอการรับทราบ')),
              ]))),
              if (event.isNotSafe && !event.acknowledged && canAcknowledge) ...[
                const SizedBox(height: 20),
                FilledButton.icon(onPressed: _acknowledging ? null : () => _acknowledge(event), icon: _acknowledging ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.done_all_rounded), label: Text(_acknowledging ? 'กำลังบันทึก...' : 'รับทราบเหตุการณ์')),
              ],
              if (event.isNotSafe && !event.acknowledged && !canAcknowledge) ...[
                const SizedBox(height: 16),
                const Text('บัญชีผู้ดูข้อมูลไม่สามารถรับทราบเหตุการณ์ได้', textAlign: TextAlign.center, style: TextStyle(color: AppPalette.mutedInk, fontSize: 13)),
              ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text, required this.color, required this.background});
  final String text;
  final Color color;
  final Color background;
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(99)), child: Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w800)));
}

class _KeyValue extends StatelessWidget {
  const _KeyValue({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: Text(label, style: const TextStyle(color: AppPalette.mutedInk, fontSize: 13))), const SizedBox(width: 12), Flexible(child: Text(value, textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)))]));
}
