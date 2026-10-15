import 'package:flutter/material.dart';

import '../../core/constants/app_palette.dart';
import '../../services/api_client.dart';
import '../../services/auth_store.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key, this.force = false});

  final bool force;

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  bool _hideCurrent = true;
  bool _hideNext = true;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _busy) return;
    setState(() => _busy = true);
    try {
      await AuthStore.instance.changePassword(currentPassword: _current.text, newPassword: _next.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('เปลี่ยนรหัสผ่านเรียบร้อยแล้ว')));
      if (!widget.force) Navigator.of(context).pop();
    } on ApiException catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(22, 32, 22, 28),
        children: [
          Icon(widget.force ? Icons.lock_reset_rounded : Icons.password_rounded, size: 54, color: AppPalette.navy),
          const SizedBox(height: 18),
          Text(widget.force ? 'เปลี่ยนรหัสผ่านก่อนเริ่มใช้งาน' : 'เปลี่ยนรหัสผ่าน', textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppPalette.ink)),
          const SizedBox(height: 8),
          Text(widget.force ? 'บัญชีนี้ใช้รหัสผ่านชั่วคราว โปรดตั้งรหัสผ่านส่วนตัวก่อนเข้าใช้งานระบบ' : 'ตั้งรหัสผ่านใหม่ที่มีความยาวอย่างน้อย 8 ตัวอักษร', textAlign: TextAlign.center, style: const TextStyle(color: AppPalette.mutedInk, height: 1.4)),
          const SizedBox(height: 28),
          TextFormField(
            controller: _current,
            obscureText: _hideCurrent,
            decoration: InputDecoration(labelText: 'รหัสผ่านปัจจุบัน', suffixIcon: IconButton(onPressed: () => setState(() => _hideCurrent = !_hideCurrent), icon: Icon(_hideCurrent ? Icons.visibility_outlined : Icons.visibility_off_outlined))),
            validator: (value) => (value ?? '').isEmpty ? 'กรุณากรอกรหัสผ่านปัจจุบัน' : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _next,
            obscureText: _hideNext,
            decoration: InputDecoration(labelText: 'รหัสผ่านใหม่', helperText: 'อย่างน้อย 8 ตัวอักษร', suffixIcon: IconButton(onPressed: () => setState(() => _hideNext = !_hideNext), icon: Icon(_hideNext ? Icons.visibility_outlined : Icons.visibility_off_outlined))),
            validator: (value) => (value ?? '').length < 8 ? 'รหัสผ่านต้องมีอย่างน้อย 8 ตัวอักษร' : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _confirm,
            obscureText: _hideNext,
            decoration: const InputDecoration(labelText: 'ยืนยันรหัสผ่านใหม่'),
            validator: (value) => value != _next.text ? 'รหัสผ่านไม่ตรงกัน' : null,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(onPressed: _busy ? null : _submit, icon: _busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.check_rounded), label: Text(_busy ? 'กำลังบันทึก...' : 'บันทึกรหัสผ่านใหม่')),
        ],
      ),
    );
    if (widget.force) return Scaffold(body: SafeArea(child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 460), child: content))));
    return Scaffold(appBar: AppBar(title: const Text('เปลี่ยนรหัสผ่าน')), body: SafeArea(child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 520), child: content))));
  }
}
