import 'package:flutter/material.dart';
import 'package:norday_flutter_core/norday_flutter_core.dart';

import '../models/pildora_detalle.dart';

/// La píldora ya destapada.
///
/// Provisional: pinta `contenidoCompleto` como texto plano, y el backend lo
/// manda en Markdown con imágenes embebidas. F4 lo sustituye por el render
/// con flutter_markdown_plus (la dependencia ya está declarada) y añade
/// guardar y valorar.
class DetallePildoraScreen extends StatelessWidget {
  final PildoraDetalle detalle;

  const DetallePildoraScreen({super.key, required this.detalle});

  @override
  Widget build(BuildContext context) {
    final t = tokens(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          detalle.titulo,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Text(
          detalle.contenidoCompleto,
          style: TextStyle(fontSize: 16, height: 1.5, color: t.text),
        ),
      ),
    );
  }
}
