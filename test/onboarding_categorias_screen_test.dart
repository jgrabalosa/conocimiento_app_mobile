import 'package:conocimiento_app_mobile/models/categoria_conocimiento.dart';
import 'package:conocimiento_app_mobile/screens/onboarding_categorias_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:norday_flutter_core/norday_flutter_core.dart';

/// Catálogo falso: el test no toca la red, sólo la regla de "al menos una en
/// QUIERE" que decide si Continuar está activo.
final _categorias = [
  CategoriaConocimiento(categoriaId: 1, nombre: 'Ciencia', icono: '🔬', color: '#27C76F'),
  CategoriaConocimiento(categoriaId: 2, nombre: 'Historia', icono: '🏛️', color: '#23395D'),
];

Widget _app() => MaterialApp(
      locale: const Locale('es'),
      supportedLocales: const [Locale('es')],
      localizationsDelegates: const [
        NordayCoreLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: OnboardingCategoriasScreen(
        cargarCategorias: () async => _categorias,
      ),
    );

/// El botón de Continuar es el único `ElevatedButton` de la pantalla.
bool _continuarActivo(WidgetTester tester) =>
    tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed != null;

void main() {
  testWidgets('arranca todo en NEUTRAL y con Continuar desactivado',
      (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    for (final boton in tester.widgetList<SegmentedButton<String>>(
        find.byType(SegmentedButton<String>))) {
      expect(boton.selected, {'NEUTRAL'});
    }
    expect(_continuarActivo(tester), isFalse);
  });

  testWidgets('marcar una categoría como QUIERE activa Continuar',
      (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sí').first);
    await tester.pumpAndSettle();

    expect(_continuarActivo(tester), isTrue);
  });

  testWidgets('quitar el único QUIERE vuelve a desactivar Continuar',
      (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sí').first);
    await tester.pumpAndSettle();
    expect(_continuarActivo(tester), isTrue);

    // NO_QUIERE tampoco cuenta: la regla es "al menos una en QUIERE", no
    // "al menos una tocada".
    await tester.tap(find.text('No').first);
    await tester.pumpAndSettle();

    expect(_continuarActivo(tester), isFalse);
  });
}
