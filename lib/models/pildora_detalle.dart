/// La píldora destapada. `contenidoCompleto` viene en Markdown y puede llevar
/// imágenes embebidas: lo pinta el detalle (Paso F4) con flutter_markdown_plus.
class PildoraDetalle {
  final int pildoraId;
  final String titulo;
  final String contenidoCompleto;
  final String? libroOrigen;
  final String? imagenUrl;
  final List<String> categorias;
  final String estado; // VISTA o GUARDADA
  final int? valoracionUsuario; // null si aún no ha valorado

  PildoraDetalle({
    required this.pildoraId,
    required this.titulo,
    required this.contenidoCompleto,
    this.libroOrigen,
    this.imagenUrl,
    this.categorias = const [],
    required this.estado,
    this.valoracionUsuario,
  });

  factory PildoraDetalle.fromJson(Map<String, dynamic> json) {
    return PildoraDetalle(
      pildoraId: json['pildoraId'],
      titulo: json['titulo'] ?? '',
      contenidoCompleto: json['contenidoCompleto'] ?? '',
      libroOrigen: json['libroOrigen'],
      imagenUrl: json['imagenUrl'],
      categorias: (json['categorias'] as List<dynamic>? ?? [])
          .map((c) => c.toString())
          .toList(),
      estado: json['estado'],
      valoracionUsuario: json['valoracionUsuario'],
    );
  }
}
