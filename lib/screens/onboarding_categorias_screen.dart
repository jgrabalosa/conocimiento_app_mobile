import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:norday_flutter_core/norday_flutter_core.dart';

import '../main.dart';
import '../models/categoria_conocimiento.dart';
import '../models/preferencia_categoria.dart';
import '../services/api_service_conocimiento.dart';
import '../widgets/error_carga.dart';

/// Los tres estados, literales y no un enum: es exactamente lo que viaja en
/// `PreferenciaCategoria.estado`, y duplicarlo en un enum paralelo sólo
/// añadiría una traducción que mantener en los dos sentidos.
const String _quiere = 'QUIERE';
const String _neutral = 'NEUTRAL';
const String _noQuiere = 'NO_QUIERE';

/// Primera pantalla de la app: el usuario dice de qué quiere recibir píldoras.
///
/// Se parte de `getCategorias()` —el catálogo completo, con su `orden`— y no
/// de `getPreferencias()`, porque aquí se empieza de cero visualmente: todo
/// arranca en NEUTRAL. Por construcción de `PortalConocimiento` nunca se
/// llega aquí con preferencias ya elegidas.
class OnboardingCategoriasScreen extends StatefulWidget {
  /// Punto de apoyo para los tests: `ApiServiceCore.cliente` es `final`, así
  /// que no hay dónde meter un cliente falso sin tocar el paquete. En
  /// producción nadie pasa esto.
  final Future<List<CategoriaConocimiento>> Function()? cargarCategorias;

  const OnboardingCategoriasScreen({super.key, this.cargarCategorias});

  @override
  State<OnboardingCategoriasScreen> createState() =>
      _OnboardingCategoriasScreenState();
}

class _OnboardingCategoriasScreenState extends State<OnboardingCategoriasScreen> {
  late Future<List<CategoriaConocimiento>> _futuro;

  /// Sólo lo que el usuario ha tocado. Lo que no está aquí es NEUTRAL, así no
  /// hay que inicializar el mapa desde dentro del `FutureBuilder`.
  final Map<int, String> _estados = {};

  bool _guardando = false;

  Future<List<CategoriaConocimiento>> _cargar() =>
      (widget.cargarCategorias ?? ApiServiceConocimiento.getCategorias)();

  @override
  void initState() {
    super.initState();
    _futuro = _cargar();
  }

  void _reintentar() {
    setState(() => _futuro = _cargar());
  }

  String _estadoDe(int categoriaId) => _estados[categoriaId] ?? _neutral;

  /// La misma regla que aplica el backend (400 si no queda ninguna en
  /// QUIERE), sólo que aquí antes de llamar: no hace falta gastar una petición
  /// para descubrir algo que ya se sabe.
  bool get _hayAlgunQuiere => _estados.containsValue(_quiere);

  Future<void> _continuar(List<CategoriaConocimiento> categorias) async {
    setState(() => _guardando = true);
    try {
      await ApiServiceConocimiento.actualizarPreferencias([
        for (final c in categorias)
          PreferenciaCategoria(
            categoriaId: c.categoriaId,
            nombre: c.nombre,
            icono: c.icono,
            color: c.color,
            estado: _estadoDe(c.categoriaId),
          ),
      ]);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const PlaceholderHome()),
      );
    } catch (e) {
      if (!mounted) return;
      // La pantalla se queda como estaba: lo que el usuario ya había marcado
      // sigue ahí, sólo falló el guardado.
      setState(() => _guardando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(MensajesError.de(context, e,
              generico: 'No se pudieron guardar tus intereses.')),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<List<CategoriaConocimiento>>(
          future: _futuro,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return ErrorCarga(error: snapshot.error!, onReintentar: _reintentar);
            }
            return _contenido(snapshot.data!);
          },
        ),
      ),
    );
  }

  Widget _contenido(List<CategoriaConocimiento> categorias) {
    final t = tokens(context);
    final l = NordayCoreLocalizations.of(context)!;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '¿Qué te interesa?',
                style: TextStyle(
                    fontSize: 24, fontWeight: FontWeight.w800, color: t.text),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Elige de qué quieres recibir píldoras. Marca al menos una '
                'categoría como «Sí»; podrás cambiarlo más adelante.',
                style: TextStyle(fontSize: 13, color: t.textMuted, height: 1.4),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            itemCount: categorias.length,
            itemBuilder: (context, i) => _tarjeta(categorias[i], t),
          ),
        ),
        _barraInferior(categorias, t, l),
      ],
    );
  }

  Widget _tarjeta(CategoriaConocimiento c, TokensContextuales t) {
    final color = _colorDe(c.color, t);
    final estado = _estadoDe(c.categoriaId);
    final colorEstado = switch (estado) {
      _quiere => t.success,
      _noQuiere => Theme.of(context).colorScheme.error,
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
                    color: color.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: _iconoDe(c.icono, color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    c.nombre,
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
                  ButtonSegment(value: _quiere, label: Text('Sí')),
                  ButtonSegment(value: _neutral, label: Text('Neutral')),
                  ButtonSegment(value: _noQuiere, label: Text('No')),
                ],
                selected: {estado},
                onSelectionChanged: (seleccion) => setState(
                    () => _estados[c.categoriaId] = seleccion.first),
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

  Widget _barraInferior(List<CategoriaConocimiento> categorias,
      TokensContextuales t, NordayCoreLocalizations l) {
    final puede = _hayAlgunQuiere && !_guardando;

    return Container(
      color: t.surface,
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!_hayAlgunQuiere)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Text(
                'Marca «Sí» en al menos una categoría para continuar.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: t.textMuted),
              ),
            ),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: puede ? () => _continuar(categorias) : null,
              child: _guardando
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(l.comunContinuar),
            ),
          ),
        ],
      ),
    );
  }
}

/// El backend manda el color como hex (`#27C76F`). Si viene a null o no
/// parsea, el color de la paleta equipada: nunca una tarjeta sin color.
Color _colorDe(String? hex, TokensContextuales t) {
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
Widget _iconoDe(String? icono, Color color) {
  final limpio = icono?.trim() ?? '';
  final esEmoji = limpio.isNotEmpty && limpio.runes.any((r) => r > 0x7F);
  return esEmoji
      ? Text(limpio, style: const TextStyle(fontSize: 20))
      : Icon(LucideIcons.shapes, size: 20, color: color);
}
