import 'package:flutter/material.dart';

import '../../core/constants/app_palette.dart';

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off_outlined, color: AppPalette.red, size: 46),
                  const SizedBox(height: 14),
                  const Text('ไม่สามารถแสดงข้อมูลได้', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppPalette.mutedInk)),
                  const SizedBox(height: 18),
                  OutlinedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('ลองอีกครั้ง')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
