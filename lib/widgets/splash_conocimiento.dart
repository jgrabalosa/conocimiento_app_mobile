import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Splash provisional, solo wordmark sobre Azul Noche.
///
/// No usa `SplashGenerico` del motor porque aquel exige un `rutaImagen` y lo
/// mete tal cual en `Image.asset`: sin logo propio todavía, cualquier valor
/// que le pasáramos reventaría en tiempo de ejecución. Esto es lo mismo menos
/// el símbolo, con la misma mecánica de duración mínima y tarea.
///
/// En Fase 4, cuando haya branding, esto se borra y se vuelve a
/// `SplashGenerico` con el símbolo de la app.
class SplashConocimiento<T> extends StatefulWidget {
  final Color colorFondo;
  final Duration duracionMinima;
  final Future<T> Function() tarea;
  final void Function(BuildContext context, T resultado) onListo;
  final String wordmark;
  final double tamanoWordmark;

  const SplashConocimiento({
    super.key,
    required this.colorFondo,
    required this.tarea,
    required this.onListo,
    required this.wordmark,
    this.duracionMinima = const Duration(milliseconds: 1200),
    this.tamanoWordmark = 30,
  });

  @override
  State<SplashConocimiento<T>> createState() => _SplashConocimientoState<T>();
}

class _SplashConocimientoState<T> extends State<SplashConocimiento<T>> {
  @override
  void initState() {
    super.initState();
    _ejecutar();
  }

  Future<void> _ejecutar() async {
    final inicio = DateTime.now();
    final resultado = await widget.tarea();
    final transcurrido = DateTime.now().difference(inicio);
    final restante = widget.duracionMinima - transcurrido;
    if (restante > Duration.zero) {
      await Future.delayed(restante);
    }
    if (mounted) widget.onListo(context, resultado);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.colorFondo,
      body: Center(
        child: Text(
          widget.wordmark,
          style: GoogleFonts.manrope(
            fontSize: widget.tamanoWordmark,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
