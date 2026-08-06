import 'dart:convert';
import 'package:norday_flutter_core/norday_flutter_core.dart';
import '../models/categoria_conocimiento.dart';
import '../models/pildora_coleccion_item.dart';
import '../models/pildora_detalle.dart';
import '../models/preferencia_categoria.dart';
import '../models/siguiente_pildora.dart';

/// Disparadores: los endpoints que sí saben de píldoras, categorías y
/// preferencias. Todo lo genérico —sesión, usuario, gamificación, tienda,
/// mascota— vive en `ApiServiceCore`, dentro de norday_flutter_core.
///
/// Se apoya en la tubería del motor ([ApiServiceCore.enviar], `verificar`,
/// `parsear`) para que un fallo de red se clasifique igual aquí que allí:
/// las pantallas solo ven `ApiException`.
///
/// Ningún método lleva `usuarioId`: el backend saca al usuario del token, y
/// pasárselo además solo abriría la puerta a que no coincidieran.
class ApiServiceConocimiento {
  static const String _baseUrl = ApiServiceCore.baseUrl;

  // ── Categorías y preferencias ──────────────────────────
  static Future<List<CategoriaConocimiento>> getCategorias() async {
    final headers = await ApiServiceCore.getHeaders();
    final response = await ApiServiceCore.enviar(() => ApiServiceCore.cliente.get(
          Uri.parse('$_baseUrl/conocimiento/categorias'),
          headers: headers,
        ));
    ApiServiceCore.verificar(response);
    return ApiServiceCore.parsear(() {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => CategoriaConocimiento.fromJson(json)).toList();
    });
  }

  static Future<List<PreferenciaCategoria>> getPreferencias() async {
    final headers = await ApiServiceCore.getHeaders();
    final response = await ApiServiceCore.enviar(() => ApiServiceCore.cliente.get(
          Uri.parse('$_baseUrl/conocimiento/preferencias'),
          headers: headers,
        ));
    ApiServiceCore.verificar(response);
    return ApiServiceCore.parsear(() {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => PreferenciaCategoria.fromJson(json)).toList();
    });
  }

  /// Manda la lista COMPLETA, no un parche: el backend rechaza con 400 si no
  /// queda al menos una categoría en QUIERE. Devuelve la lista ya actualizada,
  /// así que no hace falta un GET detrás.
  static Future<List<PreferenciaCategoria>> actualizarPreferencias(
      List<PreferenciaCategoria> nuevas) async {
    final headers = await ApiServiceCore.getHeaders();
    final response = await ApiServiceCore.enviar(() => ApiServiceCore.cliente.put(
          Uri.parse('$_baseUrl/conocimiento/preferencias'),
          headers: headers,
          body: jsonEncode(nuevas.map((p) => p.toJson()).toList()),
        ));
    ApiServiceCore.verificar(response);
    return ApiServiceCore.parsear(() {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => PreferenciaCategoria.fromJson(json)).toList();
    });
  }

  // ── El bucle ───────────────────────────────────────────
  static Future<SiguientePildora> getSiguientePildora() async {
    final headers = await ApiServiceCore.getHeaders();
    final response = await ApiServiceCore.enviar(() => ApiServiceCore.cliente.get(
          Uri.parse('$_baseUrl/conocimiento/pildoras/siguiente'),
          headers: headers,
        ));
    ApiServiceCore.verificar(response);
    return ApiServiceCore.parsear(
        () => SiguientePildora.fromJson(jsonDecode(response.body)));
  }

  /// El usuario destapa la píldora. Es la única llamada que devuelve el
  /// contenido completo.
  static Future<PildoraDetalle> match(int pildoraId) async {
    final headers = await ApiServiceCore.getHeaders();
    final response = await ApiServiceCore.enviar(() => ApiServiceCore.cliente.post(
          Uri.parse('$_baseUrl/conocimiento/pildoras/$pildoraId/match'),
          headers: headers,
        ));
    ApiServiceCore.verificar(response);
    return ApiServiceCore.parsear(
        () => PildoraDetalle.fromJson(jsonDecode(response.body)));
  }

  static Future<void> descartar(int pildoraId) async {
    final headers = await ApiServiceCore.getHeaders();
    final response = await ApiServiceCore.enviar(() => ApiServiceCore.cliente.post(
          Uri.parse('$_baseUrl/conocimiento/pildoras/$pildoraId/descartar'),
          headers: headers,
        ));
    ApiServiceCore.verificar(response);
  }

  static Future<void> guardar(int pildoraId, bool guardar) async {
    final headers = await ApiServiceCore.getHeaders();
    final response = await ApiServiceCore.enviar(() => ApiServiceCore.cliente.put(
          Uri.parse('$_baseUrl/conocimiento/pildoras/$pildoraId/guardar'),
          headers: headers,
          body: jsonEncode({'guardar': guardar}),
        ));
    ApiServiceCore.verificar(response);
  }

  /// La nota es privada del usuario, no una reseña pública. Si viene a null la
  /// clave se omite: mandar `null` literal borraría una nota ya escrita.
  static Future<void> valorar(int pildoraId, int puntuacion,
      {String? notaPersonal}) async {
    final headers = await ApiServiceCore.getHeaders();
    final body = <String, dynamic>{'puntuacion': puntuacion};
    if (notaPersonal != null) {
      body['notaPersonal'] = notaPersonal;
    }
    final response = await ApiServiceCore.enviar(() => ApiServiceCore.cliente.post(
          Uri.parse('$_baseUrl/conocimiento/pildoras/$pildoraId/valoracion'),
          headers: headers,
          body: jsonEncode(body),
        ));
    ApiServiceCore.verificar(response);
  }

  // ── Colección ──────────────────────────────────────────
  /// Los dos filtros son opcionales. Los que vengan a null no se mandan: el
  /// backend distingue "sin filtrar" de un filtro vacío.
  static Future<List<PildoraColeccionItem>> getColeccion(
      {int? categoriaId, String? estado}) async {
    final headers = await ApiServiceCore.getHeaders();
    final query = <String, String>{};
    if (categoriaId != null) query['categoriaId'] = categoriaId.toString();
    if (estado != null) query['estado'] = estado;

    final uri = Uri.parse('$_baseUrl/conocimiento/pildoras/coleccion')
        .replace(queryParameters: query.isEmpty ? null : query);

    final response = await ApiServiceCore.enviar(
        () => ApiServiceCore.cliente.get(uri, headers: headers));
    ApiServiceCore.verificar(response);
    return ApiServiceCore.parsear(() {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => PildoraColeccionItem.fromJson(json)).toList();
    });
  }
}
