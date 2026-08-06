import 'package:conocimiento_app_mobile/models/preferencia_categoria.dart';
import 'package:conocimiento_app_mobile/screens/perfil_usuario_lector_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:norday_flutter_core/norday_flutter_core.dart';

/// Sólo una en QUIERE: es el caso interesante, porque quitarla dejaría la
/// cuenta sin ninguna y es justo lo que hay que impedir.
List<PreferenciaCategoria> _unaSolaEnQuiere() => [
      PreferenciaCategoria(
          categoriaId: 1, nombre: 'Ciencia', icono: '🔬', estado: 'QUIERE'),
      PreferenciaCategoria(
          categoriaId: 2, nombre: 'Historia', icono: '🏛️', estado: 'NEUTRAL'),
    ];

List<PreferenciaCategoria> _dosEnQuiere() => [
      PreferenciaCategoria(
          categoriaId: 1, nombre: 'Ciencia', icono: '🔬', estado: 'QUIERE'),
      PreferenciaCategoria(
          categoriaId: 2, nombre: 'Historia', icono: '🏛️', estado: 'QUIERE'),
    ];

/// Registra lo que se intentó guardar. Si no se llama, es que el cambio se
/// bloqueó antes de tocar la red — que es lo que se quiere comprobar.
class _EspiaGuardado {
  final List<List<PreferenciaCategoria>> guardados = [];

  Future<List<PreferenciaCategoria>> guardar(
      List<PreferenciaCategoria> nuevas) async {
    guardados.add(nuevas);
    return nuevas;
  }
}

Widget _app(List<PreferenciaCategoria> iniciales, _EspiaGuardado espia) =>
    MaterialApp(
      locale: const Locale('es'),
      supportedLocales: const [Locale('es')],
      localizationsDelegates: const [
        NordayCoreLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: PerfilUsuarioLectorScreen(
        cargarPreferencias: () async => iniciales,
        guardarPreferencias: espia.guardar,
      ),
    );

/// El «No» de la tarjeta de Ciencia, que es la primera de la lista.
Finder _noDeLaPrimera() => find.text('No').first;

void main() {
  testWidgets('quitar la única categoría en «Sí» no se permite ni se guarda',
      (tester) async {
    final espia = _EspiaGuardado();
    await tester.pumpWidget(_app(_unaSolaEnQuiere(), espia));
    await tester.pumpAndSettle();

    await tester.tap(_noDeLaPrimera());
    await tester.pumpAndSettle();

    // Ni se llamó al backend...
    expect(espia.guardados, isEmpty);
    // ...ni el selector se movió: Ciencia sigue en QUIERE.
    final boton = tester.widget<SegmentedButton<String>>(
        find.byType(SegmentedButton<String>).first);
    expect(boton.selected, {'QUIERE'});
    // Y se avisa de por qué.
    expect(find.textContaining('al menos una categoría'), findsOneWidget);
  });

  testWidgets('con dos en «Sí», quitar una sí se aplica y se guarda entera',
      (tester) async {
    final espia = _EspiaGuardado();
    await tester.pumpWidget(_app(_dosEnQuiere(), espia));
    await tester.pumpAndSettle();

    await tester.tap(_noDeLaPrimera());
    await tester.pumpAndSettle();

    expect(espia.guardados.length, 1);
    // Va la lista completa, no un parche: el backend la espera entera.
    final enviado = espia.guardados.single;
    expect(enviado.length, 2);
    expect(enviado.firstWhere((p) => p.categoriaId == 1).estado, 'NO_QUIERE');
    expect(enviado.firstWhere((p) => p.categoriaId == 2).estado, 'QUIERE');
  });

  testWidgets('si el guardado falla, el cambio se revierte', (tester) async {
    var intentos = 0;
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('es'),
      supportedLocales: const [Locale('es')],
      localizationsDelegates: const [
        NordayCoreLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: PerfilUsuarioLectorScreen(
        cargarPreferencias: () async => _dosEnQuiere(),
        guardarPreferencias: (nuevas) async {
          intentos++;
          throw const ApiException(TipoErrorApi.sinConexion);
        },
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(_noDeLaPrimera());
    await tester.pumpAndSettle();

    expect(intentos, 1);
    // Vuelve a QUIERE: nadie debe quedarse viendo un cambio que no se guardó.
    final boton = tester.widget<SegmentedButton<String>>(
        find.byType(SegmentedButton<String>).first);
    expect(boton.selected, {'QUIERE'});
  });

  testWidgets('las filas de «Próximamente» no llevan a ninguna parte',
      (tester) async {
    final espia = _EspiaGuardado();
    await tester.pumpWidget(_app(_dosEnQuiere(), espia));
    await tester.pumpAndSettle();

    for (final titulo in ['Tienda', 'Mascota', 'Logros']) {
      final fila = tester.widget<ListTile>(find.ancestor(
        of: find.text(titulo),
        matching: find.byType(ListTile),
      ));
      expect(fila.enabled, isFalse, reason: '$titulo debería estar desactivada');
      expect(fila.onTap, isNull);

      // Y tocarlas no cambia de pantalla.
      await tester.tap(find.text(titulo), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.text('Tus intereses'), findsOneWidget);
    }

    expect(find.text('Próximamente'), findsNWidgets(3));
  });

  testWidgets('la fila de Cuenta sí es tocable', (tester) async {
    final espia = _EspiaGuardado();
    await tester.pumpWidget(_app(_dosEnQuiere(), espia));
    await tester.pumpAndSettle();

    final fila = tester.widget<ListTile>(find.ancestor(
      of: find.text('Cuenta'),
      matching: find.byType(ListTile),
    ));
    expect(fila.onTap, isNotNull);
  });
}
