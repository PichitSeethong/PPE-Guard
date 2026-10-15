import 'package:flutter/material.dart';

import '../../core/constants/app_palette.dart';
import '../../models/ppe_event.dart';
import '../../repositories/event_repository.dart';
import '../../services/refresh_signal.dart';
import '../widgets/async_state.dart';
import '../widgets/event_card.dart';
import 'event_detail_screen.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  late Future<List<PpeEvent>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
    RefreshSignal.notifier.addListener(_reloadFromSignal);
  }

  @override
  void dispose() {
    RefreshSignal.notifier.removeListener(_reloadFromSignal);
    super.dispose();
  }

  Future<List<PpeEvent>> _load() => EventRepository.instance.list(status: 'NOT_SAFE', period: 'all');

  void _reloadFromSignal() {
    if (!mounted) return;
    final next = _load();
    setState(() {
      _future = next;
    });
  }

  Future<void> _refresh() async {
    final next = _load();
    setState(() {
      _future = next;
    });
    try {
      await next;
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<List<PpeEvent>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) return const LoadingView();
          if (snapshot.hasError) return ErrorView(message: snapshot.error.toString(), onRetry: _refresh);
          final allAlerts = snapshot.data!;
          final pending = allAlerts.where((event) => !event.acknowledged).toList();
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 36),
              children: [
                Row(children: [const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('แจ้งเตือนความปลอดภัย', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppPalette.ink)), SizedBox(height: 4), Text('เหตุการณ์ไม่ปลอดภัยที่บันทึกจากจุดตรวจ PPE', style: TextStyle(color: AppPalette.mutedInk))])), IconButton.filledTonal(onPressed: _refresh, icon: const Icon(Icons.refresh_rounded))]),
                const SizedBox(height: 24),
                _AlertSummary(pending: pending.length, total: allAlerts.length),
                const SizedBox(height: 24),
                if (allAlerts.isEmpty)
                  const Card(child: Padding(padding: EdgeInsets.all(28), child: Column(children: [Icon(Icons.notifications_off_outlined, size: 38, color: AppPalette.mutedInk), SizedBox(height: 10), Text('ยังไม่มีเหตุการณ์ไม่ปลอดภัย', style: TextStyle(fontWeight: FontWeight.w900)), SizedBox(height: 4), Text('เมื่อ PPE ไม่ครบ ระบบจะแสดงรายการที่นี่', textAlign: TextAlign.center, style: TextStyle(color: AppPalette.mutedInk, fontSize: 13))])))
                else ...[
                  if (pending.isNotEmpty) ...[
                    const Text('รอการรับทราบ', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 10),
                    ...pending.map((event) => Padding(padding: const EdgeInsets.only(bottom: 10), child: EventCard(event: event, onTap: () => _open(event.id)))),
                    const SizedBox(height: 14),
                  ],
                  if (allAlerts.where((event) => event.acknowledged).isNotEmpty) ...[
                    const Text('รับทราบแล้ว', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 10),
                    ...allAlerts.where((event) => event.acknowledged).map((event) => Padding(padding: const EdgeInsets.only(bottom: 10), child: EventCard(event: event, compact: true, onTap: () => _open(event.id)))),
                  ],
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  void _open(String id) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => EventDetailScreen(eventId: id)));
  }
}

class _AlertSummary extends StatelessWidget {
  const _AlertSummary({required this.pending, required this.total});

  final int pending;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: pending > 0 ? AppPalette.redSoft : AppPalette.greenSoft, borderRadius: BorderRadius.circular(22)),
      child: Row(children: [Icon(pending > 0 ? Icons.notification_important_outlined : Icons.verified_outlined, color: pending > 0 ? AppPalette.red : AppPalette.green, size: 34), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(pending > 0 ? 'มี $pending เหตุการณ์รอการรับทราบ' : 'ไม่มีเหตุการณ์รอการรับทราบ', style: TextStyle(color: pending > 0 ? AppPalette.red : AppPalette.green, fontWeight: FontWeight.w900, fontSize: 16)), const SizedBox(height: 3), Text('รวมเหตุการณ์ไม่ปลอดภัยทั้งหมด $total รายการ', style: const TextStyle(color: AppPalette.mutedInk, fontSize: 13))]))]),
    );
  }
}
