import 'pildora_preview.dart';

/// Respuesta de `/pildoras/siguiente`.
///
/// `hayContenido` va aparte de `pildora` a propósito: sin él, la pantalla no
/// puede distinguir "aún no ha llegado" de "no queda nada que leer", y esos
/// dos vacíos se pintan distinto.
class SiguientePildora {
  final PildoraPreview? pildora;
  final bool hayContenido;

  SiguientePildora({this.pildora, required this.hayContenido});

  factory SiguientePildora.fromJson(Map<String, dynamic> json) {
    final pildoraJson = json['pildora'];
    return SiguientePildora(
      pildora: pildoraJson != null ? PildoraPreview.fromJson(pildoraJson) : null,
      hayContenido: json['hayContenido'] ?? false,
    );
  }
}
