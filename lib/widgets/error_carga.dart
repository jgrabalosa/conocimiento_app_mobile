import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:norday_flutter_core/norday_flutter_core.dart';

/// Estado de error de una carga inicial, con botón de reintentar.
///
/// Lo usan el portal y el onboarding: los dos arrancan pidiendo algo al
/// backend y ninguno de los dos puede dejar al usuario girando una rueda
/// infinita si no hay red.
///
/// El texto sale de [MensajesError], no del cuerpo crudo del backend.
class ErrorCarga extends StatelessWidget {
  final Object error;
  final VoidCallback onReintentar;

  const ErrorCarga({super.key, required this.error, required this.onReintentar});

  @override
  Widget build(BuildContext context) {
    final t = tokens(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.cloudOff, size: 48, color: t.textMuted),
            const SizedBox(height: AppSpacing.md),
            Text(
              MensajesError.de(context, error),
              textAlign: TextAlign.center,
              style: TextStyle(color: t.textMuted, fontSize: 14),
            ),
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton.icon(
              onPressed: onReintentar,
              icon: const Icon(LucideIcons.rotateCw, size: 16),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
