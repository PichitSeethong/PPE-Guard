import 'package:flutter/material.dart';

import '../../core/constants/app_palette.dart';
import '../../models/ppe_event.dart';
import '../../repositories/event_repository.dart';
import '../../services/refresh_signal.dart';
import '../widgets/async_state.dart';
import '../widgets/event_card.dart';
import '../widgets/section_header.dart';
import 'event_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _status = 'ALL';
  String _period = 'today';
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

  Future<List<PpeEvent>> _load() => EventRepository.instance.list(status: _status, period: _period);

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

  void _setStatus(String value) {
    if (value == _status) return;
    final next = EventRepository.instance.list(status: value, period: _period);
    setState(() {
      _status = value;
      _future = next;
    });
  }

  void _setPeriod(String value) {
    if (value == _period) return;
    final next = EventRepository.instance.list(status: _status, period: value);
    setState(() {
      _period = value;
      _future = next;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<List<PpeEvent>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) return const LoadingView();
          if (snapshot.hasError) return ErrorView(message: snapshot.error.toString(), onRetry: _refresh);
          final items = snapshot.data!;
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 36),
              children: [
                Row(children: [const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('ประวัติการตรวจ PPE', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppPalette.ink)), SizedBox(height: 4), Text('ดูผลการตรวจที่บันทึกแยกตาม Session ของแต่ละคน', style: TextStyle(color: AppPalette.mutedInk))])), IconButton.filledTonal(onPressed: _refresh, icon: const Icon(Icons.refresh_rounded))]),
                const SizedBox(height: 24),
                const SectionHeader(title: 'ตัวกรอง', subtitle: 'เลือกช่วงเวลาและสถานะที่ต้องการตรวจสอบ'),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('ช่วงเวลา', style: TextStyle(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      Wrap(spacing: 8, runSpacing: 8, children: [
                        _FilterChip(label: 'วันนี้', selected: _period == 'today', onTap: () => _setPeriod('today')),
                        _FilterChip(label: '7 วัน', selected: _period == 'week', onTap: () => _setPeriod('week')),
                        _FilterChip(label: '30 วัน', selected: _period == 'month', onTap: () => _setPeriod('month')),
                        _FilterChip(label: 'ทั้งหมด', selected: _period == 'all', onTap: () => _setPeriod('all')),
                      ]),
                      const SizedBox(height: 16),
                      const Text('สถานะ', style: TextStyle(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      Wrap(spacing: 8, runSpacing: 8, children: [
                        _FilterChip(label: 'ทุกสถานะ', selected: _status == 'ALL', onTap: () => _setStatus('ALL')),
                        _FilterChip(label: 'ปลอดภัย', selected: _status == 'SAFE', onTap: () => _setStatus('SAFE')),
                        _FilterChip(label: 'ไม่ปลอดภัย', selected: _status == 'NOT_SAFE', onTap: () => _setStatus('NOT_SAFE')),
                      ]),
                    ]),
                  ),
                ),
                const SizedBox(height: 24),
                SectionHeader(title: 'รายการเหตุการณ์', subtitle: '${items.length} รายการ'),
                const SizedBox(height: 12),
                if (items.isEmpty)
                  const Card(child: Padding(padding: EdgeInsets.all(28), child: Column(children: [Icon(Icons.search_off_outlined, size: 36, color: AppPalette.mutedInk), SizedBox(height: 10), Text('ไม่พบเหตุการณ์ตามเงื่อนไขที่เลือก', style: TextStyle(fontWeight: FontWeight.w800)), SizedBox(height: 4), Text('ระบบจะแสดงเฉพาะเหตุการณ์ที่ส่งจากกล้องจริง', textAlign: TextAlign.center, style: TextStyle(color: AppPalette.mutedInk, fontSize: 13))])))
                else
                  ...items.map((event) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: EventCard(
                      event: event,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => EventDetailScreen(eventId: event.id)),
                      ),
                    ),
                  )),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(label: Text(label), selected: selected, onSelected: (_) => onTap(), selectedColor: AppPalette.blueSoft, labelStyle: TextStyle(color: selected ? AppPalette.navy : AppPalette.mutedInk, fontWeight: FontWeight.w700), side: const BorderSide(color: AppPalette.line));
  }
}
