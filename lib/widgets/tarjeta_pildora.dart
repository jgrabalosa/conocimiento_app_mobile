import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:norday_flutter_core/norday_flutter_core.dart';

import '../models/pildora_preview.dart';

/// Desplazamiento horizontal a partir del cual soltar cuenta como decisión.
/// Por debajo, la tarjeta vuelve al centro.
const double _umbral = 100;

/// Inclinación máxima al arrastrar, en radianes (~2,3°). Es un guiño de que la
/// tarjeta se mueve, no un volteo.
const double _inclinacionMaxima = 0.04;

const Duration _duracionVuelta = Duration(milliseconds: 250);
const Duration _duracionSalida = Duration(milliseconds: 300);

/// La tarjeta del bucle, con swipe. Presentación pura: recibe una píldora y
/// dos callbacks, y no sabe nada de red ni de qué viene después.
///
/// Gesto y botones no son dos caminos distintos: los dos acaban en el mismo
/// `_lanzarFuera`, que anima la tarjeta hacia el lado que toque y sólo
/// entonces dispara el callback. Así la animación es idéntica se llegue por
/// donde se llegue, y un doble disparo es imposible.
///
/// Los botones no son un "por si acaso" del gesto: son la vía garantizada de
/// que el bucle avance aunque el arrastre tenga algún caso raro sin cubrir, y
/// la única forma razonable de probar esto en un test de widget.
class TarjetaPildora extends StatefulWidget {
  final PildoraPreview pildora;
  final VoidCallback onMatch;
  final VoidCallback onDescartar;

  const TarjetaPildora({
    super.key,
    required this.pildora,
    required this.onMatch,
    required this.onDescartar,
  });

  @override
  State<TarjetaPildora> createState() => _TarjetaPildoraState();
}

class _TarjetaPildoraState extends State<TarjetaPildora>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controlador;

  /// Cuánto se ha movido la tarjeta desde el centro. Es la única fuente de
  /// verdad de la posición: la escriben tanto el dedo como la animación.
  double _desplazamiento = 0;
  double _desde = 0;
  double _hasta = 0;

  /// Una tarjeta decide una sola vez. Mientras se va, ni el gesto ni los
  /// botones vuelven a disparar nada.
  bool _decidido = false;

  @override
  void initState() {
    super.initState();
    _controlador = AnimationController(vsync: this, duration: _duracionVuelta)
      ..addListener(() {
        final avance = Curves.easeOut.transform(_controlador.value);
        setState(() => _desplazamiento = _desde + (_hasta - _desde) * avance);
      });
  }

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  void _animarHasta(double destino, Duration duracion, {VoidCallback? alTerminar}) {
    _desde = _desplazamiento;
    _hasta = destino;
    _controlador
      ..duration = duracion
      ..reset();
    _controlador.forward().whenComplete(() {
      if (mounted) alTerminar?.call();
    });
  }

  void _alArrastrar(DragUpdateDetails detalles) {
    if (_decidido) return;
    // Si venía volviendo al centro y el dedo la agarra otra vez, manda el dedo.
    _controlador.stop();
    setState(() => _desplazamiento += detalles.delta.dx);
  }

  void _alSoltar(DragEndDetails detalles) {
    if (_decidido) return;
    if (_desplazamiento.abs() >= _umbral) {
      _lanzarFuera(haciaDerecha: _desplazamiento > 0);
    } else {
      _animarHasta(0, _duracionVuelta);
    }
  }

  /// El único punto de confirmación: derecha es match, izquierda es descarte.
  void _lanzarFuera({required bool haciaDerecha}) {
    if (_decidido) return;
    setState(() => _decidido = true);
    final ancho = MediaQuery.sizeOf(context).width;
    _animarHasta(
      haciaDerecha ? ancho * 1.5 : -ancho * 1.5,
      _duracionSalida,
      alTerminar: haciaDerecha ? widget.onMatch : widget.onDescartar,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = tokens(context);
    // -1 = descarte del todo, 0 = centrada, 1 = match del todo. Vale para la
    // inclinación y para la opacidad del sello a la vez.
    final intencion = (_desplazamiento / _umbral).clamp(-1.0, 1.0);

    return Column(
      children: [
        Expanded(
          child: GestureDetector(
            onPanUpdate: _alArrastrar,
            onPanEnd: _alSoltar,
            child: Transform.translate(
              offset: Offset(_desplazamiento, 0),
              child: Transform.rotate(
                angle: intencion * _inclinacionMaxima,
                child: _tarjeta(t, intencion),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _botones(t),
      ],
    );
  }

  Widget _tarjeta(TokensContextuales t, double intencion) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Stack(
        fit: StackFit.expand,
        children: [
          _fondo(t),
          // El degradado va siempre, haya foto o no: es lo que garantiza que
          // el texto se lea igual sobre una imagen clara que sobre el color
          // de respaldo, sin tener que decidir el color del texto por caso.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.center,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black87],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(
                widget.pildora.previewCorto,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.35,
                ),
              ),
            ),
          ),
          _sello(t, intencion),
        ],
      ),
    );
  }

  /// La imagen, o el color de respaldo. Con el catálogo real casi vacío la
  /// mayoría de píldoras no traerán `imagenUrl`, y una URL rota tampoco debe
  /// dejar la tarjeta en blanco.
  Widget _fondo(TokensContextuales t) {
    final respaldo = ColoredBox(
      color: t.surface2,
      child: Center(
        child: Icon(LucideIcons.bookOpen,
            size: 64, color: t.textMuted.withValues(alpha: 0.35)),
      ),
    );

    final url = widget.pildora.imagenUrl;
    if (url == null || url.isEmpty) return respaldo;

    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (context, error, pila) => respaldo,
      loadingBuilder: (context, hijo, progreso) => progreso == null
          ? hijo
          : ColoredBox(
              color: t.surface2,
              child: const Center(child: CircularProgressIndicator()),
            ),
    );
  }

  /// Insinúa hacia dónde va la cosa mientras se arrastra. Aparece del lado al
  /// que se empuja y se desvanece solo al volver al centro.
  Widget _sello(TokensContextuales t, double intencion) {
    final esMatch = intencion > 0;
    final color = esMatch ? t.success : Theme.of(context).colorScheme.error;

    return Positioned(
      top: AppSpacing.lg,
      left: esMatch ? AppSpacing.lg : null,
      right: esMatch ? null : AppSpacing.lg,
      child: Opacity(
        opacity: intencion.abs(),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.85),
            shape: BoxShape.circle,
          ),
          child: Icon(esMatch ? LucideIcons.check : LucideIcons.x,
              color: Colors.white, size: 28),
        ),
      ),
    );
  }

  Widget _botones(TokensContextuales t) {
    final rojo = Theme.of(context).colorScheme.error;

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _decidido ? null : () => _lanzarFuera(haciaDerecha: false),
            icon: const Icon(LucideIcons.x, size: 18),
            label: const Text('No me interesa'),
            style: OutlinedButton.styleFrom(
              foregroundColor: rojo,
              side: BorderSide(color: rojo.withValues(alpha: 0.5)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _decidido ? null : () => _lanzarFuera(haciaDerecha: true),
            icon: const Icon(LucideIcons.bookOpen, size: 18),
            label: const Text('Ábrela'),
            style: ElevatedButton.styleFrom(
              backgroundColor: t.success,
              padding: const EdgeInsets.symmetric(vertical: 14),
              textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}
