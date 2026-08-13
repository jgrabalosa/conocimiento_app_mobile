import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:norday_flutter_core/norday_flutter_core.dart';
import 'package:share_plus/share_plus.dart';

import '../models/pildora_detalle.dart';
import '../services/api_service_conocimiento.dart';

/// Altura de la cabecera. Fija a propósito: las píldoras traen imágenes de
/// proporciones cualesquiera, y una cabecera que cambia de alto en cada una
/// hace saltar el resto de la pantalla.
const double _altoCabecera = 220;

/// Velocidad de lectura media en español, para estimar el tiempo de lectura
/// a partir del recuento de palabras. No hay campo de backend para esto: se
/// calcula en cliente a partir de `contenidoCompleto`.
const int _palabrasPorMinuto = 200;

/// El capitular siempre en Alba, sea cual sea el tema equipado: es un rasgo
/// editorial de la lectura, no de la identidad de marca del usuario.
final TokensContextuales _tokensAlba = catalogoIdentidades['TEMA_ALBA']!.tokens;

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

  final ScrollController _scroll = ScrollController();
  double _progresoLectura = 0;

  @override
  void initState() {
    super.initState();
    _guardada = widget.detalle.estado == 'GUARDADA';
    _valoracionActual = widget.detalle.valoracionUsuario;
    _notaActual = widget.detalle.notaPersonalUsuario;
    _scroll.addListener(_actualizarProgreso);
  }

  @override
  void dispose() {
    _scroll.removeListener(_actualizarProgreso);
    _scroll.dispose();
    super.dispose();
  }

  /// Cuánto se ha bajado por el contenido, 0 a 1. Sin recorrido que hacer
  /// (contenido más corto que la pantalla) se queda en 0: no hay nada leído
  /// de más por mostrar todavía.
  void _actualizarProgreso() {
    final maximo = _scroll.position.maxScrollExtent;
    final nuevo = maximo <= 0 ? 0.0 : (_scroll.offset / maximo).clamp(0.0, 1.0);
    if (nuevo != _progresoLectura) setState(() => _progresoLectura = nuevo);
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

    return Scaffold(
      appBar: AppBar(
        // El título ya vive en la cabecera, sobre el degradado: repetirlo
        // aquí sólo le quitaría sitio a las acciones.
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: LinearProgressIndicator(
            value: _progresoLectura,
            minHeight: 3,
            backgroundColor: t.surface2,
            valueColor: AlwaysStoppedAnimation(t.primary),
          ),
        ),
      ),
      body: SingleChildScrollView(
        controller: _scroll,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _cabecera(t, d),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _metaLinea(t, d),
                  const SizedBox(height: AppSpacing.md),
                  ..._cuerpo(t, d.contenidoCompleto),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Degradado + título — el mismo lenguaje visual que `TarjetaPildora` en el
  /// bucle: la imagen (o el color de respaldo) siempre lleva un degradado
  /// transparente-a-negro para que el título en blanco se lea igual haya foto
  /// o no, y el título se ancla abajo a la izquierda en el mismo estilo.
  Widget _cabecera(TokensContextuales t, PildoraDetalle d) {
    final respaldo = ColoredBox(
      color: t.surface2,
      child: Center(
        child: Icon(LucideIcons.bookOpen,
            size: 64, color: t.textMuted.withValues(alpha: 0.35)),
      ),
    );

    final url = d.imagenUrl;
    final fondo = (url == null || url.isEmpty)
        ? respaldo
        : Image.network(
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

    return SizedBox(
      height: _altoCabecera,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          fondo,
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
                d.titulo,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.35,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Categorías, libro de origen y tiempo de lectura estimado, en ese orden y
  /// sólo las líneas que haya.
  Widget _metaLinea(TokensContextuales t, PildoraDetalle d) {
    return Column(
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
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xs),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.clock, size: 14, color: t.textMuted),
              const SizedBox(width: 4),
              Text(
                '${_minutosDeLectura(d.contenidoCompleto)} min de lectura',
                style: TextStyle(fontSize: 13, color: t.textMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Palabras del Markdown en crudo, sin afinar el recuento quitando símbolos:
  /// para una estimación de minutos no hace falta más precisión que esa.
  int _minutosDeLectura(String contenido) {
    final palabras = contenido.trim().isEmpty
        ? 0
        : contenido.trim().split(RegExp(r'\s+')).length;
    return (palabras / _palabrasPorMinuto).ceil().clamp(1, 999);
  }

  /// El cuerpo del artículo: los bloques anteriores al primer párrafo tal
  /// cual (para que un `#` de encabezado siga siendo un encabezado), el
  /// capitular sobre ese párrafo, y el resto tal cual detrás.
  ///
  /// Partir en tres en vez de en un único `MarkdownBody` es lo que permite
  /// que el capitular sea grande sólo en la primera línea y no arrastre a
  /// todo el artículo: Flutter no tiene un equivalente a `float` de CSS.
  List<Widget> _cuerpo(TokensContextuales t, String contenido) {
    final bloques = contenido.split(RegExp(r'\n\s*\n'));
    final indice = bloques.indexWhere(
        (b) => !b.trim().startsWith('#') && b.trim().isNotEmpty);

    final estiloParrafo = MarkdownStyleSheet.fromTheme(Theme.of(context))
        .copyWith(
      p: TextStyle(fontSize: 16, height: 1.55, color: t.text),
      listBullet: TextStyle(fontSize: 16, height: 1.55, color: t.text),
    );

    // Ni una palabra que capitular: se pinta todo tal cual, sin capitular.
    if (indice == -1) {
      return [MarkdownBody(data: contenido, styleSheet: estiloParrafo)];
    }

    final antes = bloques.sublist(0, indice).join('\n\n');
    final primerParrafo = bloques[indice];
    final despues = bloques.sublist(indice + 1).join('\n\n');

    final capitular = _capitular(primerParrafo);

    return [
      if (antes.isNotEmpty) ...[
        MarkdownBody(data: antes, styleSheet: estiloParrafo),
        const SizedBox(height: AppSpacing.md),
      ],
      capitular ??
          MarkdownBody(data: primerParrafo, styleSheet: estiloParrafo),
      if (despues.isNotEmpty) ...[
        const SizedBox(height: AppSpacing.md),
        MarkdownBody(data: despues, styleSheet: estiloParrafo),
      ],
    ];
  }

  /// La primera letra del párrafo, grande, en Fraunces itálica y en la
  /// paleta Alba — siempre esa paleta, aunque el usuario lleve equipada
  /// otra: es un rasgo editorial de la lectura, no de su identidad.
  ///
  /// El resto del párrafo pierde el énfasis en negrita/cursiva que pudiera
  /// llevar: para volver a mostrarlo tal cual habría que reconstruir el
  /// `TextSpan` a mano en vez de reusar `MarkdownBody`, y en un único párrafo
  /// no compensa la complejidad.
  Widget? _capitular(String parrafo) {
    final limpio = _sinFormatoMarkdown(parrafo);
    if (limpio.isEmpty) return null;

    final letra = limpio[0];
    final resto = limpio.substring(1);

    return RichText(
      text: TextSpan(
        children: [
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Text(
                letra,
                style: GoogleFonts.getFont(
                  'Fraunces',
                  fontSize: 52,
                  fontWeight: FontWeight.w600,
                  fontStyle: FontStyle.italic,
                  height: 1,
                  color: _tokensAlba.primary,
                ),
              ),
            ),
          ),
          TextSpan(
            text: resto,
            style: TextStyle(fontSize: 16, height: 1.55, color: tokens(context).text),
          ),
        ],
      ),
    );
  }

  /// Quita el énfasis y los enlaces Markdown más comunes de un fragmento de
  /// texto plano: negrita, cursiva, código en línea y `[texto](url)` → texto.
  /// No es un parser completo — sólo lo que hace falta para que el capitular
  /// no enseñe asteriscos ni backticks sueltos.
  String _sinFormatoMarkdown(String texto) {
    var limpio = texto.replaceAllMapped(
        RegExp(r'\[([^\]]+)\]\([^)]+\)'), (m) => m.group(1)!);
    limpio = limpio.replaceAll(RegExp(r'(\*\*|__|\*|_|`|#)'), '');
    return limpio.trim();
  }
}
