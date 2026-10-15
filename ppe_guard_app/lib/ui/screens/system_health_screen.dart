import 'package:flutter/material.dart';

import '../../core/constants/app_palette.dart';
import '../../core/utils/date_time_formatter.dart';
import '../../models/system_health.dart';
import '../../repositories/system_repository.dart';
import '../../services/api_client.dart';
import '../../services/auth_store.dart';
import '../widgets/async_state.dart';
import '../widgets/metric_tile.dart';

class SystemHealthScreen extends StatefulWidget {
  const SystemHealthScreen({super.key});

  @override
  State<SystemHealthScreen> createState() => _SystemHealthScreenState();
}

class _SystemHealthScreenState extends State<SystemHealthScreen> {
  late Future<SystemHealth> _future;
  bool _backingUp = false;

  @override
  void initState() {
    super.initState();
    _future = SystemRepository.instance.health();
  }

  Future<void> _refresh() async {
    final next = SystemRepository.instance.health();
    setState(() {
      _future = next;
    });
    try { await next; } catch (_) {}
  }

  Future<void> _backup() async {
    if (_backingUp) return;
    setState(() => _backingUp = true);
    try {
      final result = await SystemRepository.instance.createBackup();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('สร้าง Backup แล้ว: ${result['filename']}')));
      await _refresh();
    } on ApiException catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _backingUp = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = AuthStore.instance.user.value?.isAdmin == true;
    return Scaffold(
      appBar: AppBar(
        title: const Text('สุขภาพระบบ'),
        actions: [IconButton(onPressed: _refresh, tooltip: 'รีเฟรช', icon: const Icon(Icons.refresh_rounded))],
      ),
      body: FutureBuilder<SystemHealth>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) return const LoadingView();
          if (snapshot.hasError) return ErrorView(message: snapshot.error.toString(), onRetry: _refresh);
          final health = snapshot.data!;
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
              children: [
                Card(
                  color: health.freePercent < 10 ? AppPalette.redSoft : AppPalette.greenSoft,
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(children: [
                      Icon(health.freePercent < 10 ? Icons.storage_outlined : Icons.check_circle_outline_rounded, color: health.freePercent < 10 ? AppPalette.red : AppPalette.green, size: 34),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(health.freePercent < 10 ? 'พื้นที่ Server ใกล้เต็ม' : 'Server ทำงานปกติ', style: TextStyle(fontWeight: FontWeight.w900, color: health.freePercent < 10 ? AppPalette.red : AppPalette.green)),
                        const SizedBox(height: 4),
                        Text('ตรวจสอบล่าสุด ${DateTimeFormatter.dateTime(health.checkedAt)}', style: const TextStyle(color: AppPalette.mutedInk, fontSize: 12)),
                      ])),
                    ]),
                  ),
                ),
                const SizedBox(height: 16),
                LayoutBuilder(builder: (context, constraints) {
                  final cols = constraints.maxWidth >= 700 ? 3 : constraints.maxWidth >= 440 ? 2 : 1;
                  final width = (constraints.maxWidth - (cols - 1) * 12) / cols;
                  return Wrap(spacing: 12, runSpacing: 12, children: [
                    SizedBox(width: width, child: MetricTile(label: 'พื้นที่ว่าง', value: '${health.freePercent.toStringAsFixed(1)}%', icon: Icons.storage_outlined, color: health.freePercent < 10 ? AppPalette.red : AppPalette.green, helper: _bytes(health.freeBytes))),
                    SizedBox(width: width, child: MetricTile(label: 'ไฟล์รูปหลักฐาน', value: '${health.evidenceFiles}', icon: Icons.image_outlined, color: AppPalette.navy)),
                    SizedBox(width: width, child: MetricTile(label: 'Backup', value: '${health.backupFiles}', icon: Icons.backup_outlined, color: AppPalette.teal)),
                    SizedBox(width: width, child: MetricTile(label: 'กล้องในระบบ', value: '${health.cameraCount}', icon: Icons.videocam_outlined, color: AppPalette.navy)),
                    SizedBox(width: width, child: MetricTile(label: 'เหตุการณ์สะสม', value: '${health.eventCount}', icon: Icons.layers_outlined, color: AppPalette.amber)),
                    SizedBox(width: width, child: MetricTile(label: 'บัญชีที่ใช้งาน', value: '${health.activeUsers}', icon: Icons.people_outline_rounded, color: AppPalette.teal)),
                  ]);
                }),
                const SizedBox(height: 18),
                Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('ตำแหน่งข้อมูลใน Server', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                  const SizedBox(height: 14),
                  _Line(label: 'Database', value: health.databasePath),
                  const SizedBox(height: 10),
                  _Line(label: 'รูปหลักฐาน', value: health.evidencePath),
                ]))),
                if (isAdmin) ...[
                  const SizedBox(height: 20),
                  FilledButton.icon(onPressed: _backingUp ? null : _backup, icon: _backingUp ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.backup_rounded), label: Text(_backingUp ? 'กำลังสร้าง Backup...' : 'สำรองฐานข้อมูลและรูปตอนนี้')),
                  const SizedBox(height: 8),
                  const Text('ระบบสร้างไฟล์ ZIP โดยไม่ลบข้อมูลต้นฉบับ', textAlign: TextAlign.center, style: TextStyle(color: AppPalette.mutedInk, fontSize: 12)),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  static String _bytes(int value) {
    if (value >= 1024 * 1024 * 1024) return '${(value / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    if (value >= 1024 * 1024) return '${(value / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '$value B';
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(color: AppPalette.mutedInk, fontSize: 12, fontWeight: FontWeight.w700)), const SizedBox(height: 3), SelectableText(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700))]);
}
