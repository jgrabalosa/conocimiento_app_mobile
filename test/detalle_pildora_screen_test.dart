import 'package:conocimiento_app_mobile/models/pildora_detalle.dart';
import 'package:conocimiento_app_mobile/screens/detalle_pildora_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:norday_flutter_core/norday_flutter_core.dart';

/// Sin `imagenUrl`: en un test `Image.network` no puede resolver nada, y la
/// cabecera no es lo que se prueba aquí.
PildoraDetalle _detalle({
  String estado = 'VISTA',
  int? valoracion,
  String? nota,
  String? libro,
  List<String> categorias = const [],
  String? contenido,
}) {
  return PildoraDetalle(
    pildoraId: 3,
    titulo: 'El efecto Zeigarnik',
    contenidoCompleto:
        contenido ?? '# Tareas abiertas\n\nLo inacabado **se recuerda** mejor.',
    libroOrigen: libro,
    categorias: categorias,
    estado: estado,
    valoracionUsuario: valoracion,
    notaPersonalUsuario: nota,
  );
}

/// El capitular se pinta como un `Text` suelto en cuerpo 52 (la primera letra
/// en Fraunces). Su presencia o ausencia es lo que distingue una píldora
/// capitulada de una que se pinta entera tal cual, sin tener que fisgar la
/// estructura interna del widget.
final Finder _capitular = find.byWidgetPredicate(
    (w) => w is Text && w.style?.fontSize == 52);

Widget _app(PildoraDetalle detalle) => MaterialApp(
      locale: const Locale('es'),
      supportedLocales: const [Locale('es')],
      localizationsDelegates: const [
        NordayCoreLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: DetallePildoraScreen(detalle: detalle),
    );

/// Los iconos no se pulsan en los tests: los tres disparan red o el diálogo
/// nativo de compartir. Lo que sí se comprueba es que estén y que no lleguen
/// desactivados, que es lo que rompería la pantalla en silencio.
bool _activo(WidgetTester tester, IconData icono) {
  final boton = tester.widget<IconButton>(find.ancestor(
    of: find.byIcon(icono),
    matching: find.byType(IconButton),
  ));
  return boton.onPressed != null;
}

void main() {
  testWidgets('las tres acciones están y ninguna llega desactivada',
      (tester) async {
    await tester.pumpWidget(_app(_detalle()));

    expect(find.byIcon(LucideIcons.star), findsOneWidget);
    expect(find.byIcon(LucideIcons.bookmark), findsOneWidget);
    expect(find.byIcon(LucideIcons.share2), findsOneWidget);

    expect(_activo(tester, LucideIcons.star), isTrue);
    expect(_activo(tester, LucideIcons.bookmark), isTrue);
    expect(_activo(tester, LucideIcons.share2), isTrue);
  });

  // Cada estado inicial va en su propio test y no repintando el mismo árbol
  // con otro `detalle`: la pantalla lee `widget.detalle` en `initState`, así
  // que repintar no la recrearía. En producción no hay tal caso — cada
  // píldora llega como una ruta nueva.

  testWidgets('sin valoración previa, la estrella está apagada',
      (tester) async {
    await tester.pumpWidget(_app(_detalle()));

    expect(tester.widget<Icon>(find.byIcon(LucideIcons.star)).color,
        isNot(Colors.amber));
  });

  testWidgets('con valoración previa, la estrella está encendida',
      (tester) async {
    await tester.pumpWidget(_app(_detalle(valoracion: 4)));

    expect(
        tester.widget<Icon>(find.byIcon(LucideIcons.star)).color, Colors.amber);
  });

  testWidgets('una píldora sólo vista enseña el marcador vacío', (tester) async {
    await tester.pumpWidget(_app(_detalle()));

    expect(find.byIcon(LucideIcons.bookmark), findsOneWidget);
    expect(find.byIcon(LucideIcons.bookmarkCheck), findsNothing);
  });

  testWidgets('una píldora guardada enseña el marcador marcado', (tester) async {
    await tester.pumpWidget(_app(_detalle(estado: 'GUARDADA')));

    expect(find.byIcon(LucideIcons.bookmarkCheck), findsOneWidget);
    expect(find.byIcon(LucideIcons.bookmark), findsNothing);
  });

  testWidgets('pinta el Markdown, las categorías y el libro de origen',
      (tester) async {
    await tester.pumpWidget(_app(_detalle(
      libro: 'Psicología de lo inacabado',
      categorias: ['Psicología', 'Productividad'],
    )));

    // El Markdown se renderiza: el encabezado y el párrafo salen como texto,
    // sin las almohadillas ni los asteriscos.
    expect(find.textContaining('Tareas abiertas', findRichText: true),
        findsOneWidget);
    expect(find.textContaining('se recuerda', findRichText: true),
        findsOneWidget);
    expect(find.textContaining('**', findRichText: true), findsNothing);

    expect(find.text('Psicología · Productividad'), findsOneWidget);
    expect(find.text('De: Psicología de lo inacabado'), findsOneWidget);
  });

  testWidgets('sin categorías ni libro no se cuela ninguna línea vacía',
      (tester) async {
    await tester.pumpWidget(_app(_detalle()));

    expect(find.textContaining('De:'), findsNothing);
  });

  // El capitular es para prosa. Un contenido que abre con lista, cita o lista
  // numerada no debe traer un guion/símbolo/dígito gigante ni perder su
  // formato: se pinta entero tal cual y el capitular se omite en esa píldora.

  testWidgets('si abre con lista, no hay capitular y la lista se pinta',
      (tester) async {
    await tester.pumpWidget(_app(_detalle(
      contenido: '- Primera viñeta\n- Segunda viñeta',
    )));

    expect(_capitular, findsNothing);
    expect(find.textContaining('Primera viñeta', findRichText: true),
        findsOneWidget);
  });

  testWidgets('si abre con cita, no hay capitular y la cita se pinta',
      (tester) async {
    await tester.pumpWidget(_app(_detalle(
      contenido: '> Lo inacabado tira de nosotros.',
    )));

    expect(_capitular, findsNothing);
    expect(find.textContaining('Lo inacabado tira', findRichText: true),
        findsOneWidget);
  });

  testWidgets('si abre con lista numerada, no hay capitular y se pinta',
      (tester) async {
    await tester.pumpWidget(_app(_detalle(
      contenido: '1. Primer paso\n2. Segundo paso',
    )));

    expect(_capitular, findsNothing);
    expect(
        find.textContaining('Primer paso', findRichText: true), findsOneWidget);
  });

  testWidgets('si abre con párrafo de prosa, el capitular sí aparece',
      (tester) async {
    await tester.pumpWidget(_app(_detalle(
      contenido: 'Un párrafo de prosa que sí lleva capitular.',
    )));

    expect(_capitular, findsOneWidget);
    // La primera letra es la que sube a cuerpo 52; el resto sigue normal.
    expect(tester.widget<Text>(_capitular).data, 'U');
  });
}
