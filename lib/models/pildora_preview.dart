/// Lo que se ve ANTES del match. No trae `contenidoCompleto` porque el backend
/// no lo manda aquí: si viajara, descartar dejaría de costar nada.
class PildoraPreview {
  final int pildoraId;
  final String previewCorto;
  final String? imagenUrl;

  PildoraPreview({
    required this.pildoraId,
    required this.previewCorto,
    this.imagenUrl,
  });

  factory PildoraPreview.fromJson(Map<String, dynamic> json) {
    return PildoraPreview(
      pildoraId: json['pildoraId'],
      previewCorto: json['previewCorto'] ?? '',
      imagenUrl: json['imagenUrl'],
    );
  }
}
