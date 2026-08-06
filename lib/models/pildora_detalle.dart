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

  /// La nota que el usuario escribió al valorar, si escribió alguna.
  ///
  /// Vuelve del backend para poder precargar `ValoracionSheet`: `valorar()`
  /// sobrescribe la nota con lo que reciba, así que sin esto cambiar sólo las
  /// estrellas borraría en silencio lo que ya había escrito.
  final String? notaPersonalUsuario;

  PildoraDetalle({
    required this.pildoraId,
    required this.titulo,
    required this.contenidoCompleto,
    this.libroOrigen,
    this.imagenUrl,
    this.categorias = const [],
    required this.estado,
    this.valoracionUsuario,
    this.notaPersonalUsuario,
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
      notaPersonalUsuario: json['notaPersonalUsuario'],
    );
  }
}
