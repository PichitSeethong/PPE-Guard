import 'package:flutter/material.dart';

import '../../core/constants/app_palette.dart';
import '../../core/constants/ppe.dart';
import '../../models/dashboard_summary.dart';
import '../../repositories/dashboard_repository.dart';
import '../../services/api_client.dart';
import '../../services/refresh_signal.dart';
import '../widgets/async_state.dart';
import '../widgets/evidence_layout.dart';

class EntranceScreen extends StatefulWidget {
  const EntranceScreen({super.key});

  @override
  State<EntranceScreen> createState() => _EntranceScreenState();
}

class _EntranceScreenState extends State<EntranceScreen> {
  late Future<DashboardSummary> _future;

  @override
  void initState() {
    super.initState();
    _future = DashboardRepository.instance.load();
    RefreshSignal.notifier.addListener(_reloadFromSignal);
  }

  @override
  void dispose() { RefreshSignal.notifier.removeListener(_reloadFromSignal); super.dispose(); }
  void _reloadFromSignal() { if (!mounted) return; final next = DashboardRepository.instance.load();
    setState(() {
      _future = next;
    }); }
  Future<void> _refresh() async { final next = DashboardRepository.instance.load(); setState(() {
      _future = next;
    }); try { await next; } catch (_) {} }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('จอจุดตรวจทางเข้า'), actions: [IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh_rounded))]),
    body: FutureBuilder<DashboardSummary>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) return const LoadingView();
        if (snapshot.hasError) return ErrorView(message: snapshot.error.toString(), onRetry: _refresh);
        final event = snapshot.data!.latestEvent;
        if (event == null) return const Center(child: Text('รอข้อมูลจาก reCamera 2002'));
        final safe = event.status == Ppe.safe;
        final color = safe ? AppPalette.green : AppPalette.red;
        final background = safe ? AppPalette.greenSoft : AppPalette.redSoft;
        final message = safe ? 'PPE ครบถ้วน สามารถผ่านจุดตรวจได้' : 'กรุณาสวมอุปกรณ์ให้ครบก่อนเข้าไซต์งาน';
        final relative = event.imageUrl;
        final image = relative == null || relative.isEmpty
            ? null
            : NetworkImage(ApiClient.instance.evidenceUrl(relative));
        return RefreshIndicator(
          onRefresh: _refresh,
          child: EvidenceLayout(
            image: image,
            imageFirstOnMobile: false,
            showMissingImage: false,
            information: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(32), border: Border.all(color: color.withOpacity(.45), width: 2)),
                  child: Column(children: [
                    Icon(safe ? Icons.check_circle_rounded : Icons.cancel_rounded, size: 90, color: color),
                    const SizedBox(height: 18),
                    Text(safe ? 'ผ่านจุดตรวจ' : 'ยังไม่ผ่านจุดตรวจ', textAlign: TextAlign.center, style: TextStyle(fontSize: MediaQuery.sizeOf(context).width < 600 ? 32 : 42, height: 1.1, fontWeight: FontWeight.w900, color: color)),
                    const SizedBox(height: 12),
                    Text(message, textAlign: TextAlign.center, style: TextStyle(fontSize: 20, height: 1.4, color: color)),
                    if (!safe) ...[
                      const SizedBox(height: 22),
                      const Text('อุปกรณ์ที่ขาด', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 10),
                      Wrap(alignment: WrapAlignment.center, spacing: 10, runSpacing: 10, children: event.missingPpe.map((item) => Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), decoration: BoxDecoration(color: Colors.white.withOpacity(.75), borderRadius: BorderRadius.circular(99)), child: Text(Ppe.thai(item), style: TextStyle(fontSize: 17, color: color, fontWeight: FontWeight.w900)))).toList()),
                    ],
                  ]),
            ),
          ),
        );
      },
    ),
  );
}
