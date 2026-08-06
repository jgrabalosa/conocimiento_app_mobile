import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:norday_flutter_core/norday_flutter_core.dart';

import '../models/pildora_preview.dart';
import '../screens/detalle_pildora_screen.dart';
import '../services/api_service_conocimiento.dart';
import 'error_carga.dart';
import 'tarjeta_pildora.dart';

/// El bucle: pide la siguiente píldora, la muestra, y en cuanto el usuario
/// decide vuelve a pedir. Aquí está toda la red; [TarjetaPildora] no sabe nada
/// de esto.
class BuclePildoras extends StatefulWidget {
  const BuclePildoras({super.key});

  @override
  State<BuclePildoras> createState() => _BuclePildorasState();
}

class _BuclePildorasState extends State<BuclePildoras> {
  PildoraPreview? _actual;
  bool _cargando = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _cargarSiguiente();
  }

  Future<void> _cargarSiguiente() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final siguiente = await ApiServiceConocimiento.getSiguientePildora();
      if (!mounted) return;
      setState(() {
        // `pildora` a null es "no queda nada"; el "aún no ha llegado" lo
        // cubre `_cargando`, que es por lo que aquí no hace falta mirar
        // `hayContenido`.
        _actual = siguiente.pildora;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _cargando = false;
      });
    }
  }

  Future<void> _confirmarMatch() async {
    final pildora = _actual;
    if (pildora == null) return;

    setState(() => _cargando = true);
    try {
      final detalle = await ApiServiceConocimiento.match(pildora.pildoraId);
      if (!mounted) return;
      // Push y no replace: desde el detalle se vuelve al bucle.
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DetallePildoraScreen(detalle: detalle)),
      );
      if (!mounted) return;
      // Y al volver, la siguiente: quedarse en la píldora ya leída sería un
      // callejón sin salida.
      await _cargarSiguiente();
    } catch (e) {
      if (!mounted) return;
      // Se vuelve a pintar la misma píldora, centrada otra vez: pasar por el
      // spinner destruye el estado de la tarjeta que ya se había ido.
      setState(() => _cargando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(MensajesError.de(context, e,
              generico: 'No se pudo abrir la píldora.')),
        ),
      );
    }
  }

  Future<void> _confirmarDescarte() async {
    final pildora = _actual;
    if (pildora == null) return;

    setState(() => _cargando = true);
    try {
      await ApiServiceConocimiento.descartar(pildora.pildoraId);
    } catch (_) {
      // Que no se registre el descarte no debe cortar el bucle: lo peor que
      // pasa es que esta píldora le vuelva a salir más adelante.
    }
    if (!mounted) return;
    await _cargarSiguiente();
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return ErrorCarga(error: _error!, onReintentar: _cargarSiguiente);
    }

    final pildora = _actual;
    if (pildora == null) return const _SinContenido();

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: TarjetaPildora(
        // Que dos píldoras distintas no compartan estado de arrastre.
        key: ValueKey(pildora.pildoraId),
        pildora: pildora,
        onMatch: _confirmarMatch,
        onDescartar: _confirmarDescarte,
      ),
    );
  }
}

/// No queda nada que leer. Sin reintento ni temporizador a propósito: el
/// backend no repone contenido solo, y una rueda girando prometería algo que
/// no va a pasar.
class _SinContenido extends StatelessWidget {
  const _SinContenido();

  @override
  Widget build(BuildContext context) {
    final t = tokens(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.coffee, size: 48, color: t.textMuted),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Has visto todo por ahora.',
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w700, color: t.text),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Vuelve más tarde para más píldoras.',
              textAlign: TextAlign.center,
              style: TextStyle(color: t.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
