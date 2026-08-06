/// Una fila de la pantalla Colección. Solo llegan aquí las VISTA y las
/// GUARDADA: lo descartado no es de nadie.
class PildoraColeccionItem {
  final int pildoraId;
  final String titulo;
  final String? imagenUrl;
  final String estado;
  final String? categoriaPrincipal;

  PildoraColeccionItem({
    required this.pildoraId,
    required this.titulo,
    this.imagenUrl,
    required this.estado,
    this.categoriaPrincipal,
  });

  factory PildoraColeccionItem.fromJson(Map<String, dynamic> json) {
    return PildoraColeccionItem(
      pildoraId: json['pildoraId'],
      titulo: json['titulo'] ?? '',
      imagenUrl: json['imagenUrl'],
      estado: json['estado'],
      categoriaPrincipal: json['categoriaPrincipal'],
    );
  }
}
