/// Qué quiere ver el usuario de cada categoría: QUIERE, NEUTRAL o NO_QUIERE.
///
/// Viaja en los dos sentidos, así que es el único modelo con [toJson]. En el
/// PUT el backend solo mira `categoriaId` y `estado`, pero se manda entero:
/// devolver lo mismo que se recibió cuesta menos que recortarlo.
class PreferenciaCategoria {
  final int categoriaId;
  final String nombre;
  final String? icono;
  final String? color;
  final String estado;

  PreferenciaCategoria({
    required this.categoriaId,
    required this.nombre,
    this.icono,
    this.color,
    required this.estado,
  });

  factory PreferenciaCategoria.fromJson(Map<String, dynamic> json) {
    return PreferenciaCategoria(
      categoriaId: json['categoriaId'],
      nombre: json['nombre'] ?? '',
      icono: json['icono'],
      color: json['color'],
      estado: json['estado'],
    );
  }

  Map<String, dynamic> toJson() => {
        'categoriaId': categoriaId,
        'nombre': nombre,
        'icono': icono,
        'color': color,
        'estado': estado,
      };

  /// El usuario cambia el estado desde la lista; el resto de campos son del
  /// catálogo y no se tocan.
  PreferenciaCategoria conEstado(String nuevoEstado) => PreferenciaCategoria(
        categoriaId: categoriaId,
        nombre: nombre,
        icono: icono,
        color: color,
        estado: nuevoEstado,
      );
}
