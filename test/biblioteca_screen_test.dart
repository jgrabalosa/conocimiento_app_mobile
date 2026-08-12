import 'package:conocimiento_app_mobile/models/categoria_conocimiento.dart';
import 'package:conocimiento_app_mobile/models/pildora_coleccion_item.dart';
import 'package:conocimiento_app_mobile/screens/biblioteca_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:norday_flutter_core/norday_flutter_core.dart';

final _categorias = [
  CategoriaConocimiento(categoriaId: 1, nombre: 'Ciencia'),
  CategoriaConocimiento(categoriaId: 2, nombre: 'Historia'),
];

/// Sin `imagenUrl`: en un test `Image.network` no resuelve nada, y la
/// miniatura no es lo que se prueba aquí.
final _items = [
  PildoraColeccionItem(
      pildoraId: 10,
      titulo: 'El efecto Zeigarnik',
      estado: 'VISTA',
      categoriaPrincipal: 'Psicología'),
  PildoraColeccionItem(
      pildoraId: 11,
      titulo: 'La biblioteca de Alejandría',
      estado: 'GUARDADA',
      categoriaPrincipal: 'Historia'),
];

/// Registra con qué filtros se pidió la colección cada vez. Es lo que permite
/// comprobar que tocar un filtro dispara de verdad una carga nueva, y con qué.
class _EspiaColeccion {
  final List<({int? categoriaId, String? estado})> llamadas = [];
  final List<PildoraColeccionItem> devuelve;

  _EspiaColeccion({List<PildoraColeccionItem>? devuelve})
      : devuelve = devuelve ?? _items;

  Future<List<PildoraColeccionItem>> cargar(
      {int? categoriaId, String? estado}) async {
    llamadas.add((categoriaId: categoriaId, estado: estado));
    return devuelve;
  }
}

Widget _app(_EspiaColeccion espia) => MaterialApp(
      locale: const Locale('es'),
      supportedLocales: const [Locale('es')],
      localizationsDelegates: const [
        NordayCoreLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: BibliotecaScreen(
        cargarCategorias: () async => _categorias,
        cargarColeccion: espia.cargar,
      ),
    );

void main() {
  testWidgets('al entrar pide la colección una vez y sin filtros',
      (tester) async {
    final espia = _EspiaColeccion();
    await tester.pumpWidget(_app(espia));
    await tester.pumpAndSettle();

    expect(espia.llamadas, [(categoriaId: null, estado: null)]);
    expect(find.text('El efecto Zeigarnik'), findsOneWidget);
    expect(find.text('La biblioteca de Alejandría'), findsOneWidget);
  });

  testWidgets('cambiar el filtro de estado vuelve a pedir la colección',
      (tester) async {
    final espia = _EspiaColeccion();
    await tester.pumpWidget(_app(espia));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Guardadas'));
    await tester.pumpAndSettle();

    expect(espia.llamadas.length, 2);
    expect(espia.llamadas.last, (categoriaId: null, estado: 'GUARDADA'));
  });

  testWidgets('cambiar el filtro de categoría vuelve a pedir la colección',
      (tester) async {
    final espia = _EspiaColeccion();
    await tester.pumpWidget(_app(espia));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Historia').first);
    await tester.pumpAndSettle();

    expect(espia.llamadas.length, 2);
    expect(espia.llamadas.last, (categoriaId: 2, estado: null));
  });

  testWidgets('los dos filtros son independientes y viajan juntos',
      (tester) async {
    final espia = _EspiaColeccion();
    await tester.pumpWidget(_app(espia));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Vistas'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ciencia'));
    await tester.pumpAndSettle();

    // Elegir categoría no ha reseteado el estado.
    expect(espia.llamadas.last, (categoriaId: 1, estado: 'VISTA'));
  });

  testWidgets('el icono de estado distingue guardada de vista y es tocable',
      (tester) async {
    final espia = _EspiaColeccion();
    await tester.pumpWidget(_app(espia));
    await tester.pumpAndSettle();

    // Uno de cada, según el estado de cada píldora.
    expect(find.byIcon(LucideIcons.eye), findsOneWidget);
    expect(find.byIcon(LucideIcons.bookmarkCheck), findsOneWidget);

    // No se pulsan: `guardar` va contra la red de verdad. Lo que se comprueba
    // es que no lleguen desactivados, que es lo que los dejaría inertes sin
    // que nada lo delatara.
    for (final icono in [LucideIcons.eye, LucideIcons.bookmarkCheck]) {
      final boton = tester.widget<IconButton>(find.ancestor(
        of: find.byIcon(icono),
        matching: find.byType(IconButton),
      ));
      expect(boton.onPressed, isNotNull);
    }
  });

  testWidgets('sin nada visto todavía, el vacío explica cómo se llena',
      (tester) async {
    final espia = _EspiaColeccion(devuelve: []);
    await tester.pumpWidget(_app(espia));
    await tester.pumpAndSettle();

    expect(find.text('Aún no has visto ninguna píldora'), findsOneWidget);
  });

  testWidgets('vacío por el filtro de guardadas dice otra cosa', (tester) async {
    final espia = _EspiaColeccion(devuelve: []);
    await tester.pumpWidget(_app(espia));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Guardadas'));
    await tester.pumpAndSettle();

    expect(find.text('Aún no tienes píldoras guardadas'), findsOneWidget);
    expect(find.text('Aún no has visto ninguna píldora'), findsNothing);
  });
}
