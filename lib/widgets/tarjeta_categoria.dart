import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:norday_flutter_core/norday_flutter_core.dart';

/// Los tres estados, literales y no un enum: es exactamente lo que viaja en
/// `PreferenciaCategoria.estado`, y duplicarlo en un enum paralelo sólo
/// añadiría una traducción que mantener en los dos sentidos.
const String estadoQuiere = 'QUIERE';
const String estadoNeutral = 'NEUTRAL';
const String estadoNoQuiere = 'NO_QUIERE';

/// Una categoría con su selector de interés.
///
/// La comparten el Onboarding y el Perfil, que la pintan igual pero hacen
/// cosas distintas con el cambio: el primero acumula y guarda al final, el
/// segundo guarda al momento. Por eso este widget no decide nada — recibe el
/// estado y avisa del cambio, y quien lo use verá qué hace con él.
///
/// Toma los datos sueltos y no un modelo porque las dos pantallas parten de
/// tipos distintos: `CategoriaConocimiento` en el Onboarding (el catálogo) y
/// `PreferenciaCategoria` en el Perfil (lo ya elegido).
class TarjetaCategoria extends StatelessWidget {
  final String nombre;
  final String? icono;
  final String? color;
  final String estado;
  final ValueChanged<String> onCambio;

  const TarjetaCategoria({
    super.key,
    required this.nombre,
    required this.estado,
    required this.onCambio,
    this.icono,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final t = tokens(context);
    final colorCategoria = colorDeCategoria(color, t);
    final colorEstado = switch (estado) {
      estadoQuiere => t.success,
      estadoNoQuiere => Theme.of(context).colorScheme.error,
      _ => t.textMuted,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colorCategoria.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: iconoDeCategoria(icono, colorCategoria),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    nombre,
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700, color: t.text),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<String>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: estadoQuiere, label: Text('Sí')),
                  ButtonSegment(value: estadoNeutral, label: Text('Neutral')),
                  ButtonSegment(value: estadoNoQuiere, label: Text('No')),
                ],
                selected: {estado},
                onSelectionChanged: (seleccion) => onCambio(seleccion.first),
                style: SegmentedButton.styleFrom(
                  foregroundColor: t.textMuted,
                  selectedForegroundColor: colorEstado,
                  selectedBackgroundColor: colorEstado.withValues(alpha: 0.18),
                  side: BorderSide(color: t.textMuted.withValues(alpha: 0.3)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// El backend manda el color como hex (`#27C76F`). Si viene a null o no
/// parsea, el color de la paleta equipada: nunca una tarjeta sin color.
Color colorDeCategoria(String? hex, TokensContextuales t) {
  if (hex == null) return t.primary;
  final limpio = hex.replaceFirst('#', '').trim();
  final valor = int.tryParse(limpio.length == 6 ? 'FF$limpio' : limpio, radix: 16);
  return valor == null ? t.primary : Color(valor);
}

/// El icono llega como emoji, igual que en las categorías de Hábitos, no como
/// nombre de Lucide: se pinta tal cual, como texto.
///
/// El respaldo es [LucideIcons.shapes], y cubre dos casos: que no venga nada,
/// y que venga algo que claramente no es un emoji —todo ASCII, por ejemplo un
/// nombre suelto—. Mejor un icono genérico que una palabra descolocada dentro
/// del recuadro de color.
Widget iconoDeCategoria(String? icono, Color color) {
  final limpio = icono?.trim() ?? '';
  final esEmoji = limpio.isNotEmpty && limpio.runes.any((r) => r > 0x7F);
  return esEmoji
      ? Text(limpio, style: const TextStyle(fontSize: 20))
      : Icon(LucideIcons.shapes, size: 20, color: color);
}
