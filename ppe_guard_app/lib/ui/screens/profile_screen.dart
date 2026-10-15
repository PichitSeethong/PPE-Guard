import 'package:flutter/material.dart';

import '../../core/config/server_config.dart';
import '../../core/constants/app_palette.dart';
import '../../services/auth_store.dart';
import 'change_password_screen.dart';
import 'system_health_screen.dart';
import 'user_management_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ValueListenableBuilder(
        valueListenable: AuthStore.instance.user,
        builder: (context, user, _) {
          if (user == null) return const SizedBox.shrink();
          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 36),
            children: [
              const Text('โปรไฟล์และระบบ', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppPalette.ink)),
              const SizedBox(height: 4),
              const Text('ข้อมูลบัญชี สิทธิ์ และการเชื่อมต่อ Local Server', style: TextStyle(color: AppPalette.mutedInk)),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(children: [
                    Container(width: 62, height: 62, decoration: BoxDecoration(color: AppPalette.blueSoft, borderRadius: BorderRadius.circular(20)), child: const Icon(Icons.person_outline_rounded, size: 32, color: AppPalette.navy)),
                    const SizedBox(width: 16),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(user.displayName.isEmpty ? user.username : user.displayName, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 4),
                      Text('@${user.username}', style: const TextStyle(color: AppPalette.mutedInk)),
                      const SizedBox(height: 8),
                      Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: AppPalette.greenSoft, borderRadius: BorderRadius.circular(99)), child: Text(user.roleThai, style: const TextStyle(color: AppPalette.green, fontSize: 12, fontWeight: FontWeight.w800))),
                    ])),
                  ]),
                ),
              ),
              const SizedBox(height: 14),
              Card(
                child: Column(children: [
                  _Item(icon: Icons.business_outlined, label: 'หน่วยงาน', value: user.department),
                  const Divider(),
                  _Item(icon: Icons.dns_outlined, label: 'Local Server', value: ServerConfig.baseUrl),
                  const Divider(),
                  _Item(icon: Icons.storage_outlined, label: 'การจัดเก็บข้อมูล', value: 'ฐานข้อมูลและรูปหลักฐานอยู่ใน Server ของไซต์งาน'),
                ]),
              ),
              const SizedBox(height: 18),
              Card(
                child: Column(children: [
                  ListTile(leading: const Icon(Icons.password_rounded, color: AppPalette.navy), title: const Text('เปลี่ยนรหัสผ่าน'), subtitle: const Text('เปลี่ยนรหัสผ่านของบัญชีนี้'), trailing: const Icon(Icons.chevron_right_rounded), onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ChangePasswordScreen()))),
                  const Divider(height: 1),
                  ListTile(leading: const Icon(Icons.monitor_heart_outlined, color: AppPalette.teal), title: const Text('สุขภาพระบบ'), subtitle: const Text('สถานะ Server พื้นที่เก็บข้อมูล และ Backup'), trailing: const Icon(Icons.chevron_right_rounded), onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SystemHealthScreen()))),
                  if (user.isAdmin) ...[
                    const Divider(height: 1),
                    ListTile(leading: const Icon(Icons.manage_accounts_outlined, color: AppPalette.navy), title: const Text('จัดการผู้ใช้'), subtitle: const Text('เพิ่ม แก้ไขสิทธิ์ ปิดบัญชี และรีเซ็ตรหัสผ่าน'), trailing: const Icon(Icons.chevron_right_rounded), onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const UserManagementScreen()))),
                  ],
                ]),
              ),
              const SizedBox(height: 22),
              FilledButton.tonalIcon(onPressed: () async => AuthStore.instance.signOut(), icon: const Icon(Icons.logout_rounded), label: const Text('ออกจากระบบ')),
              const SizedBox(height: 12),
              const Text('PPE Guard Site Ready • Local Server Edition\nข้อมูลจัดเก็บภายใน Server ของไซต์งาน', textAlign: TextAlign.center, style: TextStyle(color: AppPalette.mutedInk, fontSize: 12, height: 1.5)),
            ],
          );
        },
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.all(16), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: AppPalette.navy, size: 21), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize: 12, color: AppPalette.mutedInk, fontWeight: FontWeight.w700)), const SizedBox(height: 3), Text(value, style: const TextStyle(fontWeight: FontWeight.w800))]))]));
}
