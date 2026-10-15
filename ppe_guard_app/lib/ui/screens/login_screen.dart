import 'package:flutter/material.dart';

import '../../core/constants/app_palette.dart';
import '../../services/api_client.dart';
import '../../services/auth_store.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _password = TextEditingController();

  bool _busy = false;
  bool _hidePassword = true;
  String? _error;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _busy) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await AuthStore.instance.signIn(
        username: _username.text,
        password: _password.text,
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'เข้าสู่ระบบไม่สำเร็จ กรุณาลองใหม่');
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1060),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final splitLayout = constraints.maxWidth >= 760;
                  final brandPanel = _BrandPanel(compact: !splitLayout);
                  final loginCard = _LoginCard(
                    formKey: _formKey,
                    username: _username,
                    password: _password,
                    busy: _busy,
                    error: _error,
                    hidePassword: _hidePassword,
                    onTogglePassword: () {
                      setState(() => _hidePassword = !_hidePassword);
                    },
                    onSubmit: _submit,
                  );

                  if (splitLayout) {
                    return Row(
                      children: [
                        Expanded(child: brandPanel),
                        const SizedBox(width: 32),
                        SizedBox(width: 390, child: loginCard),
                      ],
                    );
                  }

                  return Column(
                    children: [
                      brandPanel,
                      const SizedBox(height: 22),
                      loginCard,
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 360),
      padding: const EdgeInsets.all(34),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppPalette.navy, AppPalette.navyDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.health_and_safety_outlined,
              color: Colors.white,
              size: 34,
            ),
          ),
          const SizedBox(height: 26),
          Text(
            'PPE Guard',
            style: TextStyle(
              color: Colors.white,
              fontSize: compact ? 30 : 42,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ระบบติดตามความพร้อมของอุปกรณ์\n'
            'ป้องกันส่วนบุคคลในไซต์งาน',
            style: TextStyle(
              color: Colors.white.withOpacity(.84),
              fontSize: compact ? 16 : 19,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),
          const _Feature(text: 'ข้อมูลและรูปหลักฐานเก็บใน Server ของไซต์งาน'),
          const SizedBox(height: 10),
          const _Feature(text: 'บันทึกหนึ่งเหตุการณ์ต่อหนึ่ง Session และแจ้งเตือนเมื่อไม่ปลอดภัย'),
          const SizedBox(height: 10),
          const _Feature(text: 'รองรับสิทธิ์ จป. / หัวหน้างาน / ผู้ดูข้อมูล'),
        ],
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  const _Feature({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.check_circle_outline,
          color: Color(0xFFB9E9D2),
          size: 19,
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
        ),
      ],
    );
  }
}

class _LoginCard extends StatelessWidget {
  const _LoginCard({
    required this.formKey,
    required this.username,
    required this.password,
    required this.busy,
    required this.error,
    required this.hidePassword,
    required this.onTogglePassword,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController username;
  final TextEditingController password;
  final bool busy;
  final String? error;
  final bool hidePassword;
  final VoidCallback onTogglePassword;
  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'เข้าสู่ระบบ',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              const Text(
                'ใช้บัญชีที่ จป. หรือผู้ดูแลระบบกำหนดให้',
                style: TextStyle(color: AppPalette.mutedInk),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: username,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'ชื่อผู้ใช้',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'กรอกชื่อผู้ใช้'
                    : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: password,
                obscureText: hidePassword,
                onFieldSubmitted: (_) => onSubmit(),
                decoration: InputDecoration(
                  labelText: 'รหัสผ่าน',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    onPressed: onTogglePassword,
                    icon: Icon(
                      hidePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
                validator: (value) => value == null || value.isEmpty
                    ? 'กรอกรหัสผ่าน'
                    : null,
              ),
              if (error != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppPalette.redSoft,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    error!,
                    style: const TextStyle(
                      color: AppPalette.red,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 22),
              FilledButton.icon(
                onPressed: busy ? null : onSubmit,
                icon: busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.login_rounded),
                label: Text(busy ? 'กำลังตรวจสอบ...' : 'เข้าสู่ระบบ'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
