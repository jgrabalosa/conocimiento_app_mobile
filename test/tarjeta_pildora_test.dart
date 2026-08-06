import 'package:conocimiento_app_mobile/models/pildora_preview.dart';
import 'package:conocimiento_app_mobile/widgets/tarjeta_pildora.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sin `imagenUrl`: en un test `Image.network` no puede resolver nada, y para
/// lo que se prueba aquí la imagen da igual.
final _pildora = PildoraPreview(
  pildoraId: 7,
  previewCorto: '¿Por qué el cielo es azul?',
);

void main() {
  late int matches;
  late int descartes;

  setUp(() {
    matches = 0;
    descartes = 0;
  });

  Widget app() => MaterialApp(
        home: Scaffold(
          body: TarjetaPildora(
            pildora: _pildora,
            onMatch: () => matches++,
            onDescartar: () => descartes++,
          ),
        ),
      );

  testWidgets('«Ábrela» dispara onMatch y sólo onMatch', (tester) async {
    await tester.pumpWidget(app());

    await tester.tap(find.text('Ábrela'));
    await tester.pumpAndSettle();

    expect(matches, 1);
    expect(descartes, 0);
  });

  testWidgets('«No me interesa» dispara onDescartar y sólo onDescartar',
      (tester) async {
    await tester.pumpWidget(app());

    await tester.tap(find.text('No me interesa'));
    await tester.pumpAndSettle();

    expect(descartes, 1);
    expect(matches, 0);
  });

  testWidgets('el callback espera a que la tarjeta salga de pantalla',
      (tester) async {
    await tester.pumpWidget(app());

    await tester.tap(find.text('Ábrela'));
    await tester.pump();
    // Botón y gesto comparten el mismo camino: primero la animación de
    // salida, y sólo al terminar el callback.
    expect(matches, 0);

    await tester.pumpAndSettle();
    expect(matches, 1);
  });

  testWidgets('una tarjeta decide una sola vez', (tester) async {
    await tester.pumpWidget(app());

    await tester.tap(find.text('Ábrela'));
    await tester.pump(const Duration(milliseconds: 50));
    // Mientras se va, los botones quedan desactivados: un segundo toque no
    // puede colar otra decisión sobre la misma píldora.
    await tester.tap(find.text('Ábrela'), warnIfMissed: false);
    await tester.tap(find.text('No me interesa'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(matches, 1);
    expect(descartes, 0);
  });
}
