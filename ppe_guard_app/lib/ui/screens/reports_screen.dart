import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_palette.dart';
import '../../core/constants/ppe.dart';
import '../../models/statistics_summary.dart';
import '../../repositories/statistics_repository.dart';
import '../../services/api_client.dart';
import '../../services/auth_store.dart';
import '../../services/refresh_signal.dart';
import '../widgets/async_state.dart';
import '../widgets/metric_tile.dart';
import '../widgets/section_header.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _period = 'today';
  late Future<StatisticsSummary> _future;

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

  Future<StatisticsSummary> _load() {
    return StatisticsRepository.instance.load(_period);
  }

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
    } catch (_) {
      // ErrorView will render the failure state.
    }
  }

  void _setPeriod(String value) {
    if (value == _period) return;
    final next = StatisticsRepository.instance.load(value);
    setState(() {
      _period = value;
      _future = next;
    });
  }

  Future<void> _exportCsv() async {
    final uri = ApiClient.instance.authenticatedUrl(
      '/api/v1/export/events.csv',
      query: {'period': _period},
    );
    final opened = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่สามารถเปิดการดาวน์โหลด CSV ได้')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<StatisticsSummary>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const LoadingView();
          }
          if (snapshot.hasError) {
            return ErrorView(
              message: snapshot.error.toString(),
              onRetry: _refresh,
            );
          }

          final data = snapshot.data!;
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 36),
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'รายงานความปลอดภัย',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: AppPalette.ink,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'สรุปจากจำนวนการตรวจ PPE แยกตาม Session ของแต่ละคน',
                            style: TextStyle(color: AppPalette.mutedInk),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (AuthStore.instance.user.value?.canAcknowledge ==
                            true) ...[
                          IconButton.filledTonal(
                            onPressed: _exportCsv,
                            icon: const Icon(Icons.download_outlined),
                            tooltip: 'ส่งออก CSV',
                          ),
                          const SizedBox(width: 8),
                        ],
                        IconButton.filledTonal(
                          onPressed: _refresh,
                          icon: const Icon(Icons.refresh_rounded),
                          tooltip: 'รีเฟรชข้อมูล',
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _PeriodChip(
                      label: 'วันนี้',
                      selected: _period == 'today',
                      onTap: () => _setPeriod('today'),
                    ),
                    _PeriodChip(
                      label: '7 วัน',
                      selected: _period == 'week',
                      onTap: () => _setPeriod('week'),
                    ),
                    _PeriodChip(
                      label: '30 วัน',
                      selected: _period == 'month',
                      onTap: () => _setPeriod('month'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                LayoutBuilder(
                  builder: (context, layout) {
                    final columns = layout.maxWidth >= 900
                        ? 3
                        : layout.maxWidth >= 610
                            ? 2
                            : 1;
                    final width =
                        (layout.maxWidth - (columns - 1) * 12) / columns;

                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        SizedBox(
                          width: width,
                          child: MetricTile(
                            label: 'Compliance การตรวจ',
                            value: data.hasInspections
                                ? '${data.complianceRate.toStringAsFixed(1)}%'
                                : '-',
                            helper: 'SAFE ÷ จำนวนการตรวจทั้งหมด',
                            icon: Icons.verified_user_outlined,
                            color: AppPalette.green,
                          ),
                        ),
                        SizedBox(
                          width: width,
                          child: MetricTile(
                            label: 'จำนวนการตรวจทั้งหมด',
                            value: '${data.eventCount}',
                            helper: 'หนึ่ง Session ต่อหนึ่งคน',
                            icon: Icons.layers_outlined,
                            color: AppPalette.navy,
                          ),
                        ),
                        SizedBox(
                          width: width,
                          child: MetricTile(
                            label: 'ผลตรวจไม่ปลอดภัย',
                            value: '${data.notSafeEventCount}',
                            helper: 'จำนวน Session ที่เป็น NOT_SAFE',
                            icon: Icons.warning_amber_rounded,
                            color: AppPalette.red,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 28),
                LayoutBuilder(
                  builder: (context, layout) {
                    final wide = layout.maxWidth >= 760;
                    final chart = _ComplianceChart(data: data);
                    final missing = _MissingPpe(data: data);
                    if (wide) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: chart),
                          const SizedBox(width: 12),
                          Expanded(child: missing),
                        ],
                      );
                    }
                    return Column(
                      children: [
                        chart,
                        const SizedBox(height: 12),
                        missing,
                      ],
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PeriodChip extends StatelessWidget {
  const _PeriodChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppPalette.blueSoft,
      labelStyle: TextStyle(
        color: selected ? AppPalette.navy : AppPalette.mutedInk,
        fontWeight: FontWeight.w700,
      ),
      side: const BorderSide(color: AppPalette.line),
    );
  }
}

class _ComplianceChart extends StatelessWidget {
  const _ComplianceChart({required this.data});

  final StatisticsSummary data;

  @override
  Widget build(BuildContext context) {
    final total = data.eventCount;
    final safeFraction = total == 0 ? 0.0 : data.safeEventCount / total;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(
              title: 'สัดส่วนผลการตรวจ',
              subtitle: 'คำนวณจากจำนวน Session ที่ตรวจเสร็จแล้ว',
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 210,
              child: total == 0
                  ? const Center(
                      child: Text(
                        'ยังไม่มีผลการตรวจสำหรับคำนวณ',
                        style: TextStyle(color: AppPalette.mutedInk),
                      ),
                    )
                  : Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox.square(
                          dimension: 190,
                          child: CustomPaint(
                            painter: _DonutChartPainter(
                              safeFraction: safeFraction,
                            ),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${data.complianceRate.toStringAsFixed(1)}%',
                              style: const TextStyle(
                                fontSize: 25,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const Text(
                              'ปลอดภัย',
                              style: TextStyle(
                                color: AppPalette.mutedInk,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 12),
            _Legend(
              color: AppPalette.green,
              label: 'ปลอดภัย • ${data.safeEventCount} ครั้ง',
            ),
            const SizedBox(height: 7),
            _Legend(
              color: AppPalette.red,
              label: 'ไม่ปลอดภัย • ${data.notSafeEventCount} ครั้ง',
            ),
          ],
        ),
      ),
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  const _DonutChartPainter({required this.safeFraction});

  final double safeFraction;

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 28.0;
    const gapRadians = .035;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - strokeWidth / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..color = AppPalette.surfaceSoft
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;
    canvas.drawCircle(center, radius, trackPaint);

    final clampedSafe = safeFraction.clamp(0.0, 1.0);
    final start = -math.pi / 2;
    final availableSweep = 2 * math.pi - gapRadians * 2;
    final safeSweep = availableSweep * clampedSafe;
    final notSafeSweep = availableSweep - safeSweep;

    if (safeSweep > 0) {
      final safePaint = Paint()
        ..color = AppPalette.green
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(rect, start, safeSweep, false, safePaint);
    }

    if (notSafeSweep > 0) {
      final notSafePaint = Paint()
        ..color = AppPalette.red
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(
        rect,
        start + safeSweep + gapRadians,
        notSafeSweep - gapRadians,
        false,
        notSafePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.safeFraction != safeFraction;
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: AppPalette.mutedInk,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}

class _MissingPpe extends StatelessWidget {
  const _MissingPpe({required this.data});

  final StatisticsSummary data;

  @override
  Widget build(BuildContext context) {
    final entries = data.missingPpeCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(
              title: 'PPE ที่ขาดบ่อย',
              subtitle: 'ใช้ประกอบการวางแผนอบรมหรือเตรียมอุปกรณ์',
            ),
            const SizedBox(height: 18),
            if (entries.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 46),
                child: Center(
                  child: Text(
                    'ยังไม่มีข้อมูล PPE ที่ขาด',
                    style: TextStyle(color: AppPalette.mutedInk),
                  ),
                ),
              )
            else
              ...entries.take(5).map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 15),
                      child: Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: AppPalette.amberSoft,
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: const Icon(
                              Icons.construction_outlined,
                              color: AppPalette.amber,
                              size: 19,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              Ppe.thai(entry.key),
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          Text(
                            '${entry.value} ครั้ง',
                            style: const TextStyle(
                              color: AppPalette.mutedInk,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
