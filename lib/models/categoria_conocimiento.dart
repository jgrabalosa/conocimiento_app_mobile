/// Categoría del catálogo curado. No la crea el usuario: solo elige si le
/// interesa o no, y eso vive en [PreferenciaCategoria].
class CategoriaConocimiento {
  final int categoriaId;
  final String? codigo;
  final String nombre;
  final String? descripcion;
  final String? color;
  final String? icono;
  final int orden;

  CategoriaConocimiento({
    required this.categoriaId,
    this.codigo,
    required this.nombre,
    this.descripcion,
    this.color,
    this.icono,
    this.orden = 0,
  });

  factory CategoriaConocimiento.fromJson(Map<String, dynamic> json) {
    return CategoriaConocimiento(
      categoriaId: json['categoriaId'],
      codigo: json['codigo'],
      nombre: json['nombre'],
      descripcion: json['descripcion'],
      color: json['color'],
      icono: json['icono'],
      orden: json['orden'] ?? 0,
    );
  }
}
