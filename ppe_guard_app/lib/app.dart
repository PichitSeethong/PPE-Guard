import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'services/auth_store.dart';
import 'ui/screens/change_password_screen.dart';
import 'ui/screens/login_screen.dart';
import 'ui/shell/app_shell.dart';

class PpeGuardApp extends StatelessWidget {
  const PpeGuardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PPE Guard Site Ready',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: ValueListenableBuilder(
        valueListenable: AuthStore.instance.user,
        builder: (context, user, _) {
          if (user == null) return const LoginScreen();
          if (user.mustChangePassword) return const ChangePasswordScreen(force: true);
          return const AppShell();
        },
      ),
    );
  }
}
