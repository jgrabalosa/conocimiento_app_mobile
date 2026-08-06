import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:norday_flutter_core/norday_flutter_core.dart';
import 'package:share_plus/share_plus.dart';

import '../models/pildora_detalle.dart';
import '../services/api_service_conocimiento.dart';

/// Altura de la cabecera. Fija a propósito: las píldoras traen imágenes de
/// proporciones cualesquiera, y una cabecera que cambia de alto en cada una
/// hace saltar el resto de la pantalla.
const double _altoCabecera = 200;

/// La píldora ya destapada: el contenido en Markdown, y las tres cosas que se
/// pueden hacer con ella — valorarla, guardarla y compartirla.
///
/// Tiene estado propio porque guardado y valoración cambian sin salir de
/// aquí. Ninguno de los dos se toca hasta que el backend confirma: si la
/// llamada falla, el icono sigue enseñando lo último que sí quedó guardado y
/// no lo que se acaba de intentar.
class DetallePildoraScreen extends StatefulWidget {
  final PildoraDetalle detalle;

  const DetallePildoraScreen({super.key, required this.detalle});

  @override
  State<DetallePildoraScreen> createState() => _DetallePildoraScreenState();
}

class _DetallePildoraScreenState extends State<DetallePildoraScreen> {
  late bool _guardada;
  late int? _valoracionActual;
  late String? _notaActual;

  @override
  void initState() {
    super.initState();
    _guardada = widget.detalle.estado == 'GUARDADA';
    _valoracionActual = widget.detalle.valoracionUsuario;
    _notaActual = widget.detalle.notaPersonalUsuario;
  }

  void _avisar(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje)));
  }

  Future<void> _valorar() async {
    final resultado = await ValoracionSheet.mostrar(
      context,
      valoracionInicial: _valoracionActual,
      notaInicial: _notaActual,
    );
    if (resultado == null || !mounted) return; // descartado sin guardar

    final puntuacion = resultado['valoracion'] as int?;
    // Deseleccionó todas las estrellas: no hay nada que mandar. El backend
    // exige una puntuación de 1 a 5, así que tampoco existe "desvalorar".
    if (puntuacion == null) return;
    final nota = resultado['nota'] as String?;

    try {
      await ApiServiceConocimiento.valorar(
        widget.detalle.pildoraId,
        puntuacion,
        notaPersonal: nota,
      );
      if (!mounted) return;
      setState(() {
        _valoracionActual = puntuacion;
        _notaActual = nota;
      });
    } catch (e) {
      if (!mounted) return;
      _avisar(MensajesError.de(context, e,
          generico: 'No se pudo guardar tu valoración.'));
    }
  }

  Future<void> _alternarGuardado() async {
    final nuevo = !_guardada;
    try {
      await ApiServiceConocimiento.guardar(widget.detalle.pildoraId, nuevo);
      if (!mounted) return;
      setState(() => _guardada = nuevo);
    } catch (e) {
      if (!mounted) return;
      _avisar(MensajesError.de(context, e,
          generico: 'No se pudo cambiar el guardado.'));
    }
  }

  /// Texto plano, sin enlace: no hay vista web de las píldoras a la que
  /// apuntar, y sacar un fragmento del Markdown no compensa parsearlo.
  Future<void> _compartir() async {
    await SharePlus.instance.share(
      ShareParams(
        text: '${widget.detalle.titulo}\n\n'
            'Descubierto en Norday Conocimiento 📚',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = tokens(context);
    final d = widget.detalle;
    final hayImagen = d.imagenUrl != null && d.imagenUrl!.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          d.titulo,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Valorar',
            icon: Icon(
              LucideIcons.star,
              color: _valoracionActual != null ? Colors.amber : t.textMuted,
            ),
            onPressed: _valorar,
          ),
          IconButton(
            tooltip: _guardada ? 'Quitar de guardados' : 'Guardar',
            icon: Icon(
              _guardada ? LucideIcons.bookmarkCheck : LucideIcons.bookmark,
              color: _guardada ? t.primary : t.textMuted,
            ),
            onPressed: _alternarGuardado,
          ),
          IconButton(
            tooltip: 'Compartir',
            icon: Icon(LucideIcons.share2, color: t.textMuted),
            onPressed: _compartir,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hayImagen) _cabecera(t, d.imagenUrl!),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (d.categorias.isNotEmpty)
                    Text(
                      d.categorias.join(' · '),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: t.primary,
                      ),
                    ),
                  if (d.libroOrigen != null)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xs),
                      child: Text(
                        'De: ${d.libroOrigen}',
                        style: TextStyle(fontSize: 13, color: t.textMuted),
                      ),
                    ),
                  if (d.categorias.isNotEmpty || d.libroOrigen != null)
                    const SizedBox(height: AppSpacing.md),
                  // MarkdownBody y no Markdown: el segundo trae su propio
                  // scroll, y aquí ya hay un SingleChildScrollView por fuera.
                  // Las imágenes embebidas las pinta el propio paquete, que
                  // ya trae su respaldo para las que no cargan.
                  MarkdownBody(
                    data: d.contenidoCompleto,
                    styleSheet:
                        MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                      p: TextStyle(fontSize: 16, height: 1.55, color: t.text),
                      listBullet:
                          TextStyle(fontSize: 16, height: 1.55, color: t.text),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Mismo criterio que `TarjetaPildora`: una URL rota cae a un contenedor de
  /// color con un icono, nunca deja la cabecera en blanco.
  Widget _cabecera(TokensContextuales t, String url) {
    final respaldo = ColoredBox(
      color: t.surface2,
      child: Center(
        child: Icon(LucideIcons.bookOpen,
            size: 64, color: t.textMuted.withValues(alpha: 0.35)),
      ),
    );

    return SizedBox(
      height: _altoCabecera,
      width: double.infinity,
      child: Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (context, error, pila) => respaldo,
        loadingBuilder: (context, hijo, progreso) => progreso == null
            ? hijo
            : ColoredBox(
                color: t.surface2,
                child: const Center(child: CircularProgressIndicator()),
              ),
      ),
    );
  }
}
