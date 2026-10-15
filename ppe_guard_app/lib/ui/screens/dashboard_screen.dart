import 'package:flutter/material.dart';

import '../../core/constants/app_palette.dart';
import '../../models/dashboard_summary.dart';
import '../../repositories/dashboard_repository.dart';
import '../../services/refresh_signal.dart';
import '../widgets/async_state.dart';
import '../widgets/camera_card.dart';
import '../widgets/event_card.dart';
import '../widgets/metric_tile.dart';
import '../widgets/section_header.dart';
import 'event_detail_screen.dart';
import 'entrance_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<DashboardSummary> _future;

  @override
  void initState() {
    super.initState();
    _future = DashboardRepository.instance.load();
    RefreshSignal.notifier.addListener(_reloadFromSignal);
  }

  @override
  void dispose() {
    RefreshSignal.notifier.removeListener(_reloadFromSignal);
    super.dispose();
  }

  void _reloadFromSignal() {
    if (!mounted) return;
    final next = DashboardRepository.instance.load();
    setState(() {
      _future = next;
    });
  }

  Future<void> _refresh() async {
    final next = DashboardRepository.instance.load();
    setState(() {
      _future = next;
    });
    try {
      await next;
    } catch (_) {
      // Error is rendered by FutureBuilder.
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<DashboardSummary>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) return const LoadingView();
          if (snapshot.hasError) return ErrorView(message: snapshot.error.toString(), onRetry: _refresh);
          final data = snapshot.data!;
          return RefreshIndicator(
            onRefresh: _refresh,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 900;
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(isWide ? 34 : 18, 20, isWide ? 34 : 18, 36),
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('ภาพรวมความปลอดภัย', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppPalette.ink)),
                            SizedBox(height: 4),
                            Text('ติดตามสถานะ PPE จากกล้องในไซต์งานแบบเรียลไทม์', style: TextStyle(color: AppPalette.mutedInk)),
                          ]),
                        ),
                        Row(mainAxisSize: MainAxisSize.min, children: [IconButton.filledTonal(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EntranceScreen())), tooltip: 'จอจุดตรวจ', icon: const Icon(Icons.tv_outlined)), const SizedBox(width: 8), IconButton.filledTonal(onPressed: _refresh, tooltip: 'รีเฟรชข้อมูล', icon: const Icon(Icons.refresh_rounded))]),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _SafetyBanner(data: data),
                    const SizedBox(height: 18),
                    LayoutBuilder(
                      builder: (context, layout) {
                        final columns = layout.maxWidth >= 940 ? 3 : layout.maxWidth >= 610 ? 2 : 1;
                        final width = (layout.maxWidth - (columns - 1) * 12) / columns;
                        return Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            SizedBox(width: width, child: MetricTile(label: 'การตรวจวันนี้', value: '${data.eventCount}', helper: 'หนึ่ง Session ต่อหนึ่งคน', icon: Icons.layers_outlined, color: AppPalette.navy)),
                            SizedBox(width: width, child: MetricTile(label: 'ไม่ปลอดภัยวันนี้', value: '${data.notSafeEventCount}', helper: 'ต้องตรวจสอบและรับทราบ', icon: Icons.warning_amber_rounded, color: AppPalette.red)),
                            SizedBox(width: width, child: MetricTile(label: 'Compliance การตรวจ', value: data.hasInspections ? '${data.complianceRate.toStringAsFixed(1)}%' : '-', helper: data.hasInspections ? 'SAFE ÷ จำนวนการตรวจทั้งหมด' : 'รอผลการตรวจจากกล้อง', icon: Icons.verified_user_outlined, color: AppPalette.green)),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 30),
                    const SectionHeader(title: 'สถานะกล้อง', subtitle: 'กล้องต้องส่ง heartbeat อย่างต่อเนื่องเพื่อแสดงว่าออนไลน์'),
                    const SizedBox(height: 12),
                    if (data.cameras.isEmpty)
                      const _EmptyCard(icon: Icons.videocam_off_outlined, title: 'ยังไม่พบสัญญาณจาก reCamera', message: 'รอให้ reCamera 2002 ส่ง heartbeat มาที่ Local Server')
                    else
                      LayoutBuilder(
                        builder: (context, layout) {
                          final columns = layout.maxWidth >= 900 ? 2 : 1;
                          final width = (layout.maxWidth - (columns - 1) * 12) / columns;
                          return Wrap(spacing: 12, runSpacing: 12, children: data.cameras.map((camera) => SizedBox(width: width, child: CameraCard(camera: camera))).toList());
                        },
                      ),
                    const SizedBox(height: 30),
                    const SectionHeader(title: 'สถานะล่าสุด', subtitle: 'ภาพและผลตรวจล่าสุดจาก Server'),
                    const SizedBox(height: 12),
                    if (data.latestEvent == null)
                      const _EmptyCard(icon: Icons.shield_outlined, title: 'ยังไม่มีเหตุการณ์ตรวจ PPE', message: 'ระบบจะแสดงภาพและผลตรวจเมื่อกล้องส่งเหตุการณ์เข้ามา')
                    else
                      EventCard(event: data.latestEvent!, onTap: () => _openEvent(data.latestEvent!.id)),
                    const SizedBox(height: 30),
                    const SectionHeader(title: 'รายการล่าสุด', subtitle: 'ผลการตรวจล่าสุดจากแต่ละ Session'),
                    const SizedBox(height: 12),
                    if (data.recentEvents.isEmpty)
                      const _EmptyCard(icon: Icons.inbox_outlined, title: 'ยังไม่มีข้อมูลในประวัติ', message: 'ยังไม่มีการบันทึกเหตุการณ์จากกล้อง')
                    else
                      ...data.recentEvents.map((event) => Padding(padding: const EdgeInsets.only(bottom: 10), child: EventCard(event: event, compact: true, onTap: () => _openEvent(event.id)))),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _openEvent(String id) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => EventDetailScreen(eventId: id)));
  }
}

class _SafetyBanner extends StatelessWidget {
  const _SafetyBanner({required this.data});

  final DashboardSummary data;

  @override
  Widget build(BuildContext context) {
    final online = data.cameras.where((camera) => camera.isOnline).length;
    final total = data.cameras.length;
    final latestSafe = data.latestEvent?.isSafe;
    final background = latestSafe == false ? AppPalette.redSoft : AppPalette.blueSoft;
    final color = latestSafe == false ? AppPalette.red : AppPalette.navy;
    final icon = latestSafe == false ? Icons.report_problem_outlined : Icons.shield_outlined;
    final title = latestSafe == false ? 'พบสถานะไม่ปลอดภัยล่าสุด' : 'ระบบพร้อมติดตามความปลอดภัย';
    final message = latestSafe == false ? data.latestEvent!.missingThai : 'กล้องออนไลน์ $online${total == 0 ? '' : ' จาก $total'} ตัว • ข้อมูลเก็บใน Local Server ของไซต์งาน';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(24)),
      child: Row(
        children: [
          Container(width: 50, height: 50, decoration: BoxDecoration(color: color.withOpacity(.14), borderRadius: BorderRadius.circular(16)), child: Icon(icon, color: color, size: 28)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w900)), const SizedBox(height: 4), Text(message, style: TextStyle(color: color.withOpacity(.85), fontSize: 13, height: 1.35))])),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.icon, required this.title, required this.message});

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
        child: Column(children: [Icon(icon, size: 36, color: AppPalette.mutedInk), const SizedBox(height: 12), Text(title, style: const TextStyle(fontWeight: FontWeight.w900)), const SizedBox(height: 5), Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppPalette.mutedInk, fontSize: 13))]),
      ),
    );
  }
}
