import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:norday_flutter_core/norday_flutter_core.dart';

import '../models/categoria_conocimiento.dart';
import '../models/pildora_coleccion_item.dart';
import '../services/api_service_conocimiento.dart';
import '../widgets/error_carga.dart';
import 'detalle_pildora_screen.dart';

/// Los dos estados que llegan a la Biblioteca. Lo descartado no es de nadie y
/// no aparece nunca, así que aquí no hay un tercer valor.
const String _vista = 'VISTA';
const String _guardada = 'GUARDADA';

const double _ladoMiniatura = 56;

/// Todo lo que el usuario ha visto o guardado, con dos filtros independientes.
///
/// Los filtros no se combinan en una sola pregunta al backend por comodidad:
/// `getColeccion` ya acepta los dos por separado y distingue "sin filtrar" de
/// un filtro vacío, así que cada uno viaja como lo que es.
class BibliotecaScreen extends StatefulWidget {
  /// Costuras de test, mismo criterio que en `OnboardingCategoriasScreen`:
  /// `ApiServiceCore.cliente` es `final` y no hay dónde meter un cliente
  /// falso sin tocar el paquete. En producción nadie pasa esto.
  final Future<List<CategoriaConocimiento>> Function()? cargarCategorias;
  final Future<List<PildoraColeccionItem>> Function({
    int? categoriaId,
    String? estado,
  })? cargarColeccion;

  const BibliotecaScreen({
    super.key,
    this.cargarCategorias,
    this.cargarColeccion,
  });

  @override
  State<BibliotecaScreen> createState() => _BibliotecaScreenState();
}

class _BibliotecaScreenState extends State<BibliotecaScreen> {
  /// null en los dos es "Todas". Son independientes: cambiar uno no toca el
  /// otro.
  String? _estado;
  int? _categoriaId;

  /// Se piden una sola vez, al entrar: el catálogo no cambia porque el
  /// usuario toque un filtro.
  late final Future<List<CategoriaConocimiento>> _futuroCategorias;

  late Future<List<PildoraColeccionItem>> _futuroColeccion;

  @override
  void initState() {
    super.initState();
    _futuroCategorias =
        (widget.cargarCategorias ?? ApiServiceConocimiento.getCategorias)();
    _futuroColeccion = _pedirColeccion();
  }

  Future<List<PildoraColeccionItem>> _pedirColeccion() =>
      (widget.cargarColeccion ?? ApiServiceConocimiento.getColeccion)(
        categoriaId: _categoriaId,
        estado: _estado,
      );

  void _recargar() => setState(() => _futuroColeccion = _pedirColeccion());

  void _cambiarEstado(String? nuevo) {
    setState(() {
      _estado = nuevo;
      _futuroColeccion = _pedirColeccion();
    });
  }

  void _cambiarCategoria(int? nueva) {
    setState(() {
      _categoriaId = nueva;
      _futuroColeccion = _pedirColeccion();
    });
  }

  void _avisar(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje)));
  }

  Future<void> _alternarGuardado(PildoraColeccionItem item) async {
    try {
      await ApiServiceConocimiento.guardar(
          item.pildoraId, item.estado != _guardada);
    } catch (e) {
      if (!mounted) return;
      _avisar(MensajesError.de(context, e,
          generico: 'No se pudo cambiar el guardado.'));
    }
    if (!mounted) return;
    // Salga bien o mal: recargar entera sale más simple que mutar un elemento
    // suelto, y con un catálogo pequeño el coste es despreciable. Si falló, la
    // recarga devuelve el estado real, que es justo lo que hay que enseñar.
    _recargar();
  }

  /// `match` sobre algo ya visto o guardado no vuelve a sumar afinidad —el
  /// backend solo la suma la primera vez—, así que sirve tal cual para
  /// recuperar el detalle completo sin un endpoint aparte.
  Future<void> _abrirDetalle(PildoraColeccionItem item) async {
    try {
      final detalle = await ApiServiceConocimiento.match(item.pildoraId);
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DetallePildoraScreen(detalle: detalle)),
      );
      if (!mounted) return;
      // Desde el detalle se puede guardar o dejar de guardar.
      _recargar();
    } catch (e) {
      if (!mounted) return;
      _avisar(MensajesError.de(context, e,
          generico: 'No se pudo abrir la píldora.'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = tokens(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Biblioteca',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          _filtroEstado(t),
          _filtroCategoria(t),
          const Divider(height: 1),
          Expanded(child: _lista(t)),
        ],
      ),
    );
  }

  Widget _filtroEstado(TokensContextuales t) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
      child: SizedBox(
        width: double.infinity,
        child: SegmentedButton<String?>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: null, label: Text('Todas')),
            ButtonSegment(value: _vista, label: Text('Vistas')),
            ButtonSegment(value: _guardada, label: Text('Guardadas')),
          ],
          selected: {_estado},
          onSelectionChanged: (seleccion) => _cambiarEstado(seleccion.first),
          style: SegmentedButton.styleFrom(
            foregroundColor: t.textMuted,
            selectedForegroundColor: t.primary,
            selectedBackgroundColor: t.primary.withValues(alpha: 0.18),
            side: BorderSide(color: t.textMuted.withValues(alpha: 0.3)),
          ),
        ),
      ),
    );
  }

  Widget _filtroCategoria(TokensContextuales t) {
    return FutureBuilder<List<CategoriaConocimiento>>(
      future: _futuroCategorias,
      builder: (context, snapshot) {
        // Mientras cargan —o si fallan— queda solo el chip de "Todas": sin
        // categorías el filtro no sirve, pero la lista de abajo sí, y no vale
        // la pena tumbar la pantalla entera por esto.
        final categorias = snapshot.data ?? const <CategoriaConocimiento>[];

        return SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            children: [
              _chipCategoria(t, null, 'Todas'),
              for (final c in categorias)
                _chipCategoria(t, c.categoriaId, c.nombre),
            ],
          ),
        );
      },
    );
  }

  Widget _chipCategoria(TokensContextuales t, int? id, String nombre) {
    final seleccionado = _categoriaId == id;

    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: ChoiceChip(
        label: Text(nombre),
        selected: seleccionado,
        onSelected: (_) => _cambiarCategoria(id),
        selectedColor: t.primary.withValues(alpha: 0.2),
        labelStyle: TextStyle(
          color: seleccionado ? t.primary : t.textMuted,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _lista(TokensContextuales t) {
    return FutureBuilder<List<PildoraColeccionItem>>(
      future: _futuroColeccion,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return ErrorCarga(error: snapshot.error!, onReintentar: _recargar);
        }

        final items = snapshot.data!;
        if (items.isEmpty) return _vacio(t);

        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: items.length,
          itemBuilder: (context, i) => _fila(t, items[i]),
        );
      },
    );
  }

  Widget _fila(TokensContextuales t, PildoraColeccionItem item) {
    final guardada = item.estado == _guardada;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        leading: _miniatura(t, item.imagenUrl),
        title: Text(
          item.titulo,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
              fontSize: 15, fontWeight: FontWeight.w700, color: t.text),
        ),
        subtitle: item.categoriaPrincipal == null
            ? null
            : Text(item.categoriaPrincipal!,
                style: TextStyle(fontSize: 12, color: t.textMuted)),
        trailing: IconButton(
          tooltip: guardada ? 'Quitar de guardados' : 'Guardar',
          icon: Icon(
            guardada ? LucideIcons.bookmarkCheck : LucideIcons.eye,
            color: guardada ? t.primary : t.textMuted,
          ),
          onPressed: () => _alternarGuardado(item),
        ),
        onTap: () => _abrirDetalle(item),
      ),
    );
  }

  /// Mismo respaldo que `TarjetaPildora` y `DetallePildoraScreen`: sin imagen
  /// o con la URL rota, color e icono, nunca un hueco.
  Widget _miniatura(TokensContextuales t, String? url) {
    final respaldo = ColoredBox(
      color: t.surface2,
      child: Center(
        child: Icon(LucideIcons.bookOpen,
            size: 24, color: t.textMuted.withValues(alpha: 0.35)),
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: SizedBox(
        width: _ladoMiniatura,
        height: _ladoMiniatura,
        child: url == null || url.isEmpty
            ? respaldo
            : Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (context, error, pila) => respaldo,
              ),
      ),
    );
  }

  Widget _vacio(TokensContextuales t) {
    final (titulo, ayuda) = _textosVacio();

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.libraryBig, size: 48, color: t.textMuted),
            const SizedBox(height: AppSpacing.md),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w700, color: t.text),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(ayuda,
                textAlign: TextAlign.center,
                style: TextStyle(color: t.textMuted)),
          ],
        ),
      ),
    );
  }

  /// Una colección vacía de verdad y una que solo está vacía por los filtros
  /// no dicen lo mismo: la primera explica cómo se llena, la segunda que hay
  /// algo que quitar.
  (String, String) _textosVacio() {
    if (_estado == null && _categoriaId == null) {
      return (
        'Aún no has visto ninguna píldora',
        'Las que abras desde la pantalla principal aparecerán aquí.',
      );
    }
    if (_estado == _guardada && _categoriaId == null) {
      return (
        'Aún no tienes píldoras guardadas',
        'Guarda las que quieras releer y las encontrarás aquí.',
      );
    }
    return ('Nada con estos filtros', 'Prueba a quitar alguno.');
  }
}
