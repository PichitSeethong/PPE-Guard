import 'package:flutter/material.dart';

import '../../core/constants/app_palette.dart';
import '../../core/utils/date_time_formatter.dart';
import '../../models/app_user.dart';
import '../../models/audit_log.dart';
import '../../repositories/user_repository.dart';
import '../../services/api_client.dart';
import '../../services/auth_store.dart';
import '../../services/refresh_signal.dart';
import '../widgets/async_state.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<AppUser>> _usersFuture;
  late Future<List<AuditLog>> _auditFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() { if (mounted) setState(() {}); });
    _usersFuture = UserRepository.instance.list();
    _auditFuture = UserRepository.instance.auditLogs();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    final users = UserRepository.instance.list();
    final audit = UserRepository.instance.auditLogs();
    setState(() {
      _usersFuture = users;
      _auditFuture = audit;
    });
    try {
      await Future.wait([users, audit]);
    } catch (_) {}
  }

  Future<void> _createUser() async {
    final data = await showDialog<_CreateUserData>(context: context, builder: (_) => const _CreateUserDialog());
    if (data == null) return;
    try {
      await UserRepository.instance.create(
        username: data.username,
        password: data.password,
        displayName: data.displayName,
        role: data.role,
        department: data.department,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('สร้างบัญชีใหม่แล้ว ผู้ใช้ต้องเปลี่ยนรหัสผ่านเมื่อเข้าใช้ครั้งแรก')));
      await _reload();
    } on ApiException catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  Future<void> _editUser(AppUser target) async {
    final data = await showDialog<_EditUserData>(context: context, builder: (_) => _EditUserDialog(user: target));
    if (data == null) return;
    try {
      await UserRepository.instance.update(target.id, {
        'display_name': data.displayName,
        'department': data.department,
        'role': data.role,
        'is_active': data.isActive,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('อัปเดตบัญชีผู้ใช้แล้ว')));
      await _reload();
    } on ApiException catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  Future<void> _resetPassword(AppUser target) async {
    final password = await showDialog<String>(context: context, builder: (_) => _ResetPasswordDialog(username: target.username));
    if (password == null) return;
    try {
      await UserRepository.instance.resetPassword(target.id, password);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('รีเซ็ตรหัสผ่าน ${target.username} แล้ว ผู้ใช้ต้องเปลี่ยนรหัสเมื่อเข้าใช้')));
      await _reload();
    } on ApiException catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = AuthStore.instance.user.value;
    if (current == null || !current.isAdmin) {
      return const Scaffold(body: Center(child: Text('เฉพาะผู้ดูแลระบบเท่านั้นที่เข้าถึงหน้านี้ได้')));
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('จัดการผู้ใช้'),
        actions: [IconButton(onPressed: _reload, tooltip: 'รีเฟรช', icon: const Icon(Icons.refresh_rounded))],
        bottom: TabBar(controller: _tabController, tabs: const [Tab(text: 'บัญชีผู้ใช้'), Tab(text: 'บันทึกการดำเนินการ')]),
      ),
      floatingActionButton: _tabController.index == 0 ? FloatingActionButton.extended(onPressed: _createUser, icon: const Icon(Icons.person_add_alt_1_rounded), label: const Text('เพิ่มผู้ใช้')) : null,
      body: TabBarView(
        controller: _tabController,
        children: [
          FutureBuilder<List<AppUser>>(
            future: _usersFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) return const LoadingView();
              if (snapshot.hasError) return ErrorView(message: snapshot.error.toString(), onRetry: _reload);
              final users = snapshot.data ?? const <AppUser>[];
              return RefreshIndicator(
                onRefresh: _reload,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 96),
                  itemCount: users.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return Card(
                      child: ListTile(
                        onTap: () => _editUser(user),
                        leading: CircleAvatar(backgroundColor: user.isActive ? AppPalette.blueSoft : AppPalette.surfaceSoft, foregroundColor: user.isActive ? AppPalette.navy : AppPalette.mutedInk, child: Icon(user.role == 'admin' ? Icons.admin_panel_settings_outlined : user.role == 'supervisor' ? Icons.supervisor_account_outlined : Icons.visibility_outlined)),
                        title: Text(user.displayName.isEmpty ? user.username : user.displayName, style: const TextStyle(fontWeight: FontWeight.w900)),
                        subtitle: Text('@${user.username} • ${user.roleThai}\n${user.department}${user.mustChangePassword ? ' • รอเปลี่ยนรหัส' : ''}', maxLines: 2),
                        isThreeLine: true,
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'edit') _editUser(user);
                            if (value == 'reset') _resetPassword(user);
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit_outlined), title: Text('แก้ไขสิทธิ์และข้อมูล'), contentPadding: EdgeInsets.zero)),
                            PopupMenuItem(value: 'reset', child: ListTile(leading: Icon(Icons.lock_reset_outlined), title: Text('รีเซ็ตรหัสผ่าน'), contentPadding: EdgeInsets.zero)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
          FutureBuilder<List<AuditLog>>(
            future: _auditFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) return const LoadingView();
              if (snapshot.hasError) return ErrorView(message: snapshot.error.toString(), onRetry: _reload);
              final logs = snapshot.data ?? const <AuditLog>[];
              if (logs.isEmpty) return const Center(child: Text('ยังไม่มีบันทึกการดำเนินการ'));
              return RefreshIndicator(
                onRefresh: _reload,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
                  itemCount: logs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, index) {
                    final log = logs[index];
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(_actionThai(log.action), style: const TextStyle(fontWeight: FontWeight.w900)),
                          const SizedBox(height: 5),
                          Text('โดย ${log.actorUsername ?? '-'} • ${DateTimeFormatter.dateTime(log.createdAt)}', style: const TextStyle(color: AppPalette.mutedInk, fontSize: 12)),
                          if (log.detail.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(_detailText(log.detail), style: const TextStyle(color: AppPalette.mutedInk, fontSize: 12)),
                          ],
                        ]),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  static String _actionThai(String action) {
    switch (action) {
      case 'create_user': return 'สร้างบัญชีผู้ใช้';
      case 'update_user': return 'แก้ไขบัญชีผู้ใช้';
      case 'reset_password': return 'รีเซ็ตรหัสผ่าน';
      case 'change_password': return 'เปลี่ยนรหัสผ่านของตนเอง';
      case 'acknowledge_event': return 'รับทราบเหตุการณ์ PPE';
      case 'create_backup': return 'สร้างไฟล์สำรองข้อมูล';
      case 'export_events_csv': return 'ส่งออกรายงาน CSV';
      case 'login': return 'เข้าสู่ระบบ';
      default: return action;
    }
  }

  static String _detailText(Map<String, dynamic> detail) => detail.entries.map((entry) => '${entry.key}: ${entry.value}').join(' • ');
}

class _CreateUserData {
  const _CreateUserData({required this.username, required this.password, required this.displayName, required this.role, required this.department});
  final String username;
  final String password;
  final String displayName;
  final String role;
  final String department;
}

class _CreateUserDialog extends StatefulWidget {
  const _CreateUserDialog();
  @override
  State<_CreateUserDialog> createState() => _CreateUserDialogState();
}

class _CreateUserDialogState extends State<_CreateUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  final _department = TextEditingController(text: 'Safety Department');
  String _role = 'viewer';
  bool _hide = true;
  @override
  void dispose() { _username.dispose(); _password.dispose(); _name.dispose(); _department.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('เพิ่มบัญชีผู้ใช้'),
    content: SizedBox(width: 460, child: SingleChildScrollView(child: Form(key: _formKey, child: Column(mainAxisSize: MainAxisSize.min, children: [
      TextFormField(controller: _name, decoration: const InputDecoration(labelText: 'ชื่อที่แสดง'), validator: (v) => (v ?? '').trim().isEmpty ? 'กรุณากรอกชื่อ' : null),
      const SizedBox(height: 12),
      TextFormField(controller: _username, decoration: const InputDecoration(labelText: 'Username', helperText: 'ใช้ a-z, 0-9, . _ -'), validator: (v) => (v ?? '').trim().length < 3 ? 'อย่างน้อย 3 ตัวอักษร' : null),
      const SizedBox(height: 12),
      TextFormField(controller: _password, obscureText: _hide, decoration: InputDecoration(labelText: 'รหัสผ่านชั่วคราว', helperText: 'ผู้ใช้ต้องเปลี่ยนเมื่อเข้าใช้ครั้งแรก', suffixIcon: IconButton(onPressed: () => setState(() => _hide = !_hide), icon: Icon(_hide ? Icons.visibility_outlined : Icons.visibility_off_outlined))), validator: (v) => (v ?? '').length < 8 ? 'อย่างน้อย 8 ตัวอักษร' : null),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(value: _role, decoration: const InputDecoration(labelText: 'บทบาท'), items: const [DropdownMenuItem(value: 'admin', child: Text('จป. / ผู้ดูแลระบบ')), DropdownMenuItem(value: 'supervisor', child: Text('หัวหน้างาน')), DropdownMenuItem(value: 'viewer', child: Text('ผู้ดูข้อมูล'))], onChanged: (value) => setState(() => _role = value ?? 'viewer')),
      const SizedBox(height: 12),
      TextFormField(controller: _department, decoration: const InputDecoration(labelText: 'หน่วยงาน'), validator: (v) => (v ?? '').trim().isEmpty ? 'กรุณากรอกหน่วยงาน' : null),
    ])))),
    actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('ยกเลิก')), FilledButton(onPressed: () { if (_formKey.currentState!.validate()) Navigator.pop(context, _CreateUserData(username: _username.text.trim(), password: _password.text, displayName: _name.text.trim(), role: _role, department: _department.text.trim())); }, child: const Text('สร้างบัญชี'))],
  );
}

class _EditUserData {
  const _EditUserData({required this.displayName, required this.department, required this.role, required this.isActive});
  final String displayName;
  final String department;
  final String role;
  final bool isActive;
}

class _EditUserDialog extends StatefulWidget {
  const _EditUserDialog({required this.user});
  final AppUser user;
  @override
  State<_EditUserDialog> createState() => _EditUserDialogState();
}

class _EditUserDialogState extends State<_EditUserDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _department;
  late String _role;
  late bool _active;
  @override void initState() { super.initState(); _name = TextEditingController(text: widget.user.displayName); _department = TextEditingController(text: widget.user.department); _role = widget.user.role; _active = widget.user.isActive; }
  @override void dispose() { _name.dispose(); _department.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text('แก้ไข ${widget.user.username}'),
    content: SizedBox(width: 440, child: SingleChildScrollView(child: Form(key: _formKey, child: Column(mainAxisSize: MainAxisSize.min, children: [
      TextFormField(controller: _name, decoration: const InputDecoration(labelText: 'ชื่อที่แสดง'), validator: (v) => (v ?? '').trim().isEmpty ? 'กรุณากรอกชื่อ' : null),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(value: _role, decoration: const InputDecoration(labelText: 'บทบาท'), items: const [DropdownMenuItem(value: 'admin', child: Text('จป. / ผู้ดูแลระบบ')), DropdownMenuItem(value: 'supervisor', child: Text('หัวหน้างาน')), DropdownMenuItem(value: 'viewer', child: Text('ผู้ดูข้อมูล'))], onChanged: (value) => setState(() => _role = value ?? _role)),
      const SizedBox(height: 12),
      TextFormField(controller: _department, decoration: const InputDecoration(labelText: 'หน่วยงาน'), validator: (v) => (v ?? '').trim().isEmpty ? 'กรุณากรอกหน่วยงาน' : null),
      const SizedBox(height: 12),
      SwitchListTile(value: _active, onChanged: (value) => setState(() => _active = value), contentPadding: EdgeInsets.zero, title: const Text('เปิดใช้งานบัญชี'), subtitle: const Text('ปิดแล้วจะเข้าสู่ระบบไม่ได้ทันที')),
    ])))),
    actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('ยกเลิก')), FilledButton(onPressed: () { if (_formKey.currentState!.validate()) Navigator.pop(context, _EditUserData(displayName: _name.text.trim(), department: _department.text.trim(), role: _role, isActive: _active)); }, child: const Text('บันทึก'))],
  );
}

class _ResetPasswordDialog extends StatefulWidget {
  const _ResetPasswordDialog({required this.username});
  final String username;
  @override
  State<_ResetPasswordDialog> createState() => _ResetPasswordDialogState();
}

class _ResetPasswordDialogState extends State<_ResetPasswordDialog> {
  final _controller = TextEditingController();
  bool _hide = true;
  @override void dispose() { _controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('รีเซ็ตรหัสผ่าน'),
    content: SizedBox(width: 400, child: TextField(controller: _controller, obscureText: _hide, decoration: InputDecoration(labelText: 'รหัสผ่านชั่วคราวสำหรับ ${widget.username}', helperText: 'อย่างน้อย 8 ตัวอักษร', suffixIcon: IconButton(onPressed: () => setState(() => _hide = !_hide), icon: Icon(_hide ? Icons.visibility_outlined : Icons.visibility_off_outlined))))),
    actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('ยกเลิก')), FilledButton(onPressed: () { if (_controller.text.length >= 8) Navigator.pop(context, _controller.text); }, child: const Text('รีเซ็ตรหัส'))],
  );
}
