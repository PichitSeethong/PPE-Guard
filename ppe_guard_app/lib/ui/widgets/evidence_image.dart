import 'package:flutter/material.dart';

import '../../core/constants/app_palette.dart';

/// Displays the complete evidence frame without assuming a camera aspect ratio.
/// The reserved height stays bounded while the image loads or fails to load.
class EvidenceImage extends StatelessWidget {
  const EvidenceImage({
    super.key,
    required this.image,
    required this.height,
    this.allowExpand = true,
    this.cornerRadius = 24,
  });

  final ImageProvider<Object>? image;
  final double height;
  final bool allowExpand;
  final double cornerRadius;

  void _openImage(BuildContext context) {
    final provider = image;
    if (provider == null) return;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog.fullscreen(
        backgroundColor: AppPalette.canvas,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text('ภาพหลักฐาน',
                          style: TextStyle(fontWeight: FontWeight.w800)),
                    ),
                    IconButton(
                      tooltip: 'ปิดภาพ',
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: InteractiveViewer(
                  minScale: 1,
                  maxScale: 4,
                  child: SizedBox.expand(child: _image(provider)),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'เลื่อนล้อเมาส์หรือใช้สองนิ้วเพื่อซูม แล้วลากเพื่อเลื่อนภาพ',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppPalette.mutedInk, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _image(ImageProvider<Object> provider) => Image(
        key: ValueKey(provider),
        image: provider,
        // cover would crop evidence; fill would distort the original geometry.
        fit: BoxFit.contain,
        alignment: Alignment.center,
        width: double.infinity,
        height: double.infinity,
        gaplessPlayback: false,
        semanticLabel: 'ภาพหลักฐานจากกล้อง',
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded || frame != null) return child;
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        },
        errorBuilder: (_, __, ___) => const _EvidencePlaceholder(
          message: 'ไม่สามารถแสดงรูปหลักฐานได้',
          icon: Icons.broken_image_outlined,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final provider = image;
    final expandable = allowExpand && provider != null;
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Material(
        color: AppPalette.surfaceSoft,
        borderRadius: BorderRadius.circular(cornerRadius),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (provider == null)
              const _EvidencePlaceholder(
                message: 'ไม่มีรูปหลักฐาน',
                icon: Icons.image_not_supported_outlined,
              )
            else
              _image(provider),
            if (expandable)
              Positioned(
                top: 8,
                right: 8,
                child: Material(
                  color: AppPalette.surface,
                  shape: const CircleBorder(),
                  child: IconButton(
                    tooltip: 'ขยายภาพหลักฐาน',
                    onPressed: () => _openImage(context),
                    icon: const Icon(Icons.fullscreen_rounded),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _EvidencePlaceholder extends StatelessWidget {
  const _EvidencePlaceholder({required this.message, required this.icon});

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: AppPalette.mutedInk, size: 32),
              const SizedBox(height: 8),
              Text(message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppPalette.mutedInk)),
            ],
          ),
        ),
      );
}
